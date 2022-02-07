
.data?
align 4
ChooseColorStruct   CHOOSECOLOR <>
CustomColours       COLORREF    16  DUP(?)  ; 16 custom colours
CustomColoursBak    COLORREF    16  DUP(?)  ; backup of 16 custom colours in case of user cancel

CustomPaletteFilename   BYTE MAX_PATH   dup(?)

.data
MAXPALETTES         equ 4

PALETTE_SPECTRUM    equ 0
PALETTE_GREENSCREEN equ 1
PALETTE_GRAYSCALE   equ 2
PALETTE_CUSTOM      equ 3

; default custom palette entries for color control
InitCustomPalette   db  0,0,0,0,19,33,66,0,111,13,2,0,150,24,124,0
                    db  37,99,27,0,20,99,99,0,150,143,29,0,218,218,214,0
                    db  0,0,0,0,52,86,165,0,192,55,10,0,213,32,186,0
                    db  38,182,35,0,57,198,190,0,213,217,51,0,255,255,255,0


align 4
DDPalettePtrs       dd  DDPalette_RGB       ; standard Spectrum colours
                    dd  DDPalette_AGS       ; Amstrad Green-Screen Monitor
                    dd  DDPalette_GS        ; grayscale
                    dd  DDPalette_Custom

BR0                 equ     70
BR1                 equ     80
BR2                 equ     90
BR3                 equ     100

;b0                  equ     0
;b1                  equ     1
;b2                  equ     2
;b3                  equ     8   ; for stripes.szx

b0                  equ     0
b1                  equ     0
b2                  equ     0
b3                  equ     0

                  ; standard Spectrum display colours
DDPalette_RGB       db  b0, b0, b0
                    db  b0, b0, BR0
                    db  BR0, b0, b0
                    db  BR0, b0, BR0
                    db  b0, BR0, b0
                    db  b0, BR0, BR0
                    db  BR0, BR0, b0
                    db  BR0, BR0, BR0

                    db  b1, b1, b1
                    db  b1, b1, BR1
                    db  BR1, b1, b1
                    db  BR1, b1, BR1
                    db  b1, BR1, b1
                    db  b1, BR1, BR0
                    db  BR1, BR1, b1
                    db  BR1, BR1, BR1

                    db  b2, b2, b2
                    db  b2, b2, BR2
                    db  BR2, b2, b2
                    db  BR2, b2, BR2
                    db  b2, BR2, b2
                    db  b2, BR2, BR2
                    db  BR2, BR2, b2
                    db  BR2, BR2, BR2

                    db  b3, b3, b3
                    db  b3, b3, BR3
                    db  BR3, b3, b3
                    db  BR3, b3, BR3
                    db  b3, BR3, b3
                    db  b3, BR3, BR3
                    db  BR3, BR3, b3
                    db  BR3, BR3, BR3


                  ; Amstrad Green-Screen Monitor
DDPalette_AGS       db  0, (BR0/8)*0, 0
                    db  0, (BR0/8)*1, 0
                    db  0, (BR0/8)*2, 0
                    db  0, (BR0/8)*3, 0
                    db  0, (BR0/8)*4, 0
                    db  0, (BR0/8)*5, 0
                    db  0, (BR0/8)*6, 0
                    db  0, (BR0/8)*7, 0

                    db  0, (BR1/8)*0, 0
                    db  0, (BR1/8)*1, 0
                    db  0, (BR1/8)*2, 0
                    db  0, (BR1/8)*3, 0
                    db  0, (BR1/8)*4, 0
                    db  0, (BR1/8)*5, 0
                    db  0, (BR1/8)*6, 0
                    db  0, (BR1/8)*7, 0

                    db  0, (BR2/8)*0, 0
                    db  0, (BR2/8)*1, 0
                    db  0, (BR2/8)*2, 0
                    db  0, (BR2/8)*3, 0
                    db  0, (BR2/8)*4, 0
                    db  0, (BR2/8)*5, 0
                    db  0, (BR2/8)*6, 0
                    db  0, (BR2/8)*7, 0

                    db  0, (BR3/8)*0, 0
                    db  0, (BR3/8)*1, 0
                    db  0, (BR3/8)*2, 0
                    db  0, (BR3/8)*3, 0
                    db  0, (BR3/8)*4, 0
                    db  0, (BR3/8)*5, 0
                    db  0, (BR3/8)*6, 0
                    db  0, (BR3/8)*7, 0


                    ; grayscale
