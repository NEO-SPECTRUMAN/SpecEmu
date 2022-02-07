
AddDebuggerToolBar      PROTO   :DWORD,:HWND
SetDebugReadWriteButtonStates   PROTO   :DWORD
EnableDumpControls      PROTO   :DWORD
EnableDebugWindows      PROTO   :DWORD
DestroyDebugWindows     PROTO
DecodeSearchBytes       PROTO   :DWORD
DISLST_SubclassProc     PROTO   :DWORD,:DWORD,:DWORD,:DWORD
DebuggerDlgProc         PROTO   :DWORD,:DWORD,:DWORD,:DWORD
Single_Step             PROTO
Remote_Single_Step      PROTO
InitCursorStack         PROTO
PushCursorStack         PROTO
PopCursorStack          PROTO
SetProfileCycles        PROTO

GetDialogPlacement      PROTO
SaveDialogPlacement     PROTO

SetDebugMenuCheck       PROTO   :DWORD,:BYTE
SetDisassemblyFontSize  PROTO   :BYTE

Run_DebugFrame          PROTO
ToggleBreakpoint        PROTO   :WORD
AddBreakpoint           PROTO   :WORD
RemoveBreakpoint        PROTO   :WORD
ClearBreakpoints        PROTO
SortBreakpoints         PROTO

UpdateDebugger          PROTO
UpdateDebugDisplay      PROTO

GetSelectedLine         PROTO
SetSelectedLine         PROTO   :DWORD
Cursor_Up               PROTO
Cursor_Down             PROTO
FollowReference         PROTO
RetraceReference        PROTO
SetNewZ80PC             PROTO   :WORD

ParseRegText            PROTO   :DWORD

SaveLoadFwdRefs         PROTO   :BYTE
CreateDISTooltip        PROTO   :HWND
DestroyDISTooltip       PROTO
BuildDissTooltipText    PROTO

.data?
align 4
DISASSEMBLYhWnd     DWORD ?
DISLST_Handle       DWORD ?
OrigDISLSTWndProc   DWORD ?
DISASSEMBLYOldFont  DWORD   ?
StackPtr            DWORD ?
StackTopLim         DWORD ?
StackRoot           DWORD 256 DUP(?)
StackBotLim         DWORD ?

Debugger_hWnd       DWORD ?
DebugMenuHandle     DWORD ?

DissMenuHandle      DWORD   ?

LastDebugFrameCounter   DWORD   ?
LastDebugCycleCounter   DWORD   ?

PCTable             WORD    60 DUP (?)

lpFwdRefTextOffsetTable     DWORD   ?
FwdRefTextOffsetTable       DWORD   60 DUP (?)

savelpFwdRefTextOffsetTable DWORD   ?
saveFwdRefTextOffsetTable   DWORD   60 DUP (?)

Z80PC               WORD ?
oldZ80PC            WORD ?
FwdAddr             WORD ?
ForwardAddr         WORD ?
FwdAddrValid        BYTE ?
FwdAddrRST          BYTE ?
ForwardAddrValid    BYTE ?
DissLineLength      BYTE ?
GotOffset           BYTE ?
DissOffset          BYTE ?
WantBlankLine       BYTE ?
ViewAsDump          BYTE ?
DebugSHIFTKeyDown   BYTE ?
DebugCTRLKeyDown    BYTE ?

DisassemblyUpdated  BYTE    ?

in_single_step      byte    ?
snow_float          byte    ?   ; (bool) does floating bus allow for snow effect data bus reads?

align 4
DissScrollBarhWnd   dd      ?
DissScrollBarInfo   SCROLLINFO <?>

DebugWindowRect     RECT    <?>

MAXBREAKPOINTS      equ     32

TBREAKPOINT         STRUCT
PC                  DWORD   ?   ; PC address in lower 16 bits, upper = 0 for in use, $FFFF not in use
Enabled             BYTE    ?   ; is breakpoint currently enabled; a breakpoint can be in use but not currently active
_pad                BYTE    3   dup (?)
TBREAKPOINT         ENDS

.data
align 16
RunDebugFrame1      LABEL   DWORD   ; 4 bytes, any of which cause the debug frame to run
Check_Breakpoints   db      FALSE
Check_RunTo         db      FALSE
Check_LeaveROMSpace db      FALSE
Check_TraceHook     db      FALSE

RunDebugFrame2      LABEL   DWORD   ; 4 bytes, any of which cause the debug frame to run
Check_ExitSub       db      FALSE
FDCBreakEnabled     db      FALSE
Check_EnterROMSpace db      FALSE
                    db      FALSE   ; spare trap conditions

BreakPoints         db      (MAXBREAKPOINTS * sizeof TBREAKPOINT)  dup (-1) ; list of breakpoint addresses
TraceHook           dd      0

TraceStopFlag       db      0
BreakPointCnt       db      0               ; number of active breakpoints
ShowHex             db      TRUE
ShowOpsAsAscii      db      FALSE
GotWindowPlacement  db      FALSE
RasterUpdateDisplay db      FALSE

DebuggerActive      db      FALSE

MaxDisassemblyLines db      27
MaxDumpAsHexDec     db      8
MaxDumpAsAscii      db      16

                    RESETENUM
                    ENUM    diss_large_font, diss_small_font
disassemblyfontsize db      diss_large_font ; defaults to large font


DebuggerError       db      "Debugger error", 0
szToolBarClass      db      "ToolbarWindow32", 0

.data?
align   4
hDbgToolBar         HWND    ?

TempMemoryAddress   WORD    ?


.code
                    include DockWindow.asm
                    include CustomWindowMessages.asm
                    include SourceRipper.asm
                    include DebugFind.asm
                    include Registers.asm
                    include DebugPlus3.asm
                    include DebugIDE.asm
                    include DebugRunTo.asm
                    include DebugMemory.asm
                    include DebugPCHistory.asm
                    include DebugBreakpoints.asm
                    include DebugCommandParser.asm

align 16
UpdateDebugDisplay  proc
                    .if     RasterUpdateDisplay == FALSE
                            ; to get the correct +3 floating bus value in the debugger,
                            ; we render to the current tstate and then preserve the +3 floating value while the full frame is rendered
                            RENDERCYCLES
                            movzx   eax, SPGfx.plus3_float_byte
                            push    eax
                            RENDERFRAME
                            pop     eax
                            mov     SPGfx.plus3_float_byte, al
                    .else
                            RENDERCYCLES
                            invoke  SetDirtyLines
                            UPDATEWINDOW
                    .endif
                    ret
UpdateDebugDisplay  endp

;UpdateDebugDisplay  proc
;                    .if     RasterUpdateDisplay == FALSE
;                            RENDERFRAME
;                    .else
;                            RENDERCYCLES
;                            invoke  SetDirtyLines
;                            UPDATEWINDOW
;                    .endif
;                    ret
;UpdateDebugDisplay  endp

; used at runtime, this checks for an enabled breakpoint at the specified address
ISBREAKPOINT        MACRO   Address ; word
                    local   @exit
                    movzx   eax, Address
                    lea     esi, BreakPoints
                    mov     ecx, MAXBREAKPOINTS
                @@: cmp     eax, [esi].TBREAKPOINT.PC
                    je      @F          ; zero set if breakpoint hit
                    jc      @exit       ; early exit; breakpoints are sorted in ascending order so Carry indicates we're beyond this BP value or hit end marker
                    add     esi, sizeof TBREAKPOINT
                    dec     ecx
                    jnz     @B
                    inc     ecx         ; zero clear if no breakpoint hit
                    jmp     @exit

                    ; come here if we've hit this breakpoint address
                    ; set zero flag based on if this BP is currently enabled
                @@: cmp     [esi].TBREAKPOINT.Enabled, TRUE

        @exit:
                    ENDM

; search for a breakpoint at the specified address only, irrespective of enabled state
ISBREAKPOINTDEFINED MACRO   Address ; word
                    local   @exit
                    movzx   eax, Address
                    lea     esi, BreakPoints
                    mov     ecx, MAXBREAKPOINTS
                @@: cmp     eax, [esi].TBREAKPOINT.PC
                    je      @exit       ; zero set if breakpoint address matches
                    jc      @exit       ; early exit; breakpoints are sorted in ascending order so Carry indicates we're beyond this BL value or hit end marker
                    add     esi, sizeof TBREAKPOINT
                    dec     ecx
                    jnz     @B
                    inc     ecx         ; zero clear if no breakpoint hit
                    jmp     @exit

        @exit:
                    ENDM

HASLEFTROMSPACE     MACRO
                    ; exit if execution address leaves ROM space
                    ; Note: range changed to above 128K paging routines
                    ;       and to ignore returning from ROM ISR
                    .if     Check_LeaveROMSpace == TRUE
                            mov     ax, MACHINE.RomSpaceUpperCheck
                            .if     (zPC >= ax) && (PrevzPC < ax)
                                    .if     (PrevzPC < 38h) || (PrevzPC > 52h)
                                            jmp     DebugFrame_Trap
                                    .endif
                            .endif
                    .endif
                    ENDM

HASENTEREDROMSPACE  MACRO
                    ; exit if execution address enters ROM space
                    ; Note: range changed to above 128K paging routines
                    ;       and to ignore entering the ROM ISR
                    .if     Check_EnterROMSpace == TRUE
                            mov     ax, MACHINE.RomSpaceUpperCheck
                            .if     (zPC < ax) && (PrevzPC >= ax)
                                    .if     (zPC < 38h) || (zPC > 52h)
                                            jmp     DebugFrame_Trap
                                    .endif
                            .endif
                    .endif
                    ENDM

align 16
HandleDebuggerDialog:
                    CLEARSOUNDBUFFERS
                    .if     FullScreenMode == TRUE
                            invoke  FlipDisplayMode
                            invoke  AttachMenu, hWnd
                    .endif

                    mov     MenuNoUnattach, TRUE
                    mov     Check_RunTo, FALSE
                    mov     Check_ExitSub, FALSE

                    invoke  DialogBoxParam, [GlobalhInst], IDD_DEBUGGER, [hWnd], addr DebuggerDlgProc, NULL

                    mov     MenuNoUnattach, FALSE
                    ret

align 16
SetDebugMenuCheck   proc    MenuItemID:DWORD, Value:BYTE

                    .if     Value == 0
                            mov eax, MF_UNCHECKED or MF_BYCOMMAND
                    .else
                            mov eax, MF_CHECKED or MF_BYCOMMAND
                    .endif

                    invoke  CheckMenuItem, DebugMenuHandle, MenuItemID, eax
                    ret

SetDebugMenuCheck   endp

CLOSE_DEBUGGER              macro
                            jmp     Close_Debugger
                            endm

align 16
DebuggerDlgProc proc    uses        ebx esi edi,
                        hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                LOCAL   BreakControl:       DWORD,
                        wParamLow:          WORD,
                        wParamHigh:         WORD,
                        CurrentZ80PC:       WORD,
                        SearchWrapped:      BOOL,
                        tempDissString[300]:BYTE

                local   textstring:         TEXTSTRING,
                        pTEXTSTRING:        DWORD

    RESETMSG

