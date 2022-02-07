
;CreateTapeXORMask       PROTO   :DWORD,:DWORD   ; in Protos.inc
Check_Filler_Byte       PROTO   :DWORD

WriteBASICHeader        PROTO
BeginTAPBlock           PROTO   :BYTE
WriteTAPBytes           PROTO   :DWORD,:DWORD
WriteTAPByte            PROTO   :BYTE
EndTAPBlock             PROTO

BeginBASICLine          PROTO
EndBASICLine            PROTO
WriteBASICNumber        PROTO   :WORD
WriteBASICByte          PROTO   :BYTE
WriteBASICBytes         PROTO   :DWORD,:DWORD

to_Rem                  PROTO   :DWORD
;zx7_compress            PROTO   :DWORD, :DWORD, :DWORD ; in Protos.inc
zx7_cleanup             PROTO

AddLoadTimeTStates      PROTO   :DWORD

.data
val_specified           dd  FALSE
antimerge_specified     dd  FALSE

BasicHeaderData         db  0               ; type - BASIC
BasicFilename           db  "Default   "    ; filename (10 chars)
BasicDataLen            dw  0
                        dw  10              ; autostart line no.
BasicVars               dw  0               ; as BasicDataLen
                        BasicHeader_sizeof  equ $ - BasicHeaderData

.data?
BASICHeader_toggle  DWORD   ?
BASICHeader_fileptr DWORD   ?

out_FH              HANDLE  ?

basiclinenum        WORD    ?


LOADRUN             struct
loadrun_bank        BYTE    ?   ; 16+bank for paging, 255 for RUN
loadrun_address     WORD    ?   ; load addr or run addr
loadrun_length      WORD    ?   ; load length or stack addr
loadrun_XORbyte     BYTE    ?   ; byte used for XOR of loaded data or for filler byte in 'empty' RAM pages
loadrun_decomp      WORD    ?   ; decompression address or 0 if uncompressed
LOADRUN             ends

SAVERUN             struct
lpMem               DWORD   ?
Len                 DWORD   ?
SAVERUN             ends

.data?
align 4
SaveRunTable        SAVERUN     32  dup(<>)  ; 32 SAVERUN entries

.code

token_VAL       equ 176
token_PEEK      equ 190
token_USR       equ 192
token_TO        equ 204
token_READ      equ 227
token_DATA      equ 228
token_REM       equ 234
token_FOR       equ 235
token_NEXT      equ 243
token_POKE      equ 244
token_RANDOMIZE equ 249
token_CLEAR     equ 253

                        include CreateTape.inc

BASNUM                  macro   ascii:REQ, numeric:REQ
                        db      ascii
                        db      14
                        db      0, 0
                        db      numeric and 255
                        db      numeric shr 8
                        db      0
                        endm

VARNUM                  macro   numeric:REQ
                        db      0, 0
                        db      numeric and 255
                        db      numeric shr 8
                        db      0
                        endm

