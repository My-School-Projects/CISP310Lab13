; floating point to ASCII code
; author: R. Detmer
; revised: 7/2008
.586
.MODEL FLAT
.STACK  4096

; procedure ftoaproc(source, result)
; convert floating point number to ASCII string 
; Parameters passed on the stack:
;   (1) 32-bit floating point value
;   (2) address of ASCII destination string
; ASCII string with format [blank/-]d.dddddE[+/-]dd is generated.
; (The string is always 12 characters long.)

.DATA
ten       REAL4  10.0
one       REAL4  1.0
round     REAL4  0.000005
digit     DWORD  ?
exponent  DWORD  ?
byteTen   BYTE   10

.CODE
ftoaproc  PROC
          push ebp              ; establish stack frame
          mov  ebp, esp
          push eax              ; save registers
          push ebx
          push ecx
          push edi

          finit                 ; initialize FPU
          mov  edi, [ebp+12]    ; destination string address
          fld  REAL4 PTR [ebp+8]  ; value to ST 
          ftst                  ; value >= 0?
          fstsw  ax             ; status word to AX
          sahf                  ; condition code bits to flags
          jnae elseNeg          ; skip if negative
          mov  BYTE PTR [edi], ' '  ; blank for positive
          jmp  endifNeg         ; exit if
elseNeg:  mov  BYTE PTR [edi], '-'  ; minus for negative
          fchs                  ; make number positive
endifNeg:
          inc  edi              ; point at next destination byte

          mov  exponent, 0      ; exponent := 0
          ftst                  ; value = 0?
          fstsw ax              ; status word to AX
          sahf                  ; condition code bits to flags
          jz   endifZero        ; skip if zero
          fcom ten              ; value > 10?
          fstsw ax              ; status word to AX
          sahf                  ; condition code bits to flags
          jnae elseLess         ; skip if value not >= 10
untilLess:
          fdiv ten              ; value := value/10
          inc  exponent         ; add 1 to exponent
          fcom ten              ; value < 10?
          fstsw ax              ; status word to AX
          sahf                  ; condition code bits to flags
          jnb  untilLess        ; continue until value < 10
          jmp  endifBigger      ; exit if
elseLess:
whileLess:
          fcom one              ; value < 1?
          fstsw ax              ; status word to AX
          sahf                  ; condition code bits to flags
          jnb  endwhileLess     ; exit if not less
          fmul ten              ; value := 10*value
          dec  exponent         ; subtract 1 from exponent
          jmp  whileLess        ; continue while value < 1
endwhileLess:
endifBigger:
endifZero:

          fadd round            ; add rounding value
          fcom ten              ; value > 10?
          fstsw ax              ; status word to AX
          sahf                  ; condition code bits to flags
          jnae endifOver        ; skip if not
          fdiv ten              ; value := value/10
          inc  exponent         ; add 1 to exponent
endifOver:

; at this point 1.0 <= value < 10.0 (or value = 0.0)
          fld  st               ; copy value
          fisttp digit           ; store integer part
          mov  ebx, digit       ; copy integer to EBX
          or   ebx, 30h         ; convert digit to character
          mov  BYTE PTR [edi], bl  ; store character in destination
          inc  edi              ; point at next destination byte
          mov  BYTE PTR [edi], '.'     ; decimal point
          inc  edi              ; point at next destination byte
          
          mov  ecx, 5           ; count of remaining digits
forDigit: fisub digit           ; subtract integer part
          fmul ten              ; multiply by 10
          fld  st               ; copy value
          fisttp digit          ; store integer part
          mov  ebx, digit       ; copy integer to EBX
          or   ebx, 30h         ; convert digit to character
          mov  BYTE PTR [edi], bl  ; store character in destination
          inc  edi              ; point at next destination byte
          loop forDigit         ; repeat 5 times

          mov  BYTE PTR [edi], 'E'  ; exponent indicator
          inc  edi              ; point at next destination byte
          mov  eax, exponent    ; get exponent
          cmp  eax, 0           ; exponent >= 0 ?
          jnge NegExp
          mov  BYTE PTR [edi], '+'  ; non-negative exponent
          jmp  endifNegExp
NegExp:   mov  BYTE PTR [edi], '-'  ; negative exponent
          neg  eax              ; change exponent to positive
endifNegExp:
          inc  edi              ; point at next destination byte

          div  byteTen          ; convert exponent to 2 digits
          or   eax, 3030h       ; convert both digits to ASCII
          mov  BYTE PTR [edi], al  ; store characters in destination
          mov  BYTE PTR [edi+1], ah

          pop  edi              ; restore registers
          pop  ecx
          pop  ebx
          pop  eax
          pop  ebp
          ret                   ; return
ftoaproc  ENDP

atofproc  PROC
; convert ASCII string to floating point number
; Parameter passed on the stack: address of ASCII source string
; After an optional leading minus sign, only digits 0-9 and a decimal
; point are accepted -- the scan terminates with any other character.
; The floating point value is returned in ST.
; Local variables are stored on the stack:
;   ten    [EBP-4]  -- always 10 after initial code
;   point  [EBP-8]  -- Boolean, -1 for true, 0 for false
;   minus  [EBP-12] -- Boolean, -1 for true, 0 for false
;   digit  [EBP-16] -- next digit as an integer

          push ebp                      ; establish stack frame
          mov  ebp, esp
          sub  esp, 16                  ; stack space for local variables
          push eax                      ; save registers
          push esi

          mov  DWORD PTR [ebp-4], 10    ; ten := 10
          fld1                          ; divisor := 1.0
          fldz                          ; value := 0.0
          mov  DWORD PTR [ebp-8], 0     ; point := false
          mov  DWORD PTR [ebp-12], 0    ; minus := false
          mov  esi, [ebp+8]             ; address of first source character
          cmp  BYTE PTR [esi], '-'      ; leading minus sign?
          jne  endifMinus               ; skip if not
          mov  DWORD PTR [ebp-12], -1   ; minus := true
          inc  esi                      ; point at next source character
endifMinus:
          
whileOK:  mov  al, [esi]                ; get next character
          cmp  al, '.'                  ; decimal point?
          jne  endifPoint               ; skip if not
          mov  DWORD PTR [ebp-8], -1    ; point := true
          jmp  nextChar
endifPoint:
          cmp  al, '0'                  ; character >= '0'
          jnge endwhileOK               ; exit if not
          cmp  al, '9'                  ; character <= '9'
          jnle endwhileOK               ; exit if not
          and  eax, 0000000fh           ; convert ASCII to integer value
          mov  DWORD PTR [ebp-16], eax  ; put integer in memory
          fimul DWORD PTR [ebp-4]       ; value := value * 10
          fiadd DWORD PTR [ebp-16]      ; value := value + digit
          cmp  DWORD PTR [ebp-8], -1    ; already found a decimal point?
          jne  endifDec                 ; skip if not
          fxch                          ; put divisor in ST and value in ST(1)
          fimul DWORD PTR [ebp-4]       ; divisor := divisor * 10
          fxch                          ; value to ST; divisor back to ST(1)
endifDec:
nextChar: inc  esi                      ; point at next source character
          jmp  whileOK
endwhileOK:

          fdivr                         ; value := value / divisor
          cmp  DWORD PTR [ebp-12], -1   ; was there a minus sign?
          jne  endifNeg
          fchs                          ; value := -value
endifNeg:
          pop  esi                      ; restore registers
          pop  eax
          mov  esp, ebp
          pop  ebp
          ret                           ; return
atofproc  ENDP

          END
