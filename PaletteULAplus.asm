
.data?
ULAplusPalette      BYTE    64  dup (?)

ULAplus_RegPort     db      ?

Mode64_Enabled      db      ?   ; last mode-enabled state set by writing to MODEGROUP

ULAplus_LastWrite   db      ?

.data
align 4
                    RESETENUM   0
                    ENUM    ULAPLUSPALETTE_AMBER
                    ENUM    ULAPLUSPALETTE_C64
                    ENUM    ULAPLUSPALETTE_DEMO
                    ENUM    ULAPLUSPALETTE_GENERIC
                    ENUM    ULAPLUSPALETTE_GRADIENTS
                    ENUM    ULAPLUSPALETTE_GREENSCREEN
                    ENUM    ULAPLUSPALETTE_PRIMARIES
                    ENUM    ULAPLUSPALETTE_RGB
                    ENUM    ULAPLUSPALETTE_RGB_ALT
                    ENUM    ULAPLUSPALETTE_STANDARD

                    ENUM    MAXULAPLUSPALETTES

ULAplusPalettePtrs  dd  ULAplus_Amber
                    dd  ULAplus_C64
                    dd  ULAplus_Demo
                    dd  ULAplus_Generic
                    dd  ULAplus_Gradients
                    dd  ULAplus_GreenScreen
                    dd  ULAplus_Primaries
                    dd  ULAplus_RGB
                    dd  ULAplus_RGB_alt
                    dd  ULAplus_Standard

ULAplus_Standard    db  000h, 002h, 018h, 01bh, 0c0h, 0c3h, 0d8h, 0dbh ; INK
                    db  000h, 002h, 018h, 01bh, 0c0h, 0c3h, 0d8h, 0dbh ; PAPER
                    db  000h, 003h, 01ch, 01fh, 0e0h, 0e3h, 0fch, 0ffh ; +BRIGHT
                    db  000h, 003h, 01ch, 01fh, 0e0h, 0e3h, 0fch, 0ffh ;
                    db  0dbh, 0d8h, 0c3h, 0c0h, 01bh, 018h, 002h, 000h ; +FLASH
                    db  0dbh, 0d8h, 0c3h, 0c0h, 01bh, 018h, 002h, 000h ;
                    db  0ffh, 0fch, 0e3h, 0e0h, 01fh, 01ch, 003h, 000h ; +BRIGHT/
                    db  0ffh, 0fch, 0e3h, 0e0h, 01fh, 01ch, 003h, 000h ; +FLASH

ULAplus_Amber       db  0,4,40,44,80,84,120,124,0,4,40,44,80,84,120,124
                    db  0,4,40,44,80,84,120,124,0,4,40,44,80,84,120,124
                    db  0,4,40,44,80,84,120,124,0,4,40,44,80,84,120,124
                    db  0,4,40,44,80,84,120,124,0,4,40,44,80,84,120,124

ULAplus_C64         db  0,255,48,175,82,173,38,217,0,255,48,175,82,173,38,217
                    db  0,255,48,175,82,173,38,217,80,72,117,73,146,246,111,182
                    db  80,72,117,73,146,246,111,182,0,255,48,175,82,173,38,217
                    db  80,72,117,73,146,246,111,182,80,72,117,73,146,246,111,182

ULAplus_Demo        db  31,63,95,127,159,191,223,255,0,5,9,13,17,21,25,29
                    db  2,3,7,11,15,19,23,27,61,93,125,157,189,221,253,254
                    db  97,65,33,1,28,20,12,185,251,247,243,239,24,16,8,222
                    db  185,112,40,210,137,64,147,74,148,76,246,173,100,183,111,37

ULAplus_Generic     db  0,2,16,18,128,130,108,110,0,1,8,9,64,65,72,73
                    db  0,39,61,63,229,231,180,255,0,3,28,31,224,227,144,255
                    db  0,111,125,127,237,239,252,255,0,75,93,95,233,235,216,255
                    db  0,183,190,191,246,247,254,255,0,147,158,159,242,243,253,255

ULAplus_Gradients   db  0,3,28,31,224,227,252,255,0,3,24,27,192,195,216,219
                    db  0,2,20,22,160,162,180,182,0,2,16,18,128,130,144,146
                    db  0,1,12,13,96,97,108,109,0,1,8,9,64,65,72,73
                    db  0,0,4,4,32,32,36,36,0,0,0,0,0,0,0,0

