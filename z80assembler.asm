
z80_assemble            PROTO   :DWORD
z80_getobjectlength     PROTO
z80_storeasmbytes       PROTO   :DWORD,:DWORD
z80_storeasmbyte        PROTO   :BYTE
z80_storeasmwords       PROTO   :DWORD,:DWORD
z80_storeasmword        PROTO   :WORD
z80_fillasmbytes        PROTO   :DWORD,:BYTE

                        include z80opcodes.asm
                        include z80cbopcodes.asm
                        include z80edopcodes.asm
                        include z80assembler.inc

.data?
z80_lpDest              DWORD   ?
z80_lpOriginalDest      DWORD   ?

.data

.code
                        ; decode arg types
                        RESETENUM
                        ENUM    z80type_unknown
                        ENUM    z80type_8bitregister, z80type_16bitregister
                        ENUM    z80type_immediate, z80type_bracketimmediate
                        ENUM    z80type_bcdehl_mem, z80type_index_mem, z80type_IR
                        ENUM    z80type_quoted

z80m_decodearg          macro   arg:req

                        argtype = z80type_unknown
                        argstr  textequ <>
                        argitem = 0
                        argval  = 0
                        argixiy = 0
                        argconstreg textequ <>

                        if      @ITEMINLIST (arg, <ax,bx,cx,dx,si,di>) ne 0
                                argtype = z80type_immediate
                                argstr  textequ <arg>
                                argconstreg textequ <arg>
                                exitm
                        endif

                        if      @ITEMINLIST (arg, <al,bl,cl,dl,ah,bh,ch,dh>) ne 0
                                argtype = z80type_immediate
                                argstr  textequ <arg>
                                argconstreg textequ <arg>
                                exitm
                        endif

                        if      @ITEMINLIST (arg, <b,c,d,e,h,l,a,ixl,ixh,iyl,iyh>) ne 0
                                ; simple 8 bit register
                                argtype = z80type_8bitregister
                                argstr  textequ <arg>
                                exitm
                        endif

                        if      @ITEMINLIST (arg, <bc,de,hl,af,ix,iy,sp>) ne 0
                                ; simple 16 bit register
                                argtype = z80type_16bitregister
                                argstr  textequ <arg>
                                exitm
                        endif

                        ; test for 8 bit load/store to 16 bit register address
                        argitem = @ITEMINLIST (arg, <(bc),(de),(hl)>)
                        if      argitem ne 0
                                argtype = z80type_bcdehl_mem
                                argstr  textequ <arg>
                                argitem = argitem - 1   ; argitem = 0 for (bc), 1 for (de), 2 for (hl)
                                exitm
                        endif

                        ; test for "(ix" or "(iy" indexing
                        if      @SizeStr (arg) ge 6 ; (ix+n)
                                tmparg  substr <arg>, 1, 3
                                tmparg  catstr tmparg, <)>

                                indxmem = @ITEMINLIST (tmparg, <(ix),(iy>))
                                if      indxmem ne 0
                                        if      indxmem eq 1
                                                argixiy = 0ddh
                                        else
                                                argixiy = 0fdh
                                        endif

                                        tmpchr  substr <arg>, 4, 1  ; = "+" or "-"
                                        tsize   sizestr <arg>
                                        tmparg  substr <arg>, 5, tsize -5     ; remainder of string from pos 5, beyond "(ix+"

                                        argtype = z80type_index_mem
                                        argval  = z80m_get8bit(%tmparg)
                                        ifidn   tmpchr, <->
                                                argval  = -argval
                                        endif
                                        exitm
                                endif
                        endif

                        ; test for I, R argument
                        argitem = @ITEMINLIST (arg, <I,R>)
                        if      argitem ne 0
                                argtype = z80type_IR
                                argstr  textequ <arg>
                                argitem = argitem - 1   ; argitem = 0 for I, 1 for R
                                exitm
                        endif

                        ; test for "(immediate)" as in 16 bit register load/store from memory
                        tsize   sizestr <arg>
                        tmpchr  substr  <arg>, 1, 1
                        ifidn   tmpchr, <(>
                                tmpchr  substr  <arg>, tsize, 1
                                ifidn   tmpchr, <)>
                                        argtype = z80type_bracketimmediate
                                        argstr  substr <arg>, 2, tsize-2    ; unbracket immediate value
                                        ; test to see if immediate value is an x86 reg const
                                        if      @ITEMINLIST (argstr, <ax,bx,cx,dx,si,di,al,bl,cl,dl,ah,bh,ch,dh>) ne 0
                                                argconstreg textequ <argstr>
                                        else
                                                argval = z80m_get16bit(%argstr)
                                        endif
                                        exitm
                                endif
                        endif

                        ; test for quoted string
                        tsize   sizestr <arg>
                        tmpchr  substr  <arg>, 1, 1
                        ifidn   tmpchr, <">
                                tmpchr  substr  <arg>, tsize, 1
                                ifidn   tmpchr, <">
                                        argtype = z80type_quoted
                                        argstr  textequ <arg>   ; we don't strip quotes from quoted text
                                        exitm
                                endif
                        endif

                        ; fall back to immediate argument
                        argtype = z80type_immediate
                        argstr  textequ <arg>
                        argval = z80m_get16bit(arg)
                        endm

