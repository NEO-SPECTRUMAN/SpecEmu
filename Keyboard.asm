
VK_LWIN                     equ     5Bh
VK_RWIN                     equ     5Ch

.data?
align 16
keyboard_state              BYTE    256 dup (?)

keyboard_hasfocus           BYTE    ?   ; TRUE if main window has focus; see WM_SETFOCUS/WM_KILLFOCUS messages

.code
SCAN_KEYBRK                 macro   keycode:REQ, keycall:REQ
                            mov     al, [keyboard_state+keycode]
                            shl     al, 1
                            .if     CARRY?
                                    call    keycall
                                    jmp     KeyStateExit
                            .endif
                            endm

SCAN_KEY                    macro
                            mov     al, [keyboard_state+ebx]
                            shl     al, 1
                            .if     CARRY?
                                    push    ebx
                                    mov     al, bl
                                    call    ScanKeyStroke
                                    pop     ebx
                            .endif
                            endm

SCAN_KEY_SET                macro   firstkey:REQ, lastkey:REQ
                            mov     ebx, firstkey
                            .while  ebx <= lastkey
                                    SCAN_KEY
                                    inc     ebx
                            .endw
                            endm

; called from message loop when emulator is paused
align 16
GetPausedKeyState           proc    uses    esi

                            .if     keyboard_hasfocus
                                    .if     $fnc (GetKeyboardState, addr keyboard_state)
                                            invoke  Special_Key_Combos
                                    .else
                                            ADDMESSAGE_DBG  "GetPausedKeyState: GetKeyboardState() failed"
                                    .endif
                            .endif
                            ret

GetPausedKeyState           endp


                            IFDEF   KEYSTATE_INFO
                                    .data?
                                    align 4
                                    Lastkeyboard_state          BYTE    256  dup (?)
                                    keystatecopied              BYTE    ?
                            ENDIF

.code
align 16
GetSpeccyInputStates        proc

                            invoke  GetSpeccyKeyState
                            invoke  GetJoystickStates

                            IFDEF   KEYSTATE_INFO
                                    .if     keystatecopied
                                            push    esi
                                            push    edi

                                            lea     esi, keyboard_state + VK_0
                                            lea     edi, Lastkeyboard_state + VK_0
                                            mov     edx, (VK_Z - VK_0 + 1) / 4

                                    @@:     mov     eax, [esi]
                                            mov     ecx, [edi]
                                            add     esi, 4
                                            add     edi, 4

                                            and     eax, 80808080h
                                            and     ecx, 80808080h

                                            cmp     eax, ecx
                                            jnz     @F

                                            dec     edx
                                            jnz     @B

                                    @@:     .if     !ZERO?
                                                    ADDMESSAGE_DBG  "Key map changed"
                                            .endif

                                            pop     edi
                                            pop     esi
                                    .endif

                                    memcpy  addr keyboard_state, addr Lastkeyboard_state, 256
                                    mov     keystatecopied, TRUE
                            ENDIF

                            ret
GetSpeccyInputStates        endp

align 16
GetSpeccyKeyState           proc    uses    esi edi ebx

                            ; exit immediately if main window does not have focus
                            ifc     keyboard_hasfocus eq FALSE then ret
;                            ifc     ActiveState eq FALSE then ret

                            lea     edi, PORT_FE
                            mov     eax, 0FFFFFFFFh
                            stosd               ; init 4 key rows
                            stosd               ; init 4 key rows

                            invoke  GetKeyboardState, addr keyboard_state
                            .if     eax == 0
                                    ADDMESSAGE_DBG  "GetSpeccyKeyState: GetKeyboardState() failed"
                                    ret
                            .endif

                            ; handle keys which abort Spectrum key scanning
                            lea     esi, keyboard_state
                            mov     al, [esi+VK_MENU]   ; VK_ALT
                            or      al, [esi+VK_LWIN]
                            or      al, [esi+VK_RWIN]
                            or      al, [esi+VK_LMENU]
                            or      al, [esi+VK_RMENU]

                            shl     al, 1
                            jc      KeyStateExit

                            SCAN_KEYBRK VK_BACK,     Key_Delete
                            SCAN_KEYBRK 188,         Key_Comma           ; ","
                            SCAN_KEYBRK 190,         Key_Period          ; "."
                            SCAN_KEYBRK 191,         Key_Divide          ; "/"
                            SCAN_KEYBRK 186,         Key_SemiColon       ; ";"
                            SCAN_KEYBRK 189,         Key_Minus           ; "-"
                            SCAN_KEYBRK 187,         Key_Equals          ; "="
                            SCAN_KEYBRK 0C0h,        Key_SingleQuote     ; "'"
                            SCAN_KEYBRK VK_LEFT,     Key_Cursor_Left     ; cursor left
                            SCAN_KEYBRK VK_RIGHT,    Key_Cursor_Right    ; cursor right
                            SCAN_KEYBRK VK_UP,       Key_Cursor_Up       ; cursor up
                            SCAN_KEYBRK VK_DOWN,     Key_Cursor_Down     ; cursor down
                            SCAN_KEYBRK 0DEh,        Key_Hash            ; hash
                            SCAN_KEYBRK VK_DECIMAL,  Key_Period
                            SCAN_KEYBRK VK_ADD,      Key_Add
                            SCAN_KEYBRK VK_SUBTRACT, Key_Minus
                            SCAN_KEYBRK VK_MULTIPLY, Key_Multiply
                            SCAN_KEYBRK VK_DIVIDE,   Key_Divide

                            SCAN_KEY_SET    VK_0, VK_9
                            SCAN_KEY_SET    VK_A, VK_Z
                            SCAN_KEY_SET    VK_NUMPAD0, VK_NUMPAD9

                            mov     ebx, VK_SPACE
                            SCAN_KEY

                            mov     ebx, VK_RETURN
                            SCAN_KEY

                            invoke  SetShiftCtrlState