Master_Tape             proc    uses        esi edi ebx,
                                szProgName: DWORD,
                                is_128K:    DWORD,
                                szFilename: DWORD

                        ; copy up to 10 chars from szProgName into BASIC program header
                        mov     esi, szProgName
                        lea     edi, BasicFilename[0]
                        .while  (byte ptr [esi] != 0) && (edi < offset BasicFilename[10])
                                movsb
                        .endw
                        mov     al, " "
                        .while  edi < offset BasicFilename[10]
                                stosb
                        .endw


                        ; attempt to create the output file
                        mov     out_FH, $fnc (CreateFile, szFilename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
                        .if     out_FH == INVALID_HANDLE_VALUE
                                invoke  ShowMessageBox, hWnd, SADD ("Failed to create the output file"), addr szWindowName, MB_OK or MB_ICONERROR
                                return  FALSE
                        .endif

                        ; ============ start to write out the BASIC program ============

                        mov     loadtime_minutes, 0
                        mov     loadtime_seconds, 0
                        mov     loadtime_tstates, 0

                        ; write the BASIC (dummy) header
                        mov     basicprogramlen, 0
                        invoke  WriteBASICHeader

                        ; start the BASIC data area
                        invoke  BeginTAPBlock, 255  ; flag byte for data section

                        mov     basiclinenum, 10    ; initialise BASIC line number


                        ; TAP mastering code here
                        invoke  to_Rem, is_128K


                        ; ======= anti-merge protection =======
                        .data
                        antimerge   db  27h, 0fh, 0ffh, 0ffh, 0dh, 80h

                        .code
                        .if     antimerge_specified == TRUE
                                add     basicprogramlen, sizeof antimerge           ; maintain complete BASIC program size
                                invoke  WriteTAPBytes, addr antimerge, sizeof antimerge
                        .endif

                        ; ============ mark the start of the VARS area ============
                        mov     eax, basicprogramlen
                        mov     BasicVars, ax

                    .data
                        basicvars           db  0b5h, 73h, 0f2h ; USR numeric variable
                                            VARNUM  5
                        basicvars_end       label   byte
                        basicvars_sizeof    equ     basicvars_end - basicvars

                    .code
                        add     basicprogramlen, sizeof basicvars_sizeof            ; maintain complete BASIC program size
                        invoke  WriteTAPBytes, addr basicvars, basicvars_sizeof

                        ; ============ end the BASIC data area ============
                        invoke  EndTAPBlock


                        ; write following TAP memory blocks
                        lea     esi, SaveRunTable
                        assume  esi: ptr SAVERUN

                        .while  [esi].lpMem != 0
                                invoke  BeginTAPBlock, 255                          ; flag byte for data section
                                invoke  WriteTAPBytes, [esi].lpMem, [esi].Len       ; write the data section
                                invoke  EndTAPBlock
                                add     esi, sizeof SAVERUN
                        .endw

                        ; write final loading block data (23296 to 23808)
                        invoke  BeginTAPBlock, 255                                  ; flag byte for data section
                        mov     eax, currentMachine.bank5
                        add     eax, 23296-16384                                    ; eax points to 23296 in bank 5
                        invoke  WriteTAPBytes, eax, 23808-23296 ; write the data section
                        invoke  EndTAPBlock

                        assume  esi: nothing


                        ; rewrite the BASIC (now with correct info) header
                        push    loadtime_minutes
                        push    loadtime_seconds
                        invoke  WriteBASICHeader
                        pop     loadtime_seconds
                        pop     loadtime_minutes

                        invoke  CloseHandle, out_FH
                        return  TRUE

Master_Tape             endp

WriteBASICHeader        proc

                        mov     eax, basicprogramlen
                        mov     BasicDataLen, ax
;                        mov     BasicVars, ax

                        mov     eax, BASICHeader_toggle
                        inc     BASICHeader_toggle

                        and     eax, 1
                        .if     ZERO?
                                ; for 1st pass, preserve the current file pointer
                                mov     BASICHeader_fileptr, $fnc (SetFilePointer, out_FH, 0, NULL, FILE_CURRENT)
                        .else
                                ; for 2nd pass, restore the current file pointer
                                invoke  SetFilePointer, out_FH, BASICHeader_fileptr, NULL, FILE_BEGIN
                        .endif
    
                        invoke  BeginTAPBlock, 0    ; flag byte for header section
                        invoke  WriteTAPBytes, addr BasicHeaderData, BasicHeader_sizeof
                        invoke  EndTAPBlock
                        ret

WriteBASICHeader        endp

.data?
basicprogramlen         DWORD   ?
basiclinelen            DWORD   ?
basiclineptr            DWORD   ?

;basiclinedata       BYTE    65536    dup (?)   ; in Vars.asm
.code

BeginBASICLine          proc

                        mov     ax, basiclinenum                ; current BASIC line number
                        mov     basiclinedata[0], ah            ; line number (HB/LB order)
                        mov     basiclinedata[1], al
                        mov     word ptr basiclinedata[2], 0    ; line length

                        mov     basiclineptr, offset basiclinedata[4]
                        mov     basiclinelen, 4
                        ret

BeginBASICLine          endp

.data
basnumfmt               db  14
                        db  0, 0
basintnum               dw  0
                        db  0
.code
WriteBASICNumber        proc    uses    ebx,
                                basnum: WORD

                        local   textstring:     TEXTSTRING,
                                pTEXTSTRING:    DWORD

                        invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                        ADDTEXTDECIMAL  pTEXTSTRING, basnum

                        mov     ebx, len (addr textstring)

                        .if     val_specified == TRUE
                                invoke  WriteBASICByte, token_VAL
                                invoke  WriteBASICByte, 34
                                ; write ASCII representation
                                invoke  WriteBASICBytes, addr textstring, ebx
                                invoke  WriteBASICByte, 34
                        .else
                                ; write ASCII representation
                                invoke  WriteBASICBytes, addr textstring, ebx
    
                                ; write internal number format
                                m2m     basintnum, basnum
                                invoke  WriteBASICBytes, addr basnumfmt, 6
                        .endif
                        ret

WriteBASICNumber        endp

WriteBASICBytes         proc    uses          esi,
                                lpBasicBytes: DWORD,
                                count:        DWORD

                        mov     esi, lpBasicBytes

                        .while  count > 0
                                invoke  WriteBASICByte, [esi]
                                inc     esi
                                dec     count
                        .endw
                        ret

WriteBASICBytes         endp

WriteBASICByte          proc    basicbyte: BYTE

                        mov     ecx, basiclineptr
                        mov     al,  basicbyte
                        mov     [ecx], al

                        inc     basiclineptr
                        inc     basiclinelen
                        ret

WriteBASICByte          endp

EndBASICLine            proc

                        invoke  WriteBASICByte, 13              ; newline char

                        mov     eax, basiclinelen
                        add     basicprogramlen, eax            ; maintain complete BASIC program size

                        sub     ax, 4                           ; the line length stored in BASIC = length - line number/length bytes
                        mov     word ptr basiclinedata[2], ax   ; line length

                        invoke  WriteTAPBytes, addr basiclinedata, basiclinelen

                        add     basiclinenum, 10                ; update BASIC line number for following line
                        ret

EndBASICLine            endp

.data?
tapblocklen             DWORD   ?
tapblockptr             DWORD   ?
tapblockcheck           BYTE    ?

;tapblockdata    BYTE    65536  dup (?)     ; in Vars.asm
.code

AddLoadTimeTStates      proc    time:   DWORD

                        mov     eax, time
                        mov     ecx, loadtime_tstates
                        add     ecx, eax
                        .while  ecx > 3500000
                                sub     ecx, 3500000
                                inc     loadtime_seconds
                                .while  loadtime_seconds >= 60
                                        sub     loadtime_seconds, 60
                                        inc     loadtime_minutes
                                .endw
                        .endw
                        mov     loadtime_tstates, ecx
                        ret

AddLoadTimeTStates      endp

BeginTAPBlock           proc    flag: BYTE

                        mov     tapblockptr,   offset tapblockdata
                        mov     tapblocklen,   0
                        mov     tapblockcheck, 0

                        invoke  WriteTAPByte, flag          ; write the flag byte

                        test    flag, 128
                        .if     ZERO?
                                mov     ecx, 5*3500000      ; 5 seconds for header tone
                        .else
                                mov     ecx, 2*3500000      ; 2 seconds for data tone
                        .endif
                        add     ecx, 667 + 735 + 3500000    ; sync pulses + 1 second TAP block gap
                        invoke  AddLoadTimeTStates, ecx
                        ret

BeginTAPBlock           endp

WriteTAPBytes           proc    uses        esi,
                                lpTapBytes: DWORD,
                                count:      DWORD

                        mov     esi, lpTapBytes

                        .while  count > 0
                                invoke  WriteTAPByte, [esi]
                                inc     esi
                                dec     count
                        .endw
                        ret

WriteTAPBytes           endp

WriteTAPByte            proc    tapbyte: BYTE

                        mov     ecx, tapblockptr
                        mov     al,  tapbyte
                        mov     [ecx], al

                        xor     tapblockcheck, al
                        inc     tapblockptr
                        inc     tapblocklen

                        xor     ecx, ecx
                        mov     ah, 8
                @loop:  shl     al, 1
                        .if     CARRY?
                                add     ecx, 1710 * 2   ; bits saved in 2 passes
                        .else
                                add     ecx, 855 * 2    ; bits saved in 2 passes
                        .endif
                        dec     ah
                        jnz     @loop

                        invoke  AddLoadTimeTStates, ecx
                        ret

WriteTAPByte            endp

EndTAPBlock             proc

                        local   taplenbytes:    WORD

                        invoke  WriteTAPByte, tapblockcheck ; end the current block with its checksum, increasing its length by 1

                        mov     eax, tapblocklen
                        mov     taplenbytes, ax
                        invoke  WriteFile, out_FH, addr taplenbytes, 2, addr BytesSaved, NULL
        
                        .if     tapblocklen > 0
                                invoke  WriteFile, out_FH, addr tapblockdata, tapblocklen, addr BytesSaved, NULL
                        .endif
                        ret

EndTAPBlock             endp


; returns with XOR mask in cl

CreateTapeXORMask       proc    uses    esi edi ebx,
                                lpMem:  DWORD,
                                Len:    DWORD

                        local   minsetbits:     DWORD,
                                xormask:        BYTE

                        mov     xormask, 0

                        mov     minsetbits, -1

                        xor     dh, dh              ; xor mask = 0

                        SETLOOP 256
                                xor     esi, esi            ; num set bits = 0

                                mov     edi, lpMem
                                mov     ecx, Len

                @alltapbytes:   mov     bl, [edi]           ; tape byte
                                inc     edi

                                xor     bl, dh              ; XOR tape byte with current mask

                @bit_loop:      shl     bl, 1
                                adc     esi, 0              ; num set bits += carry flag
                                or      bl, bl
                                jnz     @bit_loop

                                dec     ecx
                                jnz     @alltapbytes

                                .if     esi < minsetbits
                                        mov     minsetbits, esi
                                        mov     xormask, dh
                                .endif

                                inc     dh                  ; increment XOR mask
                        ENDLOOP

                        ; now XOR tape data with correct mask value
                        mov     al, xormask
                        .if     al != 0
                                mov     edi, lpMem
                                mov     ecx, Len
                    @xor_loop:  xor     [edi], al
                                inc     edi
                                dec     ecx
                                jnz     @xor_loop
                        .endif

                        mov     cl, xormask
                        ret

CreateTapeXORMask       endp


.data
_rem_USR                db  token_RANDOMIZE
                        db  "USR 0:"
                        db  token_RANDOMIZE
                        db  token_USR
                        db  "("
                        db  token_PEEK
                        BASNUM  "23635", 23635
                        db  "+"
                        BASNUM  "256", 256
                        db  "*"
                        db  token_PEEK
                        BASNUM  "23636", 23636
                        db  "+"
                        BASNUM  "7", 7
                        db  ")"
_rem_USR_sizeof         equ $ - _rem_USR


.code

to_Rem                  proc    uses    esi edi ebx,
                                is_128K:    DWORD

                        local   LoadRun:        LOADRUN

                        local   old_SP:         WORD,
                                old_PC:         WORD

                        local   paging_locked:  BYTE,
                                bank_13467:     BYTE

                        ; preserve original SP and PC
                        mov     ax, z80registers._sp
                        mov     old_SP, ax
                        mov     ax, zPC
                        mov     old_PC, ax

                        ; Bank selection flags:
                        BITDEF	FLAG, BANK0, 0
                        BITDEF	FLAG, BANK1, 1
                        BITDEF	FLAG, BANK2, 2
                        BITDEF	FLAG, BANK3, 3
                        BITDEF	FLAG, BANK4, 4
                        BITDEF	FLAG, BANK5, 5
                        BITDEF	FLAG, BANK6, 6
                        BITDEF	FLAG, BANK7, 7

                        mov     bank_13467, FLAGF_BANK1 or FLAGF_BANK3 or FLAGF_BANK4 or FLAGF_BANK6 or FLAGF_BANK7

                        mov     paging_locked, FALSE

                        ifc     is_128K eq TRUE then test Last7FFDWrite, 32 : setnz paging_locked

                        .if     paging_locked == TRUE
                                switch  currentMachine.RAMREAD6    ; paged memory ptr @ #C000
                                        case    currentMachine.bank1
                                                mov     bank_13467, FLAGF_BANK1 ; only save bank 1
                                        case    currentMachine.bank3
                                                mov     bank_13467, FLAGF_BANK3 ; only save bank 3
                                        case    currentMachine.bank4
                                                mov     bank_13467, FLAGF_BANK4 ; only save bank 4
                                        case    currentMachine.bank6
                                                mov     bank_13467, FLAGF_BANK6 ; only save bank 6
                                        case    currentMachine.bank7
                                                mov     bank_13467, FLAGF_BANK7 ; only save bank 7
                                endsw
                        .endif

                        ; prepare and write the stack running code into memory
                        switch  z80registers.intmode, eax
                                case    0
                                        mov     Tape_Stack_IM, 46h  ; IM0
                                case    2
                                        mov     Tape_Stack_IM, 5Eh  ; IM2
                                .else
                                        mov     Tape_Stack_IM, 56h  ; IM1
                        endsw

                        ifc     currentMachine.iff2 eq FALSE then mov Tape_Stack_INTS, 243 else mov Tape_Stack_INTS, 251

                        lea     esi, RegisterBase   ; required for PUSHSTACK macros
                        mov     ax, z80registers.pc
                        PUSHSTACK
                        mov     ax, z80registers.af.w
                        PUSHSTACK
                        mov     al, z80registers.r      ; we adjust R to be correct on game re-entry
                        mov     cl, al
                        and     cl, 128
                        sub     al, 5
                        and     al, 127
                        or      al, cl
                        shl     ax, 8
                        PUSHSTACK
                        mov     al, z80registers.i
                        shl     ax, 8
                        PUSHSTACK
                        mov     ax, z80registers.bc.w
                        PUSHSTACK
                        mov     ax, z80registers.de.w
                        PUSHSTACK
                        mov     ax, z80registers.hl.w
                        PUSHSTACK
                        mov     ax, z80registers.af_.w
                        PUSHSTACK
                        mov     ax, z80registers.bc_.w
                        PUSHSTACK
                        mov     ax, z80registers.de_.w
                        PUSHSTACK
                        mov     ax, z80registers.hl_.w
                        PUSHSTACK
                        mov     ax, z80registers.ix.w
                        PUSHSTACK
                        mov     ax, z80registers.iy.w
                        PUSHSTACK

                        mov     al, Last_FE_Write
                        shl     ax, 8
                        PUSHSTACK

                        mov     ax, z80registers._sp
                        mov     Tape_Stack_SP, ax   ; set LD SP, addr for restoring registers in stack code

                        ; stack the AY registers and currently selected AY register
                        dec     z80registers._sp
                        mov     bx, z80registers._sp
                        mov     al, SCSelectReg
                        call    MemPokeByte

                        lea     esi, SCRegister15
                        mov     ecx, 16
    @writeAYregs:       dec     z80registers._sp
                        mov     bx, z80registers._sp
                        mov     al, [esi]
                        call    MemPokeByte
                        dec     esi
                        dec     ecx
                        jnz     @writeAYregs

                        mov     ax, z80registers._sp
                        mov     Tape_Stack_AY, ax   ; set address of AY registers in stack code

; do ULA+ restoration?

                        ; stack the snapshot restoration and execution code
                        lea     esi, Tape_Stack_end ; one byte beyond stack code
                        mov     ecx, Tape_Stack_size
    @writestackcode:    dec     z80registers._sp
                        dec     esi
                        mov     bx, z80registers._sp
                        mov     al, [esi]
                        call    MemPokeByte
                        dec     ecx
                        jnz     @writestackcode

                        ; stack code address becomes the PC execute address entry in the BASIC loader
                        mov     ax, z80registers._sp
                        mov     currentMachine.pc, ax

                        ; end of stack code preparation code


                        ; prepare to write the BASIC program
                        memclr  addr SaveRunTable, sizeof SaveRunTable

                        mov     basiclinenum, 0         ; initialise BASIC line number as line 0 for REM format

                        ; REM <code>
                        invoke  BeginBASICLine

                        invoke  WriteBASICByte, token_REM
                        invoke  WriteBASICByte, 13
                        invoke  WriteBASICByte, 128

                        ; write the main BASIC loader code into the REM statement
                        invoke  WriteBASICBytes, addr Tape_BASIC, Tape_BASIC_size

                        ; write the Paged RAM bank flag byte
                        .if     is_128K == TRUE
                                mov     al, Last7FFDWrite
                        .else
                                mov     al, 16
                        .endif
                        invoke  WriteBASICByte, al

                        ; write the is_128K flag byte
                        ifc     is_128K eq TRUE then mov al, 1 else mov al, 0
                        invoke  WriteBASICByte, al

                        ; write the copy of the upper 64 bytes
                        mov     eax, currentMachine.bank0
                        add     eax, 16384-64               ; start address of last 64 bytes in bank 0
                        invoke  WriteBASICBytes, eax, 64

                        ; prepare to write the load/run table entries (8 entries)
                        lea     esi, LoadRun
                        assume  esi: ptr LOADRUN

                        lea     edi, SaveRunTable
                        assume  edi: ptr SAVERUN

                        ; prepare the compressed data and fill the LoadRun table entries
                        ; but we write the compressed data later
                        ; only fill and write the table entries here


                        ; loading screen
                        memclr  addr LoadRun, sizeof LOADRUN
                        mov     [esi].loadrun_bank, 16
                        mov     [esi].loadrun_address, 16384
                        mov     [esi].loadrun_length, 6912

                        mov     [edi].lpMem, offset zx7_Bank5
                        mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank5, 6912, [edi].lpMem)
                        add     edi, sizeof SAVERUN

                        mov     [esi].loadrun_XORbyte, cl
                        .if     eax < 6912
                                ; data is compressed
                                mov     [esi].loadrun_length, ax
                                mov     [esi].loadrun_address, 32768    ; load at 32768
                                mov     [esi].loadrun_decomp, 16384     ; decompress to display file
                        .endif                
                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                        ; end loading screen


                        ; start 128K RAM banks
                        .if     is_128K == TRUE

                                ; Bank 1
                                test    bank_13467, FLAGF_BANK1
                                .if     !ZERO?
                                        memclr  addr LoadRun, sizeof LOADRUN
                                        mov     [esi].loadrun_bank, 16 + 1

                                        invoke  Check_Filler_Byte, currentMachine.bank1
                                        .if     ah == TRUE
                                                mov     [esi].loadrun_XORbyte, al   ; XORbyte is filler byte
                                                or      [esi].loadrun_bank, 80h     ; bit 7 set in bank byte marks to use filler byte
                                        .else
                                                mov     [esi].loadrun_address, 49152
                                                mov     [esi].loadrun_length, 16384
        
                                                mov     [edi].lpMem, offset zx7_Bank1
                                                mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank1, 16384, [edi].lpMem)
                                                add     edi, sizeof SAVERUN

                                                mov     [esi].loadrun_XORbyte, cl
                                                .if     eax < 16384
                                                        ; data is compressed
                                                        mov     [esi].loadrun_length, ax
                                                        mov     [esi].loadrun_address, 32768    ; load at 32768
                                                        mov     [esi].loadrun_decomp, 49152     ; decompress to RAM bank
                                                .endif
                                        .endif
                                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                                .endif

                                ; Bank 3
                                test    bank_13467, FLAGF_BANK3
                                .if     !ZERO?
                                        memclr  addr LoadRun, sizeof LOADRUN
                                        mov     [esi].loadrun_bank, 16 + 3

                                        invoke  Check_Filler_Byte, currentMachine.bank3
                                        .if     ah == TRUE
                                                mov     [esi].loadrun_XORbyte, al   ; XORbyte is filler byte
                                                or      [esi].loadrun_bank, 80h     ; bit 7 set in bank byte marks to use filler byte
                                        .else
                                                mov     [esi].loadrun_address, 49152
                                                mov     [esi].loadrun_length, 16384
        
                                                mov     [edi].lpMem, offset zx7_Bank3
                                                mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank3, 16384, [edi].lpMem)
                                                add     edi, sizeof SAVERUN

                                                mov     [esi].loadrun_XORbyte, cl
                                                .if     eax < 16384
                                                        ; data is compressed
                                                        mov     [esi].loadrun_length, ax
                                                        mov     [esi].loadrun_address, 32768    ; load at 32768
                                                        mov     [esi].loadrun_decomp, 49152     ; decompress to RAM bank
                                                .endif
                                        .endif
                                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                                .endif

                                ; Bank 4
                                test    bank_13467, FLAGF_BANK4
                                .if     !ZERO?
                                        memclr  addr LoadRun, sizeof LOADRUN
                                        mov     [esi].loadrun_bank, 16 + 4

                                        invoke  Check_Filler_Byte, currentMachine.bank4
                                        .if     ah == TRUE
                                                mov     [esi].loadrun_XORbyte, al   ; XORbyte is filler byte
                                                or      [esi].loadrun_bank, 80h     ; bit 7 set in bank byte marks to use filler byte
                                        .else
                                                mov     [esi].loadrun_address, 49152
                                                mov     [esi].loadrun_length, 16384
        
                                                mov     [edi].lpMem, offset zx7_Bank4
                                                mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank4, 16384, [edi].lpMem)
                                                add     edi, sizeof SAVERUN

                                                mov     [esi].loadrun_XORbyte, cl
                                                .if     eax < 16384
                                                        ; data is compressed
                                                        mov     [esi].loadrun_length, ax
                                                        mov     [esi].loadrun_address, 32768    ; load at 32768
                                                        mov     [esi].loadrun_decomp, 49152     ; decompress to RAM bank
                                                .endif
                                        .endif
                                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                                .endif

                                ; Bank 6
                                test    bank_13467, FLAGF_BANK6
                                .if     !ZERO?
                                        memclr  addr LoadRun, sizeof LOADRUN
                                        mov     [esi].loadrun_bank, 16 + 6

                                        invoke  Check_Filler_Byte, currentMachine.bank6
                                        .if     ah == TRUE
                                                mov     [esi].loadrun_XORbyte, al   ; XORbyte is filler byte
                                                or      [esi].loadrun_bank, 80h     ; bit 7 set in bank byte marks to use filler byte
                                        .else
                                                mov     [esi].loadrun_address, 49152
                                                mov     [esi].loadrun_length, 16384

                                                mov     [edi].lpMem, offset zx7_Bank6
                                                mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank6, 16384, [edi].lpMem)
                                                add     edi, sizeof SAVERUN

                                                mov     [esi].loadrun_XORbyte, cl
                                                .if     eax < 16384
                                                        ; data is compressed
                                                        mov     [esi].loadrun_length, ax
                                                        mov     [esi].loadrun_address, 32768    ; load at 32768
                                                        mov     [esi].loadrun_decomp, 49152     ; decompress to RAM bank
                                                .endif
                                        .endif
                                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                                .endif

                                ; Bank 7
                                test    bank_13467, FLAGF_BANK7
                                .if     !ZERO?
                                        memclr  addr LoadRun, sizeof LOADRUN
                                        mov     [esi].loadrun_bank, 16 + 7

                                        invoke  Check_Filler_Byte, currentMachine.bank7
                                        .if     ah == TRUE
                                                mov     [esi].loadrun_XORbyte, al   ; XORbyte is filler byte
                                                or      [esi].loadrun_bank, 80h     ; bit 7 set in bank byte marks to use filler byte
                                        .else
                                                mov     [esi].loadrun_address, 49152
                                                mov     [esi].loadrun_length, 16384
        
                                                mov     [edi].lpMem, offset zx7_Bank7
                                                mov     [edi].Len, $fnc (zx7_compress, currentMachine.bank7, 16384, [edi].lpMem)
                                                add     edi, sizeof SAVERUN

                                                mov     [esi].loadrun_XORbyte, cl
                                                .if     eax < 16384
                                                        ; data is compressed
                                                        mov     [esi].loadrun_length, ax
                                                        mov     [esi].loadrun_address, 32768    ; load at 32768
                                                        mov     [esi].loadrun_decomp, 49152     ; decompress to RAM bank
                                                .endif
                                        .endif
                                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                                .endif
                        .endif
                        ; end 128K RAM banks


                        ; start main code block
                        mov     ebx, (65536-64) - 23808     ; default size for 48K mode

                        .if     is_128K == TRUE
                                ; if paging locked out and bank 0 isn't paged then we don't even need bank 0...
                                .if     paging_locked == TRUE
                                        mov     eax, currentMachine.RAMREAD6
                                        .if     eax != currentMachine.bank0
                                                mov     ebx, 49152 - 23808
                                        .endif
                                .endif
                        .endif

                        memclr  addr LoadRun, sizeof LOADRUN
                        mov     [esi].loadrun_bank, 16
                        mov     [esi].loadrun_address, 23808
                        mov     [esi].loadrun_length, bx

                        mov     [edi].lpMem, offset zx7_Bank5[23808-16384]
                        mov     eax, currentMachine.bank5
                        add     eax, 23808-16384
                        mov     [edi].Len, $fnc (zx7_compress, eax, ebx, [edi].lpMem)
                        add     edi, sizeof SAVERUN

                        mov     [esi].loadrun_XORbyte, cl
                        .if     eax < ebx
                                ; data is compressed
                                mov     [esi].loadrun_length, ax
                                mov     ecx, 65536
                                sub     ecx, eax
                                mov     [esi].loadrun_address, cx       ; load at the highest possible address
                                mov     [esi].loadrun_decomp, 23808     ; decompress to 23808
                        .endif
                        invoke  WriteBASICBytes, esi, sizeof LOADRUN
                        ; end start main code block


                        memclr  addr LoadRun, sizeof LOADRUN
                        mov     [esi].loadrun_bank, 255
                        mov     ax, zPC
                        mov     [esi].loadrun_address, ax
                        mov     ax, z80registers._sp
                        mov     [esi].loadrun_length, ax
                        invoke  WriteBASICBytes, esi, sizeof LOADRUN

                        assume  esi: nothing
                        assume  edi: nothing

                        invoke  EndBASICLine

                        ; RANDOMIZE USR...
                        invoke  BeginBASICLine
                        invoke  WriteBASICBytes, addr _rem_USR, _rem_USR_sizeof
                        invoke  EndBASICLine

                        ; restore original SP and PC
                        mov     ax, old_SP
                        mov     z80registers._sp, ax
                        mov     ax, old_PC
                        mov     zPC, ax
                        ret