z80m_decode_dest_src    macro   arg1:req, arg2:req
                        z80m_decodearg  arg1
                        arg1type = argtype
                        arg1str  textequ <argstr>
                        arg1item = argitem
                        arg1val = argval
                        arg1ixiy = argixiy
                        arg1constreg    textequ <argconstreg>

                        z80m_decodearg  arg2
                        arg2type = argtype
                        arg2str  textequ <argstr>
                        arg2item = argitem
                        arg2val = argval
                        arg2ixiy = argixiy
                        arg2constreg    textequ <argconstreg>
                        endm


; ********************* support macros *********************

z80_ds                  macro   count:req, val:=<0>
                        local   cnt, cnttxt

                        cnt =   z80m_get16bit (count)

;                        cnttxt  textequ %cnt
;                        if      emitz80
;                               %echo   DS Count: cnttxt
;                        endif

                        if      cnt lt 0
                                .err    <*** DS Count < 0 ***>
                                exitm
                        endif

                        if      cnt gt 0
                                z80_PC = z80_PC + cnt
                                if      emitz80
                                        invoke  z80_fillasmbytes, cnt, val
                                endif
                        endif
                        endm

z80_db                  macro   arg8:VARARG
                        local   @db8
                        .data
                        @db8    db  arg8
                        .code
                        t_tmp = sizeof @db8
                        if      t_tmp gt 0
                                if      emitz80
                                        invoke  z80_storeasmbytes, addr @db8, t_tmp
                                endif
                                z80_PC = z80_PC + t_tmp
                        endif
                        endm

z80_dw                  macro   arg16:VARARG
                        local   @db16
                        .data
                        @db16    dw  arg16
                        .code
                        t_tmp = sizeof @db16/2
                        if      t_tmp gt 0
                                if      emitz80
                                        invoke  z80_storeasmwords, addr @db16, t_tmp
                                endif
                                z80_PC = z80_PC + (t_tmp * 2)
                        endif
                        endm

z80_defb                macro   args:vararg

                        for     @param, <args>
                                z80_label   @param
                                z80m_storebyte  0
                                z80_PC = z80_PC + 1
                        endm
                        endm

z80_defw                macro   args:vararg

                        for     @param, <args>
                                z80_label   @param
                                z80m_storeword  0
                                z80_PC = z80_PC + 2
                        endm
                        endm

z80_setloop             macro   loopreps:REQ
    z80HighLoopLab      textequ %(z80HighLoopLab + 1)
    z80LoopLab          textequ <z80HighLoopLab>

                        z80     push    hl
                        z80     ld      hl,loopreps

                       %z80    z80loop&z80LoopLab&:
                        z80     ex      (sp),hl
                        endm

z80_endloop             macro
                        z80     ex      (sp),hl
                        z80     dec     l
                        z80     jp      nz,z80loop&z80LoopLab&
                        z80     dec     h
                        z80     jp      p,z80loop&z80LoopLab&

                       %z80     z80extloop&z80LoopLab&:
                        z80     inc     sp
                        z80     inc     sp

        z80LoopLab      textequ %(z80LoopLab - 1)
                        endm

z80_breakloop           macro
                        z80     jp      z80extloop&z80LoopLab&
                        endm

