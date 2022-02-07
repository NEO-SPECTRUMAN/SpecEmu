
CompareDlgProc              PROTO   :DWORD,:DWORD,:DWORD,:DWORD
SetReadWriteButtonStates    PROTO   :DWORD

.data?
align 4
CompareSelectionPtr     DWORD   ?
FillCLBhWndDlg          DWORD   ?
FCLB_Address            WORD    ?
FCLB_OldVal             BYTE    ?
FCLB_NewVal             BYTE    ?
FCLB_FilterbyOldNew     BYTE    ?
FCLB_FilterbyIncDec     BYTE    ?
FCLB_FilterNewVal       BYTE    ?
FCLB_FilterOldVal       BYTE    ?
FCLB_WantFilterNewVal   BYTE    ?
FCLB_WantFilterOldVal   BYTE    ?
FCLB_EliminateMode      BYTE    ?

FCLB_NewValText         db      6  dup (?)
FCLB_OldValText         db      6  dup (?)

.code
HandleCompareDialog:    invoke  DialogBoxParam, GlobalhInst, IDD_COMPAREDLG, hWnd, ADDR CompareDlgProc, NULL
                        ret

CompareDlgProc          proc    uses        ebx esi edi,
                                hWndDlg:    DWORD,
                                uMsg:       DWORD,
                                wParam:     DWORD,
                                lParam:     DWORD

                        local   CompDisplayhWnd: DWORD,
                                BreakControl:    DWORD,
                                wParamLow:       WORD,
                                wParamHigh:      WORD

                        mov     eax, hWndDlg
                        mov     FillCLBhWndDlg, eax    ; global handle for "FillCompareListBox" subroutine.

                        RESETMSG

OnInitDialog
                        mov     CompDisplayhWnd, $fnc (GetDlgItem, hWndDlg, IDC_COMPDISPLAYLST)
                        SETNEWWINDOWFONT    CompDisplayhWnd, Courier_8, CompDisplayFont, CompDisplayOldFont

                        invoke  CheckDlgButton, hWndDlg, IDC_COMPAREFILTER, ZeroExt(FCLB_FilterbyOldNew)
                        invoke  CheckDlgButton, hWndDlg, IDC_COMPAREINCDEC, ZeroExt(FCLB_FilterbyIncDec)
                        invoke  CheckDlgButton, hWndDlg, IDC_ELIMINATEENTRIES, ZeroExt(FCLB_EliminateMode)
                        invoke  SetDlgItemText, hWndDlg, IDC_COMPARENEWVALUE, ADDR FCLB_NewValText
                        invoke  SetDlgItemText, hWndDlg, IDC_COMPAREOLDVALUE, ADDR FCLB_OldValText
                        invoke  SendDlgItemMessage, hWndDlg, IDC_COMPAREOLDVALUE, EM_SETLIMITTEXT, 3, 0
                        invoke  SendDlgItemMessage, hWndDlg, IDC_COMPARENEWVALUE, EM_SETLIMITTEXT, 3, 0
                        invoke  SetReadWriteButtonStates, hWndDlg

                        call    FillCompareListbox
                        return  TRUE

OnDestroy
                        mov     CompDisplayhWnd, $fnc (GetDlgItem, hWndDlg, IDC_COMPDISPLAYLST)
                        SETOLDWINDOWFONT    CompDisplayhWnd, CompDisplayFont, CompDisplayOldFont
                        return  0

