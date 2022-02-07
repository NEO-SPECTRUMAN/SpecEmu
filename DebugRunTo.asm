
.data
align 16
RunTo_Hook          dd      0
RunTo_Cycle         dd      0

RunTo_IntCounter    dd      0

Run_KeyHalfRowMasks dw      0801h, 1001h, 0401h, 2001h, 0201h, 4001h, 0101h, 8001h

RunToOpcode         dw      0
RunToPC             dw      0
RunToPortReadAddr   dw      0
RunToPortWriteAddr  dw      0
RunToPortMask       dw      0
RunToPortRAMOnly    db      0

align 4
RunToDevicePort     dd      0

                    ; all defined in SpecEmu.inc
                    ; ==========================

;                  ; enumerate Device Port Identifiers
;                    RESETENUM
;                    ENUM    DEVICE_NONE
;                    ENUM    TRDOS_SYSTEM_REGISTER, TRDOS_STATUS_REGISTER, TRDOS_TRACK_REGISTER, TRDOS_SECTOR_REGISTER, TRDOS_DATA_REGISTER, TRDOS_COMMAND_REGISTER
;                    ENUM    ULA_FE, PAGING_7FFD, PAGING_1FFD
;
;                  ; enumerate RUN_TO condition types
;                    RESETENUM
;                    ENUM    RUN_TO_PC
;                    ENUM    RUN_TO_INTERRUPT,           RUN_TO_INTERRUPT_RETRIGGER
;                    ENUM    RUN_TO_CYCLE
;                    ENUM    RUN_TO_PORT_READ,           RUN_TO_PORT_WRITE
;                    ENUM    RUN_TO_DEVICE_PORT_READ,    RUN_TO_DEVICE_PORT_WRITE
;                    ENUM    RUN_TO_FLOATING_BUS_PORT_READ
;                    ENUM    RUN_TO_HALTED
;                    ENUM    RUN_TO_USER_CONDITION
;                    ENUM    RUN_TO_AUTOLOADTAPE
;                    ENUM    RUN_TO_TAPE_STARTS,         RUN_TO_TAPE_STOPS
;                    ENUM    RUN_TO_DISK_MOTOR_ON,       RUN_TO_DISK_MOTOR_OFF
;                    ENUM    RUN_TO_OPCODE

.code
Set_RunTo_Condition proc    Runto_Condition: BYTE
                    mov     PortReadAddress,  -1
                    mov     PortWriteAddress, -1

                    mov     Check_RunTo, TRUE   ; causes Debug frame to run

                    switch  Runto_Condition
                            case    RUN_TO_PC
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_PC
                            case    RUN_TO_CYCLE
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_CYCLE

                            case    RUN_TO_INTERRUPT
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_INTERRUPT
                            case    RUN_TO_INTERRUPT_RETRIGGER
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_INTERRUPT_RETRIGGER

                            case    RUN_TO_PORT_READ
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_PORT_READ
                            case    RUN_TO_PORT_WRITE
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_PORT_WRITE
                            case    RUN_TO_DEVICE_PORT_READ
                                    mov     PortDeviceType, DEVICE_NONE ; clear previously accessed device type in Ports.asm
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_DEVICE_PORT_READ
                            case    RUN_TO_DEVICE_PORT_WRITE
                                    mov     PortDeviceType, DEVICE_NONE ; clear previously accessed device type in Ports.asm
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_DEVICE_PORT_WRITE
                            case    RUN_TO_FLOATING_BUS_PORT_READ
                                    mov     Floating_Bus_Read, FALSE
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_FLOATING_BUS_PORT_READ
                            case    RUN_TO_HALTED
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_HALTED
                            case    RUN_TO_USER_CONDITION
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_USER_CONDITION
                            case    RUN_TO_AUTOLOADTAPE
                                    mov     autotype_stage, 0
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_AUTOLOADTAPE
                            case    RUN_TO_TAPE_STARTS
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_TAPE_STARTS
                            case    RUN_TO_TAPE_STOPS
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_TAPE_STOPS
                            case    RUN_TO_DISK_MOTOR_ON
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_DISK_MOTOR_ON
                            case    RUN_TO_DISK_MOTOR_OFF
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_DISK_MOTOR_OFF
                            case    RUN_TO_OPCODE
                                    mov     [RunTo_Hook], offset Hook_RUN_TO_OPCODE
                    endsw

                    ret
Set_RunTo_Condition endp


.data?
align 4
autotype_delayframes        dd      ?
autotype_keybuffer          dd      ?
autotype_ROMPtr             dd      ?
autotype_PC                 dw      ?
autotype_lastframecount     db      ?
autotype_stage              db      ?
autotype_CODE_block         db      ?

