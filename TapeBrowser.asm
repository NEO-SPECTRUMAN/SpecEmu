
PopulateTapeBox         PROTO   :DWORD
SetInfoSeekStatus       PROTO   :DWORD
ParseInfoSeekText       PROTO
ParseInfoChar           PROTO
SubstituteInfoChar      PROTO
PopulateArchiveInfo     PROTO   :DWORD,:DWORD
ClearArchiveInfo        PROTO   :DWORD
PositionTapeDialog      PROTO   :DWORD
SaveTZXArcFile          PROTO   :DWORD,:DWORD
HandleArcText           PROTO   :DWORD,:DWORD,:BYTE
SetTapeWindowTitle      PROTO   :DWORD
QueryInfoSeek           PROTO   :DWORD
WOSInfoSeekDlgProc      PROTO   :DWORD,:DWORD,:DWORD,:DWORD
InfoSeekCleanUp         PROTO
QUERYTEXTEDIT_SubclassProc  PROTO   :DWORD,:DWORD,:DWORD,:DWORD
AddSpeccyFilename       PROTO   :DWORD,:DWORD

.data
InfoSeekFilename        db      "C:\tzxblock.tzx", 0
szTapeArcFilter         db      "TZX files (*.tzx)", 0, "*.tzx", 0, 0
InfoSeekString          db      "http://www.worldofspectrum.org/infoseek.cgi?regexp="
InfoSeekFile            BYTE    128 dup(?)
InfoNullString          db      0

.data?
align 4
QUERYTEXT_Handle        DWORD   ?
OrigQUERYTEXTWndProc    DWORD   ?

TB_BlockCnt             DWORD   ?

lpArchiveMemory         DWORD   ?
ArchiveSize             DWORD   ?
ArchiveInfoBlockPtrs    DWORD   1024 dup(?)  ; pointer to archive info blocks in Infoseek file

NEWTZXCurrBlock         WORD    ?
HeaderDataBlock         BYTE    ?
WantInfoSeek            BYTE    ?
.code

InfoSeekCleanUp         proc
                        invoke  DeleteFile, addr InfoSeekFilename
                        ret
InfoSeekCleanUp         endp

QUERYTEXTEDIT_SubclassProc  proc    uses    ebx esi edi,
                                    hWin:   DWORD,
                                    uMsg:   DWORD,
                                    wParam: DWORD,
                                    lParam: DWORD

                            switch  uMsg
                                    case    WM_GETDLGCODE
                                            return  DLGC_WANTALLKEYS
                                    case    WM_CHAR
                                            switch  wParam
                                                    case    VK_RETURN
                                                            mov     wParam, 0   ; prevent Beep
                                                            invoke  QueryInfoSeek, $fnc (GetParent, hWin)
                                                            return	0
                                            endsw
                            endsw

                            invoke  CallWindowProc, OrigQUERYTEXTWndProc, hWin, uMsg, wParam, lParam
                            ret

QUERYTEXTEDIT_SubclassProc  endp

