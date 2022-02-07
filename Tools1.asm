
Tools1DialogProc    PROTO   :DWORD, :DWORD, :DWORD, :DWORD
ToggleTools1Dialog  PROTO
ShowTools1Dialog    PROTO
HideTools1Dialog    PROTO
Tools1_MouseMove    PROTO   :DWORD,:DWORD,:DWORD

.data
Tools1_Enabled      db      FALSE

szFileListFilter    db      "*.szx;*.z80;*.sna;*.snx;*.sp;*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx;*.dsk;*.trd;*.scl;*.mgt;*.img;*.rom", 0,

ToolWindow1Name     db      "ToolWindow1", 0

.code

ToggleTools1Dialog  proc
                    .if     Tools1_Enabled == TRUE
                            invoke  HideTools1Dialog
                    .else
                            invoke  ShowTools1Dialog
                    .endif
                    ret
ToggleTools1Dialog  endp

ShowTools1Dialog    proc
                    .if     FullScreenMode == FALSE
                            invoke  ShowWindow, Tools1Dlg, SW_SHOW
                            mov     Tools1_Enabled, TRUE
                    .endif
                    ret
ShowTools1Dialog    endp

HideTools1Dialog    proc
                    invoke  ShowWindow, Tools1Dlg, SW_HIDE
                    mov     Tools1_Enabled, FALSE
                    ret
HideTools1Dialog    endp

align 16
Tools1_MouseMove    proc    uses        esi ebx,
                            hWin:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   ClientRect: RECT,
                            pixel_X:    DWORD,
                            pixel_Y:    DWORD,
                            scrbit:     DWORD,
                            attraddr:   WORD,
                            scraddr:    WORD

                    local   tools1_text:TEXTSTRING,
                            pTEXTSTRING:DWORD

                    ifc     Tools1_Enabled eq FALSE then ret

                    invoke  GetClientRect, hWin, addr ClientRect
                    mov     pixel_X,  @EVAL (ClientRect.right -  ClientRect.left / 320)                 ; pixel width
                    mov     pixel_Y,  @EVAL (ClientRect.bottom - ClientRect.top - ToolBarHeight  / 240) ; pixel height

                    movzx   edx, $LowWord (lParam)
                    mov     pixel_X,  @EVAL (edx / pixel_X)

                    movzx   edx, $HighWord (lParam)
                    sub     edx, ToolBarHeight
                    mov     pixel_Y, @EVAL (edx / pixel_Y)

                    invoke  SetDlgItemInt, Tools1Dlg, IDC_TOOLS1_ABS_MOUSEX, pixel_X, FALSE
                    invoke  SetDlgItemInt, Tools1Dlg, IDC_TOOLS1_ABS_MOUSEY, pixel_Y, FALSE

                    movzx   edx, MACHINE.TopBorderLines
                    mov     pixel_Y,  @EVAL (pixel_Y - edx) ; - top border pixels
                    mov     pixel_X,  @EVAL (pixel_X - 32)  ; - left border pixels

                    .if     (pixel_Y < 192) && (pixel_X < 256)
                            invoke  SetDlgItemInt, Tools1Dlg, IDC_TOOLS1_REL_MOUSEX, pixel_X, FALSE
                            invoke  SetDlgItemInt, Tools1Dlg, IDC_TOOLS1_REL_MOUSEY, pixel_Y, FALSE

                            lea     esi, DisplayTable
                            mov     edx, pixel_Y
                            mov     ecx, pixel_X
                            shr     ecx, 3
                            and     ecx, 31                 ; ecx = X char offset

                            mov     eax, [esi+edx*8+4]
                            add     eax, ecx
                            add     eax, 4000h
                            mov     attraddr, ax

                            mov     eax, [esi+edx*8]
                            add     eax, ecx
                            add     eax, 4000h
                            mov     scraddr, ax

                            mov     ecx, pixel_X
                            mov     eax, 7
                            and     ecx, eax                ; pixel_X and 7
                            sub     eax, ecx                ; 7 - (pixel_X and 7)
                            mov     scrbit, eax

                            invoke  INITTEXTSTRING, addr tools1_text, addr pTEXTSTRING
                            ADDTEXTDECIMAL  pTEXTSTRING, attraddr
                            ADDCHAR         pTEXTSTRING, " ", "[", "#"
                            ADDTEXTHEX      pTEXTSTRING, attraddr
                            ADDCHAR         pTEXTSTRING, "]"

                            ADDCHAR         pTEXTSTRING, ":", " "

                            mov     bx, attraddr
                            call    MemGetByte
                            mov     bl, al

                            ADDCHAR         pTEXTSTRING, "i", ":"
                            mov     al, bl
                            and     al, 7
                            ADDTEXTDECIMAL  pTEXTSTRING, al
                            ADDCHAR         pTEXTSTRING, " "

                            ADDCHAR         pTEXTSTRING, "p", ":"
                            mov     al, bl
                            shr     al, 3
                            and     al, 7
                            ADDTEXTDECIMAL  pTEXTSTRING, al
                            ADDCHAR         pTEXTSTRING, " "

                            ADDCHAR         pTEXTSTRING, "b", ":"
                            mov     al, bl
                            shr     al, 6
                            and     al, 1
                            ADDTEXTDECIMAL  pTEXTSTRING, al
                            ADDCHAR         pTEXTSTRING, " "

                            ADDCHAR         pTEXTSTRING, "f", ":"
                            mov     al, bl
                            shr     al, 7
                            and     al, 1
                            ADDTEXTDECIMAL  pTEXTSTRING, al

                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_ATTRIBUTEADDRESS, addr tools1_text

                            invoke  INITTEXTSTRING, addr tools1_text, addr pTEXTSTRING
                            ADDTEXTDECIMAL  pTEXTSTRING, scraddr
                            ADDCHAR         pTEXTSTRING, " ", "[", "#"
                            ADDTEXTHEX      pTEXTSTRING, scraddr
                            ADDCHAR         pTEXTSTRING, "]", ":", " "

                            mov     bx, scraddr
                            call    MemGetByte
                            mov     bl, al

                            mov     bh, 8
                        @@: shl     bl, 1
                            mov     al, "0"
                            adc     al, 0
                            ADDCHAR pTEXTSTRING, al
                            dec     bh
                            jnz     @B

                            ADDCHAR         pTEXTSTRING, ";", " ", "b", "i", "t", " "
                            ADDTEXTDECIMAL  pTEXTSTRING, scrbit
                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_DISPLAYADDRESS, addr tools1_text

                    .else
                            lea     esi, CTXT ("Border")
                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_DISPLAYADDRESS,   esi
                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_ATTRIBUTEADDRESS, esi

                            lea     esi, CTXT ("--")
                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_REL_MOUSEX,       esi
                            invoke  SetDlgItemText, Tools1Dlg, IDC_TOOLS1_REL_MOUSEY,       esi
                    .endif

                    ret

