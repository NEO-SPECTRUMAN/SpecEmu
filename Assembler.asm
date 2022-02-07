
                        include Scintilla.inc

Asm_StateCallback       PROTO   C   :DWORD,:DWORD,:DWORD,:WORD,:DWORD,:DWORD
Asm_ListCallback        PROTO   C   :DWORD,:WORD,:LPCSTR,:DWORD,:DWORD,:DWORD,:BOOL

ASM_ITEM_DATA           struct
hWnd                    DWORD           ?               ; window handle tab's edit control
filename                db      MAX_PATH    dup (?)
ASM_ITEM_DATA           ends

TEDITBOX_SIZE           struct
x                       DWORD   ?
y                       DWORD   ?
nwidth                  DWORD   ?
nheight                 DWORD   ?
TEDITBOX_SIZE           ends


AssemblerDialogProc     PROTO   :DWORD,:DWORD,:DWORD,:DWORD

ToggleAssemblerDialog   PROTO
ShowAssemblerDialog     PROTO
HideAssemblerDialog     PROTO

NewPage                 PROTO   :DWORD
CloseTab                PROTO   :DWORD
Switch_To_Tab           PROTO   :DWORD
GetCurrentTab           PROTO
GetTabDataNode          PROTO   :DWORD
GetTabFilename          PROTO   :DWORD,:DWORD

Asm_SaveAllTabFiles     PROTO
SaveTabFile             PROTO   :DWORD
SaveTabFileAs           PROTO   :DWORD

Get_EditBox_Size        PROTO
AsmMessageBox           PROTO   :DWORD,:DWORD,:DWORD



.data?
align 4
Asm_hWnd                dd      ?
Asm_Tab_hWnd            dd      ?   ; handle of tab control

current_sci_hWnd        dd      ?   ; handle of currently active Scintilla edit control

next_avail_tab_index    dd      ?
next_child_ID           dd      ?

EditBox_Size            TEDITBOX_SIZE   <?>

asm_ofn                 OPENFILENAME    <?>

asmtemppathstring       BYTE    MAX_PATH    dup (?)

.data
Assembler_Enabled       db      FALSE

szASMFilter             db      "Asm files (*.asm)", 0, "*.asm", 0, 0
                        db      0

asm_new_def_filename    db      "Untitled*", 0

AssemblerWinName        db      "AssemblerWindow", 0

.code

TABSTRIP_HEIGHT         =   25

SendEdit                macro   uMsg, wParam, lParam
                        invoke  SendMessage, current_sci_hWnd, uMsg, wParam, lParam
                        endm

ToggleAssemblerDialog   proc
                        .if     Assembler_Enabled == TRUE
                                invoke  HideAssemblerDialog
                        .else
                                invoke  ShowAssemblerDialog
                        .endif
                        ret
ToggleAssemblerDialog   endp

ShowAssemblerDialog     proc
                        .if     FullScreenMode == FALSE
                                mov     Assembler_Enabled, TRUE
                                invoke  ShowWindow, AssemblerDlg, SW_SHOW
                        .endif
                        ret
ShowAssemblerDialog     endp

HideAssemblerDialog     proc
                        mov     Assembler_Enabled, FALSE
                        invoke  ShowWindow, AssemblerDlg, SW_HIDE
                        ret
HideAssemblerDialog     endp


AssemblerDialogProc proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   ofn:        OPENFILENAME

                    local   rect:       RECT

                    local   WinRect:    RECT
                    local   wwidth, wheight:    DWORD

                    local   itemtab:    TC_ITEM

                    local   srcmem:     DWORD,
                            srclen:     DWORD

                    local   wParamLow:  WORD,
                            wParamHigh: WORD

                    mov     eax, wParam
                    mov     wParamLow, ax
                    shr     eax, 16
                    mov     wParamHigh, ax

                    RESETMSG

