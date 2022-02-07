
; InPort : bx = Port Address, al returns with Byte read

; esi must address RegisterBase structure on entry

align 16
InPort:         .if     rzx_mode == RZX_PLAY
                        invoke  RZX_Read_Port_Byte
                        ifc     eax ne -1 then jmp InPortExit
                .endif

                mov     PortReadAddress, bx
                mov     PortAccessType, PORT_READ
                mov     PortDeviceType, DEVICE_NONE

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

                test    bl, 1
                je      Read_KeyPorts   ; Port FE

                .if     Emulate_AY == TRUE
                        mov     cx, bx
                        and     cx, 1100000000000010b
                        cmp     cx, 1100000000000000b
                        je      Read_SCRegVal   ; Port FFFD

                        .if     MACHINE.Plus3_Compatible
                                cmp     cx, 1000000000000000b
                                je      Read_SCRegVal   ; IN (#BFFD) behaves as IN (#FFFD) on +2A/+3; needed by disks such as "Plus 3 Mate" by Lerm

;                                .if     ZERO?
;                                        movzx   eax, zPC
;                                        ADDMESSAGEDEC   "IN (#BFFD) @ ", eax
;                                        call    Read_SCRegVal
;                                        inc     al
;                                        jmp     InPortExit
;                                .endif
                        .endif
                .endif

                .if     HardwareMode == HW_PLUS3    ; machine has to be a +3 for FDD support, not just be +3 compatible (+2A)
                        mov     cx, bx
                        and     cx, 1111000000000010b

                        .if     cx == 0010000000000000b     ; Port 2FFD
                                invoke  u765_StatusPortRead, FDCHandle
                                SETTS   3
                                jmp     InPortExit

                        .elseif cx == 0011000000000000b     ; Port 3FFD
                                invoke	u765_DataPortRead, FDCHandle
                                SETTS   3
                                jmp     InPortExit
                        .endif
                .endif

                .if     MACHINE.Plus3_Compatible
                        mov     cx, bx
                        and     cx, 1111000000000010b
                        .if     cx == 0000000000000000b         ; Port 0FFD (Centronics)
                                test    Last7FFDWrite, 32       ; paging enabled?
                                .if     ZERO?
                                        mov     eax, totaltstates
                                        add     eax, 2      ; Z80 samples the data bus on the last cycle of I/O
                                        call    Read_Floating_Bus_Cycle

                                        .if     ax == 0FFFFh
                                                RENDERCYCLES
                                                mov     al, SPGfx.plus3_float_byte
                                        .endif

                                        or      al, 1
                                .else
                                        mov     al, 255     ; always 255 when paging disabled
                                .endif
                                SETTS   3
                                jmp     InPortExit
                        .endif
                .endif

                .if     HardwareMode == HW_TC2048
                        .if     bl == 0FFh
                                mov     al, Timex_Port_FF
                                FORCECONTENTION
                                SETTS   3
                                jmp     InPortExit
                        .elseif bl == 0F6h
                        .endif
                .endif


                ; ===== Fuller box specific code =====
                IFDEF   FULLER_BOX
                        cmp     bl, FULLER_AY_REGISTER
                        je      Read_SCRegVal   ; Port FFFD
                ENDIF
                ; ===== end Fuller box specific code =====


                ; ===== CBI specific code =====
                .if     CBI_Enabled == TRUE

                      ; Bit 7 - If = 1 disables I / O interface and enables I / O connector for expansion. If = 0, otherwise.
                        test    CBI_Port_252, (1 shl 7)
                        .if     ZERO?
                                switch  bl
                                        case    01Fh
                                                wd1793_ReadStatusReg    CBIHandle
                                                SETTS   3
                                                jmp     InPortExit
                                        case    03Fh
                                                wd1793_ReadTrackReg     CBIHandle
                                                SETTS   3
                                                jmp     InPortExit
                                        case    05Fh
                                                wd1793_ReadSectorReg    CBIHandle
                                                SETTS   3
                                                jmp     InPortExit
                                        case    07Fh
                                                wd1793_ReadDataReg      CBIHandle
                                                SETTS   3
                                                jmp     InPortExit
                                        case    0FFh
                                                wd1793_ReadSystemReg    CBIHandle
                                                SETTS   3
                                                jmp     InPortExit
                                endsw
                        .endif
                .endif
                ; ===== end CBI specific code =====

                ; ===== TRDOS specific code =====
                ; A0+A1 = high
                ; A7 low selects FDC, high selects System Register
                ; A5/A6 selects FDC register to read or write
                .if     (HardwareMode == HW_PENTAGON128) && (TrDos_Paged == TRUE)
                        mov     al, bl
                        and     al, 3
                        .if     al == 3
                                test    bl, 128
                                .if     ZERO?
                                        and     bl, 01100000b
                                        switch  bl
                                                case    00000000b
                                                        mov     PortDeviceType, TRDOS_STATUS_REGISTER
                                                        wd1793_ReadStatusReg    TRDOSHandle

                                                        ; FIXME: toggle index mark pulse for Seek command
                                                        .if     current_trdos_cmd == 24
                                                                rol     trdos_status_rand, 1
                                                                .if     CARRY?
                                                                        xor     al, 2
                                                                .endif
                                                        .endif

                                                        SETTS   3
                                                        jmp     InPortExit
                                                case    00100000b
                                                        mov     PortDeviceType, TRDOS_TRACK_REGISTER
                                                        wd1793_ReadTrackReg     TRDOSHandle
                                                        SETTS   3
                                                        jmp     InPortExit
                                                case    01000000b
                                                        mov     PortDeviceType, TRDOS_SECTOR_REGISTER
                                                        wd1793_ReadSectorReg    TRDOSHandle
                                                        SETTS   3
                                                        jmp     InPortExit
                                                case    01100000b
                                                        mov     PortDeviceType, TRDOS_DATA_REGISTER
                                                        wd1793_ReadDataReg      TRDOSHandle
                                                        SETTS   3
                                                        jmp     InPortExit
                                        endsw
                                .else
                                        mov     PortDeviceType, TRDOS_SYSTEM_REGISTER
                                        wd1793_ReadSystemReg    TRDOSHandle
                                        SETTS   3
                                        jmp     InPortExit
                                .endif
                        .endif
                .endif
                ; ===== end TRDOS specific code =====


                ; ===== PLUS-D specific code =====
                .if     PLUSD_Enabled == TRUE
                        switch  bl
                                case    0E3h
                                        wd1793_ReadStatusReg    PLUSDHandle
                                        SETTS   3
                                        jmp     InPortExit
                                case    0EBh
                                        wd1793_ReadTrackReg     PLUSDHandle
                                        SETTS   3
                                        jmp     InPortExit
                                case    0F3h
                                        wd1793_ReadSectorReg    PLUSDHandle
                                        SETTS   3
                                        jmp     InPortExit
                                case    0FBh
                                        wd1793_ReadDataReg      PLUSDHandle
                                        SETTS   3
                                        jmp     InPortExit
                                case    0EFh
                                        wd1793_ReadSystemReg    PLUSDHandle
                                        SETTS   3
                                        jmp     InPortExit
                                case    0E7h
                                        invoke  PLUSD_PageIn
                                        SETTS   3
                                        jmp     InPortExit
                        endsw
                .endif
                ; ===== end PLUS-D specific code =====


                ; ===== DivIDE specific code =====
                .if     DivIDEEnabled == TRUE
                        mov     cx, bx
                        and     cx, 227
                        .if     cx == 163
                                shr     bl, 2
                                and     bl, 7
                                switch  bl
                                        case 0
                                                IDE_ReadData            IDEHandle
                                        case 1
                                                IDE_ReadError           IDEHandle
                                        case 2
                                                IDE_ReadSectorCount     IDEHandle
                                        case 3
                                                IDE_ReadSectorNumber    IDEHandle
                                        case 4
                                                IDE_ReadCylinderLow     IDEHandle
                                        case 5
                                                IDE_ReadCylinderHigh    IDEHandle
                                        case 6
                                                IDE_ReadDrive_Head      IDEHandle
                                        case 7
                                                IDE_ReadStatus          IDEHandle
                                endsw
                                SETTS   3
                                jmp     InPortExit
                        .endif
                .endif
                ; ===== end DivIDE specific code =====


; Multiface 1   pages in with IN A,(#9f), pages out with IN A,(#1f) if currently paged in, else IN 31 falls through to reading Kempston joystick
; Multiface 128 pages in with IN A,(#bf), pages out with IN A,(#3f)
; Multiface 3   pages in with IN A,(#3f), pages out with IN A,(#bf)

                .if     MultifaceEnabled == TRUE
                        switch  HardwareMode
                                case    HW_16, HW_48, HW_TC2048, HW_TK90X
                                        .if     (bl == 01Fh) && (MultifacePaged == TRUE)
                                                jmp PageOutMultiface
                                        .endif
                                        ifc     bl eq 09Fh then jmp PageInMultiface

                                case    HW_128, HW_PLUS2
                                        ifc     bl eq 0BFh then jmp PageInMultiface
                                        ifc     bl eq 03Fh then jmp PageOutMultiface

                                case    HW_PLUS2A, HW_PLUS3
                                        ifc     bl eq 03Fh then jmp PageInMultiface
                                        ifc     bl eq 0BFh then jmp PageOutMultiface
                        endsw
                    .endif


                .if     bl == 1Fh
                        call    Read_Kempston_1F
                        jmp     InPortExit
                .endif

                .if     bl == 37h
                        call    Read_Kempston_37
                        jmp     InPortExit
                .endif

                ; ===== port 7FFD memory port read bug in 128K/+2
                .if     (HardwareMode == HW_128) || (HardwareMode == HW_PLUS2)
                        mov     cx, bx
                        and     cx, 1000000000000010b   ; 128K/+2: (port & 1000000000000010b) = 0000000000000000b for 0x7FFD
                        .if     ZERO?
                                call    Read_Floating_Bus

                                push    totaltstates    ; preserve current cycle count to avoid double contention being applied in OutPort_7FFD
                                call    OutPort_7FFD    ; write floating bus value to port 0x7FFD
                                pop     totaltstates    ; restore current cycle count
                                jmp     InPortExit      ; update flags
                        .endif
                .endif
                ; ===== end port 7FFD memory port read bug in 128K/+2


                ; ===== ULAplus specific code =====
                .if     ULAplus_Enabled == TRUE
                        .if     bx == 0FF3Bh
                              ; 0xFF3B is the data (read/write)
                                .if     MACHINE.Plus3_Compatible == False
                                        FORCECONTENTION         ; T2 is contended as for normal ULA reads
                                .endif
                                SETTS   3
                                invoke  ULAplus_ReadData
                                jmp     InPortExit      ; update flags
                        .endif
                .endif
                ; ===== end ULAplus specific code =====


InPortExit_Float:
                ; we reach here when reading from a non-existant port address
                call    Read_Floating_Bus


                ; IN r,(C)  SZ503P0-  Also true for IN F,(C)
InPortExit:     mov     bl, z80registers.af.lo
                and     bl, NOT @FLAGS (SZ5H3VN)
                test    al, 255
                lahf
                mov     cl, al
                and     ah, @FLAGS (SZV)        ; x86 flag bits same as Z80; V same as PF
                and     cl, @FLAGS (53)
                or      bl, ah
                or      bl, cl
                mov     z80registers.af.lo, bl  ; update Flags register

                .if     rzx_mode == RZX_RECORD
                        push    eax
                        invoke  RZX_Write_Port_Byte, al
                        pop     eax
                .endif

                mov     PortReadByte, al
                ret

align 16
Read_Floating_Bus:
                .if     MACHINE.HasLowPortContention == TRUE
                        ; if(( wPort & 0xc000 ) == 0x4000 )  // high byte between $40 and $7f
                        ; then io:1, io:1, io:1, io:1
                        .if     currentMachine.low_port_contention == TRUE
                                FORCEMULTICONTENTION    3
                        .else
                                SETTS   3
                        .endif
                .else
                        SETTS   3
                .endif

Read_Floating_Bus_No_Contend:
                .if     MACHINE.HasFloatingBus == TRUE
                        mov     Floating_Bus_Read, TRUE ; for Debug -> Run To Floating Bus Read

                        .if     in_single_step || (snow_float == FALSE)
                                ; called from debugger or snow effect floating bus disabled, can't/don't pick up real time renderer bytes
                                mov     eax, totaltstates
                                dec     eax                     ; Z80 samples the data bus on the last cycle of I/O
                                call    Read_Floating_Bus_Cycle
                        .else
                                sub     totaltstates, 2         ; adjust for renderer

                                movzx   eax, FrameSkipLoop
                                push    eax
                                mov     FrameSkipLoop, 1
                                RENDERCYCLES                    ; allow us to pick up floating bus bytes including snow effect display bytes
                                pop     eax
                                mov     FrameSkipLoop, al

                                mov     al, SPGfx.float_byte
                                add     totaltstates, 2
                                ret
                        .endif
                .else
                        mov     al, 0FFh    ; non-floating bus machines always return FF for non-existant port addresses
                .endif
                ret

Read_Floating_Bus_Cycle:    ; eax holds cycle count for floating bus read
                push    ecx
                mov     ecx, ULAReadAddress

                mov     ax, [ecx+eax*2]     ; word entry for each cycle; FFFF for border or offset into video memory
                .if     ax != 0FFFFh
                        mov     ecx, [SPGfx.zxDisplayOrg]
                        and     eax, 65535
                        mov     al, [ecx+eax]    ; current display/attribute byte
                .endif
                pop     ecx
                ret


; Source: http://www.worldofspectrum.org/forums/showpost.php?p=624143&postcount=2

; Reading from port $FE produces different results in Brazilian computers. In a nutshell:
; Input port $FE bit 7: always value 0 in TK90X, always value 1 in TK95 and ZX-Spectrum.
; Input port $FE bit 6: default value 1 (when there's no input signal) in both TK90X and TK95.
; Input port $FE bit 5: usually 1 in TK90X, but when ULA accesses a screen attribute address, it will copy bit 5 from the attribute value.
; The information above was extracted from an article by Flavio Matsumoto, based on additional information identified by Fabio Belavenuto. The complete article (in Portuguese) is available here: http://cantinhotk90x.blogspot.com.br...porta-254.html


align 16
Read_KeyPorts:  .if     MACHINE.Plus3_Compatible == False
                        FORCECONTENTION         ; T2 is contended
                .endif
                SETTS   3

                lea     ecx, SpeccyKeyPorts
                mov     ax, 08FFh

        @@:     shr     bh, 1
                .if     !CARRY?
                        and     al, [ecx]
                .endif
                inc     ecx
                dec     ah
                jnz     @B

                and     al, 31

                .if     HardwareMode == HW_TK90X
                        push    eax
                        mov     eax, totaltstates
                        sub     eax, 3          ; Z80 samples the data bus on the last cycle of I/O
                        call    Read_Floating_Bus_Cycle
                        mov     cl, al
                        pop     eax

                        and     cl, 00100000b   ; bit 5 from TK90x floating bus
                        or      al, cl
                .else
                        or      al, 10100000b   ; IN (254); bits 5 and 7 are always 1
                .endif

                or      al, EarBit  ; set by tape input or by last OUT (254) in OutPort_FE for Iss 2/3 machine
                xor     al, EarXor  ; default: 0, toggled by "tapeinvert" command in debug cmd parser
                jmp     InPortExit


align 16
Read_Kempston_37:
                lea     ecx, SpeccyKempston37
                mov     dl, JOY_KEMPSTON_37
                jmp     @F

Read_Kempston_1F:
                lea     ecx, SpeccyKempston1F
                mov     dl, JOY_KEMPSTON_1F

                ; return valid Kempston data if a joystick interface is set to Kempston emulation
@@:             xor     dh, dh
                lea     eax, Joystick1

                ; dh = count of pads emulating requested Kempston port
                SETLOOP 4
                        .if     [eax].JOYSTICKINFO.Joystick_Type == dl
                                inc     dh
                        .endif
                        add     eax, sizeof JOYSTICKINFO
                ENDLOOP

                ; Kempston pad count > 0 ?
                .if     dh > 0
                        .if     currentMachine.low_port_contention
                                FORCEMULTICONTENTION    3
                        .else
                                SETTS   3
                        .endif

                        ; read kempston input - [SpeccyKempston1F] or [SpeccyKempston37]
                        mov     al, [ecx]
                        ret
                .endif

                ; else treat as non-existant port
                call    Read_Floating_Bus
                ret


align 16
Read_SCRegVal:  add     totaltstates, 3

                movzx   eax, SCSelectReg
                cmp     eax, 14
                je      Read_SCR14

                cmp     eax, 15
                je      Read_SCR15

                mov     al, [AYShadowRegisters+eax]
                jmp     InPortExit

.data
AY_Port_Input   db  255 ; input on AY port 14
.code

                ;The AY I/O ports return input directly from the port when in
                ;input mode; but in output mode, they return an AND between the
                ;register value and the port input. So, allow for this when
                ;reading R14...

align 16
Read_SCR14:     test    SCRegister7, 64
                .if     !ZERO?
                        mov     al, SCRegister14
                        and     al, AY_Port_Input
                .else
                        mov     al, AY_Port_Input
                .endif
                jmp     InPortExit

                ;R15 is simpler to do, as the 8912 lacks the second I/O port, and
                ;the input-mode input is always 0xff */

align 16
Read_SCR15:     test    SCRegister7, 128    ; bit 7: 0 = input, 1 = output
                mov     al, 255
                jz      InPortExit          ; input mode always returns 255

                mov     al, SCRegister15    ; output mode always returns last written byte
                jmp     InPortExit

align 16
PageInMultiface:
                add     totaltstates, 3
                switch  HardwareMode
                        case    HW_16, HW_48, HW_TC2048, HW_TK90X
                                .if     (GotMultiface48Rom == TRUE) && (Multiface_LockOut == FALSE)
                                        mov     currentMachine.RAMREAD0,  offset Mf48_Mem
                                        mov     currentMachine.RAMREAD1,  offset Mf48_Mem+8192
                                        mov     currentMachine.RAMWRITE0, offset DummyMem
                                        mov     currentMachine.RAMWRITE1, offset Mf48_Mem+8192
                                        mov     MultifacePaged, TRUE
                                        call    Read_Kempston_1F
                                        jmp     InPortExit
                                .endif

                        case    HW_PLUS2A, HW_PLUS3
                                .if     (GotMultiface3Rom == TRUE) && (Multiface_LockOut == FALSE)
                                        test    Last1FFDWrite, 1
                                        .if     !ZERO?
                                                ; return 255 if in 64K ram mode
                                                mov     al, 255
                                                jmp     InPortExit
                                        .endif

                                        mov     currentMachine.RAMREAD0,   offset Mf3_Mem
                                        mov     currentMachine.RAMREAD1,   offset Mf3_Mem+8192
                                        mov     currentMachine.RAMWRITE0,  offset DummyMem
                                        mov     currentMachine.RAMWRITE1,  offset Mf3_Mem+8192
                                        mov     MultifacePaged, TRUE

                                        .if     bh == 7Fh
                                                mov     al, Last7FFDWrite
                                        .elseif bh == 1Fh
                                                mov     al, Last1FFDWrite
                                        .else
                                                mov     al, 255
                                        .endif
                                        jmp     InPortExit
                                .endif

                        .else
                                .if     (GotMultiface128Rom == TRUE) && (Multiface_LockOut == FALSE)
                                        mov     currentMachine.RAMREAD0,  offset Mf128_Mem
                                        mov     currentMachine.RAMREAD1,  offset Mf128_Mem+8192
                                        mov     currentMachine.RAMWRITE0, offset DummyMem
                                        mov     currentMachine.RAMWRITE1, offset Mf128_Mem+8192
                                        mov     MultifacePaged, TRUE

                                        mov     al, Last7FFDWrite
                                        shl     al, 4           ; bit 7 = last bit 3 value
                                        or      al, 127
                                        jmp     InPortExit
                                .endif
                endsw

                mov     al, 255
                jmp     InPortExit

align 16
PageOutMultiface:
                add     totaltstates, 3
                .if     MultifacePaged == TRUE
                        mov     al, Last7FFDWrite
                        call    Page_ROM
                        mov     MultifacePaged, FALSE
                .endif

                mov     al, 0FFh
                jmp     InPortExit


