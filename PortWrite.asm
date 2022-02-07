
; OutPort : bx = Port Address, al = Byte to output
;                Z80 always takes 4 cycles to perform a port write

; esi must address RegisterBase structure on entry

INITPORTRESPOND macro
                m2m     PortTotalTStates, totaltstates  ; initial tstates counter on entry
                endm

PORTRESPOND     macro
                push    ebx
                push    eax
                push    totaltstates
                endm

ENDPORTRESPOND  macro
                mov     eax, totaltstates
                .if     eax > PortTotalTStates
                        mov     PortTotalTStates, eax   ; track greatest totaltstates exit value
                .endif
                pop     totaltstates                    ; restore for next port test
                pop     eax
                pop     ebx
                endm


align 16
OutPort:        mov     PortWriteAddress, bx
                mov     PortWriteByte,    al

                mov     PortAccessType, PORT_WRITE

                mov     currentMachine.low_port_contention, FALSE

                .if     MACHINE.HasLowPortContention == TRUE
                        mov     cx, bx
                        and     cx, 0c000h

                        .if     cx == 04000h
                                mov     currentMachine.low_port_contention, TRUE

                        .elseif cx == 0c000h
                                .if     currentMachine.CONTENTION6 == TRUE ; contended memory at 0xC000?
                                        .if     (HardwareMode == HW_128) || (HardwareMode == HW_PLUS2)
                                                mov     currentMachine.low_port_contention, TRUE
                                        .endif
                                .endif
                        .endif

                        .if     currentMachine.low_port_contention == TRUE
                                FORCECONTENTION     ; add contention for T1
                        .endif
                .endif

                ; advance to T2 of port access
                SETTS   1

                INITPORTRESPOND


                test    bl, 1
                .if     ZERO?
                        PORTRESPOND
                        call    OutPort_FE
                        ENDPORTRESPOND
                .endif


                ; ===== Fuller box specific code =====

                IFDEF   FULLER_BOX
                        .if     bl == FULLER_AY_REGISTER
                                PORTRESPOND
                                call    OutPort_FFFD
                                ENDPORTRESPOND

                        .elseif bl == FULLER_AY_DATA
                                PORTRESPOND
                                call    OutPort_BFFD
                                ENDPORTRESPOND

                        .elseif bl == FULLER_ORATOR_WR
                                PORTRESPOND
                                mov     uSpeechStatus, uSpeechReady
                                and     al, 63
                                invoke  uSpeech_WriteAllophone, al
                                ENDPORTRESPOND

                        .endif
                ENDIF

                ; ===== end Fuller box specific code =====


                ; ===== CBI specific code =====

                .if     CBI_Enabled == TRUE

                        .if     bl == 0FCh
                                mov     CBI_Port_252, al    ; maintain latch for port 252
                        .endif

                      ; Bit 7 - If = 1 disables I / O interface and enables I / O connector for expansion. If = 0, otherwise.
                        test    CBI_Port_252, (1 shl 7)
                        .if     ZERO?   ; I/O interface enabled?
                                movzx   ecx, al
                                switch  bl, edx
                                        case    01Fh
                                                PORTRESPOND
                                                wd1793_WriteCommandReg  CBIHandle, ecx
                                                SETTS   3
                                                ENDPORTRESPOND

                                        case    03Fh
                                                PORTRESPOND
                                                wd1793_WriteTrackReg    CBIHandle, ecx
                                                SETTS   3
                                                ENDPORTRESPOND

                                        case    05Fh
                                                PORTRESPOND
                                                wd1793_WriteSectorReg   CBIHandle, ecx
                                                SETTS   3
                                                ENDPORTRESPOND

                                        case    07Fh
                                                PORTRESPOND
                                                wd1793_WriteDataReg     CBIHandle, ecx
                                                SETTS   3
                                                ENDPORTRESPOND

                                        case    0FFh
                                                PORTRESPOND
                                                mov     CBI_Port_255, al
                                                wd1793_WriteSystemReg   CBIHandle, ecx
                                                ENDPORTRESPOND
                                endsw
                        .endif
                .endif

                ; ===== end CBI specific code =====

