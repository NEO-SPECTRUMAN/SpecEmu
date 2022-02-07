
.data?
align 4

lpDD                LPDIRECTDRAW        ?       ; DDraw object
lpDDSPrimary        LPDIRECTDRAWSURFACE ?       ; DDraw primary surface
lpDDSBackBuffer     LPDIRECTDRAWSURFACE ?       ; DDraw backbuffer surface
lpDDClipper         LPDIRECTDRAWCLIPPER ?       ; DDraw clipper object
lpDDPalette         LPDIRECTDRAWPALETTE ?       ; DDraw palette object
ddsd_p              DDSURFACEDESC       <?>     ; DDraw primary surface descriptor
ddsd_b              DDSURFACEDESC       <?>     ; DDraw backbuffer surface descriptor
ddscaps             DDSCAPS             <?>     ; DDraw surface capabilities
ddPixelFormat       DDPIXELFORMAT       <?>     ; DDraw pixel format
ddcaps              DDCAPS              <?>     ; DDraw capabilities
ddbltfx             DDBLTFX             <?>     ; DDraw Blitter FX

SrcRect             RECT    <?>
DDRect              RECT    <?>
BackBuffRect        RECT    <?>

FullScreenMode      DWORD   ?
DXResult            DWORD   ?

DesktopBPP          DWORD   ?

RedComponent        DWORD   ?
GreenComponent      DWORD   ?
BlueComponent       DWORD   ?

ddCurrentPalette    DWORD   ?

DIBdrawaddr         DWORD   ?

DIB_paper           BYTE    ?
DIB_ink             BYTE    ?

.data
SurfacesReady       db  FALSE   ; surfaces only drawn when TRUE
.code

DDLOG               macro   str:req, code:req
                    ifdef   LOGGING
                            LOGHEX  str, eax
                    endif
                    endm

InitDirectDraw      proc

DDCREATE_EMULATIONONLY  =   2

                    mov     lpDD, NULL
                    mov     lpDDSPrimary, NULL
                    mov     lpDDSBackBuffer, NULL
                    mov     lpDDClipper, NULL

                    memclr  addr ddbltfx,   sizeof ddbltfx
                    mov     ddbltfx.dwSize, sizeof ddbltfx

                    LOG     "Creating DirectDraw object"
                    ifc     DirectDraw_Acceleration eq FALSE then mov ecx, DDCREATE_EMULATIONONLY else mov ecx, NULL
                    invoke  DirectDrawCreate, ecx, addr lpDD, NULL
                    mov     DXResult, eax
                    .if     eax != DD_OK
                            FATAL "Error initialising DirectDraw", eax
                    .endif

                    LOG     "Reading DirectDraw capabilities"
                    memclr  addr ddcaps, sizeof ddcaps
                    mov     [ddcaps.dwSize], sizeof ddcaps
                    DDINVOKE    GetCaps, lpDD, ADDR ddcaps, NULL
                    mov     DXResult, eax
                    .if     eax != DD_OK
                            FATAL "Error reading DirectDraw capabilities", eax
                    .endif

                    ret

InitDirectDraw      endp

GetSurfaceColours   proc

                    LOG     "Reading surface pixel format"

                    mov     [ddPixelFormat.dwSize], sizeof DDPIXELFORMAT
                    DDSINVOKE   GetPixelFormat, lpDDSPrimary, addr ddPixelFormat
                    .if     eax != DD_OK
                            FATAL "GetPixel Format failed!", eax
                    .endif

                    mov     eax, -1
                    and     eax, [ddPixelFormat.dwRBitMask]
                    mov     [RedComponent], eax

                    mov     eax, -1
                    and     eax, [ddPixelFormat.dwGBitMask]
                    mov     [GreenComponent], eax

                    mov     eax, -1
                    and     eax, [ddPixelFormat.dwBBitMask]
                    mov     [BlueComponent], eax

                    invoke  SetSpectrumPalette, UserPalette
                    invoke  BuildULAplusPalette

                    invoke  SetDirtyLines
                    UPDATEWINDOW
                    ret

GetSurfaceColours   endp

ShutdownDirectDraw  proc

                    .if lpDD != NULL
                        invoke  FreeSurfaces

                        LOG     "Releasing DirectDraw object"
                        DDINVOKE    Release, lpDD
                        mov     [lpDD], NULL
                    .endif

                    ret

ShutdownDirectDraw  endp

