
    IFNDEF  _Z80CORE_INC_
            _Z80CORE_INC_   =  1

; equates for UseIXIY
UsingHL                     equ     0
UsingIX                     equ     1
UsingIY                     equ     2


z80regunion                 macro   regname:req, reg16hi:req, reg16lo:req
                            union   &regname&
                                    w   word    ?
                                struct
                                    lo  byte    ?
                                    hi  byte    ?
                                ends
                                struct
                                    &reg16lo&  byte    ?
                                    &reg16hi&  byte    ?
                                ends
                            ends
                            endm

z80union                    macro   varname:req
                            union   &varname&
                                    w   word    ?
                                struct
                                    lo  byte    ?
                                    hi  byte    ?
                                ends
                            ends
                            endm

TMACHINE                    struct
                            z80regunion hl_, h_, l_
                            z80regunion de_, d_, e_
                            z80regunion bc_, b_, c_
                            z80regunion af_, a_, f_

                            z80regunion hl, h, l
                            z80regunion de, d, e
                            z80regunion bc, b, regc
                            z80regunion af, a, f

                            z80regunion iy, iyh, iyl
                            z80regunion ix, ixh, iyl

                            z80regunion memptr, memptrl, memptrh

                            _sp         word    ?
                            pc          word    ?

                            i           byte    ?
                            r           byte    ?
                            r_msb       byte    ?
                            interrupt   byte    ?   ; bit 2 contains IFF2, 1=EI/0=DI
                            intmode     byte    ?   ; 0=INT0, 1=INT1, 2=INT2

                            q           byte    ?   ; register Q
                            iff1        byte    ?
                            iff2        byte    ?
                            nmi         byte    ?   ; nmi received?
                          ; =====================================================================

                            ; z80state1_flags
;                            BITDEF  Z80STATE1FLAG, UNDEFINED, 0    ; no flag bits defined yet

                            align       4
                            union
                                clear_z80_state_1           dword   ?
                                struct
                                        op_useixiy          byte    ?
                                        op_inslength        byte    ?
                                        op_is_repeating     byte    ?
                                        z80state1_flags     byte    ?   ; defined above
                                ends
                            ends

                            union
                                clear_z80_state_2           dword   ?
                                struct
                                        opcode_tstates      byte    ?
                                        word_length_access  byte    ?
                                        ei_last_op          byte    ?
                                        iff2_flag_read      byte    ?
                                ends
                            ends

                            union
                                clear_z80_state_3           dword   ?
                                struct
                                        opcode_word         word    ?
                                        port_access_type    byte    ?
                                                            byte    ?
                                ends
                            ends

                            union
                                clear_z80_state_4               dword   ?
                                struct
                                        memory_read_event       byte    ?
                                        memory_write_event      byte    ?
                                        memory_contended_event  byte    ?
                                                                byte    ?
                                ends
                            ends

                            tstatecount             dword   ?
                            opcodes_executed        dword   ?

                            ; 8 bools indicating which 16K DRAMs have memory fade with inadequate refresh
                            DoesDRAMFade            dword   8   dup (?)

                            bank_ptrs               dword   8   dup (?)
                            bank0                   dword   ?
                            bank1                   dword   ?
                            bank2                   dword   ?
                            bank3                   dword   ?
                            bank4                   dword   ?
                            bank5                   dword   ?
                            bank6                   dword   ?
                            bank7                   dword   ?

                            ; dword pointers to memory used for each 8K of memory for reading
                            RAMREAD0                dword   ?   ; 0000-1FFF
                            RAMREAD1                dword   ?   ; 2000-3FFF
                            RAMREAD2                dword   ?   ; 4000-5FFF
                            RAMREAD3                dword   ?   ; 6000-7FFF
                            RAMREAD4                dword   ?   ; 8000-9FFF
                            RAMREAD5                dword   ?   ; A000-BFFF
                            RAMREAD6                dword   ?   ; C000-DFFF
                            RAMREAD7                dword   ?   ; E000-FFFF

                            ; dword pointers to memory used for each 8K of memory for writing
                            RAMWRITE0               dword   ?
                            RAMWRITE1               dword   ?
                            RAMWRITE2               dword   ?
                            RAMWRITE3               dword   ?
                            RAMWRITE4               dword   ?
                            RAMWRITE5               dword   ?
                            RAMWRITE6               dword   ?
                            RAMWRITE7               dword   ?

                            ; dword contention booleans for memory used for each 8K of memory
                            ; using dwords allows for the same offsets as used for read/write operations to be used
                            CONTENTION0             dword ?
                            CONTENTION1             dword ?
                            CONTENTION2             dword ?
                            CONTENTION3             dword ?
                            CONTENTION4             dword ?
                            CONTENTION5             dword ?
                            CONTENTION6             dword ?
                            CONTENTION7             dword ?

                            x86_jmpexitaddr         dword ? ; jmp exit address for debugger's stop command

                            z80union                memory_read_value
                            z80union                memory_write_value

                            ; counters for how many frames (~20ms) occurred since refresh for each value of R (b0-6)
                            refresh_counters        byte    128 dup (?) ; accessed as dwords; keep aligned

                            previous_pc             word    ?

                            memory_read_address     word    ?
                            memory_write_address    word    ?

                            cb_abs_addr             word    ?   ; work space for CB opcodes

                            x86test_ir              word    ?

                            cpu_refresh_cycle       byte    ?
                            cpu_temp_byte_1         byte    ?

                            low_port_contention     byte    ?

                            border                  byte    ?

                            cb_dest_val             byte    ?   ; work space for CB opcodes
                            cb_dest_reg             byte    ?   ; work space for CB opcodes
                            cb_opcode               byte    ?   ; opcode after prefixes in (FD/DD)CB opcodes

                            frame_skip_loop         byte    ?
                            port_update_pending     byte    ?

                            load_tape_type          byte    ?
                            save_tape_type          byte    ?

                            cpu_halted              byte    ?