OnCommand
                        mov     eax, wParam
                        mov     wParamLow, ax
                        shr     eax, 16
                        mov     wParamHigh, ax

                        .if     wParam == IDCANCEL
                                call    FCLB_Cleanup
                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE
                        .endif

                        .if     wParamHigh == EN_CHANGE
                                .if     (wParamLow == IDC_COMPAREOLDVALUE) || (wParamLow == IDC_COMPARENEWVALUE)
                                        ; Edit fields for old/new byte values
                                        call    FillCompareListbox
                                .endif

                        .elseif wParamHigh == BN_CLICKED
                                movzx   eax, wParamLow
                                .if     eax == IDC_COMPAREFILTER
                                        xor     FCLB_FilterbyOldNew, TRUE
                                        .if     !ZERO?
                                                invoke  CheckDlgButton, hWndDlg, IDC_COMPAREINCDEC, 0
                                                mov     FCLB_FilterbyIncDec, FALSE
                                        .endif
                                        call    FillCompareListbox

                                .elseif eax == IDC_COMPAREINCDEC
                                        xor     FCLB_FilterbyIncDec, TRUE
                                        .if     !ZERO?
                                                invoke  CheckDlgButton, hWndDlg, IDC_COMPAREFILTER, 0
                                                mov     FCLB_FilterbyOldNew, FALSE
                                        .endif
                                        call    FillCompareListbox

                                .elseif (eax == IDC_COMPBREAKONREAD) || (eax == IDC_COMPBREAKONWRITE) || (eax == IDC_COMPBREAKONACCESS)
                                        movzx   eax, wParamLow
                                        mov     BreakControl, eax

                                        invoke  SendDlgItemMessage, hWndDlg, BreakControl, BM_GETSTATE, 0, 0
                                        and     eax, BST_CHECKED
                                        .if     eax != 0
                                                invoke  SendDlgItemMessage, hWndDlg, IDC_COMPDISPLAYLST, LB_GETCURSEL, 0, 0
                                                .if     eax != LB_ERR
                                                        mov     ax, [CompareSelectionTable+eax*2]
                                                        .if     BreakControl == IDC_COMPBREAKONREAD
                                                                call    StopatMemRead1
                                                        .elseif BreakControl == IDC_COMPBREAKONWRITE
                                                                call    StopatMemWrite1
                                                        .elseif BreakControl == IDC_COMPBREAKONACCESS
                                                                call    StopatMemAccess1
                                                        .endif
                                                .endif
                                        .else
                                                mov     Check_TraceHook, FALSE
                                        .endif
                                        invoke  SetReadWriteButtonStates, hWndDlg

                                .elseif eax == IDC_ELIMINATEENTRIES
                                        xor     FCLB_EliminateMode, TRUE
                                        call    FillCompareListbox
                                .endif

                        .elseif wParamHigh == LBN_SELCHANGE
                                .if     wParamLow == IDC_COMPDISPLAYLST     ; Addresses Listbox
                                        invoke  SetReadWriteButtonStates, hWndDlg
                                .endif
                        .endif

OnClose
                        call    FCLB_Cleanup
                        invoke  EndDialog, hWndDlg, NULL
                        return  TRUE

OnDefault
                        return  FALSE

                        DOMSG

CompareDlgProc          endp