TapeBrowserDlgProc  proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   CombohWnd:  DWORD

                    local   ofn:        OPENFILENAME

                    local   t_filename[MAX_PATH]:   BYTE

    .if uMsg == WM_INITDIALOG
            CLEARSOUNDBUFFERS

            invoke  SetTapeWindowTitle, hWndDlg

            mov     lpArchiveMemory, 0

            mov     CombohWnd, $fnc (GetDlgItem, hWndDlg, IDC_TAPEBOXLST)
            SETNEWWINDOWFONT    CombohWnd, Courier_8, TapeBoxFont, TapeBoxOldFont

            invoke  SendDlgItemMessage, hWndDlg, IDC_FULLTITLE,  EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_PUBLISHER,  EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_AUTHORS,    EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_YEAR,       EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_LANGUAGE,   EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_TYPE,       EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_PRICE,      EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_PROTECTION, EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_ORIGIN,     EM_SETLIMITTEXT, 255, 0
            invoke  SendDlgItemMessage, hWndDlg, IDC_COMMENT,    EM_SETLIMITTEXT, 255, 0

            invoke  GetDlgItem, hWndDlg, IDC_INFOSEEKQUERYTEXT
            mov     QUERYTEXT_Handle, eax           ; window handle of query text edit box
            invoke  SetWindowLong, QUERYTEXT_Handle, GWL_WNDPROC, ADDR QUERYTEXTEDIT_SubclassProc
            mov     OrigQUERYTEXTWndProc, eax

            xor     ebx, ebx
            cmp     LoadTapeType, Type_NONE
            setne   bl
            invoke  EnableWindow, $fnc (GetDlgItem, hWndDlg, IDC_EJECTTAPE), ebx

            invoke  PopulateTapeBox, hWndDlg
            invoke  SetInfoSeekStatus, hWndDlg

            ifc     FullScreenMode eq TRUE then mov WantInfoSeek, FALSE ; force infoseek for fullscreen mode
            movzx   ebx, WantInfoSeek
            invoke  CheckDlgButton, hWndDlg, IDC_INFOSEEKCHECK, ebx
            ifc     FullScreenMode eq TRUE then invoke  EnableWindow, $fnc (GetDlgItem, hWndDlg, IDC_INFOSEEKCHECK), FALSE  ; disable in fullscreen mode

            invoke  PositionTapeDialog, hWndDlg     ; must be done last!

            invoke  SendMessage, hWndDlg, WM_SETICON, ICON_BIG, $fnc (LoadIcon, hInstance, IDI_TAPEICON)
            return  TRUE

    .elseif uMsg == WM_CLOSE
            invoke  SetWindowLong, QUERYTEXT_Handle, GWL_WNDPROC, OrigQUERYTEXTWndProc
            invoke  EndDialog, [hWndDlg], NULL
            return  TRUE

    .elseif uMsg == WM_DESTROY
            .if     lpArchiveMemory != 0
                    invoke  GlobalFree, lpArchiveMemory
            .endif
            mov     CombohWnd, $fnc (GetDlgItem, hWndDlg, IDC_TAPEBOXLST)
            SETOLDWINDOWFONT    CombohWnd, TapeBoxFont, TapeBoxOldFont
            return  0

    .elseif uMsg == WM_COMMAND
            .if     $HighWord (wParam) == BN_CLICKED
                    movzx   eax, $LowWord (wParam)
                    .if     eax == IDC_OK     ; OK button
                            mov     ax, [NEWTZXCurrBlock]
                            mov     [TZXCurrBlock], ax
                            call    InitTape
                            invoke  SendMessage, [hWndDlg], WM_CLOSE, 0, 0
                            return  TRUE

                    .elseif eax == IDCANCEL     ; Cancel button
                            invoke  SendMessage, [hWndDlg], WM_CLOSE, 0, 0
                            return  TRUE

                    .elseif eax == IDC_INFOSEEKCHECK  ; InfoSeek checkbox
                            .if     FullScreenMode == FALSE
                                    ; enabled only when not in fullscreen mode
                                    xor     WantInfoSeek, TRUE
                                    invoke  PositionTapeDialog, hWndDlg
                            .endif
                            return  TRUE

                    .elseif eax == IDC_OPENTAPEFILE   ; Open Tape File
                            invoke  InsertTape
                            .if     eax == TRUE
                                    invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_EJECTTAPE), TRUE
                                    invoke  SetTapeWindowTitle, hWndDlg
                            .endif
                            invoke  PopulateTapeBox, hWndDlg
                            invoke  SetInfoSeekStatus, hWndDlg
                            invoke  SetFocus, hWndDlg
                            return  TRUE

                    .elseif eax == IDC_EJECTTAPE  ; InfoSeek checkbox
                            invoke  CloseTapeFile
                            invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_EJECTTAPE), FALSE
                            invoke  SetTapeWindowTitle, hWndDlg
                            invoke  PopulateTapeBox, hWndDlg
                            invoke  SetInfoSeekStatus, hWndDlg
                            return  TRUE

                    .elseif eax == IDC_SAVETAPEFILE       ; Save Tape File
                            invoke  SaveTZXArcFile, hWndDlg, addr inserttapefilename
                            return  TRUE

                    .elseif eax == IDC_SAVEASTAPEFILE     ; Save As Tape File
                            invoke  SaveFileName, hWndDlg, SADD ("Save TZX File As"), addr szTapeArcFilter, addr ofn, addr t_filename, addr TZXExt, 0
                            .if     eax != 0
                                    invoke  SaveTZXArcFile, hWndDlg, addr t_filename
                            .endif
                            return  TRUE

                    .elseif eax == IDC_FILTERTEXT   ; Filter Infoseek string
                            invoke  GetDlgItemText, hWndDlg, IDC_INFOSEEKQUERYTEXT, ADDR InfoSeekFile, sizeof InfoSeekFile-1
                            invoke  ParseInfoSeekText
                            invoke  SetDlgItemText, hWndDlg, IDC_INFOSEEKQUERYTEXT, ADDR InfoSeekFile
                            return  TRUE

                    .elseif eax == IDC_QUERYINFOSEEK  ; Query Infoseek for Archive Info blocks
                            invoke  QueryInfoSeek, hWndDlg
                            return  TRUE
                    .endif

            .elseif $HighWord (wParam) == LBN_SELCHANGE ; also for CBN_SELCHANGE (same value)
                    .if     $LowWord (wParam) == IDC_ARCINFOLISTBOX ; Archive Info Listbox
                            invoke  SendDlgItemMessage, hWndDlg, IDC_ARCINFOLISTBOX, LB_GETCURSEL, 0, 0
                            .if     eax != LB_ERR
                                    mov     esi, [ArchiveInfoBlockPtrs+eax*4]
                                    .if     esi != 0
                                            invoke  PopulateArchiveInfo, hWndDlg, esi
                                    .endif
                            .endif
                            return  TRUE

                    .elseif $LowWord (wParam) == IDC_TAPEBOXLST     ; TapeBrowse combo box
                            invoke  SendDlgItemMessage, hWndDlg, IDC_TAPEBOXLST, LB_GETCURSEL, 0, 0
                            mov     [NEWTZXCurrBlock], ax
                            return  TRUE
                    .endif

            .endif
    .endif
    return FALSE

TapeBrowserDlgProc  endp

.data
hbrStaticBackground dd  0

