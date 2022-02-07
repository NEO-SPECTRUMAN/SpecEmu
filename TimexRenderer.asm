
            ASSUME  ESI: PTR SpectrumGfx

NEXTSCANLINEADDR    macro
                    mov     edi, [esi].TargetScanlineAddr
                    add     edi, DIBWidth
                    mov     [esi].TargetScanlineAddr, edi
                    endm

TimexPrepTopBorder:
            mov     [esi].ScreenVector, OFFSET TC_DrawTopBorder
            mov     [esi].UDCnt, 40

Align 16
TC_DrawTopBorder:
            mov     eax, [esi].TimexBorderColour

TC_DrawTopBorder_1:
            add     [esi].WaitTState, 4

            cmp     eax, [edi]
            jne     TC_DTB_Changed
            cmp     eax, [edi+4]
            jne     TC_DTB_Changed
            cmp     eax, [edi+8]
            jne     TC_DTB_Changed
            cmp     eax, [edi+12]
            jne     TC_DTB_Changed

            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_NextTopBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawTopBorder_1
            ret

TC_DTB_Changed:
            mov     [esi].ScreenVector, OFFSET TC_DrawTopBorder_Write
            mov     byte ptr [ebp], 1
            mov     [esi].FrameChanged, TRUE
            jmp     TC_DTB_Write

Align 16
TC_DrawTopBorder_Write:
            mov     eax, [esi].TimexBorderColour

TC_DrawTopBorder_2:
            add     [esi].WaitTState, 4

TC_DTB_Write:
            mov     [edi],    eax   ; write 16 border bytes
            mov     [edi+4],  eax
            mov     [edi+8],  eax
            mov     [edi+12], eax

            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_NextTopBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawTopBorder_2
            ret

Align 4
TC_NextTopBorderLine:
            NEXTSCANLINEADDR
            mov     eax, [esi].ScanTState
            add     eax, MACHINE.ScanlineCycles
            mov     [esi].ScanTState, eax
            mov     [esi].WaitTState, eax

            add     ebp, 3

            dec     [esi].TopBorderCnt
            jz      TC_PrepLeftBorder      ; top border finished
            mov     [esi].ScreenVector, OFFSET TimexPrepTopBorder
            ret

; start actual screen area
Align 4
TC_PrepLeftBorder:
            mov     [esi].ScreenVector, OFFSET TC_DrawLeftBorder
            mov     [esi].UDCnt, 4
            ret

Align 16
TC_DrawLeftBorder:
            mov     eax, [esi].TimexBorderColour

TC_DrawLeftBorder_1:
            add     [esi].WaitTState, 4
            .if     (eax != [edi]) || (eax != [edi+4]) || (eax != [edi+8]) || (eax != [edi+12])
                    mov     [edi],    eax   ; write 16 border bytes
                    mov     [edi+4],  eax
                    mov     [edi+8],  eax
                    mov     [edi+12], eax
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_PrepDisplayLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawLeftBorder_1
            ret

Align 4
TC_PrepDisplayLine:
            inc     ebp

            sub     [esi].WaitTState, 4

            mov     [esi].UDCnt, 16
            mov     [esi].FetchCycle, 0

            mov     [esi].ScreenVector, OFFSET TC_DrawDisplayLine

            ; prepare display/attr offsets for this scanline
            mov     eax, [DisplayTablePtr]
            mov     ecx, [eax]
            mov     eax, [eax+4]
            add     [DisplayTablePtr], 8
            mov     [esi].DisplayOffset, ecx
            mov     [esi].AttrOffset, eax
            ret

FETCHVIDEOMEM   macro
                .if     [esi].DoSnow == TRUE
                        and     eax, 0FFFFFF80h
                        mov     cl, z80registers.r
                        and     cl, 7Fh
                        or      al, cl
                .endif
                add     eax, [esi].zxDisplayOrg
                mov     al, [eax]
                endm

