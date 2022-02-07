
.data?
align 16
PageTableList               ListHeader  <>

PageTableNode               struct
Node                        ListNode    <>
PageTableNode               ends


AllocPageTable              PROTO   :DWORD
FreePageTable               PROTO   :DWORD

.code
x86_dereferencemem          macro
                            .if     argbracketed
                                    ; mov bx,ax
                                    invoke  x86_WriteByte, 066h
                                    invoke  x86_WriteWord, 0d88bh

                                    .if     argisword
                                            ; call [GetMemWord]
                                            x86_memcpy  addr call_MemGetWord, CALL_MEMGETWORD_SIZEOF
                                    .else
                                            ; call [GetMemByte]
                                            x86_memcpy  addr call_MemGetByte, CALL_MEMGETBYTE_SIZEOF
                                    .endif
                            .endif
                            endm

x86_getregister             macro   @reg:req
                            local   @asize

                            @asize = @GETARGSIZE (@reg)
                            if      @asize eq 1
                                    ; movzx eax, byte ptr @reg
                                    invoke  x86_WriteByte, 0fh
                                    invoke  x86_WriteWord, 05b6h
                                    invoke  x86_WriteDWord, addr @reg
        
                            elseif  @asize eq 2
                                    ; movzx eax, word ptr @reg
                                    invoke  x86_WriteByte, 0fh
                                    invoke  x86_WriteWord, 05b7h
                                    invoke  x86_WriteDWord, addr @reg
                            else
                                    .err    <Invalid sized argument for x86_getregister>
                            endif

                            x86_dereferencemem
                            endm

align 16
    farcall                 macro   @target:req
                            call    [_jp_&@target&]
                            endm

call_MemGetByte:            farcall MemGetByte
                            and     ax, 255
CALL_MEMGETBYTE_SIZEOF      equ     $ - call_MemGetByte

call_MemGetWord:            farcall MemGetWord
CALL_MEMGETWORD_SIZEOF      equ     $ - call_MemGetWord


call_GetBankAtAddr:         push    eax
                            farcall GetBankAtAddr
CALL_GETBANKATADDR_SIZEOF   equ     $ - call_GetBankAtAddr

call_GetBankConfig:         farcall GetBankConfig
CALL_GETBANKCONFIG_SIZEOF   equ     $ - call_GetBankConfig



.const
align 16
_jp_MemGetByte              dd      MemGetByte
_jp_MemGetWord              dd      MemGetWord

_jp_GetBankAtAddr           dd      GetBankAtAddr
_jp_GetBankConfig           dd      GetBankConfig

_jp_GetByte                 dd      GetByte
_jp_Op7E                    dd      Op7E
_jp_Op12                    dd      Op12
_jp_Op23                    dd      Op23
_jp_Op13                    dd      Op13

.code
; *****************************************************************

                      ; turn on indirect addressing here
                        USEESI  1

; *****************************************************************

                            ; memory-related
x86get_memreadaddr:         .if     Reg_MemoryReadEvent == MEMACCESSNONE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, Reg_MemoryReadAddress
X86GET_MEMREADADDR_SIZEOF   = $ - x86get_memreadaddr

x86get_memreadval:          .if     Reg_MemoryReadEvent == MEMACCESSNONE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, Reg_MemoryReadValueLo
X86GET_MEMREADVAL_SIZEOF    = $ - x86get_memreadval

x86get_memwriteaddr:        .if     Reg_MemoryWriteEvent == MEMACCESSNONE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, Reg_MemoryWriteAddress
X86GET_MEMWRITEADDR_SIZEOF  = $ - x86get_memwriteaddr

x86get_memwriteval:         .if     Reg_MemoryWriteEvent == MEMACCESSNONE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, Reg_MemoryWriteValueLo
X86GET_MEMWRITEVAL_SIZEOF   = $ - x86get_memwriteval

; =====================================================================
                            ; this does the "=" test for MRA
                            ; ==============================
x86test_memreadaddr:        cmp     ax, cx
    x86test_mra_jmp1:       je      @F      ; correct jcc gets switched

                            cmp     Reg_WordLengthAccess, TRUE
                            retcc   ne

                            xor     edx, edx
                            test    eax, BRKFLAGF_MRA
                            setnz   dl
                            add     ax, dx

                            test    ecx, BRKFLAGF_MRA
                            setnz   dl
                            add     cx, dx

                            cmp     ax, cx
    x86test_mra_jmp2:       je      @F      ; correct jcc gets switched

                            ret
    @@:
X86TEST_MEMREADADDR_SIZEOF  = $ - x86test_memreadaddr
x86test_mra_offset_jmp1     = x86test_mra_jmp1 - x86test_memreadaddr
x86test_mra_offset_jmp2     = x86test_mra_jmp2 - x86test_memreadaddr

; =====================================================================
                            ; this does the "=" test for MWA
                            ; ==============================
