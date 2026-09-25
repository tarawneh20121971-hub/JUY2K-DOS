BITS 16
CPU 8086
ORG 100h

; Convert a label to its COM runtime offset.
%define A(x)      (x-$$+100h)
%define QIN       0FA98h
%define QOUT      0389Ah
%define QTAG      04A43h
%define APIVER    0100h
%define RESBYTES  48
%define RESPAR    19

        jmp short MAIN

I1A:    cmp ax,QIN
        je short QUERY
        cmp ah,04h
        jne short JOLD
        pushf
        call far [cs:A(OLD)]
        jc short DONE
        cmp cl,95h
        jae short DONE
        mov ch,20h
        clc
DONE:   retf 2

QUERY:  mov ax,QOUT
        mov bx,QTAG
        mov cx,APIVER
        push cs
        pop es
        iret

JOLD:   db 0EAh
OLD:    dd 0

        times RESBYTES-($-$$) db 90h
ENDR:

%if ENDR-$$ != RESBYTES
        %error "resident core size mismatch"
%endif

%if I1A-$$ != 2
        %error "I1A offset mismatch"
%endif

%if OLD-$$ != 2Ch
        %error "OLD offset mismatch"
%endif

%if RESPAR*16 != 100h+RESBYTES
        %error "resident paragraph count mismatch"
%endif

MAIN:   cld
        push cs
        pop ds
        call PARSE
        jnc .cmdok
        jmp BADCMD
.cmdok:
        mov al,[A(ACT)]
        cmp al,2
        jne .notu
        jmp UNINST
.notu:
        cmp al,3
        jne .nots
        jmp STATUS
.nots:
        cmp al,4
        jne .nothelp
        jmp HELP
.nothelp:
        jmp INSTALL

PARSE:  mov si,81h
        xor cx,cx
        mov cl,[80h]
.scan:  jcxz .done
        lodsb
        dec cx
        cmp al,' '
        je .scan
        cmp al,9
        je .scan
        cmp al,'/'
        je short .slash
.bad0:  jmp .bad
.slash: jcxz .bad0
        lodsb
        dec cx
        cmp al,'?'
        je .save
        and al,0DFh
.save:  mov bl,al
        jcxz .dispatch
        mov al,[si]
        cmp al,' '
        je .dispatch
        cmp al,9
        jne .bad
.dispatch:
        mov al,bl
        cmp al,'Q'
        je .quiet
        cmp byte [A(ACT)],0
        jne .bad
        cmp al,'I'
        je .install
        cmp al,'U'
        je .uninstall
        cmp al,'S'
        je .status
        cmp al,'?'
        je .help
        jmp .bad
.install:
        mov byte [A(ACT)],1
        jmp .scan
.uninstall:
        mov byte [A(ACT)],2
        jmp .scan
.status:
        mov byte [A(ACT)],3
        jmp .scan
.help:
        mov byte [A(ACT)],4
        jmp .scan
.quiet:
        cmp byte [A(QUIET)],0
        jne .bad
        mov byte [A(QUIET)],1
        jmp .scan
.done:
        cmp byte [A(ACT)],0
        jne .qcheck
        cmp byte [A(QUIET)],0
        jne .bad
        mov byte [A(ACT)],1
.qcheck:
        cmp byte [A(QUIET)],0
        je .ok
        cmp byte [A(ACT)],1
        jne .bad
.ok:    clc
        ret
.bad:   stc
        ret

FIND:   mov ax,QIN
        int 1Ah
        push cs
        pop ds
        cmp ax,QOUT
        jne .no
        cmp bx,QTAG
        jne .no
        cmp cx,APIVER
        jne .no
        clc
        ret
.no:    stc
        ret

INSTALL:
        call FIND
        jc .new
        jmp ALREADY
.new:
        mov cx,0FFFFh
        mov dx,0FFFFh
        mov ah,04h
        clc
        int 1Ah
        push cs
        pop ds
        jnc .rtcraw
        jmp RTCBAD
.rtcraw:
        cmp cx,0FFFFh
        jne .cxok
        jmp RTCBAD
.cxok:  cmp dx,0FFFFh
        jne .dxok
        jmp RTCBAD