z80_label               macro   newlab:req
                        local   intname, labaddr, labelname
                        intname textequ <newlab>
                       %ifidn   <intname>, <@@>
                                ifndef  localsym_curr
                                        localsym_curr = 0
                                endif
                                localsym_curr = localsym_curr + 1
                                intname textequ %localsym_curr
                                intname catstr  <localsym>, %intname
                        endif

                       %labelname   catstr  <z80lab_>, <intname>
                       %labelname = z80_PC
                        labaddr textequ %z80_PC

                        ; list label names on final pass
                        if      emitz80
                              ; %echo    Label: labelname labaddr
                        endif
                        endm

z80m_get16bit           macro   z80arg16:req
                        local   locallab, temp
                        if      pass ge 2
                                ifidni      <z80arg16>, <@F>
                                            temp        textequ %(localsym_curr + 1)
                                            %locallab    catstr  <z80lab_>, <localsym>, <temp>
                                            exitm   %locallab
                                elseifidni  <z80arg16>, <@B>
                                            temp        textequ %localsym_curr
                                            %locallab    catstr  <z80lab_>, <localsym>, <temp>
                                            exitm   %locallab
                                endif

                                ifdef   z80lab_&z80arg16&
                                        exitm    %z80lab_&z80arg16&
                                else
                                        temp    catstr  <0+>, <z80arg16>
                                        exitm    %temp and 65535
                                endif
                        else
                                exitm   %0
                        endif
                        endm

z80m_get8bit            macro   z80arg8:req
                        local   temp
                        temp = z80m_get16bit (z80arg8)
                        exitm   %temp and 255
                        endm

z80m_getrelativedisp    macro   z80arg8:req
                        local   target, disp, txt1, txt2
                        if      emitz80
                                target = z80m_get16bit (z80arg8)

                                if  target lt z80_PC
                                    disp = (target - z80_PC) and 255
                                    if      disp lt 80h
                                            .err    <*** Backwards relative displacement out of range ***>
                                            exitm   %0
                                    endif
                                else
                                    disp = target - z80_PC
                                    if      disp gt 7Fh
                                            .err    <*** Forwards relative displacement out of range ***>
                                            exitm   %0
                                    endif
                                endif
                                exitm    %disp
                        else
                                exitm   %0
                        endif
                        endm

z80_org                 macro   z80org:req
                        z80_PC  = z80org
                        endm

z80_crt                 macro   z80crt:VARARG
                        local   string

                        t_count = argcount (z80crt)
                        if      t_count eq 0
                                exitm
                        endif

                        for     @param, <z80crt>
                                %z80m_decodearg  @param

                                if      argtype eq z80type_immediate
                                        z80     ld      a,%argval
                                        z80     rst     16

                                elseif  argtype eq z80type_8bitregister
                                        z80_crt8    %argstr

                                elseif  argtype eq z80type_16bitregister
                                        z80_crt16   %argstr

                                elseif  argtype eq z80type_quoted
                                        string  textequ <argstr>
                                        string  substr  string, 2, tsize-2    ; unquote the quoted string
                                       %tsize   sizestr <string>

                                        if      tsize le 4
                                               %forc    $char, <string>
                                                        if      emitz80
                                                                mov     al,"&$char&"
                                                        endif
                                                        z80     ld      a,al
                                                        z80     rst     16
                                                endm
                                        else
                                                z80_crtquoted   %argstr
                                        endif
                                endif
                        endm

                        endm

z80_crtquoted           macro   z80quoted:req

                        if      _z80includecrt_ eq 0
                                _z80includecrt_ = 1

                                z80                 jr      _z80crtskip_

                                z80 _z80crtprt_:    ld      a,(de)
                                z80                 cp      255
                                z80                 ret     z
                                z80                 rst     16
                                z80                 inc     de
                                z80                 jr      _z80crtprt_

                                z80 _z80crtskip_:
                        endif

                        _z80crtptrcount_    = _z80crtptrcount_ + 1
                        _localcrt1_ catstr  <_z80crtlabel_>, %_z80crtptrcount_
                        _localcrt2_ catstr  <_z80crtexit_>,  %_z80crtptrcount_

                        z80                 jp      _localcrt2_
                        z80 _localcrt1_:    db      z80quoted ;z80crt
                        z80                 db      255

                        z80 _localcrt2_:
                        z80                 push    de
                        z80                 ld      de,_localcrt1_
                        z80                 call    _z80crtprt_
                        z80                 pop     de
                        endm