x86test_memwriteaddr:       cmp     ax, cx
    x86test_mwa_jmp1:       je      @F      ; correct jcc gets switched

                            cmp     Reg_WordLengthAccess, TRUE
                            retcc   ne

                            xor     edx, edx
                            test    eax, BRKFLAGF_MWA
                            setnz   dl
                            add     ax, dx

                            test    ecx, BRKFLAGF_MWA
                            setnz   dl
                            add     cx, dx

                            cmp     ax, cx
    x86test_mwa_jmp2:       je      @F      ; correct jcc gets switched

                            ret
    @@:
X86TEST_MEMWRITEADDR_SIZEOF = $ - x86test_memwriteaddr
x86test_mwa_offset_jmp1     = x86test_mwa_jmp1 - x86test_memwriteaddr
x86test_mwa_offset_jmp2     = x86test_mwa_jmp2 - x86test_memwriteaddr
; =====================================================================

                            ; port-related
x86get_portreadaddr:        .if     PortAccessType != PORT_READ
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, PortReadAddress
X86GET_PORTREADADDR_SIZEOF  = $ - x86get_portreadaddr

x86get_portreadval:         .if     PortAccessType != PORT_READ
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, PortReadByte
X86GET_PORTREADVAL_SIZEOF   = $ - x86get_portreadval

x86get_portwriteaddr:       .if     PortAccessType != PORT_WRITE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, PortWriteAddress
X86GET_PORTWRITEADDR_SIZEOF = $ - x86get_portwriteaddr

x86get_portwriteval:        .if     PortAccessType != PORT_WRITE
                                    jmp     [Reg_x86_jmpexitaddr]
                            .endif
                            movzx   eax, PortWriteByte
X86GET_PORTWRITEVAL_SIZEOF  = $ - x86get_portwriteval

x86get_tstatecount:         mov     eax, totaltstates
                            .if     eax > 65535
                                    mov     eax, 65535
                            .endif
X86GET_TSTATECOUNT_SIZEOF = $ - x86get_tstatecount

; *****************************************************************

                      ; turn off indirect addressing here
                        USEESI  0

; *****************************************************************


AllocPageTable              proc    uses        esi,
                                    pagesize:   DWORD

                            mov     eax, pagesize
                            add     eax, sizeof PageTableNode

                            .if     $fnc (VirtualAlloc, NULL, eax, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE) != NULL
                                    mov     esi, eax
                                    AddTail offset PageTableList, esi

                                    mov     eax, esi
                                    add     eax, PageTableNode
                            .endif
                            ret
AllocPageTable              endp

FreePageTable               proc    uses            esi,
                                    lpPageTable:    DWORD

                            mov     esi, lpPageTable
                            sub     esi, sizeof PageTableNode

                            ; as the node lives at the start of the memory block,
                            ; we have to remove the node from the list before freeing
                            invoke  RemoveNode, esi
                            invoke  VirtualFree, esi, 0, MEM_RELEASE
                            ret
FreePageTable               endp

FreePageTableList           proc    uses    esi edi

                            lea     esi, PageTableList

                            .while  TRUE
                                    .break  .if $fnc (IsListEmpty, esi)

                                    mov     edi, [esi].ListHeader.lh_Head
                                    add     edi, sizeof PageTableNode

                                    invoke  FreePageTable, edi
                            .endw
                            ret
FreePageTableList           endp


.data?
align 4
pBreakpointCodePage         dd      ?

.code
x86_Breakpoint              proc    uses    esi edi ebx

                            .if     $fnc (AllocPageTable, 4096) != NULL
                                    mov     pBreakpointCodePage, eax
                            .else
                                    mov     pBreakpointCodePage, 0
                            .endif
                            ret

x86_Breakpoint              endp


                            RESETENUM
                            ENUM    BRKARGTYPE_NONE
                            ENUM    BRKARGTYPE_ERROR
                            ENUM    BRKARGTYPE_NUMERIC
                            ENUM    BRKARGTYPE_STRING
                            ENUM    BRKARGTYPE_OPERATOR

.data?
align 4
pCodePageWriteAddr          dd      ?

.code
x86_SetOrigin               proc    lpOrgAddress:   DWORD

                            mov     eax, lpOrgAddress
                            mov     pCodePageWriteAddr, eax
                            ret
x86_SetOrigin               endp

x86_memcpy                  macro   pbytes:req, count:req

                            mov     eax, count
                            invoke  x86_MemCpy, pbytes, eax ; invoke bug? count needs passing in a register here else it takes the wrong value
                            endm

x86_MemCpy                  proc    uses    esi,
                                    pBytes: DWORD,
                                    cnt:    DWORD

                            mov     esi, pBytes

                            .while  cnt > 0
                                    dec     cnt
                                    lodsb
                                    invoke  x86_WriteByte, al
                            .endw
                            ret
x86_MemCpy                  endp

x86_WriteByte               proc    uses    ecx,
                                    data:   BYTE

                            mov     ecx, pCodePageWriteAddr
                            inc     pCodePageWriteAddr

                            mov     al, data
                            mov     [ecx], al
                            ret
