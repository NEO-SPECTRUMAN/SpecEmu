
; ********************* ED opcode macros *********************

z80_ldi                 macro
                        z80m_storeword  0a0edh
                        z80_PC = z80_PC + 2
                        endm

z80_cpi                 macro
                        z80m_storeword  0a1edh
                        z80_PC = z80_PC + 2
                        endm

z80_ini                 macro
                        z80m_storeword  0a2edh
                        z80_PC = z80_PC + 2
                        endm

z80_outi                macro
                        z80m_storeword  0a3edh
                        z80_PC = z80_PC + 2
                        endm

z80_ldd                 macro
                        z80m_storeword  0a8edh
                        z80_PC = z80_PC + 2
                        endm

z80_cpd                 macro
                        z80m_storeword  0a9edh
                        z80_PC = z80_PC + 2
                        endm

z80_ind                 macro
                        z80m_storeword  0aaedh
                        z80_PC = z80_PC + 2
                        endm

z80_outd                macro
                        z80m_storeword  0abedh
                        z80_PC = z80_PC + 2
                        endm

z80_ldir                macro
                        z80m_storeword  0b0edh
                        z80_PC = z80_PC + 2
                        endm

z80_cpir                macro
                        z80m_storeword  0b1edh
                        z80_PC = z80_PC + 2
                        endm

z80_inir                macro
                        z80m_storeword  0b2edh
                        z80_PC = z80_PC + 2
                        endm

z80_otir                macro
                        z80m_storeword  0b3edh
                        z80_PC = z80_PC + 2
                        endm

z80_lddr                macro
                        z80m_storeword  0b8edh
                        z80_PC = z80_PC + 2
                        endm

z80_cpdr                macro
                        z80m_storeword  0b9edh
                        z80_PC = z80_PC + 2
                        endm

z80_indr                macro
                        z80m_storeword  0baedh
                        z80_PC = z80_PC + 2
                        endm

z80_otdr                macro
                        z80m_storeword  0bbedh
                        z80_PC = z80_PC + 2
                        endm

z80_in                  macro   arg1:req, arg2:req
                        ifidni  <arg2>, <(c)>
                                ; IN r,(C)
                                t_tmp = @ITEMINLIST (arg1, <b,c,d,e,h,l,f,a>)
                                if  t_tmp eq 0
                                    .err    <Illegal destination register for IN opcode>
                                endif
                                t_tmp = t_tmp - 1
                                z80m_storebyte  0EDh
                                z80m_storebyte  40h + (t_tmp * 8)
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        ; IN A,(n)
                        .errdifi    <arg1>, <a>, <Illegal destination register for IN opcode>
                        z80m_decodearg  arg2
                        if      argtype eq z80type_bracketimmediate
                                z80m_storebyte  0DBh
                                z80m_storeconstbyte  argval, argconstreg    ; immediate argument
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        .err    <*** Unknown IN opcode ***>
                        endm

z80_out                 macro   arg1:req, arg2:req
                        ifidni  <arg1>, <(c)>
                                ; OUT (C),r and OUT (C),0
                                t_tmp = @ITEMINLIST (arg2, <b,c,d,e,h,l,0,a>)
                                if  t_tmp eq 0
                                    .err    <Illegal destination register for OUT opcode>
                                endif
                                t_tmp = t_tmp - 1
                                z80m_storebyte  0EDh
                                z80m_storebyte  41h + (t_tmp * 8)
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        ; OUT (n),A
                        .errdifi    <arg2>, <a>, <Illegal source register for OUT opcode>
                        z80m_decodearg  arg1
                        if      argtype eq z80type_bracketimmediate
                                z80m_storebyte  0D3h
                                z80m_storeconstbyte  argval, argconstreg    ; immediate argument
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        .err    <*** Unknown OUT opcode ***>
                        endm

z80_neg                 macro
                        z80m_storeword  44edh
                        z80_PC = z80_PC + 2
                        endm

z80_retn                macro
                        z80m_storeword  45edh
                        z80_PC = z80_PC + 2
                        endm

z80_reti                macro
                        z80m_storeword  4dedh
                        z80_PC = z80_PC + 2
                        endm

z80_im                  macro   arg1:req
                        ifidn       <arg1>, <0>
                                    t_tmp=46h
                        elseifidn   <arg1>, <1>
                                    t_tmp=56h
                        elseifidn   <arg1>, <2>
                                    t_tmp=5eh
                        else
                                    .err    <Illegal value for IM opcode>
                        endif
                        z80m_storebyte  0EDh
                        z80m_storebyte  t_tmp
                        z80_PC = z80_PC + 2
                        exitm
                        endm

