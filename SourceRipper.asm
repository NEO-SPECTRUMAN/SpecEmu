
.data?
DissLabelLookup         BYTE    ?
DissShowBlankLines      BYTE    ?
DissShowHiddenLabels    BYTE    ?
DissShowLowercase       BYTE    ?
DissShowAsDEFB          BYTE    ?
.code

SOURCERIPPERALLOCSIZE   equ     1000000

SourceRipperDlgProc proc        uses        ebx esi edi,
                                hWndDlg     :DWORD,
                                uMsg        :DWORD,
                                wParam      :DWORD,
                                lParam      :DWORD

                                local       DissEdithWnd:   DWORD,
                                            DissStartAddr:  DWORD,
                                            DissEndAddr:    DWORD,
                                            lpMemory:       DWORD,
                                            lpMemEnd:       DWORD

                                local       SaveZ80PC:      WORD,
                                            LastZ80PC:      WORD,
                                            wParamLow:      WORD,
                                            wParamHigh:     WORD

                                local       Buffer1[33]:    BYTE

                                local       exitflag:       BYTE,
                                            bytecount:      BYTE

                                local       textstring:     TEXTSTRING,
                                            pTEXTSTRING:    DWORD

                invoke  HandleCustomWindowMessages, ADDR SourceRipperDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set activate checkbox ID on main debugger window
                mov     SourceRipperDLG.Menu_ID, IDM_VIEW_SOURCECODE_RIPPER

                mov     DissEdithWnd, $fnc (GetDlgItem, hWndDlg, IDC_VIEWDISASSEMBLYEDT)
                SETNEWWINDOWFONT    DissEdithWnd, Courier_New_9, DissEditFont, DissEditOldFont
                movzx   eax, DissShowBlankLines
                invoke  CheckDlgButton, hWndDlg, IDC_DISSSHOWBLANKLINESCHK, eax
                movzx   eax, DissShowHiddenLabels
                invoke  CheckDlgButton, hWndDlg, IDC_DISSSHOWHIDDENLABELSCHK, eax
                movzx   eax, DissShowLowercase
                invoke  CheckDlgButton, hWndDlg, IDC_DISSLOWERCASECHK, eax
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                SETOLDWINDOWFONT    DissEdithWnd, DissEditFont, DissEditOldFont
                return  NULL

