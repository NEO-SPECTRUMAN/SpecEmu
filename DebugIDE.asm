
PopulateIDEDlg  PROTO
UpdateIDEReg    PROTO   :DWORD,:BYTE
UpdateIDERegW   PROTO   :DWORD,:WORD

DebugIDEDlgProc proc    uses    ebx esi edi,
                        hWndDlg     :DWORD,
                        uMsg        :DWORD,
                        wParam      :DWORD,
                        lParam      :DWORD

                invoke  HandleCustomWindowMessages, ADDR IDEDLG, hWndDlg, uMsg, wParam, lParam
                .if     eax == TRUE
                        return  TRUE
                .endif

                RESETMSG

OnInitDialog
                ; set menu ID on main debugger window's menu
                mov     IDEDLG.Menu_ID, IDM_VIEW_IDE

                invoke  PopulateIDEDlg
                return  TRUE

OnShowWindow
                invoke  PopulateIDEDlg
                return  TRUE

OnClose
                return  TRUE

OnDestroy
                return  NULL

OnCommand
                return  TRUE

OnDefault
                return  FALSE

                DOMSG

DebugIDEDlgProc endp


UpdateIDEReg    proc    uses    ebx esi edi,
                        CtrlID: DWORD,
                        Value:  BYTE

                local   textstring: TEXTSTRING,
                        pTEXTSTRING:DWORD

                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                invoke  PrtBase8,       pTEXTSTRING, Value
                invoke  SendDlgItemMessage, IDEDLG.hWnd, CtrlID, WM_SETTEXT, 0, addr textstring
                ret
UpdateIDEReg    endp

UpdateIDERegW   proc    uses    ebx esi edi,
                        CtrlID: DWORD,
                        Value:  WORD

                local   textstring: TEXTSTRING,
                        pTEXTSTRING:DWORD

                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                invoke  PrtBase16,      pTEXTSTRING, Value, 0
                invoke  SendDlgItemMessage, IDEDLG.hWnd, CtrlID, WM_SETTEXT, 0, addr textstring
                ret
UpdateIDERegW   endp

PopulateIDEDlg  proc    uses        esi edi ebx

                .if     IDEDLG.Visible == TRUE

                        IDE_ReadStatus  IDEHandle
                        invoke  UpdateIDEReg, IDC_IDESTATUS, al

                        IDE_ReadError  IDEHandle
                        invoke  UpdateIDEReg, IDC_IDEERROR, al

                        IDE_ReadCylinderHigh  IDEHandle
                        mov     bh, al
                        IDE_ReadCylinderLow  IDEHandle
                        mov     bl, al
                        invoke  UpdateIDERegW, IDC_IDECYLINDER, bx

                        IDE_ReadDrive_Head  IDEHandle
                        mov     bl, al
                        and     al, 15
                        invoke  UpdateIDEReg, IDC_IDEHEAD, al
                        and     bl, 16
                        shr     bl, 4
                        invoke  UpdateIDEReg, IDC_IDEUNIT, bl

                        IDE_ReadSectorNumber  IDEHandle
                        invoke  UpdateIDEReg, IDC_IDESECTOR, al

                        IDE_ReadSectorCount  IDEHandle
                        invoke  UpdateIDEReg, IDC_IDESECTORCOUNT, al
                .endif
                ret
PopulateIDEDlg  endp



