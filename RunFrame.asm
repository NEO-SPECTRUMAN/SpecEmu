
; ##########################################################################

Run_Frame:
                        mov     al, FrameSkipCounter
                        mov     FrameSkipLoop, al

                        .if     FULLSPEEDMODE == TRUE
                                mov FrameSkipLoop, FULLSPEEDFRAMECOUNT
                        .endif

                        .if     TapePlaying && FastTapeLoading && (RealTapeMode == FALSE)
                                mov    FrameSkipLoop, AUTOTAPEFRAMESKIP
                        .endif

; #########################################################################

Emu_ReInit:
                        mov     PortUpdatePending, TRUE

; #########################################################################

;   INT low code
align 16
                        mov     eax, totaltstates

                        .while  eax < MACHINE.InterruptCycles
                                .if     (currentMachine.iff1 == TRUE) && (EI_Last == FALSE)    ; EI_Last will be false if last opcode was LD A,I or LD A,R so we can still handle the PV flag bug for those in 'z80_Interrupt' proc
                                        call    z80_Interrupt
                                        je      @F      ; jump forward if INT accepted
                                .endif

                                call    Exec_Opcode
@@:                             call    Exec_Extras

                                mov     eax, totaltstates
                        .endw

;--------------------------------------------------------------------------------
;   frame code
align 16
                        .while  totaltstates < 69888/2
                                call    Exec_Opcode
                                call    Exec_Extras
                        .endw

                        ; update keyboard and joystick port states at frame midpoint
                        call    UpdatePortState     ; preserves all registers

                        .if     currentMachine.nmi
                                call    z80_NMI
                                call    Exec_Extras ; take NMI timings into effect
                        .endif

                        mov     eax, totaltstates
align 16
                        .while  eax < MACHINE.FrameCycles
                                call    Exec_Opcode
                                call    Exec_Extras

                                mov     eax, totaltstates
                        .endw

;--------------------------------------------------------------------------------

                        push    totaltstates
                        mov     totaltstates, 71000
                        RENDERCYCLES
                        pop     totaltstates

                        mov     eax, MACHINE.FrameCycles
                        sub     totaltstates, eax

                        .if     AutoPlayTapes
                                .if     AutoTapeStarted
                                        .if     (LoadTapeType == Type_TZX) && (TZXPause > 0) && (SL_AND_32_64 == TRUE)
                                        .elseif (LoadTapeType == Type_PZX) && (PZX.Pause > 0) && (SL_AND_32_64 == TRUE)
                                        .else
                                                .if    AutoTapeStopFrames == 0
                                                       mov     TapePlaying, FALSE
                                                       mov     AutoTapeStarted, FALSE
                                                .else
                                                       dec     AutoTapeStopFrames
                                                .endif
                                        .endif
                                .endif
                        .endif

                        call    InitUpdateScreen

                        inc     FramesPerSecond
                        inc     GlobalFramesCounter

                        shr     AY_FloatingRegister, 1

                        invoke  DRAM_Fade

                        dec     FrameSkipLoop
                        jnz     Emu_ReInit

                        ret

align 16
Exec_Opcode:            push    totaltstates
                        RUNZ80INSTR             ; run current Z80 opcode
                        mov     ebx, totaltstates
                        pop     eax
                        sub     ebx, eax

                        mov     cl, CPU_Speed
                        .if     (cl != 0) && (TapePlaying == FALSE) && (RealTapeMode == FALSE)
                                .if     cl == -1
                                        shl     ebx, 1
                                .else
                                        shr     ebx, cl
                                        cmp     ebx, 1
                                        adc     ebx, 0
                                .endif
                                add     eax, ebx
                                mov     totaltstates, eax
                        .endif

                        mov     Z80TState,     bl    ; Ts timing of opcode for tape renderer, etc.
                        add     AYTimer,       bl
                        add     SampleTimer,   bl
                        add     RealTapeTimer, bl
                        add     uSpeechTimer,  ebx
                        ret

align 16
Exec_Extras:            .if     RealTapeMode
                                mov     al, MACHINE.REALTAPEPERIOD.CurrentCyclesPerSample
                                .if     RealTapeTimer >= al
                                        sub     RealTapeTimer, al
                                        invoke  Get_Real_Tape_Bit
                                .endif
                        .else
                                ifc     TapePlaying then call PlayTape
                        .endif

                        ifc     SaveTapeType ne Type_NONE then call WriteTapePulse

                        IFDEF   WANTSOUND
                        .if     MuteSound == FALSE
                                movzx   eax, BeepVal
                                inc     BeeperSubCount
                                add     BeeperSubTotal, eax

                                invoke  Sample_AY
                        .endif
                        ENDIF

                        ret

; #########################################################################