ULAplus_GreenScreen db  0,32,64,96,128,160,192,224,0,32,64,96,128,160,192,224
                    db  0,32,64,96,128,160,192,224,0,32,64,96,128,160,192,224
                    db  0,32,64,96,128,160,192,224,0,32,64,96,128,160,192,224
                    db  0,32,64,96,128,160,192,224,0,32,64,96,128,160,192,224

ULAplus_Primaries   db  0,252,1,253,2,254,3,255,32,220,33,221,34,222,35,223
                    db  64,188,65,189,66,190,67,191,96,156,97,157,98,158,99,159
                    db  128,124,129,125,130,126,131,127,160,92,161,93,162,94,163,95
                    db  160,60,193,61,194,62,195,63,224,28,225,29,226,30,227,31

ULAplus_RGB         db  255,254,253,252,247,246,245,244,191,190,189,188,183,178,181,180
                    db  127,126,125,124,119,118,117,116,31,30,29,28,23,22,21,20
                    db  239,238,237,236,227,226,225,224,175,174,173,172,163,162,161,160
                    db  111,110,109,108,99,98,97,96,47,14,13,12,3,2,1,0

ULAplus_RGB_alt     db  0,3,28,31,224,227,252,255,1,99,29,127,160,226,188,254
                    db  2,163,30,191,96,225,124,253,98,162,126,190,97,161,125,189
                    db  12,15,20,23,236,239,244,247,13,111,21,119,172,238,180,246
                    db  14,175,22,183,108,237,116,245,110,174,118,182,109,173,117,181


.code

; Register Port:
ULAPLUS_GROUPMASK       equ     11000000b
ULAPLUS_PALETTEGROUP    equ     00000000b
ULAPLUS_MODEGROUP       equ     01000000b

                  ; called at Reset time
InitULAplus         proc    uses esi edi

                    invoke  BuildULAplusPalette

                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_STANDARD

                    invoke  EnableULAplusMode, FALSE                        ; palette mode off

                    invoke  ULAplus_WriteReg,  ULAPLUS_PALETTEGROUP or 0    ; set palette entry to 0

                    mov     ULAplus_LastWrite, 255
                    ret
InitULAplus         endp

EnableULAplusMode   proc    Enable: BYTE    ; bool

                    invoke  ULAplus_WriteReg,  ULAPLUS_MODEGROUP
                    invoke  ULAplus_WriteData, Enable
                    ret
EnableULAplusMode   endp

SelectULAplusPalette proc   uses    esi edi,
                            PalNum: DWORD

                    mov     eax, PalNum
                    .if     eax < MAXULAPLUSPALETTES
                            mov     esi, [ULAplusPalettePtrs+eax*4]
                            lea     edi, ULAplusPalette
                            mov     ecx, 64/4
                            rep     movsd

                            mov     al, Last_FE_Write
                            call    Set_Border_64       ; update as this will change the active border colour in ULAplus mode
                    .endif
                    ret

SelectULAplusPalette endp

                  ; called when changing the 64 colour mode in options
SetULAplusState     proc    uses esi edi ebx

                    .if     (ULAplus_Enabled == TRUE) && (MACHINE.Has_ULAplus == TRUE)
                            mov     al, Mode64_Enabled
                            mov     SPGfx.ULA64_Active, al ; restore last 64 colour mode state if user turns ULAplus option on again
                    .else
                            mov     SPGfx.ULA64_Active, FALSE
                    .endif
                    ret

SetULAplusState     endp

ULAplus_WriteReg    proc    Value:  BYTE

                    mov     al, Value
                    mov     ULAplus_RegPort, al
                    ret

ULAplus_WriteReg    endp

ULAplus_ReadData    proc

                    mov     al, ULAplus_LastWrite   ; return the last value written to the ULAplus data port
                    ret

;                    mov     al, ULAplus_RegPort
;                    and     al, ULAPLUS_GROUPMASK
;
;                    .if     al == ULAPLUS_PALETTEGROUP
;                            movzx   ecx, ULAplus_RegPort
;                            and     ecx, 63
;                            mov     al, [ULAplusPalette+ecx]
;
;                    .elseif al == ULAPLUS_MODEGROUP
;                            mov		al, Mode64_Enabled	; return current 64 colour active status in bit 0. Mode64_Enabled always True or False (1 or 0)
;                    .endif
;
;                    ret

ULAplus_ReadData    endp

