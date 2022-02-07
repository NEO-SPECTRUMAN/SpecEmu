
PopulateExecCmd     PROTO
PopulateBreakCmd    PROTO
SetFDCArgs          PROTO   :DWORD,:DWORD,:BYTE,:DWORD,:DWORD,:BYTE,:DWORD,:DWORD,:BYTE,:DWORD,:DWORD,:BYTE,:DWORD,:DWORD,:BYTE,:DWORD,:DWORD,:BYTE
SetFDCArg           PROTO   :DWORD,:DWORD,:DWORD,:DWORD,:BYTE
SetNoFDCArgs        PROTO
SetCHRNEOT          PROTO
SetIDCHRN           PROTO
SetFDCCmdText       PROTO   :DWORD

EnableBreakArg      PROTO   :DWORD,:DWORD,:DWORD
EnableBreakArgs     PROTO   :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

UpdateFDCReg        PROTO   :DWORD,:BYTE

.data
FDCBreakHandler     dd      0

FDCBreakArg1        dd      -1  ; -1 = wildcard for all FDC break args
FDCBreakArg2        dd      -1
FDCBreakArg3        dd      -1
FDCBreakArg4        dd      -1
FDCBreakArg5        dd      -1
FDCBreakArg6        dd      -1

FDCBreakComboItems  db      "READ DATA", 0
                    db      "READ TRACK", 0
                    db      "READ SECTOR ID", 0
                    db      "SENSE DRIVE STATUS", 0
                    db      "SEEK", 0
                    db      "HEAD specific cmd", 0
                    db      0

RecNewFDCCommand    db      0   ; TRUE when new FDC command callback is received
FDCBreakOnCommand   db      0
SeekBreak           db      0
SeekBreakCyl        db      0

.data?
FDCStateStruct      FDCState    <>  ; for showing +3 debugger dialog states
tFDCState           FDCState    <>  ; for in-break-handler FDC state fetches

.code
DebugPlus3DlgProc   proc        uses        ebx esi edi,
                                hWndDlg     :DWORD,
                                uMsg        :DWORD,
                                wParam      :DWORD,
                                lParam      :DWORD

                invoke  HandleCustomWindowMessages, ADDR Plus3DLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set activate checkbox ID on main debugger window
                mov     Plus3DLG.Menu_ID, IDM_VIEW_PLUS3
                m2m     Plus3DLG.hWnd, hWndDlg

                .if     FDCBreakArg1 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK1, FDCBreakArg1, FALSE
                .endif
                .if     FDCBreakArg2 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK2, FDCBreakArg2, FALSE
                .endif
                .if     FDCBreakArg3 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK3, FDCBreakArg3, FALSE
                .endif
                .if     FDCBreakArg4 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK4, FDCBreakArg4, FALSE
                .endif
                .if     FDCBreakArg5 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK5, FDCBreakArg5, FALSE
                .endif
                .if     FDCBreakArg6 != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_FDCBRK6, FDCBreakArg6, FALSE
                .endif

                invoke  CheckDlgButton,     hWndDlg, IDC_FDCBREAK, ZeroExt (FDCBreakEnabled)
                invoke  AddComboStrings,    $fnc (GetDlgItem, hWndDlg, IDC_FDCCMDCOMBO), addr FDCBreakComboItems
                invoke  SendDlgItemMessage, hWndDlg, IDC_FDCCMDCOMBO, CB_SETCURSEL, ZeroExt (FDCBreakOnCommand), 0
                invoke  PopulateBreakCmd
                invoke  PopulateExecCmd
                return  TRUE