OnInitDialog
        mov     DebuggerActive, TRUE

        ifc     MAXIMUMSPEED eq TRUE then call SetNormalSpeed   ; restore to normal speed

        ; create global window handle
        m2m     Debugger_hWnd, hWndDlg

        mov     DebugSHIFTKeyDown, FALSE
        mov     DebugCTRLKeyDown, FALSE
        mov     DebugMenuHandle, $fnc (GetMenu, Debugger_hWnd)

        ; create each debugger dialog window
        mov     FindDLG.hWnd,         $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGFINDDLG,       hWndDlg,    addr DebugFindDlgProc,      NULL)
        mov     SourceRipperDLG.hWnd, $fnc (CreateDialogParam, GlobalhInst, IDD_VIEWDISASSEMBLYDLG, hWndDlg,    addr SourceRipperDlgProc,   NULL)
        mov     RegistersDLG.hWnd,    $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGREGISTERSDLG,  hWndDlg,    addr RegistersDlgProc,      NULL)
        mov     Plus3DLG.hWnd,        $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGPLUS3DLG,      hWndDlg,    addr DebugPlus3DlgProc,     NULL)
        mov     IDEDLG.hWnd,          $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGIDEDLG,        hWndDlg,    addr DebugIDEDlgProc,       NULL)
        mov     MemoryDLG.hWnd,       $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGMEMORYDLG,     hWndDlg,    addr DebugMemoryDlgProc,    NULL)
        mov     PCHistoryDLG.hWnd,    $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGPCHISTORYDLG,  hWndDlg,    addr DebugPCHistoryDlgProc, NULL)
        mov     BreakpointsDLG.hWnd,  $fnc (CreateDialogParam, GlobalhInst, IDD_DEBUGBREAKPOINTSDLG,hWndDlg,    addr DebugBreakpointsDlgProc, NULL)
        mov     CommandParserDLG.hWnd,$fnc (CreateDialogParam, GlobalhInst, IDD_COMMANDPARSERDLG,   hWndDlg,    addr DebugCmdParserDlgProc, NULL)

        mov     FindDLG.lpName,         CTXT ("DebugFind")
        mov     SourceRipperDLG.lpName, CTXT ("DebugSourceRipper")
        mov     RegistersDLG.lpName,    CTXT ("DebugRegisters")
        mov     Plus3DLG.lpName,        CTXT ("DebugPlus3")
        mov     IDEDLG.lpName,          CTXT ("DebugIDE")
        mov     MemoryDLG.lpName,       CTXT ("DebugMemory")
        mov     PCHistoryDLG.lpName,    CTXT ("DebugPCHistory")
        mov     BreakpointsDLG.lpName,  CTXT ("DebugBreakpoints")
        mov     CommandParserDLG.lpName,CTXT ("DebugCommandParser")

        ; send each debugger dialog window their LP_LOADSTATE message
        invoke  SendMessage, FindDLG.hWnd,         WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, SourceRipperDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, RegistersDLG.hWnd,    WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, Plus3DLG.hWnd,        WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, IDEDLG.hWnd,          WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, MemoryDLG.hWnd,       WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, PCHistoryDLG.hWnd,    WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, BreakpointsDLG.hWnd,  WM_COMMAND, WPARAM_USER, LP_LOADSTATE
        invoke  SendMessage, CommandParserDLG.hWnd,WM_COMMAND, WPARAM_USER, LP_LOADSTATE

        ; send each debugger dialog window their LP_SETSHOWSTATE message
        invoke  SendMessage, FindDLG.hWnd,         WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, SourceRipperDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, RegistersDLG.hWnd,    WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, Plus3DLG.hWnd,        WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, IDEDLG.hWnd,          WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, MemoryDLG.hWnd,       WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, PCHistoryDLG.hWnd,    WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, BreakpointsDLG.hWnd,  WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE
        invoke  SendMessage, CommandParserDLG.hWnd,WM_COMMAND, WPARAM_USER, LP_SETSHOWSTATE

        ; handle debugger specific menu items
        .if     HardwareMode == HW_PENTAGON128
                invoke  EnableMenuItem, DebugMenuHandle, IDM_TRDOS_ENABLEREADPORTS,  MF_ENABLED or MF_BYCOMMAND
                invoke  EnableMenuItem, DebugMenuHandle, IDM_TRDOS_ENABLEWRITEPORTS, MF_ENABLED or MF_BYCOMMAND
        .endif


        mov     DISASSEMBLYhWnd, $fnc (GetDlgItem, hWndDlg, IDC_DISASSEMBLYLST)

        mov     DissScrollBarhWnd, $fnc (GetDlgItem, hWndDlg, IDC_DISASSEMBLYSCB)

        mov     DissScrollBarInfo.SCROLLINFO.cbSize, sizeof SCROLLINFO
        mov     DissScrollBarInfo.SCROLLINFO.fMask,  SIF_POS or SIF_RANGE
        mov     DissScrollBarInfo.SCROLLINFO.nPage,  1
        mov     DissScrollBarInfo.SCROLLINFO.nMin,   0
        mov     DissScrollBarInfo.SCROLLINFO.nMax,   65535
        mov     DissScrollBarInfo.SCROLLINFO.nPos,   0
        invoke  SetScrollInfo, DissScrollBarhWnd, SB_CTL, addr DissScrollBarInfo, TRUE


      ; preserve the disassembly window's original font which is restored on the OnClose event
        mov     DISASSEMBLYOldFont, $fnc (SendMessage, DISASSEMBLYhWnd, WM_GETFONT, 0, 0)

        invoke  SetDisassemblyFontSize, disassemblyfontsize

        ; set the required menuitem checkbox states
        invoke  SetDebugMenuCheck, IDM_BREAKLEAVINGROMSPACE,  Check_LeaveROMSpace
        invoke  SetDebugMenuCheck, IDM_BREAKENTERINGROMSPACE, Check_EnterROMSpace
        invoke  SetDebugMenuCheck, IDM_RASTERUPDATE, RasterUpdateDisplay

        ; restore last dialog location if available
        invoke  GetDialogPlacement

        ; window handle of disassembly control
        mov     hwndDissTT, 0      ; allows for recreation of disassembly control's tooltip control
        mov     DISLST_Handle,     $fnc (GetDlgItem, Debugger_hWnd, IDC_DISASSEMBLYLST)
        mov     OrigDISLSTWndProc, $fnc (SetWindowLong, DISLST_Handle, GWL_WNDPROC, addr DISLST_SubclassProc)

        invoke  InitCursorStack

        ; we must clear MAXIMUMAUTOLOADTYPE to turn off max speed emulation if the tape autoload typer was active
        ; else it would remain active if we hit a breakpoint en-route
        mov     MAXIMUMAUTOLOADTYPE, FALSE

        ; clear the RAM-only flag for RunTo_PortRead condition
        mov     RunToPortRAMOnly, FALSE

        ; setup starting disassembly address
        mov     ax, zPC
        mov     Z80PC, ax

        .if     UsePrevzPC == TRUE  ; set if trapped on memory breakpoint, etc.
                mov     UsePrevzPC, FALSE
                mov     ax, PrevzPC
                mov     Z80PC, ax
        .endif

        invoke  SetProfileCycles

        invoke  SetDebugReadWriteButtonStates, hWndDlg
        invoke  CheckDlgButton, hWndDlg, IDC_DUMPCHK, ZeroExt (ViewAsDump)
        invoke  EnableDumpControls, hWndDlg
        invoke  UpdateDebugger

        invoke  SetDebuggerLogButtonState   ; start/stop PC logging button state + text

        invoke  AddDebuggerToolBar, GlobalhInst, Debugger_hWnd
        movzx   eax, EmuRunning
        xor     eax, TRUE
        invoke  SendMessage, hDbgToolBar, TB_CHECKBUTTON, IDM_PAUSE, eax

        ; attach menus to debugger controls
        mov     DissMenuHandle,     $fnc (LoadMenu, GlobalhInst, IDR_DISASSEMBLYMENU)
        invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_SETMENU, 0, $fnc (GetSubMenu, DissMenuHandle, 0)

        ; set Debug->Run To Tape Starts/Stops menu items
        .if     TapePlaying == TRUE
                mov     esi, MF_GRAYED  or MF_BYCOMMAND
                mov     edi, MF_ENABLED or MF_BYCOMMAND
        .else
                mov     esi, MF_ENABLED or MF_BYCOMMAND
                mov     edi, MF_GRAYED  or MF_BYCOMMAND
        .endif
        invoke  EnableMenuItem, DebugMenuHandle, IDM_RUNTOTAPESTARTS,  esi
        invoke  EnableMenuItem, DebugMenuHandle, IDM_RUNTOTAPESTOPS,   edi

        invoke  UpdateDebugDisplay

        invoke  PopulateExecCmd
        invoke  PopulateIDEDlg
        invoke  PopulateMemoryDlg
        invoke  PopulatePCHistoryDlg

        invoke  SetPagingInfo

        invoke  SendMessage, hWndDlg, WM_SETICON, ICON_SMALL, $fnc (LoadIcon, hInstance, IDI_DEBUGGERICON)

      ; we're setting initial debugger control focus to our hidden rawtext control
      ; to prevent keyboard input from initially activating any debugger controls (this was auto-stepping on space bar in certain circumstances)

        invoke  SetFocus, $fnc (GetDlgItem, Debugger_hWnd, IDC_DEBUGGERDEFAULTRAW)
        .if     eax == NULL
                ADDMESSAGE  "Debugger SetFocus () failed!"
        .endif
        return  FALSE   ; overrides dialog's default control activation

OnSysColorChange
        invoke  SendMessage,    $fnc (GetDlgItem, Debugger_hWnd, IDT_DEBUGTOOLBAR), uMsg, wParam, lParam
        invoke  InvalidateRect, $fnc (GetDlgItem, Debugger_hWnd, IDT_DEBUGTOOLBAR), NULL, TRUE
        invoke  UpdateWindow,   $fnc (GetDlgItem, Debugger_hWnd, IDT_DEBUGTOOLBAR)

OnNotify
            ASSUME  EBX: PTR NMHDR
            mov     ebx, lParam
            .if     [ebx].NMHDR.code == TTN_NEEDTEXT
                    ASSUME  EBX: PTR TOOLTIPTEXT
                    mov     [ebx].hInst, NULL
                    switch  [ebx].hdr.idFrom
                            case    IDM_DBGLOADSNAPSHOT
                                    mov     [ebx].lpszText, CTXT ("Load Snapshot")
                                    return  0
                            case    IDM_DBGSAVESNAPSHOT
                                    mov     [ebx].lpszText, CTXT ("Save Snapshot")
                                    return  0
                            case    IDM_PAUSE
                                    mov     [ebx].lpszText, CTXT ("Pause")
                                    return  0
                            case    IDM_GOTOADDRESS
                                    mov     [ebx].lpszText, CTXT ("Go To")
                                    return  0
                            .else
                                    mov     [ebx].lpszText, NULL
                                    return  0
                    endsw
            .endif
            return  TRUE
            ASSUME  EBX: NOTHING

OnCommand
        mov     eax, wParam
        mov     wParamLow, ax
        shr     eax, 16
        mov     wParamHigh, ax

        .if     wParam == WPARAM_USER
                switch  lParam
                        case    LP_USERFIND
                                .if     SearchByteCount > 0

                                        .if     SearchInDisassembly == TRUE
                                                mov     bx, Z80PC
                                                mov     SearchWrapped, FALSE

                                                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                                invoke  DisassembleLine, pTEXTSTRING

                                                .while  SearchWrapped == FALSE
                                                        mov     ax, Z80PC
                                                        mov     CurrentZ80PC, ax

                                                        invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                                        invoke  DisassembleLine, pTEXTSTRING

                                                        mov     ax, Z80PC
                                                        .if     ax < CurrentZ80PC
                                                                mov     SearchWrapped, TRUE
                                                        .endif
                                                        lea     esi, textstring
                                                        lea     edi, tempDissString
                                                        .while  TRUE
                                                                lodsb
                                                                .break  .if al == 0
                                                                .if     al == " "
                                                                        stosb
                                                                        .while  al == " "
                                                                                lodsb
                                                                        .endw
                                                                        dec     esi
                                                                .else
                                                                        stosb
                                                                .endif
                                                        .endw
                                                        mov     al, " "
                                                        stosb               ; main string must be longer than substring
                                                        xor     al, al
                                                        stosb               ; null-terminate main string
                                                        invoke  InString, 1, ADDR tempDissString, ADDR SearchParam
                                                        test    eax, eax
                                                        .if     (!SIGN?) && (eax > 0)
                                                                ; found a match
                                                                mov     ax, CurrentZ80PC
                                                                mov     Z80PC, ax
                                                                invoke  UpdateDisassembly
                                                                return  TRUE
                                                        .endif
                                                .endw

                                                mov     Z80PC, bx
                                                jmp     SearchMatchFail
                                        .endif

                                        mov     cx, Z80PC
                                        inc     cx

                                    SearchAgain:
                                        mov     bx, cx
                                        lea     esi, SearchParam
                                        mov     edx, SearchByteCount
                                    @@: call    MemGetByte
                                        cmp     al, [esi]
                                        jne     NoSearchMatch
                                        inc     esi
                                        inc     bx
                                        dec     edx
                                        jnz     @B

                                        mov     Z80PC, cx
                                        invoke  UpdateDisassembly
                                        return  TRUE

                                    NoSearchMatch:
                                        inc     cx
                                        jnz     SearchAgain

                                    SearchMatchFail:
                                        invoke  EnableDebugWindows, FALSE
                                        invoke  ShowMessageBox, [hWndDlg], SADD("No Match Found"), ADDR szWindowName, MB_OK or MB_ICONSTOP
                                        invoke  EnableDebugWindows, TRUE
                                .endif
                                ; Find dialog was active when "Find" option was clicked
                                invoke  SetFocus, FindDLG.hWnd
                                return  TRUE
                endsw

                return  TRUE
        .endif

        .if     wParamLow == IDC_DISASSEMBLYLST
                .if     wParamHigh == RTN_SELCHANGE
                        invoke  GetSelectedLine
                        mov     ax, [PCTable+eax*2] ; get the PC value for the selected line
                        mov     Z80PC, ax

                        invoke  UpdateDisassembly  ; updates display and sets index to 0
                        UPDATEWINDOW
                        return  TRUE

                .elseif wParamHigh == RTN_ENTERMENULOOP
                        mov     ebx, $fnc (GetSubMenu, DissMenuHandle, 0)
                        switch  disassemblyfontsize
                                case    diss_large_font
                                        invoke  CheckMenuItem, ebx, IDM_DISS_LARGE_FONT,  MF_BYCOMMAND or MF_CHECKED
                                        invoke  CheckMenuItem, ebx, IDM_DISS_SMALL_FONT,  MF_BYCOMMAND or MF_UNCHECKED

                                case    diss_small_font
                                        invoke  CheckMenuItem, ebx, IDM_DISS_LARGE_FONT,  MF_BYCOMMAND or MF_UNCHECKED
                                        invoke  CheckMenuItem, ebx, IDM_DISS_SMALL_FONT,  MF_BYCOMMAND or MF_CHECKED
                        endsw
                        return  TRUE

                .elseif wParamHigh == RTN_EXITMENULOOP
                        return  TRUE

                .elseif wParamHigh == RTN_MENUITEM
                        switch  lParam
                                case    IDM_DISS_BACK
                                        invoke  RetraceReference
                                        return  TRUE

                                case    IDM_DISS_SHOWNEXTINSTRUCTION
                                        invoke  SetNewZ80PC, zPC
                                        return  TRUE

                                case    IDM_DISS_RUNTOSELECTED
                                        invoke  GetSelectedLine
                                        mov     ax, [PCTable+eax*2] ; get the PC value for the selected line
                                        mov     RunToPC, ax
                                        invoke  Set_RunTo_Condition, RUN_TO_PC
                                        CLOSE_DEBUGGER

                                case    IDM_DISS_TOGGLEBREAKPOINT
                                        invoke  GetSelectedLine
                                        mov     ax, [PCTable+eax*2] ; get the PC value for the selected line
                                        invoke  ToggleBreakpoint, ax
                                        invoke  UpdateDebugger
                                        return  TRUE

                                case    IDM_DISS_LARGE_FONT
                                        mov     disassemblyfontsize,    diss_large_font
                                        invoke  SetDisassemblyFontSize, disassemblyfontsize
                                        invoke  UpdateDisassembly

                                case    IDM_DISS_SMALL_FONT
                                        mov     disassemblyfontsize,    diss_small_font
                                        invoke  SetDisassemblyFontSize, disassemblyfontsize
                                        invoke  UpdateDisassembly
                        endsw
                .endif
        .endif

        .if     wParam == IDCANCEL
                CLOSE_DEBUGGER
        .endif

        .if     wParamHigh == BN_CLICKED

            .if     (wParamLow == IDC_DISSBREAKONREAD) || (wParamLow == IDC_DISSBREAKONWRITE) || (wParamLow == IDC_DISSBREAKONACCESS)
                    movzx   eax, wParamLow
                    mov     BreakControl, eax
                    invoke  SendDlgItemMessage, hWndDlg, BreakControl, BM_GETSTATE, 0, 0
                    and     eax, BST_CHECKED
                    .if     eax != 0
                            invoke  SendDlgItemMessage, hWndDlg, IDC_COMPDISPLAYLST, LB_GETCURSEL, 0, 0
                            .if     eax != LB_ERR
                                            ; Stop hook procs use value in Z80PC, which is correct here
                                    .if     BreakControl == IDC_DISSBREAKONREAD
                                            call    StopatMemRead
                                    .elseif BreakControl == IDC_DISSBREAKONWRITE
                                            call    StopatMemWrite
                                    .elseif BreakControl == IDC_DISSBREAKONACCESS
                                            call    StopatMemAccess
                                    .endif
                            .endif
                    .else
                            mov     Check_TraceHook, FALSE
                    .endif
                    invoke  SetDebugReadWriteButtonStates, hWndDlg
                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDC_STEP   ; single step
                    invoke  Single_Step

                    invoke  UpdateDebugDisplay
                    invoke  UpdateDebugger
                    invoke  SetProfileCycles

                    invoke  PopulateExecCmd
                    invoke  PopulateIDEDlg
                    invoke  PopulateMemoryDlg
                    invoke  PopulatePCHistoryDlg
                    invoke  SetPagingInfo
                    return  TRUE

            .elseif wParamLow == IDC_HEXDEC ; flip hex/dec
                    xor     ShowHex, TRUE
                    invoke  UpdateDebugger

                    invoke  PopulateExecCmd
                    invoke  PopulateIDEDlg
                    invoke  PopulateMemoryDlg
                    invoke  PopulatePCHistoryDlg
                    invoke  PopulateBrkListbox
                    return  TRUE

            .elseif wParamLow == IDC_HEXASCII   ; flip hex/ascii
                    xor     ShowOpsAsAscii, TRUE
                    invoke  UpdateDebugger
                    invoke  PopulateMemoryDlg
                    return  TRUE

            .elseif wParamLow == IDC_DUMPCHK    ; flip mem dump/disassembly
                    xor     ViewAsDump, TRUE
                    invoke  EnableDumpControls, hWndDlg
                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDC_START_STOP_LOGGING_CHK ; start/stop PC logging
                    .if     DoLogging == FALSE
                            invoke  Start_PC_Logging, NULL
                    .else
                            invoke  Stop_PC_Logging
                    .endif
                    return  TRUE

            .elseif wParamLow == IDC_RUNTO          ; run to selected address
                    invoke  Set_RunTo_Condition, RUN_TO_PC
                    mov     ax, Z80PC
                    mov     RunToPC, ax
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDC_EXITSUB        ; exit subroutine
                    mov     Check_ExitSub, TRUE
                    mov     RETCounter, 0
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDC_STEPOVER       ; run to the following opcode
                    invoke  Set_RunTo_Condition, RUN_TO_PC
                    mov     ax, [PCTable+2]         ; address of next opcode
                    mov     RunToPC, ax
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDC_TOGGLEBREAKPOINT   ; toggle breakpoint at this address
                    invoke  ToggleBreakpoint, Z80PC
                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDC_CLEARBREAKPOINTS   ; clear all breakpoints
                    invoke  ClearBreakpoints
                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDC_FOLLOWREF          ; follow a forward reference
                    invoke  FollowReference
                    return  TRUE

            .elseif wParamLow == IDC_BACKREF            ; retrace from cursor stack
                    invoke  RetraceReference
                    return  TRUE

            .elseif wParamLow == IDC_POKEMEM            ; poke memory
                    movzx   ebx, Z80PC
                    mov     PokeAddressInit, ebx
                    call    MemGetByte
                    and     eax, 255
                    mov     PokeValueInit, eax
                    mov     PokeUpdatesDebugger, TRUE   ; disassembly updates as pokes are made
                  ; bring up the normal Poke dialog with the debugger as the owner window
                    invoke  DialogBoxParam, GlobalhInst, IDD_POKE, [Debugger_hWnd], addr PokeDlgProc, NULL
                    return  TRUE

            .elseif wParamLow == IDC_PREV_PC_STC        ; go to previous PC location
                    invoke  SetNewZ80PC, PrevzPC
                    return  TRUE
            .endif

        .endif