Align 16
TC_DrawDisplayLine:
            switch  [esi].FetchCycle
                    add     [esi].FetchCycle, 1
                    add     [esi].WaitTState, 1

                    FETCHCYCLEOFFSET = 2
                    FETCHCYCLEOFFSET = FETCHCYCLEOFFSET - 1 ; safe to assume that the ULA address bus is loaded one cycle before sampling the data bus?

                    case    FETCHCYCLEOFFSET
                            switch  Timex_Screen_Mode
                                    case    1
                                            ; screen 1
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].DisplayByte, al
                                    .else
                                            ; screen 0
                                            mov     eax, [esi].DisplayOffset
                                            FETCHVIDEOMEM
                                            mov     [esi].DisplayByte, al
                            endsw

                    case    FETCHCYCLEOFFSET+1
                            switch  Timex_Screen_Mode
                                    case    1
                                            ; screen 1
                                            mov     eax, [esi].AttrOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    case    2
                                            ; hi-colour
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    case    6
                                            ; hi-res
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    .else
                                            ; screen 0
                                            mov     eax, [esi].AttrOffset
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                            endsw

                    case    FETCHCYCLEOFFSET+2
                            switch  Timex_Screen_Mode
                                    case    1
                                            ; screen 1
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].DisplayByte, al
                                    .else
                                            ; screen 0
                                            mov     eax, [esi].DisplayOffset
                                            FETCHVIDEOMEM
                                            mov     [esi].DisplayByte, al
                            endsw

                    case    FETCHCYCLEOFFSET+3
                            switch  Timex_Screen_Mode
                                    case    1
                                            ; screen 1
                                            mov     eax, [esi].AttrOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    case    2
                                            ; hi-colour
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    case    6
                                            ; hi-res
                                            mov     eax, [esi].DisplayOffset
                                            add     eax, 2000h
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                                    .else
                                            ; screen 0
                                            mov     eax, [esi].AttrOffset
                                            FETCHVIDEOMEM
                                            mov     [esi].AttrByte, al
                                            call    Render_Timex_Character
                            endsw

                    case    7
                            mov     [esi].FetchCycle, 0
                            dec     [esi].UDCnt
                            jz      TC_PrepRightBorder
            endsw

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawDisplayLine
            ret


Align 4
TC_PrepRightBorder:
            inc     ebp

            add     [esi].WaitTState, 4

            mov     [esi].ScreenVector, OFFSET TC_DrawRightBorder
            mov     [esi].UDCnt, 4
            ret

Align 16
TC_DrawRightBorder:
            mov     eax, [esi].TimexBorderColour

TC_DrawRightBorder_1:
            add     [esi].WaitTState, 4
            .if     (eax != [edi]) || (eax != [edi+4]) || (eax != [edi+8]) || (eax != [edi+12])
                    mov     [edi],    eax   ; write 16 border bytes
                    mov     [edi+4],  eax
                    mov     [edi+8],  eax
                    mov     [edi+12], eax
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_PrepNextDisplayLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawRightBorder_1
            ret

Align 4
TC_PrepNextDisplayLine:
            NEXTSCANLINEADDR
            inc     [esi].CurrDisplayLine
            inc     ebp

            mov     edx, [esi].ScanTState
            add     edx, MACHINE.ScanlineCycles
            mov     [esi].ScanTState, edx
            mov     [esi].WaitTState, edx

            cmp     [esi].CurrDisplayLine, 192
            jnc     TC_PrepBottomBorder

            mov     [esi].ScreenVector, OFFSET TC_PrepLeftBorder
            ret

Align 4
TC_PrepBottomBorder:
            mov     [esi].ScreenVector, OFFSET TC_DrawBottomBorder
            mov     [esi].UDCnt, 40
            ret

Align 16
TC_DrawBottomBorder:
            mov     eax, [esi].TimexBorderColour

TC_DrawBottomBorder_1:
            add     [esi].WaitTState, 4

            cmp     eax, [edi]
            jne     TC_DBB_Changed
            cmp     eax, [edi+4]
            jne     TC_DBB_Changed
            cmp     eax, [edi+8]
            jne     TC_DBB_Changed
            cmp     eax, [edi+12]
            jne     TC_DBB_Changed

            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_NextBottomBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawBottomBorder_1
            ret

TC_DBB_Changed:
            mov     [esi].ScreenVector, OFFSET TC_DrawBottomBorder_Write
            mov     byte ptr [ebp], 1
            mov     [esi].FrameChanged, TRUE
            jmp     TC_DBB_Write

Align 16
TC_DrawBottomBorder_Write:
            mov     eax, [esi].TimexBorderColour

TC_DrawBottomBorder_2:
            add     [esi].WaitTState, 4

TC_DBB_Write:
            mov     [edi],    eax   ; write 16 border bytes
            mov     [edi+4],  eax
            mov     [edi+8],  eax
            mov     [edi+12], eax

            add     edi, 16
            dec     [esi].UDCnt
            jz      TC_NextBottomBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     TC_DrawBottomBorder_2
            ret