KeyStateExit:               invoke  Special_Key_Combos
                            ret

GetSpeccyKeyState           endp

align 16
Key_Delete:                 mov     al, VK_SHIFT
                            call    ScanKeyStroke
                            mov     al, "0"
                            call    ScanKeyStroke
                            ret

align 16
Key_Comma:                  mov     al,VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "N"
                            call    ScanKeyStroke
                            ret

align 16
Key_Period:                 mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "M"
                            call    ScanKeyStroke
                            ret

align 16
Key_Multiply:               mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "B"
                            call    ScanKeyStroke
                            ret

align 16
Key_Divide:                 mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "V"
                            call    ScanKeyStroke
                            ret

align 16
Key_SemiColon:              mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "O"
                            call    ScanKeyStroke
                            ret

align 16
Key_Add:                    mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "K"
                            call    ScanKeyStroke
                            ret

align 16
Key_Minus:                  mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "J"
                            call    ScanKeyStroke
                            ret

align 16
Key_Equals:                 mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "L"
                            call    ScanKeyStroke
                            ret

align 16
Key_SingleQuote:            mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "7"
                            call    ScanKeyStroke
                            ret

align 16
Key_Cursor_Left:            mov     al, VK_SHIFT
                            call    ScanKeyStroke
                            mov     al, "5"
                            call    ScanKeyStroke
                            ret

align 16
Key_Cursor_Right:           mov     al, VK_SHIFT
                            call    ScanKeyStroke
                            mov     al, "8"
                            call    ScanKeyStroke
                            ret

align 16
Key_Cursor_Up:              mov     al, VK_SHIFT
                            call    ScanKeyStroke
                            mov     al, "7"
                            call    ScanKeyStroke
                            ret

align 16
Key_Cursor_Down:            mov     al, VK_SHIFT
                            call    ScanKeyStroke
                            mov     al, "6"
                            call    ScanKeyStroke
                            ret

align 16
Key_Hash:                   mov     al, VK_CONTROL
                            call    ScanKeyStroke
                            mov     al, "3"
                            call    ScanKeyStroke
                            ret

; #########################################################################

align 16
ScanKeyStroke:              lea     esi, SpectrumKeyMap

ScanKeyMap:                 mov     ebx, [esi]
                            or      ebx, ebx
                            je      SKM_Exit

                            cmp     al, bl
                            je      FoundKey

                            add     esi, 8
                            jmp     ScanKeyMap

SKM_Exit:                   ret

FoundKey:                   mov     esi, [esi+4]    ; esi = port addr
                            shr     ebx, 8          ; bx = bit no.

                            mov     al, [esi]
                            btr     ax, bx          ; clear the key bit
                            mov     [esi], al
                            ret

; ##########################################################################

align 16
SetShiftCtrlState           proc

                            .if     KeyShiftMode != KEY_SHIFTCTRL
                                    ; use Shift keys for Caps/Symbol
                                    mov     al, [keyboard_state+VK_LSHIFT]
                                    shl     al, 1
                                    ifc     CARRY? then and PORT_FE, 254

                                    mov     al, [keyboard_state+VK_RSHIFT]
                                    shl     al, 1
                                    ifc     CARRY? then and PORT_7F, 253
                            .else
                                    ; use Shift and Ctrl keys for Caps/Symbol
                                    mov     al, [keyboard_state+VK_SHIFT]
                                    shl     al, 1
                                    ifc     CARRY? then and PORT_FE, 254

                                    mov     al, [keyboard_state+VK_CONTROL]
                                    shl     al, 1
                                    ifc     CARRY? then and PORT_7F, 253
                            .endif
                            ret

