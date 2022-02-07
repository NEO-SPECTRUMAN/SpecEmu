
; ********************* non-prefixed opcode macros *********************

z80m_branchconditionals macro   arg:req
                        t_tmp = @ITEMINLIST (arg, <nz,z,nc,c,po,pe,p,m>)
                        if      t_tmp eq 0
                        endif
                        endm

z80m_getindexoctal      macro   arg:req
                        t_prefix = 0
                        t_octal = @ITEMINLIST (arg, <b,c,d,e,h,l,(hl),a,ixh,ixl,iyh,iyl>)
                        if      t_octal eq 0
                                .err    <*** Invalid argument for octal range ***>
                        endif
                        t_octal = t_octal -1
                        if      t_octal ge 8  ; index range
                                if  t_octal ge 10
                                    t_prefix = 0fdh
                                    t_octal = t_octal - 6   ; iyh/iyl to h/l
                                else
                                    t_prefix = 0ddh
                                    t_octal = t_octal - 4   ; ixh/ixl to h/l
                                endif
                        endif
                        exitm   %t_octal
                        endm

; if immopcode is 0, this opcode has no immediate argument opcode and is an error
z80m_opcodeoctalrange   macro   arg1:req, baseopcode:req, immopcode:=<0>

                        if      argtype eq z80type_immediate
                                .erridni    <immopcode>, <0>, <*** This opcode has no immediate value variant ***>

                                z80m_storebyte  immopcode                   ; immediate variant opcode
                                z80m_storeconstbyte  argval, argconstreg    ; immediate argument
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        if      argtype eq z80type_index_mem
                                z80m_storebyte  argixiy         ; dd/fd prefix
                                z80m_storebyte  baseopcode+6    ; use (hl) variant
                                z80m_storebyte  argval          ; index offset
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                        regoctal1 = z80m_getindexoctal (arg1)
                        if      t_prefix ne 0
                                z80m_storebyte  t_prefix
                                z80_PC = z80_PC + 1
                        endif
                        z80m_storebyte  baseopcode + t_octal
                        z80_PC = z80_PC + 1
                        endm


z80_and                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_opcodeoctalrange   arg1, 0a0h, 0e6h
                        endm

z80_xor                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_opcodeoctalrange   arg1, 0a8h, 0eeh
                        endm

z80_or                  macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_opcodeoctalrange   arg1, 0b0h, 0f6h
                        endm

z80_cp                  macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_opcodeoctalrange   arg1, 0b8h, 0feh
                        endm

z80_add                 macro   arg1:req, arg2:req
                        z80m_decode_dest_src    arg1, arg2

                        ifidni  <arg1>, <a>
                                ; add a,reg8/imm
                                z80m_opcodeoctalrange   arg2, 80h, 0C6h
                                exitm
                        endif
                                ; both must be 16 bit registers
                        if      (arg1type eq z80type_16bitregister) and (arg2type eq z80type_16bitregister)
                                ; add hl/ix/iy,reg16

                                t_tmp1 = @ITEMINLIST (arg1, <hl,ix,iy>)
                                if  t_tmp1 ne 0
                                    ; dest is one of hl,ix,iy

                                    t_tmp2 = @ITEMINLIST (arg2, <hl,ix,iy>)
                                    if      t_tmp2 ne 0
                                            ; if source is also one of hl,ix,iy then it must be the same one
                                            if  t_tmp1 ne t_tmp2
                                                .err    <*** Invalid arguments for ADD ***>
                                                exitm
                                            endif
                                    endif

                                    t_tmp1 = t_tmp1 - 1     ; hl,ix,iy = 0/1/2
                                    if  t_tmp1 ge 1
                                        z80m_storebyte  ((t_tmp1 - 1) * 20h) + 0DDh  ; write the index prefix
                                        z80_PC = z80_PC + 1
                                    endif

                                    t_tmp2 = @ITEMINLIST (arg2, <bc,de,hl,sp,ix,iy>)
                                    if      t_tmp2 eq 0
                                            .err    <*** Invalid arguments for ADD ***>
                                            exitm
                                    endif
                                    t_tmp2 = t_tmp2 - 1
                                    if      t_tmp2 ge 4     ; if either ix and iy
                                            t_tmp2 = 2      ; then set to hl
                                    endif

                                    z80m_storebyte  (t_tmp2 * 10h) + 09h
                                    z80_PC = z80_PC + 1
                                    exitm
                                endif
                        endif

                        .err    <*** Invalid arguments for ADD ***>
                        endm