x86_WriteByte               endp

x86_WriteWord               proc    uses    ecx,
                                    data:   WORD

                            mov     ecx, pCodePageWriteAddr
                            add     pCodePageWriteAddr, 2

                            mov     ax, data
                            mov     [ecx], ax
                            ret
x86_WriteWord               endp

x86_WriteDWord              proc    uses    ecx,
                                    data:   DWORD

                            mov     ecx, pCodePageWriteAddr
                            add     pCodePageWriteAddr, 4

                            mov     eax, data
                            mov     [ecx], eax
                            ret
x86_WriteDWord              endp

FETCHCHAR                   macro
                            call    FetchBreakChar
                            endm

FetchBreakChar:             lodsb
                            cmp     al, " "
                            je      FetchBreakChar
                            cmp     al, 9
                            je      FetchBreakChar
                            ret

DecodeBreakArg:             FETCHCHAR
                            ifc     al eq 0 then return BRKARGTYPE_NONE

                            switch  al
                                    case    "0".."9"
                                            ; decimal numeric
                                            dec     esi         ; back to first digit for decimal numeric
                                            xor     ecx, ecx
                                            xor     ebx, ebx    ; valid characters count

                                            .while  TRUE
                                                    lodsb
                                                    switch  al
                                                            case    "0".."9"
                                                                    inc     ebx
                                                                    and     eax, 255
                                                                    sub     eax, "0"
                                                                    lea     ecx, [ecx*4+ecx]
                                                                    add     ecx, ecx
                                                                    add     ecx, eax
                                                            .else
                                                                    dec     esi
                                                                    ifc     ebx eq 0 then return BRKARGTYPE_ERROR
                                                                    mov     [edi], ecx
                                                                    return  BRKARGTYPE_NUMERIC
                                                    endsw
                                            .endw

                                    case    "#", "$"
                                            ; hexadecimal numeric
                                            xor     ecx, ecx
                                            xor     ebx, ebx    ; valid characters count
        
                                            .while  TRUE
                                                    lodsb
                                                    TOUPPER
                                                    switch  al
                                                            case    "0".."9", "A".."F"
                                                                    inc     ebx
                                                                    and     eax, 255
                                                                    sub     eax, "0"
                                                                    ifc     eax gt 9 then sub eax, 7
                                                                    shl     ecx, 4
                                                                    add     ecx, eax
                                                            .else
                                                                    dec     esi
                                                                    ifc     ebx eq 0 then return BRKARGTYPE_ERROR
                                                                    mov     [edi], ecx
                                                                    return  BRKARGTYPE_NUMERIC
                                                    endsw
                                            .endw

                                    case    "%"
                                            ; binary numeric
                                            xor     ecx, ecx
                                            xor     ebx, ebx    ; valid characters count

                                            .while  TRUE
                                                    lodsb
                                                    switch  al
                                                            case    "0".."1"
                                                                    inc     ebx
                                                                    and     eax, 255
                                                                    sub     eax, "0"
                                                                    shl     ecx, 1
                                                                    add     ecx, eax
                                                            .else
                                                                    dec     esi
                                                                    ifc     ebx eq 0 then return BRKARGTYPE_ERROR
                                                                    mov     [edi], ecx
                                                                    return  BRKARGTYPE_NUMERIC
                                                    endsw
                                            .endw

                                    case    "A".."Z", "a".."z"  ; strings can only begin with a letter
                                            ; string
                                            dec     esi         ; back to first character of string
                                            xor     ebx, ebx    ; valid characters count (string length here)
        
                                            .while  TRUE
                                                    lodsb
                                                    TOUPPER
                                                    switch  al
                                                            case    "A".."Z", "0".."9", "'", "_"    ; need "'" char for specifying alt register names
                                                                    mov     [edi+ebx], al
                                                                    inc     ebx
                                                            .else
                                                                    mov     byte ptr [edi+ebx], 0
                                                                    dec     esi
                                                                    ifc     ebx eq 0 then return BRKARGTYPE_ERROR
                                                                    return  BRKARGTYPE_STRING
                                                    endsw
                                            .endw

                                    case    "=", 21h, 3ch, 3eh  ; "=", "!", "<", ">"
                                            ; relational (type: string)
                                            dec     esi         ; back to first character of string
                                            xor     ebx, ebx    ; valid characters count (string length here)
        
                                            .while  TRUE
                                                    lodsb
                                                    switch  al
                                                            case    "=", 21h, 3ch, 3eh  ; "=", "!", "<", ">"
                                                                    mov     [edi+ebx], al
                                                                    inc     ebx
                                                            .else
                                                                    mov     byte ptr [edi+ebx], 0
                                                                    dec     esi
                                                                    ifc     ebx eq 0 then return BRKARGTYPE_ERROR
                                                                    return  BRKARGTYPE_OPERATOR
                                                    endsw
                                            .endw

                            endsw
                            return  BRKARGTYPE_ERROR


                            ; Bit flags in the register arguments themselves (upper 16 bits only)
                            BITDEF  BRKFLAG, MRA, 31    ; marks this argument register as a memory read address argument
                            BITDEF  BRKFLAG, MWA, 30    ; marks this argument register as a memory write address argument