; menu commands
        .if wParamHigh == 0

            .if     wParamLow == IDM_VIEW_REGISTERS             ; registers dialog
                    invoke  SendMessage, RegistersDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE
                    invoke  UpdateAllRegisters
                    return  TRUE

            .elseif wParamLow == IDM_VIEW_FIND                  ; find dialog
                    invoke  SendMessage, FindDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE
                    return  TRUE

            .elseif wParamLow == IDM_VIEW_SOURCECODE_RIPPER     ; disassembly viewer/ripper dialog
                    invoke  SendMessage, SourceRipperDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE
                    return  TRUE

            .elseif wParamLow == IDM_VIEW_PLUS3                 ; plus 3 dialog
                    invoke  SendMessage, Plus3DLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE
                    return  TRUE

            .elseif wParamLow == IDM_VIEW_IDE                   ; IDE dialog
                    invoke  SendMessage, IDEDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE
                    return  TRUE

            .elseif wParamLow == IDM_VIEW_MEMORY                ; Memory dialog
                    invoke  SendMessage, MemoryDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE

            .elseif wParamLow == IDM_VIEW_PC_HISTORY            ; PC History dialog
                    invoke  SendMessage, PCHistoryDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE

            .elseif wParamLow == IDM_VIEW_BREAKPOINTS           ; Breakpoints dialog
                    invoke  SendMessage, BreakpointsDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE

            .elseif wParamLow == IDM_VIEW_COMMAND_PARSER        ; Command Parser dialog
                    invoke  SendMessage, CommandParserDLG.hWnd, WM_COMMAND, WPARAM_USER, LP_TOGGLESHOWSTATE


            .elseif wParamLow == IDM_RUNTOFRAMESTART        ; run to start of frame
                    mov     RunTo_Cycle, 1000
                    invoke  Set_RunTo_Condition, RUN_TO_CYCLE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOFRAMEEND          ; run to end of frame
                    mov     RunTo_Cycle, @EVAL (MACHINE.FrameCycles - 1000)
                    invoke  Set_RunTo_Condition, RUN_TO_CYCLE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOINTERRUPT         ; run to interrupt
                    invoke  Set_RunTo_Condition, RUN_TO_INTERRUPT
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOINTERRUPTRETRIGGER    ; run to retriggered interrupt
                    invoke  Set_RunTo_Condition, RUN_TO_INTERRUPT_RETRIGGER
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOSPECIFIEDCYCLE         ; run to specified cycle
                    .if     $fnc (GetNumericInput, hWndDlg, hInstance, hIcon, SADD ("Run To Specified Cycle"), SADD ("Cycle:")) == TRUE
                            .if     ecx < MACHINE.FrameCycles
                                    mov     RunTo_Cycle, ecx
                                    invoke  Set_RunTo_Condition, RUN_TO_CYCLE
                                    CLOSE_DEBUGGER
                            .endif
                    .endif
                    return  TRUE

            .elseif wParamLow == IDM_RUNTOHALTED    ; run until CPU is HALTed
                    invoke  Set_RunTo_Condition, RUN_TO_HALTED
                    CLOSE_DEBUGGER

            .elseif (wParamLow >= IDM_KEYROW_1_5) && (wParamLow <= IDM_KEYROW_B_SPACE) ; keyboard half-row scans
                    movzx   eax, wParamLow
                    sub     eax, IDM_KEYROW_1_5
                    mov     ax, [Run_KeyHalfRowMasks+eax*2]
                    mov     RunToPortMask, ax
                    mov     RunToPortReadAddr, 0
                    mov     RunToPortRAMOnly, TRUE  ; only break for keyscans when in RAM code

                    invoke  Set_RunTo_Condition, RUN_TO_PORT_READ
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_KEYROW_ANY_KEY ; any keyboard half-row scan
                    mov     RunToPortMask, 0001h
                    mov     RunToPortReadAddr, 0
                    mov     RunToPortRAMOnly, TRUE  ; only break for any keyscan when in RAM code

                    invoke  Set_RunTo_Condition, RUN_TO_PORT_READ
                    CLOSE_DEBUGGER

            .elseif (wParamLow >= IDM_TRDOS_READSYSTEMREGISTER) && (wParamLow <= IDM_TRDOS_READDATAREGISTER) ; TR_DOS port reads
                    switch  wParamLow
                            case    IDM_TRDOS_READSYSTEMREGISTER
                                    mov     RunToDevicePort, TRDOS_SYSTEM_REGISTER
                            case    IDM_TRDOS_READSTATUSREGISTER
                                    mov     RunToDevicePort, TRDOS_STATUS_REGISTER
                            case    IDM_TRDOS_READTRACKREGISTER
                                    mov     RunToDevicePort, TRDOS_TRACK_REGISTER
                            case    IDM_TRDOS_READSECTORREGISTER
                                    mov     RunToDevicePort, TRDOS_SECTOR_REGISTER
                            case    IDM_TRDOS_READDATAREGISTER
                                    mov     RunToDevicePort, TRDOS_DATA_REGISTER
                    endsw

                    invoke  Set_RunTo_Condition, RUN_TO_DEVICE_PORT_READ
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_FLOATINGBUSREAD    ; run until port read from the floaing bus
                    invoke  Set_RunTo_Condition, RUN_TO_FLOATING_BUS_PORT_READ
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOSPECIFIEDPORTREAD    ; run until port read from specified port
                    .if     $fnc (GetNumericInput, hWndDlg, hInstance, hIcon, SADD ("Run until read from specified port"), SADD ("Port Address:")) == TRUE
                            .if     ecx <= 65535
                                    ifc     ecx ge 256 then mov RunToPortMask, 65535 else mov RunToPortMask, 255
                                    mov     RunToPortReadAddr,  cx
                                    invoke  Set_RunTo_Condition, RUN_TO_PORT_READ
                                    CLOSE_DEBUGGER
                            .endif
                    .endif
                    return  TRUE

            .elseif (wParamLow >= IDM_TRDOS_WRITESYSTEMREGISTER) && (wParamLow <= IDM_TRDOS_WRITEDATAREGISTER) ; TR_DOS port writes
                    switch  wParamLow
                            case    IDM_TRDOS_WRITESYSTEMREGISTER
                                    mov     RunToDevicePort, TRDOS_SYSTEM_REGISTER
                            case    IDM_TRDOS_WRITECOMMANDREGISTER
                                    mov     RunToDevicePort, TRDOS_COMMAND_REGISTER
                            case    IDM_TRDOS_WRITETRACKREGISTER
                                    mov     RunToDevicePort, TRDOS_TRACK_REGISTER
                            case    IDM_TRDOS_WRITESECTORREGISTER
                                    mov     RunToDevicePort, TRDOS_SECTOR_REGISTER
                            case    IDM_TRDOS_WRITEDATAREGISTER
                                    mov     RunToDevicePort, TRDOS_DATA_REGISTER
                    endsw

                    invoke  Set_RunTo_Condition, RUN_TO_DEVICE_PORT_WRITE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_ULA_FE             ; ULA Port
                    mov     RunToDevicePort, ULA_FE
                    invoke  Set_RunTo_Condition, RUN_TO_DEVICE_PORT_WRITE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_PAGING_7FFD        ; 128K Paging Port
                    mov     RunToDevicePort, PAGING_7FFD
                    invoke  Set_RunTo_Condition, RUN_TO_DEVICE_PORT_WRITE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_PAGING_1FFD        ; +3 Paging Port
                    mov     RunToDevicePort, PAGING_1FFD
                    invoke  Set_RunTo_Condition, RUN_TO_DEVICE_PORT_WRITE
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOSPECIFIEDPORTWRITE    ; run until port write to specified port
                    .if     $fnc (GetNumericInput, hWndDlg, hInstance, hIcon, SADD ("Run until write to specified port"), SADD ("Port Address:")) == TRUE
                            .if     ecx <= 65535
                                    ifc     ecx ge 256 then mov RunToPortMask, 65535 else mov RunToPortMask, 255
                                    mov     RunToPortWriteAddr, cx
                                    invoke  Set_RunTo_Condition, RUN_TO_PORT_WRITE
                                    CLOSE_DEBUGGER
                            .endif
                    .endif
                    return  TRUE

            .elseif wParamLow == IDM_RUNTOTAPESTARTS    ; run until tape starts
                    invoke  Set_RunTo_Condition, RUN_TO_TAPE_STARTS
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOTAPESTOPS     ; run until tape stops
                    invoke  Set_RunTo_Condition, RUN_TO_TAPE_STOPS
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTODISKMOTORON   ; run until disk motor turns on
                    invoke  Set_RunTo_Condition, RUN_TO_DISK_MOTOR_ON
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTODISKMOTOROFF  ; run until disk motor turns off
                    invoke  Set_RunTo_Condition, RUN_TO_DISK_MOTOR_OFF
                    CLOSE_DEBUGGER


        ; run to z80 opcode menu items
            .elseif wParamLow == IDM_RUNTOIM1     ; run until IM 1
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0ED56h
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOIM2     ; run until IM 2
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0ED5Eh
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTODI      ; run until DI
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0F3h
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTOEI      ; run until EI
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0FBh
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTO_LDA_R    ; run until LD A,R
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0ED5Fh
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTO_LDR_A    ; run until LD R,A
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0ED4Fh
                    CLOSE_DEBUGGER

            .elseif wParamLow == IDM_RUNTO_LD_IX_16384  ; run until LD IX,16384
                    invoke  Set_RunTo_Condition, RUN_TO_OPCODE
                    mov     RunToOpcode, 0DD21h         ; gets set in LD IX handler only when IX loaded with 16384
                    CLOSE_DEBUGGER
        ; end of run to opcode menu items

            .elseif wParamLow == IDM_RUNTOUSERCONDITION
                    lea     esi, tempDissString
                    mov     byte ptr [esi], 0
                    invoke  GetTextInput, hWndDlg, hInstance, hIcon, SADD ("Enter break condition"), SADD ("Enter Condition:"), addr tempDissString
                    .if     byte ptr [esi] != 0
