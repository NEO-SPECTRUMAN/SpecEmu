
.code
align 16
Draw_Icons          proc    uses    ebx esi edi

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    IFDEF   PACMAN
                    invoke  Draw_Pacman_Level_Text
                    ENDIF

                    ifc     Display_Border_Icons eq FALSE then ret

                    mov     edi, [lpDIBBits]

                    .if     (HardwareMode == HW_PENTAGON128) && (FullScreenMode == TRUE)
                            movzx   eax, MACHINE.TopBorderLines
                            sub     eax, 21
                    .else
                            mov     al, MACHINE.TopBorderLines
                            add     al, MACHINE.DisplayLines
                            movzx   eax, al
        
                            .if     FullScreenMode == FALSE
                                    movzx   ecx, MACHINE.BottomBorderLines
                                    sub     ecx, 21
                                    shr     ecx, 1
                                    add     eax, ecx
                            .endif
                    .endif

                    imul    eax, DIBWidth
                    add     edi, eax

                    add     edi, (48 + 256)

                    ifc     HardwareMode eq HW_TC2048 then add edi, 256 + 48    ; TC2048 has 512 pixels per scanline

                    ; RZX info in status bar now so only draw RZX border icon in fullscreen mode
                    .if     FullScreenMode == TRUE
                            .if     rzx_mode != RZX_NONE
                                    lea     esi, di_rzx_icon
                                    mov     dl, CLR_SPECBASE + 5    ; cyan

                                    ; flash the video cam icon when recording or streaming
                                    .if     (rzx_mode == RZX_RECORD) || (rzx_streaming_enabled == TRUE)
                                            test    GlobalFramesCounter, 32
                                            .if     !ZERO?
                                                    mov     dl, CLR_SPECBASE + 2    ; red
                                            .endif
                                    .endif

                                    mov     dh, dl
                                    add     dh, 8
                                    call    Draw_Icon
                                    sub     edi, 8

                                    push    edi

                                    add     edi, 8+24
                                    add     edi, DIBWidth * 13

                                    .if     rzx_mode == RZX_RECORD
                                            mov     al, "C"
                                            call    Draw_Icon_Char
                                            mov     al, "E"
                                            call    Draw_Icon_Char
                                            mov     al, "R"
                                            call    Draw_Icon_Char

                                    .elseif rzx_mode == RZX_PLAY
                                            mov     al, "%"
                                            call    Draw_Icon_Char

                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                            imul    eax, RZXPLAY.rzx_frame_counter, 100
                                            invoke  IntDiv, eax, RZXPLAY.rzx_max_playback_frames
                                            ifc     eax gt 99 then mov eax, 99
                                            ADDTEXTDECIMAL  pTEXTSTRING, ax, ATD_ZEROES

                                            mov     al, textstring[4]
                                            call    Draw_Icon_Char
                                            mov     al, textstring[3]
                                            call    Draw_Icon_Char
                                    .endif

                                    pop     edi
                            .endif
                    .endif

                    .if     LoadTapeType != Type_NONE
                            lea     esi, di_tape_icon_1
                            mov     dl, CLR_SPECBASE + 2    ; red
                            .if     TapePlaying == TRUE
                                    push    edi
                                    test    GlobalFramesCounter, 8
                                    .if     !ZERO?
                                            lea     esi, di_tape_icon_2
                                    .endif
                                    lea     edi, di_tape_icon_copy
                                    mov     ecx, (21 * 4) + 2
                                    rep     movsb

                                    call    di_render_tape

                                    lea     esi, di_tape_icon_copy
                                    mov     dl, CLR_SPECBASE + 4    ; green
                                    pop     edi
                            .endif

                            mov     dh, dl
                            add     dh, 8
                            call    Draw_Icon
                            sub     edi, 8
                    .endif

                    switch  HardwareMode
                            case    HW_PLUS3
                                    lea     esi, di_plus3_disk_icon
                                    mov     al, Last1FFDWrite
                                    and     al, 8
                                    ifc     al eq 8 then mov dl, CLR_SPECBASE + 4 else mov dl, CLR_SPECBASE + 2
                                    mov     dh, dl
                                    add     dh, 8
                                    call    Draw_Icon
                                    sub     edi, 8

                            case    HW_PENTAGON128
                                    lea     esi, di_trdos_disk_icon
                                    mov     al, trdos_active_frames
                                    ifc     al gt 0 then dec trdos_active_frames
                                    ifc     al gt 0 then mov dl, CLR_SPECBASE + 4 else mov dl, CLR_SPECBASE + 2
                                    mov     dh, dl
                                    add     dh, 8
                                    call    Draw_Icon
                                    sub     edi, 8
                            .else
                                    .if     CBI_Enabled == TRUE
                                            lea     esi, di_trdos_disk_icon
                                            mov     al, trdos_active_frames
                                            ifc     al gt 0 then dec trdos_active_frames
                                            ifc     al gt 0 then mov dl, CLR_SPECBASE + 4 else mov dl, CLR_SPECBASE + 2
                                            mov     dh, dl
                                            add     dh, 8
                                            call    Draw_Icon
                                            sub     edi, 8
                                    .endif
                    endsw

                    ret

