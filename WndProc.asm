
        RESETENUM   WM_USER + 2
        ENUM        WM_USER_WAVEIN
        ENUM        WM_USER_REMOTE_APP

align 16
WndProc proc    uses        ebx esi edi,
                hWin:       DWORD,
                uMsg:       DWORD,
                wParam:     DWORD,
                lParam:     DWORD

                local   var:        DWORD
                local   caW:        DWORD
                local   caH:        DWORD
                local   Rct:        RECT
                local   hDC:        DWORD
                local   Ps:         PAINTSTRUCT
                local   hMenuSub:   DWORD

                local   buffer1[128]: BYTE  ; these are two spare buffers
                local   buffer2[128]: BYTE  ; for text manipulation etc..

                local   textstring: TEXTSTRING,
                        pTEXTSTRING:DWORD

                cmp     SwitchingModes, TRUE
                je      wndproc_Default

                lea     esi, wndproc_table
                mov     eax, uMsg
                or      ebx, -1         ; end marker = -1

        @@:     mov     ecx, [esi]      ; message
                mov     edx, [esi+4]    ; message handler
                lea     esi, [esi+8]

                cmp     edx, ebx        ; end marker?
                je      wndproc_Default

                cmp     eax, ecx        ; our message?
                jne     @B

                jmp     edx             ; jump to message handler


wndproc_Default:invoke  DefWindowProc, hWin, uMsg, wParam, lParam
                ret


wndproc_MM_WIM_DATA:
                invoke  PostMessage, hWin, WM_USER_WAVEIN, wParam, lParam
                return  0

align 16
wndproc_WM_USER_WAVEIN:
                mov     edi, lParam
                mov     [edi].WAVEHDR.dwBytesRecorded, 0
                mov     [edi].WAVEHDR.dwFlags, 0
                mov     [edi].WAVEHDR.dwLoops, 0

                mov     eax, [edi].WAVEHDR.lpData
                sub     eax, offset cap_buffers
                mov     cap_writeposn, eax      ; latest write buffer offset used for resync

                invoke  waveInPrepareHeader, cap_hWaveIn, edi, sizeof WAVEHDR
                invoke  waveInAddBuffer,     cap_hWaveIn, edi, sizeof WAVEHDR
                return  0

align 16
wndproc_WM_USER_REMOTE_APP:
                ; commands from Remote...
                include C:\RadAsm\Masm\Projects\remote\EmuState.inc
                .data?
                align 4
                        EmuStateEx  EMUSTATEEX  <>
                .code

                MOVEB   macro   src:REQ, dest:REQ
                        mov     al, src
                        mov     dest, al
                        endm

                MOVEW   macro   src:REQ, dest:REQ
                        mov     ax, src
                        mov     dest, ax
                        endm

                mov     ax, zPC
                mov     EmuStateEx.PreStepPC, ax
                mov     Z80PC, ax

                INITSTRING addr textstring, addr pTEXTSTRING
                invoke  DisassembleLine, pTEXTSTRING
                strncpy addr textstring, addr EmuStateEx.disassembly, sizeof EmuStateEx.disassembly

                invoke  Remote_Single_Step

                mov     eax, totaltstates
                .if     eax < MACHINE.InterruptCycles
                        RENDERFRAME
                .endif

                mov     hCopyDataStruct.COPYDATASTRUCT.dwData, "STEP"

                lea     ecx, EmuStateEx
                assume  ecx: ptr EMUSTATEEX

                mov     hCopyDataStruct.COPYDATASTRUCT.lpData, ecx
                mov     hCopyDataStruct.COPYDATASTRUCT.cbData, sizeof EMUSTATEEX

                mov     eax, totaltstates
                mov     [ecx].state.tstates, eax
                MOVEW   zPC, [ecx].state.PC
                MOVEW   z80registers._sp, [ecx].state._SP
                MOVEW   z80registers.ix.w, [ecx].state.IX
                MOVEW   z80registers.iy.w, [ecx].state.IY
                MOVEW   z80registers.hl.w, [ecx].state.HL
                MOVEW   z80registers.de.w, [ecx].state.DE
                MOVEW   z80registers.bc.w, [ecx].state.BC
                MOVEW   z80registers.af.w, [ecx].state.AF
                MOVEW   z80registers.hl_.w, [ecx].state.HLalt
                MOVEW   z80registers.de_.w, [ecx].state.DEalt
                MOVEW   z80registers.bc_.w, [ecx].state.BCalt
                MOVEW   z80registers.af_.w, [ecx].state.AFalt
                MOVEW   z80registers.hl.w, [ecx].state.HL
                MOVEB   z80registers.i, [ecx].state.I
                GET_R   al
                mov     [ecx].state.R, al
                MOVEB   z80registers.intmode, [ecx].state.IM

                ; FIXME: fix for matching Zero emulator
                ifc    currentMachine.cpu_halted then inc [ecx].state.PC

                invoke  SendMessage, wParam, WM_COPYDATA, hWnd, addr hCopyDataStruct
                assume  ecx: nothing
                return  0

align 16
wndproc_WM_PAINT:
                .if     $fnc (GetUpdateRect, hWin, NULL, FALSE) != 0
                        invoke  RenderSpeccy, hWin
                .endif
                return 0

;wndproc_WM_ERASEBKGND:
;            return TRUE

; https://devblogs.microsoft.com/oldnewthing/20031001-00/?p=42343
; So if your program wants to detect whether the mouse has moved, you need to add a check in your WM_MOUSEMOVE that the mouse position is different from the position reported by the previous WM_MOUSEMOVE message.

align 16
wndproc_WM_MOUSEMOVE:
                mov     eax, lParam
                .if     eax != lastmousemovelParam
                        mov     lastmousemovelParam, eax

                        invoke  Tools1_MouseMove, hWin, wParam, lParam

                        .if     MenuIgnoreMouseMoveCnt > 0
                                dec     MenuIgnoreMouseMoveCnt
                                return  0
                        .endif

                        .if     FullScreenMode
                                mov     MenuTimeout, 0
                                ifc     MenuAttached eq FALSE then invoke AttachMenu, hWnd
                        .endif
                .endif
                return  0

align 16
wndproc_WM_CHAR:
        ; ====== keyup events ======

            mov     eax, lParam
            shl     eax, 2              ; bit 30 -> carry
            jc      wndproc_Default     ; exit if repeating key press

            IFDEF   KEYSTATE_INFO
                    mov     eax, wParam
                    and     eax, 255
                    ADDMESSAGEHEX   "WM_CHAR: ", eax
            ENDIF

            jmp     wndproc_Default

align 16
wndproc_WM_KEYDOWN:
              ; ====== keydown events ======

            mov     eax, lParam
            shl     eax, 2              ; bit 30 -> carry
            jc      wndproc_Default     ; exit if repeating key press

            IFDEF   KEYSTATE_INFO
                    mov     eax, wParam
                    and     eax, 255
                    ADDMESSAGEHEX   "WM_KEYDOWN: ", eax
            ENDIF

            switch  $fnc (GetKeyShiftState)
                    case    VSTATE_NONE
                            switch  wParam
                                    case    VK_INSERT
                                            invoke  RZX_Insert_Bookmark
        
                                    case    VK_DELETE
                                            invoke  RZX_Rollback
        
                                    case    VK_F1                      ; toggle max speed mode
                                            call    ToggleFullSpeed
        
                                    case    VK_F2                      ; load snapshot
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_LOADSNAPSHOT, NULL
        
                                    case    VK_F3                      ; insert tape
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_INSERTTAPE, NULL
        
                                    case    VK_F4                   ; toggle window/fullscreen modes
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_FULLSCREEN, NULL
        
                                    case    VK_F5                   ; F5 = Cause NMI, activates the Multiface if available
                                            mov     currentMachine.nmi, TRUE
        
                                    case    VK_F6                      ; F6 = Tape Browser
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_TAPEBROWSER, NULL
        
                                    case    VK_F7                      ; cycle palette
                                            inc     UserPalette
                                            .if     UserPalette > MAXPALETTES - 1   ; defined in DirectDraw.asm
                                                    mov     UserPalette, 0
                                            .endif
                                            invoke  SetSpectrumPalette, UserPalette
                                            RENDERFRAME
                                            invoke  Resync_Capture
        
                                    case    VK_F8                      ; Options
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_OPTIONS, NULL
        
                                    case    VK_F11                     ; start/stop tape
                                            invoke  StartStopTape
        
                                    case    VK_PAUSE                   ; pauses/resumes the emulation
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_PAUSE, NULL
        
                                    case    VK_ESCAPE               ; ESC = Debugger
                                            call    InitPort
        
                                            .if     (lParam != "BRK") && (EmuRunning == TRUE)   ; debugger traps always set lParam to "BRK"
                                                    mov     eax, MACHINE.FrameCycles
                                                    sub     eax, totaltstates
                                                    sub     eax, 200
                                                    invoke  nrandom, eax
                                                    add     eax, totaltstates
                                                    add     eax, 100
                                                    mov     RunTo_Cycle, eax
                                                    invoke  Set_RunTo_Condition, RUN_TO_CYCLE
                                            .else
                                                    call    HandleDebuggerDialog
                                                    invoke  Resync_Capture
                                            .endif
                            endsw

