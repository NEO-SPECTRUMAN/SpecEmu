
.data?
align 4
SearchInDisassembly     DWORD   ?
SearchByteCount         DWORD   ?
SearchParam             BYTE    300     dup(?)
.code

DebugFindDlgProc    proc    uses        ebx esi edi,
                            hWndDlg     :DWORD,
                            uMsg        :DWORD,
                            wParam      :DWORD,
                            lParam      :DWORD

                            LOCAL       wParamLow:       WORD,
                                        wParamHigh:      WORD,
                                        FindString[300]: BYTE

                invoke  HandleCustomWindowMessages, addr FindDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set activate checkbox ID on main debugger window
                mov     FindDLG.Menu_ID, IDM_VIEW_FIND

                invoke  SendDlgItemMessage, hWndDlg, IDC_FINDTEXT, EM_SETLIMITTEXT, 255, 0
                invoke  CheckDlgButton, hWndDlg, IDC_SEARCHDISASSEMBLYCHK, SearchInDisassembly
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                return  NULL

OnCommand
                mov     eax, wParam
                mov     wParamLow, ax
                shr     eax, 16
                mov     wParamHigh, ax

                .if     wParamHigh == BN_CLICKED
                        .if     (wParamLow == IDC_FINDFIRST) || (wParamLow == IDC_FINDNEXT)
                                invoke  GetDlgItemText, hWndDlg, IDC_FINDTEXT, addr FindString, sizeof FindString-1

                                invoke  DecodeSearchBytes, addr FindString
                                .if     eax != 0
                                        .if     wParamLow == IDC_FINDFIRST
                                                mov     Z80PC, 0
                                        .endif
                                        invoke  SendMessage, Debugger_hWnd, WM_COMMAND, WPARAM_USER, LP_USERFIND
                                .endif

                        .elseif wParamLow == IDC_SEARCHDISASSEMBLYCHK
                                invoke  IsDlgButtonChecked, hWndDlg, IDC_SEARCHDISASSEMBLYCHK
                                mov     SearchInDisassembly, eax
                        .endif
                .endif
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugFindDlgProc    endp

DecodeSearchBytes   proc    uses    ebx esi edi,
                            lpText: DWORD

                    local   Number: DWORD,
                            IsHex:  BOOL,
                            GotDig: BOOL

                    mov     esi, lpText
                    lea     edi, SearchParam    ; string of bytes
                    xor     ebx, ebx            ; number of bytes

                    .if     SearchInDisassembly == TRUE
                            ; filter out whitespace sequences to a single space if searching disassembly opcodes
                            ; filter out all quotes
                            .while  TRUE
                                    lodsb
                                    .break  .if al == 0
                                    .if     al != 34
                                            .if     al == " "
                                                    stosb
                                                    inc     ebx
                                                    .while  al == " "
                                                            lodsb
                                                    .endw
                                                    dec     esi
                                            .else
                                                    TOUPPER
                                                    stosb
                                                    inc     ebx
                                            .endif
                                    .endif
                            .endw
                            stosb

                            mov     SearchByteCount, ebx
                            return  ebx
                    .endif

                    .while  TRUE
                            mov     IsHex, FALSE
                        @@: lodsb
                            .break  .if al == 0
                            cmp     al, " "
                            je      @B
                            cmp     al, ","
                            je      @B

                            .if     al == 34    ; string?
                                @@: lodsb
                                    .break  .if al == 0
                                    .if     al != 34
                                            stosb
                                            inc     ebx
                                            jmp     @B
                                    .endif

                            .else   ; must be a number
                                    mov     Number, 0
                                    mov     GotDig, FALSE

                                    .if     (al == "#") || (al == "$")
                                            mov     IsHex, TRUE
                                            lodsb
                                            .break  .if al == 0
                                    .endif

                                    .if     IsHex == TRUE
                                        @@: TOUPPER
                                            .if     ((al >= "0") && (al <= "9")) || ((al >= "A") && (al <= "F"))
                                                    mov     GotDig, TRUE
                                                    sub     al, "0"
                                                    .if     al > 9
                                                            sub     al, 7
                                                    .endif
                                                    and     eax, 15
                                                    shl     Number, 4
                                                    add     Number, eax

                                                    lodsb
                                                    jmp     @B
                                            .else
                                                    mov     ecx, Number
                                                    .while  ecx >= 65536
                                                            sub     ecx, 65536
                                                    .endw
                                                    .if     ecx >= 256
                                                            mov     [edi], cl
                                                            inc     edi
                                                            inc     ebx
                                                            mov     cl, ch
                                                    .endif
                                                    mov     [edi], cl
                                                    inc     edi
                                                    inc     ebx

                                                    .break  .if GotDig == FALSE
                                                    dec     esi
                                            .endif
                                    .else
                                        @@: .if     (al >= "0") && (al <= "9")
                                                    mov     GotDig, TRUE
                                                    sub     al, "0"
                                                    and     eax, 255
                                                    mov     ecx, Number
                                                    lea     ecx, [ecx+ecx*4]
                                                    add     ecx, ecx
                                                    add     ecx, eax
                                                    mov     Number, ecx

                                                    lodsb
                                                    jmp     @B
                                            .else
                                                    mov     ecx, Number
                                                    .while  ecx >= 65536
                                                            sub     ecx, 65536
                                                    .endw
                                                    .if     ecx >= 256
                                                            mov     [edi], cl
                                                            inc     edi
                                                            inc     ebx
                                                            mov     cl, ch
                                                    .endif
                                                    mov     [edi], cl
                                                    inc     edi
                                                    inc     ebx

                                                    .break  .if GotDig == FALSE
                                                    dec     esi
                                            .endif
                                    .endif
                            .endif
                    .endw

                    mov     SearchByteCount, ebx
                    return  ebx

DecodeSearchBytes   endp