FlipDisplayMode     proc

                    .if FullScreenMode == TRUE  ; switching to windowed mode
                        mov     SwitchingModes, TRUE
                        LOG     "--> Switching to windowed mode"
                        LOG     "Freeing fullscreen surfaces"
                        invoke  FreeSurfaces

                        invoke  ShutdownDirectDraw
                        invoke  InitDirectDraw

                        LOG     "SetWindowLong"
                        invoke  SetWindowLong, hWnd, GWL_EXSTYLE, dwExStyle
                        invoke  SetWindowLong, hWnd, GWL_STYLE,   dwStyle

                        LOG     "Resizing window"
                        invoke  ShowWindow, mainwin_hToolBar, SW_SHOW
                        invoke  ShowWindow, mainwin_hStatus,  SW_SHOW
                        mov     ecx, WindowRect.right
                        sub     ecx, WindowRect.left
                        mov     edx, WindowRect.bottom
                        sub     edx, WindowRect.top
                        invoke  MoveWindow, hWnd, WindowRect.left, WindowRect.top, ecx, edx, TRUE

                        mov     FullScreenMode, FALSE
                        LOG     "Initialising windowed mode surfaces"
                        invoke  InitSurfaces, hWnd
                        LOG     "Updating window"
                        mov     SwitchingModes, FALSE
                        invoke  ShowWindow, hWnd, SW_SHOW

                        invoke  SetDirtyLines
                        UPDATEWINDOW
                        LOG     "Mode switch complete"
                        ret

                    .else                       ; switching to fullscreen mode
                        invoke  ShowWindow, mainwin_hToolBar, SW_HIDE
                        invoke  ShowWindow, mainwin_hStatus,  SW_HIDE
                        invoke  HideTools1Dialog

                        mov     SwitchingModes, TRUE
                        LOG     "--> Switching to fullscreen mode"
                        LOG     "Freeing windowed surfaces"
                        invoke  FreeSurfaces

                        invoke  ShutdownDirectDraw
                        invoke  InitDirectDraw

                        invoke  GetWindowRect, hWnd, ADDR WindowRect    ; save the window position
                        LOG     "SetWindowLong"
                        invoke  SetWindowLong, hWnd, GWL_EXSTYLE, WS_EX_LEFT or WS_EX_TOPMOST
                        invoke  SetWindowLong, hWnd, GWL_STYLE,   WS_VISIBLE or WS_POPUP

                        LOG     "Resizing window"
                        invoke  MoveWindow, hWnd, 0, 0, DDWidth, DDHeight, TRUE
                        mov     FullScreenMode, TRUE
                        LOG     "Initialising fullscreen mode surfaces"
                        invoke  InitSurfaces, hWnd
                        LOG     "Updating window"
                        mov     SwitchingModes, FALSE

                        invoke  SetDirtyLines
                        UPDATEWINDOW
                        LOG     "Mode switch complete"
                        ret
                    .endif

FlipDisplayMode     endp

InitSurfaces        proc    uses    ebx esi edi,
                            hWin:   DWORD

                    LOCAL   DDMemFlags: DWORD

                    .if     FullScreenMode == TRUE

                        ; setup fullscreen mode
                        LOG     "SetCooperativeLevel = DDSCL_FULLSCREEN + DDSCL_EXCLUSIVE"
                        DDINVOKE    SetCooperativeLevel, lpDD, hWin, DDSCL_FULLSCREEN or DDSCL_EXCLUSIVE
                        .if     eax != DD_OK
                                FATAL "Error setting DirectDraw cooperative level", eax
                        .endif

                        LOG     "Setting fullscreen display mode"
                        DDINVOKE    SetDisplayMode, lpDD, DDWidth, DDHeight, DDBpp
                        .if     eax != DD_OK
                                FATAL "Error setting display mode", eax
                        .endif

                    .else

                        ; setup windowed mode
                        LOG     "SetCooperativeLevel = DDSCL_NORMAL"
                        DDINVOKE    SetCooperativeLevel, lpDD, hWin, DDSCL_NORMAL
                        .if     eax != DD_OK
                                FATAL "Failed setting DirectDraw cooperative level", eax
                        .endif

                    .endif

                    ; the rest of surface setup is *almost* identical for windowed and fullscreen modes

                    ; setup primary surface
                    memclr  addr ddsd_p, sizeof ddsd_p
                    mov     [ddsd_p.dwSize],  sizeof DDSURFACEDESC
                    mov     [ddsd_p.dwFlags], DDSD_CAPS
                    mov     [ddsd_p.ddsCaps.dwCaps], DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY

