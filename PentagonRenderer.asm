
            ASSUME	ESI: PTR SpectrumGfx

PentagonPrepTopBorder:
            mov     [esi].ScreenVector, OFFSET PE_DrawTopBorder
            mov     [esi].UDCnt, 320/2

Align 16
PE_DrawTopBorder:
            mov     eax, [esi].BorderColour

PE_DrawTopBorder_1:
            inc     [esi].WaitTState

            cmp     ax, [edi]
            jne     PE_DTB_Changed

            add     edi, 2
            dec     [esi].UDCnt
            jz      PE_NextTopBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     PE_DrawTopBorder_1
            ret

PE_DTB_Changed:
            mov     [esi].ScreenVector, OFFSET PE_DrawTopBorder_Write
            mov     byte ptr [ebp], 1
            mov     [esi].FrameChanged, TRUE
            jmp     PE_DTB_Write

Align 16
PE_DrawTopBorder_Write:
            mov     eax, [esi].BorderColour

PE_DrawTopBorder_2:
            inc     [esi].WaitTState

PE_DTB_Write:
            mov     [edi],   ax

            add     edi, 2
            dec     [esi].UDCnt
            jz      PE_NextTopBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     PE_DrawTopBorder_2
            ret

Align 4
PE_NextTopBorderLine:
            NEXTSCANLINEADDR
            mov		eax, [esi].ScanTState
            add 	eax, MACHINE.ScanlineCycles
            mov 	[esi].ScanTState, eax
            mov 	[esi].WaitTState, eax

            add     ebp, 3

            dec 	[esi].TopBorderCnt
            jz  	PE_PrepLeftBorder      ; top border finished
            mov 	[esi].ScreenVector, OFFSET PentagonPrepTopBorder
            ret

; start actual screen area
Align 4
PE_PrepLeftBorder:
            mov 	[esi].ScreenVector, OFFSET PE_DrawLeftBorder
            mov 	[esi].UDCnt, 32/2
            ret

Align 16
PE_DrawLeftBorder:
            mov     eax, [esi].BorderColour

PE_DrawLB1: inc     [esi].WaitTState
            .if     ax != [edi]
                    mov     [edi], ax
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add 	edi, 2
            dec 	[esi].UDCnt
            jz  	PE_PrepDisplayLine

            cmp		ebx, [esi].WaitTState
            jnc		PE_DrawLB1
            ret

Align 4
PE_PrepDisplayLine:
            inc     ebp

            sub     [esi].WaitTState, 4

            mov 	[esi].UDCnt, 16
            mov     [esi].FetchCycle, 0

            mov 	[esi].ScreenVector, OFFSET PE_DrawDisplayLine

            ; prepare display/attr offsets for this scanline
            mov     eax, [DisplayTablePtr]
            mov     ecx, [eax]
            mov     eax, [eax+4]
            add     [DisplayTablePtr], 8
            mov     [esi].DisplayOffset, ecx
            mov     [esi].AttrOffset, eax
            ret

Align 16
PE_DrawDisplayLine:
            switch  [esi].FetchCycle
                    add     [esi].FetchCycle, 1
                    add     [esi].WaitTState, 1

                    FETCHCYCLEOFFSET = 2
                    FETCHCYCLEOFFSET = FETCHCYCLEOFFSET - 1 ; safe to assume that the ULA address bus is loaded one cycle before sampling the data bus?

                    case    FETCHCYCLEOFFSET
                            mov     eax, [esi].DisplayOffset
                            add     eax, [esi].zxDisplayOrg
                            mov     al, [eax]
                            mov     [esi].DisplayByte, al

                    case    FETCHCYCLEOFFSET+1
                            mov     eax, [esi].AttrOffset
                            add     eax, [esi].zxDisplayOrg
                            mov     al, [eax]
                            mov     [esi].AttrByte, al
                            call    Render_Pentagon_Character

                    case    FETCHCYCLEOFFSET+2
                            mov     eax, [esi].DisplayOffset
                            add     eax, [esi].zxDisplayOrg
                            mov     al, [eax]
                            mov     [esi].DisplayByte, al

                    case    FETCHCYCLEOFFSET+3
                            mov     eax, [esi].AttrOffset
                            add     eax, [esi].zxDisplayOrg
                            mov     al, [eax]
                            mov     [esi].AttrByte, al
                            call    Render_Pentagon_Character

                    case    7
                            mov     [esi].FetchCycle, 0
                            dec     [esi].UDCnt
                            jz      PE_PrepRightBorder
            endsw

            cmp     ebx, [esi].WaitTState
            jnc     PE_DrawDisplayLine
            ret

