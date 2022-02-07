
GetBreakpointStruct     PROTO   :DWORD

DebugBreakpointsDlgProc proc   uses    ebx esi edi,
                        hWndDlg     :DWORD,
                        uMsg        :DWORD,
                        wParam      :DWORD,
                        lParam      :DWORD

                        local       brkitem:     DWORD
                        local       buffer1[32]: BYTE


                invoke  HandleCustomWindowMessages, addr BreakpointsDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set menu ID on main debugger window's menu
                mov     BreakpointsDLG.Menu_ID, IDM_VIEW_BREAKPOINTS

                invoke  SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTEDT, EM_SETLIMITTEXT, 5, 0

                invoke  PopulateBrkListbox
                return  TRUE

OnShowWindow
                invoke  PopulateBrkListbox
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                return  NULL

OnCommand
                switch  wParam
                        case    $WPARAM (RTN_SELCHANGE, IDC_BREAKPOINTSLST)
                                ; enable the "Remove" and "Enable" buttons
                                .if     $fnc (SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETCURSEL, 0, 0) != RT_ERR
                                        mov     brkitem, eax
                                        invoke  EnableWindow, $fnc (GetDlgItem, BreakpointsDLG.hWnd, IDC_REMOVEBREAKPOINT), TRUE
                                        invoke  EnableWindow, $fnc (GetDlgItem, BreakpointsDLG.hWnd, IDC_ENABLEBREAKPOINT), TRUE

                                        invoke  GetBreakpointStruct, brkitem
                                        .if     [eax].TBREAKPOINT.Enabled == TRUE
                                                mov     ebx, CTXT ("Disable")
                                        .else
                                                mov     ebx, CTXT ("Enable")
                                        .endif
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_ENABLEBREAKPOINT, WM_SETTEXT, 0, ebx
                                .endif

                        case    $WPARAM (RTN_DBLCLK, IDC_BREAKPOINTSLST)
                                .if     $fnc (SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETCURSEL, 0, 0) != RT_ERR
                                        mov     ebx, eax
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETTEXT, ebx, addr buffer1
                                        invoke  StringToDWord, addr buffer1+2, addr lpTranslated    ; first 2 string bytes hold colour control codes
                                        invoke  SetNewZ80PC, ax
                                .endif

                        case    $WPARAM (BN_CLICKED, IDC_ENABLEBREAKPOINT)
                                .if     $fnc (SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETCURSEL, 0, 0) != RT_ERR
                                        invoke  GetBreakpointStruct, eax
                                        xor     [eax].TBREAKPOINT.Enabled, TRUE
                                        invoke  PopulateBrkListbox
                                        invoke  UpdateDisassembly   ; update breakpoints in the disassembly window
                                .endif

                        case    $WPARAM (BN_CLICKED, IDC_REMOVEBREAKPOINT)
                                .if     $fnc (SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETCURSEL, 0, 0) != RT_ERR
                                        mov     ebx, eax
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTSLST, RT_GETTEXT, ebx, addr buffer1
                                        invoke  StringToDWord, addr buffer1+2, addr lpTranslated    ; first 2 string bytes hold colour control codes
                                        invoke  RemoveBreakpoint, ax
                                        invoke  UpdateDisassembly   ; remove the highlighted breakpoint in the disassembly window
                                .endif

                        case    $WPARAM (BN_CLICKED, IDC_REMOVEALLBREAKPOINTS)
                                        invoke  ClearBreakpoints
                                        invoke  UpdateDisassembly   ; remove highlighted breakpoints in the disassembly window

                        case    $WPARAM (BN_CLICKED, IDC_ADDBREAKPOINT)
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTEDT, WM_GETTEXT, sizeof buffer1, addr buffer1
                                        invoke  StringToDWord, addr buffer1, addr lpTranslated
                                        .if     (lpTranslated == TRUE) && (eax >= 0) && (eax <= 65535)
                                                invoke  AddBreakpoint, ax
                                                invoke  SendDlgItemMessage, hWndDlg, IDC_BREAKPOINTEDT, WM_SETTEXT, 0, addr NULL_String
                                                invoke  UpdateDisassembly   ; update highlighted breakpoints in the disassembly window
                                        .endif

                endsw

                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugBreakpointsDlgProc endp

GetBreakpointStruct proc    item:   DWORD

                    lea     eax, BreakPoints
                    .while  item > 0
                            add     eax, sizeof TBREAKPOINT
                            dec     item
                    .endw
                    ret

GetBreakpointStruct endp

PopulateBrkListbox  proc    uses esi ebx

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     BreakpointsDLG.Visible == TRUE

                            invoke  SendDlgItemMessage, BreakpointsDLG.hWnd, IDC_BREAKPOINTSLST, WM_SETREDRAW, FALSE, 0
                            invoke  SendDlgItemMessage, BreakpointsDLG.hWnd, IDC_BREAKPOINTSLST, RT_RESETCONTENT, 0, 0

                            lea     esi, BreakPoints
                            mov     ebx, MAXBREAKPOINTS

                    @@:     .if     dword ptr [esi].TBREAKPOINT.PC != -1
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                                    ; first 2 string bytes hold colour control codes
                                    ADDCHAR pTEXTSTRING, RTCTL_PAPER
                                    .if     [esi].TBREAKPOINT.Enabled == TRUE
                                            ADDCHAR pTEXTSTRING, RTCOL_SYSCOLOR
                                    .else
                                            ADDCHAR pTEXTSTRING, RTCOL_RED
                                    .endif

                                    mov     eax, [esi].TBREAKPOINT.PC
                                    invoke  PrtBase16, pTEXTSTRING, ax, 0

                                    invoke  SendDlgItemMessage, BreakpointsDLG.hWnd, IDC_BREAKPOINTSLST, RT_ADDSTRING, 0, addr textstring
                            .endif

                            add     esi, sizeof TBREAKPOINT
                            dec     ebx
                            jnz     @B

                            invoke  SendDlgItemMessage, BreakpointsDLG.hWnd, IDC_BREAKPOINTSLST, WM_SETREDRAW, TRUE, 0
                            invoke  InvalidateRect,     BreakpointsDLG.hWnd, NULL, TRUE

                            ; the "Remove" and "Enable" buttons are disabled each time the breakpoint listbox updates
                            invoke  EnableWindow, $fnc (GetDlgItem, BreakpointsDLG.hWnd, IDC_REMOVEBREAKPOINT), FALSE
                            invoke  EnableWindow, $fnc (GetDlgItem, BreakpointsDLG.hWnd, IDC_ENABLEBREAKPOINT), FALSE
                    .endif
                    ret

PopulateBrkListbox  endp