Draw_Icons          endp

align 16
Draw_Icon_Char:     mov     dh, CLR_SPECBASE + 7
                    mov     dl, CLR_SPECBASE + 0

; dh = Paper colour
; dl = Ink colour
Draw_Icon_Char_Col: sub     edi, 8
                    push    edi

                    and     eax, 255
                    lea     esi, [Rom_48+15360+eax*8]

                    mov     ch, 8

            @@:     mov     al, [esi]
                    inc     esi
                    call    Draw_Icon_Byte

                    add     edi, DIBWidth - 8
                    dec     ch
                    jnz     @B

                    pop     edi
                    ret

align 16
Draw_Icon_Byte:     mov     ah, 8
            @@:     shl     al, 1
                    .if     CARRY?
                            mov     [edi], dh
                    .else
                            mov     [edi], dl
                    .endif
                    inc     edi
                    dec     ah
                    jnz     @B
                    ret


; esi = icon data
; edi = display address
; dh = 1 bit colour
; dl = 0 bit colour
align 16
Draw_Icon:          movzx   ecx, byte ptr [esi] ; width
                    mov     bl, [esi+1]         ; height
                    add     esi, 2

                    shl     ecx, 3
                    sub     edi, ecx
                    shr     ecx, 3
                    push    edi

    _draw_icon_1:   push    edi
                    mov     ch, cl

            @@:     mov     al, [esi]
                    inc     esi
                    call    Draw_Icon_Byte
                    dec     ch
                    jnz     @B

                    pop     edi
                    add     edi, DIBWidth
                    dec     bl
                    jnz     _draw_icon_1

                    pop     edi
                    ret

align 16
di_render_tape:     lea     esi, tape_last_edges_buffer
                    lea     edi, di_tape_icon_copy + 2 + 1 + 8
                    mov     dl, TRUE    ; top
                    mov     dh, 32

                    mov     cl, [esi]
                    inc     esi

                    ifc     cl eq 64 then add edi, 40 : mov dl, FALSE   ; bottom

align 16
                    SETLOOP 5
                            mov     al, [esi]
                            inc     esi

                            .if     al == cl
                                    or      [edi], dh
                                    ror     dh, 1
                                    adc     edi, 0
                                    or      [edi], dh
                                    ror     dh, 1
                                    adc     edi, 0
                            .else
                                    mov     cl, al  ; cl = last state

                                    ifc     dl eq TRUE then mov eax, 4 else mov eax, -4

                                    mov     ebx, 10

                                @@: ifc     ebx eq 5 then ror dh, 1 : adc edi, 0
                                    ifc     ebx eq 9 then ror dh, 1 : adc edi, 0

                                    or      [edi], dh
                                    add     edi, eax

                                    dec     ebx
                                    jnz     @B

                                    xor     dl, TRUE    ; flip top/bottom flag
                            .endif
                    ENDLOOP
                    ret


.data

