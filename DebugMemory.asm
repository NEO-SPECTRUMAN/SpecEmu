
;PopulateMemoryDlg   PROTO   ; now in SpecEmu.inc
;Populate_Stack      PROTO
;Populate_Memory     PROTO
;SetMemoryViewAddr   PROTO   :WORD

SCRRANGE_MIN        =       0
SCRRANGE_MAX        =       4080

.data?
MemScrollBarInfo    SCROLLINFO <?>

MemViewMenuHandle   dd      ?

MemoryScrollBarhWnd dd      ?
StackListBoxhWnd    dd      ?
MemoryListBoxhWnd   dd      ?

MemoryView_TopAddr  dw      ?

.data
                    ; equates for memory viewer tracking modes
                    RESETENUM   0
                    ENUM    MEMTRACK_NONE, MEMTRACK_READS, MEMTRACK_WRITES

MemView_TrackType   db      MEMTRACK_NONE

.code
DebugMemoryDlgProc proc uses    ebx esi edi,
                        hWndDlg:        DWORD,
                        uMsg:           DWORD,
                        wParam:         DWORD,
                        lParam:         DWORD

                local   wParamLow:      WORD,
                        wParamHigh:     WORD,
                        UpdateMemPosn:  BOOL

                invoke  HandleCustomWindowMessages, ADDR MemoryDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                mov     eax, wParam
                mov     wParamLow, ax
                shr     eax, 16
                mov     wParamHigh, ax

                RESETMSG

OnInitDialog
                ; set menu ID on main debugger window's menu
                mov     MemoryDLG.Menu_ID, IDM_VIEW_MEMORY

                mov     MemoryScrollBarhWnd, $fnc (GetDlgItem, hWndDlg, IDC_MEMORYSCB)
                mov     StackListBoxhWnd,    $fnc (GetDlgItem, hWndDlg, IDC_STACKLST)
                mov     MemoryListBoxhWnd,   $fnc (GetDlgItem, hWndDlg, IDC_MEMORYLST)

                SETNEWWINDOWFONT    StackListBoxhWnd,  Courier_New_9, StackListFont,  StackListOldFont
                SETNEWWINDOWFONT    MemoryListBoxhWnd, Courier_New_9, MemoryListFont, MemoryListOldFont

                invoke  SendMessage, MemoryListBoxhWnd, RT_SELECTENABLE, FALSE, 0

                mov     MemScrollBarInfo.SCROLLINFO.cbSize, sizeof SCROLLINFO
                mov     MemScrollBarInfo.SCROLLINFO.fMask,  SIF_POS or SIF_RANGE
                mov     MemScrollBarInfo.SCROLLINFO.nPage,  1
                mov     MemScrollBarInfo.SCROLLINFO.nMin,   0
                mov     MemScrollBarInfo.SCROLLINFO.nMax,   SCRRANGE_MAX
                mov     MemScrollBarInfo.SCROLLINFO.nPos,   0
                invoke  SetScrollInfo, MemoryScrollBarhWnd, SB_CTL, addr MemScrollBarInfo, TRUE

                mov     MemViewMenuHandle,  $fnc (LoadMenu, GlobalhInst, IDR_MEMORYVIEWERMENU)
                invoke  SendDlgItemMessage, hWndDlg, IDC_MEMORYLST, RT_SETMENU, 0, $fnc (GetSubMenu, MemViewMenuHandle, 0)

                invoke  PopulateMemoryDlg
                return  TRUE

OnShowWindow
                invoke  PopulateMemoryDlg
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                SETOLDWINDOWFONT    StackListBoxhWnd,  StackListFont,  StackListOldFont
                SETOLDWINDOWFONT    MemoryListBoxhWnd, MemoryListFont, MemoryListOldFont
                invoke  DestroyMenu, MemViewMenuHandle
                return  NULL

OnCommand
                switch  wParam
                        case    $WPARAM (RTN_DBLCLK, IDC_STACKLST)
                                invoke  SendDlgItemMessage, MemoryDLG.hWnd, IDC_STACKLST, RT_GETCURSEL, 0, 0
                                .if     eax != RT_ERR
                                        mov     bx, z80registers._sp
                                        add     ax, ax
                                        add     bx, ax
                                        call    MemGetWord
                                        mov     Z80PC, ax
                                        invoke  UpdateDebugger
                                .endif

                        case    $WPARAM (RTN_ENTERMENULOOP, IDC_MEMORYLST)
                                invoke  MutualExcludeMenuItems, MemViewMenuHandle, IDM_MEMVIEW_TRACK_NONE, IDM_MEMVIEW_TRACK_MEMWRITES, ZeroExt (MemView_TrackType)

                        case    $WPARAM (RTN_EXITMENULOOP,  IDC_MEMORYLST)

                        case    $WPARAM (RTN_MENUITEM,      IDC_MEMORYLST)
                                switch  lParam
                                        case    IDM_MEMVIEW_TRACK_NONE..IDM_MEMVIEW_TRACK_MEMWRITES
                                                sub     eax, IDM_MEMVIEW_TRACK_NONE
                                                mov     MemView_TrackType, al
                                                invoke  PopulateMemoryDlg
                                endsw
                endsw

                return  TRUE