TMACHINE                    ends


_esibase_                   equ     <currentMachine>

regexpand                   macro   _regname_:req, _register_:req
                            local   cmname, cmsize, cmtype

                            cmname  equ <currentMachine.&_register_&>
                            cmsize  = @GETARGSIZE (cmname)
                            if      cmsize  eq 1
                                    cmtype  equ     <byte>
                            elseif  cmsize  eq 2
                                    cmtype  equ     <word>
                            elseif  cmsize  eq 4
                                    cmtype  equ     <dword>
                            else
                                    .err <Unsupported data type!">
                            endif

                            if      glUseEsi eq 1
                                    &_regname_& equ <cmtype ptr [esi+(cmname - _esibase_)]>
                            elseif  glUseEsi eq 0
                                    &_regname_& equ <cmname>
                            else    
                                    .err <Unsupported _useesi_ value!">
                            endif
                            endm


CHECKESI                    macro
                            IFDEF   DEBUGBUILD
                                    .if     esi != offset RegisterBase
                                            .if     esireported == FALSE
                                                    call    esi_error   ; see SpecEmu.asm
                                                    mov     esireported, TRUE
                                            .endif
                                    .endif
                            ENDIF
                            endm

USEESI                      macro   _useesi_:req
                            glUseEsi    = _useesi_

                            regexpand   Reg_HL,     hl.w
                            regexpand   Reg_DE,     de.w
                            regexpand   Reg_BC,     bc.w
                            regexpand   Reg_AF,     af.w

                            regexpand   Reg_HL_alt, hl_.w
                            regexpand   Reg_DE_alt, de_.w
                            regexpand   Reg_BC_alt, bc_.w
                            regexpand   Reg_AF_alt, af_.w

                            regexpand   Reg_IX,     ix.w
                            regexpand   Reg_IY,     iy.w

                            regexpand   Reg_SP,     _sp

                            regexpand   Reg_A,      af.hi
                            regexpand   Reg_F,      af.lo
                            regexpand   Reg_B,      bc.hi
                            regexpand   Reg_C,      bc.lo
                            regexpand   Reg_D,      de.hi
                            regexpand   Reg_E,      de.lo
                            regexpand   Reg_H,      hl.hi
                            regexpand   Reg_L,      hl.lo

                            regexpand   Reg_A_alt,  af_.hi
                            regexpand   Reg_F_alt,  af_.lo
                            regexpand   Reg_B_alt,  bc_.hi
                            regexpand   Reg_C_alt,  bc_.lo
                            regexpand   Reg_D_alt,  de_.hi
                            regexpand   Reg_E_alt,  de_.lo
                            regexpand   Reg_H_alt,  hl_.hi
                            regexpand   Reg_L_alt,  hl_.lo

                            regexpand   Reg_IXH,    ix.hi
                            regexpand   Reg_IXL,    ix.lo
                            regexpand   Reg_IYH,    iy.hi
                            regexpand   Reg_IYL,    iy.lo

                            regexpand   Reg_I,      i
                            regexpand   Reg_R,      r
                            regexpand   Reg_R_msb,  r_msb
                            regexpand   Reg_IntMode,intmode