OnCommand
                mov     eax, wParam
                mov     wParamLow, ax
                shr     eax, 16
                mov     wParamHigh, ax

                .if     wParamHigh == BN_CLICKED
                        .if     wParamLow == IDC_DISSSHOWBLANKLINESCHK
                                invoke  IsDlgButtonChecked, hWndDlg, IDC_DISSSHOWBLANKLINESCHK
                                mov     DissShowBlankLines, al
                                return  TRUE

                        .elseif wParamLow == IDC_DISSSHOWHIDDENLABELSCHK
                                invoke  IsDlgButtonChecked, hWndDlg, IDC_DISSSHOWHIDDENLABELSCHK
                                mov     DissShowHiddenLabels, al
                                return  TRUE

                        .elseif wParamLow == IDC_DISSLOWERCASECHK
                                invoke  IsDlgButtonChecked, hWndDlg, IDC_DISSLOWERCASECHK
                                mov     DissShowLowercase, al
                                return  TRUE

                        .elseif wParamLow == IDC_DISSSHOWASDEFBCHK
                                invoke  IsDlgButtonChecked, hWndDlg, IDC_DISSSHOWASDEFBCHK
                                mov     DissShowAsDEFB, al
                                return  TRUE

                        .elseif wParamLow == IDC_SETSTARTASCURRADDRBTN
                                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                invoke  PrtBase16,      pTEXTSTRING, Z80PC, 0
                                invoke  SendDlgItemMessage, hWndDlg, IDC_DISSSTARTEDT, WM_SETTEXT, 0, addr textstring
                                return  TRUE

                        .elseif wParamLow == IDC_SETENDASCURRADDRBTN
                                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                invoke  PrtBase16,      pTEXTSTRING, Z80PC, 0
                                invoke  SendDlgItemMessage, hWndDlg, IDC_DISSENDEDT, WM_SETTEXT, 0, addr textstring
                                return  TRUE

                        .elseif wParamLow == IDC_DISSGENERATEBTN
                                invoke  GetDlgItemText, hWndDlg, IDC_DISSSTARTEDT, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                mov     DissStartAddr, eax
                                .if     (lpTranslated == FALSE) || (DissStartAddr > 65535)
                                        szText  DissAllowedRange, "Address Range = (0-65535)"
                                        invoke  ShowMessageBox, hWndDlg, ADDR DissAllowedRange, ADDR szWindowName, MB_OK
                                        return  TRUE
                                .endif

                                invoke  GetDlgItemText, hWndDlg, IDC_DISSENDEDT, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                mov     DissEndAddr, eax
                                .if     (lpTranslated == FALSE) || (DissEndAddr > 65535)
                                        invoke  ShowMessageBox, hWndDlg, ADDR DissAllowedRange, ADDR szWindowName, MB_OK
                                        return  TRUE
                                .endif
                                mov     eax, DissStartAddr
                                .if     eax > DissEndAddr
                                        invoke  ShowMessageBox, hWndDlg, SADD("Start address is greater than End address!!"), ADDR szWindowName, MB_OK
                                        return  TRUE
                                .endif

                                mov     lpMemory, AllocMem (SOURCERIPPERALLOCSIZE)
                                .if     eax == NULL
                                        invoke  ShowMessageBox, hWndDlg, SADD("Insufficient Memory Available"), ADDR szWindowName, MB_OK
                                        return  TRUE
                                .endif
                                add     eax, SOURCERIPPERALLOCSIZE
                                mov     lpMemEnd, eax

                                mov     Highlight16bit, FALSE

                                mov     ax, Z80PC
                                mov     SaveZ80PC, ax

                              ; mark all mem-mapped labels as not in use
                                lea     edi, LabelTable
                                mov     ecx, 65536/4
                                xor     eax, eax
                                rep     stosd

                                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                mov     eax, lpMemory
                                mov     byte ptr [eax], 0
                                invoke  SETTEXTPTR, pTEXTSTRING, eax    ; point the text pointer to our allocated buffer

                                ; showing as DEFB output?
                                .if     DissShowAsDEFB == TRUE

                                        mov     exitflag, FALSE
                                        mov     ebx, DissStartAddr  ; ebx = start address

                                        .while  exitflag == FALSE
                                            ; check available memory in output buffer
                                            invoke  GETTEXTPTR, pTEXTSTRING
                                            add     eax, 80
                                            .if     eax > lpMemEnd
                                                    invoke  GlobalFree, lpMemory
                                                    invoke  ShowMessageBox, hWndDlg, SADD ("Insufficient Memory Available"), addr szWindowName, MB_OK
                                                    return  TRUE
                                            .endif

                                            ADDCHAR pTEXTSTRING, 9
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "DEFB  "
                                            mov     bytecount, 4

                                            .while  bytecount > 0
                                                    call    MemGetByte
                                                    inc     ebx
                                                    invoke  OutBase8, pTEXTSTRING, al

                                                    .if     ebx > DissEndAddr
                                                            mov     exitflag, TRUE
                                                            .break
                                                    .endif

                                                    .if     bytecount > 1
                                                            ADDCHAR pTEXTSTRING, ",", " "
                                                    .endif

                                                    dec     bytecount
                                            .endw
                                            ADDCHAR pTEXTSTRING, 13, 10

                                        .endw

                                        ADDCHAR pTEXTSTRING, 13, 10

                                        jmp     @Diss_To_Lowercase  ; exit
                                .endif

                                ; showing as disassembled output
                                ; start Pass 1
                                mov     eax, DissStartAddr
                                mov     Z80PC, ax

                                lea     edi, LabelTable
                                .while  TRUE
                                        mov     ax, Z80PC
                                        mov     LastZ80PC, ax
                                        invoke  DisassembleLine, pTEXTSTRING

                                        ; check available memory in output buffer
                                        invoke  GETTEXTPTR, pTEXTSTRING
                                        add     eax, 80
                                        .if     eax > lpMemEnd
                                                invoke  GlobalFree, lpMemory
                                                invoke  ShowMessageBox, hWndDlg, SADD("Insufficient Memory Available"), ADDR szWindowName, MB_OK
                                                return  TRUE
                                        .endif
                                        .if     FwdAddrValid == TRUE
                                                movzx   eax, FwdAddr
                                                .if     (eax >= DissStartAddr) && (eax <= DissEndAddr)
                                                        mov     byte ptr [edi+eax], 1
                                                .endif
                                        .endif

                                        mov     ax, Z80PC
                                        .break  .if ax < LastZ80PC  ; break if PC wrapped
                                        mov     eax, DissEndAddr
                                        .break  .if Z80PC > ax      ; break if past range end
                                .endw

                                ; start Pass 2
                                mov     eax, DissStartAddr
                                mov     Z80PC, ax

                                mov     eax, lpMemory
                                mov     byte ptr [eax], 0
                                invoke  SETTEXTPTR, pTEXTSTRING, eax    ; point the text pointer to our allocated buffer

                                lea     edi, LabelTable
                                .while  TRUE
                                        mov     DissLabelLookup, TRUE
                                        movzx   eax, Z80PC
                                        mov     LastZ80PC, ax
                                        .if     byte ptr [edi+eax] == 1
                                                invoke  OutBase16, addr textstring, ax, 0
                                                ADDCHAR pTEXTSTRING, ":"
                                        .endif
                                        ADDCHAR pTEXTSTRING, 9
                                        mov     WantBlankLine, FALSE
                                        invoke  DisassembleLine, addr textstring
                                        ; check available memory in output buffer
                                        invoke  GETTEXTPTR, pTEXTSTRING
                                        add     eax, 80
                                        .if     eax > lpMemEnd
                                                invoke  GlobalFree, lpMemory
                                                invoke  ShowMessageBox, hWndDlg, SADD("Insufficient Memory Available"), ADDR szWindowName, MB_OK
                                                mov     DissLabelLookup, FALSE
                                                return  TRUE
                                        .endif
                                        mov     FwdAddrRST, FALSE
                                        ADDCHAR pTEXTSTRING, 13
                                        ADDCHAR pTEXTSTRING, 10
                                        .if     (DissShowBlankLines == TRUE) && (WantBlankLine == TRUE)
                                                ADDCHAR pTEXTSTRING, 13
                                                ADDCHAR pTEXTSTRING, 10
                                        .endif
                                        .if     DissShowHiddenLabels == TRUE
                                                movzx   eax, LastZ80PC
                                                inc     eax
                                                movzx   ebx, Z80PC
                                                .while  eax < ebx
                                                        .if     byte ptr [edi+eax] == 1
                                                                mov     DissLabelLookup, TRUE
                                                                invoke  OutBase16, pTEXTSTRING, ax, 0
                                                                ADDCHAR pTEXTSTRING, 9
                                                                mov     DissLabelLookup, FALSE
                                                                ADDDIRECTTEXTSTRING pTEXTSTRING, "EQU  *-"
                                                                mov     ecx, ebx
                                                                sub     ecx, eax
                                                                invoke  OutBase16, pTEXTSTRING, cx, 0
                                                                ADDCHAR pTEXTSTRING, 13
                                                                ADDCHAR pTEXTSTRING, 10
                                                        .endif
                                                        inc     eax
                                                .endw
                                        .endif

                                        mov     ax, Z80PC
                                        .break  .if ax < LastZ80PC  ; break if PC wrapped
                                        mov     eax, DissEndAddr
                                        .break  .if Z80PC > ax      ; break if past range end
                                .endw
                                mov     DissLabelLookup, FALSE

            @Diss_To_Lowercase:
                                .if     DissShowLowercase == TRUE
                                        mov     eax, lpMemory   ; initial text string pointer
                                        .while  byte ptr [eax] != 0
                                                mov     bl, [eax]
                                                .if     (bl >= "A") && (bl <= "Z")
                                                        add     bl, 32
                                                        mov     [eax], bl
                                                .endif
                                                inc     eax
                                        .endw
                                .endif

                                invoke  SetDlgItemText, hWndDlg, IDC_VIEWDISASSEMBLYEDT, lpMemory

                                mov     ax, SaveZ80PC
                                mov     Z80PC, ax

                                invoke  GlobalFree, lpMemory
                                return  TRUE
                        .endif
                .endif
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

SourceRipperDlgProc endp