RecreateSurface:    LOG     "Creating primary surface"
                    DDINVOKE    CreateSurface, lpDD, ADDR ddsd_p, ADDR lpDDSPrimary, NULL
                    mov     DXResult, eax

                    .if     eax != DD_OK
                            switch  eax
                                    case    DDERR_NOEXCLUSIVEMODE
                                            invoke  Sleep, 100
                                            jmp     RecreateSurface
                                    case    DDERR_NODIRECTDRAWHW
                                            mov     [ddsd_p.ddsCaps.dwCaps], DDSCAPS_PRIMARYSURFACE or DDSCAPS_SYSTEMMEMORY
                                            jmp     RecreateSurface
                                    .else
                                            FATAL   "Failed creating primary surface", eax
                            endsw
                    .endif

                    ; setup backbuffer surface
                    memclr  addr ddsd_b, sizeof ddsd_b
                    mov     [ddsd_b.dwSize],   sizeof DDSURFACEDESC
                    mov     [ddsd_b.dwWidth],  DIBWidth
                    mov     [ddsd_b.dwHeight], DIBHeight
                    mov     [ddsd_b.dwFlags],  DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT

                    mov     eax, [ddcaps.dwCaps]
                    and     eax, DDCAPS_BLTSTRETCH

                    .if     eax == DDCAPS_BLTSTRETCH
                            mov  [DDMemFlags], DDSCAPS_VIDEOMEMORY
                            LOG  "Attempting to allocate VIDEOMEM backbuffer"
                    .else
                            mov  [DDMemFlags], DDSCAPS_SYSTEMMEMORY
                            LOG  "Attempting to allocate SYSTEMMEM backbuffer"
                    .endif

                    mov     eax, [DDMemFlags]
                    or      eax, DDSCAPS_OFFSCREENPLAIN
                    mov     [ddsd_b.ddsCaps.dwCaps], eax

                    LOG    "Creating back buffer surface"
                    DDINVOKE    CreateSurface, lpDD, ADDR ddsd_b, ADDR lpDDSBackBuffer, NULL
                    mov     DXResult, eax

                    .if     eax != DD_OK
                            .if     [DDMemFlags] == DDSCAPS_VIDEOMEMORY
                                    LOG     "Falling back to a SYSTEMMEM backbuffer"
                                    mov     [DDMemFlags], DDSCAPS_SYSTEMMEMORY
                                    mov     eax, [DDMemFlags]
                                    or      eax, DDSCAPS_OFFSCREENPLAIN
                                    mov     [ddsd_b.ddsCaps.dwCaps], eax

                                    DDINVOKE    CreateSurface, lpDD, ADDR ddsd_b, ADDR lpDDSBackBuffer, NULL
                                    mov     DXResult, eax
                            .endif
                    .endif

                    .if     eax != DD_OK
                            FATAL   "Failed creating backbuffer surface", eax
                    .endif

                    LOG     "Creating clipper"
                    mov     lpDDClipper, 0
                    DDINVOKE    CreateClipper, lpDD, 0, ADDR lpDDClipper, NULL
                    mov     DXResult, eax

                    .if     eax == DD_OK
                            LOG         "Attaching clipper to primary surface"
                            DDCINVOKE   SetHWnd, lpDDClipper, 0, hWin
                            DDSINVOKE   SetClipper, lpDDSPrimary, lpDDClipper
                            LOG         "Releasing clipper"
                            DDCINVOKE   Release, lpDDClipper
                    .else
                            FATAL   "Failed creating clipper object", eax
                    .endif

                    invoke  GetSurfaceColours

                    mov     SurfacesReady, TRUE
                    ret

InitSurfaces        endp

FreeSurfaces        proc

                    .if     FullScreenMode == TRUE
                            LOG "Restoring Display mode"
                            DDINVOKE RestoreDisplayMode, lpDD
                            .if     eax != DD_OK
                                    LOG "Failed restoring display mode"
                            .endif

                            LOG "SetCooperativeLevel = Normal"
                            DDINVOKE    SetCooperativeLevel, lpDD, hWnd, DDSCL_NORMAL
                            .if     eax != DD_OK
                                    LOG "Failed setting DirectDraw cooperative level"
                            .endif
                    .endif

                    .if     lpDDSPrimary != NULL
                            LOG "Releasing primary surface"
                            DDSINVOKE   Release, lpDDSPrimary
                            mov     [lpDDSPrimary], NULL
                    .endif

                    .if     lpDDSBackBuffer != NULL
                            LOG "Releasing back buffer surface"
                            DDSINVOKE   Release, lpDDSBackBuffer
                            mov     [lpDDSBackBuffer], NULL
                    .endif

                    mov     SurfacesReady, FALSE
                    ret