;                    case    VSTATE_SHIFT
;                    case    VSTATE_CONTROL
;                    case    VSTATE_SHIFT_CONTROL
            endsw

            jmp     wndproc_Default

align 16
wndproc_WM_KEYUP:           ; ====== keyup events ======

                            IFDEF   KEYSTATE_INFO
                                    mov     eax, wParam
                                    and     eax, 255
                                    ADDMESSAGEHEX   "WM_KEYUP: ", eax
                            ENDIF

;                            switch  wParam
;                            endsw
                            jmp     wndproc_Default

align 16
wndproc_WM_MENUCHAR:
                            return  MNC_CLOSE shl 16

align 16
wndproc_WM_SYSCHAR:         ; ====== system char events (ALT + Key) ======

                            mov     eax, lParam
                            shl     eax, 2              ; bit 30 -> carry
                            jc      wndproc_Default     ; exit if repeating key press

                            IFDEF   KEYSTATE_INFO
                                    mov     eax, wParam
                                    and     eax, 255
                                    ADDMESSAGEHEX   "WM_SYSCHAR: ", eax
                            ENDIF

                            call    InitPort

                            switch  wParam
                                    case    VK_RETURN
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_FULLSCREEN, NULL

                                    case    VK_1    ; zoom 100%
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_ZOOM100, NULL

                                    case    VK_2    ; zoom 200%
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_ZOOM200, NULL

                                    case    VK_3    ; zoom 300%
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_ZOOM300, NULL

                                    case    VK_4    ; zoom 400%
                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_ZOOM400, NULL

                                    case    VK_9
                                            invoke  BltFlip_Mirror_Horz

                                    case    VK_0
                                            invoke  BltFlip_Mirror_Vert
                            endsw
                            jmp     wndproc_Default

align 16
wndproc_WM_SYSKEYDOWN:      ; ====== system keydown events (ALT + Key) ======

                            mov     eax, lParam
                            shl     eax, 2              ; bit 30 -> carry
                            jc      wndproc_Default     ; exit if repeating key press

                            IFDEF   KEYSTATE_INFO
                                    mov     eax, wParam
                                    and     eax, 255
                                    ADDMESSAGEHEX   "WM_SYSKEYDOWN: ", eax
                            ENDIF

                            call    InitPort

                            switch  $fnc (GetKeyShiftState)
                                  ; ==============================================================================================
                                    case    VSTATE_NONE
                                            switch  wParam
                                                    case    VK_O
                                                            ; open file type
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_OPENFILETYPE, NULL

                                                    case    VK_F2
                                                            ; save snapshot
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_SAVESNAPSHOT, NULL

                                                    case    VK_F6
                                                            ; Soft Reset
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_RESET, NULL

                                                    case    VK_F11
                                                            ; rewind tape
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_REWINDTAPE, NULL

                                                    case    VK_L
                                                            ; load memory snapshot
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_LOADMEMSNAP, NULL

                                                    case    VK_S
                                                            ; save memory snapshot
                                                            invoke  SendMessage, hWin, WM_COMMAND, IDM_SAVEMEMSNAP, NULL

                                                    case    VK_C
                                                            ; toggle ULA artifacts
                                                            xor     ULA_Artifacts_Enabled, TRUE
                                                            invoke  SetDirtyLines

                                                    case    VK_P
                                                            ; paste clipboard text into auto-type buffer
                                                            switch  HardwareMode
                                                                    case    HW_128, HW_PLUS2, HW_PLUS2A, HW_PLUS3, HW_PENTAGON128
                                                                            .if     $fnc (ShowMessageBox, hWin, SADD ("Paste clipboard text into emulation?"), addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) == IDYES
                                                                                    .if     $fnc (OpenClipboard, hWin) != 0
                                                                                            .if     $fnc (IsClipboardFormatAvailable, CF_TEXT) != 0
                                                                                                    .if     $fnc (GetClipboardData, CF_TEXT) != NULL
                                                                                                            mov     hClipboardData, eax
                                                                                                            .if     $fnc (GlobalLock, hClipboardData) != NULL
                                                                                                                    mov     ebx, eax
                                
                                                                                                                    lea     edi, DummyMem
                                                                                                                    xor     ecx, ecx
                                
                                                                                                                    .while  ecx < 8191
                                                                                                                            mov     al, [ebx]
                                                                                                                            inc     ebx
                                                                                                                            .break  .if al == 0
                                
                                                                                                                            switch  al
                                                                                                                                    case    10
                                                                                                                                    .else
                                                                                                                                            mov     [edi], al
                                                                                                                                            inc     edi
                                                                                                                                            inc     ecx
                                                                                                                            endsw
                                                                                                                    .endw
                                                                                                                    mov     byte ptr [edi], 0   ; null terminator
                                
                                                                                                                    invoke  Set_RunTo_Condition, RUN_TO_AUTOLOADTAPE
                                                                                                                    invoke  Set_Autotype_Rom_Point  ; sets autotype ROM pointer and PC address
                                                                                                                    mov     autotype_stage, 0
                                                                                                                    mov     autotype_keybuffer, offset DummyMem
                                                                                                            .endif
                                                                                                    .endif
                                                                                            .endif
                                                                                            invoke  CloseClipboard
                                                                                    .endif
                                                                            .endif
                                                            endsw   ; /paste

;                                                    case    VK_G    ; save +D RAM image
;                                                            invoke  CreateFile, CTXT ("C:\PlusD_Ram.ram"), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
;                                                            .if     eax != INVALID_HANDLE_VALUE
;                                                                    mov     SnapFH, eax
;                                                                    invoke  WriteFile, SnapFH, addr gdos_ram, 8192, addr BytesSaved, NULL
;                                                                    invoke  CloseHandle, SnapFH
;                                                                    mov     SnapFH, 0
;                                                            .endif

                                                    IFDEF   ULATUNING
                                                    case    VK_ADD
                                                            inc     ULATune

                                                    case    VK_SUBTRACT
                                                            dec     ULATune

                                                    case    VK_MULTIPLY
                                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Machine: "
                                                            GETMODELNAME        ecx
                                                            ADDTEXTSTRING       pTEXTSTRING, ecx
                                                            ADDCHAR             pTEXTSTRING, 13
                                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "ULA Frame Start: "
                                                            ADDTEXTDECIMAL      pTEXTSTRING, MACHINE.ULAFrameStart
                                                            ADDCHAR             pTEXTSTRING, 13
                                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "ULA Offset: "
                                                            ADDTEXTDECIMAL      pTEXTSTRING, ULATune

                                                            invoke  ShowMessageBox, hWin, addr textstring, addr szWindowName, MB_OK or MB_ICONINFORMATION
                                                            invoke  Resync_Capture
                                                    ENDIF   ;/ULATUNING
                                            endsw
                                  ; ==============================================================================================
                                    case    VSTATE_SHIFT
                                            switch  wParam
                                                    case    VK_J
                                                            .if     rzx_mode == RZX_PLAY
                                                                    .if     rzx_streaming_enabled == TRUE
                                                                            invoke  Close_Streaming_RZX
                                                                    .else
                                                                            invoke  Create_Streaming_RZX
                                                                    .endif
                                                            .endif

                                                    IFDEF   WANTSOUND
                                                    case    VK_Q
                                                            .if     MuteSound == FALSE
                                                                    .if     AudioFH != 0
                                                                            CLEARSOUNDBUFFERS
                                                                            invoke  ShowMessageBox, hWin, SADD ("Do you want to end WAV recording in order to mute the sound?"), addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                                                            push    eax
                                                                            invoke  Resync_Capture
                                                                            pop     eax
                                                                            .if     eax == IDNO
                                                                                    jmp     wndproc_Default
                                                                            .endif
                                                                            call    CloseAudioFile
                                                                    .endif
                                                            .endif
                                
                                                            xor     MuteSound, TRUE
                                                            .if     MuteSound == TRUE
                                                                    CLEARSOUNDBUFFERS
                                                            .endif
                                                    ENDIF
                                
                                                    IFDEF   DEBUGBUILD
                                                    case    VK_I
                                                                    .if     Check_RunTo == TRUE
                                                                            mov     eax, CTXT ("Runto Active")
                                                                    .else
                                                                            mov     eax, CTXT ("Runto Inactive")
                                                                    .endif
                                                                    ADDMESSAGEPTR   eax
                                
                                                                    .if     rzx_mode == RZX_PLAY
                                                                            mov     eax, CTXT ("RZX PLAY")
                                                                    .elseif rzx_mode == RZX_RECORD
                                                                            mov     eax, CTXT ("RZX RECORD")
                                                                    .else
                                                                            mov     eax, CTXT ("RZX NONE")
                                                                    .endif
                                                                    ADDMESSAGEPTR   eax
                                
                                                                    movzx   eax, keyboard_hasfocus
                                                                    ADDMESSAGEDEC   "Has Keyboard Focus: ", eax
                                                    ENDIF
                                            endsw
                                  ; ==============================================================================================
