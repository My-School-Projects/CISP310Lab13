; Author:
; Date:
; This is the Visual Studio 2012 version

; Preprocessor directives
.586		; use the 80586 set of instructions
.MODEL FLAT	; use the flat memory model (only 32 bit addresses, no segment:offset)

; External source files
INCLUDE io.h   ; header file for input/output
INCLUDE fio.h  ; header file for floating point conversions to and from ASCII

; Stack configuration
.STACK 4096	   ; allocate 4096 bytes for the stack

; Named memory allocation and initialization
; Use REAL4 for floating point values
.DATA
number				REAL4	3.45
numberStr			BYTE	12 DUP (?)

anotherNumberStr	BYTE	"-0.004567"
anotherNumber		REAL4	?

; procedure definitions
.CODE
_MainProc PROC

	; test ftoa, look at numberStr value after this
	ftoa numberStr, number

	; test atof, look at anotherNumber value after this
	atof anotherNumber, anotherNumberStr

done:
        mov     eax, 0  ; exit with return code 0
        ret
_MainProc ENDP

END   ; end of source code