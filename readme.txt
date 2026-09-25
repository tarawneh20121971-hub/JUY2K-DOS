JUY2KC98
DOS YEAR 2000 CENTURY CORRECTION

BACKGROUND

The original program was written to help protect computers at the
University of Jordan against the Year 2000 date problem. It was intended
for the DOS computers in use before the change from 1999 to 2000.
This background is supplied by the original author.

This repository preserves a current development version of that work.
It must not be mistaken for an unchanged copy of the original 1998 files.

WHAT IT DOES

JUY2KC98 stays in memory and handles requests to read the BIOS clock date.
It first asks the previous BIOS handler for the date. If that request
succeeds and the two-digit year is 00 through 94, it returns century 20.
For years 95 through 99, it leaves the returned century unchanged.
If the BIOS reports an error, the program leaves that error and date alone.

It corrects the date returned to the caller. It does not write a new date
to the hardware clock, repair stored files, or correct date calculations
inside other programs. It does not repair a missing February 29, 2000.

RUNNING UNDER DOS

Use an IBM PC compatible with DOS and a BIOS clock date service.
The program uses 8086 instructions, but this alone does not guarantee
that an early PC provides the required clock service.

Copy JUY2KC98.COM to a directory such as C:\JUY2K. No setup program is
needed. The source and assembler are not required on the target computer.

To load it manually, type:

  C:\JUY2K\JUY2KC98.COM /I

To load it on each boot, put that line early in AUTOEXEC.BAT, before
applications and resident programs that need the corrected BIOS date.
Loading the program does not copy files or change AUTOEXEC.BAT for you.

AUTOEXEC.BAT runs after the DOS kernel has loaded. This version does not
correct the internal DOS date already obtained during startup. Programs
that ask DOS for its date may therefore still receive an incorrect date.
Do not assume that loading this program protects every date reader from
the first moment of boot. Check the DOS date separately with DATE.

COMMANDS

  JUY2KC98          Load into memory.
  JUY2KC98 /I       Load into memory.
  JUY2KC98 /I /Q    Load without messages, including failure messages.
  JUY2KC98 /Q /I    Same quiet loading operation.
  JUY2KC98 /S       Report whether the program is resident.
  JUY2KC98 /U       Remove from memory when removal is safe.
  JUY2KC98 /?       Show command help.

/Q alone is an error. It cannot be combined with /S, /U or /?.
Loading twice reports already. and does not install a second copy.
Removal does not delete the COM file or its AUTOEXEC.BAT entry.
If another resident handler is above this one, removal is refused.

MESSAGES AND RETURN CODES

  in.        Loaded or found in memory.                  0
  already.   Already loaded.                             0
  gone.      Removed from memory.                        0
  Help       Requested help.                            0
  Help       Invalid command line.                      1
  rtc no.    BIOS clock check failed.                    3
  env no.    Could not release the environment block.    4
  out.       Not found in memory.                        5
  cant.      Removal refused.                           6
  free no.   Memory release failed; handler restored.    7

Quiet loading still returns a code for use with DOS ERRORLEVEL.

FILES AND BUILDING

  JUY2KC98.ASM   Assembly source.
  JUY2KC98.COM   DOS executable.
  BUILD_98.BAT  Current Windows build script.
  readme.txt   This file.

The current COM file is 769 bytes. The resident code and data occupy
48 bytes. DOS retains 19 paragraphs, or 304 bytes including the PSP.

The supplied BUILD_98.BAT is a modern Windows CMD build helper. It is
not a batch file for COMMAND.COM on the target DOS computer. The source
is currently built with NASM 3.02 on the development computer.

The uploaded files are at the repository root. To use BUILD_98.BAT
unchanged, arrange these files relative to the batch file:

  src\variants\JUY2KC98.ASM
  tools\nasm-3.02\nasm.exe

NASM is not included. The batch file creates the output and report
directories. The target DOS computer needs only the COM file.

TEST STATUS

Basic load, status, repeated load, quiet load and removal checks have
been run in DOSBox-X. Synthetic clock boundary tests and resident
handler chain tests remain pending. Broad testing on period hardware
and DOS versions has not been completed. This is a development copy,
not a claim of complete Year 2000 protection for every computer.

TEXT FORMAT

This documentation uses plain 7-bit ASCII and DOS CR/LF line endings,
without a Unicode byte order mark. Documentation files use .txt.
Assembly source and executable batch files retain .ASM and .BAT so
that the assembler and command interpreter can use them normally.
