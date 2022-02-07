
; ********************* (FD/DD) CB opcode macros *********************

z80m_getCBindexoctal    macro   arg:req
                        t_prefix = 0
                        t_octal = @ITEMINLIST (arg, <b,c,d,e,h,l,(hl),a>)
                        if      t_octal eq 0
                                .err    <*** Invalid argument for octal range ***>
                        endif
                        t_octal = t_octal -1
                        exitm   %t_octal
                        endm

z80m_CBopcodeoctalrange macro   arg1:req, baseopcode:req

                        if      argtype eq z80type_index_mem
                                z80m_storebyte  argixiy         ; fd/dd prefix
                                z80m_storebyte  0cbh            ; cb prefix
                                z80m_storebyte  argval          ; index offset
                                z80m_storebyte  baseopcode+6    ; use (hl) variant
                                z80_PC = z80_PC + 4
                                exitm
                        endif

                        regoctal1 = z80m_getCBindexoctal (arg1)
                        z80m_storebyte  0cbh            ; cb prefix
                        z80m_storebyte  baseopcode + regoctal1
                        z80_PC = z80_PC + 2
                        endm

z80_rlc                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 0h
                        endm

z80_rrc                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 8h
                        endm

z80_rl                  macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 10h
                        endm

z80_rr                  macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 18h
                        endm

z80_sla                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 20h
                        endm

z80_sra                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 28h
                        endm

z80_sll                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 30h
                        endm

z80_sls                 macro   arg1:req    ; pseudonym for sll
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 30h
                        endm

z80_srl                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, 38h
                        endm

z80_bitsetreset         macro   bitnum:req, arg1:req, baseopcode:req
                        if      bitnum gt 7
                                .err    <*** Invalid bit number for opcode ***>
                        endif
                        z80m_decodearg  arg1
                        z80m_CBopcodeoctalrange arg1, baseopcode + (bitnum * 8)
                        endm

z80_bit                 macro   bitnum:req, arg1:req
                        z80_bitsetreset bitnum, arg1, 40h
                        endm

z80_res                 macro   bitnum:req, arg1:req
                        z80_bitsetreset bitnum, arg1, 80h
                        endm

z80_set                 macro   bitnum:req, arg1:req
                        z80_bitsetreset bitnum, arg1, 0c0h
                        endm