OnShowWindow
                invoke  PopulateBreakCmd
                invoke  PopulateExecCmd
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                mov     FDCBreakArg1, -1
                mov     FDCBreakArg2, -1
                mov     FDCBreakArg3, -1
                mov     FDCBreakArg4, -1
                mov     FDCBreakArg5, -1
                mov     FDCBreakArg6, -1

                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK1, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg1, eax
                .endif
                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK2, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg2, eax
                .endif
                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK3, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg3, eax
                .endif
                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK4, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg4, eax
                .endif
                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK5, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg5, eax
                .endif
                invoke  GetDlgItemInt, hWndDlg, IDC_FDCBRK6, addr lpTranslated, FALSE
                .if     lpTranslated == TRUE
                        mov     FDCBreakArg6, eax
                .endif

                return  NULL

OnCommand
                .if     $HighWord (wParam) == BN_CLICKED
                        .if     $LowWord (wParam) == IDC_FDCBREAK
                                xor     FDCBreakEnabled, TRUE
                                invoke  PopulateBreakCmd
                        .endif

                .elseif $HighWord (wParam) == CBN_SELCHANGE
                        .if     $LowWord (wParam) == IDC_FDCCMDCOMBO
                                invoke  SendDlgItemMessage, hWndDlg, IDC_FDCCMDCOMBO, CB_GETCURSEL, 0, 0
                                .if     eax != LB_ERR
                                        mov     FDCBreakOnCommand, al
                                        invoke  PopulateBreakCmd
                                .endif
                        .endif
                .endif
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugPlus3DlgProc   endp

PopulateBreakCmd proc    uses        esi edi ebx

                .if     Plus3DLG.Visible == TRUE
                        .if     FDCBreakEnabled == FALSE
                                invoke  EnableControl, Plus3DLG.hWnd, IDC_FDCCMDCOMBO, FALSE
                                invoke  EnableBreakArgs, 0, 0, 0, 0, 0, 0
                                mov     FDCBreakHandler, 0
                        .else
                                invoke  EnableControl, Plus3DLG.hWnd, IDC_FDCCMDCOMBO, TRUE

                                switch  FDCBreakOnCommand
                                        case    0
                                                ; READ SECTOR
                                                invoke  EnableBreakArgs, SADD("C"),
                                                                         SADD("H"),
                                                                         SADD("R"),
                                                                         SADD("N"),
                                                                         SADD("Cyl"),
                                                                         SADD("Head")
                                                mov     FDCBreakHandler, offset BreakOnSectorRead
                                        case    1
                                                ; READ TRACK
                                                invoke  EnableBreakArgs, SADD("Cyl"),
                                                                         SADD("Head"),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0
                                                mov     FDCBreakHandler, offset BreakOnReadTrack
                                        case    2
                                                ; READ SECTOR ID
                                                invoke  EnableBreakArgs, SADD("Cyl"),
                                                                         SADD("Head"),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0
                                                mov     FDCBreakHandler, offset BreakOnReadSectorID
                                        case    3
                                                ; SENSE DRIVE STATUS
                                                invoke  EnableBreakArgs, SADD("Head"),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0
                                                mov     FDCBreakHandler, offset BreakOnSenseDriveStatus
                                        case    4
                                                ; SEEK
                                                invoke  EnableBreakArgs, SADD("Cyl"),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0
                                                mov     FDCBreakHandler, offset BreakOnSeek
                                        case    5
                                                ; HEAD specific cmd
                                                invoke  EnableBreakArgs, SADD("Head"),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0
                                                mov     FDCBreakHandler, offset BreakOnHeadSpecific
                                endsw
                        .endif
                .endif
                ret
PopulateBreakCmd endp

                    ; macros to fetch current track/head params for break handler tests only, using tFDCState structs
FETCH_CURR_TRACK    macro   track_reg:req
                    test    [FDCCommandBytes+1], 1
                    .if     ZERO?
                            mov     track_reg, tFDCState.Unit0_CTRK
                    .else
                            mov     track_reg, tFDCState.Unit1_CTRK
                    .endif
                    endm

FETCH_CURR_HEAD     macro   head_reg:req
                    test    [FDCCommandBytes+1], 4
                    .if     ZERO?
                            mov     head_reg, tFDCState.Unit0_CHEAD
                    .else
                            mov     head_reg, tFDCState.Unit1_CHEAD
                    .endif
                    endm