SetReadWriteButtonStates    proc    uses        ebx esi edi,
                                    hWndDlg:    DWORD

                            LOCAL   hwinONREAD:     DWORD,
                                    hwinONWRITE:    DWORD,
                                    hwinONACCESS:   DWORD

                            local   textstring:     TEXTSTRING,
                                    pTEXTSTRING:    DWORD

                            mov     hwinONREAD,   $fnc (GetDlgItem, hWndDlg, IDC_COMPBREAKONREAD)
                            mov     hwinONWRITE,  $fnc (GetDlgItem, hWndDlg, IDC_COMPBREAKONWRITE)
                            mov     hwinONACCESS, $fnc (GetDlgItem, hWndDlg, IDC_COMPBREAKONACCESS)

                            invoke  SendMessage, hwinONREAD, BM_SETCHECK, FALSE, 0
                            invoke  SendMessage, hwinONWRITE, BM_SETCHECK, FALSE, 0
                            invoke  SendMessage, hwinONACCESS, BM_SETCHECK, FALSE, 0
                            invoke  SendMessage, hwinONREAD, WM_SETTEXT, 0, SADD("Read Access")
                            invoke  SendMessage, hwinONWRITE, WM_SETTEXT, 0, SADD("Write Access")
                            invoke  SendMessage, hwinONACCESS, WM_SETTEXT, 0, SADD("Read/Write Access")

                            .if     Check_TraceHook == FALSE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_COMPDISPLAYLST, LB_GETCURSEL, 0, 0
                                    xor     ebx, ebx
                                    cmp     eax, LB_ERR
                                    setne   bl
                                    invoke  EnableWindow, hwinONREAD, ebx
                                    invoke  EnableWindow, hwinONWRITE, ebx
                                    invoke  EnableWindow, hwinONACCESS, ebx
                            .else
                                    .if     TraceHook == offset StopMemReadHook
                                            invoke  EnableWindow, hwinONREAD, TRUE
                                            invoke  EnableWindow, hwinONWRITE, FALSE
                                            invoke  EnableWindow, hwinONACCESS, FALSE
                                            invoke  SendMessage, hwinONREAD, BM_SETCHECK, TRUE, 0
                                            mov     ebx, CTXT("Read ")
                                            mov     esi, hwinONREAD
                                            movzx   edi, StopMemReadAddr
                                    .elseif TraceHook == offset StopMemWriteHook
                                            invoke  EnableWindow, hwinONREAD, FALSE
                                            invoke  EnableWindow, hwinONWRITE, TRUE
                                            invoke  EnableWindow, hwinONACCESS, FALSE
                                            invoke  SendMessage, hwinONWRITE, BM_SETCHECK, TRUE, 0
                                            mov     ebx, CTXT("Write ")
                                            mov     esi, hwinONWRITE
                                            movzx   edi, StopMemWriteAddr
                                    .elseif TraceHook == offset StopMemAccessHook
                                            invoke  EnableWindow, hwinONREAD, FALSE
                                            invoke  EnableWindow, hwinONWRITE, FALSE
                                            invoke  EnableWindow, hwinONACCESS, TRUE
                                            invoke  SendMessage, hwinONACCESS, BM_SETCHECK, TRUE, 0
                                            mov     ebx, CTXT("Read/Write ")
                                            mov     esi, hwinONACCESS
                                            movzx   edi, StopMemAccessAddr
                                    .endif

                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDTEXTSTRING   pTEXTSTRING, ebx
                                    ADDCHAR         pTEXTSTRING, "("
                                    ADDTEXTDECIMAL  pTEXTSTRING, edi
                                    ADDCHAR         pTEXTSTRING, ")"
                                    invoke  SendMessage, esi, WM_SETTEXT, 0, addr textstring
                            .endif

                            ret

SetReadWriteButtonStates    endp

;########################################################################

FCLB_Cleanup:           lea     esi, CompareSelectionTable
                        lea     edi, EliminateTable
                        mov     ecx, (42240*2)+2     ; +2 for end marker word
                        rep     movsb

                        invoke  GetDlgItemText, [FillCLBhWndDlg], IDC_COMPARENEWVALUE, ADDR FCLB_NewValText, 5
                        invoke  GetDlgItemText, [FillCLBhWndDlg], IDC_COMPAREOLDVALUE, ADDR FCLB_OldValText, 5
                        ret

;########################################################################

.data?
align 4
FCLB_textstring         TEXTSTRING  <>
pFCLB_textstring        DWORD       ?

.code
FillCompareListbox:     mov     CompareSelectionPtr, offset CompareSelectionTable

                        invoke  SendDlgItemMessage, FillCLBhWndDlg, IDC_COMPDISPLAYLST, WM_SETREDRAW, FALSE, 0
                        invoke  SendDlgItemMessage, FillCLBhWndDlg, IDC_COMPDISPLAYLST, LB_RESETCONTENT, 0, 0

                        invoke  GetDlgItemInt, FillCLBhWndDlg, IDC_COMPARENEWVALUE, ADDR lpTranslated, FALSE
                        .if     lpTranslated == FALSE
                                mov     FCLB_WantFilterNewVal, FALSE
                        .else
                                .if     eax > 255
                                        mov     al, 255
                                .endif
                                mov     FCLB_FilterNewVal, al
                                mov     FCLB_WantFilterNewVal, TRUE
                        .endif

                        invoke  GetDlgItemInt, FillCLBhWndDlg, IDC_COMPAREOLDVALUE, ADDR lpTranslated, FALSE
                        .if     lpTranslated == FALSE
                                mov     FCLB_WantFilterOldVal, FALSE
                        .else
                                .if     eax > 255
                                        mov     al, 255
                                .endif
                                mov     FCLB_FilterOldVal, al
                                mov     FCLB_WantFilterOldVal, TRUE
                        .endif

                        .if     FCLB_EliminateMode == TRUE
                                lea     esi, EliminateTable
                                mov     ax, [esi]
                                or      ax, ax
                                je      FCLB_FullList   ; if no entries in table then do a full listing

