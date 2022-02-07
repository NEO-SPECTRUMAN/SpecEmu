
CmdParserEdit_SubclassProc  PROTO   :DWORD,:DWORD,:DWORD,:DWORD
CmdParser_Execute           PROTO
Cmd_Fetch_String            PROTO
Cmd_Fetch_Numeric_Val       PROTO
Cmd_Fetch_Numeric           PROTO
Cmd_Fetch_Numerics          PROTO   :DWORD

Cmd_AddHistoryBox           PROTO   :DWORD

CmdParser_SetEditText       PROTO   :DWORD
CopySpecMemToTemp           PROTO   :DWORD,:DWORD

CountByteRepeats            PROTO   :DWORD,:DWORD
CountZeroBits               PROTO   :DWORD,:DWORD
CreateXORData               PROTO   :DWORD,:DWORD
Encode                      PROTO   :DWORD,:DWORD,:DWORD

Calc_CRC16_Byte             PROTO   :BYTE
Calc_CRC16_Data             PROTO   :DWORD,:DWORD
Init_CRC16                  PROTO

.data?
align 4
OrigCmdParserEditWndProc    DWORD   ?
CmdParserEdit_Handle        DWORD   ?

cmd_parser_buffer           BYTE    255 DUP (?)

.code
DebugCmdParserDlgProc       proc   uses    ebx esi edi,
                            hWndDlg     :DWORD,
                            uMsg        :DWORD,
                            wParam      :DWORD,
                            lParam      :DWORD

                            invoke  HandleCustomWindowMessages, addr CommandParserDLG, hWndDlg, uMsg, wParam, lParam
                            .if     eax == TRUE
                                    return  TRUE
                            .endif

                            RESETMSG

OnInitDialog
                            ; set menu ID on main debugger window's menu
                            mov     CommandParserDLG.Menu_ID, IDM_VIEW_COMMAND_PARSER

                            invoke  SendDlgItemMessage, hWndDlg, IDC_COMMANDEDT, EM_SETLIMITTEXT, sizeof cmd_parser_buffer, 0

                            mov     CmdParserEdit_Handle, $fnc (GetDlgItem, hWndDlg, IDC_COMMANDEDT)    ; window handle of query text edit box
                            invoke  SetWindowLong, CmdParserEdit_Handle, GWL_WNDPROC, addr CmdParserEdit_SubclassProc
                            mov     OrigCmdParserEditWndProc, eax

                            return  TRUE

OnShowWindow
                            return  TRUE

OnClose
                            return  TRUE

OnDestroy
                            invoke  SetWindowLong, CmdParserEdit_Handle, GWL_WNDPROC, OrigCmdParserEditWndProc
                            return  NULL

OnCommand
                            switch  wParam
                                    case    $WPARAM (RTN_DBLCLK, IDC_COMMAND_HISTORY)
                                            invoke  SendDlgItemMessage, CommandParserDLG.hWnd, IDC_COMMAND_HISTORY, RT_GETCURSELTEXT, 0, addr cmd_parser_buffer
                                            .if     eax != RT_ERR
                                                    invoke  CmdParser_SetEditText, addr cmd_parser_buffer
                                            .endif
                            endsw

                            return  TRUE

OnDefault
                            return  FALSE

                            DOMSG

DebugCmdParserDlgProc       endp

CmdParser_SetEditText       proc    uses    ebx,
                                    lpText: DWORD

                            mov     ebx, $fnc (GetDlgItem, CommandParserDLG.hWnd, IDC_COMMANDEDT)
                            invoke  SendMessage, ebx, WM_SETTEXT, 0, lpText
                            invoke  SendMessage, ebx, WM_KEYDOWN, VK_END, 0
                            invoke  SendMessage, ebx, WM_KEYUP,   VK_END, 0
                            invoke  SetFocus,    ebx
                            ret

CmdParser_SetEditText       endp

CmdParserEdit_SubclassProc  proc    uses    ebx esi edi,
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

                                                    invoke  SendMessage, hWin, WM_GETTEXT, sizeof cmd_parser_buffer, addr cmd_parser_buffer
                                                    invoke  SendMessage, hWin, WM_SETTEXT, 0, addr NULL_String

                                                    invoke  CmdParser_Execute
                                                    return	0
                                        endsw

                                case    WM_KEYDOWN
                                        switch  wParam
                                            case    VK_UP
                                                    mov     ebx, $fnc (GetDlgItem, CommandParserDLG.hWnd, IDC_COMMAND_HISTORY)
                                                    mov     esi, $fnc (SendMessage, ebx, RT_GETCURSEL, 0, 0)

                                                    .if     esi == -1
                                                            mov     esi, $fnc (SendMessage, ebx, RT_GETCOUNT, 0, 0)
                                                    .else
                                                            ifc     esi gt 0 then dec esi
                                                    .endif
                                                    invoke  SendMessage, ebx, RT_SETCURSEL, esi, 0
                                                    invoke  SendMessage, CommandParserDLG.hWnd, WM_COMMAND, $WPARAM (RTN_DBLCLK, IDC_COMMAND_HISTORY), 0
                                                    return  0

                                            case    VK_DOWN
                                                    mov     ebx, $fnc (GetDlgItem, CommandParserDLG.hWnd, IDC_COMMAND_HISTORY)
                                                    mov     esi, $fnc (SendMessage, ebx, RT_GETCURSEL, 0, 0)

                                                    .if     esi == -1
                                                            xor     esi, esi
                                                    .else
                                                            mov     ecx, $fnc (SendMessage, ebx, RT_GETCOUNT, 0, 0)
                                                            ifc     esi lt ecx then inc esi
                                                    .endif
                                                    invoke  SendMessage, ebx, RT_SETCURSEL, esi, 0
                                                    invoke  SendMessage, CommandParserDLG.hWnd, WM_COMMAND, $WPARAM (RTN_DBLCLK, IDC_COMMAND_HISTORY), 0
                                                    return  0
                                        endsw
                            endsw

                            invoke  CallWindowProc, OrigCmdParserEditWndProc, hWin, uMsg, wParam, lParam
                            ret

CmdParserEdit_SubclassProc  endp

.data?
align 4
cmd_arg_num                 dd      ?
cmd_arg_ptr                 dd      ?

CMD_ARG_SIZE                equ     MAX_PATH

cmd_arg_cmd                 equ     DummyMem
cmd_arg_1                   equ     cmd_arg_cmd + CMD_ARG_SIZE
cmd_arg_2                   equ     cmd_arg_1   + CMD_ARG_SIZE
cmd_arg_3                   equ     cmd_arg_2   + CMD_ARG_SIZE
cmd_arg_4                   equ     cmd_arg_3   + CMD_ARG_SIZE
cmd_arg_5                   equ     cmd_arg_4   + CMD_ARG_SIZE

align 4
mastertap_ofn               OPENFILENAME    <?>

.data
szMasterTapFilter           db  "TAP file (*.tap)", 0, "*.tap", 0,
                            0