.dxok:  mov al,cl
        mov ah,al
        and al,0Fh
        cmp al,9
        jbe .lowok
        jmp RTCBAD
.lowok:
        and ah,0F0h
        cmp ah,90h
        jbe .rtcok
        jmp RTCBAD
.rtcok:
        mov ax,351Ah
        int 21h
        mov [A(OLD)],bx
        mov [A(OLD)+2],es
        mov ax,[2Ch]
        or ax,ax
        jz .hook
        mov es,ax
        mov ah,49h
        int 21h
        push cs
        pop ds
        jnc .envok
        jmp ENVBAD
.envok:
        mov word [2Ch],0
.hook:
        cmp byte [A(QUIET)],1
        je .set
        mov dx,A(MSGIN)
        call PRINT
.set:   push cs
        pop ds
        mov dx,A(I1A)
        mov ax,251Ah
        int 21h
        mov dx,RESPAR
        mov ax,3100h
        int 21h

STATUS: call FIND
        jnc .found
        jmp NOTIN
.found:
        mov dx,A(MSGIN)
        call PRINT
        xor al,al
        jmp EXIT

UNINST: call FIND
        jnc .found
        jmp NOTIN
.found:
        mov [A(QSEG)],es
        mov ax,351Ah
        int 21h
        cmp bx,A(I1A)
        jne .bad
        push es
        pop ax
        cmp ax,[A(QSEG)]
        jne .bad
        mov es,[A(QSEG)]
        cmp word [es:0],20CDh
        jne .bad
        mov ax,[A(QSEG)]
        dec ax
        mov es,ax
        mov al,[es:0]
        cmp al,'M'
        je .mcb
        cmp al,'Z'
        jne .bad
.mcb:   mov bx,[A(QSEG)]
        cmp [es:1],bx
        jne .bad
        cmp word [es:3],RESPAR
        jb .bad
        jmp short .safe
.bad:   jmp UNSAFE
.safe:
        push ds
        mov ds,bx
        mov dx,[A(OLD)]
        mov ax,[A(OLD)+2]
        mov ds,ax
        mov ax,251Ah
        int 21h
        pop ds
        mov es,[A(QSEG)]
        mov ah,49h
        int 21h
        jc .rehook
        mov dx,A(MSGGONE)
        call PRINT
        xor al,al
        jmp EXIT
.rehook:
        push ds
        mov ds,[A(QSEG)]
        mov dx,A(I1A)
        mov ax,251Ah
        int 21h
        pop ds
        mov dx,A(MSGFREE)
        call PRINT
        mov al,7
        jmp EXIT

HELP:   mov dx,A(MSGHELP)
        call PRINT
        xor al,al
        jmp EXIT

BADCMD: mov dx,A(MSGHELP)
        call PRINT
        mov al,1
        jmp EXIT

RTCBAD: mov dx,A(MSGRTC)
        call QPRINT
        mov al,3
        jmp EXIT

ENVBAD: mov dx,A(MSGENV)
        call QPRINT
        mov al,4
        jmp EXIT

ALREADY:
        mov dx,A(MSGALR)
        call QPRINT
        xor al,al
        jmp EXIT

NOTIN:  mov dx,A(MSGOUT)
        call PRINT
        mov al,5
        jmp EXIT

UNSAFE: mov dx,A(MSGCANT)
        call PRINT
        mov al,6
        jmp EXIT

EXIT:   mov ah,4Ch
        int 21h

QPRINT: cmp byte [A(QUIET)],1
        je PDONE
PRINT:  mov ah,09h
        int 21h
PDONE:  ret

ACT      db 0
QUIET    db 0
QSEG     dw 0

MSGHELP  db 'JUY2KC98 [/I [/Q]|/U|/S|/?]',13,10,'$'
MSGIN    db 'in.',13,10,'$'
MSGOUT   db 'out.',13,10,'$'
MSGALR   db 'already.',13,10,'$'
MSGGONE  db 'gone.',13,10,'$'
MSGCANT  db 'cant.',13,10,'$'
MSGFREE  db 'free no.',13,10,'$'
MSGRTC   db 'rtc no.',13,10,'$'
MSGENV   db 'env no.',13,10,'$'