.code
WOSInfoSeekDlgProc  proc    uses        ebx esi edi,
                            hWndDlg     :DWORD,
                            uMsg        :DWORD,
                            wParam      :DWORD,
                            lParam      :DWORD

                            LOCAL       wParamLow:  WORD, wParamHigh:   WORD

                    switch  uMsg
                            case    WM_INITDIALOG
                                    mov     hbrStaticBackground, $fnc(CreateSolidBrush, 0FF0000h)
                            case    WM_CTLCOLORSTATIC
                                    invoke  SetTextColor, wParam, 0FFFFFFh
                                    invoke  SetBkMode, wParam, TRANSPARENT
                                    return  hbrStaticBackground
                    endsw
                    return  FALSE

WOSInfoSeekDlgProc  endp

QueryInfoSeek       proc    uses        ebx esi edi,
                            hWndDlg:    DWORD

                    local   hWndWOSDLG:      DWORD
                    local   ArcInfoCount:    DWORD
                    local   tempstring[256]: BYTE

                    invoke  SendDlgItemMessage, hWndDlg, IDC_ARCINFOLISTBOX, LB_RESETCONTENT, 0, 0
                    invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_ARCINFOLISTBOX), FALSE
                    invoke  SetDlgItemInt, hWndDlg, IDC_NUMARCINFOBLOCKS, 0, FALSE

                    invoke  GetDlgItemText, hWndDlg, IDC_INFOSEEKQUERYTEXT, addr InfoSeekFile, sizeof InfoSeekFile-1
                    invoke  ParseInfoSeekText
                    .if     byte ptr [InfoSeekFile] == 0
                            invoke  SetDlgItemText, hWndDlg, IDC_INFOSEEKACTUALQUERYTEXT, ADDR InfoNullString
                            return  TRUE
                    .endif
                    APPENDTEXTSTRING    offset  InfoSeekFile, CTXT("&model=spectrum&tzxblock")
                    invoke  SetDlgItemText, hWndDlg, IDC_INFOSEEKACTUALQUERYTEXT, addr InfoSeekString

                    mov     hWndWOSDLG, $fnc (CreateDialogParam, GlobalhInst, IDD_WOSInfoSeekDLG, hWndDlg, addr WOSInfoSeekDlgProc, NULL)

                    invoke  GetInetFile,    hInstance, addr InfoSeekString, addr InfoSeekFilename
                    push    eax
                    .if     hWndWOSDLG != NULL
                            invoke  Sleep, 100
                            invoke  DestroyWindow, hWndWOSDLG
                    .endif
                    pop     eax
                    .if     eax == FALSE
                            invoke  ShowMessageBox, hWndDlg, SADD("Infoseek Query Failed"), addr szWindowName, MB_OK or MB_ICONERROR
                            return  TRUE
                    .endif

                    .if     lpArchiveMemory != 0
                            invoke  GlobalFree, lpArchiveMemory
                    .endif

                    invoke  ReadFileToMemory,   addr InfoSeekFilename, addr lpArchiveMemory, addr ArchiveSize
                    .if     eax == 0
                            mov     lpArchiveMemory, 0
                            ret
                    .endif

                    lea     edi, ArchiveInfoBlockPtrs
                    mov     ecx, sizeof ArchiveInfoBlockPtrs/4
                    xor     eax, eax
                    rep     stosd

                    mov     ArcInfoCount, 0

                    lea     edi, ArchiveInfoBlockPtrs
                    mov     esi, lpArchiveMemory
                    mov     ebx, ArchiveSize

                    mov     eax, 10                 ; sizeof TZX header
                    add     esi, eax                ; skip TZX header
                    sub     ebx, eax
                    .if     CARRY?
                            return  TRUE
                    .endif

                    ; esi points to Archive Info block
                    .while  TRUE
                            sub     ebx, 3                  ;  3 bytes = block ID + block length
                            .break .if CARRY?

                            movzx   ecx, word ptr [esi+1]   ; ecx = block length
                            sub     ebx, ecx                ; whole block available?
                            .break .if CARRY?

                            pushad
                            add     esi, 5  ; point to first text string length (should be title text)
                            lea     edi, tempstring
                            movzx   ecx, byte ptr [esi]
                            inc     esi     ; point to text
                            .if     ecx > sizeof tempstring-1
                                    mov     ecx, sizeof tempstring-1
                            .endif
                            rep     movsb
                            mov     byte ptr [edi], 0
                            
                            invoke  SendDlgItemMessage, hWndDlg, IDC_ARCINFOLISTBOX, LB_ADDSTRING,
                                                        0, ADDR tempstring
                            popad

                            ; store archive info block pointer
                            mov     [edi], esi
                            add     edi, 4
                            inc     ArcInfoCount

                            ; abort if ArchiveInfo table is full
                            .break  .if ArcInfoCount == sizeof ArchiveInfoBlockPtrs/4

                            ; advance to next (possible) archive info block
                            lea     esi, [esi+ecx+3]        ; add block length + 3 bytes (block ID + block length)
                    .endw

                    ; populate with first Archive Info block data if available
                    mov     esi, [ArchiveInfoBlockPtrs]
                    .if     esi != 0
                            invoke  PopulateArchiveInfo, hWndDlg, esi
                            invoke  SendDlgItemMessage, hWndDlg, IDC_ARCINFOLISTBOX, LB_SETCURSEL, 0, 0
                            invoke  EnableWindow, $fnc (GetDlgItem, hWndDlg, IDC_ARCINFOLISTBOX), TRUE
                            invoke  SetFocus, $fnc (GetDlgItem, hWndDlg, IDC_ARCINFOLISTBOX)
                    .endif

                    invoke  SetDlgItemInt, hWndDlg, IDC_NUMARCINFOBLOCKS, ArcInfoCount, FALSE

                    return  TRUE

