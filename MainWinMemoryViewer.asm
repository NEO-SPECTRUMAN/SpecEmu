
ToggleMainWinMemViewDialog  PROTO
ShowMainWinMemViewDialog    PROTO
HideMainWinMemViewDialog    PROTO
MainWinMemViewDialogProc    PROTO   :DWORD,:DWORD,:DWORD,:DWORD

MW_Populate_Memory          PROTO

SCRRANGE_MIN        =       0
SCRRANGE_MAX        =       4080

.data?
MW_MemScrollBarInfo         SCROLLINFO <?>

MW_MemoryScrollBarhWnd      dd      ?
MW_MemoryListBoxhWnd        dd      ?
MW_MemoryView_TopAddr       dw      ?

.data
MainWinMemViewName          db      "MainWinMemoryViewerWindow", 0

MainWinMemView_Enabled      db  FALSE
.code

ToggleMainWinMemViewDialog  proc
                            .if     MainWinMemView_Enabled == TRUE
                                    invoke  HideMainWinMemViewDialog
                            .else
                                    invoke  ShowMainWinMemViewDialog
                            .endif
                            ret
ToggleMainWinMemViewDialog  endp

ShowMainWinMemViewDialog    proc
                            .if     FullScreenMode == FALSE
                                    mov     MainWinMemView_Enabled, TRUE
                                    invoke  ShowWindow, MW_MemViewDlg, SW_SHOW
                            .endif
                            ret
ShowMainWinMemViewDialog    endp

HideMainWinMemViewDialog    proc
                            mov     MainWinMemView_Enabled, FALSE
                            invoke  ShowWindow, MW_MemViewDlg, SW_HIDE
                            ret
HideMainWinMemViewDialog    endp


MainWinMemViewDialogProc    proc    uses        ebx esi edi,
                                    hWndDlg:    DWORD,
                                    uMsg:       DWORD,
                                    wParam:     DWORD,
                                    lParam:     DWORD

                            local   WinRect:    RECT

                            local   wParamLow:      WORD,
                                    wParamHigh:     WORD,
                                    UpdateMemPosn:  BOOL

                    mov     eax, wParam
                    mov     wParamLow, ax
                    shr     eax, 16
                    mov     wParamHigh, ax

                    RESETMSG

OnInitDialog
                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr MainWinMemViewName, SADD ("_X")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     esi, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr MainWinMemViewName, SADD ("_Y")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     edi, eax

                    .if     (esi != -1) && (edi != -1)
                            invoke  SetWindowPos, hWndDlg, NULL, esi, edi, 0, 0, SWP_NOOWNERZORDER or SWP_NOSIZE or SWP_NOZORDER
                    .endif

                    mov     MW_MemoryScrollBarhWnd, $fnc (GetDlgItem, hWndDlg, IDC_MAINWINMEMORYSCB)
                    mov     MW_MemoryListBoxhWnd,   $fnc (GetDlgItem, hWndDlg, IDC_MAINWINMEMORYLST)

                    SETNEWWINDOWFONT    MW_MemoryListBoxhWnd, Courier_New_9, MW_MemoryListFont, MW_MemoryListOldFont

                    invoke  SendMessage, MW_MemoryListBoxhWnd, RT_SELECTENABLE, FALSE, 0

                    mov     MW_MemScrollBarInfo.SCROLLINFO.cbSize, sizeof SCROLLINFO
                    mov     MW_MemScrollBarInfo.SCROLLINFO.fMask,  SIF_POS or SIF_RANGE
                    mov     MW_MemScrollBarInfo.SCROLLINFO.nPage,  1
                    mov     MW_MemScrollBarInfo.SCROLLINFO.nMin,   0
                    mov     MW_MemScrollBarInfo.SCROLLINFO.nMax,   SCRRANGE_MAX
                    mov     MW_MemScrollBarInfo.SCROLLINFO.nPos,   0
                    invoke  SetScrollInfo, MW_MemoryScrollBarhWnd, SB_CTL, addr MW_MemScrollBarInfo, TRUE

                    invoke  MW_Populate_Memory

                    return  TRUE