.data
align 4
trdos_status_rand   dd  1
current_trdos_cmd   db  255

.code
                ; ===== TRDOS specific code =====
                ; A0+A1 = high
                ; A7 low selects FDC, high selects System Register
                ; A5/A6 selects FDC register to read or write
                .if     (HardwareMode == HW_PENTAGON128) && TrDos_Paged
                        PORTRESPOND
                        movzx   ecx, al

                        mov     al, bl
                        and     al, 3
                        .if     al == 3
                                test    bl, 128
                                .if     ZERO?
                                        and     bl, 01100000b
                                        switch  bl
                                                case    00000000b
                                                        ;FIXME: storing this to "fix" index mark toggle in Seek command (see Status port read)
                                                        mov     current_trdos_cmd, cl

                                                        IFDEF   DEBUGBUILD
                                                                ADDMESSAGEDEC  "TRDOS Command: ",ecx
                                                        ENDIF

                                                        mov     PortDeviceType, TRDOS_COMMAND_REGISTER
                                                        wd1793_WriteCommandReg  TRDOSHandle, ecx
                                                        SETTS   3

                                                case    00100000b
                                                        mov     PortDeviceType, TRDOS_TRACK_REGISTER
                                                        wd1793_WriteTrackReg    TRDOSHandle, ecx
                                                        SETTS   3

                                                case    01000000b
                                                        mov     PortDeviceType, TRDOS_SECTOR_REGISTER
                                                        wd1793_WriteSectorReg   TRDOSHandle, ecx
                                                        SETTS   3

                                                case    01100000b
                                                        mov     PortDeviceType, TRDOS_DATA_REGISTER
                                                        wd1793_WriteDataReg     TRDOSHandle, ecx
                                                        SETTS   3
                                        endsw
                                .else
                                        mov     PortDeviceType, TRDOS_SYSTEM_REGISTER
                                        wd1793_WriteSystemReg   TRDOSHandle, ecx
                                        SETTS   3
                                .endif
                        .endif
                        ENDPORTRESPOND
                .endif
                ; ===== end TRDOS specific code =====

                ; ===== PLUS-D specific code =====
                .if     PLUSD_Enabled == TRUE
                        movzx   ecx, al
                        switch  bl, edx
                                case    0E3h
                                        PORTRESPOND
                                        wd1793_WriteCommandReg  PLUSDHandle, ecx
                                        SETTS   3
                                        ENDPORTRESPOND

                                case    0EBh
                                        PORTRESPOND
                                        wd1793_WriteTrackReg    PLUSDHandle, ecx
                                        SETTS   3
                                        ENDPORTRESPOND

                                case    0F3h
                                        PORTRESPOND
                                        wd1793_WriteSectorReg   PLUSDHandle, ecx
                                        SETTS   3
                                        ENDPORTRESPOND

                                case    0FBh
                                        PORTRESPOND
                                        wd1793_WriteDataReg     PLUSDHandle, ecx
                                        SETTS   3
                                        ENDPORTRESPOND

                                case    0EFh
                                        PORTRESPOND
                                        wd1793_WriteSystemReg   PLUSDHandle, ecx
                                        SETTS   3
                                        ENDPORTRESPOND

                                case    0E7h
                                        PORTRESPOND
                                        invoke  PLUSD_PageOut
                                        SETTS   3
                                        ENDPORTRESPOND
                        endsw
                .endif
                ; ===== end PLUS-D specific code =====

                ; ===== DivIDE specific code =====
                .if     DivIDEEnabled == TRUE
                        .if     bl == 227
                                PORTRESPOND
                                invoke  DivIDE_ControlOUT, al
                                SETTS   3
                                ENDPORTRESPOND
                        .else
                                mov     cl, bl
                                and     cl, 227
                                .if     cl == 163
                                        PORTRESPOND
                                        movzx   ecx, al
                                        shr     bl, 2
                                        and     bl, 7
                                        switch  bl, edx
                                                case 0
                                                        IDE_WriteData           IDEHandle, ecx
                                                case 1
                                                        IDE_WriteFeature        IDEHandle, ecx
                                                case 2
                                                        IDE_WriteSectorCount    IDEHandle, ecx
                                                case 3
                                                        IDE_WriteSectorNumber   IDEHandle, ecx
                                                case 4
                                                        IDE_WriteCylinderLow    IDEHandle, ecx
                                                case 5
                                                        IDE_WriteCylinderHigh   IDEHandle, ecx
                                                case 6
                                                        IDE_WriteDrive_Head     IDEHandle, ecx
                                                case 7
                                                        IDE_WriteCommand        IDEHandle, ecx
                                        endsw
                                        SETTS   3
                                        ENDPORTRESPOND
                                .endif
                        .endif
                .endif
                ; ===== end DivIDE specific code =====

                ; ===== AY sound chip decoding =====
                .if     Emulate_AY == TRUE
                        mov     cx, bx
                        and     cx, 1100000000000010b   ; & c002
                        .if     cx == 1100000000000000b ; = c000
                                push    ecx
                                PORTRESPOND
                                call    OutPort_FFFD
                                ENDPORTRESPOND
                                pop     ecx
                        .endif

                        .if     cx == 1000000000000000b ; = 8000
                                PORTRESPOND
                                call    OutPort_BFFD
                                ENDPORTRESPOND
                        .endif
                .endif
                ; ===== end AY sound chip decoding =====


                ; ===== port 7FFD memory port decoding
                mov     cx, bx
                .if     MACHINE.Plus3_Compatible
                        and     cx, 1100000000000010b       ;& c002
                        .if     cx == 0100000000000000b     ;  4000
                                PORTRESPOND
                                call    OutPort_7FFD
                                ENDPORTRESPOND
                        .endif
                .else
                        and     cx, 1000000000000010b       ;& 8002
                        .if     cx == 0000000000000000b     ;  0000
                                PORTRESPOND
                                call    OutPort_7FFD
                                ENDPORTRESPOND
                        .endif
                .endif
                ; ===== end port 7FFD memory port decoding


                ; ===== +3 specific code =====
                .if     MACHINE.Plus3_Compatible
                        mov     cx, bx
                        and     cx, 1111000000000010b       ; f002

                        .if     cx == 0001000000000000b     ; 1000 ; port 1FFD
                                push    ecx
                                PORTRESPOND
                                call    OutPort_1FFD
                                ENDPORTRESPOND
                                pop     ecx
                        .endif

                        .if     cx == 0011000000000000b     ; 3000 ; port 3FFD
                                PORTRESPOND
                                invoke  u765_DataPortWrite, FDCHandle, al
                                SETTS   3
                                ENDPORTRESPOND
                        .endif
                .endif
                ; ===== end +3 specific code =====

                ; ===== TC2048 specific code =====
                .if     HardwareMode == HW_TC2048
                        .if     bl == 0FFh
                                PORTRESPOND
                                invoke  Timex_Write_FF, al
                                FORCECONTENTION
                                SETTS   3
                                ENDPORTRESPOND

                        .elseif bl == 0F5h
                                PORTRESPOND
                                call    OutPort_FFFD
                                ENDPORTRESPOND

                        .elseif bl == 0F6h
                                PORTRESPOND
                                call    OutPort_BFFD
                                ENDPORTRESPOND
                        .endif
                .endif
                ; ===== end TC2048 specific code =====

                .if     (bl == 0DFh) && (SpecDrum_Enabled == TRUE)
                        mov     SpecDrum_LastVol, al    ; used when saving to SpecDrum SZX blocks

                        movzx   ecx, al
                        shl     ecx, 7              ; 0 to 32640
                        sub     ecx, 128 shl 7      ; -16384 to 16256
                        mov     SpecDrum_Output, cx
                .endif

                .if     (bl == 0FBh) && (Covox_Enabled == TRUE) && (HardwareMode == HW_PENTAGON128)
                        mov     Covox_LastVol, al    ; used when saving to Covox SZX blocks

                        movzx   ecx, al
                        shl     ecx, 7              ; 0 to 32640
                        sub     ecx, 128 shl 7      ; -16384 to 16256
                        mov     Covox_Output, cx
                .endif

                ; ===== ULAplus specific code =====
                .if     ULAplus_Enabled == TRUE
                        .if     bx == 0FF3Bh
                              ; 0xFF3B is the data (read/write)
                                PORTRESPOND
                                .if     MACHINE.Plus3_Compatible == False
                                        FORCECONTENTION         ; T2 is contended as for normal ULA writes
                                .endif
                                RENDERCYCLES
                                invoke  ULAplus_WriteData, al
                                SETTS   3
                                ENDPORTRESPOND

                        .elseif bx == 0BF3Bh
                                ; 0xBF3B is the register port (write only)
                                PORTRESPOND
                                .if     MACHINE.Plus3_Compatible == False
                                        FORCECONTENTION         ; T2 is contended as for normal ULA writes
                                .endif
                                RENDERCYCLES
                                invoke  ULAplus_WriteReg, al
                                SETTS   3
                                ENDPORTRESPOND
                        .endif
                .endif
                ; ===== end ULAplus specific code =====

                ;  ===== Multiface specific code =====
                .if     MultifacePaged == TRUE
                        .if		bl == 03Fh
                                mov   Multiface_LockOut, TRUE   ; for MF128 + MF3
                        .elseif	bl == 0BFh
        				        mov   Multiface_LockOut, FALSE  ; for MF128 + MF3
                        .elseif bl == 01Fh                      ; MF1