OnVScroll
                switch  lParam
                        case    MemoryScrollBarhWnd
                                invoke  GetScrollInfo, MemoryScrollBarhWnd, SB_CTL, addr MemScrollBarInfo
                                mov     ecx, MemScrollBarInfo.SCROLLINFO.nPos
                                mov     UpdateMemPosn, TRUE

                                switch  wParamLow
                                        case    SB_PAGEUP
                                                sub     ecx, 16
                                        case    SB_PAGEDOWN
                                                add     ecx, 16
                                        case    SB_LINEUP
                                                dec     ecx
                                        case    SB_LINEDOWN
                                                inc     ecx
                                        case    SB_TOP
                                                xor     ecx, ecx
                                        case    SB_BOTTOM
                                                mov     ecx, SCRRANGE_MAX
                                        case    SB_THUMBTRACK
                                                movzx   ecx, wParamHigh
                                        .else
                                                mov     UpdateMemPosn, FALSE
                                endsw

                                .if     (UpdateMemPosn == TRUE) && (ecx <= SCRRANGE_MAX)
                                        mov     MemScrollBarInfo.SCROLLINFO.nPos, ecx
                                        shl     cx, 4
                                        mov     MemoryView_TopAddr, cx
                                        invoke  SetScrollInfo, MemoryScrollBarhWnd, SB_CTL, addr MemScrollBarInfo, TRUE
                                        invoke  Populate_Memory
                                .endif

                              ; if an application processes this message, it should return zero
                                return  0
                endsw

OnMouseWheel
                .if     $fnc (IsWindowEnabled, MemoryScrollBarhWnd) != 0
                        mov     bx, $HighWord (wParam)
                        mov     esi, SB_LINEUP
                        test    bx, bx
                        .if     SIGN?
                                neg     bx
                                mov     esi, SB_LINEDOWN
                        .endif

                        .while  bx >= WHEEL_DELTA
                                invoke  SendMessage, hWndDlg, WM_VSCROLL, esi, MemoryScrollBarhWnd
                                sub     bx, WHEEL_DELTA
                        .endw
                .endif

                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugMemoryDlgProc endp

; this procedure must NOT redraw the memory control. it's called from within Populate_Memory!!

SetMemoryViewAddr   proc    newaddr:    WORD

                    invoke  GetScrollInfo, MemoryScrollBarhWnd, SB_CTL, addr MemScrollBarInfo

                    movzx   ecx, newaddr
                    and     ecx, 0FFF0h
                    .if     ecx > 0FFF0h
                            mov     ecx, 0FFF0h
                    .endif
                    mov     MemoryView_TopAddr, cx
                    shr     ecx, 4
                    mov     MemScrollBarInfo.SCROLLINFO.nPos, ecx

                    invoke  SetScrollInfo, MemoryScrollBarhWnd, SB_CTL, addr MemScrollBarInfo, TRUE
                    ret
SetMemoryViewAddr   endp

PopulateMemoryDlg   proc    uses    esi edi ebx

                    .if     MemoryDLG.Visible == TRUE
                            invoke  Populate_Stack
                            invoke  Populate_Memory

                            ifc     MemView_TrackType eq 0 then mov eax, TRUE else mov eax, FALSE
                            invoke  EnableWindow, MemoryScrollBarhWnd, eax
                    .endif
                    ret
PopulateMemoryDlg   endp

Populate_Stack      proc    uses    esi edi ebx

                    local   IDC_STACKLSThWnd:   DWORD

                    local   z80_SP: WORD

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    mov     IDC_STACKLSThWnd, $fnc (GetDlgItem, MemoryDLG.hWnd, IDC_STACKLST)

                    invoke  SendMessage, IDC_STACKLSThWnd, WM_SETREDRAW, FALSE, 0
                    invoke  SendMessage, IDC_STACKLSThWnd, RT_RESETCONTENT, 0, 0

                    mov     ax, z80registers._sp
                    mov     z80_SP, ax

                    SETLOOP 16
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                            .if     dword ptr [esp] == 16   ; first item?
                                    ADDCHAR pTEXTSTRING, "S", "P", ":", " "
                            .else
                                    ADDCHAR pTEXTSTRING, " ", " ", " ", " "
                            .endif
                            mov     bx, z80_SP
                            call    MemGetWord

                            invoke  PrtBase16, pTEXTSTRING, ax, ATD_SPACES
                            ADDCHAR pTEXTSTRING, " ", " "
                            invoke  SendMessage, IDC_STACKLSThWnd, RT_ADDSTRING, 0, addr textstring

                            add     z80_SP, 2
                    ENDLOOP

                    invoke  SendMessage, IDC_STACKLSThWnd, RT_SETCURSEL, 0, 0
                    invoke  SendMessage, IDC_STACKLSThWnd, WM_SETREDRAW, TRUE, 0

                    invoke  InvalidateRect, IDC_STACKLSThWnd, NULL, TRUE
                    ret