;OnCommand
;                    return  TRUE

OnShowWindow
                    invoke  MW_Populate_Memory
                    return  TRUE

OnClose
                    invoke  HideMainWinMemViewDialog

OnActivate
                    .if     $LowWord (wParam) != WA_INACTIVE
                            CLEARSOUNDBUFFERS
                    .endif
                    return  TRUE

OnVScroll
                    switch  lParam
                            case    MW_MemoryScrollBarhWnd
                                    invoke  GetScrollInfo, MW_MemoryScrollBarhWnd, SB_CTL, addr MW_MemScrollBarInfo
                                    mov     ecx, MW_MemScrollBarInfo.SCROLLINFO.nPos
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
                                            mov     MW_MemScrollBarInfo.SCROLLINFO.nPos, ecx
                                            shl     cx, 4
                                            mov     MW_MemoryView_TopAddr, cx
                                            invoke  SetScrollInfo, MW_MemoryScrollBarhWnd, SB_CTL, addr MW_MemScrollBarInfo, TRUE
                                            invoke  MW_Populate_Memory
                                    .endif
    
                                  ; if an application processes this message, it should return zero
                                    return  0
                    endsw

OnMouseWheel
                    .if     $fnc (IsWindowEnabled, MW_MemoryScrollBarhWnd) != 0
                            mov     bx, $HighWord (wParam)
                            mov     esi, SB_LINEUP
                            test    bx, bx
                            .if     SIGN?
                                    neg     bx
                                    mov     esi, SB_LINEDOWN
                            .endif
    
                            .while  bx >= WHEEL_DELTA
                                    invoke  SendMessage, hWndDlg, WM_VSCROLL, esi, MW_MemoryScrollBarhWnd
                                    sub     bx, WHEEL_DELTA
                            .endw
                    .endif
    
                    return  TRUE

OnDestroy
                    SETOLDWINDOWFONT    MW_MemoryListBoxhWnd, MW_MemoryListFont, MW_MemoryListOldFont

                    invoke  GetWindowRect, hWndDlg, addr WinRect

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr MainWinMemViewName, SADD ("_X")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.left

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr MainWinMemViewName, SADD ("_Y")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.top

                    return  NULL

OnDefault
                    return  FALSE

                    DOMSG

                    ret

MainWinMemViewDialogProc    endp


MW_Populate_Memory  proc    uses    esi edi ebx

                    local   IDC_MEMORYLSThWnd:  DWORD
                    local   MemViewOrg:         WORD

                    local   textstring:         TEXTSTRING,
                            pTEXTSTRING:        DWORD

                    ifc     MainWinMemView_Enabled eq FALSE then ret

                    mov     IDC_MEMORYLSThWnd, $fnc (GetDlgItem, MW_MemViewDlg, IDC_MAINWINMEMORYLST)

                    mov     ax, MW_MemoryView_TopAddr
                    mov     MemViewOrg, ax

                    invoke  SendMessage, IDC_MEMORYLSThWnd, RT_CLEAREOL,     FALSE, 0
                    invoke  SendMessage, IDC_MEMORYLSThWnd, WM_SETREDRAW,    FALSE, 0
                    invoke  SendMessage, IDC_MEMORYLSThWnd, RT_RESETCONTENT, 0, 0

                    SETLOOP 16
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            invoke  PrtBase16, pTEXTSTRING, MemViewOrg, ATD_SPACES
                            ADDCHAR pTEXTSTRING, ":", " "

                            SETLOOP 16
                                    mov     bx, MemViewOrg
                                    call    MemGetByte  ; al = byte

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
                    invoke  UpdateWindow,   IDC_MEMORYLSThWnd
                    ret

MW_Populate_Memory  endp