QueryInfoSeek       endp

SetInfoSeekStatus       proc    uses        ebx,
                                hWndDlg:    DWORD

                        invoke  SendDlgItemMessage, hWndDlg, IDC_ARCINFOLISTBOX, LB_RESETCONTENT, 0, 0
                        invoke  SetDlgItemText,     hWndDlg, IDC_INFOSEEKQUERYTEXT, ADDR InfoNullString
                        invoke  SetDlgItemText,     hWndDlg, IDC_INFOSEEKACTUALQUERYTEXT, ADDR InfoNullString

                        .if     LoadTapeType == Type_TZX    ; if TZX tape inserted
                                mov     ebx, TRUE
                        .else
                                mov     ebx, FALSE
                        .endif

                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_QUERYINFOSEEK),     ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_INFOSEEKQUERYTEXT), ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_FILTERTEXT),        ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_ARCINFOLISTBOX),    ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_SAVETAPEFILE),      ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_SAVEASTAPEFILE),    ebx

                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_FULLTITLE),         ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_PUBLISHER),         ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_AUTHORS),           ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_YEAR),              ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_LANGUAGE),          ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_TYPE),              ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_PRICE),             ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_PROTECTION),        ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_ORIGIN),            ebx
                        invoke  EnableWindow, $fnc(GetDlgItem, hWndDlg, IDC_COMMENT),           ebx

                        .if     ebx == TRUE
                                ; if a TZX file
                                invoke  NameFromPath, addr inserttapefilename, addr InfoSeekFile
                                invoke  ParseInfoSeekText
                                invoke  SetDlgItemText, hWndDlg, IDC_INFOSEEKQUERYTEXT, addr InfoSeekFile
                        .else
                                ; no tape or not a TZX file
                        .endif
                        ret

SetInfoSeekStatus       endp

ParseInfoSeekText       proc    uses    esi edi

                        lea     esi, InfoSeekFile
                        mov     edi, esi

          NextInfoChar: lodsb
                        invoke  ParseInfoChar
                        .if     ZERO?
                                .if     (al == " ") || (al == "-") || (al == "+")
                                    @@: lodsb
                                        invoke  SubstituteInfoChar
                                        .if     (al == " ") || (al == "-") || (al == "+")
                                                jmp     @B
                                        .endif
                                        invoke  ParseInfoChar
                                        .if     !ZERO?
                                                jmp     EndInfoStr
                                        .endif
                                        dec     esi
                                        mov     al, "+"
                                .endif
                                stosb
                                jmp     NextInfoChar
                        .endif
          EndInfoStr:   mov     byte ptr [edi], 0

                        ret
ParseInfoSeekText       endp

; return ZERO flag set for legal chars, else ZERO flag clear
; can substitute char codes
ParseInfoChar           proc    ; al = character code
                        .if     (al == 0) || (al == ".") || (al == "(") || (al == "_")
                                cmp     al, 255     ; return Illegal
                                ret
                        .endif
                        invoke  SubstituteInfoChar
                        cmp     al, al  ; return Legal
                        ret
ParseInfoChar           endp

SubstituteInfoChar      proc    ; al = character code
                        .if     (al == 0) || (al == ".") || (al == "(") || (al == "_")
                                ret
                        .endif
                        .if     (al == "+") || (al == "'")
                                ret
                        .endif
                        .if     (al >= "0") && (al <= "9")
                                ret
                        .endif
                        .if     (al >= "a") && (al <= "z")
                                ret
                        .endif
                        .if     (al >= "A") && (al <= "Z")
                                ret
                        .endif
                        mov     al, " "
                        ret
SubstituteInfoChar      endp

;esi=address of Speccy filename
AddSpeccyFilename   proc    lpText:     DWORD,
                            lpspecfn:   DWORD

                    pushad
                    mov     edi, $fnc (GETTEXTPTR, lpText)
                    mov     esi, lpspecfn

                    mov     al, 34
                    mov     [edi], al
                    inc     edi

                    mov     cl, 10
        @@:         mov     al, [esi]
                    inc     esi
                    .if     (al < 32) || (al > 127)
                            mov     al, " "
                    .endif
                    mov     [edi], al
                    inc     edi
                    dec     cl
                    jnz     @B

                    mov     al, 34
                    mov     [edi], al
                    inc     edi
                    xor     al, al
                    mov     [edi], al
                    invoke  SETTEXTPTR, lpText, edi

                    popad
                    ret
AddSpeccyFilename   endp

PositionTapeDialog  proc    uses            esi edi,
                            hWndDlg:        DWORD,

                    local   winRect:        RECT,
                            wWidth:         DWORD,
                            wHeight:        DWORD,
                            DisplayW:       DWORD,
                            DisplayH:       DWORD

                    .if     FullScreenMode == TRUE
                            mov     DisplayW, DDWidth
                            mov     DisplayH, DDHeight
                    .else
                            m2m     DisplayW, sWid
                            m2m     DisplayH, sHgt
                    .endif

                    invoke  GetWindowRect, hWndDlg, addr winRect
                    mov     eax, winRect.right
                    sub     eax, winRect.left
                    mov     wWidth, eax

                    .if     WantInfoSeek == TRUE
                            mov     wHeight, 559
                    .else
                            mov     wHeight, 250
                    .endif

                    mov     winRect.top, $fnc (TopXY, wHeight, DisplayH)

                    invoke  SetWindowPos, hWndDlg, HWND_TOP, winRect.left, winRect.top, wWidth, wHeight, NULL
                    ret