OnInitDialog
                    m2m     Asm_hWnd, hWndDlg
                    mov     Asm_Tab_hWnd, $fnc (GetDlgItem, hWndDlg, IDC_ASM_TABS)

                    mov     next_child_ID, 4200

                    mov     next_avail_tab_index, 0
                    mov     current_sci_hWnd, 0

                    invoke  Get_EditBox_Size
                    invoke  MoveWindow, Asm_Tab_hWnd, 0, 0, EditBox_Size.nwidth, TABSTRIP_HEIGHT, TRUE

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr AssemblerWinName, SADD ("_X")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     esi, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr AssemblerWinName, SADD ("_Y")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     edi, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr AssemblerWinName, SADD ("_W")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     wwidth, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, addr AssemblerWinName, SADD ("_H")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     wheight, eax

                    mov     edx, SWP_NOOWNERZORDER or SWP_NOZORDER
                    .if     (wwidth == -1) || (wheight == -1)
                            or      edx, SWP_NOSIZE     ; SetWindowPos ignores cx, cy params (new width, hew height)
                    .endif

                    .if     (esi != -1) && (edi != -1)
                            invoke  SetWindowPos, hWndDlg, NULL, esi, edi, wwidth, wheight, edx
                    .endif

                    return  TRUE

OnCommand

                    ; menu commands
                    .if     wParamHigh == 0

                            switch  wParamLow
                                    case    IDM_ASM_NEW
                                            invoke  NewPage, addr asm_new_def_filename

                                    case    IDM_ASM_OPEN
                                            mov     ofn.lpstrDefExt, offset ASMExt
                                            .if     $fnc (GetFileName, hWndDlg, SADD ("Open assembler source file"), addr szASMFilter, addr ofn, addr szAsmFileName, addr ASMExt) != 0

                                                    ; is this file already open?
                                                    xor     esi, esi
                                                    .while  TRUE
                                                            .if     $fnc (GetTabDataNode, esi) != 0
                                                                    mov     edi, eax
                                                                    .if     $fnc (Cmpi, addr [edi].ASM_ITEM_DATA.filename, addr szAsmFileName) == 0
                                                                            ; filename matches with item tab in esi
                                                                            invoke  Switch_To_Tab, esi  ; switch to the tab with matching filename
                                                                            return  TRUE
                                                                    .endif
                                                            .else
                                                                    .break  ; reached end of tab item list; no filename match so continue to open new tab
                                                            .endif
                                                            inc     esi     ; next tab item
                                                    .endw

                                                    .if     $fnc (ReadFileToMemory, addr szAsmFileName, addr srcmem, addr srclen) != NULL
                                                            .if     $fnc (NewPage, addr szAsmFileName) == TRUE ; create a new source tab and edit control
                                                                    SendEdit    SCI_ADDTEXT, srclen, srcmem ; insert file source into edit control
                                                                    SendEdit    SCI_EMPTYUNDOBUFFER, 0, 0   ; clear UNDO after inserting the source text
                                                            .endif
                                                            FreeMem (srcmem)    ; free the memory copy of the source file
                                                    .endif
                                            .endif

                                    case    IDM_ASM_SAVE
                                            mov     esi, $fnc (GetCurrentTab)
                                            ifc     esi ne -1 then invoke SaveTabFile, esi

                                    case    IDM_ASM_SAVE_AS
                                            mov     esi, $fnc (GetCurrentTab)
                                            ifc     esi ne -1 then invoke SaveTabFileAs, esi

                                    case    IDM_ASM_CLOSE
                                            mov     esi, $fnc (GetCurrentTab)
                                            ifc     esi ne -1 then invoke CloseTab, esi

                                    case    IDM_ASM_ASSEMBLE
                                            mov     esi, $fnc (GetCurrentTab)
                                            .if     esi == -1
                                                    invoke  AsmMessageBox, SADD ("No source file selected"), 0, MB_OK
                                                    return  TRUE    ; exit
                                            .endif

                                            ; save all source files and then return to current source file tab
                                            push    esi
                                            invoke  Asm_SaveAllTabFiles
                                            pop     esi
                                            invoke  Switch_To_Tab, esi

                                            .if     $fnc (GetTabDataNode, esi) == 0
                                                    invoke  AsmMessageBox, SADD ("Uh oh..."), 0, MB_OK
                                                    return  TRUE    ; exit
                                            .endif

                                            mov     edi, eax
                                            lea     edi, [edi].ASM_ITEM_DATA.filename
                                            invoke  Assemble_Source, edi, hWndDlg

                                            invoke  Show_Message_Dialog
                            endsw
                    .endif

                    return  TRUE