FCLB_ElimLoop:                  mov     ax, [esi]
                                or      ax, ax
                                je      FCLB_ElimExit

                                add     esi, 2
                                push    esi
                                mov     FCLB_Address, ax
                                sub     ax, 23296
                                mov     esi, currentMachine.bank5 ;+6912         ; start at 23296
                                add     esi, 6912
                                add     esi, eax
                                lea     edi, MemSnapshot+6912   ; equiv. Bank5 in saved memory snapshot
                                add     edi, eax
                                call    FCLB_Check
                                pop     esi
                                jmp     FCLB_ElimLoop

FCLB_ElimExit:                  invoke  SendDlgItemMessage, FillCLBhWndDlg, IDC_COMPDISPLAYLST, WM_SETREDRAW, TRUE, 0
                                invoke  GetDlgItem, FillCLBhWndDlg, IDC_COMPDISPLAYLST
                                .if     eax != NULL
                                        invoke InvalidateRect, eax, NULL, TRUE
                                .endif
                                ret
                        .endif

FCLB_FullList:          mov     FCLB_Address, 23296
                        mov     esi, currentMachine.bank5   ;+6912         ; start at 23296
                        add     esi, 6912
                        lea     edi, MemSnapshot+6912   ; equiv. Bank5 in saved memory snapshot
                        mov     ecx, 42240              ; number of bytes to compare
FCLB_Loop:              call    FCLB_Check
                        inc     esi
                        inc     edi
                        inc     FCLB_Address
                        dec     ecx
                        jnz     FCLB_Loop

                        invoke  SendDlgItemMessage, FillCLBhWndDlg, IDC_COMPDISPLAYLST, WM_SETREDRAW, TRUE, 0
                        invoke  GetDlgItem, FillCLBhWndDlg, IDC_COMPDISPLAYLST
                        .if     eax != NULL
                                invoke InvalidateRect, eax, NULL, TRUE
                        .endif
                        ret

FCLB_Check:             mov     al, [esi]    ; al = new value
                        mov     bl, [edi]    ; bl = old value
                        cmp     al, bl
                        je      FCLB_EndCheck

                        .if     FCLB_FilterbyOldNew == TRUE
                                .if     FCLB_WantFilterOldVal == TRUE
                                        cmp     bl, FCLB_FilterOldVal
                                        jne     FCLB_EndCheck
                                .endif
                                .if     FCLB_WantFilterNewVal == TRUE
                                        cmp     al, FCLB_FilterNewVal
                                        jne     FCLB_EndCheck
                                .endif

                        .elseif FCLB_FilterbyIncDec == TRUE
                                mov     cl, al
                                sub     cl, bl
                                .if     (cl != 1) && (cl != -1)
                                        jmp     FCLB_EndCheck
                                .endif
                        .endif

                        pushad
                        mov     FCLB_OldVal, bl
                        mov     FCLB_NewVal, al

                        mov     edi, CompareSelectionPtr
                        add     CompareSelectionPtr, 2
                        mov     ax, FCLB_Address
                        mov     [edi], ax
                        mov     word ptr [edi+2], 0   ; NULL word end marker

                        invoke  INITTEXTSTRING, addr FCLB_textstring, addr pFCLB_textstring
                        ADDTEXTDECIMAL      pFCLB_textstring, FCLB_Address
                        ADDDIRECTTEXTSTRING pFCLB_textstring, " ("
                        ADDTEXTHEX          pFCLB_textstring, FCLB_Address
                        ADDDIRECTTEXTSTRING pFCLB_textstring, ")  "
                        ADDTEXTDECIMAL      pFCLB_textstring, FCLB_OldVal, ATD_SPACES
                        ADDDIRECTTEXTSTRING pFCLB_textstring, "   "
                        ADDTEXTDECIMAL      pFCLB_textstring, FCLB_NewVal, ATD_SPACES

                        invoke  SendDlgItemMessage, FillCLBhWndDlg, IDC_COMPDISPLAYLST, LB_ADDSTRING, 0, addr FCLB_textstring
                        popad