CompileBreakpointCode       proc    uses    esi edi ebx,
                                    lpbreakstr: PTR

                            local   expectbracket, argbracketed: BOOL
                            local   argisword:      BOOL
                            local   x86pass:        DWORD
                            local   breakargtype:   DWORD
                            local   argfunction:    DWORD
                            local   operatortype:   DWORD
                            local   temp1:          DWORD

                            local   x86jcc:         BYTE
                            local   bitwisechar:    BYTE

                            local   breakpointstring [1024]: BYTE
                            local   thisbreakarg     [1024]: BYTE
                            local   thisbitwisearg   [1024]: BYTE

                            ADDMESSAGEPTR_DBG   lpbreakstr

                            invoke  x86_SetOrigin, pBreakpointCodePage
                            invoke  x86_WriteWord, 0e783h               ; and edi, nn
                            invoke  x86_WriteByte, 0                    ; nn = 0 (edi == False)

                            push    pCodePageWriteAddr
                            invoke  x86_WriteByte, 0c3h                 ; retn
                            pop     pCodePageWriteAddr

                            .if     len (lpbreakstr) >= sizeof breakpointstring - 4
                                    ADDMESSAGE_DBG  "Breakpoint string too long"
                                    return  FALSE
                            .endif

                            ; take a copy of the break arg string
                            mov     esi, lpbreakstr
                            lea     edi, breakpointstring
                        @@: lodsb
                            stosb
                            or      al, al
                            jnz     @B

                            ; add more null terminators to save on persistent checking
                            mov     dword ptr [edi], 0
                            mov     dword ptr [edi+4], 0

                            lea     esi, breakpointstring
                            mov     x86pass, 0

                            ; clear the operator type; this is re-cleared after each cmp iteration in the main loop
                            mov     operatortype, 0

                            .while  TRUE
                                    mov     eax, x86pass
                                    inc     eax
                                    and     eax, 3
                                    cmp     eax, 1
                                    adc     eax, 0
                                    mov     x86pass, eax   ; 1-3

                                    mov     expectbracket, FALSE
                                    mov     argbracketed, FALSE
                                    mov     argisword, FALSE

                                    RESETENUM
                                    ENUM    ARGFNC_NONE
                                    ENUM    ARGFNC_ONLYHIGH, ARGFNC_ONLYLOW

                                    mov     argfunction, ARGFNC_NONE


                                    @@:     FETCHCHAR
                                            switch  al
                                                    case    0
                                                            .break
                                                    case    "("
                                                            inc     esi
                                                            mov     expectbracket, TRUE
                                            endsw