Align 4
TC_NextBottomBorderLine:
            NEXTSCANLINEADDR
            mov     eax, [esi].ScanTState
            add     eax, MACHINE.ScanlineCycles
            mov     [esi].ScanTState, eax
            mov     [esi].WaitTState, eax

            add     ebp, 3

            dec     [esi].BottomBorderCnt
            jz      TC_VerticalRetrace ; bottom border finished
            mov     [esi].ScreenVector, OFFSET TC_PrepBottomBorder
            ret

Align 4
TC_VerticalRetrace:
            mov     [esi].ScreenVector, OFFSET UScrExit
            mov     [esi].WaitTState, 180000
            ret


Render_Timex_Character:
            mov     al, Timex_Screen_Mode
            cmp     al, 6
            je      Render_Timex_HiRes

            .if     [esi].ULA64_Active == TRUE

                  ; temp fix for ULA+ colour cycling
                    or      byte ptr [ebp], 1 + 128     ; set to use ULA+ palette in 'ColourDump' proc
                    mov     [esi].FrameChanged, TRUE
                  ; end temp fix for ULA+ colour cycling

                    movzx   eax, [esi].AttrByte                 ; eax = attribute byte
                    movzx   ecx, [esi].DisplayByte              ; ecx = display byte

                    shl     eax, 11                             ; * 2048 (256 entries per colour * 8 bytes/entry)
                    lea     eax, [eax+ecx*8]                    ; 8 bytes/entry
                    add     eax, [esi].ptrULA64ColourTable      ; offset into DirectDraw colour mapping table

                    align   16
                    SETLOOP 8
                            movzx   ecx, byte ptr [eax]
                            mov     dl, [ULAplusPalette+ecx]
                            mov     [edi],   dl
                            mov     [edi+1], dl
                            add     eax, 1
                            add     edi, 2
                    ENDLOOP

                    add     [esi].DisplayOffset, 1
                    add     [esi].AttrOffset, 1
                    ret
            .endif

            movzx   eax, [esi].AttrByte                 ; eax = attribute byte
            movzx   ecx, [esi].DisplayByte              ; ecx = display byte

            test    eax, 128
            je      @F                                  ; flash bit clear?

            and     eax, 127                            ; clear Flash bit

            xor     cl, [esi].FlashInverterByte

@@:         shl     eax, 12                             ; * 4096 (256 entries per colour * 16 bytes/entry)
            shl     ecx, 4                              ; 16 bytes/entry
            lea     eax, [eax+ecx]
            add     eax, [esi].ptrTimexColourTable      ; offset into DirectDraw colour mapping table

            mov     ecx, [eax]                          ; pick up 8 pixel colour values
            mov     edx, [eax+4]
            .if     ecx != [edi]
                    mov     [edi], ecx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            .if     edx != [edi+4]
                    mov     [edi+4], edx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add     edi, 8

            mov     ecx, [eax+8]                        ; pick up next 8 pixel colour values
            mov     edx, [eax+12]
            .if     ecx != [edi]
                    mov     [edi], ecx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            .if     edx != [edi+4]
                    mov     [edi+4], edx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add     edi, 8

            add     [esi].DisplayOffset, 1
            add     [esi].AttrOffset, 1
            ret

Render_Timex_HiRes:
            movzx   ecx, [esi].DisplayByte              ; ecx = display byte
            movzx   eax, Timex_Screen_Colour            ; border/paper colour
            call    RenderTimexChar                     ; render as standard width Spectrum character

            movzx   ecx, [esi].AttrByte                 ; eax = 2nd display byte in hi-res mode
            movzx   eax, Timex_Screen_Colour            ; border/paper colour
            call    RenderTimexChar                     ; render as standard width Spectrum character

            sub     [esi].DisplayOffset, 1              ; RenderTimexChar has incremented these twice so decrement by 1
            sub     [esi].AttrOffset, 1

            ret

RenderTimexChar:
            shl     eax, 11                             ; * 2048 (256 entries per colour * 8 bytes/entry)
            lea     eax, [eax+ecx*8]                    ; 8 bytes/entry
            add     eax, [esi].ptrSpecColourTable       ; offset into DirectDraw colour mapping table

            mov     ecx, [eax]                          ; pick up 8 pixel colour values
            mov     edx, [eax+4]

            .if     ecx != [edi]
                    mov     [edi], ecx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif

            .if     edx != [edi+4]
                    mov     [edi+4], edx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif

            add     edi, 8

            add     [esi].DisplayOffset, 1
            add     [esi].AttrOffset, 1
            ret

            ASSUME  ESI:NOTHING