;                                    case    VSTATE_CONTROL
;                                            switch  wParam
;                                            endsw
                                  ; ==============================================================================================
;                                    case    VSTATE_SHIFT_CONTROL
;                                            switch  wParam
;                                            endsw
                            endsw

                            ; If you intercept the WM_SYSKEYDOWN message, call DefWindowProc afterward. Otherwise, you will block the operating system from handling the command.
                            ; ALT menu navigation and ALT+F4 require DefWndProc for WM_SYSKEYDOWN messages.
                            jmp     wndproc_Default

align 16
wndproc_WM_SYSKEYUP:        ; ====== system keydown events (ALT + Key) ======

                            IFDEF   KEYSTATE_INFO
                                    mov     eax, wParam
                                    and     eax, 255
                                    ADDMESSAGEHEX   "WM_SYSKEYUP: ", eax
                            ENDIF

                            jmp     wndproc_Default

.data
rzx_rec_showREC             db      10101010b

.code
align 16
wndproc_WM_TIMER:
            switch  wParam
                    case    TIMER_1_SECOND
                            .if     rzx_flash_window_counter > 0
                                    dec     rzx_flash_window_counter
                                    .if     ZERO?
                                            invoke  FlashWindow, hWnd, TRUE ; reinvert window state back to non-flashed
                                    .endif
                            .endif

                            invoke  MW_Populate_Memory  ; re-populates main win memory viewer if enabled

                            .if     (FullScreenMode == TRUE) && (MenuAttached == TRUE)
                                    inc     MenuTimeout
                                    ifc     MenuTimeout gt 3 then invoke DetachMenu    ; timeout in seconds
                            .endif

                            .if     HardwareMode == HW_TC2048
                                    .if     (FramesPerSecond == 59) || (FramesPerSecond == 61)
                                            mov     FramesPerSecond, 60
                                    .endif
                            .else
                                    .if     (FramesPerSecond == 49) || (FramesPerSecond == 51)
                                            mov     FramesPerSecond, 50
                                    .endif
                            .endif

                            IFDEF   SHOW_FPS
                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            ADDTEXTSTRING           pTEXTSTRING, offset szWindowName
                            ADDDIRECTTEXTSTRING     pTEXTSTRING, " ["
                            ADDTEXTDECIMAL          pTEXTSTRING, FramesPerSecond
                            ADDDIRECTTEXTSTRING     pTEXTSTRING, " FPS]"
                            invoke  SetWindowText, hWin, addr textstring
                            ENDIF

                            invoke  IntMul, FramesPerSecond, 100
                            invoke  Div2Int, eax, MACHINE.FramesPerSecond
                            mov     FramesPerSecond, eax

                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                            mov     eax, FramesPerSecond
                            ADDTEXTDECIMAL          pTEXTSTRING, eax
                            ADDDIRECTTEXTSTRING     pTEXTSTRING, " %"
                            invoke  SetStatusPartText, mainwin_hStatus, statuspart_speed, addr textstring

                            .if     rzx_mode == RZX_PLAY
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING pTEXTSTRING, "RZX: "
                                    imul    eax, RZXPLAY.rzx_frame_counter, 100
                                    invoke  IntDiv, eax, RZXPLAY.rzx_max_playback_frames
                                    ifc     eax gt 99 then mov eax, 99
                                    ADDTEXTDECIMAL  pTEXTSTRING, ax
                                    ADDCHAR pTEXTSTRING, "%"
                                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, addr textstring

                            .elseif rzx_mode == RZX_RECORD
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING pTEXTSTRING, "RZX: "
                                    ror     rzx_rec_showREC, 1
                                    .if     CARRY?
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "REC"
                                    .endif
                                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, addr textstring

                            IFDEF   PACMAN
                            .elseif pacmode == PACMODE_RECORD
                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                    ADDDIRECTTEXTSTRING pTEXTSTRING, "PAC: "
                                    ror     rzx_rec_showREC, 1
                                    .if     CARRY?
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "REC"
                                    .endif
                                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, addr textstring

                            .elseif pacmode == PACMODE_PLAYBACK
                                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, SADD ("PAC: PLAY")
                            ENDIF

                            .else
                                    IFDEF   DEBUGBUILD
                                            invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, SADD ("Debug")
                                    ELSE
                                            invoke  SetStatusPartText, mainwin_hStatus, statuspart_rzx, SADD (" ")
                                    ENDIF
                            .endif


                            IFDEF   DEBUGBUILD
                                    invoke  FlashWindow, hWin, TRUE
                            ENDIF

                            mov     FramesPerSecond, 0  ; reset FPS counter every second
                            inc     Timer_1s_tickcount  ; increment our global 1s tick counter
            endsw
            return  0

align 16
wndproc_WM_NCLBUTTONDOWN:
                            ; The DefWindowProc function tests the specified point to find the location of the cursor and performs the appropriate action.
                            ; If appropriate, DefWindowProc sends the WM_SYSCOMMAND message to the window.
                            CLEARSOUNDBUFFERS
                            jmp     wndproc_Default

align 16
wndproc_WM_COPYDATA:
                            ; If the receiving application processes this message, it should return TRUE; otherwise, it should return FALSE.

                            ; retrieve filenames passed from new instances

                            ; wParam = calling application's main window handle
                            ; hWnd   = SpecEmu's main window handle

                            ; only accept files when debugger is non-active and there's no message box displayed
                            .if     (DebuggerActive == FALSE) && (MessageBoxDisplayed == FALSE)
                                    mov     esi, lParam
                                    assume  esi: PTR COPYDATASTRUCT

                                    .if     esi != 0
                                            .if     [esi].dwData == "SPEC"
                                                    .if     [esi].lpData != 0
                                                            strncpy [esi].lpData, addr szFileName, sizeof szFileName
                                                            invoke  ReadFileType, addr szFileName
                                                    .endif

                                            ; commands from Remote...
                                            .elseif [esi].dwData == "PAUS"
                                                    ifc     $fnc (InSendMessage) then invoke ReplyMessage, TRUE

                                                    ifc EmuRunning eq TRUE then invoke PauseResumeEmulation ; pause the emulator

                                                    mov     hCopyDataStruct.COPYDATASTRUCT.dwData, "PAUS"
                                                    mov     hCopyDataStruct.COPYDATASTRUCT.cbData, 0
                                                    mov     hCopyDataStruct.COPYDATASTRUCT.lpData, 0
                                                    invoke  SendMessage, wParam, WM_COPYDATA, hWnd, addr hCopyDataStruct

                                            .elseif [esi].dwData == "SNAP"
                                                    .if     [esi].lpData != 0
                                                            strncpy [esi].lpData, addr szFileName, sizeof szFileName
                                                            ifc     $fnc (InSendMessage) then invoke ReplyMessage, TRUE

                                                            invoke  ReadFileType, addr szFileName

                                                            mov     hCopyDataStruct.COPYDATASTRUCT.dwData, "SNAP"
                                                            mov     hCopyDataStruct.COPYDATASTRUCT.cbData, 0
                                                            mov     hCopyDataStruct.COPYDATASTRUCT.lpData, 0
                                                            invoke  SendMessage, wParam, WM_COPYDATA, hWnd, addr hCopyDataStruct

                                                            mov     RemoteStepCounter, 0
                                                    .endif

                                            .elseif [esi].dwData == "STEP"
                    				                ; post back to oneself and process asynchronously
                                                    ; ifc     $fnc (InSendMessage) then invoke ReplyMessage, TRUE
                                                    invoke  PostMessage, hWnd, WM_USER_REMOTE_APP, wParam, "STEP" ;[esi].dwData

                                                    inc     RemoteStepCounter
                                                    ADDMESSAGEDEC "STEP ", RemoteStepCounter
                                            .endif
                                    .endif

                                    assume  esi: NOTHING
                            .endif
                            invoke  Resync_Capture
                            return  TRUE

