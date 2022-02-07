
; IDM_FIRSTMACHINE & IDM_LASTMACHINE defined in SpecEmu.asm

                include Machines\Spectrum_16K.asm
                include Machines\Spectrum_48K.asm
                include Machines\Spectrum_128K.asm
                include Machines\Spectrum_Plus2.asm
                include Machines\Spectrum_Plus2A.asm
                include Machines\Spectrum_Plus3.asm
                include Machines\Pentagon_128K.asm
                include Machines\TC2048.asm
                include Machines\TK90X.asm

align 16
Machine_Initialise:
                invoke  Init_AY
                call    InitPort

                memcpy  addr spk_mic_output_defaults, addr spk_mic_output_table, SPK_MIC_OUTPUT_SIZEOF
                mov     [BeepVal], BEEPERLOW ;BEEPERCENTRE


                ; initialise external hardware modules
                invoke  PLUSD_Initialise
                invoke  uSpeech_Initialise

                call    Set_Machine_Config

                mov     MultifacePaged,   FALSE
                mov     Multiface_LockOut,TRUE      ; Multiface locked out by default on reset

                mov     SoftRomPaged,     FALSE
                mov     MicroSourcePaged, FALSE
                mov     PLUSD_Paged,      FALSE
                mov     uSpeech_Paged,    FALSE

                mov     currentMachine.nmi, FALSE

                ; setup display features for conventional Spectrum machines
                ; machines with altered display features are set in machine initialisation code
                mov     MACHINE.RendererEntryPoint, offset SpectrumPrepTopBorder
                mov     MACHINE.TopBorderLines, 24
                mov     MACHINE.DisplayLines, 192
                mov     MACHINE.BottomBorderLines, 24
                mov     MACHINE.DisplayWidth, 32+256+32
                mov     MACHINE.DisplayHeight, 24+192+24
                mov     MACHINE.PixelWidth, 256
                mov     MACHINE.BorderWidth, 32

                mov     MACHINE.FramesPerSecond, 50

                m2m     SPGfx.zxDisplayOrg, currentMachine.bank5

                mov     MACHINE.Plus3_Compatible, False ; +2A/+3 initialisation code will set this to True

                mov     MACHINE.Has_AY, TRUE
                mov     MACHINE.DoesSnow, TRUE
                mov     MACHINE.CrashesOnSnow, FALSE

                mov     MACHINE.HasFloatingBus, TRUE
                mov     MACHINE.HasLowPortContention, TRUE
                mov     MACHINE.Has_ULAColourArtifacts, TRUE
                mov     MACHINE.Has_ULAplus, TRUE

                mov     MACHINE.AUDIOPERIOD.SampleLoopCount, 0
                mov     MACHINE.REALTAPEPERIOD.SampleLoopCount, 0

                mov     Last7FFDWrite, 0
                mov     Last1FFDWrite, 0

                ; set all DRAMs to not have memory fade
                ; each machine will then set its correct values
                mov     eax, FALSE
                mov     currentMachine.DoesDRAMFade[0*4], eax
                mov     currentMachine.DoesDRAMFade[1*4], eax
                mov     currentMachine.DoesDRAMFade[2*4], eax
                mov     currentMachine.DoesDRAMFade[3*4], eax
                mov     currentMachine.DoesDRAMFade[4*4], eax
                mov     currentMachine.DoesDRAMFade[5*4], eax
                mov     currentMachine.DoesDRAMFade[6*4], eax
                mov     currentMachine.DoesDRAMFade[7*4], eax

                switch  HardwareMode
                        case    HW_16
                                call    Spectrum_16K_Initialise
                        case    HW_48
                                call    Spectrum_48K_Initialise
                        case    HW_128
                                call    Spectrum_128K_Initialise
                        case    HW_PLUS2
                                call    Spectrum_Plus2_Initialise
                        case    HW_PLUS2A
                                call    Spectrum_Plus2A_Initialise
                        case    HW_PLUS3
                                call    Spectrum_Plus3_Initialise
                        case    HW_PENTAGON128
                                call    Pentagon_128K_Initialise
                        case    HW_TC2048
                                call    TC2048_Initialise
                        case    HW_TK90X
                                call    TK90X_Initialise
                endsw

                .if     CBI_Enabled == TRUE
                        mov     CBI_Port_252, 00000000b
                        mov     CBI_Port_255, 00001100b

                        wd1793_ResetDevice          CBIHandle
                        wd1793_SetActiveCallback    CBIHandle, offset AddOnFastDiskCallback
                        wd1793_SetDriveStepCallback CBIHandle, offset AddOnDriveStepCallback  ; in Machines.asm
                .endif

                invoke  SetSnowEffect
                invoke  Set_Emulate_AY
                invoke  InitULAplus

                ; clear the R refresh counters
                invoke  FillBuffer, addr currentMachine.refresh_counters, sizeof currentMachine.refresh_counters, 0

                IFDEF   WANTSOUND
                call    ReinitAudio ; machines can be PAL or NTSC so the audio needs reinitialising
                ENDIF

                invoke  SetMachineStatusBar

                ret