.code
CmdParser_Execute   proc    uses    esi edi ebx

                    local   textstring:     TEXTSTRING,
                            pTEXTSTRING:    DWORD

                    local   is_128K:        DWORD,
                            testcount1:     DWORD,
                            testcount2:     DWORD

                    local   temp1, temp2:   DWORD,
                            temp3, temp4:   DWORD,
                            temp5, temp6:   DWORD

                    local   lpUserAsmSrc:   DWORD   ; ptr to asm source line in "asm" command

                    local   sa: SECURITY_ATTRIBUTES

                    local   buffer1 [128]:   BYTE

                    local   tempfilepath [1024]: BYTE
                    local   tempcurdir [MAX_PATH]: BYTE

                    local   asmsourcefile [MAX_PATH]: BYTE          ; path/filename
                    local   asmsourcefilePath [MAX_PATH]: BYTE      ; file path only
                    local   asmsourcefileName [MAX_PATH]: BYTE      ; file name only
                    local   asmsourcefileBin [MAX_PATH]: BYTE       ; asm Bin file name
                    local   asmsourcefileSymbol [MAX_PATH]: BYTE    ; asm Symbol file name
                    local   asmsourcefileErr [MAX_PATH]: BYTE       ; asm Error file name

                    local   assemblersourcecode [1024]: BYTE

                    mov     cmd_arg_num, 0
                    mov     cmd_arg_ptr, offset cmd_arg_cmd

                    invoke  Cmd_Fetch_String
                    jz      CmdParser_Error

                    invoke  szLower, addr cmd_arg_cmd

                    switch$ addr cmd_arg_cmd

                          ; ============================
                            IFDEF   PACMAN

                            PACARG  macro
                                    local   @exit
                                    invoke  Cmd_Fetch_Numeric   ; cmd_arg_1 = start level
                                    mov     cl, 0
                                    jz      @exit               ; no arg given, use default 0
                                    mov     cl, al              ; use given arg (0-255)
                            @exit:
                                    endm

                          ; ============================
                            case$   "pac"
                                    PACARG
                                    invoke  Enable_Pacmode, PACMODE_FREEPLAY, cl

                            case$   "pacrecord"
                                    PACARG
                                    invoke  Enable_Pacmode, PACMODE_RECORD, cl

                            case$   "pacplayback"
                                    PACARG
                                    invoke  Enable_Pacmode, PACMODE_PLAYBACK, cl

                            case$   "!p"
                                    PACARG
                                    invoke  Enable_Pacmode, PACMODE_RECORD, cl
                            ENDIF
                          ; ============================
                            case$   "basic"
                                    ;zxamdpoke(23635,23755)
                                    ;zxamsetreg(pc,4770)
                                    ;zxamsetreg(iy,23610)
                                    ;zxamsetreg(im,1)
                                    ;zxamsetreg(int,1)
                                    ;zxamsetreg(sp,65352)

                                    mov     bx, 23635
                                    mov     ax, 23755
                                    call    MemPokeWord
                                    mov     bx, 23606
                                    mov     ax, 15360
                                    call    MemPokeWord

                                    mov     zPC, 4770
                                    mov     z80registers.iy.w, 23610
                                    mov     z80registers.intmode, 1
                                    ENABLEINTS
                                    mov     z80registers._sp, 65352

                          ; ============================
                            case$   "new"
                                    invoke  Cmd_Fetch_Numeric   ; cmd_arg_1 = NEW address
                                    jz      CmdParser_Error

                                    DISABLEINTS
                                    mov     z80registers.af.hi, 0
                                    mov     eax, dword ptr cmd_arg_1
                                    mov     z80registers.de.w, ax
                                    mov     zPC, 4555

                          ; ============================
                            case$   "copymem"
                                    invoke  Cmd_Fetch_Numerics, 3       ; cmd_arg_1 = src; cmd_arg_2 = dest; cmd_arg_3 = size
                                    jz      CmdParser_Error

                                  ; attempt to allocate buffer memory
                                    mov     esi, $fnc (CopySpecMemToTemp, dword ptr cmd_arg_1, dword ptr cmd_arg_3)
                                    test    esi, esi
                                    je      CmdParser_Error

                                    push    esi
                                    mov     ebx, dword ptr cmd_arg_2    ; dest

                                    .while  dword ptr cmd_arg_3 > 0     ; size
                                            mov     al, [esi]
                                            inc     esi
                                            call    MemPokeByte
                                            inc     bx
                                            dec     dword ptr cmd_arg_3
                                    .endw

                                    pop     esi
                                    FreeMem (esi)

                          ; ============================
                            case$   "fillmem"
                                    invoke  Cmd_Fetch_Numerics, 3               ; cmd_arg_1 = start; cmd_arg_2 = size; cmd_arg_3 = byte
                                    jz      CmdParser_Error

                                    mov     ebx, dword ptr cmd_arg_1            ; start

                                    .while  dword ptr cmd_arg_2 > 0             ; size
                                            mov     eax, dword ptr cmd_arg_3    ; byte
                                            call    MemPokeByte
                                            inc     bx
                                            dec     dword ptr cmd_arg_2
                                    .endw

                          ; ============================
                            case$   "out"
                                    invoke  Cmd_Fetch_Numerics, 2
                                    jz      CmdParser_Error

                                    mov     ebx, dword ptr cmd_arg_1
                                    mov     eax, dword ptr cmd_arg_2

                                    push    totaltstates
                                    lea     esi, RegisterBase
                                    call    OutPort
                                    pop     totaltstates

                          ; ============================
                            case$   "hz"
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDTEXTDECIMAL  pTEXTSTRING, MACHINE.FramesPerSecond
                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, " Hz"
                                    invoke  Cmd_AddHistoryBox, addr textstring

                          ; ============================
                            case$   "z80v1"
                                    mov     save_z80_as_v1_enabled, TRUE
                                    invoke  Cmd_AddHistoryBox, SADD ("Saving 48K .z80 as v1")

                          ; ============================
                            case$   "z80v3"
                                    mov     save_z80_as_v1_enabled, FALSE
                                    invoke  Cmd_AddHistoryBox, SADD ("Saving 48K .z80 as v3")

                          ; ============================
                            case$   "bdr"
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Port $FE: $"
                                    ADDTEXTHEX      pTEXTSTRING, Last_FE_Write
                                    ADDCHAR         pTEXTSTRING, " "
                                    ADDCHAR         pTEXTSTRING, "("
                                    ADDTEXTDECIMAL  pTEXTSTRING, Last_FE_Write
                                    ADDCHAR         pTEXTSTRING, ")"
                                    invoke  Cmd_AddHistoryBox, addr textstring

                          ; ============================
                            case$   "tk"
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Port $FC: $"
                                    ADDTEXTHEX      pTEXTSTRING, CBI_Port_252
                                    ADDCHAR         pTEXTSTRING, " "
                                    ADDCHAR         pTEXTSTRING, "("
                                    ADDTEXTDECIMAL  pTEXTSTRING, CBI_Port_252
                                    ADDCHAR         pTEXTSTRING, ")"
                                    invoke  Cmd_AddHistoryBox, addr textstring

                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Port $FF: $"
                                    ADDTEXTHEX      pTEXTSTRING, CBI_Port_255
                                    ADDCHAR         pTEXTSTRING, " "
                                    ADDCHAR         pTEXTSTRING, "("
                                    ADDTEXTDECIMAL  pTEXTSTRING, CBI_Port_255
                                    ADDCHAR         pTEXTSTRING, ")"
                                    invoke  Cmd_AddHistoryBox, addr textstring

                          ; ============================
                            case$   "tapeinvert"
                                    xor     EarXor, 64

                                    movzx   ebx, EarXor
                                    mov     byte ptr textstring, 0
                                    invoke  szMultiCat, 2,  addr textstring, SADD ("Ear XOR: "), str$ (ebx)
                                    invoke  Cmd_AddHistoryBox, addr textstring

                          ; ============================
                            case$   "set"
                                    invoke  Cmd_Fetch_String
                                    jz      CmdParser_Error

                                    invoke  szLower, addr cmd_arg_1

                                    switch$ addr cmd_arg_1
                                            case$   "tstates"
                                                    invoke  Cmd_Fetch_Numeric_Val   ; cmd_arg_2 = tstate value
                                                    jz      CmdParser_Error

