; FIO.H -- header file for I/O macros (listing suppressed)
.NOLIST      ; turn off listing

; 32-bit version with windows I/O
; R. Detmer   October 2007

; Chapman -- difficulty is that the regular registers are not large enough to 
; hold the 80 bit floating point values.

.586
EXTRN atofproc:NEAR32, ftoaproc:NEAR32


ftoa        MACRO  dest,source         ; convert floating point to ASCII string
            push   ebx                 ; save EBX
            lea    ebx, dest           ; destination address
            push   ebx                 ; destination parameter
            mov    ebx, [esp+4]        ; in case source was EBX
            mov    ebx, source         ; source value
            push   ebx                 ; source parameter
            call   ftoaproc            ; call ftoaproc(source,dest)
            add    esp, 8              ; remove parameters
            pop    ebx                 ; restore EBX
            ENDM

atof        MACRO  dest, source		   ; convert ASCII string to REAL4
            push   eax				   ; save EAX
			lea    eax,source          ; source address to EAX
            push   eax                 ; source parameter on stack
            call   atofproc            ; call atodproc(source)
			fstp   dest				   ; get answer into EAX
            add    esp, 4              ; remove parameter from the stack
			pop eax					   ; restore eax
            ENDM

.LIST        ; begin listing