;    INT3
;    add ax, 32768
;    or  ax, 32710
;    movzx   eax, z80registers.hl.w


                                            dec     esi
                                            lea     edi, thisbreakarg
                                            call    DecodeBreakArg
                                            mov     breakargtype, eax   ; store argument type return code

                                            ; except for BRKARGTYPE_OPERATOR operators (=, !=, <, etc), check if argument is followed by ".h" or ".l"
                                            ; being careful how we handle the current character pointer (esi)
                                            .if     breakargtype != BRKARGTYPE_OPERATOR
                                                    mov     temp1, esi
                                                    FETCHCHAR
                                                    .if     al == "."
                                                            FETCHCHAR
                                                            TOUPPER
                                                            .if     al == "H"
                                                                    mov     argfunction, ARGFNC_ONLYHIGH
                                                                    mov     temp1, esi
                                                            .elseif al == "L"
                                                                    mov     argfunction, ARGFNC_ONLYLOW
                                                                    mov     temp1, esi
                                                            .endif
                                                    .endif
                                                    mov     esi, temp1
                                            .endif

                                            ; check for closing bracket if opening bracket was present
                                            ; being sure to check for ".w" word sized argument specifier within the brackets first
                                            .if     expectbracket
                                                    FETCHCHAR
                                                    .if     al == "."
                                                            FETCHCHAR
                                                            TOUPPER
                                                            .if     al == "W"
                                                                    mov     argisword, TRUE
                                                                    FETCHCHAR   ; to check for closing bracket
                                                            .else
                                                                    return  FALSE
                                                            .endif
                                                    .endif

                                                    .if     al != ")"
                                                            return  FALSE
                                                    .endif

                                                    mov     expectbracket, FALSE
                                                    mov     argbracketed, TRUE
                                            .endif


                                            ; ===========================================================================
                                            ; move on to evaluating the argument based on return code from DecodeBreakArg
                                            ; ===========================================================================

                                            ; note: when loading all types of initial arguments into eax, be sure to extend to eax, clearing all bits.
                                            ; BRKFLAG flag bits may be set in upper 16 bits for certain types of arguments

                                            switch  breakargtype
                                                    case    BRKARGTYPE_NONE
                                                            ADDMESSAGE_DBG   "BRKARGTYPE_NONE"

                                                    case    BRKARGTYPE_ERROR
                                                            return  FALSE

                                                    case    BRKARGTYPE_NUMERIC
                                                            ; ADDMESSAGEDEC_DBG   "Cond Numeric: ", dword ptr [edi]
                                                            switch  x86pass
                                                                    case    1, 3
                                                                            ; arg to eax
                                                                            ; mov eax, nnnn
                                                                            invoke  x86_WriteByte, 0b8h
                                                                            mov     eax, [edi]
                                                                            ifc     eax gt 65535 then return FALSE
                                                                            invoke  x86_WriteDWord, eax

                                                                            x86_dereferencemem
                                                                    .else
                                                                            return  FALSE
                                                            endsw

                                                    case    BRKARGTYPE_STRING
                                                            switch  x86pass
                                                                    case    1, 3
                                                                            switch$ edi
                                                                                    case$   "AF"
                                                                                            x86_getregister z80registers.af
                                                                                    case$   "A"
                                                                                            x86_getregister z80registers.af.hi
                                                                                    case$   "F"
                                                                                            x86_getregister z80registers.af.lo
                                                                                    case$   "AF'"
                                                                                            x86_getregister z80registers.af_
                                                                                    case$   "A'"
                                                                                            x86_getregister z80registers.af_.hi
                                                                                    case$   "F'"
                                                                                            x86_getregister z80registers.af_.lo

                                                                                    case$   "BC"
                                                                                            x86_getregister z80registers.bc
                                                                                    case$   "B"
                                                                                            x86_getregister z80registers.bc.hi
                                                                                    case$   "C"
                                                                                            x86_getregister z80registers.bc.lo
                                                                                    case$   "BC'"
                                                                                            x86_getregister z80registers.bc_
                                                                                    case$   "B'"
                                                                                            x86_getregister z80registers.bc_.hi
                                                                                    case$   "C'"
                                                                                            x86_getregister z80registers.bc_.lo

                                                                                    case$   "DE"
                                                                                            x86_getregister z80registers.de
                                                                                    case$   "D"
                                                                                            x86_getregister z80registers.de.hi
                                                                                    case$   "E"
                                                                                            x86_getregister z80registers.de.lo
                                                                                    case$   "DE'"
                                                                                            x86_getregister z80registers.de_
                                                                                    case$   "D'"
                                                                                            x86_getregister z80registers.de_.hi
                                                                                    case$   "E'"
                                                                                            x86_getregister z80registers.de_.lo

                                                                                    case$   "HL"
                                                                                            x86_getregister z80registers.hl
                                                                                    case$   "H"
                                                                                            x86_getregister z80registers.hl.hi
                                                                                    case$   "L"
                                                                                            x86_getregister z80registers.hl.lo
                                                                                    case$   "HL'"
                                                                                            x86_getregister z80registers.hl_
                                                                                    case$   "H'"
                                                                                            x86_getregister z80registers.hl_.hi
                                                                                    case$   "L'"
                                                                                            x86_getregister z80registers.hl_.lo

                                                                                    case$   "IX"
                                                                                            x86_getregister z80registers.ix
                                                                                    case$   "IXH"
                                                                                            x86_getregister z80registers.ix.hi
                                                                                    case$   "IXL"
                                                                                            x86_getregister z80registers.ix.lo

                                                                                    case$   "IY"
                                                                                            x86_getregister z80registers.iy
                                                                                    case$   "IYH"
                                                                                            x86_getregister z80registers.iy.hi
                                                                                    case$   "IYL"
                                                                                            x86_getregister z80registers.iy.lo

                                                                                    case$   "MPTR"
                                                                                            x86_getregister z80registers.memptr

                                                                                    case$   "IR"
                                                                                            ; xor   eax, eax
                                                                                            invoke  x86_WriteWord,  0c033h
                                                                                            ; mov   ah, byte ptr z80registers.i
                                                                                            invoke  x86_WriteWord,  258ah
                                                                                            invoke  x86_WriteDWord, addr z80registers.i
                                                                                            ; mov   al, byte ptr z80registers.r
                                                                                            invoke  x86_WriteByte,  0a0h
                                                                                            invoke  x86_WriteDWord, addr z80registers.r
                                                                                            ; and   al, 7fh
                                                                                            invoke  x86_WriteWord,  7f24h
                                                                                            ; or    al, byte ptr z80registers.r_msb
                                                                                            invoke  x86_WriteWord,  050ah
                                                                                            invoke  x86_WriteDWord, addr z80registers.r_msb

                                                                                            x86_dereferencemem

                                                                                    case$   "I"
                                                                                            x86_getregister z80registers.i

                                                                                    case$   "R"
                                                                                            ; movzx eax, z80registers.r
                                                                                            invoke  x86_WriteByte, 0fh
                                                                                            invoke  x86_WriteWord, 05b6h
                                                                                            invoke  x86_WriteDWord, addr z80registers.r
                                                                                            ; and   al, 7fh
                                                                                            invoke  x86_WriteWord,  7f24h
                                                                                            ; or    al, byte ptr z80registers.r_msb
                                                                                            invoke  x86_WriteWord,  050ah
                                                                                            invoke  x86_WriteDWord, addr z80registers.r_msb

                                                                                            x86_dereferencemem

                                                                                    case$   "IM"
                                                                                            x86_getregister z80registers.intmode

                                                                                    case$   "IFF1"
                                                                                            x86_getregister z80registers.iff1

                                                                                    case$   "IFF2"
                                                                                            x86_getregister z80registers.iff2

                                                                                    case$   "SP"
                                                                                            x86_getregister z80registers._sp

                                                                                    case$   "PC"
                                                                                            x86_getregister z80registers.pc

                                                                                    case$   "MRA"
                                                                                            or      operatortype, BRKFLAGF_MRA
                                                                                            x86_memcpy  addr x86get_memreadaddr, X86GET_MEMREADADDR_SIZEOF

                                                                                            ; mark this argument as the one with the MRA value (would be in eax or ecx when testing)
                                                                                            ; or    eax, BRKFLAGF_MRA
                                                                                            invoke  x86_WriteByte,  0dh
                                                                                            invoke  x86_WriteDWord, BRKFLAGF_MRA

                                                                                    case$   "MRV"
                                                                                            x86_memcpy  addr x86get_memreadval, X86GET_MEMREADVAL_SIZEOF

                                                                                    case$   "MWA"
                                                                                            or      operatortype, BRKFLAGF_MWA
                                                                                            x86_memcpy  addr x86get_memwriteaddr, X86GET_MEMWRITEADDR_SIZEOF

                                                                                            ; mark this argument as the one with the MWA value (would be in eax or ecx when testing)
                                                                                            ; or    eax, BRKFLAGF_MWA
                                                                                            invoke  x86_WriteByte,  0dh
                                                                                            invoke  x86_WriteDWord, BRKFLAGF_MWA

                                                                                    case$   "MWV"
                                                                                            x86_memcpy  addr x86get_memwriteval, X86GET_MEMWRITEVAL_SIZEOF

                                                                                    case$   "PRA"
                                                                                            x86_memcpy  addr x86get_portreadaddr, X86GET_PORTREADADDR_SIZEOF

                                                                                    case$   "IN"
                                                                                            x86_memcpy  addr x86get_portreadaddr, X86GET_PORTREADADDR_SIZEOF

                                                                                    case$   "PRV"
                                                                                            x86_memcpy  addr x86get_portreadval, X86GET_PORTREADVAL_SIZEOF

                                                                                    case$   "PWA"
                                                                                            x86_memcpy  addr x86get_portwriteaddr, X86GET_PORTWRITEADDR_SIZEOF

                                                                                    case$   "OUT"
                                                                                            x86_memcpy  addr x86get_portwriteaddr, X86GET_PORTWRITEADDR_SIZEOF

                                                                                    case$   "PWV"
                                                                                            x86_memcpy  addr x86get_portwriteval, X86GET_PORTWRITEVAL_SIZEOF

                                                                                    case$   "P0"
                                                                                            ; xor   eax, eax
                                                                                            invoke  x86_WriteWord,  0c033h
                                                                                            x86_memcpy  addr call_GetBankAtAddr, CALL_GETBANKATADDR_SIZEOF

                                                                                    case$   "P1"
                                                                                            ; mov eax, nnnn
                                                                                            invoke  x86_WriteByte, 0b8h
                                                                                            invoke  x86_WriteDWord, 16384
                                                                                            x86_memcpy  addr call_GetBankAtAddr, CALL_GETBANKATADDR_SIZEOF

                                                                                    case$   "P2"
                                                                                            ; mov eax, nnnn
                                                                                            invoke  x86_WriteByte, 0b8h
                                                                                            invoke  x86_WriteDWord, 32768
                                                                                            x86_memcpy  addr call_GetBankAtAddr, CALL_GETBANKATADDR_SIZEOF

                                                                                    case$   "P3"
                                                                                            ; mov eax, nnnn
                                                                                            invoke  x86_WriteByte, 0b8h
                                                                                            invoke  x86_WriteDWord, 49152
                                                                                            x86_memcpy  addr call_GetBankAtAddr, CALL_GETBANKATADDR_SIZEOF

                                                                                    case$   "TS"
                                                                                            x86_memcpy  addr x86get_tstatecount, X86GET_TSTATECOUNT_SIZEOF

                                                                                    case$   "PAGING"
                                                                                            x86_memcpy  addr call_GetBankConfig, CALL_GETBANKCONFIG_SIZEOF

                                                                                    case$   "SNOW"
                                                                                            ; movzx eax, SPGfx.SnowEffect
                                                                                            invoke  x86_WriteByte, 0fh
                                                                                            invoke  x86_WriteWord, 05b6h
                                                                                            invoke  x86_WriteDWord, addr SPGfx.SnowEffect

                                                                                    case$   "SCREEN"
                                                                                            ; movzx eax, SPGfx.CurrScreen
                                                                                            invoke  x86_WriteByte, 0fh
                                                                                            invoke  x86_WriteWord, 05b6h
                                                                                            invoke  x86_WriteDWord, addr SPGfx.CurrScreen

                                                                                    case$   "BORDER"
                                                                                            ; movzx eax, Last_FE_Write
                                                                                            invoke  x86_WriteByte, 0fh
                                                                                            invoke  x86_WriteWord, 05b6h
                                                                                            invoke  x86_WriteDWord, addr Last_FE_Write
                                                                                            ; and   al, 7
                                                                                            invoke  x86_WriteWord,  0724h


                                                                        _x86flag    macro   fMask:req
                                                                                    invoke  x86_WriteWord,  0c033h  ; xor   eax, eax
                                                                                    invoke  x86_WriteWord,  05f6h   ; test  byte ptr z80registers.af.lo, fMask
                                                                                    invoke  x86_WriteDWord, addr z80registers.af.lo
                                                                                    invoke  x86_WriteByte,  fMask

                                                                                    invoke  x86_WriteWord,  950fh   ; setnz al
                                                                                    invoke  x86_WriteByte,  0c0h
                                                                                    endm

                                                                                    case$   "FS"
                                                                                            _x86flag    FLAG_S
                                                                                    case$   "FZ"
                                                                                            _x86flag    FLAG_Z
                                                                                    case$   "F5"
                                                                                            _x86flag    FLAG_5
                                                                                    case$   "FH"
                                                                                            _x86flag    FLAG_H
                                                                                    case$   "F3"
                                                                                            _x86flag    FLAG_3
                                                                                    case$   "FV"
                                                                                            _x86flag    FLAG_V
                                                                                    case$   "FP"
                                                                                            _x86flag    FLAG_P
                                                                                    case$   "FN"
                                                                                            _x86flag    FLAG_N
                                                                                    case$   "FC"
                                                                                            _x86flag    FLAG_C

                                                                                    else$

                                                                                            return  FALSE
                                                                            endsw$
                                                            endsw

                                                    case    BRKARGTYPE_OPERATOR
                                                            switch  x86pass
                                                                    case    2