;                            invoke  ParseUserCondition, esi
;                            .if     eax == TRUE
;                                    invoke  Set_RunTo_Condition, RUN_TO_USER_CONDITION
;                                    CLOSE_DEBUGGER
;                            .endif
                    .endif
                    return  TRUE

            .elseif wParamLow == IDM_GOTOADDRESS
                    invoke  GetNumericInput, hWndDlg, hInstance, hIcon, SADD ("Go To"), SADD ("Address:")
                    .if     (eax == TRUE) && (ecx <= 65535)
                            invoke  SetNewZ80PC, cx
                    .endif
                    return  TRUE

            .elseif wParamLow == IDM_ENTERTEXTSTRING
                    lea     esi, tempDissString
                    mov     byte ptr [esi], 0
                    invoke  GetTextInput, hWndDlg, hInstance, hIcon, SADD ("Enter text at current address"), SADD ("Enter Text:"), addr tempDissString
                    .if     byte ptr [esi] != 0
                            mov     bx, Z80PC
                            .while  byte ptr [esi] != 0
                                    mov     al, [esi]
                                    call    MemPokeByte
                                    inc     bx
                                    inc     esi
                            .endw
                            invoke  UpdateDisassembly
                    .endif
                    return  TRUE


            .elseif wParamLow == IDM_BREAKLEAVINGROMSPACE
                    xor     Check_LeaveROMSpace, TRUE
                    invoke  SetDebugMenuCheck, IDM_BREAKLEAVINGROMSPACE, Check_LeaveROMSpace
                    return  TRUE

            .elseif wParamLow == IDM_BREAKENTERINGROMSPACE
                    xor     Check_EnterROMSpace, TRUE
                    invoke  SetDebugMenuCheck, IDM_BREAKENTERINGROMSPACE, Check_EnterROMSpace
                    return  TRUE

            .elseif wParamLow == IDM_RASTERUPDATE
                    xor     RasterUpdateDisplay, TRUE
                    invoke  SetDebugMenuCheck, IDM_RASTERUPDATE, RasterUpdateDisplay
                    return  TRUE

            .elseif wParamLow == IDM_DBGLOADSNAPSHOT
                    invoke  EnableDebugWindows, FALSE
                    invoke  LoadSnapshot, hWndDlg
                    invoke  EnableDebugWindows, TRUE
                    RENDERFRAME

                    mov     ax, zPC
                    mov     Z80PC, ax       ; setup starting disassembly address

                    m2m     LastDebugFrameCounter, GlobalFramesCounter  ; reset for a loaded snapshot within the debugger
                    m2m     LastDebugCycleCounter, totaltstates
                    invoke  SetProfileCycles

                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDM_DBGSAVESNAPSHOT
                    invoke  EnableDebugWindows, FALSE
                    invoke  EnableWindow, hWndDlg, FALSE

                    invoke  SaveSnapshot, hWndDlg

                    invoke  EnableWindow, hWndDlg, TRUE
                    invoke  EnableDebugWindows, TRUE
                    return  TRUE

            .elseif wParamLow == IDM_DBGLOADMEMSNAPSHOT
                    invoke  EnableDebugWindows, FALSE
                    invoke  LoadMemorySnapshot, hWndDlg
                    invoke  EnableDebugWindows, TRUE
                    RENDERFRAME

                    mov     ax, zPC
                    mov     Z80PC, ax       ; setup starting disassembly address

                    m2m     LastDebugFrameCounter, GlobalFramesCounter  ; reset for a loaded snapshot within the debugger
                    m2m     LastDebugCycleCounter, totaltstates
                    invoke  SetProfileCycles

                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDM_DBGSAVEMEMSNAPSHOT
                    invoke  EnableDebugWindows, FALSE
                    invoke  SaveMemorySnapshot, hWndDlg
                    invoke  EnableDebugWindows, TRUE
                    return  TRUE

            .elseif wParamLow == IDM_DBGLOADIF2ROM
                    invoke  EnableDebugWindows, FALSE
                    invoke  LoadIF2_ROM, hWndDlg
                    invoke  EnableDebugWindows, TRUE
                    RENDERFRAME

                    mov     ax, zPC
                    mov     Z80PC, ax       ; setup starting disassembly address

                    m2m     LastDebugFrameCounter, GlobalFramesCounter  ; reset for a loaded snapshot within the debugger
                    m2m     LastDebugCycleCounter, totaltstates
                    invoke  SetProfileCycles

                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDM_DBGLOADBINARYFILE
                    invoke  DialogBoxParam, GlobalhInst, IDD_LOADBINARY, hWndDlg, addr LoadBinaryDlgProc,  NULL
                    invoke  UpdateDebugger
                    return  TRUE

            .elseif wParamLow == IDM_DBGSAVEBINARYFILE
                    invoke  DialogBoxParam, GlobalhInst, IDD_SAVEBINARY, hWndDlg, addr SaveBinaryDlgProc,  NULL
                    return  TRUE


            .elseif wParamLow == IDM_PAUSE
                    invoke  SendMessage, hWnd, WM_COMMAND, IDM_PAUSE, NULL
                    invoke  EnableDumpControls, hWndDlg
                    return  TRUE

            .elseif wParamLow == IDM_CLOSEDEBUGGER
                    CLOSE_DEBUGGER
            .endif

        .endif
        return  TRUE

OnVScroll
        switch  lParam
                case    DissScrollBarhWnd
                        switch  $LowWord (wParam)
                                case    SB_PAGEUP
                                        invoke  SendMessage, DISLST_Handle, WM_KEYDOWN, VK_PGUP, NULL
                                case    SB_PAGEDOWN
                                        invoke  SendMessage, DISLST_Handle, WM_KEYDOWN, VK_PGDN, NULL
                                case    SB_LINEUP
                                        invoke  SendMessage, DISLST_Handle, WM_KEYDOWN, VK_UP,   NULL
                                case    SB_LINEDOWN
                                        invoke  SendMessage, DISLST_Handle, WM_KEYDOWN, VK_DOWN, NULL
                                case    SB_THUMBTRACK
                                        mov     cx, $HighWord (wParam)
                                        mov     Z80PC, cx
                                        invoke  Cursor_Up
                                        invoke  Cursor_Down
                                        invoke  UpdateDisassembly
                                case    SB_TOP
                                        mov     Z80PC, 0
                                        invoke  UpdateDisassembly
                                case    SB_BOTTOM
                                        mov     Z80PC, 0FFFFh
                                        invoke  UpdateDisassembly
                        endsw
              ; if an application processes this message, it should return zero
                return  0
        endsw

OnEnterMenuLoop
        ifc     MemorySnapshotValid eq TRUE then mov eax, MF_ENABLED or MF_BYCOMMAND else mov eax, MF_GRAYED or MF_BYCOMMAND
        invoke  EnableMenuItem, DebugMenuHandle, IDM_DBGLOADMEMSNAPSHOT, eax


OnClose
        invoke   DestroyDebugWindows

      ; restore the disassembly window's original font
        invoke  SendMessage, DISASSEMBLYhWnd, WM_SETFONT, DISASSEMBLYOldFont, TRUE

        invoke  SetWindowLong, DISLST_Handle, GWL_WNDPROC, OrigDISLSTWndProc
        invoke  SaveDialogPlacement

        mov     DebuggerActive, FALSE
        invoke  EndDialog, [hWndDlg], NULL
        return TRUE

OnDestroy
        ; destroy debugger control menus
        invoke  DestroyMenu, DissMenuHandle
        return  TRUE

OnDefault
        return FALSE

        DOMSG

Close_Debugger: invoke  PostMessage, hWndDlg, WM_CLOSE, 0, 0
                return  TRUE

DebuggerDlgProc endp

align 16
SetDisassemblyFontSize  proc    fontsize: BYTE

                        switch  fontsize
                                case    diss_large_font
                                        invoke  SendMessage, DISASSEMBLYhWnd, WM_SETFONT, gl_Courier_New_9, TRUE
                                        mov     MaxDisassemblyLines, 28

                                case    diss_small_font
                                        invoke  SendMessage, DISASSEMBLYhWnd, WM_SETFONT, gl_Courier_New_6, TRUE
                                        mov     MaxDisassemblyLines, 53
                        endsw
                        mov     MaxDumpAsHexDec, 8
                        mov     MaxDumpAsAscii, 16
                        ret

SetDisassemblyFontSize  endp

align 16
ToggleBreakpoint    proc    Address:WORD

                    pushad
                    ISBREAKPOINTDEFINED Address
                    .if     ZERO?
                            invoke  RemoveBreakpoint, Address
                    .else
                            invoke  AddBreakpoint, Address
                    .endif
                    popad
                    ret

ToggleBreakpoint    endp

align 16
ClearBreakpoints    proc    uses esi ecx

                    lea     esi, BreakPoints
                    mov     ecx, MAXBREAKPOINTS
                    mov     eax, -1
                @@: mov     [esi].TBREAKPOINT.PC, eax
                    add     esi, sizeof TBREAKPOINT
                    dec     ecx
                    jnz     @B

                    mov     BreakPointCnt, 0
                    mov     Check_Breakpoints, FALSE ; turn off debug frame for breakpoints

                    invoke  PopulateBrkListbox
                    ret

ClearBreakpoints    endp

align 16
AddBreakpoint       proc    uses    esi ecx,
                            Address:word

                    ; exit if a breakpoint exists at specified address
                    ISBREAKPOINTDEFINED Address
                    retcc   z

                    lea     esi, BreakPoints
                    mov     ecx, MAXBREAKPOINTS

@@:                 .if     dword ptr [esi].TBREAKPOINT.PC == -1
                            movzx   eax, Address
                            mov     [esi].TBREAKPOINT.PC, eax       ; breakpoint set
                            mov     [esi].TBREAKPOINT.Enabled, TRUE ; breakpoint enabled
                            inc     BreakPointCnt
                            mov     Check_Breakpoints, TRUE         ; runs debug frame

                            invoke  SortBreakpoints
                            invoke  PopulateBrkListbox
                            ret
                    .endif

                    add     esi, sizeof TBREAKPOINT
                    dec     ecx
                    jnz     @B

                    invoke  MessageBox, hWnd, SADD ("All breakpoints have been used"), addr DebuggerError, MB_OK or MB_ICONINFORMATION
                    ret

AddBreakpoint       endp

align 16
SortBreakpoints     proc    uses    esi edi ebx

                    lea     esi, BreakPoints
                    xor     ecx, ecx

                    .while  ecx != MAXBREAKPOINTS - 1
                            lea     edi, [esi+sizeof TBREAKPOINT]
                            lea     edx, [ecx+1]

                            .while  edx != MAXBREAKPOINTS
                                    mov     eax, [esi].TBREAKPOINT.PC
                                    mov     ebx, [edi].TBREAKPOINT.PC

                                    .if     ebx < eax
                                            pushad
                                            invoke  SwapMemory, esi, edi, sizeof TBREAKPOINT
                                            popad
                                    .endif

                                    add     edi, sizeof TBREAKPOINT
                                    inc     edx
                            .endw

                            add     esi, sizeof TBREAKPOINT
                            inc     ecx
                    .endw

                    ret

SortBreakpoints     endp

align 16
RemoveBreakpoint    proc    uses esi ecx,
                            Address:WORD

                    lea     esi, BreakPoints
                    mov     ecx, MAXBREAKPOINTS
                    movzx   eax, Address

@@:                 .if     dword ptr [esi].TBREAKPOINT.PC == eax
                            mov     dword ptr [esi].TBREAKPOINT.PC, -1  ; reset breakpoint

                            dec     BreakPointCnt
                            .if     BreakPointCnt == 0
                                    mov     Check_Breakpoints, FALSE    ; turn off debug frame for breakpoints
                            .endif

                            invoke  SortBreakpoints
                            invoke  PopulateBrkListbox
                            ret
                    .endif

                    add     esi, sizeof TBREAKPOINT
                    dec     ecx
                    jnz     @B

                    ret

RemoveBreakpoint    endp

align 16
GetDialogPlacement  proc    uses    esi edi,

                    mov     DummyMem, 0
                    strcat  addr DummyMem, SADD("DebuggerWin"), SADD ("_X")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     esi, eax

                    mov     DummyMem, 0
                    strcat  addr DummyMem, SADD("DebuggerWin"), SADD ("_Y")
                    invoke  ReadProfileInt,  addr DummyMem, -1
                    mov     edi, eax

                    .if     (esi != -1) && (edi != -1)
                            invoke  SetWindowPosition, Debugger_hWnd, esi, edi
                    .endif
                    ret

GetDialogPlacement  endp

align 16
SaveDialogPlacement proc

                    invoke  GetWindowRect, Debugger_hWnd, addr DebugWindowRect

                    mov     DummyMem, 0
                    strcat  addr DummyMem, SADD ("DebuggerWin"), SADD ("_X")
                    invoke  WriteProfileInt, addr DummyMem, DebugWindowRect.left

                    mov     DummyMem, 0
                    strcat  addr DummyMem, SADD ("DebuggerWin"), SADD ("_Y")
                    invoke  WriteProfileInt, addr DummyMem, DebugWindowRect.top
                    ret

SaveDialogPlacement endp