FreeSurfaces        endp

RestoreSurfaces     proc

; returns DD_OK if surfaces not lost or successfully restored

                    DDSINVOKE   IsLost, lpDDSPrimary
                    .if         eax == DDERR_SURFACELOST
                                DDSINVOKE   Restore, lpDDSPrimary
                                invoke  SetDirtyLines
                    .endif

                    .if     eax != DD_OK
                            ret
                    .endif

                    DDSINVOKE   IsLost, lpDDSBackBuffer
                    .if         eax == DDERR_SURFACELOST
                                DDSINVOKE   Restore, lpDDSBackBuffer
                                invoke  SetDirtyLines
                    .endif

                    ret

RestoreSurfaces     endp

align 16
DIBToScreen         proc    hWin:   DWORD

FS_OFFSET_X         equ     ((DIBWidth-320)/2)
FS_OFFSET_Y         equ     24  ; only take lower 24 border lines from top border area

ZOOMOFFSET          equ     15

                    invoke  Draw_Icons

                    .if     $fnc (DumptoDXSurface) == DD_OK
                            invoke  BlitScreen, hWin
                    .endif
                    ret     ; return with any error

DIBToScreen         endp

align 16
BltFlip_Mirror_Horz proc
                    test    [ddcaps.dwFXCaps], DDFXCAPS_BLTMIRRORLEFTRIGHT
                    .if     !ZERO?
                            xor     ddbltfx.dwDDFX, DDBLTFX_MIRRORLEFTRIGHT
                    .endif
                    ret
BltFlip_Mirror_Horz endp

align 16
BltFlip_Mirror_Vert proc
                    test    [ddcaps.dwFXCaps], DDFXCAPS_BLTMIRRORUPDOWN
                    .if     !ZERO?
                            xor     ddbltfx.dwDDFX, DDBLTFX_MIRRORUPDOWN
                    .endif
                    ret
BltFlip_Mirror_Vert endp

DOBLIT              MACRO
                    .if     VSync_Enabled == TRUE
                            DDINVOKE    WaitForVerticalBlank, lpDD, DDWAITVB_BLOCKBEGIN, NULL
                    .endif

                    DDSINVOKE   Blt, lpDDSPrimary, addr DDRect, lpDDSBackBuffer, addr SrcRect, DDBLT_WAIT or DDBLT_DDFX, addr ddbltfx
                    .if         eax != DD_OK
                                DDLOG   "Blit fail: ", eax

                                .if     eax == DDERR_INVALIDRECT
                                        LOG     "INVALIDRECT"
                                        LOGRECT "Src rect", offset SrcRect
                                        LOGRECT "Dest rect", offset DDRect
                                .endif
                    .endif
                    ENDM

align 16
GetSrcDIBRect       proc    lpRect: DWORD

                    mov     ecx, lpRect
                    assume  ecx: ptr RECT

                    mov     [ecx].left,   0
                    m2m     [ecx].right,  MACHINE.DisplayWidth
                    mov     [ecx].top,    0
                    m2m     [ecx].bottom, MACHINE.DisplayHeight
                    ret

                    assume  ecx: nothing
GetSrcDIBRect       endp

align 16
SetDIBDrawPosn          proc    x, y:       DWORD

                        imul    eax, y, DIBWidth
                        add     eax, x
                        add     eax, lpDIBBits
                        mov     DIBdrawaddr, eax

                        ret
SetDIBDrawPosn          endp

align 16
SetDIBPaper             proc    colour: BYTE

                        mov     al, colour
                        add     al, CLR_SPECBASE
                        mov     DIB_paper, al
                        ret
SetDIBPaper             endp

align 16
SetDIBInk               proc    colour: BYTE

                        mov     al, colour
                        add     al, CLR_SPECBASE
                        mov     DIB_ink, al
                        ret
SetDIBInk               endp

align 16
DrawDIBText             proc    uses    edi esi,
                                lpText: DWORD

                        mov     esi, lpText

                        .while  byte ptr [esi] != 0
                                invoke  DrawDIBChar, byte ptr [esi]
                                inc     esi
                        .endw

                        ret
DrawDIBText             endp

