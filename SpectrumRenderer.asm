
            assume  esi: ptr SpectrumGfx

NEXTSCANLINEADDR    macro
                    mov     edi, [esi].TargetScanlineAddr
                    add     edi, DIBWidth
                    mov     [esi].TargetScanlineAddr, edi
                    endm

SP_GETBORDERCOLOUR  macro   reg32:REQ
                    cmp     [esi].ULA64_Active, TRUE
                    cmove   reg32, [esi].ULAPlusBorderColour
                    cmovne  reg32, [esi].BorderColour
                    endm

SP_ULAPLUS_FLAG     macro
                    .if     [esi].ULA64_Active == TRUE
                            mov     byte ptr [ebp], 128
                    .endif
                    endm

align 16
SpectrumPrepTopBorder:  SP_ULAPLUS_FLAG

                        mov     [esi].ScreenVector, offset SP_DrawTopBorder
                        mov     [esi].UDCnt, 40

SP_DrawTopBorder:       SP_GETBORDERCOLOUR  eax

SP_DrawTopBorder_1:     add     [esi].WaitTState, 4

                        cmp     eax, [edi]
                        jne     SP_DTB_Changed
                        cmp     eax, [edi+4]
                        jne     SP_DTB_Changed

                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_NextTopBorderLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawTopBorder_1
                        ret

SP_DTB_Changed:         mov     [esi].ScreenVector, offset SP_DrawTopBorder_Write
                        or      byte ptr [ebp], 1
                        mov     [esi].FrameChanged, TRUE
                        jmp     SP_DTB_Write

SP_DrawTopBorder_Write: SP_GETBORDERCOLOUR  eax

SP_DrawTopBorder_2:     add     [esi].WaitTState, 4

SP_DTB_Write:           mov     [edi],   eax   ; write 8 border bytes
                        mov     [edi+4], eax

                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_NextTopBorderLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawTopBorder_2
                        ret

SP_NextTopBorderLine:   NEXTSCANLINEADDR
                        mov     eax, [esi].ScanTState
                        add     eax, MACHINE.ScanlineCycles
                        mov     [esi].ScanTState, eax
                        mov     [esi].WaitTState, eax

                        add     ebp, 3

                        sub     [esi].TopBorderCnt, 1
                        jz      SP_PrepLeftBorder      ; top border finished
                        mov     [esi].ScreenVector, offset SpectrumPrepTopBorder
                        ret

; start actual screen area
SP_PrepLeftBorder:      SP_ULAPLUS_FLAG
                        mov     [esi].ScreenVector, offset SP_DrawLeftBorder
                        mov     [esi].UDCnt, 4
                        ret

SP_DrawLeftBorder:      SP_GETBORDERCOLOUR  eax

SP_DrawLeftBorder_1:    add     [esi].WaitTState, 4
                        .if     (eax != [edi]) || (eax != [edi+4])
                                mov     [edi],   eax   ; write 8 border bytes
                                mov     [edi+4], eax
                                or      byte ptr [ebp], 1
                                mov     [esi].FrameChanged, TRUE
                        .endif
                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_PrepDisplayLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawLeftBorder_1
                        ret

SP_PrepDisplayLine:     inc     ebp
                        SP_ULAPLUS_FLAG

                        sub     [esi].WaitTState, 4     ; back to 14336 for the 48K machine

                        mov     [esi].UDCnt, 16
                        mov     [esi].FetchCycle, 0

                        mov     [esi].IsPaper, TRUE
                        mov     [esi].PrevAttrByte, 0

                        mov     [esi].ScreenVector, offset SP_DrawDisplayLine

                        ; prepare display/attr offsets for this scanline
                        mov     eax, [DisplayTablePtr]
                        add     [DisplayTablePtr], 8
                        mov     ecx, [eax]
                        mov     eax, [eax+4]
                        mov     [esi].DisplayOffset, ecx
                        mov     [esi].AttrOffset, eax
                        ret


FETCHVIDEOMEM           macro
                        add     eax, [esi].zxDisplayOrg
                        mov     al, [eax]
                        endm

FETCHDISPLAYMEM_SNOW    macro
                        call    fetch_display_mem_snow
                        endm

FETCHATTRIBUTEMEM_SNOW  macro
                        call    fetch_attribute_mem_snow
                        endm

;http://www.zxdesign.info/dynamicRam3.shtml