z80_crtnum              macro

                        if      _z80includecrtnum_ eq 0
                                _z80includecrtnum_ = 1

                                z80                         jr      _z80crtnumskip_

                                z80 _z80crtnumdigit_:       ld      a,"0"-1
                                z80 _z80crtnumdig_loop_:    inc     a
                                z80                         add     hl,bc
                                z80                         jr      c,_z80crtnumdig_loop_
                                z80                         sbc     hl,bc
                                z80                         cp      d   ;"0"?
                                z80                         jr      nz,_z80crtnumnonzero_

                                z80                         bit     0,e
                                z80                         ret     z

                                z80 _z80crtnumnonzero_:     rst     16
                                z80                         set     0,e
                                z80                         ret

                                z80 _z80crtnum16_:          push    af
                                z80                         push    bc
                                z80                         push    de

                                z80                         ld      de,("0" shl 8) or 0
                                z80                         ld      bc,65536-10000
                                z80                         call    _z80crtnumdigit_
                                z80                         ld      bc,65536-1000
                                z80                         call    _z80crtnumdigit_
                                z80                         jr      _z80crtnum8_1_

                                z80 _z80crtnum8_:           push    af
                                z80                         push    bc
                                z80                         push    de

                                z80                         ld      de,("0" shl 8) or 0
                                z80 _z80crtnum8_1_:         ld      bc,65536-100
                                z80                         call    _z80crtnumdigit_
                                z80                         ld      bc,65536-10
                                z80                         call    _z80crtnumdigit_

                                z80                         ld      a,d ;"0"
                                z80                         add     a,l
                                z80                         rst     16

                                z80                         pop     de
                                z80                         pop     bc
                                z80                         pop     af
                                z80                         ret

                                z80 _z80crtnumskip_:
                        endif
                        endm

z80_crthex              macro

                        if      _z80includecrthex_ eq 0
                                _z80includecrthex_ = 1

                                z80                         jr      _z80crthexskip_

                                z80 _z80crthex16_:          ld      a,h
                                z80                         call    _z80crthex8_1

                                z80 _z80crthex8_:           ld      a,l

                                z80 _z80crthex8_1:          push    af
                                z80                         rra
                                z80                         rra
                                z80                         rra
                                z80                         rra
                                z80                         call    _z80crthexdigit_
                                z80                         pop     af

                                z80 _z80crthexdigit_:       and     15
                                z80                         cp      10
                                z80                         sbc     a,69h
                                z80                         daa
                                z80                         rst     16
                                z80                         ret

                                z80 _z80crthexskip_:
                        endif
                        endm

z80_crt16               macro   arg16:req, ashex:=<0>
                        z80_crtnum

                        z80     push    hl

                        if          @ITEMINLIST (arg16, <af,bc,de,ix,iy>) ne 0
                                    z80     push    arg16
                                    z80     pop     hl
                        elseifidni  <arg16>, <sp>
                                    z80     ld      hl,2    ; +2 to account for the PUSH HL
                                    z80     add     hl,sp
                        elseifidni  <arg16>, <hl>
                                    ; do nothing for hl arg
                        else
                                    z80     ld      hl,arg16
                        endif

                        if      ashex eq 1
                                z80     call    _z80crthex16_
                        else
                                z80     call    _z80crtnum16_
                        endif

                        z80     pop     hl
                        endm

z80_crt8                macro   arg8:req, ashex:=<0>
                        z80_crtnum

                        z80     push    hl

                        t_tmp = @ITEMINLIST (arg8, <a,b,c,d,e,h,l,ixl,ixh,iyl,iyh>)
                        if      t_tmp ne 0
                                t_tmp = t_tmp - 1
                                if      t_tmp le 6
                                        ; a - l
                                        ; we only move 'arg8' to L if it isn't L, cos LD L,L would be dumb
                                        ifdifi  <arg8>, <l>
                                                z80     ld      l,arg8
                                        endif
                                        z80     ld      h,0
                                else
                                        ; ixl,ixh,iyl,iyh
                                        z80     push    af
                                        z80     ld      a,arg8
                                        z80     ld      l,a
                                        z80     ld      h,0
                                        z80     pop     af
                                endif
                        else
                                    ; immediate arg
                                    z80     ld      hl,arg8
                        endif

                        if      ashex eq 1
                                z80     call    _z80crthex8_
                        else
                                z80     call    _z80crtnum8_
                        endif

                        z80     pop     hl
                        endm