align 16
DrawDIBChar             proc    uses    esi edi,
                                char:   BYTE

                        movzx   eax, char
                        sub     eax, 32

                        .if     CARRY? || (eax >= DIBcharfontsizeof/8)
                                mov     al, "?" - 32
                        .endif

                        mov     edi, DIBdrawaddr
                        lea     esi, [DIBcharfont+eax*8]

                        mov     dl, DIB_paper
                        mov     dh, DIB_ink

                        SETLOOP 8
                                mov     al, [esi]
                                inc     esi

                                mov     ah, 8
                                @@:     shl     al, 1
                                        .if     CARRY?
                                                mov     [edi], dh
                                        .else
                                                mov     [edi], dl
                                        .endif
                                        inc     edi

                                dec     ah
                                jnz     @B

                                add     edi, DIBWidth - 8
                        ENDLOOP

                        add     DIBdrawaddr, 8
                        ret

DrawDIBChar             endp

align 16
BlitScreen          proc    hWin:   DWORD

                    local   tPoint: POINT

                    invoke  GetSrcDIBRect, addr SrcRect

                    .if     FullScreenMode == TRUE
                            mov     DDRect.left,   0
                            mov     DDRect.top,    0
                            mov     DDRect.right,  DDWidth
                            mov     DDRect.bottom, DDHeight
                    .else
                            ; window routine
                            mov     tPoint.x, 0
                            mov     tPoint.y, 0
                            invoke  ClientToScreen, hWin, addr tPoint
                            invoke  GetClientRect,  hWin, addr DDRect
                            invoke  OffsetRect,     addr DDRect, tPoint.x, tPoint.y

                            mov     eax, ToolBarHeight
                            add     DDRect.top, eax

                            mov     eax, StatusHeight
                            sub     DDRect.bottom, eax
                    .endif

                    DOBLIT
                    .if     eax != DD_OK
                            .if     eax == DDERR_SURFACELOST
                                    invoke  RestoreSurfaces
                                    .if     eax == DD_OK
                                            DOBLIT
                                    .endif
                            .else
                                    LOG     "Blit error"
                            .endif
                    .endif
                    ret

BlitScreen          endp

GETPIXELPALETTE     macro
                    ifc     byte ptr [edx] lt 128 then mov ddCurrentPalette, offset ddSurfacePalette else mov ddCurrentPalette, offset ddULAplusPalette
                    endm

align 16
ColourDump          proc    uses    esi edi ebx,
                            Dest:           DWORD,
                            Pitch:          DWORD,
                            BPPFunction:    DWORD,
                            DisplayOffset:  DWORD,     ; offset from Dest in bytes
                            R_BorderOffset: DWORD      ; offset from Dest in bytes

                    local   pEndSurface:    DWORD

                    mov     eax, MACHINE.DisplayHeight
                    mov     ecx, [Pitch]
                    mul     ecx
                    add     eax, [Dest]
                    mov     pEndSurface, eax

                    mov     eax, SPGfx.VerticalOffset
                    .if     eax > 0
                            sub     eax, 10
                            ifc     CARRY? then xor eax, eax
                            mov     SPGfx.VerticalOffset, eax
                            mul     [Pitch]
                            add     eax, [Dest]
                            mov     edi, eax

                            invoke  SetDirtyLines
                    .else
                            mov     edi, [Dest]
                    .endif

                    mov     esi, [lpDIBBits]
                    lea     edx, DirtyLines

                    movzx   eax, MACHINE.TopBorderLines
                    SETLOOP eax
                    .if     byte ptr [edx] != 0

                            GETPIXELPALETTE

                            mov     byte ptr [edx], 0
                            push    edi
                            push    esi
                            mov     eax, MACHINE.DisplayWidth
                            call    [BPPFunction]
                            pop     esi
                            pop     edi
                    .endif
                    add     edx, 3
                    add     esi, DIBWidth
                    add     edi, [Pitch]
                    ifc     edi ge pEndSurface then mov edi, Dest
                    ENDLOOP


                    SETLOOP DISPLAYLINES
                    ; test left border update
                    .if     byte ptr [edx] != 0

                            GETPIXELPALETTE

                            mov     byte ptr [edx], 0
                            push    edi
                            push    esi
                            mov     eax, MACHINE.BorderWidth
                            call    [BPPFunction]
                            pop     esi
                            pop     edi
                    .endif
                    inc     edx

                    ; test display update
                    .if     byte ptr [edx] != 0

                            GETPIXELPALETTE

                            mov     byte ptr [edx], 0
                            push    edi
                            push    esi
                            add     esi, MACHINE.BorderWidth
                            add     edi, DisplayOffset
                            mov     eax, MACHINE.PixelWidth
                            call    [BPPFunction]
                            pop     esi
                            pop     edi
                    .endif
                    inc     edx

                    ; test right border update
                    .if     byte ptr [edx] != 0

                            GETPIXELPALETTE

                            mov     byte ptr [edx], 0
                            push    edi
                            push    esi
                            add     esi, MACHINE.BorderWidth
                            add     esi, MACHINE.PixelWidth
                            add     edi, R_BorderOffset
                            mov     eax, MACHINE.BorderWidth
                            call    [BPPFunction]
                            pop     esi
                            pop     edi
                    .endif
                    inc     edx

                    add     esi, DIBWidth
                    add     edi, [Pitch]
                    ifc     edi ge pEndSurface then mov edi, Dest
                    ENDLOOP

                    movzx   eax, MACHINE.BottomBorderLines
                    SETLOOP eax
                    .if     byte ptr [edx] != 0

                            GETPIXELPALETTE

                            mov     byte ptr [edx], 0
                            push    edi
                            push    esi
                            mov     eax, MACHINE.DisplayWidth
                            call    [BPPFunction]
                            pop     esi
                            pop     edi
                    .endif
                    add     edx, 3
                    add     esi, DIBWidth
                    add     edi, [Pitch]
                    ifc     edi ge pEndSurface then mov edi, Dest
                    ENDLOOP

                    ret

