
Get_PC_Log_Parent   PROTO
Log_Base16          PROTO   :DWORD,:WORD
Log_Newline         PROTO


WARN_SIZE_STEP      equ     20 * 1024 * 1024

align 16
Get_PC_Log_Parent   proc
                    .if     DebuggerActive == TRUE
                            mov     eax, Debugger_hWnd  ; debugger main window
                    .else
                            mov     eax, hWnd           ; specemu main window
                    .endif
                    ret
Get_PC_Log_Parent   endp

; brings up a file requester if lpFilename = NULL
align 16
Start_PC_Logging    proc    uses        ebx,
                            lpFilename: PTR

                    local   hParent:    HWND,
                            ofn:        OPENFILENAME

                    ifc     DoLogging eq TRUE then ret  ; exit immediately if already logging

                    mov     InitialLogOpcode, FALSE

                    mov     ebx, FALSE

                    .if     lpFilename == NULL
                            mov     hParent, $fnc (Get_PC_Log_Parent)

                            .if     $fnc (SaveFileName, hParent, SADD ("Save PC Log"), addr szLOGFilter, addr ofn, addr PCLog_Filename, addr LOGExt, 0) != 0
                                    .if     $fnc (AskOverwriteFile, addr PCLog_Filename, hParent, addr szWindowName) == TRUE
                                            mov     ebx, TRUE
                                    .endif
                            .endif
                    .else
                            strncpy lpFilename, addr PCLog_Filename, sizeof PCLog_Filename
                            mov     ebx, TRUE
                    .endif

                    .if     ebx
                            mov     PCLogFileStream, $fnc (CreateFileStream, addr PCLog_Filename, FSA_WRITE, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 16384)
                            .if     eax != -1
                                    mov     DoLogging, TRUE
                                    mov     PCLog_Filesize, 0
                                    mov     PCLog_Warnsize, WARN_SIZE_STEP

                                    mov     ax, zPC
                                    inc     ax
                                    mov     PrevzPC, ax ; ensure logging of first opcode. previous PC != PC

                                    mov     InitialLogOpcode, TRUE  ; initial log opcode has initial register values dumped
                            .endif
                    .endif

                    invoke  SetDebuggerLogButtonState
                    ret

Start_PC_Logging    endp

align 16
Stop_PC_Logging     proc

                    ifc     DoLogging eq FALSE then ret

                    invoke  Log_Newline
                    invoke  Log_Registers
                    invoke  CloseFileStream, PCLogFileStream

                    mov     DoLogging, FALSE

                    invoke  SetDebuggerLogButtonState
                    ret

Stop_PC_Logging     endp

align 16
SetDebuggerLogButtonState   proc    uses ebx

                    ifc     DebuggerActive eq FALSE then ret

                    invoke  CheckDlgButton, Debugger_hWnd, IDC_START_STOP_LOGGING_CHK, ZeroExt (DoLogging)

                    .if     DoLogging == TRUE
                            mov     ebx, CTXT ("Stop PC Trace")
                    .else
                            mov     ebx, CTXT ("Start PC Trace")
                    .endif

                    invoke  SetDlgItemText, Debugger_hWnd, IDC_START_STOP_LOGGING_CHK, ebx
                    ret

SetDebuggerLogButtonState   endp

align 16
Log_PC              proc    uses    ebx

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     DoLogging == TRUE

                          ; start PC logging code
                            mov     ax, zPC
                            .if     ax != PrevzPC

                                    .if     InitialLogOpcode    ; initial log opcode has initial register values dumped (this gets set back to TRUE at the start of each frame)
                                            invoke  Log_Newline
                                            invoke  Log_Registers
                                            invoke  Log_Newline
                                            mov     InitialLogOpcode, FALSE
                                    .endif

                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                                    invoke  Log_Base16, pTEXTSTRING, zPC

;                                    push    ebx
;                                    mov     bx, zPC
;                                    call    MemGetByte
;                                    ADDTEXTHEX pTEXTSTRING, al
;                                    pop     ebx
;                                    ADDCHAR pTEXTSTRING, 32

                                  ; log current tstate count
                                    ADDTEXTDECIMAL  pTEXTSTRING, totaltstates, ATD_SPACES

                                    ifdef   LOGOPCODES
                                            ADDCHAR pTEXTSTRING, 9
                                            mov     ax, zPC
                                            mov     Z80PC, ax
                                            invoke  DisassembleLine, pTEXTSTRING
                                    endif

                                    ADDCHAR pTEXTSTRING, 13, 10