SetShiftCtrlState           endp

; ##########################################################################

                            ; test for special emulator key combos
align 16
Special_Key_Combos          proc    uses    esi

                            local   hStrmOut:   DWORD

                            local   textstring: TEXTSTRING,
                                    pTEXTSTRING:DWORD

                            lea     esi, keyboard_state
                            mov     al, [esi+VK_MENU]
                            and     al, [esi+VK_SHIFT]
                            and     al, [esi+VK_CONTROL]
                            and     al, [esi+VK_M]
                            and     al, [esi+VK_P]
                            and     al, [esi+VK_DELETE]
                            ifc     al ge 80h then invoke Show_Message_Dialog

                            IFDEF   DEBUGBUILD
                                    mov     al, [esi+VK_HOME]
                                    and     al, [esi+VK_END]
                                    and     al, [esi+VK_PRIOR]  ; PAGE UP key
                                    .if     al >= 80h
                                            invoke WriteMemoryToFile, SADD ("G:\keymap.bin"), addr keyboard_state, sizeof keyboard_state

                                            mov     hStrmOut, $fnc (CreateFileStream, SADD ("G:\keymap.txt"), FSA_WRITE, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 1024)
                                            .if     hStrmOut != 0
                                                    invoke  WriteFileStreamString, hStrmOut, SADD ("  | 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F", 13, 10)
                                                    invoke  WriteFileStreamString, hStrmOut, SADD ("--+-----------------------------------------------", 13, 10)

                                                    lea     esi, keyboard_state

                                                    SETLOOP 16
                                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                                                            mov     eax, esi
                                                            sub     eax, offset keyboard_state
                                                            shr     al, 4
                                                            cmp     al, 10
                                                            sbb     al, 69h
                                                            das
                                                            ADDCHAR     pTEXTSTRING, al     ; Y offset as single hex digit (0..F)
                                                            ADDCHAR     pTEXTSTRING, " ", "|"

                                                            SETLOOP 16
                                                                    ADDCHAR     pTEXTSTRING, " "
                                                                    mov     al, [esi]
                                                                    inc     esi
                                                                    .if     al >= 80h
                                                                            ADDTEXTHEX  pTEXTSTRING, al
                                                                    .else
                                                                            ADDCHAR     pTEXTSTRING, " ", " "
                                                                    .endif
                                                            ENDLOOP

                                                            ADDCHAR     pTEXTSTRING, 13, 10
                                                            invoke  WriteFileStreamString, hStrmOut, addr textstring
                                                    ENDLOOP

                                                    invoke  CloseFileStream, hStrmOut
                                            .endif
                                    .endif
                            ENDIF

                            ret
Special_Key_Combos          endp

KEYDEF                      macro   winkeycode, speckeybit, speckeyport
                            db      winkeycode
                            db      speckeybit
                            db      0, 0
                            dd      speckeyport
                            endm

.const
align 16
SpectrumKeyMap              db      VK_SHIFT, 0, 0, 0
                            dd      PORT_FE

                            KEYDEF  "Z",        1, PORT_FE
                            KEYDEF  "X",        2, PORT_FE
                            KEYDEF  "C",        3, PORT_FE
                            KEYDEF  "V",        4, PORT_FE

                            KEYDEF  "A",        0, PORT_FD
                            KEYDEF  "S",        1, PORT_FD
                            KEYDEF  "D",        2, PORT_FD
                            KEYDEF  "F",        3, PORT_FD
                            KEYDEF  "G",        4, PORT_FD

                            KEYDEF  "Q",        0, PORT_FB
                            KEYDEF  "W",        1, PORT_FB
                            KEYDEF  "E",        2, PORT_FB
                            KEYDEF  "R",        3, PORT_FB
                            KEYDEF  "T",        4, PORT_FB

                            KEYDEF  "1",        0, PORT_F7
                            KEYDEF  "2",        1, PORT_F7
                            KEYDEF  "3",        2, PORT_F7
                            KEYDEF  "4",        3, PORT_F7
                            KEYDEF  "5",        4, PORT_F7

                            KEYDEF  VK_NUMPAD1, 0, PORT_F7
                            KEYDEF  VK_NUMPAD2, 1, PORT_F7
                            KEYDEF  VK_NUMPAD3, 2, PORT_F7
                            KEYDEF  VK_NUMPAD4, 3, PORT_F7
                            KEYDEF  VK_NUMPAD5, 4, PORT_F7

                            KEYDEF  "0",        0, PORT_EF
                            KEYDEF  "9",        1, PORT_EF
                            KEYDEF  "8",        2, PORT_EF
                            KEYDEF  "7",        3, PORT_EF
                            KEYDEF  "6",        4, PORT_EF

                            KEYDEF  VK_NUMPAD0, 0, PORT_EF
                            KEYDEF  VK_NUMPAD9, 1, PORT_EF
                            KEYDEF  VK_NUMPAD8, 2, PORT_EF
                            KEYDEF  VK_NUMPAD7, 3, PORT_EF
                            KEYDEF  VK_NUMPAD6, 4, PORT_EF

                            KEYDEF  "P",        0, PORT_DF
                            KEYDEF  "O",        1, PORT_DF
                            KEYDEF  "I",        2, PORT_DF
                            KEYDEF  "U",        3, PORT_DF
                            KEYDEF  "Y",        4, PORT_DF

                            KEYDEF  VK_RETURN,  0, PORT_BF
                            KEYDEF  "L",        1, PORT_BF
                            KEYDEF  "K",        2, PORT_BF
                            KEYDEF  "J",        3, PORT_BF
                            KEYDEF  "H",        4, PORT_BF

                            KEYDEF  VK_SPACE,   0, PORT_7F
                            KEYDEF  VK_CONTROL, 1, PORT_7F
                            KEYDEF  "M",        2, PORT_7F
                            KEYDEF  "N",        3, PORT_7F
                            KEYDEF  "B",        4, PORT_7F
                            dd      0   ; table end marker