;                               mov   Multiface_LockOut, TRUE   ; reset FF_NMI_PENDING: terminates NMI signal
                        .endif
                .endif
        		;  ===== end Multiface specific code =====


;                High byte in 0x40 (0xc0) to 0x7f (0xff)?    Low bit    Contention pattern
;                                   No                          0       N:1, C:3
;                                   No                          1       N:4
;                                   Yes                         0       C:1, C:3
;                                   Yes                         1       C:1, C:1, C:1, C:1

                ; if (( wPort & 0xc000 ) == 0x4000 ) & not ULA port  // high byte between $40 and $7f
                ; then io:1, io:1, io:1, io:1
                PORTRESPOND
                test    bl, 1
                .if     !ZERO?
                        .if         currentMachine.low_port_contention == TRUE
                                    FORCEMULTICONTENTION    3
                        .else
                                    SETTS   3
                        .endif
                .else
                        FORCECONTENTION
                        SETTS   3
                .endif
                ENDPORTRESPOND

                ; exit with the latest tstates counter from all activated ports (highest contention)
                m2m     totaltstates, PortTotalTStates
                ret

;--------------------------------------------------------------------------------

; * AY registers >= 16 behave as a floating AY register
; see https://www.worldofspectrum.org/forums/discussion/23327/

align 16
OutPort_FFFD:   add     totaltstates, 3

                ifc     al gt 16 then mov al, 16    ; ceiling at 16th AY register
                mov     SCSelectReg, al
                ret