align 16
z80_NMI:  ; -- takes 11 T-States to respond
                        mov     currentMachine.nmi, FALSE

                        lea     esi, RegisterBase

                        mov     eax, 11
                        mov     Z80TState,     al
                        add     AYTimer,       al
                        add     SampleTimer,   al
                        add     RealTapeTimer, al
                        add     uSpeechTimer,  eax

                        sub     eax, 6              ; Z80CALL adds back 6 cycles
                        add     Reg_totaltstates, eax

                        inc     Reg_R

                        ; reset refresh counter entry for current value of R
                        movzx   eax, Reg_R
                        and     eax, 7Fh
                        mov     [currentMachine.refresh_counters+eax], 0

                        .if     HALTED
                                mov     HALTED, FALSE
                                inc     Reg_PC  ; step past HALT instruction
                        .endif

                        ; CBI95_NMI_enabled set by commandline switch
                        .if     (CBI_Enabled == TRUE) && (CBI95_NMI_enabled == TRUE)
                                and     CBI_Port_252, not (1 shl 7)     ; enable CBI I / O interface
                                and     CBI_Port_255, not (1 shl 7)     ; page in the CBI EPROM
            
                                invoke  Z80Call_MEMPTR, 102
                                mov     currentMachine.iff1, FALSE                     ; IFF1 = 0; IFF2 unchanged
                                ret
                        .endif

                        .if     DivIDEEnabled
                                .if     DivIDE.Mapped == FALSE
                                        invoke  Z80Call_MEMPTR, 102
                                        mov     currentMachine.iff1, FALSE             ; IFF1 = 0; IFF2 unchanged
                                .endif
                                ret
                        .endif

                        .if     PLUSD_Enabled
                                invoke  Z80Call_MEMPTR, 102
                                mov     currentMachine.iff1, FALSE                     ; IFF1 = 0; IFF2 unchanged
                                ret
                        .endif

                        .if     HardwareMode == HW_PENTAGON128
                                ;Beta has the "Magic Button". When pressed, the execution continues as 
                                ;long as we're in ROM. It prevents TRDOS' own routines being interrupted.
                                ;With first memory access outside - ROM A(15,14) != "00" & MEMRQ="0", 
                                ;Beta is paged in and NMI is triggered. So the NMI execution starts in 
                                ;Beta ROM. It saves the memory snapshot to the disk then.
                                ;The saved snapshot can be loaded back by GOTO "name" CODE at the TRDOS 
                                ;prompt.
                                ;I just checked this against the original Beta v5.03 schematics.

                                .if     zPC >= 4000h
                                        call    TrDos_Page_In

                                        invoke  Z80Call_MEMPTR, 102
                                        mov     currentMachine.iff1, FALSE             ; IFF1 = 0; IFF2 unchanged
                                .endif
                                ret
                        .endif

                        invoke  Z80Call_MEMPTR, 102
                        mov     currentMachine.iff1, FALSE     ; IFF1 = 0; IFF2 unchanged

                        .if     (MultifaceEnabled == TRUE) && (MultifacePaged == FALSE)
                                mov     Multiface_LockOut, FALSE   ; enable Multiface device
                                call    PageInMultiface
                        .endif
                        ret

align 16
z80_Interrupt:          .if     HardwareMode == HW_TC2048
                                test    Timex_Port_FF, 64
                                retcc   nz                      ; return non-zero if INTs are disabled in hardware
                        .endif

                        lea     esi, RegisterBase
                        inc     Reg_R

                        ; reset refresh counter entry for current value of R
                        movzx   eax, Reg_R
                        and     eax, 7Fh
                        mov     [currentMachine.refresh_counters+eax], 0

                        .if     HALTED
                                mov     HALTED, FALSE
                                inc     Reg_PC  ; step past HALT instruction
                        .endif

                        .if     IFF2_Read
                                ; LD A,I or LD A,R was just executed, copying IFF2 to the PV flag
                                ; if an interrupt was just accepted during that opcode, clear the PV flag as IFF2 would have been cleared before it was transferred
                                and     Reg_F, NOT FLAG_V
                                mov     IFF2_Read, FALSE
                        .endif

                        DISABLEINTS     ; disable interrupts when accepting an interrupt

                        movzx   eax, Reg_IntMode
                        cmp     eax, 2
                        jc      IntMode01

                        mov     bh, Reg_I
                        mov     bl, 255
                        call    MemGetWord
                        mov     bx, ax      ; IM 2 int vector > bx
                        mov     eax, 19     ; 19 cycles for IM 2
                        jmp     IntModeEx

IntMode01:              mov     eax, 13     ; 13 cycles for IM 0 and IM 1 modes (tested on real 48K machine)
                        mov     bx,  56     ; IM 0/1 int vector > bx

IntModeEx:              mov     Z80TState,     al
                        add     AYTimer,       al
                        add     SampleTimer,   al
                        add     RealTapeTimer, al
                        add     uSpeechTimer,  eax

                        sub     eax, 6              ; Z80CALL adds back 6 cycles
                        add     Reg_totaltstates, eax

                        invoke  Z80Call_MEMPTR, bx

                        xor     eax, eax    ; set zero flag to signal INT accepted
                        ret

; ##########################################################################

align 16
Z80Call_MEMPTR          proc    uses        esi ebx edi,
                                z80addr:    WORD

                        lea     esi, RegisterBase
                        mov     ax,  z80addr
                        mov     Reg_MemPtr, ax
                        Z80CALL
                        ret

Z80Call_MEMPTR          endp