z80_adc                 macro   arg1:req, arg2:req
                                ; adc a,reg8/imm
                        ifidni  <arg1>, <a>
                                z80m_decodearg  arg2
                                z80m_opcodeoctalrange   arg2, 88h, 0ceh
                                exitm
                        endif

                        ifidni  <arg1>, <hl>
                                ; adc hl,bc/de/hl/sp
                                t_tmp = @ITEMINLIST (arg2, <bc,de,hl,sp>)
                                if      t_tmp ne 0
                                        t_tmp = t_tmp - 1
                                        z80m_storebyte  0EDh
                                        z80m_storebyte  04Ah + (t_tmp * 10h)
                                        z80_PC = z80_PC + 2
                                        exitm
                                endif
                        endif

                        .err    <*** Invalid arguments for ADC ***>
                        endm

z80_sbc                 macro   arg1:req, arg2:req
                                ; sbc a,reg8/imm
                        ifidni  <arg1>, <a>
                                z80m_decodearg  arg2
                                z80m_opcodeoctalrange   arg2, 98h, 0DEh
                                exitm
                        endif

                        ifidni  <arg1>, <hl>
                                ; sbc hl,bc/de/hl/sp
                                t_tmp = @ITEMINLIST (arg2, <bc,de,hl,sp>)
                                if      t_tmp ne 0
                                        t_tmp = t_tmp - 1
                                        z80m_storebyte  0EDh
                                        z80m_storebyte  042h + (t_tmp * 10h)
                                        z80_PC = z80_PC + 2
                                        exitm
                                endif
                        endif

                        .err    <Invalid arguments for SBC>
                        endm

z80_sub                 macro   arg1:req
                        z80m_decodearg  arg1
                        z80m_opcodeoctalrange   arg1, 90h, 0D6h
                        endm