align 16
wndproc_WM_COMMAND:
    ;======== menu commands ========

        LOWORD  wParam
;        call    InitPort   ; esxdos requires space+reset to reinitialise

        switch  eax

            case    RECENTFILEMENUID..RECENTFILEMENUID+9
                    mov     ebx, eax
                    invoke  GetMenuString, MenuHandle, ebx, addr szFileName, MAX_PATH, MF_BYCOMMAND
                    invoke  ReadFileType, addr szFileName

            case    IDM_OPENFILETYPE                   ; open file
                    call    Speaker_Low
                    MouseOn
                    invoke  OpenFileType
                    RENDERFRAME
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_LOADSNAPSHOT                   ; load snapshot
                    call    Speaker_Low
                    MouseOn
                    invoke  LoadSnapshot, hWin
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_SAVESNAPSHOT                   ; save snapshot
                    MouseOn
                    invoke  SaveSnapshot, hWin
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_LOADMEMSNAP                    ; load memory snapshot
                    .if     rzx_mode == RZX_NONE
                            invoke  LoadMemorySnapshot, hWin
                            RENDERFRAME
                            invoke  Resync_Capture
                    .endif

            case    IDM_SAVEMEMSNAP                    ; save memory snapshot
                    invoke  SaveMemorySnapshot, hWin
                    invoke  Resync_Capture

            case    IDM_LOADIF2ROM
                    MouseOn
                    invoke  LoadIF2_ROM, hWin
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_LOADBINARYFILE                 ; load binary file
                    MouseOn
                    call    LoadBinaryDialog
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_SAVEBINARYFILE                 ; save binary file
                    MouseOn
                    call    SaveBinaryDialog
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_INSERTTAPE                     ; insert tape
                    call    Speaker_Low
                    MouseOn
                    invoke  InsertTape
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_EJECTTAPE                      ; eject tape
                    invoke  CloseTapeFile

            case    IDM_INSERTDISK_A                ; insert disk into Drive A:
                    MouseOn
                    mov     TargetDrive, 0          ; select A:
                    invoke  InsertDisk
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_INSERTDISK_B                ; insert disk into Drive B:
                    MouseOn
                    mov     TargetDrive, 1          ; select B:
                    invoke  InsertDisk
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_INSERTDISK_C                ; insert disk into Drive C:
                    MouseOn
                    mov     TargetDrive, 2          ; select C:
                    invoke  InsertDisk
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_INSERTDISK_D                ; insert disk into Drive D:
                    MouseOn
                    mov     TargetDrive, 3          ; select D:
                    invoke  InsertDisk
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_EJECTDISK_A
                    switch  HardwareMode
                            case    HW_PLUS3
                                    invoke  u765_EjectDisk, FDCHandle, 0
                            case    HW_PENTAGON128
                                    wd1793_EjectDisk        TRDOSHandle, 0
                            .else
                                    .if     PLUSD_Enabled == TRUE
                                            wd1793_EjectDisk        PLUSDHandle, 1  ; 1-based for +D units
                                    .endif

                                    .if     CBI_Enabled == TRUE
                                            wd1793_EjectDisk        CBIHandle, 0
                                    .endif
                    endsw

            case    IDM_EJECTDISK_B
                    switch  HardwareMode
                            case    HW_PLUS3
                                    invoke  u765_EjectDisk, FDCHandle, 1
                            case    HW_PENTAGON128
                                    wd1793_EjectDisk        TRDOSHandle, 1
                            .else
                                    .if     PLUSD_Enabled == TRUE
                                            wd1793_EjectDisk        PLUSDHandle, 2  ; 1-based for +D units
                                    .endif

                                    .if     CBI_Enabled == TRUE
                                            wd1793_EjectDisk        CBIHandle, 1
                                    .endif
                    endsw

            case    IDM_EJECTDISK_C
                    switch  HardwareMode
                            case    HW_PENTAGON128
                                    wd1793_EjectDisk        TRDOSHandle, 2
                            .else
                                    .if     CBI_Enabled == TRUE
                                            wd1793_EjectDisk        CBIHandle, 2
                                    .endif
                    endsw

            case    IDM_EJECTDISK_D
                    switch  HardwareMode
                            case    HW_PENTAGON128
                                    wd1793_EjectDisk        TRDOSHandle, 3
                            .else
                                    .if     CBI_Enabled == TRUE
                                            wd1793_EjectDisk        CBIHandle, 3
                                    .endif
                    endsw

            case    IDM_SAVESCREEN                     ; save screen
                    MouseOn
                    invoke  SaveScreenFile
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_EXIT                           ; exit
                    invoke  SendMessage, hWin, WM_SYSCOMMAND, SC_CLOSE, NULL

            case    IDM_ABOUT                          ; about
                    MouseOn
                    call    HandleAboutDialog
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_RESET                       ; Soft Reset
                    invoke  Close_RZX, 0, FALSE

                    invoke  GetUserConfig           ; gets user's current machine config
                    call    ResetSpectrum

            case    IDM_HARDRESET                   ; Hard Reset
                    invoke  Close_RZX, 0, FALSE

                    invoke  GetUserConfig           ; gets user's current machine config
                    mov     HardReset, TRUE
                    call    ResetSpectrum

            case    IDM_PAUSE                          ; Pause/Resume
                    call    InitPort
                    invoke  PauseResumeEmulation
                    ifc     EmuRunning eq TRUE then invoke Resync_Capture

            case    IDM_GENERATENMI                    ; Generate NMI
                    mov     currentMachine.nmi, TRUE

            case    IDM_1_75_MHZ..IDM_50_MHZ            ; set CPU clock speed
                    sub     eax, IDM_1_75_MHZ
                    dec     eax                         ; make range -1 to IDM_50_MHZ - 1
                    mov     CPU_Speed, al

            case    IDM_FULLSPEED                      ; toggle fullspeed mode
                    call ToggleFullSpeed

            case    IDM_ZOOM100
;                    ifc     FullScreenMode ne TRUE then invoke  SetClientSize, hWin, MACHINE.DisplayWidth, MACHINE.DisplayHeight
                    ifc     FullScreenMode ne TRUE then invoke SetClientSize, hWin, 320, 240

            case    IDM_ZOOM200