;                                                    mov     eax, dword ptr cmd_arg_2
                                                    .while  eax >= MACHINE.FrameCycles
                                                            sub     eax, MACHINE.FrameCycles
                                                    .endw
                                                    mov     totaltstates, eax

                                            case$   "intlen"
                                                    invoke  Cmd_Fetch_Numeric_Val   ; cmd_arg_2 = tstate value
                                                    jz      CmdParser_Error

                                                    .while  eax >= MACHINE.FrameCycles
                                                            sub     eax, MACHINE.FrameCycles
                                                    .endw
                                                    mov     MACHINE.InterruptCycles, eax

                                    else$
                                            jmp     CmdParser_Error ; unknown command
                                    endsw$

                          ; ============================
                            case$   "master"

                                    invoke  Cmd_AddHistoryBox, addr cmd_parser_buffer   ; this command is echoed to the output window


                                    invoke  Cmd_Fetch_String        ; fetch Program name into cmd_arg_1
                                    jz      CmdParser_Error

                                    invoke  Cmd_Fetch_Numeric_Val   ; cmd_arg_2 = 48 or 128
                                    jz      CmdParser_Error

                                    invoke  Cmd_Fetch_String        ; do we have cmd_arg_3 ?
                                    .if     ZERO?
                                            ; no filename given
                                            invoke  EnableDebugWindows, FALSE
                                            invoke  SaveFileName, Debugger_hWnd, SADD ("Master Tape"), addr szMasterTapFilter, addr mastertap_ofn, addr masterTapFilename, NULL, 0
                                            push    eax
                                            invoke  EnableDebugWindows, TRUE
                                            pop     eax
                                            ifc     eax eq 0 then jmp CmdParser_Error
                                    .else
                                            ; a filename was given
                                            strncpy addr cmd_arg_3, addr masterTapFilename, sizeof masterTapFilename
                                    .endif

                                    ADDEXTENSION    offset masterTapFilename, offset TAPExt

                                    invoke  EnableDebugWindows, FALSE
                                    invoke  AskOverwriteFile, addr masterTapFilename, Debugger_hWnd, addr szWindowName
                                    push    eax
                                    invoke  EnableDebugWindows, TRUE
                                    pop     eax

                                    ifc     eax == FALSE then jmp CmdParser_Error

                                    switch  cmd_arg_2
                                            case    48
                                                    mov     is_128K, FALSE
                                            case    128
                                                    mov     is_128K, TRUE
                                            .else
                                                    jmp     CmdParser_Error
                                    endsw

                                    xor     esi, esi        ; zero = mastering allowed
                                    movzx   eax, z80registers._sp
                                    ifc     eax eq 0 then mov eax, 65536
                                    .if     eax < 24064
                                            mov     esi, CTXT ("SP must be !>= 24064 (#5E00).")
                                    .endif
                                    movzx   eax, zPC
                                    movzx   ecx, z80registers._sp
                                    ifc     ecx eq 0 then mov ecx, 65536
                                    mov     edx, ecx
                                    sub     edx, 256
                                    .if     (eax >= edx) && (eax < ecx)  ; PC cannot be between (SP-256) and SP
                                            mov     esi, CTXT ("Working stack space will overwrite Program Counter.")
                                    .endif

                                    .if     esi == 0
                                            invoke  EnableDebugWindows, FALSE
                                            invoke  ShowMessageBox, Debugger_hWnd, SADD ("Do you want anti-merge for this tape?"), addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                            ifc     eax eq IDYES then mov antimerge_specified, TRUE else mov antimerge_specified, FALSE
                                            invoke  EnableDebugWindows, TRUE


                                            invoke  Cmd_AddHistoryBox, SADD ("Mastering tape image, please wait...")
                                            invoke  Master_Tape, addr cmd_arg_1, is_128K, addr masterTapFilename
                                            invoke  Cmd_AddHistoryBox, SADD ("Mastering finished.")

                                            mov     byte ptr textstring, 0
                                            invoke  szMultiCat, 5,  addr textstring,
                                                                    SADD ("Loading time: "),
                                                                    str$ (loadtime_minutes), SADD ("m "),
                                                                    str$ (loadtime_seconds), SADD ("s")
                                            invoke  Cmd_AddHistoryBox, addr textstring
                                    .else
                                            invoke  Cmd_AddHistoryBox, esi
                                            invoke  Cmd_AddHistoryBox, SADD ("Mastering aborted.")
                                    .endif

                          ; ============================
                            case$   "ay"

                            dsText  ayreg_txt,  "AY register: "
                            dsText  ayopbr_txt, " ("
                            dsText  ayclbr_txt, " )"

                            movzx   ebx, SCSelectReg

                            mov     byte ptr textstring, 0
                            invoke  szMultiCat, 2,  addr textstring, SADD ("AY selected register: "), str$ (ebx)
                            invoke  Cmd_AddHistoryBox, addr textstring

                            ForLp   ebx, 0, 15
                                    mov     byte ptr textstring, 0
                                    movzx   edi, byte ptr [SCRegister0+ebx]

                                    switch  ebx
                                            case    7
                                                    push    edi
                                                    mov     ecx, edi        ; ecx = AY reg value
                                                    lea     edi, buffer1
                                                    mov     eax, "x x "
                                                    stosd

                                                    shl     cl, 2
                                                    SETLOOP 6
                                                            shl     cl, 1
                                                            mov     ah, "0"
                                                            adc     ah, 0
                                                            stosw
                                                    ENDLOOP
                                                    xor     al, al
                                                    stosb                   ; terminate string
                                                    pop     edi
                                                    invoke  szMultiCat, 7,  addr textstring, addr ayreg_txt, str$ (ebx), SADD (": "), str$ (edi), addr ayopbr_txt, addr buffer1, addr ayclbr_txt
                                            .else
                                                    invoke  szMultiCat, 4,  addr textstring, addr ayreg_txt, str$ (ebx), SADD (": "), str$ (edi)

                                    endsw
                                    invoke  Cmd_AddHistoryBox, addr textstring
                            Next    ebx

                          ; ============================
                            case$   "keyb"
                                    invoke  Cmd_AddHistoryBox, SADD ("F7FE: 1 2 3 4 5")
                                    invoke  Cmd_AddHistoryBox, SADD ("EFFE: 6 7 8 9 0")
                                    invoke  Cmd_AddHistoryBox, SADD ("FBFE: Q W E R T")
                                    invoke  Cmd_AddHistoryBox, SADD ("DFFE: Y U I O P")
                                    invoke  Cmd_AddHistoryBox, SADD ("FDFE: A S D F G")
                                    invoke  Cmd_AddHistoryBox, SADD ("BFFE: H J K L Enter")
                                    invoke  Cmd_AddHistoryBox, SADD ("FEFE: Caps Z X C V")
                                    invoke  Cmd_AddHistoryBox, SADD ("7FFE: B N M Sym Space")

                          ; ============================
                            case$   "scpp"
                                        mov     ebx, $fnc (speccpp_myfunc, currentMachine.bank5)

                                        invoke  Cmd_AddHistoryBox, str$ (ebx)

                                        RENDERFRAME

                          ; ============================
                            case$   "mag"

                                    ; cache: C:\Users\woody\AppData\Roaming\ZXiSeek

                                    mov     byte ptr tempfilepath, 0
                                    invoke  szMultiCat, 2, addr tempfilepath, offset appPath, SADD ("ZXiSeek\ZXiSeek.exe")

                                    memclr  addr StartupInfo, sizeof StartupInfo
                                    mov     StartupInfo.cb, sizeof STARTUPINFO
                                    mov     StartupInfo.wShowWindow, SW_SHOWDEFAULT

                                    .if     $fnc (CreateProcess, NULL, addr tempfilepath, NULL, NULL, FALSE, DETACHED_PROCESS, NULL, NULL, addr StartupInfo, addr ProcessInfo) != 0
                                            ; wait for ZXiSeek to finish
                                            ; invoke  WaitForSingleObject, ProcessInfo.hProcess, INFINITE

                                            ; close handles to the child process and its primary thread
                                            invoke  CloseHandle, ProcessInfo.hProcess
                                            invoke  CloseHandle, ProcessInfo.hThread

                                            invoke  PostMessage, Debugger_hWnd, WM_CLOSE, 0, 0  ; close debugger after opening magazine viewer
                                    .else
                                            invoke  ShowMessageBox, hWnd, SADD ("CreateProcess failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                    .endif

                          ; ============================
                            case$   "mod"
                                    SETLOOP     1000000
                                                mov     temp1, $fnc (nrandom, 10000000)
                                                mov     temp2, $fnc (nrandom, 10000000)
                                                inc     temp2   ; ensure non-zero (div by zero error)

                                                mov     temp1, @EVAL (temp1 ~ temp2)
                                                mov     temp2, $fnc (Mod2Int, temp1, temp2)

                                                mov     eax, temp1
                                                .if     eax != temp2
                                                        invoke  Cmd_AddHistoryBox, hex$ (temp1)
                                                        invoke  Cmd_AddHistoryBox, hex$ (temp2)
                                                .endif
                                    ENDLOOP

                                    invoke  Cmd_AddHistoryBox, str$ (@EVAL (65540 ~ 65536))
                                    invoke  Cmd_AddHistoryBox, str$ (@EVAL (15 ~ 9))
                                    invoke  Cmd_AddHistoryBox, str$ (@EVAL (15 ~ 2048))
                                    invoke  Cmd_AddHistoryBox, str$ (@EVAL (2100 ~ 2048))

                                    mov     eax, 5
                                    ABS     eax
                                    invoke  Cmd_AddHistoryBox, str$ (eax)
                                    mov     eax, -5
                                    ABS     eax
                                    invoke  Cmd_AddHistoryBox, str$ (eax)
                                    xor     eax, eax
                                    ABS     eax
                                    invoke  Cmd_AddHistoryBox, str$ (eax)
                                    mov     eax, -1
                                    ABS     eax
                                    invoke  Cmd_AddHistoryBox, str$ (eax)
                                    mov     eax, 1
                                    ABS     eax
                                    invoke  Cmd_AddHistoryBox, str$ (eax)

                                    invoke  Cmd_AddHistoryBox, SADD ("Done!")

                          ; ============================

                            case$   "stop"
                                    ; move to first char after "stop" command
                                    lea     esi, cmd_parser_buffer-1
                                    mov     eax, "pots"
                                @@: inc     esi
                                    cmp     eax, [esi]
                                    jne     @B
                                    add     esi, 4

                                @@: lodsb
                                    cmp     al, " "
                                    je      @B
                                    cmp     al, 9
                                    je      @B

                                    dec     esi

                                    or      al, al
                                    je      CmdParser_Error

                                    IFDEF   DEBUGBUILD
                                            ADDMESSAGE_DBG  "Writing Stop command to:"
                                            ADDMESSAGE_DBG  "C:\ProgramData\specemustopcmd.txt"
                                            mov     eax, len (esi)
                                            .if     $fnc (WriteMemoryToFile, SADD ("C:\ProgramData\specemustopcmd.txt"), esi, len (esi)) == 0
                                                    ADDMESSAGE_DBG  "Error writing Stop command file"
                                            .endif
                                    ENDIF

                                    .if     $fnc (CompileBreakpointCode, esi)
;                                            invoke  Cmd_AddHistoryBox, addr cmd_parser_buffer

                                            invoke  Set_RunTo_Condition, RUN_TO_USER_CONDITION

                                            invoke  PostMessage, Debugger_hWnd, WM_CLOSE, 0, 0  ; close debugger for run-to execution
                                    .else
                                            ADDMESSAGE_DBG  "Stop Command Error"
                                            jmp     CmdParser_Error
                                    .endif

                          ; ============================
.data
dump_banks_0_7              db      0, 1, 2, 3, 4, 5, 6, 7, -1
dump_banks_5_2_0            db      5, 2, 0, -1
dump_banks_5                db      5, -1

.code
                            case$   "dump"

                                    invoke  Cmd_Fetch_String        ; fetch path/filename into cmd_arg_1
                                    jz      CmdParser_Error

                                    switch  HardwareMode
                                            case    HW_16
                                                    lea     esi, dump_banks_5
                                                    mov     eax, True

                                            case    HW_48, HW_TC2048, HW_TK90X
                                                    lea     esi, dump_banks_5_2_0
                                                    mov     eax, True

                                            case    HW_128, HW_PLUS2, HW_PLUS2A, HW_PLUS3, HW_PENTAGON128
                                                    lea     esi, dump_banks_0_7
                                                    mov     eax, True

                                            .else
                                                    mov     eax, False
                                    endsw

                                    .if     eax == True
                                            .while  byte ptr [esi] != -1
                                                    movzx   ebx, byte ptr [esi]

                                                    invoke  Calc_CRC16_Data, [currentMachine.bank_ptrs+ebx*4], 16384
                                                    mov     di, ax

                                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                                    ADDTEXTSTRING   pTEXTSTRING, addr cmd_arg_1
                                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, ".bank"
                                                    ADDTEXTDECIMAL          pTEXTSTRING, ebx
                                                    ADDCHAR                 pTEXTSTRING, "."
                                                    ADDTEXTHEX              pTEXTSTRING, di
                                                    invoke  WriteMemoryToFile, addr textstring, [currentMachine.bank_ptrs+ebx*4], 16384

                                                    inc     esi
                                            .endw
                                    .endif

                          ; ============================
                            case$   "snowfloat"
                                    xor     snow_float, TRUE
                                    .if     !ZERO?
                                            invoke  Cmd_AddHistoryBox, SADD ("Snow float: Enabled")
                                    .else
                                            invoke  Cmd_AddHistoryBox, SADD ("Snow float: Disabled")
                                    .endif

                          ; ============================
                            IFDEF   DEBUGBUILD
                            case$   "test"
                              .data?
                                    lptestmem   DWORD   ?
                                    testlen     DWORD   ?
                              .code
                                    mov     lptestmem, AllocMem (65536+65536)
                                    .if     lptestmem == 0
                                            invoke  Cmd_AddHistoryBox, SADD ("Out of memory.")
                                    .else
;                                            memcpy  addr Bank5, lptestmem, 49152
                                            mov     testcount1, $fnc (zx7_compress, currentMachine.bank2, 32768, lptestmem)

                                            invoke  Cmd_AddHistoryBox, str$ (testcount1)

                                            mov     esi, lptestmem
                                            add     esi, 65536
                                            mov     testcount2, $fnc (Encode, lptestmem, testcount1, esi)

                                            invoke  Cmd_AddHistoryBox, str$ (testcount2)

                                            mov     testcount2, $fnc (Encode, currentMachine.bank2, 32768, esi)

                    invoke  WriteMemoryToFile, SADD ("E:\zEncoded.bin"), esi, testcount2

;                                            mov     testcount1, $fnc (CountZeroBits, lptestmem, testlen)
;                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
;                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "No filter 0-bit count: "
;                                            ADDTEXTDECIMAL      pTEXTSTRING, testcount1
;                                            invoke  Cmd_AddHistoryBox, addr textstring

                                            FreeMem lptestmem
                                    .endif
                            ENDIF
                          ; ============================

                            case$   "asm"
                                    ifc     have_pasmo eq 0 then jmp CmdParser_Error

                                    .if     $fnc (CreateTempFilename, addr asmsourcefile, SADD ("asmsrcline"), SADD ("asm")) == FALSE
                                            invoke  ShowMessageBox, hWnd, SADD ("CreateTempFilename failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                            jmp     @@asmcmdexit
                                    .endif
                                    ;ADDMESSAGEPTR_DBG   addr asmsourcefile ; adds asm source path/name message

                                    ; generate an initial ORG directive source line so relative jumps work
                                    movzx   ebx, Z80PC
                                    mov     assemblersourcecode, 0
                                    invoke  szMultiCat, 3, addr assemblersourcecode, CTXT (" org "), str$ (ebx), addr chars_newline

                                    ; move to first char after "asm" command
                                    lea     esi, cmd_parser_buffer-1
                                    mov     al, "m"
                                @@: inc     esi
                                    cmp     al, [esi]
                                    jne     @B
                                    inc     esi

                                @@: lodsb
                                    cmp     al, " "
                                    je      @B
                                    cmp     al, 9
                                    je      @B

                                    dec     esi

                                    or      al, al
                                    je      CmdParser_Error

                                    mov     lpUserAsmSrc, esi   ; ptr to asm source line in "asm" command

                                    ; now write the user's source line to our file for assembling
                                    invoke  szMultiCat, 3, addr assemblersourcecode, addr char_space, esi, addr chars_newline
                                    ;invoke  WriteMemoryToFile, SADD ("E:\zzz.txt"), addr assemblersourcecode, len (addr assemblersourcecode)   ; when we want to see generated source
                                    .if     $fnc (WriteMemoryToFile, addr asmsourcefile, addr assemblersourcecode, len (addr assemblersourcecode)) == 0
                                            ADDMESSAGE_DBG  "Error writing assembler source file"
                                            jmp     @@asmcmdexit
                                    .endif

                                    hPasmoStdOut    equ     <temp1>

                                    invoke  GetCurrentDirectory, sizeof tempcurdir, addr tempcurdir ; preserve current currdir

                                    invoke  ExtractFilePath, addr asmsourcefile, addr asmsourcefilePath
                                    invoke  ExtractFileName, addr asmsourcefile, addr asmsourcefileName

                                    strncpy addr asmsourcefileName, addr asmsourcefileBin,    sizeof asmsourcefileBin
                                    strncpy addr asmsourcefileName, addr asmsourcefileSymbol, sizeof asmsourcefileSymbol
                                    strncpy addr asmsourcefileName, addr asmsourcefileErr,    sizeof asmsourcefileErr

                                    invoke  @@AddExtension, addr asmsourcefileBin,    CTXT ("bin")
                                    invoke  @@AddExtension, addr asmsourcefileSymbol, CTXT ("symbol")
                                    invoke  @@AddExtension, addr asmsourcefileErr,    CTXT ("err")

                                    .if     $fnc (SetCurrentDirectory, addr asmsourcefilePath) == 0
                                            invoke  ShowMessageBox, hWnd, SADD ("SetCurrentDirectory failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                            jmp     @@asmcmdexit
                                    .endif

                                    mov     byte ptr tempfilepath, 0
                                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, offset appPath, SADD ("pasmo.exe", 34, " --alocal --err --name code ")

                                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileName,   addr char_quote_space  ; "<srcfile>.asm" + " "
                                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileBin,    addr char_quote_space  ; "<srcfile>.bin" + " "
                                    invoke  szMultiCat, 3, addr tempfilepath, addr char_quote, addr asmsourcefileSymbol, addr char_quote        ; "<srcfile>.symbol"

                                    ifdef   DEBUGBUILD
                                            ;invoke  Cmd_AddHistoryBox, addr tempfilepath
                                    endif

                                    ;mov     DummyMem, 0
                                    ;invoke  szMultiCat, 2, addr DummyMem, CTXT ("Assembling: "), addr asmsourcefileName
                                    ;invoke  Cmd_AddHistoryBox, addr DummyMem


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
                                                    invoke  ShowMessageBox, hWnd, SADD ("CreateProcess failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                            .endif

                                            invoke  CloseHandle, hPasmoStdOut

                                            hStdOutFileMem  equ     <temp2>
                                            hStdOutFileLen  equ     <temp3>
                                            .if     $fnc (ReadFileToMemory, addr asmsourcefileErr, addr hStdOutFileMem, addr hStdOutFileLen) != 0
                                                    .if     hStdOutFileLen > 0
                                                            ; we have assembly errors
                                                            textlineptr equ     temp4

                                                            ; output the user source line with error
                                                            invoke  Cmd_AddHistoryBox, lpUserAsmSrc

                                                            m2m     textlineptr, hStdOutFileMem
                                                            .while  TRUE
                                                                    .if     $fnc (ReadTextLine, addr textlineptr, addr DummyMem) != 0
                                                                            ; don't output error lines referencing our temp source file (error in line x of file:"name")
                                                                            .if     $fnc (InString, 1, addr DummyMem, SADD ("asmsrcline")) == 0
                                                                                    invoke  Cmd_AddHistoryBox, addr DummyMem
                                                                            .endif
                                                                    .else
                                                                            .break
                                                                    .endif
                                                            .endw
                                                    .else
                                                            ; assembled without errors
                                                            invoke  Cmd_AddHistoryBox, CTXT ("Assembled: No Errors")
                                                            asmBinMem   equ     <temp4>
                                                            asmBinLen   equ     <temp5>
                                                            .if     $fnc (ReadFileToMemory, addr asmsourcefileBin, addr asmBinMem, addr asmBinLen) != 0

                                                                    mov     esi, asmBinMem
                                                                    mov     bx, Z80PC

                                                                    .while  asmBinLen > 0
                                                                            invoke  WriteZ80Byte, bx, byte ptr [esi]
                                                                            inc     bx
                                                                            inc     esi
                                                                            dec     asmBinLen
                                                                    .endw

                                                                    invoke  GlobalFree, asmBinMem
                                                                    invoke  UpdateDisassembly
                                                            .else
                                                                    invoke  ShowMessageBox, hWnd, SADD ("Error reading assembled binary file"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                                            .endif
                                                    .endif
                                                    invoke  GlobalFree, hStdOutFileMem
                                                    invoke  DeleteFile, addr asmsourcefileErr
                                                    invoke  DeleteFile, addr asmsourcefileName
                                                    invoke  DeleteFile, addr asmsourcefileSymbol
                                                    invoke  DeleteFile, addr asmsourcefileBin
                                            .endif
                                    .else
                                            invoke  ShowMessageBox, hWnd, SADD ("CreateFile failed"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                    .endif

                                    invoke  SetCurrentDirectory, addr tempcurdir    ; restore current currdir on exit

                    @@asmcmdexit:

                          ; ============================
                            case$   "asmcontend"
                                    passes = 3
                                    pass = 1

                                    repeat  passes

                                    z80_assembler   offset DummyMem

    im2table    equ     0be00h
                                    z80             org     32768

                                    z80             di
                                    z80             ld      (oldsp+1),sp

                                    z80             fillmem im2table,257,0bfh

                                    z80             ld      sp,0be00h

                                    z80             ld      hl,0E9FDh   ; jp (iy)
                                    z80             ld      (0bfbfh),hl

                                    z80             call    3435
                                    z80             opencrt 2

                                    z80             for     w, 0, 7
                                    z80                     ld      a,(w)
                                    z80                     call    page_ram

                                    z80                     call    swap_bank_code

                                    z80                     ld      hl,0c000h
                                    z80                     ld      d,h
                                    z80                     ld      e,l

;                                    z80             breakpoint
                                    z80                     ld      a,high im2table
                                    z80                     ld      bc,0
                                    z80                     ei
                                    z80                     halt

                                    z80                     ld      i,a
                                    z80                     im      2
                                    z80                     ld      iy,im2_pre
                                    z80                     halt

                                    z80                     ld      iy,im2_main
                                    z80                     call    -bank_code_sizeof

                                    z80                     call    set_im1

                                    z80                     call    swap_bank_code

                                    z80                     xor     a
                                    z80                     call    page_ram

                                    z80                     crt     "RAM "
                                    z80                     ld      a,(w)
                                    z80                     crt     a, ": ", bc, " loops - "
                                    z80                     ld      h,b
                                    z80                     ld      l,c
                                    z80                     ld      de,1655
                                    z80                     or      a
                                    z80                     sbc     hl,de
                                    z80                     jr      c,@F
                                    z80                     crt     "un"
                                    z80 @@:                 crt     "contended"
                                    z80                     crt     13
                                    z80             next    w

                                    z80 oldsp:      ld      sp,0

                                    z80             ld      hl,2758h
                                    z80             exx
                                    z80             ret

                                    z80 swap_bank_code:
                                    z80             push    bc
                                    z80             push    de
                                    z80             push    hl
                                    z80             ld      hl,-bank_code_sizeof
                                    z80             ld      de,bank_code
                                    z80             ld      b,bank_code_sizeof
                                    z80 @@:         ld      c,(hl)
                                    z80             ld      a,(de)
                                    z80             ld      (hl),a
                                    z80             ld      a,c
                                    z80             ld      (de),a
                                    z80             inc     hl
                                    z80             inc     de
                                    z80             djnz    @B
                                    z80             pop     hl
                                    z80             pop     de
                                    z80             pop     bc
                                    z80             ret

                                    z80 bank_code:  ldi
                                    z80             inc     bc
                                    z80             inc     bc
                                    z80             jr      bank_code
                                    bank_code_sizeof    equ z80_PC - z80lab_bank_code

                                    z80 page_ram:   push    bc
                                    z80             ld      bc,7ffdh
                                    z80             or      16
                                    z80             ld      (23388),a
                                    z80             out     (c),a
                                    z80             pop     bc
                                    z80             ret

                                    z80 set_im1:    di
                                    z80             ld      iy,23610
                                    z80             ld      a,03fh
                                    z80             ld      i,a
                                    z80             im      1
                                    z80             ei
                                    z80             ret

                                    z80 im2_pre:    nop
                                    z80             ei
                                    z80             reti

                                    z80 im2_main:   pop     af  ; drop interrupt return address to bank_code loop
                                    z80             ei
                                    z80             reti

                                    z80             defw    w

                                    pass = pass + 1
                                    endm

                                    mov     testcount1, $fnc (z80_getobjectlength)
                                    invoke  MemoryCopy, addr DummyMem, currentMachine.bank2, testcount1
                                    invoke  Cmd_AddHistoryBox, str$ (testcount1)


                          ; ============================
                            case$   "testeval"
                                    passes = 3
                                    pass = 1

                                    repeat  passes

                                    z80_assembler   offset DummyMem

                                    z80             org     32768

;                                    z80             call    3435
                                    z80             opencrt 2

                                    z80             ld      hl,5+10*20
                                    z80             crt     "5+10*20 = ", hl, 13

                                    z80             ld      hl,200-5*5
                                    z80             crt     "200-5*5 = ", hl, 13

                                    z80             ld      hl,2+2*6/(4/2)
                                    z80             crt     "2+2*6/(4/2) = ", hl, 13

                                    z80             ld      hl,-10000+38
                                    z80             crt     "-10000+38 = $"
                                    z80             crthex16 hl
                                    z80             crt     13

                                                    mov     al, z80registers.r
                                    z80             ld      c,al   ; return the core's current R register to BASIC
                                    z80             ld      b,0
                                    z80             ret

                                    z80             ld      hl,-1
                                    z80             ld      a,-1
                                    z80             ld      hl,-bank_code_sizeof
                                    z80             ld      (hl),201
                                    z80             call    -bank_code_sizeof
                                    z80             ld      hl,65536*32 shl 31 * 1024
                                    z80             ld      de,bank_code
                                    z80             ld      b,bank_code_sizeof
                                                    mov     ah, z80registers.i
                                                    mov     al, z80registers.r
                                    z80             ld      bc,ax   ; return the core's current IR regs to BASIC
                                    z80             ret

                                    z80 bank_code:  ldi
                                    z80             inc     bc
                                    z80             nop
                                    z80             jr      bank_code
                                    z80 end_code:
                                    bank_code_sizeof    equ z80_PC - z80lab_bank_code


                                    pass = pass + 1
                                    endm

                                    mov     testcount1, $fnc (z80_getobjectlength)
                                    invoke  MemoryCopy, addr DummyMem, currentMachine.bank2, testcount1
                                    invoke  Cmd_AddHistoryBox, str$ (testcount1)

                          ; ============================
                            case$   "+3"
                                    passes = 3
                                    pass = 1

                                    repeat  passes

                                    z80_assembler   offset DummyMem
    p3_im2table equ     0be00h

                                    z80             org     32768

                                    z80             fillmem p3_im2table,257,0bfh

                                    z80             ld      a,0c3h
                                    z80             ld      hl,im2_isr
                                    z80             ld      (0bfbfh),a
                                    z80             ld      (0bfc0h),hl

                                    z80             halt
                                    z80             ld      a,high p3_im2table
                                    z80             ld      i,a
                                    z80             im      2

                                    z80             ld      bc,254

                                    z80 mloop1:     halt

                                    z80             ld      a,7
                                    z80             ld      e,5

                                    z80 iloop1:     out     (c),a       ; border 7

                                    z80             in      d,(c)
                                    z80             djnz    iloop1

                                    z80             dec     e
                                    z80             jr      nz,iloop1

                                    z80             out     (c),e       ; border 0

                                    z80             in      a,(c)
                                    z80             and     31
                                    z80             cp      31
                                    z80             jr      z,mloop1

                                    z80 set_im1:    di
                                    z80             ld      iy,23610
                                    z80             ld      a,03fh
                                    z80             ld      i,a
                                    z80             im      1
                                    z80             ei
                                    z80             ret

                                    z80 im2_isr:    nop
                                    z80             nop
                                    z80             ei
                                    z80             reti

                                    pass = pass + 1
                                    endm

                                    mov     testcount1, $fnc (z80_getobjectlength)
                                    invoke  MemoryCopy, addr DummyMem, currentMachine.bank2, testcount1
                                    invoke  Cmd_AddHistoryBox, str$ (testcount1)

                          ; ============================
                            case$   "irtest"
                                    passes = 3
                                    pass = 1

                                    repeat  passes

                                    z80_assembler   offset DummyMem

                                    z80             org     32768

                                    z80             ld      (oldsp),sp
                                    z80             ld      sp,0

                                    z80             halt

                                    z80             ld      hl,loop
                                    z80             ld      de,550
                                    z80             ld      bc,0

                                    z80             ld      a,251
                                    z80             breakpoint
                                    z80             ex      af,af

                                    z80 loop:       dec     de
                                    z80             ld      a,e
                                    z80             ld      r,a

                                    z80             ex      af,af
                                    z80             xor     8
                                    z80             ld      (int_opcode),a
                                    z80             ex      af,af
                                    z80 int_opcode: nop

                                    z80             or      d
                                    z80             jr      z,exit

                                    z80             ld      a,r
                                    z80             jp      m,flipreg

                                    z80             jp      pe,xorc
                                    z80             jp      po,xorb
                                    z80             jr      exit

                                    z80 xorb:       xor     b
                                    z80             ld      b,a
                                    z80             jp      (hl)

                                    z80 xorc:       xor     c
                                    z80             ld      c,a
                                    z80             jp      (hl)

                                    z80 flipreg:    ld      i,a
                                    z80             breakpoint
                                    z80             xor     a
                                    z80             ld      a,i
                                    z80             jp      po,xorc
                                    z80             jp      pe,xorb

                                    z80 exit:
                                    z80             breakpoint

                                    z80             di
                                    z80             ld      sp,(oldsp)
                                    z80             ld      a,63
                                    z80             ld      i,a
                                    z80             ei
                                    z80             ret

                                    z80 oldsp:      dw      0

                                    pass = pass + 1
                                    endm

                                    mov     testcount1, $fnc (z80_getobjectlength)
                                    invoke  MemoryCopy, addr DummyMem, currentMachine.bank2, testcount1
                                    invoke  Cmd_AddHistoryBox, str$ (testcount1)

                          ; ============================
                            case$   "ff01"
                                    passes = 3
                                    pass = 1

                                    repeat  passes

                                    z80_assembler   offset DummyMem

                                    z80             org     32768

                                    z80             breakpoint
                                    z80             ld      bc,0ff01h
                                    z80             ld      hl,60000/26

                                    z80 mloop1:     halt

                                    z80             di

                                    z80 loop:       in      d,(c)

                                    z80             dec     l
                                    z80             jp      nz,loop

                                    z80             dec     h
                                    z80             jp      p,loop

                                    z80             ei
                                    z80             ret

                                    pass = pass + 1
                                    endm

                                    mov     testcount1, $fnc (z80_getobjectlength)
                                    invoke  MemoryCopy, addr DummyMem, currentMachine.bank2, testcount1
                                    invoke  Cmd_AddHistoryBox, str$ (testcount1)

                          ; ============================
                            case$   "ops"
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Z80 opcodes executed: "
                                    ADDTEXTDECIMAL  pTEXTSTRING, currentMachine.opcodes_executed
                                    invoke  Cmd_AddHistoryBox, addr textstring

                                    mov     currentMachine.opcodes_executed, 0

                          ; ============================
                            case$   "sha256"
                                	invoke  SHA256Init
                                	invoke  SHA256Update, offset Rom_Plus3, 65536
                                	invoke  SHA256Final

                                	invoke  HexEncode, eax, SHA256_DIGESTSIZE, addr DummyMem
                                    invoke  Cmd_AddHistoryBox, addr DummyMem
                                    ADDMESSAGEPTR   addr DummyMem

                          ; ============================
                            case$   "md5"
                                    invoke  MD5Init
                                    invoke  MD5Update, offset Rom_Plus3, 65536
                                    invoke  MD5Final
                                    invoke  HexEncode, eax, MD5_DIGESTSIZE, addr DummyMem

                                    invoke  Cmd_AddHistoryBox, addr DummyMem
                                    ADDMESSAGEPTR   addr DummyMem

                          ; ============================
                            case$   "zero"
                                    hZeroCmdWin     equ     <temp1>
                                    hZeroCmdFile    equ     <temp2>

                                    .if     $fnc (FindWindow, NULL, SADD ("Zero"))
                                            mov     hZeroCmdWin, eax

                                            ; CreateTempFilename  lpTempFilename, lpSuffix, lpExt

                                            .if     $fnc (CreateTempFilename, addr tempfilepath, SADD ("_send2zero"), SADD ("szx"))
                                                    .if     $fnc (CreateFile, addr tempfilepath, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE
                                                            mov     SnapFH, eax

                                                            call    Save_SZXFormat
                                                            invoke  CloseHandle, SnapFH
                                                            mov     SnapFH, 0

                                                            lea     edx, tempfilepath   ; our snapshot filename
                                                            mov     ecx, len (edx)
                                                            inc     ecx                 ; + null terminator

                                                            mov     hCopyDataStruct.COPYDATASTRUCT.dwData, "SNAP"
                                                            mov     hCopyDataStruct.COPYDATASTRUCT.cbData, ecx
                                                            mov     hCopyDataStruct.COPYDATASTRUCT.lpData, edx

                                                            invoke  SendMessage, hZeroCmdWin, WM_COPYDATA, CommandParserDLG.hWnd, addr hCopyDataStruct

                                                            invoke  DeleteFile,  addr tempfilepath
                                                    .endif
                                            .endif
                                    .endif

                            else$
                                    jmp     CmdParser_Error ; unknown command
                    endsw$

                    ; successfully executed commands are added into the command parser's history box
;                    invoke  Cmd_AddHistoryBox, addr cmd_parser_buffer

                    ; and update stuff that might be affected by commands
                    invoke  UpdateDebugDisplay
                    invoke  UpdateDebugger
                    invoke  PopulateMemoryDlg
                    invoke  SetPagingInfo
                    ret

    CmdParser_Error:
                    ; reinstate edit text for user editing
                    invoke  CmdParser_SetEditText, addr cmd_parser_buffer
                    ret

CmdParser_Execute   endp

.data?
even
crc_16              dw  ?

.code
Init_CRC16              proc
                        mov     crc_16, -1
                        ret
Init_CRC16              endp

Calc_CRC16_Data         proc    uses    ebx esi edi,
                                lpData: DWORD, Len: DWORD

                        invoke  Init_CRC16

                        mov     esi, lpData
                        mov     ebx, Len
                        .while  ebx > 0
                                mov     al, [esi]
                                inc     esi
                                invoke  Calc_CRC16_Byte, al

                                dec     ebx
                        .endw

                        mov     ax, crc_16
                        ret
Calc_CRC16_Data         endp

Calc_CRC16_Byte         proc    uses        ebx esi edi,
                                crcbyte:    BYTE

                        mov     al, crcbyte
                        mov     dx, crc_16

; CRC-16/CITT for 8080/Z80
; On entry HL = old CRC, A = byte
; On exit HL = new CRC, A,B,C undefined

                        xor     al, dh
                        mov     bl, al
                        mov     cl, dl
                        ror     al, 4
                        mov     dl, al
                        and     al, 0fh
                        mov     dh, al
                        xor     al, bl
                        mov     bl, al
                        xor     al, dl
                        and     al, 0f0h
                        mov     dl, al
                        xor     al, cl
                        add     dx, dx
                        xor     al, dh
                        mov     dh, al
                        mov     al, dl
                        xor     al, bl
                        mov     dl, al

                        mov     crc_16, dx

                        ret
Calc_CRC16_Byte         endp

Cmd_AddHistoryBox   proc    uses        esi ebx,
                            newstring:  DWORD

                    mov     ebx, $fnc (GetDlgItem, CommandParserDLG.hWnd, IDC_COMMAND_HISTORY)

                    ; if the history box has > 20 items, delete item 0
                    .if     $fnc (SendMessage, ebx, RT_GETCOUNT, 0, 0) > 20
                            invoke  SendMessage, ebx, RT_DELETESTRING, 0, 0
                    .endif

                    mov     esi, $fnc (SendMessage, ebx, RT_ADDSTRING, NULL, newstring) ; returns index of new string
;                    invoke  SendMessage, ebx, RT_SETCURSEL, esi, 0                      ; new string becomes current selection
                    ret

Cmd_AddHistoryBox   endp

CopySpecMemToTemp   proc    uses    esi ebx,
                            src:    DWORD,
                            msize:  DWORD

                    .if     msize > 0
                            mov     esi, AllocMem (msize)
                            .if     esi != 0
                                    push    esi

                                    mov     ebx, src
                                    .while  msize > 0
                                            call    MemGetByte
                                            mov     [esi], al
                                            inc     esi
                                            inc     bx
                                            dec     msize
                                    .endw

                                    pop     esi
                                    return  esi ; return address of allocated memory block
                            .endif
                    .endif

                    return  0               ; return memory allocation error (or size == 0)

CopySpecMemToTemp   endp

Cmd_Fetch_String    proc
                    inc     cmd_arg_num
                    invoke  ArgByNumber, addr cmd_parser_buffer, cmd_arg_ptr, cmd_arg_num, 0

                    mov     eax, cmd_arg_ptr
                    movzx   eax, byte ptr [eax]         ; eax = 0 for error, else valid string argument

                    add     cmd_arg_ptr, CMD_ARG_SIZE   ; advance to next arg dest pointer

                    or      eax, eax                    ; set zero flag on char in eax. set = error, else success
                    ret
Cmd_Fetch_String    endp

Cmd_Fetch_Numeric_Val proc

                    invoke  Cmd_Fetch_String
                    retcc   z                           ; exit now if error (no string argument)

                    sub     cmd_arg_ptr, CMD_ARG_SIZE   ; back to this string pointer

                    invoke  StringToDWord, cmd_arg_ptr, addr lpTranslated

                    mov     ecx, cmd_arg_ptr            ; where we will store the numeric value
                    add     cmd_arg_ptr, CMD_ARG_SIZE   ; advance to next arg dest pointer

                    .if     lpTranslated == TRUE
                            mov     [ecx], eax
                            cmp     eax, -1             ; reset zero flag to indicate success; value also returned in EAX
                            ret
                    .endif

                    xor     eax, eax                    ; set zero flag to indicate error
                    ret

Cmd_Fetch_Numeric_Val endp

Cmd_Fetch_Numeric   proc

                    invoke  Cmd_Fetch_Numeric_Val
                    retcc   z                           ; exit now if error

                    .if     eax <= 65535
                            cmp     eax, -1             ; reset zero flag to indicate success; also returns value in EAX
                            ret
                    .endif

                    xor     eax, eax                    ; set zero flag to indicate error

                    ret
Cmd_Fetch_Numeric   endp

Cmd_Fetch_Numerics  proc    count:  DWORD

                    cmp     count, 0
                    retcc   z                           ; return on error

                    .while  count > 0
                            invoke  Cmd_Fetch_Numeric
                            retcc   z                   ; return on error

                            dec     count
                    .endw

                    cmp     count, -1                   ; reset zero flag to indicate success
                    ret

Cmd_Fetch_Numerics  endp


CountByteRepeats    proc    uses    esi edi ebx,
                            lpMem:  DWORD,
                            Len:    DWORD

                    mov     esi, lpMem
                    mov     ebx, Len

                    ifc     ebx lt 2 then return 0

                    xor     ecx, ecx
                    xor     edx, edx

                    mov     al, [esi]
                    inc     esi
                    dec     ebx

                    .while  ebx > 0
                            cmp     al, [esi]
                            setz    dl
                            add     ecx, edx
                            mov     al, [esi]

                            inc     esi
                            dec     ebx
                    .endw

                    return  ecx

CountByteRepeats    endp

CountZeroBits       proc    uses    esi edi ebx,
                            lpMem:  DWORD,
                            Len:    DWORD

                    mov     esi, lpMem
                    mov     ebx, Len

                    xor     ecx, ecx

                    .while  ebx > 0
                            mov     al, [esi]
                            inc     esi
                            dec     ebx

                            mov     ah, 8
                    @loop:  shl     al, 1
                            cmc
                            adc     ecx, 0
                            dec     ah
                            jnz     @loop
                    .endw

                    return  ecx

CountZeroBits       endp

CreateXORData       proc    uses    esi edi ebx,
                            lpMem:  DWORD,
                            Len:    DWORD

                    mov     esi, lpMem
                    mov     ebx, Len

                    .while  ebx > 0
                            ifc     ebx lt 256 then mov edi, ebx else mov edi, 256
                            invoke  CreateTapeXORMask, esi, edi

                            add     esi, edi
                            sub     ebx, edi
                    .endw

                    ret

CreateXORData       endp

;0 = literal
;    next 4 bits is a literal nybble
;
;1 = use weighted table
;    next 2 bits offset into table
;
;Weighted table (0-3) stored from high to low frequency in data.

Encode              proc    uses    esi edi ebx,
                            lpSrc:  DWORD,
                            Len:    DWORD,
                            lpDest: DWORD

                    local   weighted[16]: DWORD ; 0-15
                    local   encoding[4]:  BYTE  ; 0-3

                    memclr  addr weighted[0], sizeof weighted
                    memclr  addr encoding[0], sizeof encoding

                    mov     esi, lpSrc
                    mov     ebx, Len

                    .while  ebx > 0
                            mov     cl, [esi]
                            inc     esi
                            dec     ebx

                            SETLOOP 2
                                    mov     al, cl
                                    shl     cl, 4

                                    shr     al, 4
                                    and     eax, 15
                                    inc     weighted[eax*4]
                            ENDLOOP
                    .endw

                    lea     edi, encoding[0]
                    SETLOOP 4
                            lea     edx, weighted[0]
                            xor     ecx, ecx

                            mov     ebx, 1

                            .while  ebx < 16
                                    mov     eax, weighted[ebx*4]
                                    .if     eax > [edx]
                                            mov     ecx, ebx
                                            lea     edx, weighted[ebx*4]
                                    .endif
                                    inc     ebx
                            .endw

                            mov     [edi], cl
                            mov     dword ptr [edx], 0

                            inc     edi
                    ENDLOOP

;                    invoke  Cmd_AddHistoryBox, str$ (ZeroExt (encoding[0]))
;                    invoke  Cmd_AddHistoryBox, str$ (ZeroExt (encoding[1]))
;                    invoke  Cmd_AddHistoryBox, str$ (ZeroExt (encoding[2]))
;                    invoke  Cmd_AddHistoryBox, str$ (ZeroExt (encoding[3]))

                    ; encode to lpDestMem
                    mov     edi, lpDest
                    mov     eax, dword ptr encoding[0]
                    stosd               ; store the 4 encoding bytes

                    mov     esi, lpSrc
                    mov     bx, 0       ; bh = bit count, bl = construction byte

                    .while  Len > 0
                            mov     ch, [esi]
                            inc     esi
                            dec     Len

                            SETLOOP 2
                                    mov     cl, ch
                                    shl     ch, 4

                                    shr     cl, 4
                                    mov     dl, 3   ; encoded nibs use 3 bits

                                    .if     cl == encoding[0]
                                            mov     cl, 100b shl 5
                                    .elseif cl == encoding[1]
                                            mov     cl, 101b shl 5
                                    .elseif cl == encoding[2]
                                            mov     cl, 110b shl 5
                                    .elseif cl == encoding[3]
                                            mov     cl, 111b shl 5
                                    .else
                                            shl     cl, 3   ; =0bbbb for literal
                                            mov     dl, 5   ; literals use 5 bits
                                    .endif

                                    ; move dl bits to output stream
                                    .while  dl > 0
                                            dec     dl

                                            shl     cl, 1
                                            rcl     bl, 1
                                            inc     bh
                                            and     bh, 7   ; do we have a byte yet?
                                            .if     ZERO?
                                                    mov     [edi], bl
                                                    inc     edi
                                            .endif
                                    .endw
                            ENDLOOP
                    .endw

                    .if     bh > 0      ; unwritten data?
                            mov     [edi], bl
                            inc     edi
                    .endif

                    sub     edi, lpDest
                    return  edi         ; return length of encoded data

Encode              endp