Tools1_MouseMove    endp

align 16
Tools1DialogProc    proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   W32Find:            WIN32_FIND_DATA,
                            temppath[MAX_PATH]: BYTE,
                            drivename[4]:       BYTE,
                            tempQLP[MAX_PATH]:  BYTE

                    local   WinRect:            RECT

                    local   textstring:         TEXTSTRING,
                            pTEXTSTRING:        DWORD

                    RESETMSG

OnInitDialog
                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr ToolWindow1Name, SADD ("_X")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     esi, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr ToolWindow1Name, SADD ("_Y")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     edi, eax

                    .if     (esi != -1) && (edi != -1)
                            invoke  SetWindowPos, hWndDlg, NULL, esi, edi, 0, 0, SWP_NOOWNERZORDER or SWP_NOSIZE or SWP_NOZORDER
                    .endif


                    invoke  GetLogicalDriveStrings, sizeof temppath, addr temppath
                    mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_GAMESDRIVECOMBO)

                    invoke  ReadQuickLoadPath

                    strcpy  addr QuickLoadFilePath, addr tempQLP
                    mov     esi, $fnc (@@FindStringEnd, addr tempQLP)
                    ifc     byte ptr [esi-1] ne "\" then mov byte ptr [esi], "\" : inc esi
                    mov     dword ptr [esi], "*.*"

                    .if     $fnc (FindFirstFile, addr tempQLP, addr W32Find) == INVALID_HANDLE_VALUE
                            invoke  GetCurrentDirectory, MAX_PATH, addr QuickLoadFilePath
                    .else
                            invoke  FindClose, eax
                    .endif

                    memcpy  addr QuickLoadFilePath, addr drivename, 3
                    mov     drivename[3], 0
                    invoke  szUpper, addr drivename

                    xor     edi, edi        ; combo box drive number
                    lea     esi, temppath   ; ptr to drive strings
                    .while  TRUE
                            ifc     byte ptr [esi] eq 0 then xor edi, edi : .break   ; reset to first logical drive if end of drives list reached

                            invoke  szUpper, esi                    ; drive name to uppercase
                            invoke  szCmpi, addr drivename, esi, 3  ; our drive name?
                            .break  .if eax == 0                    ; a match; edi returns combo box drive selector for this drive

                            mov     esi, $fnc (@@FindStringEnd, esi)
                            inc     esi ; next drive string or end of stringlist
                            inc     edi ; next combo box drive number
                    .endw

                    invoke  DlgDirListComboBox, hWndDlg, addr QuickLoadFilePath, IDC_GAMESDRIVECOMBO, IDC_QUICKLOADFILEPATHSTC, DDL_DRIVES

                    invoke  SendDlgItemMessage, hWndDlg, IDC_GAMESDRIVECOMBO, CB_SETCURSEL, edi, 0

                    invoke  PostMessage, hWndDlg, WM_COMMAND, $WPARAM (CBN_SELCHANGE, IDC_GAMESDRIVECOMBO), ebx

                    return  TRUE

OnActivate
                    ; we need to preserve/restore the current directory in case user uses InsertTape, etc, on a different directory
                    .if     $LowWord (wParam) != WA_INACTIVE
                            invoke  SetCurrentDirectory, addr QuickLoad_Temp
                            CLEARSOUNDBUFFERS
                    .else
                            invoke  GetCurrentDirectory, MAX_PATH, addr QuickLoad_Temp
                    .endif
                    return  TRUE