align 16
UpdateDisassembly   proc    uses ebx esi edi

                    local   lpPCTable:      DWORD

                    local   eolstringptr:   DWORD

                    local   textstring:     TEXTSTRING,
                            pTEXTSTRING:    DWORD

            mov     DisassemblyUpdated, TRUE

            mov     lpPCTable, offset PCTable
            mov     lpFwdRefTextOffsetTable, offset FwdRefTextOffsetTable

            memclr  addr FwdRefTextOffsetTable, sizeof FwdRefTextOffsetTable

            ; update scrollbar position
            movzx   ecx, Z80PC
            mov     DissScrollBarInfo.SCROLLINFO.nPos, ecx
            invoke  SetScrollInfo, DissScrollBarhWnd, SB_CTL, addr DissScrollBarInfo, TRUE


            ; clear the RawText entries
            invoke SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, WM_SETREDRAW, FALSE, 0
            invoke SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_RESETCONTENT, 0, 0

            mov     Highlight8bit,  TRUE
            mov     Highlight16bit, TRUE

            mov     ax, Z80PC
            mov     oldZ80PC, ax

            .if     ViewAsDump == TRUE
                    SETLOOP ZeroExt (MaxDisassemblyLines)
                            ; write the PC address for this line into the PCTable array
                            mov     esi, [lpPCTable]
                            mov     ax, Z80PC
                            mov     [esi], ax
                            add     esi, 2
                            mov     [lpPCTable], esi

                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            invoke  PrtBase16, pTEXTSTRING, Z80PC, 0
                            .if     ShowHex == FALSE
                                    mov     al, " "
                                    .if     Z80PC < 10000
                                            ADDCHAR pTEXTSTRING, al
                                    .endif
                                    .if     Z80PC < 1000
                                            ADDCHAR pTEXTSTRING, al
                                    .endif
                                    .if     Z80PC < 100
                                            ADDCHAR pTEXTSTRING, al
                                    .endif
                                    .if     Z80PC < 10
                                            ADDCHAR pTEXTSTRING, al
                                    .endif
                            .endif
                            ADDCHAR pTEXTSTRING, " "

                            .if     ShowOpsAsAscii == TRUE
                                    push    ZeroExt (MaxDumpAsAscii)
                                    @@:     call    GetNextByte
                                            .if     (al < 32) || (al > 127)
                                                    mov     al, "."
                                            .endif
                                            ADDCHAR pTEXTSTRING, al
                                            ADDCHAR pTEXTSTRING, " "
                                    dec     dword ptr [esp]
                                    jnz     @B
                                    add     esp, 4
                            .else
                                    push    ZeroExt (MaxDumpAsHexDec)
                                    @@:     .if     ShowHex == TRUE
                                                    call    GetNextByte
                                                    ADDTEXTHEX  pTEXTSTRING, al
                                                    ADDCHAR     pTEXTSTRING, " ", " "
                                            .else
                                                    call    GetNextByte
                                                    mov     bl, al
                                                    .if     bl < 100
                                                            ADDCHAR pTEXTSTRING, "0"
                                                    .endif
                                                    .if     bl < 10
                                                            ADDCHAR pTEXTSTRING, "0"
                                                    .endif
                                                    mov     al, bl
                                                    ADDTEXTDEC  pTEXTSTRING, al
                                                    ADDCHAR     pTEXTSTRING, " "
                                            .endif
                                    dec     dword ptr [esp]
                                    jnz     @B
                                    add     esp, 4
                            .endif
                            invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_ADDSTRING, 0, addr textstring
                    ENDLOOP
                    jmp     UpdateEnd
            .endif

            mov WantBlankLine, FALSE
            xor cl,cl

            .while cl < MaxDisassemblyLines
                push    cx

                ; write the PC address for this line into the PCTable array
                mov     esi, [lpPCTable]
                mov     ax, Z80PC
                mov     [esi], ax
                add     esi, 2
                mov     [lpPCTable], esi

                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING   ; initialise a new string
                .if     WantBlankLine == TRUE
                        mov     WantBlankLine, FALSE

                .else
                    push    cx

                    ; insert the PC address + additional spaces if decimal
                    invoke  PrtBase16, pTEXTSTRING, Z80PC, 0
                    .if     ShowHex == FALSE
                            mov     al, " "
                            .if     Z80PC < 10000
                                    ADDCHAR pTEXTSTRING, al
                            .endif
                            .if     Z80PC < 1000
                                    ADDCHAR pTEXTSTRING, al
                            .endif
                            .if     Z80PC < 100
                                    ADDCHAR pTEXTSTRING, al
                            .endif
                            .if     Z80PC < 10
                                    ADDCHAR pTEXTSTRING, al
                            .endif
                    .endif

                    ; space for hex/ascii bytes
                    ADDSPACES   pTEXTSTRING, 16

                    ; insert the Z80 disassembly
                    invoke  DisassembleLine, pTEXTSTRING

                    push    $fnc (GETTEXTPTR, pTEXTSTRING)
                    pop     eolstringptr    ; make a copy of the current end-of-string pointer

                    invoke  SETTEXTPTR, pTEXTSTRING, addr textstring+7  ; placement for hex/ascii bytes within the string

                    ; start loop to add hex/ascii bytes
                    mov     ax, Z80PC
                    push    ax
                    mov     ax, initZ80PC
                    mov     Z80PC, ax

                    mov     cl, InsLength
                    mov     InsLength, 0    ; reset InsLength for this loop

ShowOpHex:          push    ecx
                    call    GetNextByte     ; this will increment InsLength

                    .if     ShowOpsAsAscii == TRUE
                            .if     (al < 32) || (al > 127)
                                    mov     al, "."
                            .endif
                            ADDCHAR     pTEXTSTRING, al
                    .else
                            ADDTEXTHEX  pTEXTSTRING, al
                            ADDCHAR     pTEXTSTRING, " "    ; write a separator for hex bytes
                    .endif

                    pop     ecx
                    dec     cl
                    jnz     ShowOpHex       ; InsLength will be same value when loop exits

                    ; end loop to add hex/ascii bytes

                    pop     ax
                    mov     Z80PC,ax

                    ; now we need to write over the null byte that the text functions append to end of string
                    mov     edi, $fnc (GETTEXTPTR, pTEXTSTRING)
                    mov     byte ptr [edi], " "


                    ; insert a "*" if this is a breakpoint address, and highlight this line
                    ISBREAKPOINT    initZ80PC   ; must use the start address of this line
                    .if     ZERO?
                            mov     edi, eolstringptr
                            add     edi, 2
                            mov     eolstringptr, edi

                            mov     byte ptr [textstring+20], "*"

                            lea     ecx, textstring
                            .while  edi != ecx
                                    mov     al, [edi-2]
                                    mov     [edi], al
                                    dec     edi
                            .endw

                            mov     byte ptr [textstring+0], RTCTL_PAPER
                            mov     byte ptr [textstring+1], RTCOL_GREEN
                    .endif

                    pop     cx
                    .if     cl == 0
                            mov     ax, FwdAddr
                            mov     ForwardAddr, ax
                            mov     al, FwdAddrValid
                            mov     ForwardAddrValid, al
                            mov     al, InsLength
                            mov     DissLineLength, al   ; required for disassembly navigation
                    .endif
                .endif

                ; add new string to Disassembly ListBox
                invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_ADDSTRING, 0, addr textstring

                add     lpFwdRefTextOffsetTable, 4

                pop     cx
                inc     cl
            .endw       ; repeat for all disassembly lines

            ; update forward reference button state
            movzx   eax, ForwardAddrValid   ; eax = TRUE or FALSE
            invoke  EnableControl, Debugger_hWnd, IDC_FOLLOWREF, eax


UpdateEnd:
            ; now clear current selection and update the disassembly listbox
            invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_SETCURSEL, 0, 0
            invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, WM_SETREDRAW, TRUE, 0

            invoke  InvalidateRect, $fnc (GetDlgItem, Debugger_hWnd, IDC_DISASSEMBLYLST), NULL, TRUE

            mov     ax, oldZ80PC
            mov     Z80PC, ax

            mov     lpFwdRefTextOffsetTable, 0

            mov     Highlight8bit,  FALSE
            mov     Highlight16bit, FALSE
            ret

UpdateDisassembly   endp

align 16
EnableControl   proc    hWin    :DWORD,
                        CtrlID  :DWORD,
                        State   :DWORD

                .if     $fnc (GetDlgItem, hWin, CtrlID) != NULL
                        invoke  EnableWindow, eax, State
                .endif

                ret

EnableControl   endp

; adds line disassembly to sting in an instance of @@textstringptr

align 16
DisassembleLine proc    uses    ebx esi edi,
                        lpText: PTR @@textstringptr

                local   Opcode: BYTE

            mov     GotOffset, FALSE
            mov     InsLength, 0
            mov     FwdAddrValid, FALSE
            mov     FwdAddrRST, FALSE

            mov     ax, Z80PC
            mov     initZ80PC, ax

            call    GetNextByte
            mov     Opcode, al

            .if     al == 0DDh
                    call    GetNextByte
                    mov     Opcode, al
                    .if     (al == 0DDh) || (al == 0FDh) || (al == 0EDh)
                            call    MoveBackByte
                            lea     esi, DDOpPtrs
                            jmp     ShowOp
                    .endif
                    .if     al == 0CBh
                            call    GetNextByte
                            mov     DissOffset, al
                            mov     GotOffset, TRUE
                            call    GetNextByte
                            lea     esi, DDCBOpPtrs
                            jmp     ShowOp
                    .endif
                    lea     esi, DDOpPtrs
                    jmp     ShowOp
            .endif

            .if     al == 0FDh
                    call    GetNextByte
                    mov     Opcode, al
                    .if     (al == 0DDh) || (al == 0FDh) || (al == 0EDh)
                            call    MoveBackByte
                            lea     esi, FDOpPtrs
                            jmp     ShowOp
                    .endif
                    .if     al == 0CBh
                            call    GetNextByte
                            mov     DissOffset, al
                            mov     GotOffset, TRUE
                            call    GetNextByte
                            lea     esi, FDCBOpPtrs
                            jmp     ShowOp
                    .endif
                    lea     esi, FDOpPtrs
                    jmp     ShowOp
            .endif

            .if     al == 0CBh
                    call    GetNextByte
                    lea     esi, CBOpPtrs
                    jmp     ShowOp
            .endif

            .if     al == 0EDh
                    call    GetNextByte
                    lea     esi, EDOpPtrs
                    jmp     ShowOp
            .endif

            lea     esi, OpPtrs

ShowOp:     and     eax, 255
            mov     esi, [esi+eax*4]

ShowOpLoop: mov     al, [esi]
            inc     esi
            or      al, al
            je      ShowOpDone

            push    esi
            .if     al == "q"
                    call    GetNextByte
                    invoke  OutBase8, lpText, al
                    jmp     ShowOpNext
            .endif

            .if     al == "w"
                    call    GetNextWord
                    mov     FwdAddr, ax
                    mov     FwdAddrValid, TRUE
                    invoke  OutBase16, lpText, ax, 0
                    jmp     ShowOpNext
            .endif

            .if     al == "e"
                    call    GetNextByte
                    cbw
                    mov     bx, Z80PC
                    add     ax, bx
                    mov     FwdAddr, ax
                    mov     FwdAddrValid, TRUE
                    invoke  OutBase16, lpText, ax, 0
                    jmp     ShowOpNext
            .endif

            .if     al == "r"
                    movzx   ax, Opcode
                    sub     al, 0C7h
                    mov     FwdAddr, ax
                    mov     FwdAddrValid, TRUE
                    mov     FwdAddrRST, TRUE    ; indicate forward address is a RST opcode
                    invoke  OutBase16, lpText, ax, 0
                    jmp     ShowOpNext
            .endif

            .if     al == "j"
                    call    GetNextWord
                    mov     FwdAddr, ax
                    mov     FwdAddrValid, TRUE
                    invoke  OutBase16, lpText, ax, 0
                    jmp     ShowOpNext
            .endif

            .if     al == "+"
                    .if     GotOffset == FALSE
                            call    GetNextByte
                            mov     DissOffset, al
                    .endif
                    mov     dl, "+"
                    mov     al, DissOffset
                    .if     al > 127
                            mov     dl, "-"
                            neg     al
                    .endif
                    push    ax
                    ADDCHAR lpText, dl
                    pop     ax
                    invoke  OutBase8, lpText, al
                    jmp     ShowOpNext
            .endif

            .if     al == "|"
                    mov     WantBlankLine, TRUE
                    jmp     ShowOpNext
            .endif

            ADDCHAR lpText, al

ShowOpNext: pop     esi
            jmp     ShowOpLoop

ShowOpDone: ret

DisassembleLine     endp

align 16
GetNextByte:                mov     bx, Z80PC
                            call    MemGetByte
                            inc     Z80PC
                            inc     InsLength
                            ret

align 16
GetNextWord:                mov     bx, Z80PC
                            call    MemGetWord
                            add     Z80PC, 2
                            add     InsLength, 2
                            ret

align 16
MoveBackByte:               dec     Z80PC
                            dec     InsLength
                            ret

.data?
Highlight8bit               db      ?
Highlight16bit              db      ?

.code
align 16
OutBase8                    proc    lptextstring:   DWORD,
                                    Value:          BYTE

                            pushad

                            .if     Highlight8bit
                                    ADDCHAR lptextstring, RTCTL_INK, RTCOL_BLUE
                            .endif

                            mov     al, Value

                            .if     ShowHex
                                    ADDCHAR      lptextstring, "#"
                                    ADDTEXTHEX   lptextstring, al
                            .else
                                    ADDTEXTDEC   lptextstring, al
                            .endif

                            .if     Highlight8bit
                                    ADDCHAR  lptextstring, RTCTL_INK, RTCOL_SYSCOLOR
                            .endif

                            popad
                            ret

OutBase8                    endp

align 16
OutBase16                   proc    lptextstring:   DWORD,
                                    Value:          WORD,
                                    Flags:          BYTE

                            local   showhash:       BYTE

                            pushad

                            .if     Highlight16bit
                                    mov     ecx, lpFwdRefTextOffsetTable
                                    .if     ecx != 0
                                            .if     FwdAddrValid
                                                    invoke  GETTEXTPTR, lptextstring
                                                    sub     eax, lptextstring   ; - string start address
                                                    mov     [ecx], al
                                                    add     al, 4
                                                    mov     [ecx+1], al
                                                    mov     ax, FwdAddr
                                                    mov     [ecx+2], ax
                                            .endif
                                    .endif
                                    ADDCHAR  lptextstring, RTCTL_INK, RTCOL_RED
                            .endif

                            mov     showhash, TRUE

                            movzx   eax, Value
                            .if     DissLabelLookup && (FwdAddrRST == FALSE)
                                    .if     byte ptr [LabelTable+eax] == 1
                                            ADDCHAR  lptextstring, "L"
                                            mov     showhash, FALSE
                                    .endif
                            .endif

                            .if     ShowHex
                                    ifc     showhash == TRUE then ADDCHAR  lptextstring, "#"
                                    ADDTEXTHEX       lptextstring, ax
                            .else
                                    ADDTEXTDECIMAL   lptextstring, ax, Flags
                            .endif

                            .if     Highlight16bit
                                    ADDCHAR  lptextstring, RTCTL_INK, RTCOL_SYSCOLOR
                            .endif

                            popad
                            ret

OutBase16                   endp

.data
remote_step                 db      FALSE   ; only TRUE when in Remote_Single_Step (z80 core can take certain actions based on interacting with Remote app)