align 16
fetch_display_mem_snow  proc
                        .if     [esi].DoSnow == FALSE   ; DoSnow can only be true if I addresses contended memory and within M1 fetch cycles in the core (M1_Fetch)
                                add     eax, [esi].zxDisplayOrg
                                mov     al, [eax]
                                ret
                        .endif

                        and     eax, 0FFFFFF00h         ; A7=0
                        movzx   ecx, z80registers.r
                        and     ecx, 7Fh                ; A0-A6=R
                        or      eax, ecx

                        add     eax, [esi].zxDisplayOrg
                        mov     al, [eax]
                        ret
fetch_display_mem_snow  endp

align 16
fetch_attribute_mem_snow proc
                        .if     [esi].DoSnow == FALSE   ; DoSnow can only be true if I addresses contended memory and within M1 fetch cycles in the core (M1_Fetch)
                                add     eax, [esi].zxDisplayOrg
                                mov     al, [eax]
                                ret
                        .endif

                        and     eax, 0FFFFFF00h         ; A7=0
                        movzx   ecx, z80registers.r
                        and     ecx, 7Fh                ; A0-A6=R
                        or      eax, ecx

                        add     eax, [esi].zxDisplayOrg
                        mov     al, [eax]
                        ret
fetch_attribute_mem_snow endp

SP_LOOPBACK             macro
                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawDisplayLine
                        ret
                        endm

align 16
SP_DrawDisplayLine:     movzx   eax, [esi].FetchCycle
                        mov     [esi].float_byte, 255

                        add     [esi].FetchCycle, 1
                        add     [esi].WaitTState, 1

                        jmp     [SP_DrawJump+eax*4]

                        ; safe to assume that the ULA address bus is loaded one cycle before sampling the data bus?
                        ; confirmed fetch cycles in snow test program

                        ; see 14838 in test prog
                        ; and 15510

                        ; If an instruction fetch state T3 and T4 occur while the ULA is between fetching bytes 2 and 3, and the refresh address on the bus is between 0x4000 and 0x7FFF, then as described above, the ULA dynamic memory handler will force RAS low.
                        ; Thus it cannot rise as it normally would during the second CAS assertion, but instead remains low as the next row address is placed on the bus, and into the next CAS assertion. The upshot is that the row address of the second byte pair of the four byte fetch will not get latched into the RAM.

    SP_Draw_D1:         mov     eax, [esi].DisplayOffset
                        FETCHDISPLAYMEM_SNOW
                        mov     [esi].DisplayByte, al
                        mov     [esi].float_byte, al
                        mov     [esi].plus3_float_byte, al
                        SP_LOOPBACK

    SP_Draw_A1:         mov     eax, [esi].AttrOffset
                        FETCHATTRIBUTEMEM_SNOW
                        mov     [esi].AttrByte, al
                        mov     [esi].float_byte, al
                        mov     [esi].plus3_float_byte, al

                        call    Render_Spectrum_Character
                        SP_LOOPBACK

    SP_Draw_D2:         mov     eax, [esi].DisplayOffset
                        FETCHDISPLAYMEM_SNOW
                        mov     [esi].DisplayByte, al
                        mov     [esi].float_byte, al
                        mov     [esi].plus3_float_byte, al
                        SP_LOOPBACK

    SP_Draw_A2:         mov     eax, [esi].AttrOffset
                        FETCHATTRIBUTEMEM_SNOW
                        mov     [esi].AttrByte, al
                        mov     [esi].float_byte, al
                        mov     [esi].plus3_float_byte, al

                        call    Render_Spectrum_Character
                        SP_LOOPBACK

    SP_Draw7:           mov     [esi].FetchCycle, 0
                        sub     [esi].UDCnt, 1
                        jz      SP_PrepRightBorder

    SP_DrawLoop:        SP_LOOPBACK


.data
align 16
SP_DrawJump             dd      SP_DrawLoop, SP_Draw_D1, SP_Draw_A1, SP_Draw_D2, SP_Draw_A2, SP_DrawLoop, SP_DrawLoop, SP_Draw7

.code
SP_PrepRightBorder:     inc     ebp
                        SP_ULAPLUS_FLAG

                        add     [esi].WaitTState, 4

                        mov     [esi].ScreenVector, offset SP_DrawRightBorder
                        mov     [esi].UDCnt, 4
                        ret

SP_DrawRightBorder:     SP_GETBORDERCOLOUR  eax