OnNotify
                    assume  ebx: ptr NMHDR
                    mov     ebx, lParam

                    mov     eax, [ebx].NMHDR.hwndFrom

                    .if     eax == Asm_Tab_hWnd
                            ; notification came from the assembler's tab control
                            switch  [ebx].NMHDR.code
                                    case    TCN_SELCHANGING
                                            ; hide the edit control switching out of view
                                            mov     esi, $fnc (GetCurrentTab)
                                            .if     esi != -1
                                                    .if     $fnc (GetTabDataNode, esi) != 0
                                                            mov     edi, eax
                                                            invoke  ShowWindow, [edi].ASM_ITEM_DATA.hWnd, SW_HIDE
                                                    .endif
                                            .endif

                                    case    TCN_SELCHANGE
                                            ; resize and show the edit control switching into view
                                            mov     esi, $fnc (GetCurrentTab)
                                            .if     esi != -1
                                                    invoke  Switch_To_Tab, esi
                                            .endif
                            endsw
                    .endif

                    assume  ebx: NOTHING

OnSizing
                    LimitWindowWidth    400
                    LimitWindowHeight   300

                    invoke  Get_EditBox_Size
                    invoke  MoveWindow, current_sci_hWnd, EditBox_Size.x, EditBox_Size.y, EditBox_Size.nwidth, EditBox_Size.nheight, TRUE
                    return  TRUE

OnSize
                    invoke  Get_EditBox_Size
                    invoke  MoveWindow, current_sci_hWnd, EditBox_Size.x, EditBox_Size.y, EditBox_Size.nwidth, EditBox_Size.nheight, TRUE
                    invoke  MoveWindow, Asm_Tab_hWnd, 0, 0, EditBox_Size.nwidth, TABSTRIP_HEIGHT, TRUE
                    return  TRUE

OnShowWindow
                    return  TRUE

OnClose
                    invoke  HideAssemblerDialog
                    return  0

OnActivate
;                    .if     $LowWord (wParam) != WA_INACTIVE
;                            CLEARSOUNDBUFFERS
;                    .endif
                    return  0

OnEnterMenuLoop
                    CLEARSOUNDBUFFERS

OnEnterSizeMove
                    CLEARSOUNDBUFFERS

OnDestroy
                    invoke  GetWindowRect, hWndDlg, addr WinRect

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr AssemblerWinName, SADD ("_X")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.left

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr AssemblerWinName, SADD ("_Y")
                    invoke  WriteProfileInt, addr DummyMem, WinRect.top

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr AssemblerWinName, SADD ("_W")
                    invoke  WriteProfileInt, addr DummyMem, @EVAL (WinRect.right - WinRect.left)

                    mov     DummyMem, 0
                    strcat  addr DummyMem,   addr AssemblerWinName, SADD ("_H")
                    invoke  WriteProfileInt, addr DummyMem, @EVAL (WinRect.bottom - WinRect.top)

                    return  NULL

OnDefault
                    return  FALSE

                    DOMSG

                    ret

AssemblerDialogProc endp

GetCurrentTab       proc
                    return  $fnc (SendMessage, Asm_Tab_hWnd, TCM_GETCURSEL, 0, 0)   ; -1 on error, else current tab number
GetCurrentTab       endp