ColourDump          endp

align 16
ColourDump8bit:     mov     ecx, eax
                    shr     ecx, 2      ; bytes_to_convert/4
                    rep     movsd
                    ret

align 16
ColourDump16bit:    push    edx
                    push    ebp
                    mov     ebp, ddCurrentPalette

                    shr     eax, 3      ; bytes_to_convert/8
                    push    eax

            @@:     movzx   eax, byte ptr [esi]
                    movzx   ebx, byte ptr [esi+1]
                    movzx   ecx, byte ptr [esi+2]
                    movzx   edx, byte ptr [esi+3]
                    add     esi, 4
                    mov     ax,  word ptr [ebp+eax*4]
                    mov     bx,  word ptr [ebp+ebx*4]
                    mov     cx,  word ptr [ebp+ecx*4]
                    mov     dx,  word ptr [ebp+edx*4]
                    mov     [edi],   ax
                    mov     [edi+2], bx
                    mov     [edi+4], cx
                    mov     [edi+6], dx
                    add     edi, 8

                    movzx   eax, byte ptr [esi]
                    movzx   ebx, byte ptr [esi+1]
                    movzx   ecx, byte ptr [esi+2]
                    movzx   edx, byte ptr [esi+3]
                    add     esi, 4
                    mov     ax,  word ptr [ebp+eax*4]
                    mov     bx,  word ptr [ebp+ebx*4]
                    mov     cx,  word ptr [ebp+ecx*4]
                    mov     dx,  word ptr [ebp+edx*4]
                    mov     [edi],   ax
                    mov     [edi+2], bx
                    mov     [edi+4], cx
                    mov     [edi+6], dx
                    add     edi, 8

                    dec     dword ptr [esp]
                    jnz     @B
                    add     esp, 4

                    pop     ebp
                    pop     edx
                    ret

align 16
ColourDump24bit:    push    ebp
                    mov     ebp, ddCurrentPalette

                    shr     eax, 2      ; bytes_to_convert/4
                    push    eax

            @@:     mov     ebx, [esi]
                    add     esi, 4

                    movzx   eax, bl
                    shr     ebx, 8
                    mov     ecx, dword ptr [ebp+eax*4]
                    mov     [edi], ecx

                    movzx   eax, bl
                    shr     ebx, 8
                    mov     ecx, dword ptr [ebp+eax*4]
                    mov     [edi+3], ecx

                    movzx   eax, bl
                    shr     ebx, 8
                    mov     ecx, dword ptr [ebp+eax*4]
                    mov     [edi+6], ecx

                    movzx   eax, bl
                    shr     ebx, 8
                    mov     ecx, dword ptr [ebp+eax*4]
                    mov     [edi+9], ecx
                    add     edi, 12

                    dec     dword ptr [esp]
                    jnz     @B
                    add     esp, 4

                    pop     ebp
                    ret