;                           ==============================================

                            regexpand   Reg_Border,                 border
                            regexpand   Reg_totaltstates,           tstatecount
                            regexpand   Reg_opcodes_executed,       opcodes_executed

                            regexpand   Reg_PC,                     pc
                            regexpand   Reg_PrevzPC,                previous_pc

                            regexpand   Reg_MemoryReadAddress,      memory_read_address
                            regexpand   Reg_MemoryWriteAddress,     memory_write_address

                            regexpand   Reg_Q,                      q
                            regexpand   Reg_CBDestVal,              cb_dest_val
                            regexpand   Reg_CBAbsAddr,              cb_abs_addr
                            regexpand   Reg_CBDestReg,              cb_dest_reg

                            regexpand   Reg_CBOpcode,               cb_opcode
                            regexpand   Reg_FrameSkipLoop,          frame_skip_loop
                            regexpand   Reg_PortUpdatePending,      port_update_pending

                            regexpand   Reg_LoadTapeType,           load_tape_type
                            regexpand   Reg_SaveTapeType,           save_tape_type

                            regexpand   Reg_MemPtr,                 memptr

                            regexpand   Reg_ClearZ80State1,         clear_z80_state_1
                            regexpand   Reg_UseIXIY,                op_useixiy
                            regexpand   Reg_InsLength,              op_inslength
                            regexpand   Reg_IsRepeating,            op_is_repeating

                            regexpand   Reg_ClearZ80State2,         clear_z80_state_2
                            regexpand   Reg_Z80TState,              opcode_tstates
                            regexpand   Reg_WordLengthAccess,       word_length_access
                            regexpand   Reg_EI_Last,                ei_last_op
                            regexpand   Reg_IFF2_Read,              iff2_flag_read

                            regexpand   Reg_ClearZ80State3,         clear_z80_state_3
                            regexpand   Reg_OpcodeWord,             opcode_word
                            regexpand   Reg_PortAccessType,         port_access_type

                            regexpand   Reg_ClearZ80State4,         clear_z80_state_4
                            regexpand   Reg_MemoryReadEvent,        memory_read_event
                            regexpand   Reg_MemoryWriteEvent,       memory_write_event
                            regexpand   Reg_MemoryContendedEvent,   memory_contended_event

                            regexpand   Reg_refresh_cycle,          cpu_refresh_cycle
                            regexpand   Reg_proc_temp_byte_1,       cpu_temp_byte_1

                            regexpand   Reg_HALTED,                 cpu_halted

                            regexpand   Reg_MemoryReadValue,        memory_read_value
                            regexpand   Reg_MemoryReadValueLo,      memory_read_value.lo
                            regexpand   Reg_MemoryReadValueHi,      memory_read_value.hi

                            regexpand   Reg_MemoryWriteValue,       memory_write_value
                            regexpand   Reg_MemoryWriteValueLo,     memory_write_value.lo
                            regexpand   Reg_MemoryWriteValueHi,     memory_write_value.hi

                            regexpand   Reg_x86_jmpexitaddr,        x86_jmpexitaddr
                            endm

                          ; ==============================================

                          ; compatibility equates for previous var names

                            totaltstates        equ <currentMachine.tstatecount>
                            zPC                 equ <currentMachine.pc>
                            PrevzPC             equ <currentMachine.previous_pc>
                            MemoryReadAddress   equ <currentMachine.memory_read_address>
                            MemoryWriteAddress  equ <currentMachine.memory_write_address>

                            zQ                  equ <currentMachine.q>
                            CBDestVal           equ <currentMachine.cb_dest_val>
                            CBAbsAddr           equ <currentMachine.cb_abs_addr>
                            CBDestReg           equ <currentMachine.cb_dest_reg>

                            FrameSkipLoop       equ <currentMachine.frame_skip_loop>
                            PortUpdatePending   equ <currentMachine.port_update_pending>

                            LoadTapeType        equ <currentMachine.load_tape_type>
                            SaveTapeType        equ <currentMachine.save_tape_type>

                            zMemPtr             equ <currentMachine.memptr.w>

                            ClearZ80State1      equ <currentMachine.clear_z80_state_1>
                            UseIXIY             equ <currentMachine.op_useixiy>
                            InsLength           equ <currentMachine.op_inslength>
                            IsRepeating         equ <currentMachine.op_is_repeating>

                            ClearZ80State2      equ <currentMachine.clear_z80_state_2>
                            Z80TState           equ <currentMachine.opcode_tstates>
                            WordLengthAccess    equ <currentMachine.word_length_access>
                            EI_Last             equ <currentMachine.ei_last_op>
                            IFF2_Read           equ <currentMachine.iff2_flag_read>

                            ClearZ80State3      equ <currentMachine.clear_z80_state_3>
                            OpcodeWord          equ <currentMachine.opcode_word>
                            PortAccessType      equ <currentMachine.port_access_type>

                            MemoryReadEvent     equ <currentMachine.memory_read_event>
                            MemoryWriteEvent    equ <currentMachine.memory_write_event>
                            MemoryContendedEvent equ <currentMachine.memory_contended_event>

                            MemoryReadValue     equ <currentMachine.memory_read_value>
                            MemoryWriteValue    equ <currentMachine.memory_write_value>

                            refresh_cycle       equ <currentMachine.cpu_refresh_cycle>
                            proc_temp_byte_1    equ <currentMachine.cpu_temp_byte_1>

                            HALTED              equ <currentMachine.cpu_halted>