Asm_SaveAllTabFiles proc    uses esi

                    xor     esi, esi
                    .while  TRUE
                            .if     $fnc (GetTabDataNode, esi) != 0
                                    invoke  Switch_To_Tab, esi
                                    invoke  SaveTabFile, esi
                            .else
                                    .break  ; reached end of tab item list; no filename match so continue to open new tab
                            .endif
                            inc     esi     ; next tab item
                    .endw
                    ret

Asm_SaveAllTabFiles endp

;' ========================================================================================
;' SCI_GETTEXT(int length, char *text)
;' This returns length-1 characters of text from the start of the document plus one
;' terminating 0 character. To collect all the text in a document, use SCI_GETLENGTH to
;' get the number of characters in the document (nLen), allocate a character buffer of
;' length nLen+1 bytes, then call SCI_GETTEXT(nLen+1, char *text). If the text argument
;' is 0 then the length that should be allocated to store the entire document is returned.
;' If you then save the text, you should use SCI_SETSAVEPOINT to mark the text as unmodified.
;' ========================================================================================
;' ========================================================================================
;FUNCTION SCI_GetText (BYVAL hSci AS DWORD) AS STRING
;   LOCAL nLen AS LONG
;   LOCAL buffer AS STRING
;   nLen = SendMessage(hSci, %SCI_GETLENGTH, 0, 0)
;   IF nLen < 1 THEN EXIT FUNCTION
;   buffer = SPACE$(nLen + 1)
;   SendMessageA(hSci, %SCI_GETTEXT, nLen + 1, STRPTR(buffer))
;   FUNCTION = REMOVE$(buffer, CHR$(0))
;END FUNCTION
;' ========================================================================================

SaveTabFile         proc    uses        esi edi,
                            tab_item:   DWORD

                    local   ofn:        OPENFILENAME
                    local   itemtab:    TC_ITEM

                    local   srcmem:     DWORD,
                            srclen:     DWORD

                    local   alloclen:   DWORD

                    local   filename [MAX_PATH]:    BYTE

                    mov     edi, $fnc (GetTabDataNode, tab_item)
                    ifc     edi  eq 0 then ret

                    strcpy  addr [edi].ASM_ITEM_DATA.filename, addr filename    ; copy full filepath/name into our local filename buffer

                    .if     $fnc (Cmpi, addr [edi].ASM_ITEM_DATA.filename, addr asm_new_def_filename) == 0
                            ; filename matches our default new page filename
                            ; so we do a Save As function
                            invoke  SaveTabFileAs, tab_item
                            ret
                    .endif

                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_GETLENGTH, 0, 0  ; return the length of the document in bytes
                    mov     srclen, eax

                    inc     eax
                    mov     alloclen, eax

                    mov     srcmem, AllocMem (alloclen)
                    .if     srcmem != NULL
                            invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_GETTEXT, alloclen, srcmem

                            .if     $fnc (WriteMemoryToFile, addr filename, srcmem, srclen) != 0
                                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_EMPTYUNDOBUFFER, 0, 0   ; clear UNDO after writing source file
                                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_SETSAVEPOINT, 0, 0      ; mark the text as unmodified
                            .endif
                            FreeMem (srcmem)
                    .endif

                    ret
SaveTabFile         endp