align 16
ColourDump32bit:    push    edx
                    push    ebp
                    mov     ebp, ddCurrentPalette

                    shr     eax, 2      ; bytes_to_convert/4
                    push    eax

            @@:     movzx   eax, byte ptr [esi]
                    movzx   ebx, byte ptr [esi+1]
                    movzx   ecx, byte ptr [esi+2]
                    movzx   edx, byte ptr [esi+3]
                    add     esi, 4

                    mov     eax, dword ptr [ebp+eax*4]
                    mov     ebx, dword ptr [ebp+ebx*4]
                    mov     ecx, dword ptr [ebp+ecx*4]
                    mov     edx, dword ptr [ebp+edx*4]

                    mov     [edi],    eax
                    mov     [edi+4],  ebx
                    mov     [edi+8],  ecx
                    mov     [edi+12], edx
                    add     edi, 16

                    dec     dword ptr [esp]
                    jnz     @B
                    add     esp, 4

                    pop     ebp
                    pop     edx
                    ret

align 16
DumptoDXSurface     proc

                    local   Pitch   : DWORD,
                            Dest    : DWORD

                    invoke  LockBackBufferSurface
                    .if     eax != DD_OK    ; failed to lock the surface
                            ret             ; return with the error
                    .endif

                    m2m     Pitch, [ddsd_b.lPitch]
                    m2m     Dest,  [ddsd_b.lpSurface]

                    .if     FullScreenMode == TRUE
                            mov     eax, DDBpp
                    .else
                            mov     eax, DesktopBPP
                    .endif

                    mov     edx, MACHINE.BorderWidth    ; left border width
                    add     edx, MACHINE.PixelWidth     ; right border offset

                    mov     ecx, MACHINE.BorderWidth

                    .if     eax == 32
                            shl     edx, 2  ; * 4
                            shl     ecx, 2  ; * 4
                            invoke  ColourDump, Dest, Pitch, addr ColourDump32bit, ecx, edx

                    .elseif eax == 16
                            shl     edx, 1  ; * 2
                            shl     ecx, 1  ; * 2
                            invoke  ColourDump, Dest, Pitch, addr ColourDump16bit, ecx, edx

                    .elseif eax == 24
                            mov     eax, edx
                            shl     edx, 1
                            add     edx, eax    ; * 3

                            mov     eax, ecx
                            shl     ecx, 1
                            add     ecx, eax    ; * 3
                            invoke  ColourDump, Dest, Pitch, addr ColourDump24bit, ecx, edx

                    .elseif eax == 8
                            invoke  ColourDump, Dest, Pitch, addr ColourDump8bit, ecx, edx

                    .else
                            invoke  UnlockBackBufferSurface
                            LOG     "Unsupported desktop colour depth"
                            return  -1  ; return with error
                    .endif

                    invoke  UnlockBackBufferSurface
                    return  DD_OK   ; return no error

DumptoDXSurface     endp

align 16
LockBackBufferSurface   proc

LockBackSurface:    mov  [ddsd_b.dwSize],  sizeof DDSURFACEDESC
                    mov  [ddsd_b.dwFlags], DDSD_PITCH

                  ; not using DDLOCK_WAIT causes deferred blits to prevent main window refreshes on WM_PAINT when emulator is paused
                    DDSINVOKE   mLock,   lpDDSBackBuffer, NULL, addr ddsd_b, DDLOCK_SURFACEMEMORYPTR or DDLOCK_WRITEONLY or DDLOCK_WAIT, NULL

                    .if     eax == DD_OK
                            ret         ; return with no error
                    .endif

                    .if     eax == DDERR_SURFACELOST
                            invoke  RestoreSurfaces
                            .if     eax == DD_OK
                                    jmp     LockBackSurface ; relock if surfaces restored successfully
                            .endif
                            DDLOG   "Restore fail: ", eax
                            ret         ; else return the error

                    .elseif (eax == DDERR_SURFACEBUSY) || (eax == DDERR_WASSTILLDRAWING)
                            ret     ; drop this frame and return the error

                    .else
                            DDLOG   "Lock fail: ", eax
                    .endif
                    ret     ; return the error

LockBackBufferSurface   endp

align 16
UnlockBackBufferSurface proc

                        DDSINVOKE   Unlock, lpDDSBackBuffer, NULL
                        .if         eax != DD_OK
                                    DDLOG   "Unlock fail: ", eax
                        .endif
                        ret

UnlockBackBufferSurface endp

align 16
GetDesktopBPP       proc

                    local   tempDC:     DWORD,
                            tempBPP:    DWORD

                    mov     tempDC,    $fnc (GetWindowDC, $fnc (GetDesktopWindow))
                    mov     tempBPP,   $fnc (GetDeviceCaps, tempDC, BITSPIXEL)
                    invoke  ReleaseDC, $fnc (GetDesktopWindow), tempDC
                    return  tempBPP     ; return bits per pixel

GetDesktopBPP       endp

