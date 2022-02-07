
PopulatePCHistoryDlg    PROTO
PopulatePCHistory       PROTO

.data?
PCHistoryListboxhWnd    dd  ?

.code

DebugPCHistoryDlgProc proc   uses    ebx esi edi,
                        hWndDlg     :DWORD,
                        uMsg        :DWORD,
                        wParam      :DWORD,
                        lParam      :DWORD

                local   num_buffer[128]: BYTE

                invoke  HandleCustomWindowMessages, ADDR PCHistoryDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set menu ID on main debugger window's menu
                mov     PCHistoryDLG.Menu_ID, IDM_VIEW_PC_HISTORY

                mov     PCHistoryListboxhWnd, $fnc (GetDlgItem, hWndDlg, IDC_PCHISTORYLST)

                SETNEWWINDOWFONT    PCHistoryListboxhWnd, Courier_New_9, PCHistoryListFont,  PCHistoryListOldFont

                invoke  PopulatePCHistoryDlg
                invoke  SendMessage, PCHistoryListboxhWnd, LB_SETCURSEL, 0, 0
                return  TRUE

OnShowWindow
                invoke  PopulatePCHistoryDlg
                invoke  SendMessage, PCHistoryListboxhWnd, LB_SETCURSEL, 0, 0
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                SETOLDWINDOWFONT    PCHistoryListboxhWnd,  PCHistoryListFont,  PCHistoryListOldFont
                return  NULL

OnCommand
                switch  wParam
                        case    $WPARAM (LBN_DBLCLK, IDC_PCHISTORYLST)
                                invoke  SendDlgItemMessage, hWndDlg, IDC_PCHISTORYLST, LB_GETCURSEL, 0, 0
                                .if     eax != LB_ERR
                                        mov     ebx, eax
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_PCHISTORYLST, LB_GETTEXT, ebx, addr num_buffer
                                        invoke  szTrim, addr num_buffer
                                        invoke  StringToDWord, addr num_buffer, addr lpTranslated
                                        .if     lpTranslated == TRUE
                                                mov     Z80PC, ax
                                                invoke  UpdateDebugger
                                        .endif
                                .endif
                endsw
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugPCHistoryDlgProc endp

PopulatePCHistoryDlg    proc    uses    esi edi ebx

                        ifc     PCHistoryDLG.Visible eq FALSE then ret

                        invoke  PopulatePCHistory

                        ret
PopulatePCHistoryDlg    endp

PopulatePCHistory   proc    uses    esi edi ebx

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    invoke  SendMessage, PCHistoryListboxhWnd, WM_SETREDRAW, FALSE, 0
                    invoke  SendMessage, PCHistoryListboxhWnd, LB_RESETCONTENT, 0, 0

                    mov     esi, PC_History._Offset

                    SETLOOP 256
                            mov     ebx, [PC_History.Table+esi*4]
                            ifc     ebx eq -1 then BREAKLOOP

                            sub     esi, 1
                            and     esi, 255

                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING 
                            invoke  PrtBase16,      pTEXTSTRING, bx, ATD_SPACES
                            invoke  SendMessage, PCHistoryListboxhWnd, LB_ADDSTRING, 0, addr textstring
                    ENDLOOP

                    invoke  SendMessage, PCHistoryListboxhWnd, WM_SETREDRAW, TRUE, 0

                    invoke  InvalidateRect, PCHistoryListboxhWnd, NULL, TRUE
                    ret

PopulatePCHistory   endp