SaveTabFileAs       proc    uses        esi edi,
                            tab_item:   DWORD

                    local   ofn:        OPENFILENAME
                    local   itemtab:    TC_ITEM

                    local   srcmem:     DWORD,
                            srclen:     DWORD

                    local   alloclen:   DWORD

                    local   fnameonly [MAX_PATH]:   BYTE,
                            savefname [MAX_PATH]:   BYTE

                    mov     edi, $fnc (GetTabDataNode, tab_item)
                    ifc     edi  eq 0 then ret

                    ifc     Assembler_Enabled eq FALSE then invoke ShowAssemblerDialog

                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_GETLENGTH, 0, 0  ; return the length of the document in bytes
                    mov     srclen, eax

                    inc     eax
                    mov     alloclen, eax

                    mov     srcmem, AllocMem (alloclen)
                    .if     srcmem != NULL
                            invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_GETTEXT, alloclen, srcmem

                            mov     savefname[0], 0 ; empty filename in dialog
                            .if     $fnc (SaveFileName, Asm_hWnd, SADD ("Save file as"), addr szASMFilter, addr ofn, addr savefname, addr ASMExt, 0) != 0
                                    .if     $fnc (AskOverwriteFile, addr savefname, Asm_hWnd, addr szWindowName) == TRUE
                                            .if     $fnc (WriteMemoryToFile, addr savefname, srcmem, srclen) != 0
                                                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_EMPTYUNDOBUFFER, 0, 0   ; clear UNDO after writing source file
                                                    invoke  SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_SETSAVEPOINT, 0, 0      ; mark the text as unmodified

                                                    strcpy  addr savefname, addr [edi].ASM_ITEM_DATA.filename   ; copy full filepath/name into our item data node
                                                    invoke  ExtractFileName, addr savefname, addr fnameonly     ; only display filename

                                                    memclr  addr itemtab, sizeof itemtab
                                                    lea     esi, itemtab
                                                    mov     [esi].TC_ITEM.imask,      TCIF_TEXT
                                                    lea     eax, fnameonly
                                                    mov     [esi].TC_ITEM.pszText,    eax
                                                    mov     [esi].TC_ITEM.cchTextMax, len (addr fnameonly)

                                                    invoke  SendMessage, Asm_Tab_hWnd, TCM_SETITEM, tab_item, addr itemtab
                                            .endif
                                    .endif
                            .endif
                            FreeMem (srcmem)
                    .endif

                    ret
SaveTabFileAs       endp

NewPage             proc    uses        esi edi ebx,
                            lpFilename: DWORD

                    local   editctrl:   DWORD

                    local   rect:       RECT,
                            newtab:     TC_ITEM

                    local   fnameonly [MAX_PATH]:   BYTE

                    mov     edi, AllocMem (sizeof ASM_ITEM_DATA)
                    ifc     edi  eq 0 then return FALSE

                    invoke  Get_EditBox_Size
                    invoke  CreateWindowEx, WS_EX_CLIENTEDGE, SADD ("Scintilla"), addr szWindowName, WS_CHILD or WS_VISIBLE,
                                            EditBox_Size.x, EditBox_Size.y, EditBox_Size.nwidth, EditBox_Size.nheight,
                                            Asm_hWnd, next_child_ID, hInstance, NULL
                    ifc     eax eq NULL then FreeMem (edi) : return FALSE

                    mov     editctrl, eax

                    lea     esi, newtab
                    memclr  esi, sizeof TC_ITEM

                    strcpy  lpFilename, addr [edi].ASM_ITEM_DATA.filename                   ; copy full filepath/name into our item data node
                    invoke  ExtractFileName, lpFilename, addr fnameonly                     ; only display filename

                    mov     [esi].TC_ITEM.imask,      TCIF_TEXT or TCIF_PARAM
                    lea     eax, fnameonly
                    mov     [esi].TC_ITEM.pszText,    eax
                    mov     [esi].TC_ITEM.cchTextMax, len (addr fnameonly)
                    mov     [esi].TC_ITEM.lParam,     edi                                   ; store our item data node pointer into new tab's lParam

                    m2m     [edi].ASM_ITEM_DATA.hWnd, editctrl                              ; window handle for the new tab's edit control

                    .if     $fnc (SendMessage, Asm_Tab_hWnd, TCM_INSERTITEM, next_avail_tab_index, esi) == -1
                            invoke  DestroyWindow, editctrl
                            FreeMem edi
                            return  FALSE
                    .endif

                    invoke  Switch_To_Tab, next_avail_tab_index                             ; our new tab becomes the current tab

                    inc     next_avail_tab_index
                    inc     next_child_ID

                    SendEdit    SCI_SETMARGINTYPEN, 0, SC_MARGIN_NUMBER
                    SendEdit    SCI_SETMARGINWIDTHN, 0, 32

                    SendEdit    SCI_STYLESETFONT, STYLE_DEFAULT, SADD ("Courier New")
                    SendEdit    SCI_STYLESETSIZE, STYLE_DEFAULT, 9
                    SendEdit    SCI_STYLECLEARALL, 0, 0

                    return  TRUE