.code
align 16
Remote_Single_Step          proc    uses ebx esi edi

                            mov     remote_step, TRUE

                            mov     Z80TState, 0        ; reset in case interrupt due
                            mov     eax, totaltstates

                            .if     eax < MACHINE.InterruptCycles
                                    .if     (currentMachine.iff1 == TRUE) && (EI_Last == FALSE)
                                            call    z80_Interrupt   ; clears HALT flag, sets Z80TState to interrupt timing
                                            je      @F      ; jump forward if INT accepted
                                    .endif
                            .endif

                            call    Exec_Opcode
@@:                         call    Exec_Extras

                            mov     ebx, MACHINE.FrameCycles
                            .if     totaltstates >= ebx
                                    sub     totaltstates, ebx
                            .endif

                            mov     ax, zPC
                            mov     Z80PC, ax

                            mov     StackPtr, offset StackRoot

                            GET_R   al
                            mov     z80registers.r, al

                            mov     remote_step, FALSE
                            ret

Remote_Single_Step          endp

;Remote_Single_Step          proc    uses ebx esi edi
;
;                            local   tstates:BYTE
;
;                            mov     remote_step, TRUE
;
;                            push    [totaltstates]
;                            RUNZ80INSTR                 ; run current Z80 opcode
;                            pop     eax
;                            mov     ebx, totaltstates
;                            sub     ebx, eax
;                            mov     tstates, bl
;
;                            mov     ebx, MACHINE.FrameCycles
;                            .if     totaltstates >= ebx
;                                    sub     totaltstates, ebx
;                            .endif
;
;                            mov     Z80TState, 0        ; reset in case interrupt due
;
;                            mov     eax, totaltstates
;                            .if     eax < MACHINE.InterruptCycles
;                                    .if     (currentMachine.iff1 == TRUE) && (EI_Last == FALSE)
;                                            call    z80_Interrupt   ; clears HALT flag, sets Z80TState to interrupt timing
;                                    .endif
;                            .endif
;
;                            mov     al, tstates
;                            add     Z80TState, al
;
;                            ifc     TapePlaying then call PlayTape
;                            ifc     SaveTapeType ne Type_NONE then call WriteTapePulse
;
;                            mov     ax, zPC
;                            mov     Z80PC, ax
;
;                            mov     StackPtr, offset StackRoot
;
;                            mov     al, z80registers.r
;                            and     al, 127
;                            or      al, Reg_R_msb
;                            mov     z80registers.r, al
;
;                            mov     remote_step, FALSE
;                            ret
;
;Remote_Single_Step          endp

align 16
Single_Step                 proc    uses ebx esi edi

                            mov     eax, totaltstates

                            .if     eax < MACHINE.InterruptCycles
                                    .if     (currentMachine.iff1 == TRUE) && (EI_Last == FALSE)
                                            call    z80_Interrupt   ; clears DoingHALT flag
                                            je      @F              ; jump forward if INT accepted
                                    .endif
                            .endif

                            push    [totaltstates]
                            mov     in_single_step, TRUE
                            RUNZ80INSTR                 ; run current Z80 opcode
                            mov     in_single_step, FALSE
                            pop     eax
                            mov     ebx, totaltstates
                            sub     ebx, eax
                            mov     Z80TState, bl

@@:                         ifc     TapePlaying then call PlayTape
                            ifc     SaveTapeType ne Type_NONE then call WriteTapePulse

                            mov     ebx, MACHINE.FrameCycles
                            .if     totaltstates >= ebx
                                    sub     totaltstates, ebx
                            .endif

                            mov     ax, zPC
                            mov     Z80PC, ax

                            mov     StackPtr, offset StackRoot

                            mov     al, z80registers.r
                            and     al, 127
                            or      al, Reg_R_msb
                            mov     z80registers.r, al
                            ret

Single_Step                 endp

align 16
SetProfileCycles    proc    uses    esi edi
                    mov     esi, GlobalFramesCounter
                    sub     esi, LastDebugFrameCounter
                    mov     edi, totaltstates
                    mov     edx, LastDebugCycleCounter

                    .if     edi < edx
                            dec     esi
                            mov     eax, MACHINE.FrameCycles
                            sub     eax, edx
                            add     eax, edi
                            mov     edi, eax
                    .else
                            sub     edi, edx
                    .endif

                    invoke  SetDlgItemInt, Debugger_hWnd, IDC_FRAMESCOUNT, esi, FALSE
                    invoke  SetDlgItemInt, Debugger_hWnd, IDC_CYCLECOUNT,  edi, FALSE

                    m2m     LastDebugFrameCounter, GlobalFramesCounter
                    m2m     LastDebugCycleCounter, totaltstates
                    ret
SetProfileCycles    endp

align 16
UpdateDebugger      proc

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    invoke  UpdateDisassembly
                    invoke  UpdateAllRegisters

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    invoke  PrtBase16,      pTEXTSTRING, PrevzPC, 0
                    invoke  SendDlgItemMessage, Debugger_hWnd, IDC_PREVPC, WM_SETTEXT, 0, addr textstring

                    GETMODELNAME    ecx
                    invoke  SendDlgItemMessage, Debugger_hWnd, IDC_HARDWARE, WM_SETTEXT, 0, ecx

                    .if     Check_TraceHook == FALSE
                            invoke  SendDlgItemMessage, Debugger_hWnd, IDC_MEMBREAKADDRSTC, WM_SETTEXT, 0, SADD ("N/A")
                    .else
                            .if     TraceHook == offset StopMemReadHook
                                    mov     bx, StopMemReadAddr
                            .elseif TraceHook == offset StopMemWriteHook
                                    mov     bx, StopMemWriteAddr
                            .elseif TraceHook == offset StopMemAccessHook
                                    mov     bx, StopMemAccessAddr
                            .endif
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            invoke  PrtBase16,      pTEXTSTRING, bx, 0
                            invoke  SendDlgItemMessage, Debugger_hWnd, IDC_MEMBREAKADDRSTC, WM_SETTEXT, 0, addr textstring
                    .endif

                    mov     al, ShowHex
                    push    eax
                    mov     ShowHex, FALSE

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                    mov     totaltstates, $fnc (Mod2Int, totaltstates, MACHINE.FrameCycles)

                    invoke  PrtBase32,      pTEXTSTRING, eax
                    ADDDIRECTTEXTSTRING     pTEXTSTRING, " / "
                    invoke  PrtBase32,      pTEXTSTRING, MACHINE.FrameCycles
                    invoke  SendDlgItemMessage, Debugger_hWnd, IDC_TStates, WM_SETTEXT, 0, ADDR textstring

                    pop     eax
                    mov     ShowHex, al

                    UPDATEWINDOW
                    ret
UpdateDebugger      endp

align 16
PrtBase8            proc    lptextstring:   DWORD,
                            Value:          BYTE

                    pushad
                    mov     al, Value
                    .if     ShowHex == TRUE
                            ADDCHAR     lptextstring, "#"
                            ADDTEXTHEX  lptextstring, al
                    .else
                            ADDTEXTDEC  lptextstring, al
                    .endif
                    popad
                    ret
PrtBase8            endp

align 16
PrtBase16           proc    lptextstring: DWORD,
                            Value:        WORD,
                            Flags:        BYTE

                    pushad
                    mov     edi, lptextstring
                    movzx   eax, Value
                    .if     ShowHex == TRUE
                            ADDCHAR     lptextstring, "#"
                            ADDTEXTHEX  lptextstring, ax
                    .else
                            ADDTEXTDECIMAL  lptextstring, ax, Flags
                    .endif
                    popad
                    ret
PrtBase16           endp

align 16
PrtBase32           proc    lptextstring: DWORD,
                            Value:        DWORD

                    pushad
                    mov     eax, Value
                    .if     ShowHex == TRUE
                            ADDCHAR     lptextstring, "#"
                            ADDTEXTHEX  lptextstring, eax
                    .else
                            ADDTEXTDEC  lptextstring, eax
                    .endif
                    popad
                    ret
PrtBase32           endp

align 16
PushCursorStack     proc
                    push    esi
                    mov     esi, [StackPtr]
                    mov     eax, [esi]
                    cmp     eax, 0FFFFFFFFh
                    je      @F
                    xor     eax, eax
                    mov     ax, Z80PC
                    mov     [esi], eax
                    add     esi, 4
                    mov     [StackPtr], esi
@@:                 pop     esi
                    ret
PushCursorStack     endp

align 16
PopCursorStack      proc
                    push    esi
                    mov     esi, [StackPtr]
                    sub     esi, 4
                    mov     eax, [esi]
                    cmp     eax, 0FFFFFFFFh
                    je      @F
                    mov     [StackPtr], esi
@@:                 pop     esi
                    ret
PopCursorStack      endp

align 16
InitCursorStack     proc
                    mov     eax, 0FFFFFFFFh
                    mov     [StackTopLim], eax
                    mov     [StackBotLim], eax
                    mov     [StackPtr], OFFSET StackRoot
                    ret
InitCursorStack     endp


.data?
ti                  TOOLINFO    <>
uid                 DWORD       ?
hwndDissTT          DWORD       ?
ttTextPtr           DWORD       ?
TTcreating          BYTE        ?

align 4
ttTextString        TEXTSTRING  <>
pttTextString       DWORD       ?

.data
ttNoText            db      0

.code
align 16
SaveLoadFwdRefs     proc    saveload:   BYTE

                    .if     saveload == 0
                            ; saving state
                            mov     eax, lpFwdRefTextOffsetTable
                            mov     savelpFwdRefTextOffsetTable, eax
                            memcpy  addr FwdRefTextOffsetTable, addr saveFwdRefTextOffsetTable, sizeof FwdRefTextOffsetTable
                    .else
                            ; restoring state
                            mov     eax, savelpFwdRefTextOffsetTable
                            mov     lpFwdRefTextOffsetTable, eax
                            memcpy  addr saveFwdRefTextOffsetTable, addr FwdRefTextOffsetTable, sizeof FwdRefTextOffsetTable
                    .endif
                    ret

SaveLoadFwdRefs     endp

align 16
CreateDISTooltip    proc    hWin:   HWND

                    mov     TTcreating, TRUE
                    mov     ttTextPtr, offset ttNoText

                    invoke  CreateWindowEx, WS_EX_TOPMOST, SADD("TOOLTIPS_CLASS32"), NULL,
                                            WS_POPUP or TTS_NOPREFIX or TTS_ALWAYSTIP,
                                            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
                                            hWin, NULL,
                                            GlobalhInst, NULL
                    mov     hwndDissTT, eax

                    .if     hwndDissTT != 0
                            mov     uid, 0
                            invoke  SetWindowPos, hwndDissTT, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE

                            SETNEWWINDOWFONT      hwndDissTT, Courier_New_9, ttFont, ttOldFont

                            mov     ti.cbSize,      sizeof (TOOLINFO)
                            mov     ti.uFlags,      TTF_SUBCLASS
                            m2m     ti.hWnd,        hWin
                            m2m     ti.hInst,       GlobalhInst
                            m2m     ti.uId,         uid
                            mov     ti.lpszText,    LPSTR_TEXTCALLBACK

                            ; toolTip control will originally have a NULL client area
                            mov     ti.rect.left,   0
                            mov     ti.rect.top,    0
                            mov     ti.rect.right,  0
                            mov     ti.rect.bottom, 0

                            invoke  SendMessage, hwndDissTT, TTM_ADDTOOL, 0, addr ti
                            invoke  SendMessage, hwndDissTT, TTM_SETDELAYTIME, TTDT_AUTOPOP, 1000*30
                    .endif

                    mov     TTcreating, FALSE
                    ret
CreateDISTooltip    endp

align 16
DestroyDISTooltip   proc
                    .if     hwndDissTT != 0
                            SETOLDWINDOWFONT    hwndDissTT, ttFont, ttOldFont
                            invoke  DestroyWindow, hwndDissTT
                            mov     hwndDissTT, 0
                    .endif
                    ret
DestroyDISTooltip   endp

align 16
BuildDissTooltipText    proc    uses    ebx

                        local   _z80pc: WORD

                        mov     ax, Z80PC
                        mov     _z80pc, ax

                        invoke  SaveLoadFwdRefs, 0  ; save fwdrefs table for new disassembly

                        invoke  INITTEXTSTRING, addr ttTextString, addr pttTextString
                        SETLOOP 10
                                .if     dword ptr [esp] == 10
                                        ADDDIRECTTEXTSTRING pttTextString, "Code:  "
                                .else
                                        ADDDIRECTTEXTSTRING pttTextString, "       "
                                .endif
                                invoke  DisassembleLine, pttTextString
                                ADDCHAR pttTextString, 13, 10
                        ENDLOOP
                        ADDCHAR pttTextString, 13, 10

                        mov     bx, _z80pc
                        SETLOOP 4
                                .if     dword ptr [esp] == 4
                                        ADDDIRECTTEXTSTRING pttTextString, "HEX:   "
                                .else
                                        ADDDIRECTTEXTSTRING pttTextString, "       "
                                .endif
                                SETLOOP 8
                                        call    MemGetByte
                                        ADDTEXTHEX  pttTextString, al
                                        ADDCHAR     pttTextString, " "
                                        inc     bx
                                ENDLOOP
                                ADDCHAR pttTextString, 13, 10
                        ENDLOOP
                        ADDCHAR pttTextString, 13, 10

                        mov     bx, _z80pc
                        SETLOOP 2
                                .if     dword ptr [esp] == 2
                                        ADDDIRECTTEXTSTRING pttTextString, "ASCII: "
                                .else
                                        ADDDIRECTTEXTSTRING pttTextString, "       "
                                .endif
                                SETLOOP 23
                                        call    MemGetByte
                                        .if     (al < 32) || (al > 127)
                                                mov     al, "."
                                        .endif
                                        ADDCHAR pttTextString, al
                                        inc     bx
                                ENDLOOP
                                ADDCHAR pttTextString, 13, 10
                        ENDLOOP

                        invoke  SaveLoadFwdRefs, 1  ; reload fwdrefs table for new disassembly

                        mov     ttTextPtr, offset ttTextString

                        ret
BuildDissTooltipText    endp