ULAplus_WriteData   proc    Value:  BYTE

                    mov     al,  Value
                    mov     ULAplus_LastWrite, al

                    mov     al, ULAplus_RegPort
                    and     al, ULAPLUS_GROUPMASK

                    .if     al == ULAPLUS_PALETTEGROUP
                            movzx   ecx, ULAplus_RegPort
                            and     ecx, 63
                            mov     al,  Value
                            mov     [ULAplusPalette+ecx], al

                            mov     al, Last_FE_Write
                            call    Set_Border_64       ; update as this may change the active border colour in ULAplus mode

                    .elseif al == ULAPLUS_MODEGROUP
                            mov     al, Value
                            and     al, 1
                            .if     !ZERO?
                                    mov     Mode64_Enabled,      TRUE   ; store separately incase user changes 64 colour option in options
                                    mov     SPGfx.ULA64_Active,  TRUE
                            .else
                                    mov     Mode64_Enabled,      FALSE
                                    mov     SPGfx.ULA64_Active,  FALSE
                            .endif
;                            invoke  SetDirtyLines  ; breaks stuff
                    .endif

                    ret
ULAplus_WriteData   endp

BuildULAplusPalette proc    uses    ebx

                    local   SpecCol:    DWORD,
                            ColPercent: RGBQUAD

                    xor     ebx, ebx

                    .while  ebx < 256
                            invoke  SetULAplusPaletteEntry, ebx, bl
                            inc     ebx
                    .endw
                    ret

BuildULAplusPalette endp

SetULAplusPaletteEntry  proc    PaletteEntry:   DWORD,
                                Attr:           BYTE

                    local   SpecCol:    DWORD,
                            ColPercent: RGBQUAD

                    ifc     PaletteEntry ge 256 then ret

                    invoke  MapAttr2RGBPercent, Attr, addr ColPercent

                    mov     eax, [RedComponent]
                    movzx   cx,  ColPercent.rgbRed      ; red percentage
                    invoke  GetPercentComponent, eax, cx
                    and     eax, [RedComponent]
                    mov     [SpecCol], eax

                    mov     eax, [GreenComponent]
                    movzx   cx,  ColPercent.rgbGreen    ; green percentage
                    invoke  GetPercentComponent, eax, cx
                    and     eax, [GreenComponent]
                    or      [SpecCol], eax

                    mov     eax, [BlueComponent]
                    movzx   cx,  ColPercent.rgbBlue     ; blue percentage
                    invoke  GetPercentComponent, eax, cx
                    and     eax, [BlueComponent]
                    or      eax, [SpecCol]

                    mov     ecx, PaletteEntry
                    mov     [ddULAplusPalette+ecx*4], eax
                    ret

SetULAplusPaletteEntry  endp

MapAttr2RGBPercent  proc    uses        esi edi ebx,
                            Attr:       BYTE,
                            lpRGBQuad : DWORD

                    mov     ebx, lpRGBQuad

                  ; Bits 0-1: Blue intensity.
                  ; Bits 2-4: Red intensity.
                  ; Bits 5-7: Green intensity.

                    mov     al, Attr
                    and     al, 00011100b
                    shr     al, 2
                    invoke  Map_hmlhmlml, al
                    invoke  GetColourAsPercent, al      ; R (0-255)
                    mov     [ebx].RGBQUAD.rgbRed, al

                    mov     al, Attr
                    and     al, 11100000b
                    shr     al, 5
                    invoke  Map_hmlhmlml, al
                    invoke  GetColourAsPercent, al      ; G (0-255)
                    mov     [ebx].RGBQUAD.rgbGreen, al

                  ; The low bit is duplicated (Bb becomes Bbb)
                    mov     al, Attr
                    and     al, 00000011b
                    mov     cl, al
                    and     cl, 1
                    shl     al, 1
                    or      al, cl
                    invoke  Map_hmlhmlml, al
                    invoke  GetColourAsPercent, al      ; B (0-255)
                    mov     [ebx].RGBQUAD.rgbBlue, al
                    ret

MapAttr2RGBPercent  endp

Map_hmlhmlml        proc    hml:    BYTE

                    mov     cl, hml
                    and     cl, 7

                    mov     al, cl
                    shl     al, 5       ; hml-----

                    mov     ah, cl
                    shl     ah, 2
                    or      al, ah      ; hmlhml--

                    and     cl, 3
                    or      al, cl      ; hmlhmlml
                    ret

Map_hmlhmlml        endp