DDPalette_GS        db  (BR0/8)*0, (BR0/8)*0, (BR0/8)*0
                    db  (BR0/8)*1, (BR0/8)*1, (BR0/8)*1
                    db  (BR0/8)*2, (BR0/8)*2, (BR0/8)*2
                    db  (BR0/8)*3, (BR0/8)*3, (BR0/8)*3
                    db  (BR0/8)*4, (BR0/8)*4, (BR0/8)*4
                    db  (BR0/8)*5, (BR0/8)*5, (BR0/8)*5
                    db  (BR0/8)*6, (BR0/8)*6, (BR0/8)*6
                    db  (BR0/8)*7, (BR0/8)*7, (BR0/8)*7

                    db  (BR1/8)*0, (BR1/8)*0, (BR1/8)*0
                    db  (BR1/8)*1, (BR1/8)*1, (BR1/8)*1
                    db  (BR1/8)*2, (BR1/8)*2, (BR1/8)*2
                    db  (BR1/8)*3, (BR1/8)*3, (BR1/8)*3
                    db  (BR1/8)*4, (BR1/8)*4, (BR1/8)*4
                    db  (BR1/8)*5, (BR1/8)*5, (BR1/8)*5
                    db  (BR1/8)*6, (BR1/8)*6, (BR1/8)*6
                    db  (BR1/8)*7, (BR1/8)*7, (BR1/8)*7

                    db  (BR2/8)*0, (BR2/8)*0, (BR2/8)*0
                    db  (BR2/8)*1, (BR2/8)*1, (BR2/8)*1
                    db  (BR2/8)*2, (BR2/8)*2, (BR2/8)*2
                    db  (BR2/8)*3, (BR2/8)*3, (BR2/8)*3
                    db  (BR2/8)*4, (BR2/8)*4, (BR2/8)*4
                    db  (BR2/8)*5, (BR2/8)*5, (BR2/8)*5
                    db  (BR2/8)*6, (BR2/8)*6, (BR2/8)*6
                    db  (BR2/8)*7, (BR2/8)*7, (BR2/8)*7

                    db  (BR3/8)*0, (BR3/8)*0, (BR3/8)*0
                    db  (BR3/8)*1, (BR3/8)*1, (BR3/8)*1
                    db  (BR3/8)*2, (BR3/8)*2, (BR3/8)*2
                    db  (BR3/8)*3, (BR3/8)*3, (BR3/8)*3
                    db  (BR3/8)*4, (BR3/8)*4, (BR3/8)*4
                    db  (BR3/8)*5, (BR3/8)*5, (BR3/8)*5
                    db  (BR3/8)*6, (BR3/8)*6, (BR3/8)*6
                    db  (BR3/8)*7, (BR3/8)*7, (BR3/8)*7


                  ; custom Spectrum display colours (built from the default palette or "custompalette.pal")
DDPalette_Custom    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0

                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0

                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0

                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0
                    db  0, 0, 0

PaletteFilename     db  "custompalette.pal", 0

.code


LoadCustomPalettes  proc    uses esi edi ecx

                    local   PaletteFH

                    ; initialise custom palette filename
                    invoke  GetAppPath, ADDR CustomPaletteFilename
                    lea     edi, CustomPaletteFilename
                @@: mov     al, [edi]
                    inc     edi
                    or      al, al
                    jnz     @B

                    dec     edi
                    lea     esi, PaletteFilename
                    mov     ecx, sizeof PaletteFilename
                    rep     movsb

                    ; initialise default custom palette
                    lea     esi, InitCustomPalette
                    lea     edi, CustomColours
                    mov     ecx, sizeof CustomColours
                    rep     movsb

                    invoke  filesize, ADDR CustomPaletteFilename

                    .if     eax == sizeof CustomColours ; sizeof CustomPalette file

                            invoke CreateFile,  ADDR CustomPaletteFilename,
                                                GENERIC_READ,
                                                FILE_SHARE_READ, NULL,
                                                OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                            mov     PaletteFH, eax

                            .if     PaletteFH != INVALID_HANDLE_VALUE
                                    invoke ReadFile, PaletteFH,
                                                     ADDR CustomColours, sizeof CustomColours,
                                                     ADDR BytesMoved, NULL

                                    invoke  CloseHandle, PaletteFH
                            .endif
                    .endif

                    invoke  SetCustomPalette    ; set our new custom palette
                    ret

LoadCustomPalettes  endp

SaveCustomPalettes  proc

                    local   PaletteFH

                    invoke  CreateFile, ADDR CustomPaletteFilename,
                                        GENERIC_WRITE,
                                        FILE_SHARE_WRITE, NULL,
                                        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                    mov     PaletteFH, eax

                    .if     PaletteFH != INVALID_HANDLE_VALUE
                            invoke  WriteFile,  PaletteFH,
                                                ADDR CustomColours, sizeof CustomColours,
                                                ADDR BytesSaved, NULL

                            invoke  CloseHandle, PaletteFH
                    .endif

                    ret

SaveCustomPalettes  endp