align 16
DISLST_SubclassProc proc    uses ebx esi edi,
                    hWin:   DWORD,
                    uMsg:   DWORD,
                    wParam: DWORD,
                    lParam: DWORD

                    local   _oldZ80PC:      WORD,
                            _mouseX:        BYTE,
                            _mouseY:        BYTE

                    local   _fontwidth:     DWORD,
                            _fontheight:    DWORD

                    .if     (hwndDissTT == 0) && (TTcreating == FALSE)
                            invoke  CreateDISTooltip, hWin
                    .endif

                    Switch uMsg
                            case    WM_NOTIFY
                                    assume  ebx: ptr NMTTDISPINFO
                                    mov     ebx, lParam
                                    .if     [ebx].hdr.code == TTN_GETDISPINFO
                                            invoke  SendMessage, [ebx].hdr.hwndFrom, TTM_SETMAXTIPWIDTH, 0, 300
                                            m2m     [ebx].lpszText, ttTextPtr
                                            return  0
                                    .endif
                                    assume  ebx: nothing

                            case    WM_LBUTTONDOWN
                                    invoke  GetFocus
                                    ifc     eax ne hWin then invoke SetFocus, hWin

                                    invoke  SendMessage, hWin, RT_GETFONTWIDTH, 0, 0
                                    mov     cx, ax
                                    mov     ax, $LowWord (lParam)
                                    xor     dx, dx
                                    div     cx
                                    mov     _mouseX, al

                                    mov     ax, Z80PC
                                    mov     _oldZ80PC, ax
                                    invoke  CallWindowProc, OrigDISLSTWndProc, hWin, uMsg, wParam, lParam

                                    invoke  SendMessage, hWin, RT_GETCURSEL, 0, 0
                                    movzx   ebx, MaxDisassemblyLines
                                    .if     eax < ebx
                                            lea     ecx, [FwdRefTextOffsetTable+eax*4]
                                            mov     ax, [ecx]
                                            .if     (_mouseX >= al) && (_mouseX <= ah)
                                                    mov     ax, _oldZ80PC
                                                    mov     Z80PC, ax
                                                    invoke  SetNewZ80PC, word ptr [ecx+2]
                                            .endif
                                    .endif
                                    return  0

                            case    WM_RBUTTONDOWN
                                    invoke  SendMessage, hWin, RT_GETFONTHEIGHT, 0, 0
                                    mov     cx, ax
                                    mov     ax, $HighWord (lParam)
                                    xor     dx, dx
                                    div     cx
                                    mov     _mouseY, al
                                    invoke  SetSelectedLine, ZeroExt (_mouseY)
                                    ; now fall through to handle default behaviour; we may have a menu attached

                            case    WM_MOUSEMOVE
                                    invoke  GetFocus
                                    ifc     eax ne hWin then invoke SetFocus, hWin

                                    ; the window class cursor will be restored on each mouse move
                                    ; so we only need to explicitly set it here if in a highlighted forward reference zone
                                    invoke  SendMessage, hWin, RT_GETFONTWIDTH, 0, 0
                                    mov     _fontwidth, eax
                                    mov     cx, ax
                                    mov     ax, $LowWord (lParam)
                                    xor     dx, dx
                                    div     cx
                                    mov     _mouseX, al

                                    invoke  SendMessage, hWin, RT_GETFONTHEIGHT, 0, 0
                                    mov     _fontheight, eax
                                    mov     cx, ax
                                    mov     ax, $HighWord (lParam)
                                    xor     dx, dx
                                    div     cx
                                    mov     _mouseY, al

                                    movzx   eax, _mouseY
                                    movzx   ebx, MaxDisassemblyLines
                                    .if     eax < ebx
                                            lea     ecx, [FwdRefTextOffsetTable+eax*4]
                                            mov     ax, [ecx]
                                            .if     (_mouseX >= al) && (_mouseX <= ah)
                                                    invoke  SetCursor, $fnc (LoadCursor, NULL, IDC_HAND)

                                                    mov     ti.rect.left,   @EVAL (_mouseX * _fontwidth)
                                                    mov     ti.rect.right,  @EVAL (_fontwidth * 5 + ti.rect.left)
                                                    mov     ti.rect.top,    @EVAL (_mouseY * _fontheight)
                                                    mov     ti.rect.bottom, @EVAL (_fontheight + ti.rect.top)

                                                    mov     ax, Z80PC
                                                    mov     _oldZ80PC, ax

                                                    movzx   eax, _mouseY
                                                    lea     ecx, [FwdRefTextOffsetTable+eax*4]
                                                    mov     ax, [ecx+2]
                                                    mov     Z80PC, ax

                                                    invoke  BuildDissTooltipText

                                                    mov     ax, _oldZ80PC
                                                    mov     Z80PC, ax
                                            .else
                                                    xor     eax, eax
                                                    mov     ti.rect.left,   eax
                                                    mov     ti.rect.top,    eax
                                                    mov     ti.rect.right,  eax
                                                    mov     ti.rect.bottom, eax
                                                    mov     ttTextPtr, offset ttNoText
                                            .endif
                                            invoke  SendMessage, hwndDissTT, TTM_NEWTOOLRECT, 0, addr ti
                                    .endif
                                    return  0

                            case    WM_MOUSEWHEEL
                                    mov     cx, $HighWord (wParam)
                                    test    cx, cx
                                    lea     esi, Cursor_Up
                                    .if     SIGN?
                                            neg     cx
                                            lea     esi, Cursor_Down
                                    .endif

                                    .while  cx >= WHEEL_DELTA
                                            push    ecx
                                            call    esi
                                            pop     ecx
                                            sub     cx, WHEEL_DELTA
                                    .endw
                                    invoke  UpdateDisassembly
                                    return  0

                            case    WM_KEYDOWN
                                    switch  wParam
                                            case    VK_SHIFT
                                                    mov     DebugSHIFTKeyDown, TRUE
                                                    return  0

                                            case    VK_CONTROL
                                                    mov     DebugCTRLKeyDown, TRUE
                                                    return  0

                                            case    VK_DOWN
                                                    invoke  Cursor_Down
                                                    invoke  UpdateDisassembly
                                                    return  0

                                            case    VK_UP
                                                    invoke  Cursor_Up
                                                    invoke  UpdateDisassembly
                                                    return  0

                                            case    VK_PGUP
                                                    .if     DebugCTRLKeyDown == TRUE
                                                            sub     Z80PC, 0400h
                                                    .else
                                                            movzx   eax, MaxDisassemblyLines
                                                            sub     eax, 5
                                                            SETLOOP eax
                                                                    invoke  Cursor_Up
                                                            ENDLOOP
                                                    .endif
                                                    invoke  UpdateDisassembly
                                                    return  0

                                            case    VK_PGDN
                                                    .if     DebugCTRLKeyDown == TRUE
                                                            add     Z80PC, 0400h
                                                    .else
                                                            movzx   eax, MaxDisassemblyLines
                                                            sub     eax, 5
                                                            SETLOOP eax
                                                                    invoke  Cursor_Down
                                                            ENDLOOP
                                                    .endif
                                                    invoke  UpdateDisassembly
                                                    return  0

                                            case    VK_LEFT
                                                    invoke  RetraceReference
                                                    return  0

                                            case    VK_RIGHT
                                                    invoke  FollowReference
                                                    return  0
                                    endsw

                            case    WM_KEYUP
                                    switch  wParam
                                            case    VK_SHIFT
                                                    mov     DebugSHIFTKeyDown, FALSE
                                                    return  0

                                            case    VK_CONTROL
                                                    mov     DebugCTRLKeyDown, FALSE
                                                    return  0
                                    endsw
                    endsw

DISLST_Default:     return  $fnc (CallWindowProc, OrigDISLSTWndProc, hWin, uMsg, wParam, lParam)

DISLST_SubclassProc endp

align 16
SetNewZ80PC         proc    newz80pc:   WORD

                    mov     ax, newz80pc
                    .if     ax != Z80PC
                            invoke  PushCursorStack
                            mov     ax, newz80pc
                            mov     Z80PC, ax

                            ; enable the back reference button
                            invoke  EnableControl, Debugger_hWnd, IDC_BACKREF, TRUE
                            invoke  EnableMenuItem, DissMenuHandle, IDM_DISS_BACK, MF_ENABLED or MF_BYCOMMAND
        
                            invoke  UpdateDisassembly
                    .endif
                    ret

SetNewZ80PC         endp

align 16
FollowReference     proc

                    .if     ViewAsDump == TRUE
                            inc     Z80PC
                            invoke  UpdateDisassembly
                            ret
                    .endif

                    .if     ForwardAddrValid == TRUE
                            invoke  SetNewZ80PC, ForwardAddr
                    .endif
                    ret

FollowReference     endp

align 16
RetraceReference    proc

                    .if     ViewAsDump == TRUE
                            dec     Z80PC
                            invoke  UpdateDisassembly
                            ret
                    .endif

                    invoke  PopCursorStack
                    .if     eax != 0FFFFFFFFh
                            mov     Z80PC, ax
                            invoke  UpdateDisassembly
                    .endif

                    .if     [StackPtr] == OFFSET StackRoot
                            ; disable the back reference button if retrace stack is empty
                            invoke  EnableControl, Debugger_hWnd, IDC_BACKREF, FALSE
                            invoke  EnableMenuItem, DissMenuHandle, IDM_DISS_BACK, MF_GRAYED or MF_BYCOMMAND
                    .endif

                    ret

RetraceReference    endp

align 16
Cursor_Up           proc    uses esi edi ebx

                    local   startZ80PC: WORD,
                            currZ80PC:  WORD,
                            entryZ80PC: WORD

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     ViewAsDump == TRUE
                            .if     ShowOpsAsAscii == TRUE
                                    movzx   ax, MaxDumpAsAscii
                                    sub     Z80PC, ax
                            .else
                                    movzx   ax, MaxDumpAsHexDec
                                    sub     Z80PC, ax
                            .endif
                            ret
                    .endif


                    mov     ax, Z80PC
                    mov     entryZ80PC, ax  ; value on entry

                    sub     ax, 20          ; initially scan from (Z80PC - 20)
                    mov     startZ80PC, ax  ; we scan forwards from here in the inner loop

                    mov     ebx, 19         ; start with forwards scan of 19 bytes
                    .while  ebx > 0

                            mov     ax, startZ80PC
                            mov     Z80PC, ax

                            lea     esi, [ebx-1]
                            .while  esi > 0
                                    mov     ax, Z80PC
                                    mov     currZ80PC, ax

                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING   ; required before calling DisassembleLine
                                    invoke  DisassembleLine, pTEXTSTRING

                                    mov     ax, Z80PC
                                    cmp     ax, entryZ80PC
                                    mov     ax, currZ80PC
                                    je      FPLine_Fnd  ; match; use currZ80PC

                                    dec     esi
                            .endw

                            inc     startZ80PC  ; increment inner loop starting PC
                            dec     ebx         ; decrement forwards scan counter
                    .endw

                    ; if no match, use entry value - 1
                    mov     ax, entryZ80PC
                    sub     ax, 1

FPLine_Fnd:
                    mov     Z80PC, ax

                    ret
Cursor_Up           endp

align 16
Cursor_Down         proc

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     ViewAsDump == TRUE
                            .if     ShowOpsAsAscii == TRUE
                                    movzx   ax, MaxDumpAsAscii
                                    add     Z80PC, ax
                            .else
                                    movzx   ax, MaxDumpAsHexDec
                                    add     Z80PC, ax
                            .endif
                            ret
                    .endif

                    pushad
                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING   ; required before calling DisassembleLine
                    invoke  DisassembleLine, pTEXTSTRING     ; incs Z80PC by opcode length
                    popad
                    ret
Cursor_Down         endp

align 16
GetSelectedLine     proc
                    invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_GETCURSEL, 0, 0
                    .if     eax == RT_ERR
                          ; set current selection to index 0
                            invoke  SetSelectedLine, 0
                            xor     eax, eax
                    .endif
                    ret     ; eax = current selection

GetSelectedLine     endp

align 16
SetSelectedLine     proc    index:  DWORD

                    invoke  SendDlgItemMessage, Debugger_hWnd, IDC_DISASSEMBLYLST, RT_SETCURSEL, index, 0
                    ret

SetSelectedLine     endp

align 16
ParseRegText        proc    CtrlID:     DWORD

                    LOCAL   CtrlHandle: DWORD,
                            buffer1[6]: BYTE

                    invoke  GetDlgItem, RegistersDLG.hWnd, CtrlID
                    mov     CtrlHandle, eax     ; handle of editbox

                    invoke  SendMessage, CtrlHandle, WM_GETTEXT, sizeof buffer1, addr buffer1

                    invoke  StringToDWord, addr buffer1, addr lpTranslated
                    ret     ; ax = word result

ParseRegText        endp

Run_DebugFrame      proc

                    mov     al, FrameSkipCounter
                    mov     FrameSkipLoop, al

                    .if     FULLSPEEDMODE == TRUE
                            mov FrameSkipLoop, FULLSPEEDFRAMECOUNT
                    .endif

                    .if     TapePlaying && FastTapeLoading && (RealTapeMode == FALSE)
                            mov    FrameSkipLoop, AUTOTAPEFRAMESKIP
                    .endif

Dbg_Emu_ReInit:     mov     PortUpdatePending, TRUE

        ;   INT low code
                    mov     RunTo_IntCounter, 0

                    mov     eax, totaltstates

;--------------------------------------------------------------------------------
align 16
                        .while  eax < MACHINE.InterruptCycles

                                .if     (currentMachine.iff1 == TRUE) && (EI_Last == FALSE)
                                        inc     RunTo_IntCounter

                                        call    z80_Interrupt
                                        je      @F      ; jump forward if INT accepted
                                .endif

                                call    Exec_Opcode
@@:                             call    Exec_Extras

                                ; exit if RunTo is active and reached
                                .if     Check_RunTo
                                        CHECK_RUN_TO
                                .else
                                        ; mutually exclude with RunTo...
                                        HASLEFTROMSPACE
                                        HASENTEREDROMSPACE
                                        ISBREAKPOINT    zPC
                                        je      DebugFrame_Trap     ; breakpoint hit
                                .endif
        
                                .if     Check_ExitSub
                                        test    RETCounter, 255
                                        js      DebugFrame_Trap     ; break if negative
                                .endif

                                .if     Check_TraceHook
                                        call    [TraceHook]
                                        .if     TraceStopFlag
                                                mov     TraceStopFlag, FALSE
                                                jmp     DebugFrame_Trap
                                        .endif
                                .endif
        
                                mov     eax, totaltstates
                        .endw
