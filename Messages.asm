
MessagesDialogProc          PROTO   :DWORD,:DWORD,:DWORD,:DWORD
Add_Message_Item            PROTO   :PTR
Show_Message_Dialog         PROTO
Clear_Messages              PROTO

;   defined in vars.inc
;   MessageMem  equ     (DummyMem + sizeof DummyMem) - 256

.data?
align 4
MessagesHandle              dd      ?

.data
MessageWinName              db      "MessagesWindow", 0

.code

ADDMESSAGE                  macro   msg:req
                            local   @@msg
                            .data
                                    @@msg   db  msg, 0
                            .code
                            pushad
                            invoke  Add_Message_Item, addr @@msg
                            popad
                            endm

ADDMESSAGEPTR               macro   lpmsg:req
                            pushad
                            invoke  Add_Message_Item, lpmsg
                            popad
                            endm

ADDMESSAGEDEC               macro   msg:req, arg:req
                            local   @@msg, @@buffer1
                            .data
                                    @@msg   db  msg, 0
                            .data?
                                    @@buffer1   byte 12 dup (?)
                            .code
                                    pushad
                                    mov     ebx, arg
                                    mov     MessageMem, 0
                                    invoke  szMultiCat, 2, addr MessageMem, addr @@msg, str$ (ebx)
                                    invoke  Add_Message_Item, addr MessageMem
                                    popad
                            endm

ADDMESSAGEHEX               macro   msg:req, arg:req
                            local   @@msg, @@buffer1
                            .data
                                    @@msg   db  msg, 0
                            .data?
                                    @@buffer1   byte 12 dup (?)
                            .code
                                    pushad
                                    mov     ebx, arg
                                    mov     MessageMem, 0
                                    invoke  szMultiCat, 2, addr MessageMem, addr @@msg, hex$ (ebx)
                                    invoke  Add_Message_Item, addr MessageMem
                                    popad
                            endm

align 16
Add_Message_Item            proc    lpItem: PTR
                            .if     $fnc (SendMessage, MessagesHandle, LB_GETCOUNT, 0, 0) != LB_ERR
                                    .if     eax > 255
                                            invoke  SendMessage, MessagesHandle, LB_DELETESTRING, 0, 0  ; delete top string in list box
                                    .endif
                                    invoke  SendMessage, MessagesHandle, LB_ADDSTRING, 0, lpItem
                            .endif
                            ret
Add_Message_Item            endp

Clear_Messages              proc

                            invoke  SendMessage, MessagesHandle, LB_RESETCONTENT, 0, 0
                            ret
Clear_Messages              endp

Show_Message_Dialog         proc

                            invoke ShowWindow, MessagesDlg, SW_SHOW
                            ret
Show_Message_Dialog         endp

align 16
MessagesDialogProc          proc    uses        esi edi ebx,
                                    hWndDlg:    DWORD,
                                    uMsg:       DWORD,
                                    wParam:     DWORD,
                                    lParam:     DWORD

                            local   WinRect:    RECT

                            RESETMSG

OnInitDialog
                            mov     DummyMem, 0
                            strcat  addr DummyMem, addr MessageWinName, SADD ("_X")
                            invoke  ReadProfileInt,  addr DummyMem, -1
                            mov     esi, eax

                            mov     DummyMem, 0
                            strcat  addr DummyMem, addr MessageWinName, SADD ("_Y")
                            invoke  ReadProfileInt,  addr DummyMem, -1
                            mov     edi, eax

                            .if     (esi != -1) && (edi != -1)
                                    invoke  SetWindowPos, hWndDlg, NULL, esi, edi, 0, 0, SWP_NOOWNERZORDER or SWP_NOSIZE or SWP_NOZORDER
                            .endif

                            mov     MessagesHandle, $fnc (GetDlgItem, hWndDlg, IDC_MESSAGESLST)

                            SETNEWWINDOWFONT    MessagesHandle, Courier_8, MessageBoxFont, MessageBoxOldFont
                            invoke  SendMessage, MessagesHandle, LB_INITSTORAGE, 256, 256*32

                            return  FALSE

OnClose
                            invoke  ShowWindow, hWndDlg, SW_HIDE

OnDestroy
                            SETOLDWINDOWFONT    MessagesHandle, MessageBoxFont, MessageBoxOldFont

                            invoke  GetWindowRect, hWndDlg, addr WinRect

                            mov     DummyMem, 0
                            strcat  addr DummyMem,   addr MessageWinName, SADD ("_X")
                            invoke  WriteProfileInt, addr DummyMem, WinRect.left

                            mov     DummyMem, 0
                            strcat  addr DummyMem,   addr MessageWinName, SADD ("_Y")
                            invoke  WriteProfileInt, addr DummyMem, WinRect.top

                            return  NULL

OnDefault
                            return  FALSE

                            DOMSG

MessagesDialogProc          endp

ADDMESSAGE_DBG              macro   msg:req
                            IFDEF   DEBUGBUILD
                                    ADDMESSAGE  msg
                            ENDIF
                            endm

ADDMESSAGEPTR_DBG           macro   msg:req
                            IFDEF   DEBUGBUILD
                                    ADDMESSAGEPTR   msg
                            ENDIF
                            endm

ADDMESSAGEDEC_DBG           macro   msg:req, arg:req
                            IFDEF   DEBUGBUILD
                                    ADDMESSAGEDEC   msg, arg
                            ENDIF
                            endm

ADDMESSAGEHEX_DBG           macro   msg:req, arg:req
                            IFDEF   DEBUGBUILD
                                    ADDMESSAGEHEX   msg, arg
                            ENDIF
                            endm