.data
autotapekeys_48_BASIC       db      239, 34, 34, 13, 0
autotapekeys_128_BASIC      db      13, 0
autotapekeys_Plus3_BASIC    db      10, 13, "load ""t:"" : load """"", 13, 0

autotapekeys_48_CODE        db      239, 34, 34, 175, 13, 0
autotapekeys_128_CODE       db      10, 13, "load """" code", 13, 0
autotapekeys_Plus3_CODE     db      10, 13, "load ""t:"" : load """" code", 13, 0

AUTOTAPE_FRAMEWAIT          equ     5

.code
; sets autotype ROM pointer and PC address
Set_Autotype_Rom_Point      proc

                            switch  HardwareMode
                                    case    HW_16, HW_48
                                            mov     autotype_PC,        10B0h
                                            mov     autotype_ROMPtr,    offset Rom_48           ; in standard ROM

                                    case    HW_128
                                            mov     autotype_PC,        3683h
                                            mov     autotype_ROMPtr,    offset Rom_128          ; in ROM 0 (Editor)

                                    case    HW_PLUS2
                                            mov     autotype_PC,        36A9h
                                            mov     autotype_ROMPtr,    offset Rom_Plus2        ; in ROM 0 (Editor)

                                    case    HW_PLUS2A, HW_PLUS3
                                            mov     autotype_PC,        1875h
                                            mov     autotype_ROMPtr,    offset Rom_Plus3        ; in ROM 0 (Editor)

                                    case    HW_PENTAGON128
                                            mov     autotype_PC,        3683h
                                            mov     autotype_ROMPtr,    offset Rom_Pentagon128  ; in ROM 0 (Editor)

                                    case    HW_TC2048
                                            mov     autotype_PC,        10B0h
                                            mov     autotype_ROMPtr,    offset Rom_TC2048       ; in standard ROM

                                    case    HW_TK90X
                                            mov     autotype_PC,        10B0h
                                            mov     autotype_ROMPtr,    offset Rom_TK90x        ; in standard TK-90x ROM
                            endsw
                            ret

Set_Autotype_Rom_Point      endp


Hook_RUN_TO_AUTOLOADTAPE:
                            .if     autotype_stage == 0
                                    ; we must match PC and correct ROM to continue to stage 2
                                    mov     ax,  zPC
                                    ifc     ax   ne autotype_PC     then ret    ; ne = no trap
                                    mov     eax, currentMachine.RAMREAD0
                                    ifc     eax  ne autotype_ROMPtr then ret    ; ne = no trap

                                    invoke  nrandom, 25
                                    add     al, SPGfx.FrameCnt
                                    add     al, AUTOTAPE_FRAMEWAIT
                                    and     al, 31
                                    mov     autotype_lastframecount, al
                                    inc     autotype_stage                      ; now at stage 1
                            .endif

                            ; exit if this is the same frame as the last
                            mov     al, SPGfx.FrameCnt
                            ifc     al  ne autotype_lastframecount then ret     ; ne = no trap
                            add     al, AUTOTAPE_FRAMEWAIT
                            and     al, 31
                            mov     autotype_lastframecount, al

                            ; this only runs once every AUTOTAPE_FRAMEWAIT frames
                            mov     bx, 23611
                            call    MemGetByte
                            test    al, 32                                      ; is ROM ready for a new keypress?
                            .if     ZERO?
                                    mov     ecx, autotype_keybuffer

                                    ; do we have keys to send?
                                    .if     byte ptr [ecx] != 0
                                            or      al, 32
                                            mov     bx, 23611
                                            call    MemPokeByte                 ; signal a new keypress
                                            mov     bx, 23560
                                            mov     al, [ecx]
                                            call    MemPokeByte                 ; insert keycode into lastkey sysvar

                                            inc     autotype_keybuffer
                                            inc     ecx                         ; increment to see if we've now reached buffer end (below)
                                    .endif

                                    ; check for end of key buffer immediately upon sending the last key press
                                    ; fixes Break on leaving ROM function by disabling Check_RunTo condition for Autoload typing after the final buffered key press

                                    ; end of key buffer?
                                    .if     byte ptr [ecx] == 0
                                            ; end of key buffer
                                            mov     MAXIMUMAUTOLOADTYPE, FALSE  ; disable max speed emulation for autoloading tapes
                                            mov     Check_RunTo, FALSE          ; end this RUN_TO condition now
                                            or      eax, -1                     ; without a trap to the debugger
                                            ret
                                    .endif
                            .endif

                            or      eax, -1 ; no trap
                            ret

Hook_RUN_TO_PC:             mov     ax, zPC
                            cmp     RunToPC, ax
                            ret

Hook_RUN_TO_CYCLE:          mov     eax, totaltstates
                            mov     ecx, RunTo_Cycle
                            .if     eax >= ecx
                                    add     ecx, 40 ;100
                                    .if     eax < ecx
                                            xor     eax, eax    ; zero set = trap to debugger
                                            ret
                                    .endif
                            .endif
                            or      eax, -1
                            ret

Hook_RUN_TO_INTERRUPT:
                            cmp     RunTo_IntCounter, 1
                            ret

Hook_RUN_TO_INTERRUPT_RETRIGGER:
                            cmp     RunTo_IntCounter, 2
                            ret

Hook_RUN_TO_PORT_READ:      ifc     PortAccessType ne PORT_READ then ret

                            .if     RunToPortRAMOnly == TRUE
                                    .if     zPC < 16384
                                            ret
                                    .endif
                            .endif

                            mov     ax, PortReadAddress
                            and     ax, RunToPortMask
                            .if     ax == RunToPortReadAddr
                                    mov     UsePrevzPC, TRUE
                            .endif
                            ret

Hook_RUN_TO_PORT_WRITE:     ifc     PortAccessType ne PORT_WRITE then ret

                            .if     RunToPortRAMOnly == TRUE
                                    .if     zPC < 16384
                                            ret
                                    .endif
                            .endif

                            mov     ax, PortWriteAddress
                            and     ax, RunToPortMask
                            .if     ax == RunToPortWriteAddr
                                    mov     UsePrevzPC, TRUE
                            .endif
                            ret

Hook_RUN_TO_DEVICE_PORT_READ:
                            .if     PortAccessType == PORT_READ
                                    mov     eax, PortDeviceType
                                    .if     eax == RunToDevicePort
                                            mov     UsePrevzPC, TRUE
                                    .endif
                            .endif
                            ret

Hook_RUN_TO_DEVICE_PORT_WRITE:
                            .if     PortAccessType == PORT_WRITE
                                    mov     eax, PortDeviceType
                                    .if     eax == RunToDevicePort
                                            mov     UsePrevzPC, TRUE
                                    .endif
                            .endif
                            ret

Hook_RUN_TO_FLOATING_BUS_PORT_READ:
                            .if     Floating_Bus_Read == TRUE
                                    mov     UsePrevzPC, TRUE
                            .endif
                            ret

Hook_RUN_TO_HALTED:         cmp     HALTED, TRUE
                            ret

.data?
align 4
pBreakpoint_stack           dd      ?

.code
align 16
Hook_RUN_TO_USER_CONDITION: .if     pBreakpointCodePage != 0
                                    lea     esi, RegisterBase

                                    mov     [Reg_x86_jmpexitaddr], offset @F

                                    mov     pBreakpoint_stack, esp
;     INT3
                                    call    [pBreakpointCodePage]

                            @@:     mov     esp, pBreakpoint_stack

                                    cmp     edi, TRUE
;                                    sete    UsePrevzPC
                                    ret
                            .endif
                            or      eax, -1 ; no trap
                            ret

Hook_RUN_TO_TAPE_STARTS:    cmp     TapePlaying, TRUE     ; traps if tape playing
                            ret

Hook_RUN_TO_TAPE_STOPS:     cmp     TapePlaying, FALSE    ; traps if tape not playing
                            ret

Hook_RUN_TO_DISK_MOTOR_ON:  .if     HardwareMode == HW_PLUS3    ; traps if disk motor is on
                                    mov     al, Last1FFDWrite
                                    and     al, 8
                                    xor     al, 8
                                    .if     ZERO?
                                            mov     UsePrevzPC, TRUE
                                    .endif
                            .endif
                            ret

Hook_RUN_TO_DISK_MOTOR_OFF: .if     HardwareMode == HW_PLUS3    ; traps if disk motor is off
                                    mov     al, Last1FFDWrite
                                    and     al, 8
                                    .if     ZERO?
                                            mov     UsePrevzPC, TRUE
                                    .endif
                            .endif
                            ret

Hook_RUN_TO_OPCODE:         mov     ax, RunToOpcode
                            .if     ax == OpcodeWord
                                    mov     UsePrevzPC, TRUE
                            .endif
                            ret




CHECK_RUN_TO                macro
                            call    [RunTo_Hook]
                            je      DebugFrame_Trap
                            endm