;                                    mov     ecx, len (addr textstring)
                                    mov     ecx, $fnc (GETTEXTLEN, pTEXTSTRING)

                                    add     PCLog_Filesize, ecx

                                    invoke  WriteFileStream, PCLogFileStream, addr textstring, ecx

                                  ; warn on filesize of PC log file
                                    mov     eax, PCLog_Filesize
                                    .if     eax >= PCLog_Warnsize
                                            add     PCLog_Warnsize, WARN_SIZE_STEP

                                            pushad
                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                            ADDDIRECTTEXTSTRING     pTEXTSTRING, "Your PC log file size is now "

                                            invoke  IntDiv, PCLog_Filesize, 1024 * 1024

                                            ADDTEXTDECIMAL          pTEXTSTRING, eax
                                            ADDDIRECTTEXTSTRING     pTEXTSTRING, " MB."
                                            ADDCHAR                 pTEXTSTRING, 13
                                            ADDDIRECTTEXTSTRING     pTEXTSTRING, " Do you want to continue logging?"

                                            MouseOn
                                            mov     ebx, $fnc (Get_PC_Log_Parent)
                                            invoke  ShowMessageBox, ebx, addr textstring, addr szWindowName, MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON1

                                            .if     eax == IDNO
                                                    invoke  Stop_PC_Logging
                                                    invoke  ShowMessageBox, $fnc (Get_PC_Log_Parent), SADD ("PC logging has stopped."), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                            .endif

                                            MouseOff
                                            popad
                                    .endif

                            .endif
                          ; end PC logging code
                    .endif
                    ret
Log_PC              endp

align 16
Log_Registers       proc

                    local   textstring: TEXTSTRING,
                            pTEXTSTRING:DWORD

                    .if     DoLogging == TRUE

                          ; log all registers
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "PC: #"
                            mov     ax, zPC
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR     pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "SP: #"
                            mov     ax, z80registers._sp
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "IX: #"
                            mov     ax, z80registers.ix.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "IY: #"
                            mov     ax, z80registers.iy.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "HL: #"
                            mov     ax, z80registers.hl.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "HL': #"
                            mov     ax, z80registers.hl_.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "DE: #"
                            mov     ax, z80registers.de.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "DE': #"
                            mov     ax, z80registers.de_.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "BC: #"
                            mov     ax, z80registers.bc.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "BC': #"
                            mov     ax, z80registers.bc_.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "AF: #"
                            mov     ax, z80registers.af.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "AF': #"
                            mov     ax, z80registers.af_.w
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 13, 10

                            ADDDIRECTTEXTSTRING pTEXTSTRING, "IR: #"
                            mov     ah, z80registers.i
                            mov     al, z80registers.r
                            and     al, 127
                            or      al, z80registers.r_msb
                            ADDTEXTHEX  pTEXTSTRING, ax
                            ADDCHAR pTEXTSTRING, 9
                            ADDDIRECTTEXTSTRING pTEXTSTRING, "IM: #"
                            mov     al, z80registers.intmode
                            ADDTEXTHEX  pTEXTSTRING, al
                            ADDCHAR pTEXTSTRING, 13, 10

                            mov     ecx, len (addr textstring)
                            add     PCLog_Filesize, ecx

                            invoke  WriteFileStream, PCLogFileStream, addr textstring, ecx; len (addr textstring)

                          ; end log all registers
                    .endif
                    ret
Log_Registers       endp

align 16

Log_Base16          proc    lptextstring:   DWORD,
                            val16:          WORD

                    .if     ShowHex == TRUE
                            ADDTEXTHEX      lptextstring, val16
                    .else
                            ADDTEXTDECIMAL  lptextstring, val16, ATD_SPACES
                    .endif
                    ret
Log_Base16          endp

.const
Log_Newline_txt     db  13, 10

.code
align 16
Log_Newline         proc
                    invoke  WriteFileStream, PCLogFileStream, addr Log_Newline_txt, sizeof Log_Newline_txt
                    add     PCLog_Filesize, sizeof Log_Newline_txt
                    ret
Log_Newline         endp