PositionTapeDialog  endp

PopulateArchiveInfo proc    uses                esi edi ebx,
                            hWndDlg:            DWORD,
                            lpArchiveInfoBlock: DWORD

                    local   TextID:             DWORD
                    local   BlockLength:        DWORD
                    local   tempstring[260]:    BYTE

                    invoke  ClearArchiveInfo, hWndDlg

                    mov     esi, lpArchiveInfoBlock ; esi points to block ID
                    xor     eax, eax

                    lodsb
                    .if     al != 32h
                            ret                     ; wrong block type!
                    .endif

                    lodsw
                    mov     BlockLength, eax

                    movzx   eax, byte ptr [esi]     ; number of text strings
                    inc     esi                     ; esi points to text ID byte

                    SETLOOP eax
                            movzx   eax, byte ptr [esi]
                            inc     esi
                            mov     TextID, eax

                            movzx   ecx, byte ptr [esi]     ; ecx = text string length
                            inc     esi
                            lea     edi, tempstring
                            .if     ecx > sizeof tempstring-1
                                    mov     ecx, sizeof tempstring-1
                            .endif
                            .if     ecx > 0
                                    rep     movsb
                            .endif
                            mov     byte ptr [edi], 0

                            switch  TextID
                                    case    0
                                            mov     edx, IDC_FULLTITLE
                                    case    1
                                            mov     edx, IDC_PUBLISHER
                                    case    2
                                            mov     edx, IDC_AUTHORS
                                    case    3
                                            mov     edx, IDC_YEAR
                                    case    4
                                            mov     edx, IDC_LANGUAGE
                                    case    5
                                            mov     edx, IDC_TYPE
                                    case    6
                                            mov     edx, IDC_PRICE
                                    case    7
                                            mov     edx, IDC_PROTECTION
                                    case    8
                                            mov     edx, IDC_ORIGIN
                                    case    0FFh
                                            mov     edx, IDC_COMMENT
                                    .else
                                            mov     edx, 0
                            endsw
                            .if     edx != 0
                                    invoke  SetDlgItemText, hWndDlg, edx, addr tempstring
                            .endif
                    ENDLOOP


                    ret
PopulateArchiveInfo endp

ClearArchiveInfo    proc    hWndDlg:    DWORD
                    invoke  SetDlgItemText, hWndDlg, IDC_FULLTITLE,  addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_PUBLISHER,  addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_AUTHORS,    addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_YEAR,       addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_LANGUAGE,   addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_TYPE,       addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_PRICE,      addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_PROTECTION, addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_ORIGIN,     addr InfoNullString
                    invoke  SetDlgItemText, hWndDlg, IDC_COMMENT,    addr InfoNullString
                    ret
ClearArchiveInfo    endp

; file type known to be TZX
; inserttapefilename = filename
; _tapfileptr = pointer to start of tape data memory
; _tapfilesize = size of tape data memory

.data?
Arc_tempstring      BYTE    256   dup(?)
Arc_TZXID           BYTE    ?
Arc_TZXBlockLength  WORD    ?
Arc_TZXNumStrings   BYTE    ?
Arc_TZXBlockData    BYTE    16384 dup(?)

.code
SaveTZXArcFile      proc    uses            ebx esi edi,
                            hWndDlg:        DWORD,
                            lpFilename:     DWORD

                    LOCAL   TZXFilehandle:  DWORD,
                            BytesWritten:   DWORD

                    invoke	CreateFile,	lpFilename, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                    mov     TZXFilehandle, eax

                    .if		eax == INVALID_HANDLE_VALUE
                            invoke	ShowMessageBox, hWndDlg, SADD("Unable to open TZX file for saving"), addr szWindowName, MB_OK or MB_ICONERROR
                            ret
                    .endif

                    mov     esi, _tapfileptr    ; pointer to TZX data
                    mov     ebx, _tapfilesize   ; size of TZX data

                    ; write TZX header
                    sub     ebx, 10
                    .if     CARRY?
                            invoke  CloseHandle, TZXFilehandle
                            ret
                    .endif
                    invoke  WriteFile, TZXFilehandle, esi, 10, ADDR BytesWritten, NULL
                    add     esi, 10

                    ; if first block is an Archive Info block
                    ; then we skip the block and replace with our own constructed block
                    .if     ebx < 3
                            invoke  CloseHandle, TZXFilehandle
                            ret
                    .endif
                    .if     byte ptr [esi] == 32h
                            movzx   ecx, word ptr [esi+1]   ; get block length
                            add     ecx, 3                  ; add 3 (block ID + block length)
                            add     esi, ecx                ; skip the block
                            sub     ebx, ecx                ; adjust remaining length of TZX data
                            .if     CARRY?
                                    invoke  CloseHandle, TZXFilehandle
                                    ret
                            .endif
                    .endif

                    ; now construct a new Archive Info block
                    pushad
                    mov     Arc_TZXID, 32h
                    mov     Arc_TZXBlockLength, 0
                    mov     Arc_TZXNumStrings, 0
                    lea     edi, Arc_TZXBlockData

                    invoke  HandleArcText, hWndDlg, IDC_FULLTITLE,  0
                    invoke  HandleArcText, hWndDlg, IDC_PUBLISHER,  1
                    invoke  HandleArcText, hWndDlg, IDC_AUTHORS,    2
                    invoke  HandleArcText, hWndDlg, IDC_YEAR,       3
                    invoke  HandleArcText, hWndDlg, IDC_LANGUAGE,   4
                    invoke  HandleArcText, hWndDlg, IDC_TYPE,       5
                    invoke  HandleArcText, hWndDlg, IDC_PRICE,      6
                    invoke  HandleArcText, hWndDlg, IDC_PROTECTION, 7
                    invoke  HandleArcText, hWndDlg, IDC_ORIGIN,     8
                    invoke  HandleArcText, hWndDlg, IDC_COMMENT,    0FFh

                    .if     Arc_TZXBlockLength > 0
                            movzx   ecx, Arc_TZXBlockLength
                            inc     Arc_TZXBlockLength  ; account for no. of text strings in block length
                            add     ecx, 4          ; add 4 (block ID(1) + block length(2) + number of text strings(1))
                            invoke  WriteFile, TZXFilehandle, ADDR Arc_TZXID, ecx, ADDR BytesWritten, NULL
                    .endif
                    popad

                    ; write remainder of TZX data
                    .if     ebx > 0
                            invoke  WriteFile, TZXFilehandle, esi, ebx, ADDR BytesWritten, NULL
                    .endif

                    invoke  CloseHandle, TZXFilehandle
                    ret