to_Rem                  endp

; returns AH = TRUE and AL = filler byte
; or AH = FALSE

Check_Filler_Byte       proc    uses    esi,
                                lpBank: DWORD

                        mov     esi, lpBank
                        mov     al, [esi]
                        inc     esi

                        mov     ecx, 16383
            @loop:      cmp     al, [esi]
                        jne     @nomatch

                        inc     esi
                        dec     ecx
                        jnz     @loop

                        mov     ah, TRUE
                        ret

            @nomatch:   return  0

Check_Filler_Byte       endp


.data?
zx7dataptr              DWORD   ?

.code
; returns size of (compressed?) data at lpDestMem
zx7_compress            proc    uses        esi edi ebx,
                                lpSrcMem:   DWORD,
                                SrcLen:     DWORD,
                                lpDestMem:  DWORD

                        local   zx7datalen: DWORD,
                                TempHandle: DWORD,
                                zx7path    [MAX_PATH]: BYTE,
                                zx7CmdLine [MAX_PATH*3]: BYTE

                        mov     zx7dataptr, 0   ; null memptr, requires GlobalFree() if set by ReadFileToMemory()

                        .if     $fnc (CreateTempFile, addr zx7SrcFile, addr TempHandle) == FALSE
                                jmp     @zx7_failed
                        .endif
                        invoke  CloseHandle, TempHandle ; CreateTempFile opens a filehandle so we close it

                        invoke  @@CopyString, addr zx7SrcFile, addr zx7DestFile
                        APPENDTEXTSTRING      addr zx7DestFile, SADD (".zx7")

                        invoke  GetAppPath, addr zx7path
                        APPENDTEXTSTRING    addr zx7path, SADD ("zx7.exe")

                        ; write source memory to temp source file
                        .if     $fnc (WriteMemoryToFile, addr zx7SrcFile, lpSrcMem, SrcLen) == 0
                                invoke  ShowMessageBox, hWnd, SADD ("WriteMemoryToFile failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                jmp     @zx7_failed
                        .endif

                        memclr  addr StartupInfo, sizeof StartupInfo
                        mov     StartupInfo.cb, sizeof STARTUPINFO
                        mov     StartupInfo.wShowWindow, SW_SHOWDEFAULT

                        lea     esi, zx7SrcFile
                        lea     edi, zx7DestFile
                        mov     zx7CmdLine, 0
                        invoke  szMultiCat, 11, addr zx7CmdLine,
                                                addr char_quote, addr zx7path, addr char_quote,
                                                addr char_space,
                                                addr char_quote, esi, addr char_quote,
                                                addr char_space,
                                                addr char_quote, edi, addr char_quote

                        .if     $fnc (CreateProcess, NULL, addr zx7CmdLine, NULL, NULL, FALSE, DETACHED_PROCESS, NULL, NULL, addr StartupInfo, addr ProcessInfo) == 0
                                invoke  ShowMessageBox, hWnd, SADD ("CreateProcess failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                jmp     @zx7_failed
                        .endif

                        ; wait for zx7.exe to finish
                        invoke  WaitForSingleObject, ProcessInfo.hProcess, INFINITE

                        ; close handles to the child process and its primary thread
                        invoke  CloseHandle, ProcessInfo.hProcess
                        invoke  CloseHandle, ProcessInfo.hThread

                        ifc     $fnc (ReadFileToMemory, addr zx7DestFile, addr zx7dataptr, addr zx7datalen) eq 0 then jmp @zx7_failed

                        mov     eax, zx7datalen
                        .if     (eax == 0) || (eax >= SrcLen)
                                ; something not right with compressed data length...
                                jmp     @zx7_failed
                        .endif

                        invoke  MemoryCopy, zx7dataptr, lpDestMem, zx7datalen   ; copy compressed data to destmem
                        invoke  zx7_cleanup
                        invoke  CreateTapeXORMask, lpDestMem, zx7datalen        ; create XOR mask in cl
                        return  zx7datalen                                      ; and return our compressed data length


        @zx7_failed:    invoke  zx7_cleanup

                        invoke  MemoryCopy, lpSrcMem, lpDestMem, SrcLen         ; on failure, simply make a direct copy in destmem
                        invoke  CreateTapeXORMask, lpDestMem, SrcLen            ; create XOR mask in cl
                        return  SrcLen                                          ; and return original source size

zx7_compress            endp


zx7_cleanup             proc

                        ifc     zx7dataptr ne 0 then invoke GlobalFree, zx7dataptr : mov zx7dataptr, 0

                        .if     $fnc (exist, addr zx7SrcFile) == 1
                                invoke  DeleteFile, addr zx7SrcFile
                        .endif
                        .if     $fnc (exist, addr zx7DestFile) == 1
                                invoke  DeleteFile, addr zx7DestFile
                        .endif
                        ret
zx7_cleanup             endp


