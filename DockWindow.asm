
TWINSIZE                STRUCT
WRect                   RECT    <>
WWidth                  DWORD   ?
WHeight                 DWORD   ?
TWINSIZE                ENDS

GetWindowSize           PROTO   :DWORD,:PTR TWINSIZE

; structure for external debugger dialogs
TDEBUGDIALOG            STRUCT
hWnd                    DWORD   ?   ; window handle of this dialog box
Menu_ID                 DWORD   ?   ; menu ID of this dialog's activation item in main debugger window's menu
lpName                  DWORD   ?   ; ptr to text string defining the name of this dialog (for LOAD/SAVE STATE messages)
WinSize                 TWINSIZE <> ; current position & size of this dialog
Visible                 BYTE    ?   ; TRUE if visible, else FALSE
IsInitWinSize           BYTE    ?   ; TRUE if initial window size has been setup in WM_INITDIALOG in custom message handler
TDEBUGDIALOG            ENDS

TogglePopupStyle        PROTO   :PTR TDEBUGDIALOG

.data?
align 4

DIALOGARRAY             LABEL   BYTE
FindDLG                 TDEBUGDIALOG <?>
SourceRipperDLG         TDEBUGDIALOG <?>
RegistersDLG            TDEBUGDIALOG <?>
Plus3DLG                TDEBUGDIALOG <?>
IDEDLG                  TDEBUGDIALOG <?>
MemoryDLG               TDEBUGDIALOG <?>
PCHistoryDLG            TDEBUGDIALOG <?>
BreakpointsDLG          TDEBUGDIALOG <?>
CommandParserDLG        TDEBUGDIALOG <?>

NUMDIALOGS              equ     ($ - DIALOGARRAY) / sizeof TDEBUGDIALOG ; number of debugger dialogs

.code

                        ASSUME  EBX: PTR  TDEBUGDIALOG


TogglePopupStyle        proc    uses        ebx,
                                hDialog:    PTR  TDEBUGDIALOG

                        LOCAL   winStyle:   DWORD,
                                winExStyle: DWORD

                        mov     ebx, hDialog

                        mov     winStyle,   $fnc (GetWindowLong, [ebx].hWnd, GWL_STYLE)
                        mov     winExStyle, $fnc (GetWindowLong, [ebx].hWnd, GWL_EXSTYLE)
                        mov     eax, winStyle
                        test    eax, WS_CHILD
                        .if     ZERO?
                                and     eax, NOT (WS_POPUP or WS_CAPTION or WS_SYSMENU)
                                or      eax, (WS_CHILD or DS_CONTROL)
                                invoke  SetWindowLong, [ebx].hWnd, GWL_STYLE, eax
                        .else
                                and     eax, NOT (WS_CHILD or DS_CONTROL)
                                or      eax, (WS_POPUP or WS_CAPTION or WS_SYSMENU)
                                invoke  SetWindowLong, [ebx].hWnd, GWL_STYLE, eax
                        .endif

                        ; Send the window a WM_NCCALCSIZE message because the frame style has changed
                        invoke  SetWindowPos, [ebx].hWnd, 0, 0, 0, 0, 0,
                                              SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED
                        ret

TogglePopupStyle        endp


                        ASSUME  EBX: NOTHING