;                    .if     FullScreenMode != TRUE
;                            mov     esi, MACHINE.DisplayWidth
;                            mov     edi, MACHINE.DisplayHeight
;                            shl     esi, 1
;                            shl     edi, 1
;                            invoke  SetClientSize, hWin, esi, edi
;                    .endif
                    ifc     FullScreenMode ne TRUE then invoke SetClientSize, hWin, 320*2, 240*2

            case    IDM_ZOOM300
                    ifc     FullScreenMode ne TRUE then invoke SetClientSize, hWin, 320*3, 240*3

            case    IDM_ZOOM400
                    ifc     FullScreenMode ne TRUE then invoke SetClientSize, hWin, 320*4, 240*4

                  ; ULA palette selection
            case    IDM_SPECTRUMPALETTE
                    invoke  SetSpectrumPalette, PALETTE_SPECTRUM
                    RENDERFRAME

            case    IDM_GREENSCREENPALETTE
                    invoke  SetSpectrumPalette, PALETTE_GREENSCREEN
                    RENDERFRAME

            case    IDM_BLACKANDWHITEPALETTE
                    invoke  SetSpectrumPalette, PALETTE_GRAYSCALE
                    RENDERFRAME

            case    IDM_CUSTOMPALETTE
                    invoke  SetSpectrumPalette, PALETTE_CUSTOM
                    RENDERFRAME

            case    IDM_EDITCUSTOMPALETTE
                    MouseOn
                    invoke  EditCustomPalette
                    MouseOff
                    invoke  Resync_Capture

                  ; ULAplus palette selection
            case    IDM_ULAPLUS_AMBER
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_AMBER
                    RENDERFRAME

            case    IDM_ULAPLUS_C64
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_C64
                    RENDERFRAME

            case    IDM_ULAPLUS_DEMO
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_DEMO
                    RENDERFRAME

            case    IDM_ULAPLUS_GENERIC
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_GENERIC
                    RENDERFRAME

            case    IDM_ULAPLUS_GRADIENTS
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_GRADIENTS
                    RENDERFRAME

            case    IDM_ULAPLUS_GREENSCREEN
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_GREENSCREEN
                    RENDERFRAME

            case    IDM_ULAPLUS_PRIMARIES
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_PRIMARIES
                    RENDERFRAME

            case    IDM_ULAPLUS_RGB
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_RGB
                    RENDERFRAME

            case    IDM_ULAPLUS_RGB_ALT
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_RGB_ALT
                    RENDERFRAME

            case    IDM_ULAPLUS_STANDARD
                    invoke  EnableULAplusMode,    TRUE
                    invoke  SelectULAplusPalette, ULAPLUSPALETTE_STANDARD
                    RENDERFRAME

            case    IDM_DEBUGGER                       ; Debugger
                    invoke  PostMessage, hWnd, WM_KEYDOWN, VK_ESCAPE, "FK"

            case    IDM_POKEMEMORY                     ; Poke Memory
                    MouseOn
                    call    HandlePokeDialog
                    MouseOff
                    invoke  Resync_Capture

.data
szCheatTitle    db  "Cheats Finder Unavailable", 0
szCheatText     db  "In order to use the Cheats Finder, you must first save a snapshot to memory.", 13, 13
                db  "First, load a game in which you wish to find some cheats.", 13
                db  "Begin a new game, which will ensure that the Lives/Energy counters have been initialised, then "
                db  "select ",34,"Save Memory Snapshot",34," from the ",34,"File",34," menu to save a snapshot to memory.", 0

.code
            case    IDM_CHEATSFINDER                   ; cheats finder
                    MouseOn
                    .if     MemorySnapshotValid == FALSE
                            invoke  ShowMessageBox, hWin, addr szCheatText, addr szCheatTitle, MB_OK or MB_ICONWARNING
                    .else
                            call    HandleCompareDialog
                    .endif
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_FULLSCREEN                     ; toggle window/fullscreen modes
                    CLEARSOUNDBUFFERS
                    invoke  FlipDisplayMode
                    invoke  AttachMenu, hWnd

                    invoke  SetStatusPartSizes, mainwin_hStatus, hWin, addr statusdiffs, numStatusParts
                    invoke  SendMessage, mainwin_hStatus, WM_SIZE, 0, 0

                    invoke  Resync_Capture

            case    IDM_RECORDVIDEO                    ; toggle video frame recording
                    MouseOn
                    invoke  ToggleVideoRecording
                    MouseOff
                    invoke  Resync_Capture

            IFDEF   WANTSOUND
            case    IDM_RECORDAUDIO                    ; record audio to WAV file
                    .if     AudioFH != 0
                            call    CloseAudioFile
                    .else
                            MouseOn
                            invoke  OpenAudioFile
                            MouseOff
                            invoke  Resync_Capture
                    .endif
            ENDIF

            case    IDM_INSERTSAVETAPE                 ; insert tape for saving
                    MouseOn
                    invoke  InsertSaveTape
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_EJECTSAVETAPE                  ; eject save tape
                    call    CloseSaveTapeFile

; ====================================================================================================

            case    IDM_RZX_PLAY                        ; play an RZX recording
                    MouseOn
                    invoke  Open_RZX
                    MouseOff

            case    IDM_RZX_RECORD                      ; record a new RZX recording
                    MouseOn

                    .if     $fnc (Is_Pacman_Trapped)
                            invoke  ShowMessageBox, hWnd, SADD ("SpecEmu cannot record a PAC-MAN RZX file"), addr szWindowName, MB_OK
                            ret
                    .endif

                    invoke  Create_RZX, FALSE           ; no continue
                    MouseOff

            case    IDM_RZX_CONTINUE_RECORD             ; continue recording an existing RZX
                    MouseOn
                    invoke  Create_RZX, TRUE            ; allow continue
                    MouseOff

            case    IDM_RZX_STOP                        ; end RZX recording/playback
                    invoke  Close_RZX, 0, FALSE

            case    IDM_RZX_ADD_BOOKMARK                ; add a rollback bookmark
                    invoke  RZX_Insert_Bookmark

            case    IDM_RZX_ROLLBACK                    ; rollback recording
                    invoke  RZX_Rollback

            case    IDM_RZX_CLEANUP                     ; clean-up recording
                    invoke  RZX_Finalise, FALSE

            case    IDM_RZX_FINALISE                    ; finalise recording
                    invoke  RZX_Finalise, TRUE

; ====================================================================================================

            case    IDM_FIRSTMACHINE..IDM_LASTMACHINE   ; select hardware model
;                    mov     eax, MenuCode
                    sub     eax, IDM_FIRSTMACHINE       ; al = Hardware model
                    .if     al != HardwareMode
                            push    eax
                            invoke  GetUserConfig
                            pop     eax
                            mov     HardwareMode, al
                            invoke  SetUserConfig       ; store user's new machine config before resetting
                            call    ResetSpectrum
                    .endif

            case    IDM_OPTIONS                        ; Options property sheet
                    MouseOn
                    invoke  HandleOptionsDialog
                    MouseOff
                    invoke  Resync_Capture

            IFDEF   PACMAN
            case    IDM_PACMAN_FREEPLAYFROMSTART
                    invoke  Enable_Pacmode, PACMODE_FREEPLAY, 0

            case    IDM_PACMAN_FREEPLAYFROMLEVEL
                    invoke  GetNumericInput, hWin, hInstance, hIcon, SADD ("PAC-MAN Free Play From Level"), SADD ("Level (1 to 256):")
                    .if     (eax == TRUE) && (ecx >= 1) && (ecx <= 256)
                            dec     cl  ; down to 0-255 range
                            invoke  Enable_Pacmode, PACMODE_FREEPLAY, cl
                    .endif

            case    IDM_PACMAN_PERFECTPLAYFROMSTART
                    invoke  Enable_Pacmode, PACMODE_PLAYBACK, 0

            case    IDM_PACMAN_PERFECTPLAYFROMLEVEL
                    invoke  GetNumericInput, hWin, hInstance, hIcon, SADD ("PAC-MAN Free Play From Level"), SADD ("Level (1 to 256):")
                    .if     (eax == TRUE) && (ecx >= 1) && (ecx <= 256)
                            dec     cl  ; down to 0-255 range
                            invoke  Enable_Pacmode, PACMODE_PLAYBACK, cl
                    .endif
            ENDIF   ; /PACMAN

            case    IDM_INSTALLGENIE128
                    call    InstallGenie128

            case    IDM_SEBASIC_48K
                    invoke  LoadSZXStateFromMemory, addr sebasic_48k, sebasic_48k_size, addr LoadSZXStateCallback

            case    IDM_ASSEMBLER                       ; show/hide the assembler
                    invoke  ToggleAssemblerDialog

            case    IDM_CLEAR_MEM_MAP                   ; clear memory map
                    invoke  Clear_Mem_Map

            case    IDM_SAVE_MEM_MAP                    ; save memory map
                    MouseOn
                    invoke  Save_Memory_Map
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_TAPEBROWSER                    ; tape browser
                    MouseOn
                    call    HandleTapeBrowserDialog
                    MouseOff
                    invoke  Resync_Capture

            case    IDM_TOOLWINDOW1                    ; show/hide tool window 1
                    invoke  ToggleTools1Dialog
                    invoke  SetFocus, hWin

            case    IDM_MAINWINMEMORYVIEWER            ; show/hide main window's memory viewer
                    invoke  ToggleMainWinMemViewDialog

            case    IDM_ACCELERATETAPELOADING          ; accelerate tape loading
                    xor    FastTapeLoading, TRUE

            case    IDM_REALTAPEMODE                   ; real tape mode loading
                    invoke  Flip_RealTape_Mode

            case    IDM_STARTSTOPTAPE                  ; start/stop tape
                    invoke  StartStopTape

            case    IDM_REWINDTAPE                     ; rewind tape
                    call    RewindTZXTape

        endsw
        jmp     wndproc_Default

        ;====== end menu commands ======