SaveTZXArcFile      endp

; must not preserve EDI register!
HandleArcText       proc    hWndDlg:    DWORD,
                            EditBoxID:  DWORD,
                            TextID:     BYTE

                    local   TZXTextLength:  DWORD

                    invoke  SendDlgItemMessage, hWndDlg, EditBoxID, WM_GETTEXTLENGTH, 0, 0
                    .if     eax > 0
                            .if     eax > 255
                                    mov     eax, 255    ; max chars allowed per entry
                            .endif
                            mov     TZXTextLength, eax  ; length without NULL byte
                            mov     cl, TextID
                            mov     [edi], cl           ; store text string type
                            inc     edi
                            stosb                       ; store text length field
                            add     Arc_TZXBlockLength, 2

                            mov     ecx, eax
                            inc     ecx                 ; account for NULL byte
                            invoke  SendDlgItemMessage, hWndDlg, EditBoxID, WM_GETTEXT, ecx, ADDR Arc_tempstring

                            lea     esi, Arc_tempstring
                            mov     ecx, TZXTextLength
                            add     Arc_TZXBlockLength, cx
                            rep     movsb

                            inc     Arc_TZXNumStrings
                    .endif
                    ret
HandleArcText       endp

SetTapeWindowTitle  proc    hWndDlg :DWORD

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Tape Browser"

                    .if     LoadTapeType != Type_NONE
                            ADDCHAR     pTEXTSTRING, " ", "-", " "
                            invoke  NameFromPath, addr inserttapefilename, $fnc (GETTEXTPTR, pTEXTSTRING)
                    .endif

                    invoke  SetWindowText, hWndDlg, addr textstring
                    ret
SetTapeWindowTitle  endp

PopulateTapeBox     proc    uses        esi edi ebx,
                            hWndDlg:    DWORD

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

            invoke  ClearArchiveInfo, hWndDlg

            invoke  SendDlgItemMessage, hWndDlg, IDC_TAPEBOXLST, LB_RESETCONTENT, 0, 0

            mov     [HeaderDataBlock], FALSE
            mov     [TB_BlockCnt], 0

            cmp     LoadTapeType, Type_NONE
            je      TB_InitDone

            mov     esi, [TZXBlockPtrs]
TB_Loop:    mov     eax, [esi]
            add     esi, 4
            or      eax, eax
            je      TB_InitDone

            push    esi

            push    eax
            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

            mov     eax, [TB_BlockCnt]
            ADDTEXTDECIMAL  pTEXTSTRING, ax, ATD_SPACES
            ADDCHAR         pTEXTSTRING, ":", " "
            pop     eax

            mov     esi, eax    ; esi = address of this tape block's data/ID (for TZX)

; if this is a TAP file then ESI = address of standard .TAP data structure
; if this is a TZX file then ESI = address of this TZX block's ID number
; if this is a PZX file then ESI = address of this PZX block's ID string

            .if     LoadTapeType == Type_PZX    ; if tape is a PZX file
                    switch  dword ptr [esi]
                    case    "SLUP"
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "PULS"
                    case    "ATAD"
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "DATA"
                    case    "POTS"
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "STOP"
                    case    "SWRB"
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "BRWS"
                            mov     ecx, [esi+4]
                            lea     esi, [esi+8]
                            .if     ecx > 0
                                    push    ecx
                                    ADDCHAR pTEXTSTRING, " ", "{"
                                    pop     ecx
                                    ADDTEXTSTRINGLENGTH pTEXTSTRING, esi, ecx
                                    ADDCHAR pTEXTSTRING, "}"
                            .endif
                    case    "SUAP"
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "PAUS {0x"
                            mov     eax, [esi+8]
                            and     eax, 7FFFFFFFh
                            ADDTEXTHEX  pTEXTSTRING, eax
                            ADDDIRECTTEXTSTRING pTEXTSTRING, " cycles, ~"
                            invoke  IntDiv, dword ptr [esi+8], 3500
                            ADDTEXTDECIMAL      pTEXTSTRING, eax
                            ADDDIRECTTEXTSTRING pTEXTSTRING, " ms}"
                    .else
                            SETLOOP 4
                                    lodsb
                                    .if     (al < 32) || (al > 127)
                                            mov     al, "."
                                    .endif
                                    ADDCHAR pTEXTSTRING, al
                            ENDLOOP
                    endsw
                    jmp     TB_NextBlock
            .endif

            .if     LoadTapeType == Type_TAP    ; if tape is a TAP file
                    jmp     TB_Block10          ; then it *is* a block 10 standard loader
            .endif

            mov     al, [esi]

            .if     al == 10h