SetSpectrumPalette  proc    uses    esi edi ebx,
                            PalNum: DWORD

                    local   SpecCol:DWORD

                    mov     eax, PalNum
                    mov     UserPalette, eax

                    mov     esi, [DDPalettePtrs+eax*4]      ; esi points to selected palette entries
                    lea     edi, ddSurfacePalette+(CLR_SPECBASE*4)

                    SETLOOP 32  ; 32 Spectrum display colours

                        mov     eax, [RedComponent]
                        movzx   bx,  byte ptr [esi]     ; red percentage
                        inc     esi
                        invoke  GetPercentComponent, eax, bx
                        and     eax, [RedComponent]
                        mov     [SpecCol], eax

                        mov     eax, [GreenComponent]
                        movzx   bx,  byte ptr [esi]     ; green percentage
                        inc     esi
                        invoke  GetPercentComponent, eax, bx
                        and     eax, [GreenComponent]
                        or      [SpecCol], eax

                        mov     eax, [BlueComponent]
                        movzx   bx,  byte ptr [esi]     ; blue percentage
                        inc     esi
                        invoke  GetPercentComponent, eax, bx
                        and     eax, [BlueComponent]
                        or      eax, [SpecCol]

                        stosd

                    ENDLOOP
                    ret

SetSpectrumPalette  endp

EditCustomPalette   proc    uses esi edi ecx

                    ASSUME  ESI: PTR CHOOSECOLOR
                    lea     esi, ChooseColorStruct
                    mov     [esi].lStructSize, sizeof CHOOSECOLOR
                    m2m     [esi].hwndOwner, hWnd
                    mov     [esi].hInstance, NULL
                    mov     [esi].rgbResult, 0      ; to do!
                    mov     [esi].lpCustColors, OFFSET CustomColours
                    mov     [esi].Flags, CC_FULLOPEN
                    ASSUME  ESI: NOTHING

                    ; backup custom colours
                    lea     esi, CustomColours
                    lea     edi, CustomColoursBak
                    mov     ecx, sizeof CustomColours
                    rep     movsb

                    invoke  ChooseColor, ADDR ChooseColorStruct
                    .if     eax != NULL
                            ; if OK then create and enable the new custom palette
                            invoke  SetCustomPalette    ; set our new custom palette
                            invoke  SetSpectrumPalette, PALETTE_CUSTOM
                            invoke  SetDirtyLines
                            UPDATEWINDOW
                    .else
                            ; else restore the old custom colours
                            lea     esi, CustomColoursBak
                            lea     edi, CustomColours
                            mov     ecx, sizeof CustomColours
                            rep     movsb
                    .endif
                    ret

EditCustomPalette   endp


SetCustomPalette    proc    uses esi edi ebx ecx

                    lea     esi, CustomColours
                    lea     edi, DDPalette_Custom   ; address BRIGHT 0 (and half-brighter) table

                    SETLOOP 2

                            SETLOOP 8
                                ; get Red component
                                invoke  GetColourAsPercent, byte ptr [esi]  ; R (0-255)
                                inc     esi
                                mov     [edi], al           ; store R percent
                                mov     [edi+24], al        ; and into the half-brighter table
                                inc     edi

                                ; get Green component
                                invoke  GetColourAsPercent, byte ptr [esi]  ; G (0-255)
                                inc     esi
                                mov     [edi], al           ; store G percent
                                mov     [edi+24], al        ; and into the half-brighter table
                                inc     edi

                                ; get Blue component
                                invoke  GetColourAsPercent, byte ptr [esi]  ; B (0-255)
                                inc     esi
                                mov     [edi], al           ; store B percent
                                mov     [edi+24], al        ; and into the half-brighter table
                                inc     edi

                                inc     esi                 ; skip to the next COLORREF entry
                            ENDLOOP

                            add     edi, 24                 ; advance to address BRIGHT 1 (and half-brighter) table
                    ENDLOOP
                    ret

SetCustomPalette    endp

; given a colour value (0-255), return that as a percentage of the range (100% being 255)
; (Colour / 255) × 100, or...
; (Colour * 100) / 255
GetColourAsPercent  proc    Colour: BYTE

;                    movzx   eax, Colour
;                    invoke  MulDiv, eax, 100, 255
;                    ret

                    movzx   eax, Colour
                    mov     cx, 100
                    mul     cx
                    invoke  IntDiv, eax, 255
                    ret

GetColourAsPercent  endp

GetPercentComponent proc    uses    ebx ecx,
                            Colour: DWORD,
                            Percent:WORD

                    mov     eax, Colour

                    .if     eax != 0
                            xor     cl, cl    ; initialise our bit shift counter

                            ; count the number of shifts required until our colour bits sit in the lowest bits
                            .while  TRUE
                                    test    eax, 1
                                    .break  .if !ZERO?
                                    inc     cl
                                    shr     eax, 1
                            .endw

                            movzx   ebx, Percent
                            invoke  GetPercent, eax, ebx    ; eax = our new colour intensity percentage

                            shl     eax, cl     ; shift our colour bits back into position
                    .endif
                    ret

GetPercentComponent endp