; wipes all 128K RAM banks
align 16
WipeSpeccyMem           proc
                        ForLp   eax, 0, 7
                                push    eax
                                memclr  [currentMachine.bank_ptrs+eax*4], 4000h
                                pop     eax
                        Next    eax
                        ret
WipeSpeccyMem           endp

align 16
SetSnowEffect   proc
                .if     Snow_Enabled == TRUE
                        .if     MACHINE.DoesSnow == TRUE
                                push    ebx
                                mov     bh, z80registers.i
                                call    Is_Contended
                                pop     ebx
                                .if     eax == TRUE ; does the I register address contended memory?
                                        mov     SPGfx.SnowEffect, TRUE
                                        ret
                                .endif
                        .endif
                .endif
                mov     SPGfx.SnowEffect, FALSE
                ret
SetSnowEffect   endp

align 16
Set_Emulate_AY  proc
                .if     MACHINE.Has_AY == TRUE
                        mov     Emulate_AY, TRUE
                .else
                        .if     AY_in_48_mode == TRUE
                                mov     Emulate_AY, TRUE
                        .else
                                mov     Emulate_AY, FALSE

                                mov     Total_ChanA, 0
                                mov     Total_ChanB, 0
                                mov     Total_ChanC, 0
                                mov     FinalChanA,  0
                                mov     FinalChanB,  0
                                mov     FinalChanC,  0
                        .endif
                .endif
                ret
Set_Emulate_AY  endp

NO_DIVIDE       macro
                mov     DivIDEEnabled, FALSE
                endm

NO_PLUS_D       macro
                mov     PLUSD_Enabled, FALSE
                endm

NO_SOFTROM      macro
                mov     SoftRomEnabled, FALSE
                endm

NO_USPEECH      macro
                mov     uSpeech_Enabled, FALSE
                endm

NO_MICROSOURCE  macro
                mov     MicroSourceEnabled, FALSE
                endm

NO_SPECDRUM     macro
                mov     SpecDrum_Enabled, FALSE
                endm

NO_CBI          macro
                mov     CBI_Enabled, FALSE
                endm

align 16
Set_Machine_Config:
                switch  HardwareMode
                        case    HW_16

                        case    HW_48

                        case    HW_128
                                NO_USPEECH
                                NO_MICROSOURCE
                                NO_SPECDRUM
                                NO_CBI

                        case    HW_PLUS2
                                NO_USPEECH
                                NO_MICROSOURCE
                                NO_SPECDRUM
                                NO_CBI

                        case    HW_PLUS2A, HW_PLUS3
                                NO_PLUS_D
                                NO_SOFTROM
                                NO_USPEECH
                                NO_MICROSOURCE
                                NO_SPECDRUM
                                NO_CBI

                        case    HW_PENTAGON128
                                NO_DIVIDE
                                NO_PLUS_D
                                NO_SOFTROM
                                NO_USPEECH
                                NO_MICROSOURCE
                                NO_SPECDRUM
                                NO_CBI

                        case    HW_TC2048

                        case    HW_TK90X

                endsw

                ret

align 16
ClearContentionTable:
                push    edi
                lea     edi, ContentionTable
                mov     ecx, 72000
                xor     al, al
                rep     stosb

                mov     edi, ULAReadAddress
                mov     ecx, 72000
                mov     ax,  0FFFFh
                rep     stosw
                pop     edi
                ret

align 16
AddOnFastDiskCallback:
                mov     trdos_active_frames, 50 ; for disk icon
                .if     AddOnFastDiskLoading == TRUE
                        mov     MAXIMUMDISKSPEED, MAXIMUMDISKSPEEDFRAMES
                .endif
                ret

align 16
AddOnDriveStepCallback:
                .if     AddOnFastDiskLoading == FALSE
                        DSBINVOKE   SetCurrentPosition, DriveStepBuffer, 0
                        DSBINVOKE   Play, DriveStepBuffer, 0, 0, 0
                .endif
                ret


align 16
InstallGenie128:
                invoke  ZLIB_DecompressBlock, addr GenieMemDump, GENIEMEMDUMPSIZE, addr Mf128_Mem+8192, 8192
                .if     eax != 8192
                        invoke  ShowMessageBox, hWnd, SADD ("Corrupted Genie data"), addr szWindowName, MB_OK or MB_ICONWARNING
                .endif
                ret

