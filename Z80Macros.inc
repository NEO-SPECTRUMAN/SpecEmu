
; Z80 core support macros
; ------------------

; GETINDEXEDOPCODE
; ================
; reads the byte following the signed offset in indexed opcodes
; adds the 5 Tstates (internal operation) + contended cycles

; returns byte in al

; increments PC register

GETINDEXEDOPCODE    MACRO
                    push    ebx
                    movzx   ebx, Reg_PC
                    GETOPCODEBYTE                           ; read the opcode to al
                    SETTS   3                               ; 3 Ts for opcode read
                    ADDMULTICONTENTIONPC    2               ; 2 contended cycles at address of opcode read
                    add     Reg_PC, 1                       ; advance PC
                    add     Reg_InsLength, 1 ; required for disassembler
                    pop     ebx
                    ENDM

Setf5_3             MACRO   arg1
                    IFDIF	<arg1>, <al>
                    		mov   al, arg1
                    ENDIF
                    and     Reg_F, NOT @FLAGS (53)
                    and     al, @FLAGS (53)
                    or      Reg_F, al
                    ENDM

                  ; bx = base addr, al = offset
ADDOFFSET           MACRO
                    cbw                                     ; extend al to ax
                    add     bx, ax                          ; bx = effective addr
                    mov     Reg_MemPtr, bx
                    ENDM

INCBYTE             MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    inc     al
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53VN)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F, ah
                    ENDM

DECBYTE             MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    dec     al
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53V)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    or      ah, FLAG_N
                    mov     Reg_F, ah
                    ENDM

ADDBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    add     al, arg2
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53VN)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F, ah
                    ENDM

ADCBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    adc     al, arg2
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53VN)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F, ah
                    ENDM

SUBBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    sub     al, arg2
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53V)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    or      ah, FLAG_N
                    mov     Reg_F, ah
                    ENDM

SBCBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    sbb     al, arg2
                    lahf
                    seto    cl
                    mov     dl, al
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53V)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    or      ah, FLAG_N
                    mov     Reg_F, ah
                    ENDM

ANDBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    and     al, arg2
                    lahf
                    mov     dl, al
                    or      ah, FLAG_H
                    and     ah, NOT @FLAGS (53N)
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F,ah

                    test    byte ptr arg2, NOT (64+32)
                    .if     ZERO?
                            .if     (byte ptr arg2 == 32) || (byte ptr arg2 == 64)
                                    mov     SL_AND_32_64, TRUE  ; set the potential tape loader flag
                            .endif
                    .endif
                    ENDM

ORBYTE              MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    or      al, arg2
                    lahf
                    mov     dl, al
                    and     ah, NOT @FLAGS (5H3N)
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F, ah
                    ENDM

XORBYTE             MACRO   arg1,arg2
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <al>
                            mov al, arg1
                    ENDIF
                    mov     ah, Reg_F
                    sahf
                    xor     al, arg2
                    lahf
                    mov     dl, al
                    and     ah, NOT @FLAGS (5H3N)
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    mov     Reg_F, ah
                    ENDM

CMPBYTE             MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <dl>
                            mov dl, arg1
                    ENDIF
                    mov     al, Reg_A
                    mov     ah, Reg_F
                    sahf
                    cmp     al, dl
                    lahf
                    seto    cl
                    shl     cl, 2
                    and     ah, NOT @FLAGS (53V)
                    or      ah, cl
                    and     dl, @FLAGS (53)
                    or      ah, dl
                    or      ah, FLAG_N
                    mov     Reg_F, ah
                    ENDM

ADDHL               MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <cx>
                            mov     cx, arg1
                    ENDIF
                    movzx   ebx, Reg_HL
                    mov     dl,  Reg_F
                    lea     eax, [ebx+1]

                    add     bl, cl
                    mov     Reg_MemPtr, ax
                    adc     bh, ch
                    lahf

                    mov     Reg_HL, bx
                    and     dl, @FLAGS (SZV)
                    and     ah, @FLAGS (HC)
                    and     bh, @FLAGS (53)
                    or      ah, dl
                    or      ah, bh
                    mov     Reg_F, ah
                    ENDM

ADDIX               MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <cx>
                            mov     cx, arg1
                    ENDIF
                    movzx   ebx, Reg_IX
                    mov     dl,  Reg_F
                    lea     eax, [ebx+1]

                    add     bl, cl
                    mov     Reg_MemPtr, ax
                    adc     bh, ch
                    lahf

                    mov     Reg_IX, bx
                    and     dl, @FLAGS (SZV)
                    and     ah, @FLAGS (HC)
                    and     bh, @FLAGS (53)
                    or      ah, dl
                    or      ah, bh
                    mov     Reg_F, ah
                    ENDM

ADDIY               MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <cx>
                            mov     cx, arg1
                    ENDIF
                    movzx   ebx, Reg_IY
                    mov     dl,  Reg_F
                    lea     eax, [ebx+1]

                    add     bl, cl
                    mov     Reg_MemPtr, ax
                    adc     bh, ch
                    lahf

                    mov     Reg_IY, bx
                    and     dl, @FLAGS (SZV)
                    and     ah, @FLAGS (HC)
                    and     bh, @FLAGS (53)
                    or      ah, dl
                    or      ah, bh
                    mov     Reg_F, ah
                    ENDM

ADCHL               MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <cx>
                            mov     cx, arg1
                    ENDIF
                    movzx   ebx, Reg_HL
                    mov     ah,  Reg_F
                    lea     edx, [ebx+1]

                    sahf
                    adc     bl, cl
                    mov     Reg_MemPtr, dx
                    adc     bh, ch
                    lahf

                    seto    cl
                    mov     Reg_HL, bx
                    shl     cl, 2
                    and     ah, NOT @FLAGS (Z53VN)
                    or      bx, bx
                    .if     ZERO?
                            or  ah, FLAG_Z
                    .endif
                    and     bh, @FLAGS (53)
                    or      ah, cl
                    or      ah, bh
                    mov     Reg_F, ah
                    ENDM

SBCHL               MACRO   arg1
                    FLAGS_MODIFIED  TRUE
                    IFDIF	<arg1>, <cx>
                            mov     cx, arg1
                    ENDIF
                    movzx   ebx, Reg_HL
                    mov     ah,  Reg_F
                    lea     edx, [ebx+1]

                    sahf
                    sbb     bl, cl
                    mov     Reg_MemPtr, dx
                    sbb     bh, ch
                    lahf

                    seto    cl
                    mov     Reg_HL, bx
                    shl     cl, 2
                    and     ah, NOT @FLAGS (Z53V)
                    or      bx, bx
                    .if     ZERO?
                            or  ah, FLAG_Z
                    .endif
                    and     bh, @FLAGS (53)
                    or      ah, cl
                    or      ah, bh
                    or      ah, FLAG_N
                    mov     Reg_F, ah
                    ENDM