.data
align 8
; Original file C:\RadASM\Spectrum_Projects\SuperCrapInvaders\NewFont.font at 768 bytes

DIBcharfont         db 0,0,0,0,0,0,0,0,48,48,48,48,48,0,48,48
                    db 54,108,0,0,0,0,0,0,0,36,126,36,36,126,36,0
                    db 0,8,62,40,62,10,62,8,113,82,100,8,19,37,71,0
                    db 0,16,40,16,42,68,58,0,12,12,24,0,0,0,0,0
                    db 12,24,24,24,24,24,24,12,24,12,12,12,12,12,12,24
                    db 0,24,126,60,126,24,0,0,0,0,8,8,62,8,8,0
                    db 0,0,0,0,0,24,24,48,0,0,0,62,62,0,0,0
                    db 0,0,0,0,0,48,48,0,1,2,4,8,16,32,64,0
                    db 62,99,103,107,115,99,62,0,56,24,24,24,24,24,126,0
                    db 60,102,6,12,24,48,127,0,127,3,6,31,3,99,62,0
                    db 6,14,22,38,70,127,6,6,127,96,96,62,3,99,62,0
                    db 12,24,48,126,99,99,62,0,127,99,3,6,12,24,48,0
                    db 62,99,99,62,99,99,62,0,62,99,99,63,3,99,62,0
                    db 0,0,24,24,0,24,24,0,0,0,24,24,0,24,24,48
                    db 0,0,4,8,16,8,4,0,0,0,0,62,0,62,0,0
                    db 255,231,129,195,129,231,255,255,62,99,3,30,24,0,24,24
                    db 0,60,74,86,94,64,60,0,28,54,99,127,99,99,102,0
                    db 94,119,99,126,99,119,94,0,30,51,96,96,96,51,30,0
                    db 124,102,99,99,99,102,124,0,63,115,96,126,96,115,63,0
                    db 127,99,96,124,96,96,96,0,62,99,96,111,99,103,61,0
                    db 99,99,99,127,115,99,99,0,126,90,24,24,24,90,126,0
                    db 63,6,3,3,99,54,28,0,99,102,108,124,110,103,99,0
                    db 112,96,96,96,96,99,127,0,118,127,107,107,107,99,102,0
                    db 110,63,51,51,51,51,115,2,28,54,99,99,99,54,28,0
                    db 126,51,51,126,48,48,120,0,28,54,99,99,109,54,27,1
                    db 126,99,99,126,108,102,99,0,62,99,96,62,3,99,62,0
                    db 255,153,24,24,24,24,60,0,115,51,99,99,99,103,61,0
                    db 99,99,99,99,119,62,28,8,99,99,107,107,107,127,54,0
                    db 99,119,62,28,62,119,99,0,115,51,99,63,3,99,62,0
                    db 127,71,14,28,56,115,127,0,0,14,8,8,8,8,14,0
                    db 0,0,64,32,16,8,4,0,0,112,16,16,16,16,112,0
                    db 0,16,56,84,16,16,16,0,0,0,0,0,0,0,0,255
                    db 0,28,34,120,32,32,126,0,0,0,62,3,63,99,63,0
                    db 48,96,110,115,99,99,126,0,0,0,62,99,96,99,62,0
                    db 7,3,59,103,99,99,63,0,0,0,62,99,126,96,62,0
                    db 14,24,127,24,24,24,24,48,0,0,62,99,99,63,3,126
                    db 96,96,126,99,99,99,102,0,24,0,56,24,24,24,126,0
                    db 12,0,14,7,3,3,102,60,96,96,99,102,124,102,99,0
                    db 56,24,48,48,48,60,24,0,0,0,118,127,107,107,99,2
                    db 0,0,110,59,51,51,115,2,0,0,62,99,99,99,62,0
                    db 0,0,126,51,51,126,48,120,0,0,62,102,102,110,54,7
                    db 0,0,110,51,48,48,120,0,0,0,62,96,62,3,126,0
                    db 0,48,126,48,48,51,30,0,0,0,115,51,99,99,63,0
                    db 0,0,99,99,54,28,8,0,0,0,99,107,107,127,54,0
                    db 0,0,99,54,28,54,99,0,0,0,115,51,99,63,3,62
                    db 0,0,127,70,28,49,127,0,0,14,8,48,8,8,14,0
                    db 0,8,8,8,8,8,8,0,0,112,16,12,16,16,112,0
                    db 0,20,40,0,0,0,0,0,60,66,153,161,161,153,66,60
DIBcharfontsizeof   equ  $-DIBcharfont

.code