NewPage             endp

CloseTab            proc    uses        edi,
                            tab_item:   DWORD

                    local   textstring: TEXTSTRING
                    local   ptextstring:DWORD

                    local   filename [MAX_PATH + 100]: BYTE

                    mov     edi, $fnc (GetTabDataNode, tab_item)
                    .if     edi != 0

                            .if     $fnc (SendMessage, [edi].ASM_ITEM_DATA.hWnd, SCI_GETMODIFY, 0, 0) != 0
                                    ; text is modified
                                    invoke  Switch_To_Tab, tab_item
                                    invoke  GetTabFilename, tab_item, addr filename

                                    invoke  INITTEXTSTRING, addr textstring, addr ptextstring
                                            ADDDIRECTTEXTSTRING ptextstring, "The text in "
                                            ADDCHAR             ptextstring, 34
                                            ADDTEXTSTRING       ptextstring, addr filename
                                            ADDCHAR             ptextstring, 34
                                            ADDDIRECTTEXTSTRING ptextstring, " has been changed."
                                            ADDCHAR             ptextstring, 10, 10
                                            ADDDIRECTTEXTSTRING ptextstring, "Do you want to save the changes?"

                                    .if     $fnc (AsmMessageBox, addr textstring, 0, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON1) == IDYES
                                            invoke  SaveTabFile, tab_item
                                    .endif
                            .endif

                            invoke  Switch_To_Tab, 0
                            invoke  CloseWindow, [edi].ASM_ITEM_DATA.hWnd   ; close tab's edit control
                            FreeMem edi

                            invoke  SendMessage, Asm_Tab_hWnd, TCM_DELETEITEM, tab_item, 0  ; delete this tab
                            dec     next_avail_tab_index
                    .endif
                    ret

CloseTab            endp

Switch_To_Tab       proc    uses        edi,
                            tab_item:   DWORD

                    .if     $fnc (GetTabDataNode, tab_item) != 0
                            mov     edi, eax
                            ifc     current_sci_hWnd ne 0 then invoke ShowWindow, current_sci_hWnd, SW_HIDE             ; hide current tab edit control

                            m2m     current_sci_hWnd, [edi].ASM_ITEM_DATA.hWnd                                          ; update current tab edit control
                            invoke  Get_EditBox_Size
                            invoke  MoveWindow, current_sci_hWnd, EditBox_Size.x, EditBox_Size.y, EditBox_Size.nwidth, EditBox_Size.nheight, TRUE
                            invoke  ShowWindow, current_sci_hWnd, SW_SHOW
                            invoke  SetFocus,   current_sci_hWnd

                            invoke  SendMessage, Asm_Tab_hWnd, TCM_SETCURSEL, tab_item, 0                               ; switch to new tab
                    .endif
                    ret

Switch_To_Tab       endp

GetTabDataNode      proc    tab_item:   DWORD

                    local   itemtab:    TC_ITEM

                    memclr  addr itemtab, sizeof itemtab
                    mov     itemtab.imask, TCIF_PARAM
                    .if     $fnc (SendMessage, Asm_Tab_hWnd, TCM_GETITEM, tab_item, addr itemtab) == TRUE
                            return  itemtab.lParam
                    .endif
                    return  0

GetTabDataNode      endp

GetTabFilename      proc    tab_item:   DWORD,
                            lpFilename: DWORD

                    .if     $fnc (GetTabDataNode, tab_item) != 0
                            strcpy  addr [eax].ASM_ITEM_DATA.filename, lpFilename
                    .else
                            mov     eax, lpFilename
                            mov     byte ptr [eax], 0   ; return NULL string
                    .endif
                    ret