Populate_Stack      endp

Populate_Memory     proc    uses    esi edi ebx

                    local   IDC_MEMORYLSThWnd:  DWORD

                    local   MemViewOrg:         WORD

                    local   comp_addr_1:        WORD,
                            comp_addr_2:        WORD,
                            check_comp_1:       BOOL,
                            check_comp_2:       BOOL,
                            highlight_paper:    BYTE,
                            highlighted_flag:   BOOL

                    local   textstring:         TEXTSTRING,
                            pTEXTSTRING:        DWORD

                    mov     check_comp_1, FALSE
                    mov     check_comp_2, FALSE

                    mov     IDC_MEMORYLSThWnd, $fnc (GetDlgItem, MemoryDLG.hWnd, IDC_MEMORYLST)

                    switch  MemView_TrackType
                            case    MEMTRACK_READS, MEMTRACK_WRITES
                                    .if     MemView_TrackType == MEMTRACK_READS
                                            mov     highlight_paper, RTCOL_CYAN
                                            mov     bl, MemoryReadEvent
                                            mov     si, MemoryReadAddress
                                    .else
                                            mov     highlight_paper, RTCOL_GREEN
                                            mov     bl, MemoryWriteEvent
                                            mov     si, MemoryWriteAddress
                                    .endif

                                    .if     bl != MEMACCESSNONE
                                            mov     cx, si
                                            mov     comp_addr_1, cx
                                            and     cx, 0FFF0h
                                            sub     cx, 128-16
                                            mov     check_comp_1, TRUE

                                            invoke  SetMemoryViewAddr, cx

                                            ; high byte can only be valid if the low byte was
                                            .if     bl == MEMACCESSWORD
                                                    mov     cx, si
                                                    inc     cx
                                                    mov     comp_addr_2, cx
                                                    mov     check_comp_2, TRUE
                                            .endif
                                    .endif
                    endsw

                    mov     ax, MemoryView_TopAddr
                    mov     MemViewOrg, ax

                    invoke  SendMessage, IDC_MEMORYLSThWnd, RT_CLEAREOL,     FALSE, 0
                    invoke  SendMessage, IDC_MEMORYLSThWnd, WM_SETREDRAW,    FALSE, 0
                    invoke  SendMessage, IDC_MEMORYLSThWnd, RT_RESETCONTENT, 0, 0

                    SETLOOP 16
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                            invoke  PrtBase16, pTEXTSTRING, MemViewOrg, ATD_SPACES
                            ADDCHAR pTEXTSTRING, ":", " "

                            mov     highlighted_flag, FALSE

                            SETLOOP 16
                                    mov     bx, MemViewOrg
                                    call    MemGetByte  ; al = byte

                                    .if     check_comp_1 == TRUE
                                            .if     bx == comp_addr_1
                                                    push    eax
                                                    ADDCHAR pTEXTSTRING, RTCTL_PAPER
                                                    mov     al, highlight_paper
                                                    ADDCHAR pTEXTSTRING, al
                                                    mov     highlighted_flag, TRUE
                                                    pop     eax
                                            .endif
                                    .endif

                                    .if     check_comp_2 == TRUE
                                            .if     bx == comp_addr_2
                                                    push    eax
                                                    ADDCHAR pTEXTSTRING, RTCTL_PAPER
                                                    mov     al, highlight_paper
                                                    ADDCHAR pTEXTSTRING, al
                                                    mov     highlighted_flag, TRUE
                                                    pop     eax
                                            .endif
                                    .endif

                                    .if     ShowOpsAsAscii ==TRUE
                                            .if     (al < 32) || (al > 127)
                                                    mov     al, "."
                                            .endif
                                            ADDCHAR pTEXTSTRING, al
                                            mov     bl, 2   ; 2 spaces
                                    .else
                                            ADDTEXTHEX  pTEXTSTRING, al
                                            mov     bl, 1   ; 1 space
                                    .endif

                                    .if     highlighted_flag == TRUE
                                            ADDCHAR pTEXTSTRING, RTCTL_PAPER
                                            ADDCHAR pTEXTSTRING, RTCOL_SYSCOLOR
                                            mov     highlighted_flag, FALSE
                                    .endif

                                    .while  bl > 0
                                            ADDCHAR pTEXTSTRING, " "
                                            dec     bl
                                    .endw

                                    inc     MemViewOrg
                            ENDLOOP

                            invoke  SendMessage, IDC_MEMORYLSThWnd, RT_ADDSTRING, 0, addr textstring
                    ENDLOOP

                    invoke  SendMessage,    IDC_MEMORYLSThWnd, WM_SETREDRAW, TRUE, 0
                    invoke  InvalidateRect, IDC_MEMORYLSThWnd, NULL, TRUE
                    ret

Populate_Memory     endp



