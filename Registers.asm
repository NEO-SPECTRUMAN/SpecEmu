
UpdateAllRegisters      PROTO
UpdateRegister          PROTO   :DWORD,:WORD

.data?
.code


SOURCERIPPERALLOCSIZE   equ     1000000

RegistersDlgProc proc   uses        ebx esi edi,
                        hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                 LOCAL  CtrlID:     DWORD,
                        wParamLow:  WORD,
                        wParamHigh: WORD
                        

                invoke  HandleCustomWindowMessages, ADDR RegistersDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set activate checkbox ID on main debugger window
                mov     RegistersDLG.Menu_ID, IDM_VIEW_REGISTERS
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
                        .if     wParamLow == IDC_INTSTATUS  ; enable/disable interrupts
                                .if     currentMachine.iff1 == TRUE
                                        DISABLEINTS
                                .else
                                        ENABLEINTS
                                .endif
                                invoke  UpdateAllRegisters
                                return  TRUE

                        .elseif wParamLow == IDC_HALT_STATUS    ; toggle HALTed state
                                xor     HALTED, TRUE
                                invoke  UpdateAllRegisters
                                return  TRUE

                        ; check for button clicks on the register label controls
                        .elseif wParamLow == IDC_rPC
                                invoke  SetMemoryViewAddr, zPC
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rSP
                                invoke  SetMemoryViewAddr, z80registers._sp
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rAF
                                invoke  SetMemoryViewAddr, z80registers.af.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rAF_
                                invoke  SetMemoryViewAddr, z80registers.af_.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rBC
                                invoke  SetMemoryViewAddr, z80registers.bc.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rBC_
                                invoke  SetMemoryViewAddr, z80registers.bc_.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rDE
                                invoke  SetMemoryViewAddr, z80registers.de.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rDE_
                                invoke  SetMemoryViewAddr, z80registers.de_.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rHL
                                invoke  SetMemoryViewAddr, z80registers.hl.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rHL_
                                invoke  SetMemoryViewAddr, z80registers.hl.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rIX
                                invoke  SetMemoryViewAddr, z80registers.ix.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rIY
                                invoke  SetMemoryViewAddr, z80registers.iy.w
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rIR
                                switch  z80registers.intmode
                                        case    2
                                                mov     bh, z80registers.i
                                                mov     bl, 255
                                                call    MemGetWord
                                        .else
                                                mov     ax, 56
                                endsw

                                invoke  SetMemoryViewAddr, ax
                                invoke  PopulateMemoryDlg

                        .elseif wParamLow == IDC_rMEMPTR
                                invoke  SetMemoryViewAddr, zMemPtr
                                invoke  PopulateMemoryDlg


                        .elseif (wParamLow >= IDC_FLAG_S) && (wParamLow <= IDC_FLAG_C)
                                ; flags checkbox clicked
                                movzx   eax, wParamLow
                                mov     CtrlID, eax
                                invoke  IsDlgButtonChecked, hWndDlg, CtrlID
                                mov     edx, eax        ; dl = checked bit

                                mov     eax, CtrlID
                                sub     eax, IDC_FLAG_S ; eax = 0-7
                                mov     ecx, 7
                                sub     ecx, eax        ; reverse bit order
                                shl     dl, cl          ; shift bit value into position
                                mov     al, z80registers.af.lo
                                btr     ax, cx          ; clear the appropriate bit
                                or      al, dl          ; and OR in the new bit
                                mov     z80registers.af.lo, al          ; store the new flags value
                                invoke  UpdateDebugger
                                return  TRUE
                        .endif
                        return  TRUE

                .elseif wParamHigh == EN_UPDATE
                        switch  wParamLow, ax
                                case    IDC_PC
                                        invoke  ParseRegText, IDC_PC
                                        ifc     lpTranslated eq TRUE then mov zPC, ax
                                case    IDC_SP
                                        invoke  ParseRegText, IDC_SP
                                        ifc     lpTranslated eq TRUE then mov z80registers._sp, ax
                                case    IDC_AF
                                        invoke  ParseRegText, IDC_AF
                                        ifc     lpTranslated eq TRUE then mov z80registers.af.w, ax
                                case    IDC_ExAF
                                        invoke  ParseRegText, IDC_ExAF
                                        ifc     lpTranslated eq TRUE then mov z80registers.af_.w, ax
                                case    IDC_BC
                                        invoke  ParseRegText, IDC_BC
                                        ifc     lpTranslated eq TRUE then mov z80registers.bc.w, ax
                                case    IDC_ExBC
                                        invoke  ParseRegText, IDC_ExBC
                                        ifc     lpTranslated eq TRUE then mov z80registers.bc_.w, ax
                                case    IDC_DE
                                        invoke  ParseRegText, IDC_DE
                                        ifc     lpTranslated eq TRUE then mov z80registers.de.w, ax
                                case    IDC_ExDE
                                        invoke  ParseRegText, IDC_ExDE
                                        ifc     lpTranslated eq TRUE then mov z80registers.de_.w, ax
                                case    IDC_HL
                                        invoke  ParseRegText, IDC_HL
                                        ifc     lpTranslated eq TRUE then mov z80registers.hl.w, ax
                                case    IDC_ExHL
                                        invoke  ParseRegText, IDC_ExHL
                                        ifc     lpTranslated eq TRUE then mov z80registers.hl_.w, ax
                                case    IDC_IX
                                        invoke  ParseRegText, IDC_IX
                                        ifc     lpTranslated eq TRUE then mov z80registers.ix.w, ax
                                case    IDC_IY
                                        invoke  ParseRegText, IDC_IY
                                        ifc     lpTranslated eq TRUE then mov z80registers.iy.w, ax
                                case    IDC_IR
                                        invoke  ParseRegText, IDC_IR
                                        .if     lpTranslated == TRUE
                                                mov     z80registers.i, ah
                                                mov     z80registers.r, al
                                                and     al, 128
                                                mov     Reg_R_msb, al
                                        .endif
                                        invoke  SetSnowEffect
                                case    IDC_IM
                                        invoke  ParseRegText, IDC_IM
                                        .if     lpTranslated == TRUE
                                                .if     (ax >= 0) && (ax <= 2)
                                                        mov     z80registers.intmode, al
                                                .endif
                                        .endif
                        endsw
                .endif
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