z80_inc                 macro   arg1:req
                        t_prefix = 0

                        z80m_decodearg  arg1
                        if      argtype eq z80type_8bitregister
                                t_tmp = @ITEMINLIST (arg1, <b,c,d,e,h,l,a,ixh,ixl,iyh,iyl>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid argument for INC ***>
                                        exitm
                                endif
                                t_tmp = t_tmp - 1
                                if      t_tmp ge 7              ; index range
                                        if  t_tmp ge 9
                                            t_prefix = 0fdh
                                            t_tmp = t_tmp - 5   ; iyh/iyl to h/l
                                        else
                                            t_prefix = 0ddh
                                            t_tmp = t_tmp - 3   ; ixh/ixl to h/l
                                        endif
                                endif

                                if      t_tmp eq 6
                                        ; inc a
                                        z80m_storebyte  3ch
                                else
                                        if  t_prefix ne 0
                                            z80m_storebyte  t_prefix
                                        endif
                                        z80m_storebyte  04h + (8 * t_tmp)
                                endif
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        if      (argtype eq z80type_bcdehl_mem) and (argitem eq 2)  ; argitem = 0 for (bc), 1 for (de), 2 for (hl)
                                ; (hl)
                                z80m_storebyte  34h
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        if      argtype eq z80type_index_mem
                                ; (ii+d)
                                z80m_storebyte  argixiy     ; prefix
                                z80m_storebyte  34h
                                z80m_storebyte  argval      ; offset
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                        if      argtype eq z80type_16bitregister
                                t_tmp = @ITEMINLIST (arg1, <bc,de,hl,sp,ix,iy>) - 1
                                if      t_tmp ge 4
                                        z80m_storebyte  ((t_tmp - 4) * 20h) + 0DDh
                                        t_tmp = 2
                                        z80_PC = z80_PC + 1
                                endif
                                z80m_storebyte  (t_tmp * 10h) + 03h
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        .err    <Invalid arguments for INC>
                        endm

z80_dec                 macro   arg1:req
                        t_prefix = 0

                        z80m_decodearg  arg1
                        if      argtype eq z80type_8bitregister
                                t_tmp = @ITEMINLIST (arg1, <b,c,d,e,h,l,a,ixh,ixl,iyh,iyl>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid argument for DEC ***>
                                        exitm
                                endif
                                t_tmp = t_tmp - 1
                                if      t_tmp ge 7              ; index range
                                        if  t_tmp ge 9
                                            t_prefix = 0fdh
                                            t_tmp = t_tmp - 5   ; iyh/iyl to h/l
                                        else
                                            t_prefix = 0ddh
                                            t_tmp = t_tmp - 3   ; ixh/ixl to h/l
                                        endif
                                endif

                                if      t_tmp eq 6
                                        ; dec a
                                        z80m_storebyte  03Dh
                                else
                                        if  t_prefix ne 0
                                            z80m_storebyte  t_prefix
                                        endif
                                        z80m_storebyte  05h + (8 * t_tmp)
                                endif
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        if      (argtype eq z80type_bcdehl_mem) and (argitem eq 2)  ; argitem = 0 for (bc), 1 for (de), 2 for (hl)
                                ; (hl)
                                z80m_storebyte  35h
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        if      argtype eq z80type_index_mem
                                ; (ii+d)
                                z80m_storebyte  argixiy     ; prefix
                                z80m_storebyte  35h
                                z80m_storebyte  argval      ; offset
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                        if      argtype eq z80type_16bitregister
                                t_tmp = @ITEMINLIST (arg1, <bc,de,hl,sp,ix,iy>) - 1
                                if      t_tmp ge 4
                                        z80m_storebyte  ((t_tmp - 4) * 20h) + 0DDh
                                        t_tmp = 2
                                        z80_PC = z80_PC + 1
                                endif
                                z80m_storebyte  (t_tmp * 10h) + 0Bh
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        .err    <Invalid arguments for DEC>
                        endm

z80_ld                  macro   arg1:req, arg2:req

                        t_prefix = 0

                        z80m_decode_dest_src    arg1, arg2

                                ; ld reg8,reg8/imm
                        if      arg1type eq z80type_8bitregister
                                regoctal1 = @ITEMINLIST (arg1, <b,c,d,e,h,l,(hl),a,ixh,ixl,iyh,iyl>) -1
                                regoctal2 = @ITEMINLIST (arg2, <b,c,d,e,h,l,(hl),a,ixh,ixl,iyh,iyl>) -1

                                if      regoctal1 ge 8  ; index range
                                        if  regoctal1 ge 10
                                            t_prefix = 0fdh
                                            regoctal1 = regoctal1 - 6   ; iyh/iyl to h/l
                                        else
                                            t_prefix = 0ddh
                                            regoctal1 = regoctal1 - 4   ; ixh/ixl to h/l
                                        endif
                                endif

                                if      regoctal2 ge 8  ; index range
                                        if  regoctal2 ge 10
                                            t_prefix = 0fdh
                                            regoctal2 = regoctal2 - 6   ; iyh/iyl to h/l
                                        else
                                            t_prefix = 0ddh
                                            regoctal2 = regoctal2 - 4   ; ixh/ixl to h/l
                                        endif
                                endif

                                if      t_prefix ne 0
                                        z80m_storebyte  t_prefix
                                        z80_PC = z80_PC + 1
                                endif

                                if      arg2type eq z80type_8bitregister
                                        ; ld reg8,reg8
                                        z80m_storebyte  40h + (8 * regoctal1) + regoctal2
                                        z80_PC = z80_PC + 1
                                        exitm

                                elseif  arg2type eq z80type_immediate
                                        ; ld reg8,imm
                                        z80m_storebyte  6 + (8 * regoctal1)
                                        z80m_storeconstbyte  arg2val, arg2constreg  ; immediate argument
                                        z80_PC = z80_PC + 2
                                        exitm
                                endif
                        endif

                                ; ld reg8,(bc/de/hl)
                        if      (arg1type eq z80type_8bitregister) and (arg2type eq z80type_bcdehl_mem)
                                ; arg1/2item = 0 for (bc), 1 for (de), 2 for (hl)
                                if      arg2item lt 2
                                        ; (bc), (de)
                                        z80m_storebyte  0ah + (arg2item * 16)
                                        z80_PC = z80_PC + 1
                                        exitm
                                else
                                        ;(hl)
                                        regoctal1 = @ITEMINLIST (arg1, <b,c,d,e,h,l,(hl),a>) -1
                                        z80m_storebyte  46h + (8 * regoctal1)
                                        z80_PC = z80_PC + 1
                                        exitm
                                endif
                        endif

                                ; ld (bc/de/hl),reg8
                        if      (arg1type eq z80type_bcdehl_mem) and (arg2type eq z80type_8bitregister)
                                ; arg1/2item = 0 for (bc), 1 for (de), 2 for (hl)
                                if      arg1item lt 2
                                        ; (bc), (de)
                                        z80m_storebyte  02h + (arg1item * 16)
                                        z80_PC = z80_PC + 1
                                        exitm
                                else
                                        ;(hl)
                                        regoctal2 = @ITEMINLIST (arg2, <b,c,d,e,h,l,(hl),a>) -1
                                        z80m_storebyte  70h + regoctal2
                                        z80_PC = z80_PC + 1
                                        exitm
                                endif
                        endif

                                ; ld (hl),imm
                        if      (arg1type eq z80type_bcdehl_mem) and (arg2type eq z80type_immediate)
                                ; arg1/2item = 0 for (bc), 1 for (de), 2 for (hl)
                                if      arg1item eq 2
                                        ; (hl)
                                        z80m_storebyte  36h
                                        z80m_storeconstbyte  arg2val, arg2constreg  ; immediate argument
                                        z80_PC = z80_PC + 2
                                        exitm
                                else
                                        .err    <*** Only LD (HL),n allowed ***>
                                endif
                        endif

                                ; ld (ii+n),imm
                        if      (arg1type eq z80type_index_mem) and (arg2type eq z80type_immediate)
                                z80m_storebyte  arg1ixiy    ; dd or fd
                                z80m_storebyte  36h
                                z80m_storebyte  arg1val                     ; index offset value
                                z80m_storeconstbyte  arg2val, arg2constreg  ; immediate argument
                                z80_PC = z80_PC + 4
                                exitm
                        endif

                                ; ld reg8,(ii+d)
                        if      (arg1type eq z80type_8bitregister) and (arg2type eq z80type_index_mem)
                                regoctal1 = @ITEMINLIST (arg1, <b,c,d,e,h,l,(hl),a>) -1

                                z80m_storebyte  arg2ixiy    ; dd or fd
                                z80m_storebyte  46h + (8 * regoctal1)
                                z80m_storebyte  arg2val     ; index offset value
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                                ; ld (ii+d),reg8
                        if      (arg1type eq z80type_index_mem) and (arg2type eq z80type_8bitregister)
                                regoctal1 = @ITEMINLIST (arg2, <b,c,d,e,h,l,(hl),a>) -1

                                z80m_storebyte  arg1ixiy    ; dd or fd
                                z80m_storebyte  70h + regoctal1
                                z80m_storebyte  arg1val     ; index offset value
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                                ; ld reg16,imm
                        if      (arg1type eq z80type_16bitregister) and (arg2type eq z80type_immediate)
                                regoctal1 = @ITEMINLIST (arg1, <bc,de,hl,sp,ix,iy>) -1
                                if      regoctal1 le 3
                                        ; ld bc/de/hl/sp,imm
                                        z80m_storebyte  1 + (10h * regoctal1)
                                        z80m_storeconstword arg2val, arg2constreg
                                        z80_PC = z80_PC + 3
                                        exitm
                                elseif  regoctal1 ge 4
                                        ; ld ix/iy,imm
                                        z80m_storebyte  0ddh + 20h * (regoctal1 - 4)
                                        z80m_storebyte  21h
                                        z80m_storeconstword arg2val, arg2constreg
                                        z80_PC = z80_PC + 4
                                        exitm
                                endif
                        endif

                                ; ld sp,hl/ix/iy
                        if      (arg1type eq z80type_16bitregister) and (arg2type eq z80type_16bitregister)
                                ifidni  <arg1>, <sp>
                                        regoctal1 = @ITEMINLIST (arg2, <hl,ix,iy>)
                                        if      regoctal1 ne 0
                                                regoctal1 = regoctal1 - 1
                                                if      regoctal1 ge 1
                                                        z80m_storebyte  ((regoctal1 - 1) * 20h) + 0ddh   ; dd or fd
                                                        z80_PC = z80_PC + 1
                                                endif
                                                z80m_storebyte  0F9h
                                                z80_PC = z80_PC + 1
                                                exitm
                                        else
                                                .err    <*** Only LD SP,HL/IX/IY allowed ***>
                                        endif
                                endif
                        endif

                                ; ld a,(mem)
                        if      (arg1type eq z80type_8bitregister) and (arg2type eq z80type_bracketimmediate)
                                .errdifi    <arg1>, <a>, <*** Only A register allowed ***>

                                z80m_storebyte  3ah
                                z80m_storeconstword  arg2val, arg2constreg  ; immediate argument
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                                ; ld (mem),a
                        if      (arg1type eq z80type_bracketimmediate) and (arg2type eq z80type_8bitregister)
                                .errdifi    <arg2>, <a>, <*** Only A register allowed ***>

                                z80m_storebyte  32h
                                z80m_storeconstword  arg1val, arg1constreg  ; immediate argument
                                z80_PC = z80_PC + 3
                                exitm
                        endif

                                ; ld reg16,(mem)
                        if      (arg1type eq z80type_16bitregister) and (arg2type eq z80type_bracketimmediate)
                                tmpldreg = @ITEMINLIST (arg1, <bc,de,hl,sp,ix,iy>) -1
                                if      tmpldreg ge 4
                                        ; ix/iy?
                                        z80m_storebyte  ((tmpldreg - 4) * 20h) + 0ddh   ; dd or fd
                                        z80_PC = z80_PC + 1
                                        tmpldreg = 2    ; and treat as hl
                                endif
                                if      tmpldreg eq 0
                                        z80m_storeword  4bedh   ; bc
                                        z80_PC = z80_PC + 2
                                elseif  tmpldreg eq 1
                                        z80m_storeword  5bedh   ; de
                                        z80_PC = z80_PC + 2
                                elseif  tmpldreg eq 2
                                        z80m_storebyte  2ah     ; hl
                                        z80_PC = z80_PC + 1
                                elseif  tmpldreg eq 3
                                        z80m_storeword  7bedh   ; sp
                                        z80_PC = z80_PC + 2
                                endif
                                z80m_storeconstword arg2val, arg2constreg   ; immediate argument
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                                ; ld (mem),reg16
                        if      (arg1type eq z80type_bracketimmediate) and (arg2type eq z80type_16bitregister)
                                tmpldreg = @ITEMINLIST (arg2, <bc,de,hl,sp,ix,iy>) -1
                                if      tmpldreg ge 4
                                        ; ix/iy?
                                        z80m_storebyte  ((tmpldreg - 4) * 20h) + 0ddh   ; dd or fd
                                        z80_PC = z80_PC + 1
                                        tmpldreg = 2    ; and treat as hl
                                endif
                                if      tmpldreg eq 0
                                        z80m_storeword  43edh   ; bc
                                        z80_PC = z80_PC + 2
                                elseif  tmpldreg eq 1
                                        z80m_storeword  53edh   ; de
                                        z80_PC = z80_PC + 2
                                elseif  tmpldreg eq 2
                                        z80m_storebyte  22h     ; hl
                                        z80_PC = z80_PC + 1
                                elseif  tmpldreg eq 3
                                        z80m_storeword  73edh   ; sp
                                        z80_PC = z80_PC + 2
                                endif
                                z80m_storeconstword  arg1val, arg1constreg  ; immediate argument
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                                ; ld a,i/r
                        if      (arg1type eq z80type_8bitregister) and (arg2type eq z80type_IR)
                                ; arg2item = 0 for I, 1 for R
                                z80m_storebyte  0edh
                                z80m_storebyte  57h + (arg2item * 8)
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                                ; ld i/r,a
                        if      (arg1type eq z80type_IR) and (arg2type eq z80type_8bitregister)
                                ; arg1item = 0 for I, 1 for R
                                z80m_storebyte  0edh
                                z80m_storebyte  47h + (arg1item * 8)
                                z80_PC = z80_PC + 2
                                exitm
                        endif

                        .err    <*** Unknown LD opcode ***>
                        echo    <arg1>,<arg2>

                        endm


z80_nop                 macro
                        z80m_storebyte  0
                        z80_PC = z80_PC + 1
                        endm

z80_jp                  macro   args:VARARG
                        arg1 textequ <getarg (1, args)>

                        t_tmp = @ITEMINLIST (arg1, <(hl),(ix),(iy)>)
                        if      t_tmp ne 0
                                if      t_tmp ge 2
                                        z80m_storebyte  0DDh + (20h * (t_tmp - 2))  ; write prefix byte for ix/iy
                                        z80_PC = z80_PC + 1
                                endif
                                z80m_storebyte  0E9h    ; jp (hl)
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        t_count = argcount (args)
                        if      t_count eq 2
                                t_tmp = @ITEMINLIST (arg1, <nz,z,nc,c,po,pe,p,m>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid branch condition for JP ***>
                                        exitm
                                endif
                                z80m_storebyte  0C2h + (8 * (t_tmp - 1))
                                arg1 textequ <getarg (2, args)>
                        else
                                z80m_storebyte  0C3h
                        endif
                        z80m_storeword  z80m_get16bit(%arg1)
                        z80_PC = z80_PC + 3
                        endm

z80_djnz                macro   arg:req
                        z80m_storebyte  10h
                        z80_PC = z80_PC + 2
                        z80m_storebyte  z80m_getrelativedisp(arg)
                        endm

z80_jr                  macro   args:VARARG
                        arg1 textequ <getarg (1, args)>
                        t_count = argcount (args)
                        if      t_count eq 2
                                t_tmp = @ITEMINLIST (arg1, <nz,z,nc,c>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid branch condition for JR ***>
                                        exitm
                                endif
                                z80m_storebyte  20h + (8 * (t_tmp - 1))
                                arg1 textequ <getarg (2, args)>
                        else
                                z80m_storebyte  18h
                        endif
                        z80_PC = z80_PC + 2
                        z80m_storebyte  z80m_getrelativedisp(%arg1)
                        endm

z80_call                macro   args:VARARG
                        arg1 textequ <getarg (1, args)>
                        t_count = argcount (args)
                        if      t_count eq 2
                                t_tmp = @ITEMINLIST (arg1, <nz,z,nc,c,po,pe,p,m>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid branch condition for CALL ***>
                                        exitm
                                endif
                                z80m_storebyte  0C4h + (8 * (t_tmp - 1))
                                arg1 textequ <getarg (2, args)>
                        else
                                z80m_storebyte  0CDh
                        endif
                        z80m_storeword  z80m_get16bit(%arg1)
                        z80_PC = z80_PC + 3
                        endm

z80_ret                 macro   args:VARARG
                        t_count = argcount (args)
                        if      t_count eq 0
                                z80m_storebyte  0C9h
                                z80_PC = z80_PC + 1
                                exitm
                        endif

                        arg1 textequ <getarg (1, args)>
                        t_tmp = @ITEMINLIST (arg1, <nz,z,nc,c,po,pe,p,m>)
                        if      t_tmp eq 0
                                .err    <*** Invalid branch condition for RET ***>
                                exitm
                        endif
                        z80m_storebyte  0C0h + (8 * (t_tmp - 1))
                        z80_PC = z80_PC + 1
                        endm

z80_rst                 macro   arg:req
                        z80m_decodearg  arg
                        if      argtype ne z80type_immediate
                                .err    <*** RST only accepts immediate values ***>
                        endif

                        t_tmp = argval shr 3
                        if      ((argval mod 8) ne 0) or (t_tmp gt 7)
                                .err    <Invalid value for RST>
                        endif

                        z80m_storebyte  0C7h + (8 * t_tmp)
                        z80_PC = z80_PC + 1
                        endm

z80_rlca                macro
                        z80m_storebyte  07h
                        z80_PC = z80_PC + 1
                        endm

z80_rrca                macro
                        z80m_storebyte  0Fh
                        z80_PC = z80_PC + 1
                        endm

z80_rla                 macro
                        z80m_storebyte  17h
                        z80_PC = z80_PC + 1
                        endm

z80_rra                 macro
                        z80m_storebyte  1Fh
                        z80_PC = z80_PC + 1
                        endm

z80_daa                 macro
                        z80m_storebyte  27h
                        z80_PC = z80_PC + 1
                        endm

z80_cpl                 macro
                        z80m_storebyte  2Fh
                        z80_PC = z80_PC + 1
                        endm

z80_scf                 macro
                        z80m_storebyte  37h
                        z80_PC = z80_PC + 1
                        endm

z80_ccf                 macro
                        z80m_storebyte  3Fh
                        z80_PC = z80_PC + 1
                        endm

z80_halt                macro
                        z80m_storebyte  76h
                        z80_PC = z80_PC + 1
                        endm

z80_ex                  macro   arg1:req, arg2:req
                        ifidni  <arg1>, <af>
                                ifidni  <arg2>, <af>
                                        z80m_storebyte  08h
                                        z80_PC = z80_PC + 1
                                        exitm
                                endif
                        endif
                        ifidni  <arg1>, <de>
                                ifidni  <arg2>, <hl>
                                        z80m_storebyte  0EBh
                                        z80_PC = z80_PC + 1
                                        exitm
                                endif
                        endif
                        ifidni  <arg1>, <(sp)>
                                t_tmp = @ITEMINLIST (arg2, <hl,ix,iy>)
                                if      t_tmp eq 0
                                        .err    <*** Invalid register for EX (SP),reg16 ***>
                                        exitm
                                endif
                                t_tmp = t_tmp - 1
                                if      t_tmp ge 1
                                        z80m_storebyte  (20h * (t_tmp - 1)) + 0DDh  ; write index prefix
                                        z80_PC = z80_PC + 1
                                endif
                                z80m_storebyte  0E3h
                                z80_PC = z80_PC + 1
                                exitm
                        endif
                        .err    <*** Invalid argument for EX ***>
                        endm

z80_exx                 macro
                        z80m_storebyte  0D9h
                        z80_PC = z80_PC + 1
                        endm

z80_di                  macro
                        z80m_storebyte  0F3h
                        z80_PC = z80_PC + 1
                        endm

z80_ei                  macro
                        z80m_storebyte  0FBh
                        z80_PC = z80_PC + 1
                        endm

z80_push                macro   arg:req
                        t_tmp = @ITEMINLIST (arg, <bc,de,hl,af,ix,iy>)
                        if      t_tmp eq 0
                                .err    <*** Invalid register for PUSH ***>
                                exitm
                        endif
                        t_tmp = t_tmp - 1
                        if      t_tmp ge 4
                                z80m_storebyte  (20h * (t_tmp - 4)) + 0DDh  ; write index prefix
                                z80_PC = z80_PC + 1
                                t_tmp = 2                                   ; set t_tmp to hl variant
                        endif
                        z80m_storebyte  (10h * t_tmp) + 0C5h
                        z80_PC = z80_PC + 1
                        endm

z80_pop                 macro   arg:req
                        t_tmp = @ITEMINLIST (arg, <bc,de,hl,af,ix,iy>)
                        if      t_tmp eq 0
                                .err    <*** Invalid register for POP ***>
                                exitm
                        endif
                        t_tmp = t_tmp - 1
                        if      t_tmp ge 4
                                z80m_storebyte  (20h * (t_tmp - 4)) + 0DDh  ; write index prefix
                                z80_PC = z80_PC + 1
                                t_tmp = 2                                   ; set t_tmp to hl variant
                        endif
                        z80m_storebyte  (10h * t_tmp) + 0C1h
                        z80_PC = z80_PC + 1
                        endm