align 16
BreakOnSectorRead   proc

                    mov     al, FDCCommandBytes[0]
                    and     al, 31
                    .if     (al == 6) || (al == 12)                 ; READ DATA, READ DELETED DATA
                            mov     eax, FDCBreakArg1
                            .if     eax != -1
                                    cmp     al, FDCCommandBytes[2]
                                    jne     @F
                            .endif
                            mov     eax, FDCBreakArg2
                            .if     eax != -1
                                    cmp     al, FDCCommandBytes[3]
                                    jne     @F
                            .endif
                            mov     eax, FDCBreakArg3
                            .if     eax != -1
                                    cmp     al, FDCCommandBytes[4]
                                    jne     @F
                            .endif
                            mov     eax, FDCBreakArg4
                            .if     eax != -1
                                    cmp     al, FDCCommandBytes[5]
                                    jne     @F
                            .endif
                            .if     FDCBreakArg5 != -1
                                    invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                                    mov     eax, FDCBreakArg5
                                    FETCH_CURR_TRACK cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif
                            .if     FDCBreakArg6 != -1
                                    invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                                    mov     eax, FDCBreakArg6
                                    FETCH_CURR_HEAD cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif

                            return  TRUE    ; signal debugger break
                    .endif

@@:                 return  FALSE   ; signal no debugger break

BreakOnSectorRead   endp

align 16
BreakOnReadTrack    proc
                    mov     al, FDCCommandBytes[0]
                    and     al, 31
                    .if     al == 2                        ; READ TRACK
                            invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                            .if     FDCBreakArg1 != -1
                                    mov     eax, FDCBreakArg1
                                    FETCH_CURR_TRACK cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif
                            .if     FDCBreakArg2 != -1
                                    mov     eax, FDCBreakArg2
                                    FETCH_CURR_HEAD cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif

                            return  TRUE    ; signal debugger break
                    .endif

@@:                 return  FALSE   ; signal no debugger break

BreakOnReadTrack    endp

align 16
BreakOnReadSectorID proc
                    mov     al, FDCCommandBytes[0]
                    and     al, 31
                    .if     al == 10                        ; READ SECTOR ID
                            invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                            .if     FDCBreakArg1 != -1
                                    mov     eax, FDCBreakArg1
                                    FETCH_CURR_TRACK cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif
                            .if     FDCBreakArg2 != -1
                                    mov     eax, FDCBreakArg2
                                    FETCH_CURR_HEAD cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif

                            return  TRUE    ; signal debugger break
                    .endif

@@:                 return  FALSE   ; signal no debugger break

BreakOnReadSectorID endp

align 16
BreakOnSenseDriveStatus proc

                    mov     al, FDCCommandBytes[0]
                    and     al, 31
                    .if     al == 4                        ; SENSE DRIVE STATUS
                            invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                            .if     FDCBreakArg1 != -1
                                    mov     eax, FDCBreakArg1
                                    FETCH_CURR_HEAD cl
                                    cmp     al,  cl
                                    jne     @F
                            .endif

                            return  TRUE    ; signal debugger break
                    .endif

@@:                 return  FALSE   ; signal no debugger break

BreakOnSenseDriveStatus endp

align 16
BreakOnSeek         proc

                    mov     al, FDCCommandBytes[0]
                    and     al, 31
                    .if     SeekBreak == TRUE           ; SEEK
                            mov     SeekBreak, FALSE    ; SeekBreak set in FDC command callback in Machines/+3
                            mov     eax, FDCBreakArg1
                            .if     eax != -1
                                    cmp     al, SeekBreakCyl
                                    jne     @F
                            .endif

                            mov     al, SeekBreakCyl
                            mov     FDCCommandBytes[2], al
                            mov     FDCCommandBytes[0], 15
                            return  TRUE    ; signal debugger break
                    .endif