Align 4
PE_PrepRightBorder:
            inc     ebp

            add     [esi].WaitTState, 4

            mov 	[esi].ScreenVector, OFFSET PE_DrawRightBorder
            mov 	[esi].UDCnt, 32/2
            ret

Align 16
PE_DrawRightBorder:
            mov     eax, [esi].BorderColour

PE_DrawRB1: inc     [esi].WaitTState
            .if     ax != [edi]
                    mov     [edi], ax
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif
            add 	edi, 2
            dec 	[esi].UDCnt
            jz  	PE_PrepNextDisplayLine

            cmp		ebx, [esi].WaitTState
            jnc		PE_DrawRB1
            ret

Align 4
PE_PrepNextDisplayLine:
            NEXTSCANLINEADDR
            inc     [esi].CurrDisplayLine
            inc     ebp

            mov 	edx, [esi].ScanTState
            add 	edx, MACHINE.ScanlineCycles
            mov 	[esi].ScanTState, edx
            mov 	[esi].WaitTState, edx

            cmp     [esi].CurrDisplayLine, 192
            jnc 	PE_PrepBottomBorder

            mov 	[esi].ScreenVector, OFFSET PE_PrepLeftBorder
            ret

Align 4
PE_PrepBottomBorder:
            mov 	[esi].ScreenVector, OFFSET PE_DrawBottomBorder
            mov 	[esi].UDCnt, 320/2
            ret

Align 16
PE_DrawBottomBorder:
            mov 	eax, [esi].BorderColour

PE_DrawBottomBorder_1:
            inc     [esi].WaitTState

            cmp     ax, [edi]
            jne     PE_DBB_Changed

            add     edi, 2
            dec     [esi].UDCnt
            jz      PE_NextBottomBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     PE_DrawBottomBorder_1
            ret

PE_DBB_Changed:
            mov     [esi].ScreenVector, OFFSET PE_DrawBottomBorder_Write
            mov     byte ptr [ebp], 1
            mov     [esi].FrameChanged, TRUE
            jmp     PE_DBB_Write

Align 16
PE_DrawBottomBorder_Write:
            mov     eax, [esi].BorderColour

PE_DrawBottomBorder_2:
            inc     [esi].WaitTState

PE_DBB_Write:
            mov     [edi], ax

            add     edi, 2
            dec     [esi].UDCnt
            jz      PE_NextBottomBorderLine

            cmp     ebx, [esi].WaitTState
            jnc     PE_DrawBottomBorder_2
            ret

Align 4
PE_NextBottomBorderLine:
            NEXTSCANLINEADDR
            mov 	eax, [esi].ScanTState
            add 	eax, MACHINE.ScanlineCycles
            mov 	[esi].ScanTState, eax
            mov 	[esi].WaitTState, eax

            add     ebp, 3

            dec 	[esi].BottomBorderCnt
            jz  	PE_VerticalRetrace ; bottom border finished
            mov 	[esi].ScreenVector, OFFSET PE_PrepBottomBorder
            ret

Align 4
PE_VerticalRetrace:
            mov		[esi].ScreenVector, OFFSET UScrExit
            mov 	[esi].WaitTState, 180000
            ret

Render_Pentagon_Character:
            movzx   eax, [esi].AttrByte         ; eax = attribute byte
            movzx   ecx, [esi].DisplayByte      ; ecx = display byte

            test    eax, 128
            je      @F                          ; flash bit clear

            and     eax, 127                    ; clear Flash bit

            xor     cl, [esi].FlashInverterByte

@@:         shl     eax, 11                         ; * 2048 (256 entries per colour * 8 bytes/entry)
            lea     eax, [eax+ecx*8]                ; 8 bytes/entry
            add     eax, [esi].ptrSpecColourTable   ; offset into DirectDraw colour mapping table

            mov     ecx, [eax]                      ; pick up 8 pixel colour values
            mov     eax, [eax+4]

            .if     ecx != [edi]
                    mov     [edi], ecx
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif

            .if     eax != [edi+4]
                    mov     [edi+4], eax
                    mov     byte ptr [ebp], 1
                    mov     [esi].FrameChanged, TRUE
            .endif

            add     edi, 8

            add     [esi].DisplayOffset, 1
            add     [esi].AttrOffset, 1
            ret


            ASSUME	ESI:NOTHING