align 16
OutPort_BFFD:   add     totaltstates, 3

                movzx   ebx, byte ptr [SCSelectReg] ; 0 - 16
                and     al, [AYWriteMask+ebx]
                mov     [AYShadowRegisters+ebx], al

                ifc     ebx gt 15 then ret

                mov     [SCRegister0+ebx], al

                cmp     ebx, 6
                je      InitAYReg6

                cmp     ebx, 13
                je      InitAYReg13
                ret

InitAYReg6:     cmp     al, 1
                adc     al, 0
                mov     [InternalR6], al
                ret

InitAYReg13:    mov     EnvCounter, 0       ; writing to R13 resets the envelope counter

                IFNDEF  WANTSOUND
                ret

                ELSE
                movzx   ebx, byte ptr [SCRegister13]
                and     ebx, 15
                jmp     [InitEnvVectors+ebx*4]

.data
Align 16
InitEnvVectors  dd      InitEnv0, InitEnv1, InitEnv2,  InitEnv3,  InitEnv4,  InitEnv5,  InitEnv6,  InitEnv7
                dd      InitEnv8, InitEnv9, InitEnv10, InitEnv11, InitEnv12, InitEnv13, InitEnv14, InitEnv15

.code
InitEnv0:
InitEnv1:
InitEnv2:
InitEnv3:       mov     EnvMode, env_DECAY
                mov     EnvVolume, 15
                ret