FCLB_EndCheck:          ret


.data?
even
StopMemAccessAddr       WORD    ?
StopMemReadAddr         WORD    ?
StopMemWriteAddr        WORD    ?

.code
;StopatMemAccess:        mov     ax, Z80PC
;
;StopatMemAccess1:     ; ax = break on access address
;                        mov     StopMemAccessAddr, ax
;                        mov     TraceHook, offset StopMemAccessHook
;                        mov     Check_TraceHook, TRUE
;                        ret
;
;align 16
;StopMemAccessHook:      mov     ax, StopMemAccessAddr
;                        cmp     ax, MemoryReadAddress
;                        je      @F
;                        cmp     ax, MemoryWriteAddress
;                        je      @F
;
;                        .if     WordLengthAccess == TRUE
;                                inc     ax          ; check for HB address as well
;                                cmp     ax, MemoryReadAddress
;                                je      @F
;                                cmp     ax, MemoryWriteAddress
;                                je      @F
;                        .endif
;                        ret
;
;@@:                     mov     TraceStopFlag,TRUE
;                        mov     UsePrevzPC,TRUE
;
;                        inc     MemoryReadAddress       ; prevent multiple triggers for the read address before next memory read
;                        inc     MemoryWriteAddress      ; prevent multiple triggers for the write address before next memory write
;                        ret

StopatMemAccess:        mov     ax, Z80PC

StopatMemAccess1:     ; ax = break on access address
                        mov     StopMemAccessAddr, ax   ; for showing address in debugger stop at edit box
                        mov     StopMemReadAddr, ax
                        mov     StopMemWriteAddr, ax
                        mov     TraceHook, offset StopMemAccessHook
                        mov     Check_TraceHook, TRUE
                        ret

align 16
StopMemAccessHook:      call    StopMemReadHook
                        call    StopMemWriteHook
                        ret

; ######################################################################

StopatMemRead:          mov     ax, Z80PC

StopatMemRead1:       ; ax = break on memread address
                        mov     StopMemReadAddr, ax
                        mov     TraceHook, offset StopMemReadHook
                        mov     Check_TraceHook, TRUE
                        ret

align 16
StopMemReadHook:        cmp     MemoryReadEvent, MEMACCESSNONE
                        retcc   z

                        mov     ax, MemoryReadAddress
                        cmp     ax, StopMemReadAddr
                        je      @F

                        .if     WordLengthAccess == TRUE
                                inc     ax          ; check for HB address as well
                                cmp     ax, StopMemReadAddr
                                je      @F
                        .endif
                        ret

@@:                     mov     TraceStopFlag, TRUE
                        mov     UsePrevzPC, TRUE

;                        inc     MemoryReadAddress       ; prevent multiple triggers for the read address before next memory read
                        ret

; ######################################################################

StopatMemWrite:         mov     ax, Z80PC

StopatMemWrite1:      ; ax = break on memwrite address
                        mov     StopMemWriteAddr, ax
                        mov     TraceHook, offset StopMemWriteHook
                        mov     Check_TraceHook, TRUE
                        ret

align 16
StopMemWriteHook:       cmp     MemoryWriteEvent, MEMACCESSNONE
                        retcc   z

                        mov     ax, MemoryWriteAddress
                        cmp     ax, StopMemWriteAddr
                        je      @F

                        .if     WordLengthAccess == TRUE
                                inc     ax          ; check for HB address as well
                                cmp     ax, StopMemWriteAddr
                                je      @F
                        .endif
                        ret

@@:                     mov     TraceStopFlag, TRUE
                        mov     UsePrevzPC, TRUE

;                        inc     MemoryWriteAddress      ; prevent multiple triggers for the write address before next memory write
                        ret

; ######################################################################

ClearStopHooks:         mov     TraceHook, 0
                        mov     Check_TraceHook, FALSE
                        ret