@@:                 return  FALSE   ; signal no debugger break
BreakOnSeek         endp

align 16
BreakOnHeadSpecific proc

                    .if     FDCBreakArg1 != -1
                            invoke  u765_GetFDCState, FDCHandle, addr tFDCState
                            mov     al, FDCCommandBytes[0]
                            and     al, 31
                            switch  al
                                    case    2, 4, 5, 6, 9, 10, 12, 13, 15, 17, 25, 29
                                    mov     ecx, FDCBreakArg1
                                    and     cl, 1
                                    mov     al, FDCCommandBytes[1]
                                    and     al, 4
                                    shr     al, 2   ; isolate HD bit (=0/1)
                                    cmp     al, cl
                                    jne     @F
                                    return  TRUE    ; signal debugger break
                            endsw
                    .endif
@@:                 return  FALSE   ; signal no debugger break
BreakOnHeadSpecific endp

EnableBreakArgs proc    arg1a:  DWORD,
                        arg2a:  DWORD,
                        arg3a:  DWORD,
                        arg4a:  DWORD,
                        arg5a:  DWORD,
                        arg6a:  DWORD

                invoke  EnableBreakArg, IDC_FDCBRK1STC, IDC_FDCBRK1, arg1a
                invoke  EnableBreakArg, IDC_FDCBRK2STC, IDC_FDCBRK2, arg2a
                invoke  EnableBreakArg, IDC_FDCBRK3STC, IDC_FDCBRK3, arg3a
                invoke  EnableBreakArg, IDC_FDCBRK4STC, IDC_FDCBRK4, arg4a
                invoke  EnableBreakArg, IDC_FDCBRK5STC, IDC_FDCBRK5, arg5a
                invoke  EnableBreakArg, IDC_FDCBRK6STC, IDC_FDCBRK6, arg6a
                ret
EnableBreakArgs endp

EnableBreakArg  proc    uses    ebx esi edi,
                        ctitle: DWORD,
                        ctlval: DWORD,
                        arg1:   DWORD

                mov     esi, $fnc (GetDlgItem, Plus3DLG.hWnd, ctitle)
                mov     edi, $fnc (GetDlgItem, Plus3DLG.hWnd, ctlval)
                .if     arg1 == 0
                        mov     ebx, SW_HIDE
                .else
                        invoke  SendMessage, esi, WM_SETTEXT, 0, arg1
                        mov     ebx, SW_SHOW
                .endif

                invoke  ShowWindow, esi, ebx
                invoke  ShowWindow, edi, ebx
                ret
EnableBreakArg  endp

UpdateFDCReg    proc    uses    ebx esi edi,
                        CtrlID: DWORD,
                        Value:  BYTE

                local   textstring: TEXTSTRING,
                        pTEXTSTRING:DWORD

                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                invoke  PrtBase8,       pTEXTSTRING, Value
                invoke  SendDlgItemMessage, Plus3DLG.hWnd,
                                            CtrlID,
                                            WM_SETTEXT, 0,
                                            addr textstring
                ret
UpdateFDCReg    endp