GetTabFilename      endp

Get_EditBox_Size    proc

                    local   rect:   RECT

                    invoke  GetClientRect, Asm_hWnd, addr rect
                    m2m     EditBox_Size.x,       rect.left
                    m2m     EditBox_Size.y,       @EVAL (rect.top + TABSTRIP_HEIGHT)
                    mov     EditBox_Size.nwidth,  @EVAL (rect.right  - rect.left)
                    mov     EditBox_Size.nheight, @EVAL (rect.bottom - rect.top - TABSTRIP_HEIGHT)
                    ret

Get_EditBox_Size    endp

;                    invoke  AsmMessageBox, hWndDlg, SADD ("Text"), SADD ("Caption"), MB_OK

AsmMessageBox       proc    lpText:     DWORD,
                            lpCaption:  DWORD,
                            uType:      DWORD

                    mov     eax, lpCaption
                    ifc     eax eq 0 then lea eax, CTXT ("Assembler")

                    invoke  MessageBox, Asm_hWnd, lpText, eax, uType
                    ret
AsmMessageBox       endp


Assemble_Source     proc    sourcefile:     LPCSTR,
                            hWndParent:     DWORD

                    local   hPasmoStdOut:   DWORD
                    local   hStdOutFileMem,
                            hStdOutFileLen: DWORD
                    local   textlineptr:    DWORD

                    local   sa: SECURITY_ATTRIBUTES

                    local   asmsourcefile       [MAX_PATH]: BYTE    ; path/filename
                    local   asmsourcefilePath   [MAX_PATH]: BYTE    ; file path only
                    local   asmsourcefileName   [MAX_PATH]: BYTE    ; file name only
                    local   asmsourcefileTap    [MAX_PATH]: BYTE    ; asm TAP file name
                    local   asmsourcefileSymbol [MAX_PATH]: BYTE    ; asm Symbol file name
                    local   asmsourcefileErr    [MAX_PATH]: BYTE    ; asm Error file name

                    local   asmlaunchTapfile    [MAX_PATH]: BYTE    ; asm TAP file path/name launch

                    local   tempfilepath [1024]: BYTE
                    local   tempcurdir [MAX_PATH]: BYTE

                    strncpy sourcefile, addr asmsourcefile, sizeof asmsourcefile

                    invoke  Clear_Messages

                    invoke  GetCurrentDirectory, sizeof tempcurdir, addr tempcurdir ; preserve current currdir

                    invoke  ExtractFilePath, addr asmsourcefile, addr asmsourcefilePath
                    invoke  ExtractFileName, addr asmsourcefile, addr asmsourcefileName

                    strncpy addr asmsourcefileName, addr asmsourcefileTap,    sizeof asmsourcefileTap
                    strncpy addr asmsourcefileName, addr asmsourcefileSymbol, sizeof asmsourcefileSymbol
                    strncpy addr asmsourcefileName, addr asmsourcefileErr,    sizeof asmsourcefileErr

                    invoke  @@AddExtension, addr asmsourcefileTap,    CTXT ("tap")
                    invoke  @@AddExtension, addr asmsourcefileSymbol, CTXT ("symbol")
                    invoke  @@AddExtension, addr asmsourcefileErr,    CTXT ("err")

                    .if     $fnc (SetCurrentDirectory, addr asmsourcefilePath) == 0
                            invoke  ShowMessageBox, hWndParent, SADD ("SetCurrentDirectory failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                            return  FALSE
                    .endif

                    mov     byte ptr tempfilepath, 0
                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, offset appPath, SADD ("pasmo.exe", 34, " --alocal --err --name code --tapbas ")

                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileName,   addr char_quote_space  ; "<srcfile>.asm" + " "
                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileTap,    addr char_quote_space  ; "<srcfile>.tap" + " "
                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileSymbol, addr char_quote        ; "<srcfile>.symbol"

                    ifdef   DEBUGBUILD
                            ; show Pasmo command line
                            ;invoke  ShowMessageBox, hWndParent, addr tempfilepath, addr szWindowName, MB_OK or MB_ICONINFORMATION
                    endif

                    mov     DummyMem, 0
                    invoke  szMultiCat, 2, addr DummyMem, CTXT ("Assembling: "), addr asmsourcefileName
                    ADDMESSAGEPTR   addr DummyMem


                    memclr  addr sa, sizeof sa
                    mov     sa.nLength, sizeof sa
                    mov     sa.bInheritHandle, TRUE

                    mov     hPasmoStdOut, $fnc (CreateFile, addr asmsourcefileErr, FILE_ALL_ACCESS, FILE_SHARE_READ, addr sa, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
                    .if     hPasmoStdOut != INVALID_HANDLE_VALUE

                            memclr  addr ProcessInfo, sizeof ProcessInfo
                            memclr  addr StartupInfo, sizeof StartupInfo

                            mov     StartupInfo.cb, sizeof STARTUPINFO
                            mov     StartupInfo.dwFlags, STARTF_USESTDHANDLES
                            mov     StartupInfo.hStdInput, $fnc (GetStdHandle, STD_INPUT_HANDLE)
                            m2m     StartupInfo.hStdOutput, hPasmoStdOut
                            mov     StartupInfo.hStdError, $fnc (GetStdHandle, STD_ERROR_HANDLE)

                            .if     $fnc (CreateProcess, NULL, addr tempfilepath, NULL, NULL, TRUE, NORMAL_PRIORITY_CLASS or CREATE_NO_WINDOW, NULL, NULL, addr StartupInfo, addr ProcessInfo) != 0
                                    ; wait for Pasmo to finish
                                    invoke  WaitForSingleObject, ProcessInfo.hProcess, INFINITE

                                    ; close handles to the child process and its primary thread
                                    invoke  CloseHandle, ProcessInfo.hProcess
                                    invoke  CloseHandle, ProcessInfo.hThread
                            .else
                                    invoke  ShowMessageBox, hWndParent, SADD ("CreateProcess failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                            .endif

                            invoke  CloseHandle, hPasmoStdOut

                            .if     $fnc (ReadFileToMemory, addr asmsourcefileErr, addr hStdOutFileMem, addr hStdOutFileLen) != 0
                                    .if     hStdOutFileLen > 0
                                            ; errors in assembly
                                            m2m     textlineptr, hStdOutFileMem
                                            .while  TRUE
                                                    .if     $fnc (ReadTextLine, addr textlineptr, addr DummyMem) != 0
                                                            ADDMESSAGEPTR   addr DummyMem
                                                    .else
                                                            .break
                                                    .endif
                                            .endw
                                    .else
                                            ; assembled without errors
                                            ADDMESSAGE  "Assembly Complete"

                                            mov     DummyMem, 0
                                            invoke  szMultiCat, 2, addr DummyMem, CTXT ("Loading: "), addr asmsourcefileTap
                                            ADDMESSAGEPTR   addr DummyMem

                                            mov     asmlaunchTapfile, 0
                                            invoke  szMultiCat, 2, addr asmlaunchTapfile, addr asmsourcefilePath, addr asmsourcefileTap
                                            ADDMESSAGEPTR   addr asmlaunchTapfile

                                            invoke  InsertTape_1, addr asmlaunchTapfile
                                    .endif
                                    invoke  GlobalFree, hStdOutFileMem
                                    invoke  DeleteFile, addr asmsourcefileErr
                            .endif
                    .else
                            invoke  ShowMessageBox, hWndParent, SADD ("CreateFile failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                    .endif

                    invoke  SetCurrentDirectory, addr tempcurdir    ; restore current currdir on exit
                    return  TRUE

Assemble_Source     endp