;--------------------------------------------------------------------------------

        ;   end INT low code

                        mov     eax, totaltstates

;--------------------------------------------------------------------------------
align 16
                        .while  eax < MACHINE.FrameCycles

                            .if     PortUpdatePending == TRUE
                                    .if     eax > 69888/2
                                            mov     PortUpdatePending, FALSE
                                            call    UpdatePortState     ; preserves all registers

                                            .if     currentMachine.nmi
                                                    call    z80_NMI
                                                    jmp     @F
                                            .endif
                                    .endif
                            .endif

                            call    Exec_Opcode
@@:                         call    Exec_Extras

                            ; break into debugger if RunTo is active and condition reached
                            .if     Check_RunTo
                                    CHECK_RUN_TO
                            .else
                                    ; mutually exclude with RunTo...
                                    HASLEFTROMSPACE
                                    HASENTEREDROMSPACE
                                    ISBREAKPOINT    zPC
                                    je      DebugFrame_Trap     ; breakpoint hit
                            .endif

                            .if     Check_ExitSub
                                    test    RETCounter, 255
                                    js      DebugFrame_Trap     ; break if negative
                            .endif

                            .if     Check_TraceHook
                                    call    [TraceHook]
                                    .if     TraceStopFlag
                                            mov     TraceStopFlag, FALSE
                                            jmp     DebugFrame_Trap
                                    .endif
                            .endif

                            .if     (FDCBreakEnabled == TRUE) && (RecNewFDCCommand == TRUE)
                                    mov     RecNewFDCCommand, FALSE
                                    call    [FDCBreakHandler]
                                    cmp     eax, TRUE
                                    je      DebugFrame_Trap
                            .endif

                            mov     eax, totaltstates
                        .endw
;--------------------------------------------------------------------------------

                        RENDERCYCLES

                        mov     eax, MACHINE.FrameCycles
                        sub     totaltstates, eax

                        .if     AutoPlayTapes
                                .if     AutoTapeStarted
                                        .if     (LoadTapeType == Type_TZX) && (TZXPause > 0) && (SL_AND_32_64 == TRUE)
                                        .elseif (LoadTapeType == Type_PZX) && (PZX.Pause > 0) && (SL_AND_32_64 == TRUE)
                                        .else
                                                .if    AutoTapeStopFrames == 0
                                                       mov     TapePlaying, FALSE
                                                       mov     AutoTapeStarted, FALSE
                                                .else
                                                       dec     AutoTapeStopFrames
                                                .endif
                                        .endif
                                .endif
                        .endif

                        call    InitUpdateScreen

                        inc     FramesPerSecond
                        inc     GlobalFramesCounter

                        shr     AY_FloatingRegister, 1

                        invoke  DRAM_Fade

                        dec     FrameSkipLoop
                        jnz     Dbg_Emu_ReInit
    
                        return  FALSE       ; no trap occurred in this frame

DebugFrame_Trap:        return  TRUE        ; cause debugger to appear

Run_DebugFrame          endp

align 16
Is_CBI_Paged            proc

                        mov     ax, zPC
                        ifc     ax ge 4000h then return FALSE

                        ; port 255, bit 7 - Paging the EPROM. If = 0, enables and disables EPROM EPROM OF BASIC. If = 1, the opposite.
                        test    CBI_Port_255, (1 shl 7)
                        .if     ZERO?
                                return  TRUE
                        .endif

                        ifc     ah ne 3ch then return FALSE

                        ; port 252, bit 6 - If = 1 disables EPROM DOS including in the area and that this priority. If enable = 0 (only 3C00h 3cFFh the area).
                        test    CBI_Port_252, (1 shl 6)
                        .if     ZERO?
                                return  TRUE
                        .endif

                        return  FALSE

Is_CBI_Paged            endp

align 16
SetPagingInfo       proc    uses esi

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                    lea     esi, currentMachine.RAMREAD0
                    SETLOOP 4
                           ; handle special cases for first 16K memory space
                            .if     dword ptr [esp] == 4
                                    .if     CBI_Enabled == TRUE
                                            .if     $fnc (Is_CBI_Paged) == TRUE
                                                    mov     eax, CTXT ('Beta 48')
                                                    jmp     @F
                                            .endif
                                    .endif
                            .endif

                            switch  dword ptr [esi]

                                    ; RAM
                                    case    currentMachine.bank0
                                            mov     eax, CTXT ('Page 0')
                                    case    currentMachine.bank1
                                            mov     eax, CTXT ('Page 1')
                                    case    currentMachine.bank2
                                            mov     eax, CTXT ('Page 2')
                                    case    currentMachine.bank3
                                            mov     eax, CTXT ('Page 3')
                                    case    currentMachine.bank4
                                            mov     eax, CTXT ('Page 4')
                                    case    currentMachine.bank5
                                            mov     eax, CTXT ('Page 5')
                                    case    currentMachine.bank6
                                            mov     eax, CTXT ('Page 6')
                                    case    currentMachine.bank7
                                            mov     eax, CTXT ('Page 7')

                                    ; ROM
                                    case    offset Rom_48
                                            mov     eax, CTXT ('ROM 0')

                                    case    offset Rom_128
                                            mov     eax, CTXT ('ROM 0')
                                    case    offset Rom_128+16384
                                            mov     eax, CTXT ('ROM 1')

                                    case    offset Rom_Plus2
                                            mov     eax, CTXT ('ROM 0')
                                    case    offset Rom_Plus2+16384
                                            mov     eax, CTXT ('ROM 1')

                                    case    offset Rom_Plus3
                                            mov     eax, CTXT ('ROM 0')
                                    case    offset Rom_Plus3+16384
                                            mov     eax, CTXT ('ROM 1')
                                    case    offset Rom_Plus3+32768
                                            mov     eax, CTXT ('ROM 2')
                                    case    offset Rom_Plus3+49152
                                            mov     eax, CTXT ('ROM 3')

                                    case    offset Rom_Pentagon128
                                            mov     eax, CTXT ('ROM 0')
                                    case    offset Rom_Pentagon128+16384
                                            mov     eax, CTXT ('ROM 1')

                                    case    offset Rom_TC2048
                                            mov     eax, CTXT ('ROM 0')

                                    case    offset Rom_Trdos
                                            mov     eax, CTXT ('TR-DOS')

                                    case    offset Rom_TK90x
                                            mov     eax, CTXT ('ROM 0')

                                    case    offset Mf128_Mem, offset Mf3_Mem, offset Mf48_Mem
                                            mov     eax, CTXT ('MF ROM/RAM')

                                    case    offset  SoftRom_RAM
                                            mov     eax, CTXT ('SOFT-ROM')
                            .else
                                    mov     eax, CTXT ('N/A')
                            endsw

                        @@: ADDTEXTSTRING   pTEXTSTRING, eax
                            add     esi, 8
                            ifc     dword ptr [esp] ne 1 then ADDCHAR pTEXTSTRING, ",", " "
                    ENDLOOP

                    switch  HardwareMode
                            case    HW_16, HW_48, HW_TC2048, HW_TK90X
                            .else
                                    test    Last7FFDWrite, 32
                                    .if     ZERO?
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, " (EN)"
                                    .else
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, " (DIS)"
                                    .endif
                    endsw

                    invoke  SetDlgItemText, Debugger_hWnd, IDC_PAGEINFOSTC, addr textstring

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    test    Last7FFDWrite, 8
                    .if     ZERO?
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Screen: 0"
                    .else
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Screen: 1"
                    .endif
                    .if     SPGfx.SnowEffect
                            ADDDIRECTTEXTSTRING pTEXTSTRING, " (Snow)"
                    .endif

                    invoke  SetDlgItemText, Debugger_hWnd, IDC_SCREENSTC, addr textstring

                    ret
SetPagingInfo       endp

align 16
SetDebugReadWriteButtonStates   proc    uses        ebx esi edi,
                                        hWndDlg:    DWORD

                                local   hwinONREAD:     DWORD,
                                        hwinONWRITE:    DWORD,
                                        hwinONACCESS:   DWORD

                                mov     hwinONREAD,   $fnc (GetDlgItem, hWndDlg, IDC_DISSBREAKONREAD)
                                mov     hwinONWRITE,  $fnc (GetDlgItem, hWndDlg, IDC_DISSBREAKONWRITE)
                                mov     hwinONACCESS, $fnc (GetDlgItem, hWndDlg, IDC_DISSBREAKONACCESS)

                                invoke  SendMessage, hwinONREAD,   BM_SETCHECK, FALSE, 0
                                invoke  SendMessage, hwinONWRITE,  BM_SETCHECK, FALSE, 0
                                invoke  SendMessage, hwinONACCESS, BM_SETCHECK, FALSE, 0

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
                                        .elseif TraceHook == offset StopMemWriteHook
                                                invoke  EnableWindow, hwinONREAD, FALSE
                                                invoke  EnableWindow, hwinONWRITE, TRUE
                                                invoke  EnableWindow, hwinONACCESS, FALSE
                                                invoke  SendMessage, hwinONWRITE, BM_SETCHECK, TRUE, 0
                                        .elseif TraceHook == offset StopMemAccessHook
                                                invoke  EnableWindow, hwinONREAD, FALSE
                                                invoke  EnableWindow, hwinONWRITE, FALSE
                                                invoke  EnableWindow, hwinONACCESS, TRUE
                                                invoke  SendMessage, hwinONACCESS, BM_SETCHECK, TRUE, 0
                                        .endif
                                .endif

                                ret

SetDebugReadWriteButtonStates   endp

align 16
EnableDumpControls  proc    uses        ebx,
                            hWndDlg:    DWORD

                    movzx   ebx, ViewAsDump
                    invoke  EnableControl, Debugger_hWnd, IDC_BACKREF, ebx
                    invoke  EnableControl, Debugger_hWnd, IDC_FOLLOWREF, ebx

                    xor     ebx, TRUE
                    invoke  EnableControl, Debugger_hWnd, IDC_STEP, ebx
                    invoke  EnableControl, Debugger_hWnd, IDC_TOGGLEBREAKPOINT, ebx
                    invoke  EnableControl, Debugger_hWnd, IDC_CLEARBREAKPOINTS, ebx

                  ; following controls are always disabled if the emulator is paused
                    .if     EmuRunning == FALSE
                            mov     ebx, FALSE
                    .endif

                    invoke  EnableControl, Debugger_hWnd, IDC_STEPOVER, ebx
                    invoke  EnableControl, Debugger_hWnd, IDC_RUNTO, ebx
                    invoke  EnableControl, Debugger_hWnd, IDC_EXITSUB, ebx

                    .if     ViewAsDump == FALSE
                            mov     ebx, [StackPtr]
                            sub     ebx, 4
                            mov     eax, [ebx]
                            .if     eax != 0FFFFFFFFh
                                    invoke  EnableControl, Debugger_hWnd, IDC_BACKREF, TRUE
                            .endif
                    .endif
                    ret
EnableDumpControls  endp

; enables/disables all child windows/dialogs of the main debugger dialog box
align 16
EnableDebugWindows              proc    uses    esi ebx,
                                State:  DWORD

                                lea     esi, DIALOGARRAY
                                mov     ebx, NUMDIALOGS
                            @@: invoke  EnableWindow, [esi].TDEBUGDIALOG.hWnd, State
                                add     esi, sizeof TDEBUGDIALOG
                                dec     ebx
                                jnz     @B
                                ret

EnableDebugWindows              endp

; destroys all child windows/dialogs of the main debugger dialog box
align 16
DestroyDebugWindows proc    uses    esi ebx

                    lea     esi, DIALOGARRAY
                    mov     ebx, NUMDIALOGS
                @@: invoke  SendMessage,   [esi].TDEBUGDIALOG.hWnd, WM_COMMAND, WPARAM_USER, LP_SAVESTATE
                    invoke  DestroyWindow, [esi].TDEBUGDIALOG.hWnd
                    mov     [esi].TDEBUGDIALOG.hWnd, NULL
                    add     esi, sizeof TDEBUGDIALOG
                    dec     ebx
                    jnz     @B
                    ret

DestroyDebugWindows endp

.const
dbgwin_tbrbtns      TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
                    TBBUTTON    <STD_FILEOPEN,IDM_DBGLOADSNAPSHOT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <STD_FILESAVE,IDM_DBGSAVESNAPSHOT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
                    TBBUTTON    <16,IDM_PAUSE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
                    TBBUTTON    <21,IDM_GOTOADDRESS,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>

DBGWIN_NTBRBTNS     equ         ((THIS BYTE - dbgwin_tbrbtns) / sizeof TBBUTTON)

.code
align 16
AddDebuggerToolBar  proc    hInst:      DWORD,
                            hOwner:     HWND

                    LOCAL   tbab:       TBADDBITMAP

                    mov     hDbgToolBar, $fnc (GetDlgItem, Debugger_hWnd, IDT_DEBUGTOOLBAR)

                    ; Set toolbar struct size
                    invoke  SendMessage, hDbgToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0


                    ; Add toolbar bitmaps
                    push    HINST_COMMCTRL
                    pop     tbab.hInst
                    mov     tbab.nID, IDB_STD_SMALL_COLOR
                    invoke  SendMessage, hDbgToolBar, TB_ADDBITMAP, 15, addr tbab

;                    invoke  SetTbrColorMap
                    invoke  CreateMappedBitmap, hInstance, IDB_MAINWINTOOLBAR, 0, addr TbrColorMap, 1
                    mov     tbab.nID, eax
                    mov     tbab.hInst, NULL
                    invoke  SendMessage, hDbgToolBar, TB_ADDBITMAP, 6, addr tbab

                    ; Set toolbar buttons
                    invoke  SendMessage, hDbgToolBar, TB_ADDBUTTONS, DBGWIN_NTBRBTNS, addr dbgwin_tbrbtns

                    return  hDbgToolBar

AddDebuggerToolBar  endp