align 16
wndproc_WM_DROPFILES:
                call    InitPort
                invoke  DragQueryFile, wParam, 0, addr szFileName, sizeof szFileName

                mov     TargetDrive, 0  ; dropped disk images go into Drive A:
                invoke  ReadFileType, addr szFileName

                invoke  DragFinish, wParam
                invoke  Resync_Capture
                return  0

align 16
wndproc_WM_CREATE:
                            ; If an application processes this message, it should return zero to continue creation of the window.
                            ; If the application returns –1, the window is destroyed and the CreateWindowEx or CreateWindow function returns a NULL handle.

                            ; IniProfile sets window dimensions in WindowRect structure
                            ; in this case: WindowRect.right = width, WindowRect.bottom = height
                            ; window height doesn't include toolbar height

                            mov     MenuHandle, $fnc (LoadMenu, hInstance, IDR_MAINMENU)
                            invoke  AttachMenu, hWin

                            IFNDEF  PACMAN
                            invoke  DeleteMenu, MenuHandle, IDM_PACMAN_MENU, MF_BYCOMMAND
                            ENDIF

                            mov     ToolBarHeight, $fnc (AddMainWinToolBar, hWin)
                            mov     StatusHeight,  $fnc (AddMainWinStatus, hWin)

                            invoke  SetClientSize, hWin, WindowRect.right, WindowRect.bottom

                            invoke  SetWindowPos, hWin, HWND_NOTOPMOST, WindowRect.left, WindowRect.top, 0, 0, SWP_NOSIZE

                          ; set window min/max values when sizing
                            invoke  SetRect,            addr winClientRect, 0, 0, 320, 240
                            invoke  AdjustWindowRectEx, addr winClientRect, dwStyle, TRUE, dwExStyle
                            mov     MinimumWidth,  @EVAL (winClientRect.right - winClientRect.left)
                            mov     MinimumHeight, @EVAL (winClientRect.bottom - winClientRect.top + ToolBarHeight + StatusHeight)

                          ; start 1 second interval timer
                            mov     TimerID_1sec, $fnc (SetTimer, hWin, TIMER_1_SECOND, 1000, NULL)
                            .if     eax == NULL
                                    FATAL   "Timer unavailable"
                            .endif

                          ; initialise global fonts
                            mov     gl_Courier_New_6, $fnc (CreateFontIndirect, addr Courier_New_6)
                            mov     gl_Courier_New_9, $fnc (CreateFontIndirect, addr Courier_New_9)

                            ;invoke  SetDropTarget, hWin

                            return  0

align 16
wndproc_WM_DISPLAYCHANGE:
                            call    InitPort
                            invoke  SetDirtyLines
                            invoke  Sleep, 10

                            .if     (SwitchingModes == TRUE) || (FullScreenMode == TRUE)
                                    ; caused by internal window/fullscreen toggle
                                    LOG     "--> Received WM_DISPLAYCHANGE because we invoked the window/fullscreen toggle"
                            .else
                                    LOG     "--> Received WM_DISPLAYCHANGE after system display change"
                                    mov     SwitchingModes, TRUE
                                    mov     eax, wParam     ; new bits per pixel setting for display
                                    mov     DesktopBPP, eax
            
                                    invoke  ShutdownDirectDraw
                                    invoke  InitDirectDraw
                                    invoke  InitSurfaces, hWin
                                    mov     SwitchingModes, FALSE
                            .endif
                            invoke  Resync_Capture
                            return  0

align 16
wndproc_WM_ENTERSIZEMOVE:
                            call    InitPort
                            CLEARSOUNDBUFFERS
                            mov     WindowSizeMove, TRUE
                            return  0

align 16
wndproc_WM_EXITSIZEMOVE:
                            mov     WindowSizeMove, FALSE
                            invoke  Resync_Capture
                            return  0


align 16
wndproc_WM_SIZE:
                            .if     mainwin_hToolBar != NULL
                                    invoke  SendMessage, mainwin_hToolBar, TB_AUTOSIZE, 0, 0
                            .endif

                            .if     mainwin_hStatus != NULL
                                    invoke  SetStatusPartSizes, mainwin_hStatus, hWin, addr statusdiffs, numStatusParts
                                    invoke  SendMessage, mainwin_hStatus, WM_SIZE, 0, 0
                            .endif

                            .if     hWnd != NULL
                                    UPDATEWINDOW
                            .else
                                    invoke  InvalidateRect, hWin, NULL, FALSE
                                    invoke  UpdateWindow,   hWin
                            .endif
                            return  0

align 16
wndproc_WM_SIZING:
                            ; An application should return TRUE if it processes this message.
                            LimitWindowWidth    MinimumWidth
                            LimitWindowHeight   MinimumHeight
                            return  TRUE