FLAG_S          equ     80h
FLAG_Z          equ     40h
FLAG_5          equ     20h
FLAG_H          equ     10h
FLAG_3          equ     08h
FLAG_V          equ     04h
FLAG_P          equ     04h
FLAG_N          equ     02h
FLAG_C          equ     01h

@FLAGS          macro   @flagsparm:REQ

                local   @flagsval, @flagstr
                local   @char

                @flagstr equ <@flagsparm>

                @flagsval = 0

              % forc    @char, <@flagstr>
                        ifidn       <@char>, <S>
                                @flagsval = @flagsval or FLAG_S
                        elseifidn   <@char>, <Z>
                                @flagsval = @flagsval or FLAG_Z
                        elseifidn   <@char>, <5>
                                @flagsval = @flagsval or FLAG_5
                        elseifidn   <@char>, <H>
                                @flagsval = @flagsval or FLAG_H
                        elseifidn   <@char>, <3>
                                @flagsval = @flagsval or FLAG_3
                        elseifidn   <@char>, <P>
                                @flagsval = @flagsval or FLAG_P
                        elseifidn   <@char>, <V>
                                @flagsval = @flagsval or FLAG_V
                        elseifidn   <@char>, <N>
                                @flagsval = @flagsval or FLAG_N
                        elseifidn   <@char>, <C>
                                @flagsval = @flagsval or FLAG_C
                        else
                                .err    <Unknown flag bit specified>
                        endif
                endm

                exitm   %@flagsval

                endm

;############################################################################################

; Macros

SETTS           macro   Z80timing:req
                add     Reg_totaltstates, Z80timing
                endm

SETINTMODE      MACRO   newintmode:req
                mov     z80registers.intmode, newintmode
                ENDM

GET_R           macro   reg8:req
                mov     reg8, z80registers.r
                and     reg8, 127
                or      reg8, z80registers.r_msb
                endm

SET_R           macro   reg8:req
                mov     z80registers.r, reg8
                mov     z80registers.r_msb, reg8
                and     z80registers.r_msb, 128
                endm

; bx = addr
; al = byte result
M1_FETCH        MACRO
                call    M1_Fetch
                ENDM

; bx = addr
; al = byte result
GETOPCODEBYTE   MACRO
                call    GetOpcodeByte
                ENDM

; bx = addr
; al = byte result
GETBYTE         MACRO
                call    GetByte
                ENDM

; bx = address
; ax = word result
GETOPCODEWORD   MACRO
                call    GetOpcodeWord
                ENDM

; bx = address
; ax = word result
GETWORD         MACRO
                call    GetWord
                ENDM