RegistersDlgProc endp

UpdateAllRegisters  proc    uses ebx

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     RegistersDLG.Visible == FALSE
                            ret
                    .endif

                    invoke  UpdateRegister, IDC_AF,   z80registers.af.w
                    invoke  UpdateRegister, IDC_BC,   z80registers.bc.w
                    invoke  UpdateRegister, IDC_DE,   z80registers.de.w
                    invoke  UpdateRegister, IDC_HL,   z80registers.hl.w

                    invoke  UpdateRegister, IDC_ExAF, z80registers.af_.w
                    invoke  UpdateRegister, IDC_ExBC, z80registers.bc_.w
                    invoke  UpdateRegister, IDC_ExDE, z80registers.de_.w
                    invoke  UpdateRegister, IDC_ExHL, z80registers.hl_.w

                    invoke  UpdateRegister, IDC_PC,   zPC
                    invoke  UpdateRegister, IDC_SP,   z80registers._sp
                    invoke  UpdateRegister, IDC_IX,   z80registers.ix.w
                    invoke  UpdateRegister, IDC_IY,   z80registers.iy.w

                    invoke  UpdateRegister, IDC_MEMPTR, zMemPtr

                    mov     ah, z80registers.i
                    mov     al, z80registers.r
                    and     al, 127
                    or      al, Reg_R_msb
                    invoke  UpdateRegister, IDC_IR, ax

                    .if     currentMachine.iff1 == TRUE
                           mov     eax, CTXT ("Enabled")
                    .else
                           mov     eax, CTXT ("Disabled")
                    .endif
                    invoke  SendDlgItemMessage, RegistersDLG.hWnd, IDC_INTSTATUS, WM_SETTEXT, 0, eax

                    movzx   eax, HALTED
                    invoke  CheckDlgButton, RegistersDLG.hWnd, IDC_HALT_STATUS, eax

                    ; set the Flags checkboxes
                    mov     al, z80registers.af.lo
                    mov     ecx, IDC_FLAG_S
                    SETLOOP 8
                            shl     al, 1
                            push    eax
                            push    ecx
                            mov     eax, 0
                            adc     eax, 0
                            invoke  CheckDlgButton, RegistersDLG.hWnd, ecx, eax
                            pop     ecx
                            pop     eax
                            inc     ecx
                    ENDLOOP

                    mov     al, ShowHex
                    push    eax
                    mov     ShowHex, FALSE

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    invoke  PrtBase8,       pTEXTSTRING, z80registers.intmode
                    invoke  SendDlgItemMessage, RegistersDLG.hWnd, IDC_IM, WM_SETTEXT, 0, addr textstring

                    pop     eax
                    mov     ShowHex, al

                    ret
UpdateAllRegisters  endp

UpdateRegister      proc    uses    ebx esi edi,
                            CtrlID: DWORD,
                            Value:  WORD

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD


                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    invoke  PrtBase16,      pTEXTSTRING, Value, 0
                    invoke  SendDlgItemMessage, RegistersDLG.hWnd, CtrlID, WM_SETTEXT, 0, addr textstring
                    ret
UpdateRegister      endp



