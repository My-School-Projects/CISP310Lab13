; General comments
; Author:  
; Date: 
; This is the Visual Studio 2012/Visual C++ Express Edition 2012 version   

; Preprocessor directives
.586		; use the 80586 set of instructions
.MODEL FLAT	; use the flat memory model (only 32 bit addresses, no segment:offset)

; External source files
INCLUDE io.h   ; header file for input/output
INCLUDE fio.h  ; header file for floating point input/output

; Stack configuration
.STACK 4096	   ; allocate 4096 bytes for the stack

; Named memory allocation and initialization
.DATA
	
	; the X's are spaces which will be filled in by the ftoa macro.

	inputPrompt  BYTE "Radius: ", 0

	outputLabel  BYTE "The radius is "
	outputRadius BYTE "XXXXXXXXXXX", 0

	outputText			BYTE "The circumference is "
	outputCircumference BYTE "XXXXXXXXXXX", 0dh, 0ah
						BYTE "The area is "
	outputArea			BYTE "XXXXXXXXXXX", 0

	; more than 20 characters input is unreasonable
	inputRadius	 BYTE 20 DUP ("X")

	floatRadius REAL4 0.0

; procedure definitions
.CODE
_MainProc PROC
	
	; get radius from user

	input inputPrompt, inputRadius, 20



	; call findCircumference(radius)

	finit					; initialize f.p. registers
	
	mov eax, floatRadius	; EAX := radius

	push eax				; push parameter 1
	
	call findCircumference	; findCircumference(radius)

	pop ebx					; throw away parameter

	
	
	; call findArea(radius)

	finit					; initialize f.p. registers

	push eax				; push parameter 1

	call findArea			; findArea(radius)

	pop ebx					; throw away parameter



	mov     eax, 0  ; exit with return code 0
	
	ret
_MainProc ENDP

; findArea(float radius)

findArea PROC
	
	; establish stack frame

	push ebp		; save old EBP
	mov ebp, esp	; create reference for accessing radius (EBP + 8)
	pushfd			; save EFLAGS

	; A = pi * r^2
	
	fld REAL4 PTR [ebp + 8]	; load radius into ST(0)

	fst ST(1)				; load radius into ST(1)

	; f.p. stack:
	; ST(0) : radius
	; ST(1) : radius

	fmul					; ST(0) := radius * radius

	; f.p. stack:
	; ST(0) : radius^2

	fldpi					; load pi into ST(0)

	; f.p. stack:
	; ST(0) : pi
	; ST(1) : radius^2

	fmul					; ST(0) := pi * radius^2

	; f.p. stack:
	; ST(0) : pi * radius^2

	; restore registers
	
	popfd			; restore EFLAGS
	pop ebp
	
	; temporarily save ST(0) to the integer stack

	fst REAL4 PTR [ebp - 4]

	; wipe out f.p. registers

	finit

	; restore ST(0) from the integer stack

	fld REAL4 PTR [ebp - 4]

	ret

findArea ENDP

; findCircumference(float radius)

findCircumference PROC

	; establish stack frame

	push ebp		; save old EBP
	mov ebp, esp	; create reference for accessing radius (EBP + 8)
	pushfd			; save EFLAGS

	; C = 2 * pi * r
	
	fld REAL4 PTR [ebp + 8]	; load radius into ST(0)

	fldpi					; load pi into ST(0)

	; f.p. stack:
	; ST(0) : pi
	; ST(1) : radius

	fmul					; ST(0) := pi * radius

	fld1					; load 1.0 into ST(0)
	fld1					; (twice)

	; f.p. stack:
	; ST(0) : 1.0
	; ST(1) : 1.0
	; ST(2) : pi * radius

	fadd					; ST(0) := 1.0 + 1.0

	; f.p. stack:
	; ST(0) : 2.0
	; ST(1) : pi * radius

	fmul					; ST(0) := 2.0 * pi * radius

	; ST(0) : 2.0 * pi * radius

	; restore registers
	
	popfd			; restore EFLAGS
	pop ebp
	
	; temporarily save ST(0) to the integer stack

	fst REAL4 PTR [ebp - 4]

	; wipe out f.p. registers

	finit

	; restore ST(0) from the integer stack

	fld REAL4 PTR [ebp - 4]

	ret

findCircumference ENDP

END   ; end of source code