PopulateExecCmd proc    uses        esi edi ebx

              ; set motor on/off menu item states
                test    Last1FFDWrite, 8
                .if     ZERO?
                        mov     esi, MF_ENABLED or MF_BYCOMMAND
                        mov     edi, MF_GRAYED  or MF_BYCOMMAND
                .else
                        mov     esi, MF_GRAYED  or MF_BYCOMMAND
                        mov     edi, MF_ENABLED or MF_BYCOMMAND
                .endif
                invoke  EnableMenuItem, DebugMenuHandle, IDM_RUNTODISKMOTORON,  esi
                invoke  EnableMenuItem, DebugMenuHandle, IDM_RUNTODISKMOTOROFF, edi


                .if     Plus3DLG.Visible == TRUE

                        test    Last1FFDWrite, 8
                        .if     ZERO?
                                lea     esi, CTXT ("Stopped")
                        .else
                                lea     esi, CTXT ("Running")
                        .endif
                        invoke  SetDlgItemText, Plus3DLG.hWnd, IDC_STCDRIVEMOTORS, esi


                        lea     ebx, FDCStateStruct
                        assume  ebx: ptr FDCState

                        invoke  u765_GetFDCState, FDCHandle, ebx

                        invoke  UpdateFDCReg, IDC_MSR, [ebx].MSR
                        invoke  UpdateFDCReg, IDC_ST0, [ebx].ST0
                        invoke  UpdateFDCReg, IDC_ST1, [ebx].ST1
                        invoke  UpdateFDCReg, IDC_ST2, [ebx].ST2
                        invoke  UpdateFDCReg, IDC_ST3, [ebx].ST3

                        lea     esi, FDCCommandBytes
                        mov     al, [esi]
                        and     al, 31
                        switch  al
                                case    0
                                        invoke  SetFDCCmdText, SADD("No command executing")
                                        invoke  SetNoFDCArgs
                                case    2
                                        invoke  SetFDCCmdText, SADD("READ TRACK")
                                        invoke  SetCHRNEOT
                                case    3
                                        invoke  SetFDCCmdText, SADD("SPECIFY")
                                        invoke  SetNoFDCArgs
                                case    4
                                        invoke  SetFDCCmdText, SADD("SENSE DRIVE STATUS")
                                        invoke  SetNoFDCArgs
                                case    5
                                        invoke  SetFDCCmdText, SADD("WRITE DATA")
                                        invoke  SetCHRNEOT
                                case    6
                                        invoke  SetFDCCmdText, SADD("READ DATA")
                                        invoke  SetCHRNEOT
                                case    7
                                        invoke  SetFDCCmdText, SADD("RECALIBRATE")
                                        invoke  SetNoFDCArgs
                                case    8
                                        invoke  SetFDCCmdText, SADD("SENSE INTERRUPT STATUS")
                                        invoke  SetNoFDCArgs
                                case    9
                                        invoke  SetFDCCmdText, SADD("WRITE DELETED DATA")
                                        invoke  SetCHRNEOT
                                case    10
                                        invoke  SetFDCCmdText, SADD("READ SECTOR ID")
                                        invoke  SetIDCHRN
                                case    12
                                        invoke  SetFDCCmdText, SADD("READ DELETED DATA")
                                        invoke  SetCHRNEOT
                                case    13
                                        invoke  SetFDCCmdText, SADD("FORMAT TRACK")
                                        invoke  SetFDCArgs,    SADD("N"),   2, 255,
                                                               SADD("SC"),  3, 255,
                                                               SADD("GPL"), 4, 255,
                                                               SADD("D"),   5, 255,
                                                               0,0,0,
                                                               0,0,0
                                case    15
                                        invoke  SetFDCCmdText, SADD("SEEK")
                                        invoke  SetFDCArgs,    SADD("Cyl"), 2, 255,
                                                               0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0
                                case    16
                                        invoke  SetFDCCmdText, SADD("VERSION")
                                        invoke  SetNoFDCArgs
                                case    17
                                        invoke  SetFDCCmdText, SADD("SCAN EQUAL")
                                        invoke  SetNoFDCArgs
                                case    25
                                        invoke  SetFDCCmdText, SADD("SCAN LOW OR EQUAL")
                                        invoke  SetNoFDCArgs
                                case    29
                                        invoke  SetFDCCmdText, SADD("SCAN HIGH OR EQUAL")
                                        invoke  SetNoFDCArgs
                                .else
                                        invoke  SetFDCCmdText, SADD("INVALID COMMAND")
                                        invoke  SetNoFDCArgs
                        endsw
                .endif
                ret

PopulateExecCmd endp