SP_DrawRightBorder_1:   add     [esi].WaitTState, 4
                        .if     (eax != [edi]) || (eax != [edi+4])
                                mov     [edi],   eax   ; write 8 border bytes
                                mov     [edi+4], eax
                                or      byte ptr [ebp], 1
                                mov     [esi].FrameChanged, TRUE
                        .endif
                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_PrepNextDisplayLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawRightBorder_1
                        ret

SP_PrepNextDisplayLine: NEXTSCANLINEADDR
                        inc     [esi].CurrDisplayLine
                        inc     ebp

                        mov     edx, [esi].ScanTState
                        add     edx, MACHINE.ScanlineCycles
                        mov     [esi].ScanTState, edx
                        mov     [esi].WaitTState, edx

                        cmp     [esi].CurrDisplayLine, 192
                        jnc     SP_PrepBottomBorder

                        mov     [esi].ScreenVector, offset SP_PrepLeftBorder
                        ret

SP_PrepBottomBorder:    SP_ULAPLUS_FLAG
                        mov     [esi].ScreenVector, offset SP_DrawBottomBorder
                        mov     [esi].UDCnt, 40
                        ret

SP_DrawBottomBorder:    SP_GETBORDERCOLOUR  eax

SP_DrawBottomBorder_1:  add     [esi].WaitTState, 4

                        cmp     eax, [edi]
                        jne     SP_DBB_Changed
                        cmp     eax, [edi+4]
                        jne     SP_DBB_Changed

                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_NextBottomBorderLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawBottomBorder_1
                        ret

SP_DBB_Changed:         mov     [esi].ScreenVector, offset SP_DrawBottomBorder_Write
                        or      byte ptr [ebp], 1
                        mov     [esi].FrameChanged, TRUE
                        jmp     SP_DBB_Write

SP_DrawBottomBorder_Write:SP_GETBORDERCOLOUR  eax

SP_DrawBottomBorder_2:  add     [esi].WaitTState, 4

SP_DBB_Write:           mov     [edi],   eax   ; write 8 border bytes
                        mov     [edi+4], eax

                        add     edi, 8
                        sub     [esi].UDCnt, 1
                        jz      SP_NextBottomBorderLine

                        cmp     ebx, [esi].WaitTState
                        jnc     SP_DrawBottomBorder_2
                        ret

SP_NextBottomBorderLine:NEXTSCANLINEADDR
                        mov     eax, [esi].ScanTState
                        add     eax, MACHINE.ScanlineCycles
                        mov     [esi].ScanTState, eax
                        mov     [esi].WaitTState, eax

                        add     ebp, 3

                        sub     [esi].BottomBorderCnt, 1
                        jz      SP_VerticalRetrace ; bottom border finished
                        mov     [esi].ScreenVector, offset SP_PrepBottomBorder
                        ret

SP_VerticalRetrace:     mov     [esi].ScreenVector, offset UScrExit
                        mov     [esi].WaitTState, 180000
                        ret

align 16
Render_Spectrum_Character:
            .if     [esi].ULA64_Active

                  ; temp fix for ULA+ colour cycling
                    or      byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
                  ; end temp fix for ULA+ colour cycling

                    movzx   eax, [esi].AttrByte                 ; eax = attribute byte
                    movzx   ecx, [esi].DisplayByte              ; ecx = display byte

                    shl     eax, 11                             ; * 2048 (256 entries per colour * 8 bytes/entry)
                    lea     eax, [eax+ecx*8]                    ; 8 bytes/entry
                    add     eax, [esi].ptrULA64ColourTable      ; offset into DirectDraw colour mapping table

;                    mov     ecx, [eax]                          ; pick up 8 pixel colour values
;                    mov     edx, [eax+4]

                    mov     dh, 8
                        @@: movzx   ecx, byte ptr [eax]
                            inc     eax
                            mov     dl, [ULAplusPalette+ecx]
                            mov     [edi], dl
                            inc     edi
                    dec     dh
                    jnz     @B

                    inc     [esi].DisplayOffset
                    inc     [esi].AttrOffset
                    ret
            .endif

            .if     ULA_Artifacts_Enabled && MACHINE.Has_ULAColourArtifacts

                    ; ULA artifacts on

                    movzx   eax, [esi].DisplayByte              ; eax = display byte
                    mov     cl,  [esi].AttrByte

                    test    cl, 128
                    .if     !ZERO? && ([esi].FrameCnt >= 16)
                            and     cl, 127                             ; clear Flash bit
                            xor     al, 255                             ; invert display byte
                    .endif

