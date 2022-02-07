
HandleCustomWindowMessages  PROTO   :PTR TDEBUGDIALOG,:DWORD,:DWORD,:DWORD,:DWORD

; user-defined messages passed between dialogs
    ; wParam of WM_COMMAND for all private messages
    WPARAM_USER         equ     -1

; list of lParam values of WM_COMMAND for private messages
    ; standard window behaviour messages for all dialogs
    LP_SETSHOWSTATE     equ     0
    LP_SHOWWINDOW       equ     1
    LP_HIDEWINDOW       equ     2
    LP_TOGGLESHOWSTATE  equ     3
    LP_LOADSTATE        equ     4
    LP_SAVESTATE        equ     5

    ; dialog specific messages
    LP_USERFIND         equ     10


HandleCustomWindowMessages  PROTO   :PTR TDEBUGDIALOG,:DWORD,:DWORD,:DWORD

.code

GetWindowSize   proc    uses        ebx,
                        hWin:       DWORD,
                        lpTWINSIZE: PTR TWINSIZE

                mov     ebx, lpTWINSIZE
                ASSUME  ebx: PTR TWINSIZE
                invoke  GetWindowRect, hWin, ADDR [ebx].WRect
                .if     eax != 0
                        mov     [ebx].WWidth,  _SUB ([ebx].WRect.right, [ebx].WRect.left)
                        mov     [ebx].WHeight, _SUB ([ebx].WRect.bottom, [ebx].WRect.top)
                        mov     eax, 1  ; non-zero = success
                .endif
                ret

GetWindowSize   endp

; handles custom window messages for debugger's external dialogs
; returns TRUE if caller should exit immediately upon return
; returns FALSE if caller handles default message processing

HandleCustomWindowMessages  proc    uses        ebx esi edi,
                                    hDialog:    PTR  TDEBUGDIALOG,
                                    hWndDlg:    DWORD,
                                    uMsg:       DWORD,
                                    wParam:     DWORD,
                                    lParam:     DWORD

    mov     ebx, hDialog
    ASSUME  ebx: PTR  TDEBUGDIALOG

    RESETMSG

OnInitDialog
            .if     [ebx].IsInitWinSize == FALSE
                    mov     [ebx].IsInitWinSize, TRUE
                    invoke  GetWindowSize, hWndDlg, ADDR [ebx].WinSize
            .else
                    invoke  MoveWindow, hWndDlg, [ebx].WinSize.WRect.left, [ebx].WinSize.WRect.top,
                                        [ebx].WinSize.WWidth, [ebx].WinSize.WHeight, TRUE
            .endif
            return  FALSE

OnMove
            invoke  GetWindowSize, hWndDlg, ADDR [ebx].WinSize
            return  TRUE

OnClose
            invoke  SendMessage, hWndDlg, WM_COMMAND, WPARAM_USER, LP_HIDEWINDOW
            invoke  SetFocus, Debugger_hWnd
            ; caller handles additional cleanup
            return  FALSE

OnCommand
            .if     wParam == IDCANCEL
                    invoke  SendMessage, [ebx].hWnd, WM_COMMAND, WPARAM_USER, LP_HIDEWINDOW
                    return  TRUE

            .elseif wParam == WPARAM_USER
                    switch  lParam
                        case    LP_SETSHOWSTATE
                                .if     [ebx].Visible == TRUE
                                        mov     eax, LP_SHOWWINDOW
                                .else
                                        mov     eax, LP_HIDEWINDOW
                                .endif
                                invoke  SendMessage, [ebx].hWnd, WM_COMMAND, WPARAM_USER, eax
                                return  TRUE

                        case    LP_SHOWWINDOW
                                mov     [ebx].Visible, TRUE
                                invoke  ShowWindow, [ebx].hWnd, SW_SHOW
                                invoke  CheckMenuItem, DebugMenuHandle, [ebx].Menu_ID, MF_CHECKED or MF_BYCOMMAND
                                return  TRUE

                        case    LP_HIDEWINDOW
                                mov     [ebx].Visible, FALSE
                                invoke  ShowWindow, [ebx].hWnd, SW_HIDE
                                invoke  CheckMenuItem, DebugMenuHandle, [ebx].Menu_ID, MF_UNCHECKED or MF_BYCOMMAND
                                return  TRUE

                        case    LP_TOGGLESHOWSTATE
                                xor     [ebx].Visible, TRUE
                                invoke  SendMessage, [ebx].hWnd, WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
                                return  TRUE

                        case    LP_LOADSTATE
                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_Visible")
                                invoke  ReadProfileInt,  addr DummyMem, 0
                                mov     [ebx].Visible, al

                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_X")
                                invoke  ReadProfileInt,  addr DummyMem, -1
                                mov     esi, eax

                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_Y")
                                invoke  ReadProfileInt,  addr DummyMem, -1
                                mov     edi, eax

                                .if     (esi != -1) && (edi != -1)
                                        mov     [ebx].WinSize.WRect.left, esi
                                        mov     [ebx].WinSize.WRect.top,  edi
                                        invoke  MoveWindow, [ebx].hWnd, esi, edi,
                                                            [ebx].WinSize.WWidth, [ebx].WinSize.WHeight, TRUE
                                .endif

                        case    LP_SAVESTATE
                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_Visible")
                                invoke  WriteProfileInt, addr DummyMem, ZeroExt ([ebx].Visible)

                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_X")
                                invoke  WriteProfileInt, addr DummyMem, ([ebx].WinSize.WRect.left)

                                mov     DummyMem, 0
                                strcat  addr DummyMem, [ebx].lpName, SADD ("_Y")
                                invoke  WriteProfileInt, addr DummyMem, ([ebx].WinSize.WRect.top)

                    endsw
            .endif

    ; caller continues to process messages
OnDefault
    return  FALSE

    DOMSG

    ASSUME  ebx: NOTHING

HandleCustomWindowMessages  endp