z80_crthex8             macro   arg8:req
                        z80_crthex

                        z80_crt8    arg8, 1
                        endm

z80_crthex16            macro   arg8:req
                        z80_crthex

                        z80_crt16   arg8, 1
                        endm

z80_for                 macro   LCV:req, args:VARARG

                        t_count = argcount (args)
                        if      t_count lt 2
                                .err    <*** Not enough FOR arguments ***>
                                exitm
                        endif

                        Start   textequ <getarg (1, args)>
                        Stop    textequ <getarg (2, args)>

                        ifndef  $$z80For&LCV&
                                $$z80For&LCV& = 0
                        else
                                $$z80For&LCV& = $$z80For&LCV& + 1
                        endif

                        ForLoop catstr  <_$For&LCV&_>,  %$$z80For&LCV&
                        NextLbl catstr  <_$Next&LCV&_>, %$$z80For&LCV&

                        z80     push    hl
                        z80     ld      hl,Start

                       %z80 &ForLoop&:
                        z80     ld      (LCV),hl

                        z80     push    de
                        z80     ld      de,Stop + 1
                        z80     or      a
                        z80     sbc     hl,de
                        z80     pop     de
                        z80     pop     hl
                        z80     jp      nc,NextLbl
                        endm

z80_next                macro   LCV:req

                        ForLoop catstr  <_$For&LCV&_>,  %$$z80For&LCV&
                        NextLbl catstr  <_$Next&LCV&_>, %$$z80For&LCV&

                        z80     push    hl
                        z80     ld      hl,(LCV)
                        z80     inc     hl
                        z80     jp      ForLoop

                       %z80 &NextLbl&:
endm

z80_align               macro   alignsize:req

                        $$align = ((z80_PC + (alignsize - 1)) and not (alignsize - 1)) - z80_PC

                        if      $$align gt 0
                                z80     ds      $$align, 0
                        endif
                        endm

z80_breakpoint          macro
                        invoke  AddBreakpoint, z80_PC
                        endm

z80_fillmem             macro   pMem:req, args:vararg

                        t_count = argcount (args)
                        if      t_count lt 1
                                .err    <*** Not enough MEMFILL arguments ***>
                                exitm
                        endif

                        bcount   textequ <getarg (1, args)>

                        if      t_count ge 2
                                fbyte   textequ <getarg (2, args)>

                                ifdifi  <fbyte>, <a>
                                        z80     ld      a,fbyte
                                endif
                        else
                                z80     xor     a   ; if no filler byte specified, use 0 for filler
                        endif

                        if      bcount eq 0
                                exitm
                        endif

                        if      _z80includefillmem_ eq 0
                                _z80includefillmem_ = 1

                                z80                         jr      _z80fillmemskip_

                                z80 _z80fillmem_:           inc     b

                                z80 _z80fillmemloop_:       ld      (hl),a
                                z80                         inc     hl
                                z80                         dec     c
                                z80                         jp      nz,_z80fillmemloop_
                                z80                         djnz    _z80fillmemloop_

                                z80                         ret

                                z80 _z80fillmemskip_:
                        endif

                                z80                         push    hl
                                z80                         push    bc
                                z80                         ld      hl,pMem
                                z80                         ld      bc,bcount
                                z80                         call    _z80fillmem_
                                z80                         pop     bc
                                z80                         pop     hl
                        endm