;We have 4 sets of 8 brightness colours (black to white), so 32 colours.
;
;For each pixel: Bright = bright bit * 16 (so using set 0 or 2 of bright cols)
;              : If transition is from ink to paper pixel then if new paper col >= last ink col && new paper !BLACK then Bright = Bright + 8 (using set 1 or 3 of bright cols)


        @@:         mov     ah, cl
                    shr     ah, 2
                    and     ah, 16  ; BRIGHT level

                    mov     dh, cl
                    and     dh, 7
                    add     dh, ah  ; INK colour

                    mov     dl, cl
                    shr     dl, 3
                    and     dl, 7
                    add     dl, ah  ; PAPER colour

                    mov     [esi].PixelCount, -1

align 16
                    SETLOOP 8
                            add     [esi].PixelCount, 1

                            shl     al, 1
                            .if     CARRY?
                                    ; ink pixel
                                    mov     ah, dh                  ; ink + 0/16 bright
                                    mov     [esi].IsPaper, FALSE

                            .else
                                    ; paper pixel
                                    mov     ah, dl                  ; paper + 0/16 bright

                                    .if     [esi].PixelCount == 0
                                            .if     ([esi].PrevAttrByte >= 128) && ([esi].AttrByte < 128)
                                                    .if     [esi].FrameCnt >= 16
                                                            ifc     (ah eq 0) || (ah eq 16) then mov ah, 24 else add ah, 8
                                                            jmp     RSC_WritePixel
                                                    .endif
                                            .endif
                                    .endif

                                    .if     ([esi].IsPaper == FALSE)
                                            ; transition from Ink to Paper pixel

                                            ; What I meant to say was that "it is only when a particular R, G or B colour bit is off for INK and on for PAPER".

                                            ; Given that there are three colour bits, then you get the effect across the colour range, but not as pronounced
                                            ; as when all RGB bits are on for PAPER (white) and off for INK (black).

                                            mov     cl, [esi].LastColour    ; last pixel colour (ink) + 0/16 for bright level
                                            mov     ch, dl                  ; new paper col to ch
                                            and     cl, 7                   ; last ink col: 0-7
                                            and     ch, 7                   ; paper col: 0-7
                                            sub     ch, cl                  ; ch = paper - last ink
                                            .if     !SIGN? && (ch > 0)      ; paper >= last ink && not black
                                                    add     ah, 8           ; add extra bright level
                                            .endif
                                    .endif
                                    mov     [esi].IsPaper, TRUE
                            .endif

                    RSC_WritePixel:
                            mov     [esi].LastColour, ah

                            add     ah, CLR_SPECBASE
                            .if     ah != [edi]
                                    mov     [edi], ah
                                    or      byte ptr [ebp], 1
                                    mov     [esi].FrameChanged, TRUE
                            .endif
                            add     edi, 1
                    ENDLOOP

                    mov     al, [esi].AttrByte
                    mov     [esi].PrevAttrByte, al
        
                    inc     [esi].DisplayOffset
                    inc     [esi].AttrOffset
                    ret

align 16
            .else
                    ; ULA artifacts off
                    movzx   eax, [esi].AttrByte                 ; eax = attribute byte
                    movzx   ecx, [esi].DisplayByte              ; ecx = display byte

                    test    eax, 128
                    je      @F                                  ; flash bit clear?

                    and     eax, 127                            ; clear Flash bit

                    xor     cl, [esi].FlashInverterByte

        @@:         shl     eax, 11                             ; * 2048 (256 entries per colour * 8 bytes/entry)
                    mov     edx, [esi].ptrSpecColourTable       ; offset into DirectDraw colour mapping table
                    lea     eax, [eax+ecx*8]                    ; 8 bytes/entry
                    add     eax, edx

                    mov     ecx, [eax]                          ; pick up 8 pixel colour values
                    mov     edx, [eax+4]

                    .if     (ecx != [edi]) || (edx != [edi+4])
                            mov     [edi],   ecx
                            mov     [edi+4], edx
                            or      byte ptr [ebp], 1
                            mov     [esi].FrameChanged, TRUE
                    .endif

                    add     edi, 8

                    inc     [esi].DisplayOffset
                    inc     [esi].AttrOffset
                    ret

            .endif
            ret

            ASSUME  ESI:NOTHING