TB_Block10:
                    .if     LoadTapeType != Type_TAP
                            add     esi, 3
                    .endif

                    movzx   eax, word ptr [esi]     ; eax = block length
                    add     esi, 2

                    .if     eax == 19               ; header=17 bytes+flag+checksum
                            mov     bl,[esi]

                            .if     bl == 0             ; 0=header
                                    mov     bl,[esi+1]      ; header type byte

                                    .if     bl == 0         ; PROGRAM header
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "PROGRAM: "
                                            push    esi
                                            add     esi, 2
                                            invoke  AddSpeccyFilename, pTEXTSTRING, esi
                                            pop     esi
                                            xor     eax, eax
                                            mov     ax, [esi+14]
                                            .if     eax < 32768
                                                    push    eax
                                                    ADDDIRECTTEXTSTRING pTEXTSTRING, " LINE "
                                                    pop     eax
                                                    ADDTEXTDECIMAL  pTEXTSTRING, eax
                                            .endif
                                            mov     HeaderDataBlock, TRUE
                                            jmp     TB_NextBlock
    
                                    .elseif bl == 1     ; Numeric Array
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "NUMBER:  "
                                            push    esi
                                            add     esi, 2
                                            invoke  AddSpeccyFilename, pTEXTSTRING, esi
                                            pop     esi
                                            ADDCHAR pTEXTSTRING, byte ptr [esi+15]     ; variable name
                                            ADDCHAR pTEXTSTRING, "("
                                            ADDCHAR pTEXTSTRING, ")"
                                            mov     HeaderDataBlock, TRUE
                                            jmp     TB_NextBlock

                                    .elseif bl == 2     ; Character Array
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "CHAR:    "
                                            push    esi
                                            add     esi, 2
                                            invoke  AddSpeccyFilename, pTEXTSTRING, esi
                                            pop     esi
                                            ADDCHAR pTEXTSTRING, byte ptr [esi+15]     ; variable name
                                            ADDCHAR pTEXTSTRING, "$"
                                            ADDCHAR pTEXTSTRING, "("
                                            ADDCHAR pTEXTSTRING, ")"
                                            mov     HeaderDataBlock, TRUE
                                            jmp     TB_NextBlock
    
                                    .elseif bl == 3     ; CODE block
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "CODE:    "
                                            push    esi
                                            add     esi, 2
                                            invoke  AddSpeccyFilename, pTEXTSTRING, esi
                                            pop     esi
                                            xor     eax, eax
                                            mov     ax, [esi+14] ; Code start
                                            xor     ebx, ebx
                                            mov     bx, [esi+12] ; Code length
                                            push    ebx
                                            ADDCHAR         pTEXTSTRING, " "
                                            ADDTEXTDECIMAL  pTEXTSTRING, eax
                                            ADDCHAR         pTEXTSTRING, ","
                                            pop     ebx
                                            ADDTEXTDECIMAL  pTEXTSTRING, ebx
                                            mov     HeaderDataBlock, TRUE
                                            jmp     TB_NextBlock
                                    .endif  ; PROGRAM header

                            .endif  ; 0=header

                    .endif  ;.if eax == 19               ; header=17 bytes+flag+checksum

                    push    eax    ; eax still = length
                    .if     HeaderDataBlock == TRUE
                            ADDDIRECTTEXTSTRING pTEXTSTRING, " --Data:              "
                            mov HeaderDataBlock, FALSE
                    .else
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Headerless:           "
                    .endif
                    pop     eax
                    sub     eax, 2   ; drop flag+checksum byte count
                    .if     CARRY?
                            xor     eax, eax
                    .endif
                    ADDTEXTDECIMAL  pTEXTSTRING, eax

            .elseif al == 11h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Turbo Data:           "
                    inc     esi
                    mov     eax, [esi+0Fh]
                    and     eax, 00FFFFFFh  ; length of turbo data block
                    sub     eax, 2          ; drop flag+checksum byte count
                    .if     CARRY?
                            xor     eax, eax
                    .endif
                    ADDTEXTDECIMAL pTEXTSTRING, eax

            .elseif al == 12h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Pure Tone {"
                    xor     eax, eax
                    xor     ebx, ebx
                    inc     esi
                    mov     ax, [esi]       ; length of pulses
                    mov     bx, [esi+2]     ; no. of pulses
                    push    eax
                    ADDTEXTDECIMAL  pTEXTSTRING, ebx
                    ADDDIRECTTEXTSTRING pTEXTSTRING, " pulses of "
                    pop     eax
                    ADDTEXTDECIMAL  pTEXTSTRING, eax
                    ADDCHAR         pTEXTSTRING, " ", "T", "}"

            .elseif al == 13h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Pulse Sequence {"
                    inc     esi
                    xor     eax, eax
                    mov     al, [esi]
                    ADDTEXTDECIMAL  pTEXTSTRING, eax
                    ADDDIRECTTEXTSTRING pTEXTSTRING, " pulses}"

            .elseif al == 14h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Pure Data:            "
                    inc     esi
                    mov     eax, [esi+7]
                    and     eax, 00FFFFFFh
                    ADDTEXTDECIMAL  pTEXTSTRING, eax

            .elseif al == 15h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Direct Recording:     "
                    inc     esi
                    mov     eax, [esi+5]
                    and     eax, 00FFFFFFh
                    ADDTEXTDECIMAL  pTEXTSTRING, eax

            .elseif al == 16h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "C64 Rom Type Data Block"

            .elseif al == 17h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "C64 Turbo Tape Data Block"

            .elseif al == 18h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "CSW Recording Block"

            .elseif al == 19h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Generalised Data Block"

            .elseif al == 20h
                    inc     esi
                    xor     eax, eax
                    mov     ax, [esi]
                    .if     eax == 0
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "STOP TAPE"
                    .else
                            push    eax
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Pause {"
                            pop     eax
                            ADDTEXTDECIMAL      pTEXTSTRING, eax
                            ADDDIRECTTEXTSTRING pTEXTSTRING, " ms}"
                    .endif

            .elseif al == 21h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Group {"
                    inc     esi
                    xor     ecx, ecx
                    mov     cl, [esi]       ; ecx=length
                    inc     esi             ; esi=string
                    ADDTEXTSTRINGLENGTH pTEXTSTRING, esi, ecx
                    ADDCHAR pTEXTSTRING, "}"

            .elseif al == 22h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Group End"

            .elseif al == 23h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Jump {to block "
                    inc     esi
                    xor     eax, eax
                    mov     ax, [esi]
                    add     eax, [TB_BlockCnt]
                    ADDTEXTDECIMAL  pTEXTSTRING, eax
                    ADDCHAR pTEXTSTRING, "}"

            .elseif al == 24h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Loop {"
                    xor     eax, eax
                    inc     esi
                    mov     ax, [esi]
                    ADDTEXTDECIMAL  pTEXTSTRING, eax
                    ADDDIRECTTEXTSTRING pTEXTSTRING, " iterations}"

            .elseif al == 25h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Loop End"

            .elseif al == 26h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Call Sequence"

            .elseif al == 27h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Return from Sequence"

            .elseif al == 28h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Select Block"

            .elseif al == 2Ah
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "STOP TAPE (48K mode only)"

            .elseif al == 2Bh
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Set Signal Level"

            .elseif al == 30h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Text {"
                    inc     esi
                    xor     ecx, ecx
                    mov     cl, [esi]   ; ecx=length
                    inc     esi         ; esi=string
                    ADDTEXTSTRINGLENGTH pTEXTSTRING, esi, ecx
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "}"

            .elseif al == 31h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Message Block"

            .elseif al == 32h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Archive Info"
                    invoke  PopulateArchiveInfo, hWndDlg, esi

            .elseif al == 33h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Hardware Type"

            .elseif al == 34h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Emulation Info"

            .elseif al == 35h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Custom Info Block"

            .elseif al == 40h
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Snapshot Block"

            .elseif al == 5Ah
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "ZX Tape Merge Header"

            .elseif al == SPECIAL_PAUSE_BLOCK
                    jmp     TB_Next_NoAddString ; don't show these in tape browser

            .elseif al == BLOCK_WAV
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Wave Recording: "
                    invoke  NameFromPath, addr WAVfilename, ADDR temppathstring
                    ADDCHAR         pTEXTSTRING, 34
                    ADDTEXTSTRING   pTEXTSTRING, offset temppathstring
                    ADDCHAR         pTEXTSTRING, 34

            .elseif al == BLOCK_CSW
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "CSW Recording: "
                    invoke  NameFromPath, addr CSWfilename, addr temppathstring
                    ADDCHAR         pTEXTSTRING, 34
                    ADDTEXTSTRING   pTEXTSTRING, offset temppathstring
                    ADDCHAR         pTEXTSTRING, 34
            .else
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Unknown Block Type"
            .endif

TB_NextBlock:
            invoke  SendDlgItemMessage, hWndDlg, IDC_TAPEBOXLST, LB_ADDSTRING, 0, ADDR textstring

TB_Next_NoAddString:
            pop     esi
            inc     TB_BlockCnt
            jmp     TB_Loop

; come here when all tape blocks are in the Combo Box

TB_InitDone:
            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
            .if     LoadTapeType == Type_NONE
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "       No Tape Inserted"
            .else
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "       End of Tape"
            .endif
            invoke  SendDlgItemMessage, hWndDlg, IDC_TAPEBOXLST, LB_ADDSTRING, 0, ADDR textstring

            xor     edx,edx
            mov     dx, TZXCurrBlock
            mov     NEWTZXCurrBlock, dx  ; init NEWTZXCurrBlock for OK button
            invoke  SendDlgItemMessage, hWndDlg, IDC_TAPEBOXLST, LB_SETCURSEL, edx, 0

            ret
PopulateTapeBox     endp