z80                     macro   mnarg, args:VARARG

                        oparg   textequ <>
                        arg     textequ <>
                        t_label textequ <>
                        mnemonic textequ <mnarg>

                        ifb     <mnarg>
                                exitm
                        endif

                        newlab  = 0
                        t_tmp = 1
                      % forc    $char, <mnemonic>
                                ifidn   <$char>, < >
                                        exitm
                                endif

                                ifidn   <$char>, <:>
                                        z80_label   %t_label    ; create the new label
                                        newlab = 1
                                        exitm
                                else
                                        t_label catstr  t_label, <$char>
                                        t_tmp = t_tmp + 1
                                endif
                        endm

                        if      newlab eq 1
                                if      @SizeStr (%mnemonic) lt (t_tmp+1)
                                        exitm   ; nothing after colon, so only a label on this line
                                endif
                                mnemonic    substr  mnemonic, t_tmp+1   ; strip label name from mnemonic argument
                        endif

                        t_tmp = 0
                        t_leadspc = 0
                        t_quoted = 0
                      % forc    $char, <mnemonic>
                                t_addchar = 0

                                ifidn   <$char>, <!">
                                        ; we add the opening or closing quote, then toggle quoted flag
                                        t_addchar = 1
                                        t_quoted = not t_quoted
                                endif

                                ifidn   <$char>, < >
                                        if  t_leadspc eq 1
                                            t_tmp = 1
                                        endif
                                else
                                        t_leadspc = 1
                                        t_addchar = 1
                                endif

                                if  (t_addchar eq 1) or t_quoted
                                        if  t_tmp eq 0
                                            oparg   catstr  oparg, <$char>
                                        else
                                            arg   catstr  arg, <$char>
                                        endif
                                endif
                        endm

                        ifidni  oparg, <ld>
                                %z80_ld  <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <call>
                                %z80_call <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <ret>
                                %z80_ret <arg>
                                exitm
                        endif

                        ifidni  oparg, <djnz>
                                %z80_djnz <arg>
                                exitm
                        endif

                        ifidni  oparg, <jr>
                                %z80_jr <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <jp>
                                %z80_jp <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <push>
                                %z80_push <arg>
                                exitm
                        endif

                        ifidni  oparg, <pop>
                                %z80_pop <arg>
                                exitm
                        endif

                        ifidni  oparg, <inc>
                                %z80_inc <arg>
                                exitm
                        endif

                        ifidni  oparg, <dec>
                                %z80_dec <arg>
                                exitm
                        endif

                        ifidni  oparg, <add>
                                %z80_add <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <adc>
                                %z80_adc <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <sub>
                                %z80_sub <arg>
                                exitm
                        endif

                        ifidni  oparg, <sbc>
                                %z80_sbc <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <and>
                                %z80_and <arg>
                                exitm
                        endif

                        ifidni  oparg, <xor>
                                %z80_xor <arg>
                                exitm
                        endif

                        ifidni  oparg, <or>
                                %z80_or <arg>
                                exitm
                        endif

                        ifidni  oparg, <cp>
                                %z80_cp <arg>
                                exitm
                        endif

                        ifidni  oparg, <ex>
                                %z80_ex <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <rla>
                                z80_rla
                                exitm
                        endif

                        ifidni  oparg, <rra>
                                z80_rra
                                exitm
                        endif

                        ifidni  oparg, <rlca>
                                z80_rlca
                                exitm
                        endif

                        ifidni  oparg, <rrca>
                                z80_rrca
                                exitm
                        endif

                        ifidni  oparg, <daa>
                                z80_daa
                                exitm
                        endif

                        ifidni  oparg, <cpl>
                                z80_cpl
                                exitm
                        endif

                        ifidni  oparg, <scf>
                                z80_scf
                                exitm
                        endif

                        ifidni  oparg, <ccf>
                                z80_ccf
                                exitm
                        endif

                        ifidni  oparg, <rlc>
                                %z80_rlc <arg>
                                exitm
                        endif

                        ifidni  oparg, <rrc>
                                %z80_rrc <arg>
                                exitm
                        endif

                        ifidni  oparg, <rl>
                                %z80_rl <arg>
                                exitm
                        endif

                        ifidni  oparg, <rr>
                                %z80_rr <arg>
                                exitm
                        endif

                        ifidni  oparg, <sla>
                                %z80_sla <arg>
                                exitm
                        endif

                        ifidni  oparg, <sra>
                                %z80_sra <arg>
                                exitm
                        endif

                        ifidni  oparg, <sll>
                                %z80_sll <arg>
                                exitm
                        endif

                        ifidni  oparg, <sls>    ; pseudonym for SLL
                                %z80_sls <arg>
                                exitm
                        endif

                        ifidni  oparg, <srl>
                                %z80_srl <arg>
                                exitm
                        endif

                        ifidni  oparg, <bit>
                                %z80_bit <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <res>
                                %z80_res <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <set>
                                %z80_set <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <ldi>
                                z80_ldi
                                exitm
                        endif

                        ifidni  oparg, <cpi>
                                z80_cpi
                                exitm
                        endif

                        ifidni  oparg, <ini>
                                z80_ini
                                exitm
                        endif

                        ifidni  oparg, <outi>
                                z80_outi
                                exitm
                        endif

                        ifidni  oparg, <ldd>
                                z80_ldd
                                exitm
                        endif

                        ifidni  oparg, <cpd>
                                z80_cpd
                                exitm
                        endif

                        ifidni  oparg, <ind>
                                z80_ind
                                exitm
                        endif

                        ifidni  oparg, <outd>
                                z80_outd
                                exitm
                        endif

                        ifidni  oparg, <ldir>
                                z80_ldir
                                exitm
                        endif

                        ifidni  oparg, <cpir>
                                z80_cpir
                                exitm
                        endif

                        ifidni  oparg, <inir>
                                z80_inir
                                exitm
                        endif

                        ifidni  oparg, <otir>
                                z80_otir
                                exitm
                        endif

                        ifidni  oparg, <lddr>
                                z80_lddr
                                exitm
                        endif

                        ifidni  oparg, <cpdr>
                                z80_cpdr
                                exitm
                        endif

                        ifidni  oparg, <indr>
                                z80_indr
                                exitm
                        endif

                        ifidni  oparg, <otdr>
                                z80_otdr
                                exitm
                        endif

                        ifidni  oparg, <in>
                                %z80_in <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <out>
                                %z80_out <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <di>
                                z80_di
                                exitm
                        endif

                        ifidni  oparg, <ei>
                                z80_ei
                                exitm
                        endif

                        ifidni  oparg, <halt>
                                z80_halt
                                exitm
                        endif

                        ifidni  oparg, <exx>
                                z80_exx
                                exitm
                        endif

                        ifidni  oparg, <neg>
                                z80_neg
                                exitm
                        endif

                        ifidni  oparg, <reti>
                                z80_reti
                                exitm
                        endif

                        ifidni  oparg, <retn>
                                z80_retn
                                exitm
                        endif

                        ifidni  oparg, <rst>
                                %z80_rst <arg>
                                exitm
                        endif

                        ifidni  oparg, <im>
                                %z80_im <arg>
                                exitm
                        endif

                        ifidni  oparg, <rld>
                                z80_rld
                                exitm
                        endif

                        ifidni  oparg, <rrd>
                                z80_rrd
                                exitm
                        endif

                        ifidni  oparg, <nop>
                                z80_nop
                                exitm
                        endif

                        ifidni  oparg, <db>
                                %z80_db <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <dw>
                                %z80_dw <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <ds>
                                %z80_ds <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <defb>
                                %z80_defb <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <defw>
                                %z80_defw <arg>, <args>
                                exitm
                        endif

                        ifidni  oparg, <org>
                                %z80_org <arg>
                                exitm
                        endif

                        ifidni  oparg, <setloop>
                                %z80_setloop <arg>
                                exitm
                        endif

                        ifidni  oparg, <endloop>
                                %z80_endloop
                                exitm
                        endif

                        ifidni  oparg, <breakloop>
                                %z80_breakloop
                                exitm
                        endif

                        ; check for inbuilt functions
                        ifidni  oparg, <opencrt>
                               %z80     ld      a,arg
                                z80     call    1601h
                                exitm
                        endif

                        ifidni  oparg, <crt>
                               %z80_crt <arg>, <args>
                               exitm
                        endif

                        ifidni  oparg, <crt16>
                               %z80_crt16   <arg>
                               exitm
                        endif

                        ifidni  oparg, <crt8>
                               %z80_crt8    <arg>
                               exitm
                        endif

                        ifidni  oparg, <crthex8>
                               %z80_crthex8 <arg>
                               exitm
                        endif

                        ifidni  oparg, <crthex16>
                               %z80_crthex16 <arg>
                               exitm
                        endif

                        ifidni  oparg, <for>
                                t_label catstr  <z80lab_>, arg
                               %z80_for <t_label>, <args>
                               exitm
                        endif

                        ifidni  oparg, <next>
                                t_label catstr  <z80lab_>, arg
                               %z80_next <t_label>
                               exitm
                        endif

                        ifidni  oparg, <align>
                               %z80_align <arg>
                               exitm
                        endif

                        ifidni  oparg, <breakpoint>
                               %z80_breakpoint
                               exitm
                        endif

                        ifidni  oparg, <fillmem>
                               %z80_fillmem <arg>, <args>
                               exitm
                        endif

                        ; we don't know what this is...
                        %echo   *** oparg: Unknown opcode ***
                        .err

                        endm