di_tape_icon_1      db      4, 21   ; width, height
                    db      11111111b, 11111111b, 11111111b, 11111111b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10100000b, 00000000b, 00000000b, 00000101b  ; top of tape render
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b

                    db      10000111b, 00000000b, 00000000b, 11100001b
                    db      10001010b, 10000000b, 00000001b, 01010001b
                    db      10001101b, 10000000b, 00000001b, 10110001b
                    db      10001010b, 10000000b, 00000001b, 01010001b
                    db      10000111b, 00000000b, 00000000b, 11100001b

                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b  ; bottom of tape render
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000001b, 11111111b, 11111111b, 10000001b
                    db      10000010b, 00000000b, 00000000b, 01000001b
                    db      10000010b, 00000000b, 00000000b, 01000001b
                    db      10000100b, 00000000b, 00000000b, 00100001b
                    db      10100100b, 00000000b, 00000000b, 00100101b
                    db      10000100b, 00000000b, 00000000b, 00100001b
                    db      11111111b, 11111111b, 11111111b, 11111111b

di_tape_icon_2      db      4, 21   ; width, height
                    db      11111111b, 11111111b, 11111111b, 11111111b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10100000b, 00000000b, 00000000b, 00000101b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b

                    db      10000111b, 00000000b, 00000000b, 11100001b
                    db      10001101b, 10000000b, 00000001b, 10110001b
                    db      10001000b, 10000000b, 00000001b, 00010001b
                    db      10001101b, 10000000b, 00000001b, 10110001b
                    db      10000111b, 00000000b, 00000000b, 11100001b

                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000000b, 00000001b
                    db      10000001b, 11111111b, 11111111b, 10000001b
                    db      10000010b, 00000000b, 00000000b, 01000001b
                    db      10000010b, 00000000b, 00000000b, 01000001b
                    db      10000100b, 00000000b, 00000000b, 00100001b
                    db      10100100b, 00000000b, 00000000b, 00100101b
                    db      10000100b, 00000000b, 00000000b, 00100001b
                    db      11111111b, 11111111b, 11111111b, 11111111b




di_plus3_disk_icon  db      2, 21   ; width, height
                    db      11111111b, 11111111b
                    db      10000001b, 10000001b
                    db      10000001b, 10000001b
                    db      10000001b, 10000001b
                    db      10000001b, 10000001b
                    db      10000000b, 00000001b
                    db      10000000b, 00000001b
                    db      10000000b, 00000001b
                    db      10000001b, 10000001b
                    db      10000011b, 11000001b
                    db      10000011b, 11000001b
                    db      10000001b, 10000001b
                    db      10000000b, 00000001b
                    db      10000000b, 00000001b
                    db      10000000b, 00000001b
                    db      10000000b, 00000001b
                    db      10011111b, 11111001b
                    db      10011111b, 11111001b
                    db      10011111b, 11111001b
                    db      10011111b, 11111001b
                    db      11111111b, 11111111b

di_trdos_disk_icon  db      3, 21   ; width, height

                    db      11111111b, 11111111b, 11111111b
                    db      10000110b, 10101100b, 00100001b
                    db      10000101b, 01010100b, 00100001b
                    db      10000110b, 10101100b, 00100001b
                    db      10000101b, 01010100b, 00100001b
                    db      10000110b, 10101100b, 00100001b
                    db      10000011b, 11111111b, 11000001b
                    db      10000000b, 00000000b, 00000001b
                    db      10000000b, 00000000b, 00000001b
                    db      10000111b, 11111111b, 11100001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001011b, 11111111b, 11010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001011b, 11111111b, 11010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001000b, 00000000b, 00010001b
                    db      10001011b, 11111111b, 11010001b
                    db      11111111b, 11111111b, 11111111b




di_rzx_icon         db      3, 13   ; width, height
                    db      00000000b, 00000000b, 00000000b
                    db      00000000b, 00000000b, 00000000b
                    db      00110011b, 11111111b, 11100000b
                    db      00111110b, 00000000b, 00010000b
                    db      00111110b, 01111111b, 10010000b
                    db      00111010b, 10000000b, 01010000b
                    db      00110010b, 10000000b, 01010000b
                    db      00000010b, 10000000b, 01010000b
                    db      00000010b, 01111111b, 10010000b
                    db      00000010b, 00000000b, 00010000b
                    db      00000001b, 11111111b, 11100000b
                    db      00000000b, 00000000b, 00000000b
                    db      00000000b, 00000000b, 00000000b

.data?
di_tape_icon_copy   BYTE    (21 * 4) + 2    dup (?)