align 16
wndproc_WM_ENTERMENULOOP:
                call    InitPort

                mov     MenuNoUnattach, TRUE
                CLEARSOUNDBUFFERS

                IFDEF   PACMAN
                ; disable PAC-MAN main menu if ROMs aren't available
                .if     HavePacmanROMs == FALSE
                        invoke  EnableMenuItem, MenuHandle, IDM_PACMAN_MENU, MF_GRAYED or MF_BYCOMMAND
                .endif
                ENDIF

                invoke  PopulateRecentFilesMenu

                ; enable/check Tool Window 1 menu item
                ifc     FullScreenMode eq TRUE then mov ebx, MF_GRAYED or MF_BYCOMMAND else mov ebx, MF_ENABLED or MF_BYCOMMAND
                invoke  EnableMenuItem, MenuHandle, IDM_TOOLWINDOW1,         ebx
                invoke  EnableMenuItem, MenuHandle, IDM_MAINWINMEMORYVIEWER, ebx
                invoke  EnableMenuItem, MenuHandle, IDM_ASSEMBLER,           ebx

                ifc     Tools1_Enabled eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_TOOLWINDOW1, eax

                ifc     MainWinMemView_Enabled eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_MAINWINMEMORYVIEWER, eax

                IFDEF   ENABLEASSEMBLER
                        .if     have_pasmo
                                ifc     Assembler_Enabled eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                                invoke  CheckMenuItem, MenuHandle, IDM_ASSEMBLER, eax
                        .else
                                invoke  DeleteMenu, MenuHandle, IDM_ASSEMBLER, MF_BYCOMMAND
                        .endif
                ELSE
                        invoke  DeleteMenu, MenuHandle, IDM_ASSEMBLER, MF_BYCOMMAND
                ENDIF

                ; handle Zoom menu items
                .if     FullScreenMode == TRUE
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM100, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM200, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM300, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM400, MF_GRAYED or MF_BYCOMMAND
                .else
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM100, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM200, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_ZOOM300, MF_ENABLED or MF_BYCOMMAND

                        invoke  GetClientRect, hWin, addr Rct
                        mov     eax, ToolBarHeight
                        add     eax, StatusHeight
                        sub     Rct.bottom, eax

                        ifc     (Rct.right eq 320) && (Rct.bottom eq 240) then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                        invoke  CheckMenuItem, MenuHandle, IDM_ZOOM100, eax

                        ifc     (Rct.right eq 320*2) && (Rct.bottom eq 240*2) then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                        invoke  CheckMenuItem, MenuHandle, IDM_ZOOM200, eax

                        ifc     (Rct.right eq 320*3) && (Rct.bottom eq 240*3) then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                        invoke  CheckMenuItem, MenuHandle, IDM_ZOOM300, eax

                        ifc     (Rct.right eq 320*4) && (Rct.bottom eq 240*4) then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                        invoke  CheckMenuItem, MenuHandle, IDM_ZOOM400, eax
                .endif

                ; check selected CPU speed
                mov     al, CPU_Speed
                inc     al              ; return to 0-based value
                movzx   eax, al
                invoke  MutualExcludeMenuItems, MenuHandle, IDM_1_75_MHZ, IDM_50_MHZ, eax

                ; check selected hardware model
                invoke  MutualExcludeMenuItems, MenuHandle, IDM_FIRSTMACHINE, IDM_LASTMACHINE, ZeroExt (HardwareMode)

                ; check selected palette mode
                invoke  MutualExcludeMenuItems, MenuHandle, IDM_SPECTRUMPALETTE, IDM_CUSTOMPALETTE, UserPalette

                ; enable/disable ULAplus palette mode selection
                ifc     ULAplus_Enabled eq TRUE then mov eax, MF_ENABLED or MF_BYCOMMAND else mov eax, MF_GRAYED or MF_BYCOMMAND
                invoke  EnableMenuItem, MenuHandle, IDM_ULAPLUS_SUBMENU, eax

                ; enable/disable Eject Tape menu item
                ifc     LoadTapeType ne Type_NONE then mov eax, MF_ENABLED or MF_BYCOMMAND else mov eax, MF_GRAYED or MF_BYCOMMAND
                invoke  EnableMenuItem, MenuHandle, IDM_EJECTTAPE, eax

                ; enable/disable disk specific menu items
                .if     HardwareMode == HW_PLUS3
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_A, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_B, MF_ENABLED or MF_BYCOMMAND
                        ; no units C and D for the +3
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_C, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_D, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_C,  MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_D,  MF_GRAYED or MF_BYCOMMAND

                        mov     ebx, MF_GRAYED or MF_BYCOMMAND
                        .if     $fnc (u765_DiskInserted, FDCHandle, 0) == TRUE
                                mov     ebx, MF_ENABLED or MF_BYCOMMAND
                        .endif
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_A, ebx

                        mov     ebx, MF_GRAYED or MF_BYCOMMAND
                        .if     $fnc (u765_DiskInserted, FDCHandle, 1) == TRUE
                                mov     ebx, MF_ENABLED or MF_BYCOMMAND
                        .endif
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_B, ebx

                .elseif HardwareMode == HW_PENTAGON128
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_A, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_B, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_C, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_D, MF_ENABLED or MF_BYCOMMAND

                        wd1793_DiskInserted     TRDOSHandle, 0
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_A, ebx

                        wd1793_DiskInserted     TRDOSHandle, 1
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_B, ebx

                        wd1793_DiskInserted     TRDOSHandle, 2
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_C, ebx

                        wd1793_DiskInserted     TRDOSHandle, 3
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_D, ebx

                .elseif CBI_Enabled == TRUE
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_A, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_B, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_C, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_D, MF_ENABLED or MF_BYCOMMAND

                        wd1793_DiskInserted     CBIHandle, 0
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_A, ebx

                        wd1793_DiskInserted     CBIHandle, 1
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_B, ebx

                        wd1793_DiskInserted     CBIHandle, 2
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_C, ebx

                        wd1793_DiskInserted     CBIHandle, 3
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_D, ebx

                .elseif PLUSD_Enabled == TRUE
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_A, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_B, MF_ENABLED or MF_BYCOMMAND
                        ; no units C and D for the PLUS-D
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_C, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_D, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_C,  MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_D,  MF_GRAYED or MF_BYCOMMAND

                        wd1793_DiskInserted     PLUSDHandle, 1  ; 1-based for +D disks
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_A, ebx

                        wd1793_DiskInserted     PLUSDHandle, 2  ; 1-based for +D disks
                        ifc     eax eq TRUE then mov ebx, MF_ENABLED or MF_BYCOMMAND else mov ebx, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_B, ebx

                .else
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_A, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_B, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_C, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTDISK_D, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_A,  MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_B,  MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_C,  MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTDISK_D,  MF_GRAYED or MF_BYCOMMAND
                .endif
                ; end disk specific menu items

                ; check/uncheck Pause menu item
                ifc     EmuRunning eq TRUE then mov eax, MF_UNCHECKED or MF_BYCOMMAND else mov eax, MF_CHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_PAUSE, eax

                ; check/uncheck Fullscreen menu item
                ifc     FullScreenMode eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_FULLSCREEN, eax

                ; check/uncheck Accelerate Tape Loading menu item
                ifc     FastTapeLoading eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_ACCELERATETAPELOADING, eax

                ; check/uncheck Real Tape Mode menu item
                ifc     RealTapeMode eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_REALTAPEMODE, eax

                ; check/uncheck max speed menu item
                ifc     MAXIMUMSPEED eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_FULLSPEED, eax

                ; check/uncheck recording video frames menu item
                ifc     RecordingFrames eq TRUE then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                invoke  CheckMenuItem, MenuHandle, IDM_RECORDVIDEO, eax

                ; check/uncheck recording audio menu item
                IFDEF   WANTSOUND
                .if     MuteSound == TRUE
                        invoke  CheckMenuItem,  MenuHandle, IDM_RECORDAUDIO,  MF_UNCHECKED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_RECORDAUDIO,  MF_GRAYED or MF_BYCOMMAND
                .else
                        invoke  EnableMenuItem, MenuHandle, IDM_RECORDAUDIO, MF_ENABLED or MF_BYCOMMAND
                        ifc     AudioFH ne 0 then mov eax, MF_CHECKED or MF_BYCOMMAND else mov eax, MF_UNCHECKED or MF_BYCOMMAND
                        invoke  CheckMenuItem, MenuHandle, IDM_RECORDAUDIO, eax
                .endif
                ELSE
                invoke  EnableMenuItem, MenuHandle, IDM_RECORDAUDIO, MF_GRAYED or MF_BYCOMMAND
                ENDIF

                ; enable/disable save tape menu items
                .if     SaveTapeType == Type_NONE
                        ; no save tape inserted
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTSAVETAPE, MF_ENABLED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTSAVETAPE,  MF_GRAYED or MF_BYCOMMAND
                .else
                        ; a save tape is inserted
                        invoke  EnableMenuItem, MenuHandle, IDM_INSERTSAVETAPE, MF_GRAYED or MF_BYCOMMAND
                        invoke  EnableMenuItem, MenuHandle, IDM_EJECTSAVETAPE,  MF_ENABLED or MF_BYCOMMAND
                .endif

                ; check/uncheck install genie into Multiface menu item
                ifc     (HardwareMode ge HW_16) && (HardwareMode le HW_PLUS2) then mov eax, MF_ENABLED or MF_BYCOMMAND else mov eax, MF_GRAYED or MF_BYCOMMAND
                invoke  EnableMenuItem, MenuHandle, IDM_INSTALLGENIE128, eax

                return  0

align 16
wndproc_WM_EXITMENULOOP:    mov     MenuNoUnattach, FALSE
                            invoke  Resync_Capture
                            jmp     wndproc_Default

align 16
wndproc_WM_ACTIVATE:        ; If the window is being activated and is not minimized, the DefWindowProc function sets the keyboard focus to the window.
                            ; If the window is activated by a mouse click, it also receives a WM_MOUSEACTIVATE message.
                            mov     eax, wParam
                            .if     ax == WA_INACTIVE
                                    ifc     FullScreenMode eq TRUE then CLEARSOUNDBUFFERS
                                    ifc     Pause_On_Lost_Focus eq TRUE then CLEARSOUNDBUFFERS

                                    call    InitPort            ; reset all Spectrum keys to up
                                    invoke  ClearKeyboardState

                                    mov     ActiveState, FALSE
                            .else
                                    invoke  SetFocus, hWin
                                    mov     ActiveState, TRUE

                                    call    InitPort            ; reset all Spectrum keys to up
                                    invoke  ClearKeyboardState

                                    ifc     FullScreenMode eq TRUE then invoke Resync_Capture
                            .endif
                            jmp     wndproc_Default

align 16
wndproc_WM_SETFOCUS:        mov     keyboard_hasfocus, TRUE
                            jmp     wndproc_Default

align 16
wndproc_WM_KILLFOCUS:       call    InitPort
                            mov     keyboard_hasfocus, FALSE
                            jmp     wndproc_Default