@ITEMINLIST             macro   item:REQ, list:VARARG
                        @result = 0
                        @itemnum = 0
                        for     @param, <list>
                                @itemnum = @itemnum + 1
                              % ifidni  <item>, <@param>
                                        @result = @itemnum
                                        exitm
                                endif
                        endm
                        exitm   %@result
                        ENDM

z80_fillasmbytes        proc    uses        ecx,
                                count:      DWORD,
                                filler:     BYTE

                        mov     ecx, count
                        .while  ecx > 0
                                invoke  z80_storeasmbyte, filler
                                dec     ecx
                        .endw
                        ret
z80_fillasmbytes        endp

z80_storeasmbytes       proc    uses        esi ecx,
                                lpBytes:    DWORD,
                                count:      DWORD

                        mov     esi, lpBytes
                        mov     ecx, count
                        .while  ecx > 0
                                invoke  z80_storeasmbyte, [esi]
                                inc     esi
                                dec     ecx
                        .endw
                        ret
z80_storeasmbytes       endp

z80_storeasmbyte        proc    uses        ecx eax,
                                thebyte:    BYTE

                        mov     al, thebyte
                        mov     ecx, z80_lpDest
                        inc     z80_lpDest
                        mov     [ecx], al
                        ret
z80_storeasmbyte        endp