SetFDCCmdText   proc    lpText: DWORD
                invoke  SetDlgItemText, Plus3DLG.hWnd, IDC_EXECCMD, lpText
                ret
SetFDCCmdText   endp

SetNoFDCArgs    proc
                invoke  SetFDCArgs,     0, 0, 0,
                                        0, 0, 0,
                                        0, 0, 0,
                                        0, 0, 0,
                                        0, 0, 0,
                                        0, 0, 0
                ret
SetNoFDCArgs    endp

SetCHRNEOT      proc
                invoke  SetFDCArgs,     SADD ("C"),   2,  255,
                                        SADD ("H"),   3,  255,
                                        SADD ("R"),   4,  255,
                                        SADD ("N"),   5,  255,
                                        SADD ("EOT"), 6,  255,
                                        SADD ("Cyl"), -1, 255
                ret
SetCHRNEOT      endp

SetIDCHRN       proc
                invoke  SetFDCArgs,     SADD ("C"),   2,  255,
                                        SADD ("H"),   3,  255,
                                        SADD ("R"),   4,  255,
                                        SADD ("N"),   5,  255,
                                        SADD ("Cyl"), -1, 255,
                                        0, 0, 0
                ret
SetIDCHRN       endp

SetFDCArgs      proc    arg1a:DWORD, arg1b:DWORD, and1:BYTE,
                        arg2a:DWORD, arg2b:DWORD, and2:BYTE,
                        arg3a:DWORD, arg3b:DWORD, and3:BYTE,
                        arg4a:DWORD, arg4b:DWORD, and4:BYTE,
                        arg5a:DWORD, arg5b:DWORD, and5:BYTE,
                        arg6a:DWORD, arg6b:DWORD, and6:BYTE

                invoke  SetFDCArg, IDC_FDCARG1STC, IDC_FDCARG1, arg1a, arg1b, and1
                invoke  SetFDCArg, IDC_FDCARG2STC, IDC_FDCARG2, arg2a, arg2b, and2
                invoke  SetFDCArg, IDC_FDCARG3STC, IDC_FDCARG3, arg3a, arg3b, and3
                invoke  SetFDCArg, IDC_FDCARG4STC, IDC_FDCARG4, arg4a, arg4b, and4
                invoke  SetFDCArg, IDC_FDCARG5STC, IDC_FDCARG5, arg5a, arg5b, and5
                invoke  SetFDCArg, IDC_FDCARG6STC, IDC_FDCARG6, arg6a, arg6b, and6
                ret

SetFDCArgs      endp

SetFDCArg       proc    uses    ebx esi edi,
                        ctitle: DWORD,
                        ctlval: DWORD,
                        arg1:   DWORD,
                        arg2:   DWORD,
                        ANDval: BYTE

                mov     esi, $fnc (GetDlgItem, Plus3DLG.hWnd, ctitle)
                mov     edi, $fnc (GetDlgItem, Plus3DLG.hWnd, ctlval)
                .if     arg1 == 0
                        mov     ebx, SW_HIDE
                .else
                        invoke  SendMessage, esi, WM_SETTEXT, 0, arg1
                        mov     eax, arg2
                        .if     eax == -1
                                ; arg2 = -1 to fetch command physical cylinder value
                                test    [FDCCommandBytes+1], 1
                                .if     ZERO?
                                        movzx   eax, FDCStateStruct.Unit0_CTRK
                                .else
                                        movzx   eax, FDCStateStruct.Unit1_CTRK
                                .endif
                        .else
                                ; arg2 = offset into FDC command bytes
                                movzx   eax, [FDCCommandBytes+eax]
                                and     al,  [ANDval]
                        .endif
                        invoke  SetDlgItemInt, Plus3DLG.hWnd, ctlval, eax, FALSE
                        mov     ebx, SW_SHOW
                .endif

                invoke  ShowWindow, esi, ebx
                invoke  ShowWindow, edi, ebx
                ret

SetFDCArg       endp