.data
align 16
PORT_FE                     db      0   ; keyboard ports modified by Windows key events
PORT_FD                     db      0
PORT_FB                     db      0
PORT_F7                     db      0
PORT_EF                     db      0
PORT_DF                     db      0
PORT_BF                     db      0
PORT_7F                     db      0
PORT_1F                     db      0   ; kempston joystick port 31
PORT_37                     db      0   ; kempston joystick port 55

SpeccyKeyPorts              db      8 dup (?)    ; keyboard ports read by emulated machine
SpeccyKempston1F            db      0            ; kempston port 31 read by emulated machine
SpeccyKempston37            db      0            ; kempston port 55 read by emulated machine

; ##########################################################################

CLRKEY                      macro   @vkbase:req, @vkkey:req
                            mov     byte ptr [@vkbase+@vkkey], 0
                            endm

CLRKEYSET                   macro   @vkbase:req, @vkstart:req, @vkend:req
                            local   @vkcnt, @vkoffset

                            if      @vkend lt @vkstart
                                    .err    <CLRKEYSET: start !> end>
                            endif

                            @vkcnt = @vkend - @vkstart + 1
                            @vkoffset = @vkstart

                            while   @vkcnt ge 4
                                    mov     dword ptr [@vkbase + @vkoffset], 0
                                    @vkoffset = @vkoffset + 4
                                    @vkcnt = @vkcnt - 4
                            endm

                            if      @vkcnt ge 2
                                    mov     word ptr [@vkbase + @vkoffset], 0
                                    @vkoffset = @vkoffset + 2
                                    @vkcnt = @vkcnt - 2
                            endif

                            if      @vkcnt eq 1
                                    mov     byte ptr [@vkbase + @vkoffset], 0
                                    @vkoffset = @vkoffset + 1
                                    @vkcnt = @vkcnt - 1
                            endif
                            endm

.code
align 16
ClearKeyboardState          proc    uses    edi

                            lea     edi, keyboard_state

                            invoke  GetKeyboardState, edi

                            CLRKEYSET   edi, VK_BACK, VK_TAB
                            CLRKEY      edi, VK_RETURN
                            CLRKEY      edi, VK_SHIFT
                            CLRKEY      edi, VK_CONTROL
                            CLRKEY      edi, VK_SPACE
                            CLRKEYSET   edi, VK_LEFT, VK_DOWN
                            CLRKEYSET   edi, VK_0, VK_9
                            CLRKEYSET   edi, VK_A, VK_Z
                            CLRKEYSET   edi, VK_NUMPAD0, VK_DIVIDE
                            CLRKEYSET   edi, VK_LSHIFT, VK_RCONTROL

                            invoke  SetKeyboardState, edi

                            IFDEF   KEYSTATE_INFO
                                    ADDMESSAGE_DBG  "SetKeyboardState"
                            ENDIF

                            ret
ClearKeyboardState          endp

align 16
InitPort:                   push    edi
                            lea     edi, PORT_FE

                            ; init primary rows
                            mov     eax, 0FFFFFFFFh
                            stosd               ; init 4 key rows
                            stosd               ; init 4 key rows
                            xor     ax, ax
                            stosw               ; init kempston 31+55 bytes

                            call    UpdatePortState

                            pop     edi
                            ret

align 16
; must preserve all registers
UpdatePortState:            push    esi
                            push    edi
                            lea     esi, PORT_FE
                            lea     edi, SpeccyKeyPorts
                            movsd
                            movsd
                            movsw
                            pop     edi
                            pop     esi
                            ret