OnCommand
                    .if     wParam == $WPARAM (CBN_SELCHANGE, IDC_GAMESDRIVECOMBO)
;                            invoke  DlgDirSelectComboBoxEx, hWndDlg, addr QuickLoadFilePath, MAX_PATH, IDC_GAMESDRIVECOMBO
                            invoke  SendDlgItemMessage, hWndDlg, IDC_GAMESDRIVECOMBO, CB_GETCURSEL, 0, 0
                            ifc     eax eq CB_ERR then return TRUE
                            mov     ebx, eax
                            invoke  SendDlgItemMessage, hWndDlg, IDC_GAMESDRIVECOMBO, CB_GETLBTEXT, ebx, addr QuickLoadFilePath
                            lea     esi, QuickLoadFilePath
                            mov     edi, esi
                            .while  byte ptr [esi] != 0
                                    mov     bl, [esi]
                                    switch  bl
                                            case    "[", "]", "-"
                                            .else
                                                    mov     [edi], bl
                                                    inc     edi
                                    endsw
                                    inc     esi
                            .endw
                            mov     byte ptr [edi], ":"
                            mov     byte ptr [edi+1], 0


                            invoke  DlgDirList, hWndDlg, addr QuickLoadFilePath, IDC_GAMESDIRLISTBOX, IDC_QUICKLOADFILEPATHSTC, DDL_DIRECTORY or DDL_EXCLUSIVE
                            mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_GAMESDIRLISTBOX)
                            invoke  SendMessage, hWndDlg, WM_COMMAND, $WPARAM (LBN_DBLCLK, IDC_GAMESDIRLISTBOX), ebx

                    .elseif wParam == $WPARAM (LBN_DBLCLK, IDC_GAMESDIRLISTBOX)
                            invoke  DlgDirSelectEx, hWndDlg, addr QuickLoadFilePath, MAX_PATH, IDC_GAMESDIRLISTBOX
                            .if     eax != 0 
                                    invoke  DlgDirList, hWndDlg, addr QuickLoadFilePath, IDC_GAMESDIRLISTBOX, IDC_QUICKLOADFILEPATHSTC, DDL_DIRECTORY or DDL_EXCLUSIVE
                            .endif
                            invoke  GetCurrentDirectory, MAX_PATH, addr QuickLoadFilePath
                            strcpy  addr QuickLoadFilePath, addr INI_QuickLoadFilePath  ; take copy for writing to INI file
                            invoke  DlgDirList, hWndDlg, addr QuickLoadFilePath, IDC_GAMESLISTBOX, 0, 0

                    .elseif wParam == $WPARAM (LBN_DBLCLK, IDC_GAMESLISTBOX)
                            invoke  DlgDirSelectEx,     hWndDlg, addr QuickLoadFilePath, MAX_PATH, IDC_GAMESLISTBOX
                            invoke  SendDlgItemMessage, hWndDlg, IDC_QUICKLOADFILEPATHSTC, WM_SETTEXT, 0, addr QuickLoadFilePath

                            invoke  GetCurrentDirectory, MAX_PATH, addr QuickLoad_Temp

                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            ADDTEXTSTRING   pTEXTSTRING, offset QuickLoad_Temp
                            ADDCHAR         pTEXTSTRING, "\"
                            ADDTEXTSTRING   pTEXTSTRING, offset QuickLoadFilePath
                            invoke  SendDlgItemMessage, hWndDlg, IDC_QUICKLOADFILEPATHSTC, WM_SETTEXT, 0, addr textstring

                            strcpy  addr textstring, addr szFileName
                            invoke  ReadFileType, addr szFileName
                            invoke  SetFocus, hWnd
                    .endif
                    return  TRUE

OnVKeyToItem
                    mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_GAMESLISTBOX)
                    .if     (lParam == ebx) && ($LowWord (wParam) == 13)     ; treat enter as a double click
                                    invoke  SendMessage, hWndDlg, WM_COMMAND, $WPARAM (LBN_DBLCLK, IDC_GAMESLISTBOX), ebx
                                    return  -2  ; -2 indicates that the application handled the keystroke
                    .endif

                    mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_GAMESDIRLISTBOX)
                    .if     (lParam == ebx) && ($LowWord (wParam) == 13)     ; treat enter as a double click
                                    invoke  SendMessage, hWndDlg, WM_COMMAND, $WPARAM (LBN_DBLCLK, IDC_GAMESDIRLISTBOX), ebx
                                    return  -2  ; -2 indicates that the application handled the keystroke
                    .endif

                    return  -1  ; -1 indicates that the list box should perform the default action in response to the keystroke

OnClose
                    invoke  HideTools1Dialog

OnDestroy
                    invoke  WriteQuickLoadPath

                    invoke  GetWindowRect, hWndDlg, addr WinRect

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr ToolWindow1Name, SADD ("_X")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.left

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr ToolWindow1Name, SADD ("_Y")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.top

                    return  NULL

OnDefault
                    return  FALSE

                    DOMSG

                    ret

Tools1DialogProc    endp