z80_storeasmwords       proc    uses        esi ecx,
                                lpWords:    DWORD,
                                count:      DWORD

                        mov     esi, lpWords
                        mov     ecx, count
                        .while  ecx > 0
                                invoke  z80_storeasmword, word ptr [esi]
                                add     esi, 2
                                dec     ecx
                        .endw
                        ret
z80_storeasmwords       endp

z80_storeasmword        proc    uses        ecx eax,
                                theword:    WORD

                        mov     ax, theword
                        mov     ecx, z80_lpDest
                        add     z80_lpDest,2
                        mov     [ecx], ax
                        ret
z80_storeasmword        endp

z80m_storebyte          macro   thebyte:req
                        if      emitz80
                                invoke  z80_storeasmbyte, thebyte
                        endif
                        endm

z80m_storeword          macro   theword:req
                        if      emitz80
                                invoke  z80_storeasmword, theword
                        endif
                        endm

z80m_storeconstbyte     macro   thebyte:req, argconst:req
                        if      emitz80
                                ifb     argconst
                                        invoke  z80_storeasmbyte, (thebyte and 255)
                                else
                                        invoke  z80_storeasmbyte, argconst
                                endif
                        endif
                        endm

z80m_storeconstword     macro   theword:req, argconst:req
                        if      emitz80
                                ifb     argconst
                                        invoke  z80_storeasmword, (theword and 65535)
                                else
                                        invoke  z80_storeasmword, argconst
                                endif
                        endif
                        endm

z80_getobjectlength     proc
                        mov     eax, z80_lpDest
                        sub     eax, z80_lpOriginalDest
                        ret
z80_getobjectlength     endp

z80_assemble            proc    uses    ebx esi edi,
                                lpDest: DWORD

                        m2m     z80_lpDest, lpDest
                        m2m     z80_lpOriginalDest, lpDest
                        ret
z80_assemble            endp

z80_assembler           macro   lpDest:req
                        local   txt

                        txt     textequ %pass
                      ;% echo   Pass txt

                        if      pass eq passes
                                emitz80 = 1
                        else
                                emitz80 = 0
                        endif

                        localsym_curr = 0
                        z80HighLoopLab  textequ <0>
                        z80LoopLab      textequ <z80HighLoopLab>

                        ; reset the For..Next var counters
                      % forc    @char, <abcdefghijklmnopqrstuvwxyz>
                                $$z80Forz80lab_&@char& = 0
                        endm

                        _z80crtptrcount_= 0

                        _z80includecrt_ = 0
                        _z80includecrtnum_= 0
                        _z80includecrthex_= 0
                        _z80includefillmem_= 0

                        if      emitz80
                                invoke  z80_assemble, lpDest
                        endif
                        endm