; bx = address
; ax = word result
GETSTACKWORD    MACRO
                call    GetStackWord
                ENDM

; bx = address
; bx + ax = word result
GETRUNWORD      MACRO
                mov     bx, Reg_PC
                add     Reg_PC, 2
                add     Reg_InsLength, 2
                GETOPCODEWORD
                mov     ebx, eax
                ENDM

; bx = addr, al = byte
POKEBYTE        MACRO
                call    PokeByte
                ENDM

; bx = addr, al = byte
POKESTACKBYTE   MACRO
                movzx   ebx, bx
                or      byte ptr [Map_Memory+ebx], MEMMAPF_STACK_WRITE
                call    PokeByte_NoMemMap
                ENDM

; bx = address
; ax = word result
POKEWORD        MACRO
                call    PokeWord
                ENDM

; returns HL/IX/IY in ax
GETHL           MACRO
                mov     al, Reg_UseIXIY
                .if     al == 0
                        mov     ax, Reg_HL
                .elseif al == UsingIX
                        mov     ax, Reg_IX
                .else
                        mov     ax, Reg_IY
                .endif
                ENDM

; Entry   : bx = Z80 memory address
; Returns : pointer to Z80 memory address in esi.
GETZ80ADDRESS   macro
                push    ebx
                shr     ebx, 11
                and     ebx, 28
                mov     esi, [currentMachine.RAMREAD0+ebx]
                pop     ebx
                and     ebx, 1FFFh
                add     esi, ebx
                endm

READ_OPCODE     macro
                mov     bx, Reg_PC
                M1_FETCH                    ; al = opcode
                SETTS   4                   ; 4 TStates for M1 cycle
                endm

FETCH_OPCODE    MACRO   lpOpcodeTable

                .if     Reg_HALTED
                        add     Reg_PC, 1   ; halted state refetches the opcode after HALT so contend on that PC address
                        READ_OPCODE

                        mov     al, 076h    ; HALT opcode
                        lea     ecx, Op76   ; preload handler for HALT, this will decrement PC back to HALT for next loop

                .else
                        .if     DivIDEEnabled == TRUE
                                invoke  DivIDE_MemTestA

                                IFNB    <lpOpcodeTable>
                                mov     ecx, lpOpcodeTable
                                ENDIF

                                READ_OPCODE

                                push    eax
                                push    ecx
                                invoke  DivIDE_MemTestB
                                pop     ecx
                                pop     eax
                        .else
                                IFNB    <lpOpcodeTable>
                                mov     ecx, lpOpcodeTable
                                ENDIF
        
                                READ_OPCODE
                        .endif

                        IFNB    <lpOpcodeTable>
                        mov     ecx, [ecx+eax*4]
                        ENDIF

                        add     Reg_PC, 1
                .endif

                add     Reg_R, 1
                add     Reg_InsLength, 1
                ENDM

; ax = value to push
PUSHSTACK       MACRO
                ror     ax, 8           ; swap low/high byte order
                mov     bx, Reg_SP
                sub     Reg_SP, 2
                dec     bx
                POKESTACKBYTE           ; PUSH high byte
                dec     bx
                SETTS   3
                mov     al, ah          ; PUSH low byte
                POKESTACKBYTE
                SETTS   3

                mov     Reg_MemoryWriteAddress, bx    ; address low byte
                mov     Reg_MemoryWriteEvent, MEMACCESSWORD
                ENDM


; ax receives popped value
POPSTACK        MACRO
                mov     bx, Reg_SP
                add     Reg_SP, 2
                GETSTACKWORD
                ENDM

; ax = call address
Z80CALL         MACRO
                mov     cx, Reg_PC
                mov     Reg_PC, ax
                mov     ax, cx
                PUSHSTACK

                inc     RETCounter
                ENDM

Z80RET          MACRO
                POPSTACK
                mov     Reg_PC, ax
                mov     Reg_MemPtr, ax

                dec     RETCounter
                ENDM

FLAGS_MODIFIED              macro   state:=<FALSE>
                            mov     Reg_Q, state
                            endm

;############################################################################################

RUNZ80INSTR     MACRO
                call    ExecZ80Opcode
                CHECKESI                ; checks esi points to RegisterBase in debug build
                ENDM


    ENDIF   ;/_Z80CORE_INC_