InitEnv4:
InitEnv5:
InitEnv6:
InitEnv7:       mov     EnvMode, env_ATTACK
                mov     EnvVolume, 0
                ret

InitEnv8:
InitEnv9:
InitEnv10:
InitEnv11:      mov     EnvMode, env_DECAY
                mov     EnvVolume, 15
                ret

InitEnv12:
InitEnv13:
InitEnv14:
InitEnv15:      mov     EnvMode, env_ATTACK
                mov     EnvVolume, 0
                ret
                ENDIF

.const
align 4
                            ; copied to spk_mic_output_table on Machine initialisation
                            ; Pentagon adjusts spk:0, mic:1 value to produce sound for MIC bit alone active
spk_mic_output_defaults     dw      BEEPERLOW                   ; spk:0, mic:0
                            dw      BEEPERLOW                   ; spk:0, mic:1
                            dw      BEEPERHIGH                  ; spk:1, mic:0
                            dw      BEEPERHIGH + BEEPERMICBOOST ; spk:1, mic:1
SPK_MIC_OUTPUT_SIZEOF       equ     $ - spk_mic_output_defaults

                            IF      SPK_MIC_OUTPUT_SIZEOF ne 8
                                    .err    <SPK_MIC_OUTPUT_SIZEOF ne 8>
                            ENDIF

.data?
align 16
spk_mic_output_table        byte    SPK_MIC_OUTPUT_SIZEOF dup (?)