;    INT3
                                                                            switch  word ptr [edi]
                                                                                    ; set the jcc opcode each relational operator
                                                                                    case    "="
                                                                                            mov     x86jcc, 74h ; je    @F  ; =

                                                                                            _jcc_   = 21h or ("=" shl 8)    ; !=
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 75h ; jne   @F

                                                                                            _jcc_   = 3ch or (3eh shl 8)    ; <>
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 75h ; jne   @F

                                                                                            _jcc_   = 3ch                   ; <
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 72h ; jb    @F

                                                                                            _jcc_   = 3ch or ("=" shl 8)    ; <=
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 76h ; jbe   @F

                                                                                            _jcc_   = 3eh                   ; >
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 77h ; ja    @F

                                                                                            _jcc_   = 3eh or ("=" shl 8)    ; >=
                                                                                    case    _jcc_
                                                                                            mov     x86jcc, 73h ; jae   @F

                                                                                    .else
                                                                                            return  FALSE
                                                                            endsw
                                                            endsw
                                            endsw

                                            ; modify the eax argument if indicated for high byte or low byte only comparisons
                                            ; these argfunction values were excluded above for BRKARGTYPE_OPERATOR
                                            switch  argfunction
                                                    case    ARGFNC_ONLYHIGH
                                                            invoke  x86_WriteDWord, 08e8c166h   ; shr   ax, 8

                                                    case    ARGFNC_ONLYLOW
                                                            invoke  x86_WriteDWord, 00ff2566h   ; and   ax, ffh
                                            endsw

                                            ; except for BRKARGTYPE_OPERATOR operators (=, !=, <, etc), check if argument is followed by bitwise operators for the current argument
                                            ; being careful how we handle the current character pointer (esi)
                                            .if     breakargtype != BRKARGTYPE_OPERATOR
                                                    mov     temp1, esi
                                                @@: FETCHCHAR
                                                    .if     (al == "&") || (al == "|") || (al == "^") || (al == "+") || (al == "-")
                                                            mov     bitwisechar, al

                                                            lea     edi, thisbitwisearg ;thisbreakarg
                                                            call    DecodeBreakArg

                                                            switch  eax
                                                                    case    BRKARGTYPE_NUMERIC
                                                                            mov     temp1, esi  ; update current character pointer

                                                                            mov     eax, [edi]

                                                                            .if     bitwisechar == "&"
                                                                                    ; and ax, nn
                                                                                    invoke  x86_WriteWord, 2566h
                                                                                    mov     eax, [edi]
                                                                                    ifc     eax gt 65535 then return FALSE
                                                                                    invoke  x86_WriteWord, ax
                                                                                    jmp     @B

                                                                            .elseif bitwisechar == "|"
                                                                                    ; or ax, nn
                                                                                    invoke  x86_WriteWord, 0d66h
                                                                                    mov     eax, [edi]
                                                                                    ifc     eax gt 65535 then return FALSE
                                                                                    invoke  x86_WriteWord, ax
                                                                                    jmp     @B

                                                                            .elseif bitwisechar == "^"
                                                                                    ; or ax, nn
                                                                                    invoke  x86_WriteWord, 3566h
                                                                                    mov     eax, [edi]
                                                                                    ifc     eax gt 65535 then return FALSE
                                                                                    invoke  x86_WriteWord, ax
                                                                                    jmp     @B

                                                                            .elseif bitwisechar == "+"
                                                                                    ; add ax, nn
                                                                                    invoke  x86_WriteWord, 0566h
                                                                                    mov     eax, [edi]
                                                                                    ifc     eax gt 65535 then return FALSE
                                                                                    invoke  x86_WriteWord, ax
                                                                                    jmp     @B

                                                                            .elseif bitwisechar == "-"
                                                                                    ; sub ax, nn
                                                                                    invoke  x86_WriteWord, 2d66h
                                                                                    mov     eax, [edi]
                                                                                    ifc     eax gt 65535 then return FALSE
                                                                                    invoke  x86_WriteWord, ax
                                                                                    jmp     @B

                                                                            .else
                                                                                    ; should never get here!
                                                                                    return  FALSE
                                                                            .endif
                                                                    .else
                                                                            return  FALSE
                                                            endsw
                                                    .endif
                                                    mov     esi, temp1
                                            .endif

                                            ; =================================================

                                            ; move on to creating code blocks...
                                            ; =================================================

                                            switch  x86pass
                                                    case    2

                                                    case    1
                                                            invoke  x86_WriteByte, 50h     ; push   eax

                                                    case    3
                                                            invoke  x86_WriteWord, 0c88bh  ; mov    ecx, eax
                                                            invoke  x86_WriteByte, 58h     ; pop    eax

                                                            ; we have to allow for word-length reads/writes for memory read address (MRA) and memory write address (MWA) tests
                                                            ; else fall through to the standard test code for most other operators
                                                            .while  TRUE
                                                                    test    operatortype, BRKFLAGF_MRA
                                                                    .if     !ZERO?
                                                                            push    pCodePageWriteAddr
                                                                            x86_memcpy  addr x86test_memreadaddr, X86TEST_MEMREADADDR_SIZEOF
                                                                            pop     edx
                                                                            ; adjust the jcc condition opcodes
                                                                            mov     al, x86jcc
                                                                            mov     [edx + x86test_mra_offset_jmp1], al
                                                                            mov     [edx + x86test_mra_offset_jmp2], al

                                                                            .break
                                                                    .endif

                                                                    test    operatortype, BRKFLAGF_MWA
                                                                    .if     !ZERO?
                                                                            push    pCodePageWriteAddr
                                                                            x86_memcpy  addr x86test_memwriteaddr, X86TEST_MEMWRITEADDR_SIZEOF
                                                                            pop     edx
                                                                            ; adjust the jcc condition opcodes
                                                                            mov     al, x86jcc
                                                                            mov     [edx + x86test_mwa_offset_jmp1], al
                                                                            mov     [edx + x86test_mwa_offset_jmp2], al

                                                                            .break
                                                                    .endif

                                                                    ; ========================================
                                                                    ; standard default test for most operators
                                                                    ; ========================================
                                                                    ; cmp   ax, cx
                                                                    invoke  x86_WriteByte, 66h
                                                                    invoke  x86_WriteWord, 0c13bh

                                                                    ; jcc   @F
                                                                    invoke  x86_WriteByte, x86jcc
                                                                    invoke  x86_WriteByte, 01h

                                                                    ; retn
                                                                    invoke  x86_WriteByte, 0c3h

                                                                    .break
                                                            .endw

                                                            ; clear operator type after each cmp iteration
                                                            mov     operatortype, 0

                                            endsw
                            .endw

                            ; have to end on multiples of 3 passes! (value cmp value)
                            ; note that the pass count wraps around to 1 after 3 passes, so we test for 1
                            .if     x86pass != 1
                                    return  FALSE
                            .endif

                            invoke  x86_WriteByte, 0bfh     ; mov   edi,nnnn
                            invoke  x86_WriteDWord, TRUE    ; mov   edi,TRUE
                            invoke  x86_WriteByte, 0c3h     ; retn

                            invoke  FlushInstructionCache, $fnc (GetCurrentProcess), NULL, NULL
                            return  TRUE

CompileBreakpointCode       endp