align 16
wndproc_WM_NOTIFY:          mov     ebx, lParam
                            .if     [ebx].NMHDR.code == TTN_NEEDTEXT

                                  ; get tooltip for the main window toolbar
                                    ASSUME  EBX: PTR TOOLTIPTEXT
                                    mov     [ebx].hInst, NULL
                                    switch  [ebx].hdr.idFrom
                                            case    IDM_OPENFILETYPE
                                                    mov     [ebx].lpszText, CTXT ("Open File")
                                                    return  0
                                            case    IDM_SAVESNAPSHOT
                                                    mov     [ebx].lpszText, CTXT ("Save Snapshot")
                                                    return  0
                                            case    IDM_RESET
                                                    mov     [ebx].lpszText, CTXT ("Soft Reset")
                                                    return  0
                                            case    IDM_PAUSE
                                                    mov     [ebx].lpszText, CTXT ("Pause")
                                                    return  0
                                            case    IDM_FULLSCREEN
                                                    mov     [ebx].lpszText, CTXT ("Full Screen")
                                                    return  0
                                            case    IDM_TAPEBROWSER
                                                    mov     [ebx].lpszText, CTXT ("Open Tape Browser")
                                                    return  0
                                            case    IDM_DEBUGGER
                                                    mov     [ebx].lpszText, CTXT ("Debugger")
                                                    return  0
                                            case    IDM_OPTIONS
                                                    mov     [ebx].lpszText, CTXT ("Options")
                                                    return  0
                                            .else
                                                    mov     [ebx].lpszText, NULL
                                                    return  0
                                    endsw
                            .endif
                            ASSUME  EBX: NOTHING
                            jmp     wndproc_Default

align 16
wndproc_WM_SYSCOLORCHANGE:  invoke  DestroyWindow, mainwin_hToolBar
                            invoke  AddMainWinToolBar, hWin

                            invoke  DestroyWindow, mainwin_hStatus
                            invoke  AddMainWinStatus, hWin

                            jmp     wndproc_Default

                            ; In WM_SYSCOMMAND messages, the four low-order bits of the wParam parameter are used internally by the system.
                            ; To obtain the correct result when testing the value of wParam, an application must combine
                            ; the value 0xFFF0 with the wParam value by using the bitwise AND operator.
align 16
wndproc_WM_SYSCOMMAND:      mov     eax, wParam
                            and     eax, 0FFF0h

                            switch  eax
                                    case    SC_SCREENSAVE
                                            return  0       ; disable screen saver
            
                                    case    SC_MONITORPOWER
                                            return  0       ; disable monitor power-saving mode
                            endsw
                            jmp     wndproc_Default

                            ; An application can prompt the user for confirmation, prior to destroying a window, by processing the WM_CLOSE message and calling the DestroyWindow function only if the user confirms the choice.
                            ; By default, the DefWindowProc function calls the DestroyWindow function to destroy the window.
align 16
wndproc_WM_CLOSE:           call    InitPort
                            CLEARSOUNDBUFFERS

                            .if     (ConfirmExit == TRUE) && (BypassConfirmExit == FALSE)
                                    invoke  ShowMessageBox, hWin, SADD ("Really want to quit SpecEmu ?"), SADD ("Exit Requester"), MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                    .if     eax == IDNO
                                            invoke  Resync_Capture
                                            return  0
                                    .endif
                            .endif

                            invoke  Asm_SaveAllTabFiles
                            jmp     wndproc_Default

align 16
wndproc_WM_DESTROY:         invoke  Close_RZX, 0, FALSE         ; close any open RZX file (before removing any inserted tapes or disks)

                            invoke  FreeTaskQueue               ; free any queued tasks

                            invoke  FreePageTableList           ; free any allocated virtual page tables

                            invoke  DestroyWindow, SoftRomDlg
                            invoke  DestroyWindow, Tools1Dlg
                            invoke  DestroyWindow, MW_MemViewDlg
                            invoke  DestroyWindow, AssemblerDlg
                            invoke  DestroyWindow, MessagesDlg

                            mov     SafeRun, FALSE

                            invoke  CloseTapeFile
                            call    CloseSaveTapeFile
                            invoke  u765_Shutdown, FDCHandle    ; close all +3 disk units, release FDCHandle

                            IDE_ShutDown    IDEHandle           ; close all HDF disk images, release IDEHandle

                            wd1793_ShutDown TRDOSHandle         ; close all Pentagon/Trdos disk units, release TRDOSHandle
                            wd1793_ShutDown PLUSDHandle         ; close all PLUS D disk units, release PLUSDHandle
                            wd1793_ShutDown CBIHandle           ; close all CBI disk units, release CBIHandle

                            invoke  InfoSeekCleanUp

                            IFDEF   WANTSOUND
                            call    CloseAudioFile
                            ENDIF

                            ifc     MAXIMUMSPEED eq TRUE then call SetNormalSpeed   ; restore before writing .ini file

                            mov     eax, FullScreenMode
                            mov     StartFullscreen, al     ; will start Fullscreen if exited in Fullscreen mode

                            ifc     FullScreenMode eq TRUE then invoke FlipDisplayMode ; restore windowed mode so correct window coords get written to the INI file

                            call    WriteProfile
                            invoke  SaveRecentFileList

                            invoke  SaveCustomPalettes

                            invoke  Machine_Delete, addr currentMachine ; delete the machine instance

                            call    FreeResources          ; free up allocated resources

                            IFDEF   WANTSOUND
                            call    ShutdownDirectSound
                            ENDIF

                            invoke  Close_Capture           ; close sound capture if currently in capture (real tape) mode

                            invoke  ShutdownDirectDraw      ; releases all surfaces and the directdraw object

                            invoke  KillTimer, hWin, TIMER_1_SECOND

                          ; delete global fonts
                            invoke  DeleteObject, gl_Courier_New_6
                            invoke  DeleteObject, gl_Courier_New_9

                            ;invoke  RevokeDragDrop, hWin

                            invoke  PostQuitMessage, NULL
                            return  0

WNDPROCHANDLER              macro   msg:req
                            dd      msg, wndproc_&msg&
                            endm
.data
align 16
wndproc_table               dd  MM_WIM_DATA,        wndproc_MM_WIM_DATA
                            WNDPROCHANDLER          WM_USER_WAVEIN
                            WNDPROCHANDLER          WM_USER_REMOTE_APP
                            WNDPROCHANDLER          WM_PAINT
                            WNDPROCHANDLER          WM_MOUSEMOVE
                            WNDPROCHANDLER          WM_CHAR
                            WNDPROCHANDLER          WM_KEYDOWN
                            WNDPROCHANDLER          WM_KEYUP
                            WNDPROCHANDLER          WM_SYSCHAR
                            WNDPROCHANDLER          WM_SYSKEYDOWN
                            WNDPROCHANDLER          WM_SYSKEYUP
                            WNDPROCHANDLER          WM_TIMER
                            WNDPROCHANDLER          WM_NCLBUTTONDOWN
                            WNDPROCHANDLER          WM_COPYDATA
                            WNDPROCHANDLER          WM_COMMAND
                            WNDPROCHANDLER          WM_DROPFILES
                            WNDPROCHANDLER          WM_CREATE
                            WNDPROCHANDLER          WM_DISPLAYCHANGE
                            WNDPROCHANDLER          WM_ENTERSIZEMOVE
                            WNDPROCHANDLER          WM_EXITSIZEMOVE
                            WNDPROCHANDLER          WM_SIZE
                            WNDPROCHANDLER          WM_SIZING
                            WNDPROCHANDLER          WM_ENTERMENULOOP
                            WNDPROCHANDLER          WM_EXITMENULOOP
                            WNDPROCHANDLER          WM_MENUCHAR
                            WNDPROCHANDLER          WM_ACTIVATE
                            WNDPROCHANDLER          WM_SETFOCUS
                            WNDPROCHANDLER          WM_KILLFOCUS
                            WNDPROCHANDLER          WM_NOTIFY
                            WNDPROCHANDLER          WM_SYSCOLORCHANGE
                            WNDPROCHANDLER          WM_SYSCOMMAND
                            WNDPROCHANDLER          WM_CLOSE
                            WNDPROCHANDLER          WM_DESTROY
;                            WNDPROCHANDLER          WM_ERASEBKGND
                            dd  -1,                 -1
.code
WndProc                     endp

; ========================================================================

                            RESETENUM   0
                            ENUM    VSTATE_NONE             ; b: 00
                            ENUM    VSTATE_CONTROL          ; b: 01
                            ENUM    VSTATE_SHIFT            ; b: 10
                            ENUM    VSTATE_SHIFT_CONTROL    ; b: 11

                            VSTATE_CONTROL_SHIFT    equ     VSTATE_SHIFT_CONTROL

GetKeyShiftState            proc    uses    ebx

                            xor     ebx, ebx
                            invoke  GetKeyState, VK_SHIFT   ; will become bit 1 of result
                            shl     ax, 1
                            rcl     ebx, 1

                            invoke  GetKeyState, VK_CONTROL ; will become bit 0 of result
                            shl     ax, 1
                            rcl     ebx, 1

                            return  ebx
GetKeyShiftState            endp