.code
align 16
SetPort_FE:                 push    ebx
                            mov     Last_FE_Write, al

                            .if     (RealTapeMode == FALSE) && (TapePlaying == FALSE)
                                    .if     MACHINE.Plus3_Compatible
                                            mov     EarBit, 0
                                    .elseif HardwareMode == HW_TK90X    ; Input port $FE bit 6: default value 1 (when there's no input signal) in both TK90X and TK95 (http://www.worldofspectrum.org/forums/showpost.php?p=624143&postcount=2)
                                            mov     EarBit, 64
                                    .else
                                            mov     bl, al
                                            .if     (Issue3Keyboard == TRUE) || (HardwareMode >= HW_128)
                                                    and     bl, 00010000b
                                            .else
                                                    and     bl, 00011000b
                                            .endif
                                            setnz   cl
                                            shl     cl, 6
                                            mov     EarBit, cl
                                    .endif
                            .endif

                            test    al, 8
                            setnz   MICVal

                            movzx   ebx, al
                            shr     ebx, 2     ; (spk:mic) >> bits 2:1
                            and     ebx, 6     ; (spk:mic) * 2

                            mov     ax, word ptr [spk_mic_output_table + ebx]
                            mov     BeepVal, ax

                            pop     ebx
                            ret

align 16
                ; Port FE is contended on T2
OutPort_FE:     mov     PortDeviceType, ULA_FE

                call    SetPort_FE

                .if     MACHINE.Plus3_Compatible == False
                        FORCECONTENTION		; force contention on T2
                .endif

                ; now change border colour
                switch  HardwareMode
                        case    HW_TC2048
                                invoke  Set_Timex_Border_Colour, Last_FE_Write
                        .else
                                mov     al, Last_FE_Write
                                and     al, 7
                                add     al, CLR_SPECBASE

                                .if     al != byte ptr [SPGfx.BorderColour]
                                        RENDERCYCLES
                                .endif
                endsw

                mov     al, Last_FE_Write
                call    Set_BorderColour
                SETTS   3
                ret


Set_BorderColour:
                push	eax
                push	ebx
                push    ecx

                and     al, 7
                mov     cl, al

                mov     Reg_Border, al  ; always maintain for snapshot loading/saving

                add     al, CLR_SPECBASE
                mov	    ah, al
                mov 	bx, ax
                shl 	eax, 16
                mov 	ax, bx
                mov 	[SPGfx.BorderColour], eax

                mov     al, cl
                call    Set_Border_64

                pop     ecx
                pop     ebx
                pop     eax
                ret

Set_Border_64:  push    ebx

                movzx   eax, al
                and     eax, 7
                add     eax, 8              ; PAPER colour in the first CLUT
                mov     al, [ULAplusPalette+eax]

                mov     ah, al
                mov     bx, ax
                shl     eax, 16
                mov     ax, bx
                mov     [SPGfx.ULAPlusBorderColour], eax

        		pop     ebx
                ret

Set_SpeakerState:
                test    al, 16              ; bit 4 = SPK
                jz      Speaker_High        ; active low

Speaker_Low:    mov     BeepVal, BEEPERLOW
                ret

Speaker_High:   mov     BeepVal, BEEPERHIGH
                ret


align 16
OutPort_1FFD:   mov     PortDeviceType, PAGING_1FFD
                add     totaltstates, 3

                cmp     MACHINE.Plus3_Compatible, True
                je      Port1FFD_1
                ret

Port1FFD_1:     test    Last7FFDWrite, 32   ; if bit 5 = 1, then lock out all paging
                jz      Do_Out1FFD
                ret

Do_Out1FFD:     mov     Last1FFDWrite, al

                push    eax
                invoke  u765_SetMotorState, FDCHandle, al
                pop     eax

                test    al, 1
                jnz     Switch64KRamMode

                ; page correct RAM pages at #4000 - #BFFF
                mov     eax, currentMachine.bank5
                mov     currentMachine.RAMREAD2,  eax
                mov     currentMachine.RAMWRITE2, eax
                add     eax, 8192
                mov     currentMachine.RAMREAD3,  eax
                mov     currentMachine.RAMWRITE3, eax

                mov     currentMachine.CONTENTION2, True
                mov     currentMachine.CONTENTION3, True

                mov     eax, currentMachine.bank2
                mov     currentMachine.RAMREAD4,  eax
                mov     currentMachine.RAMWRITE4, eax
                add     eax, 8192
                mov     currentMachine.RAMREAD5,  eax
                mov     currentMachine.RAMWRITE5, eax

                mov     currentMachine.CONTENTION4, False
                mov     currentMachine.CONTENTION5, False

                ; now need to page in the correct RAM @ #C000, ROM and display
                mov     al, Last7FFDWrite
                jmp     Paging_128


.data
align 16
SpecialRamConfig    dd  currentMachine.bank0, currentMachine.bank1, currentMachine.bank2, currentMachine.bank3
                    dd  currentMachine.bank4, currentMachine.bank5, currentMachine.bank6, currentMachine.bank7
                    dd  currentMachine.bank4, currentMachine.bank5, currentMachine.bank6, currentMachine.bank3
                    dd  currentMachine.bank4, currentMachine.bank7, currentMachine.bank6, currentMachine.bank3

SpecialContConfig   dd  FALSE, FALSE, FALSE, FALSE  ; 0/1/2/3
                    dd  TRUE,  TRUE,  TRUE,  TRUE   ; 4/5/6/7
                    dd  TRUE,  TRUE,  TRUE,  FALSE  ; 4/5/6/3
                    dd  TRUE,  TRUE,  TRUE,  FALSE  ; 4/7/6/3

.code
align 16
Switch64KRamMode: ; put +3 into 64K ram mode
                push    esi
                and     eax, 6      ; bb << 1
                shl     eax, 3      ; bb << 4 for 16 * 64K RAM selector bits

                lea     edi, currentMachine.RAMREAD0            ; do RAMREADs on pass 1
                SETLOOP 2
                        lea     esi, [SpecialRamConfig+eax]
                        SETLOOP 4
                                mov     ecx, [esi]
                                add     esi, 4
                                mov     ecx, [ecx]              ; dereference the currentMachine bank pointer

                                mov     [edi], ecx
                                add     ecx, 8192
                                mov     [edi+4], ecx
                                add     edi, 8
                        ENDLOOP
                        lea     edi, currentMachine.RAMWRITE0   ; do RAMWRITESs on pass 2
                ENDLOOP

                ; now update contended banks status
                lea     esi, [SpecialContConfig+eax]
                lea     edi, currentMachine.CONTENTION0
                SETLOOP 4
                        mov     ecx, [esi]
                        add     esi, 4

                        mov     [edi],   ecx
                        mov     [edi+4], ecx
                        add     edi, 8
                ENDLOOP

                pop     esi
                mov     MultifacePaged, FALSE

                ret

Align 16
OutPort_7FFD:   mov     PortDeviceType, PAGING_7FFD

                mov     bl, HardwareMode
                cmp     bl, HW_128
                je      Port7FFD_128

                cmp     bl, HW_PLUS2
                je      Port7FFD_128

                cmp     bl, HW_PENTAGON128
                je      Port7FFD_128

                cmp     bl, HW_PLUS2A
                je      Port7FFD_Plus3

                cmp     bl, HW_PLUS3
                je      Port7FFD_Plus3

                add     totaltstates, 3
                ret

Port7FFD_128:   call    Port7FFD_Contention

                test    Last7FFDWrite, 32
                je      Paging_128
                ret


align 16
; +3 paging is also done here if not in 64K RAM mode
Paging_128:     mov     Last7FFDWrite, al

                ; page ram - C000-FFFF
                and     eax, 7
                xor     ecx, ecx

                .if     MACHINE.Plus3_Compatible
                        ; +2A/+3 - pages 4-7 are contended
                        cmp     al, 4
                        setnc   cl
                .else
                        ; 128K/+2 - odd numbered ram pages are contended
                        test    al, 1
                        setnz   cl
                .endif

                mov     currentMachine.CONTENTION6, ecx
                mov     currentMachine.CONTENTION7, ecx

                mov     eax, [currentMachine.bank_ptrs+eax*4]
                mov     currentMachine.RAMREAD6,  eax
                mov     currentMachine.RAMWRITE6, eax
                add     eax, 8192
                mov     currentMachine.RAMREAD7,  eax
                mov     currentMachine.RAMWRITE7, eax

                invoke  SetSnowEffect   ; is the I register now addressing contended memory?

                .if     DivIDEEnabled == TRUE
                        .if     (DivIDE.Mapped == FALSE) && (DivIDE.PortValue < DIVIDE_CONMEM)
                                mov     al, Last7FFDWrite
                                call    Page_ROM
                        .endif

                .elseif HardwareMode == HW_PENTAGON128
                        .if     TrDos_Paged == FALSE
                                mov     al, Last7FFDWrite
                                call    Page_ROM
                        .endif

                .elseif PLUSD_Enabled == TRUE
                        .if     PLUSD_Paged == FALSE
                                mov     al, Last7FFDWrite
                                call    Page_ROM
                        .endif
                .else
                        .if     (MultifacePaged == FALSE) && (SoftRomPaged == FALSE)
                                mov     al, Last7FFDWrite
                                call    Page_ROM
                        .endif
                .endif

                mov     al, Last7FFDWrite
                jmp     Page_Display


Port7FFD_Plus3: call    Port7FFD_Contention

                test    Last7FFDWrite, 32   ; paging enabled?
                je  	@F
                ret

@@:             mov     Last7FFDWrite, al   ; needs updating incase we're currently in 64K RAM mode

                test    Last1FFDWrite, 1    ; is Plus3 in normal paging mode?
                je      Paging_128          ; normal 128K paging if so
                jmp     Page_Display        ; else only page the display


align 16
              ; this routine must preserve ebx
Page_ROM:       movzx   ecx, al
                and     ecx, 16
                shl     ecx, 10     ; ecx = 0 or 16384

                switch  HardwareMode
                        case    HW_16..HW_48
                                lea     edx, Rom_48
                                xor     ecx, ecx       ; no offset to ROM 1 for 48K
                        case    HW_128
                                lea     edx, Rom_128
                        case    HW_PLUS2
                                lea     edx, Rom_Plus2
                        case    HW_PLUS2A, HW_PLUS3
                                lea     edx, Rom_Plus3
                                test    Last1FFDWrite, 4
                                .if     !ZERO?
                                        lea     edx, Rom_Plus3+32768    ; ROM 2 or 3
                                .endif
                        case    HW_PENTAGON128
                                lea     edx, Rom_Pentagon128
                        case    HW_TC2048
                                lea     edx, Rom_TC2048
                                xor     ecx, ecx       ; no offset to ROM 1 for TC2048
                        case    HW_TK90X
                                lea     edx, Rom_TK90x
                                xor     ecx, ecx       ; no offset to ROM 1 for TK90X
                endsw

                add     edx, ecx
                mov     currentMachine.RAMREAD0, edx
                add     edx, 8192
                mov     currentMachine.RAMREAD1, edx
                mov     currentMachine.RAMWRITE0, offset DummyMem
                mov     currentMachine.RAMWRITE1, offset DummyMem
                ret

align 16
Page_Display:   mov     edx, currentMachine.bank5
                test    al, 8
                setne   SPGfx.CurrScreen
                cmovne  edx, currentMachine.bank7
                mov     SPGfx.zxDisplayOrg, edx
                ret

; al = byte written to port $7FFD (and must be preserved here)
align 16
Port7FFD_Contention:
                ; this contention is now applied at the end of the port write code

;                High byte in 0x40 (0xc0) to 0x7f (0xff)?    Low bit    Contention pattern
;                                   No                          0       N:1, C:3
;                                   No                          1       N:4
;                                   Yes                         0       C:1, C:3
;                                   Yes                         1       C:1, C:1, C:1, C:1

; https://www.worldofspectrum.org/forums/discussion/46834/

;          contention btime   btime  stime   stime   atime   atime   ptime   ptime   ptime
;             start   aligned last   visible invis.  invis.  visible invis.  visible sizes afterwards
;48K          14336   14112   14115   14335   14336   14335   14336    N/A     N/A                       (early timings, add +1 for late)
;128K, +2     14362   14134   14137   14361   14362   14361   14362   14358   14359  2x2,4x8,6x8,8x8,... (early timings, add +1 for late)
;+2A, +3      14362   14137   14140   14363   14364   14363   14364   14364   14365  1x2,2x6,3x2,4x6,...
;Pentagon     17984*  17762   17762   17983   17984   17983   17984   17984   17985  1x4,2x4,3x4,4x4,...
;
;* There is no contention on Pentagon - in this case this is simply when reading from 0x4000/5800 starts.

; Screen flips after contention on final IO cycle

                mov     ch, al
                mov     cl, Last7FFDWrite
                and     cx, 0808h                   ; trap old and new screen bits
                .if     ch != cl
                        push    totaltstates

                        .if     MACHINE.Plus3_Compatible
                                SETTS   2                   ; +2A/+3 verified with ptime test
                        .elseif (HardwareMode == HW_PENTAGON128)
                                SETTS   1                   ; ??
                        .else
                                test    PortWriteAddress, 1
                                .if     !ZERO?
                                        .if         currentMachine.low_port_contention
                                                    ; C:1, C:1, C
                                                    FORCEMULTICONTENTION    2                   ; 128k/+2 verified with ptime test
                                                    FORCECONTENTION                             ; apply any contention on final cycle
                                        .else
                                                    ; N:2
                                                    SETTS   2
                                        .endif
                                .else
                                        ; C:2
                                        FORCECONTENTION
                                        SETTS   2
                                .endif
                        .endif

                        RENDERCYCLES                ; render now if screen is flipping

                        pop     totaltstates
                .endif
                ret

.data
align 16
AYWriteMask     db      255, 15         ; R0-1
                db      255, 15         ; R2-3
                db      255, 15         ; R4-5
                db      31              ; R6
                db      255             ; R7
                db      31,  31,  31    ; R8-9-10
                db      255, 255        ; R11-12
                db      15              ; R13
                db      255, 255        ; R14-15

                db      255             ; R16, floating AY register mask
.code


