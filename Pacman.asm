
                    IFDEF   PACMAN

                    include PacmanSnaps.inc

align 16
Enable_Pacmode      proc    set_mode:   BYTE,
                            startlevel: BYTE

                    local   snappath[MAX_PATH]:BYTE

                    ; close any previously running pacmode, close files, etc...
                    invoke  Disable_Pacmode

                    ; exit now if ROMs are unavailable in ROMs folder (checked on SpecEmu startup code)
                    ifc     HavePacmanROMs eq FALSE then ret

                    ; load the pacman mem snap, copy Pac-Man ROMs in, patch the ROMs with obo's patches
                    .if     $fnc (PrepPacManEnviron) == FALSE
                            return  FALSE   ; did something go wrong?
                    .endif

                    .if     $fnc (Pac_Is_0123) == FALSE
                            ADDMESSAGE  "SZX wrong config: Not in RAM 0/1/2/3 mode!"
                            ret
                    .endif

                  ; temp patches to obo's sprite clipping
                    invoke  WriteBankByte, 2, 0a87fh, 018h
                    invoke  WriteBankByte, 2, 0a883h, 0f8h
                  ; ======================================

                    mov     al, startlevel
                    mov     z80registers.af.hi, al      ; Pacman start level passed in A register (first snap opcode at #0690 writes A to #4e13)

                    invoke  WriteZ80Byte, 087eh, 0ah    ; patches ROM bug that clears the starting level number

                    mov     cl, 5                       ; start with 5 lives (aiming for 3,333,360 points)
                    ifc     startlevel eq 255 then inc cl ; we'd have an extra life by now!
                    invoke  WriteZ80Byte, 4e6fh, cl     ; starting lives counter from DIP switch

                    ; difficulty levels at #0068 in ROM
                    ; 0068  00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14

                    movzx   cx, startlevel
                    ifc     cx gt 14h then mov cx, 14h  ; max out at 20 (14h)
                    add     cx, 0068h                   ; cx = difficulty level table pointer

                    invoke  GetZ80MemoryAddr, 0883h
                    mov     byte ptr [eax], 21h         ; ld hl,
                    mov     word ptr [eax+1], cx        ; nnnn

                    invoke  Set_Pacman_Patches          ; insert runtime patches from the z80 core

                    mov     ax, z80registers.pc
                    mov     Z80PC, ax

                    mov     al, set_mode
                    mov     pacmode, al

                    mov     paclevel_loaded, FALSE

                    ret
Enable_Pacmode      endp

align 16
Disable_Pacmode     proc

                    .if     pac_strm_handle != 0
                            .if     pacmode == PACMODE_RECORD
                                    invoke  StreamPacDataPair   ; stream any final data pair
                            .endif

                            invoke  CloseFileStream, pac_strm_handle
                            mov     pac_strm_handle, 0
                    .endif

                    invoke  Free_PacInputMem

                    mov     pacmode, PACMODE_NONE

                    ret
Disable_Pacmode     endp

align 16
Free_PacInputMem    proc

                    .if     pacinput_base != 0
                            invoke  FreeMemory, pacinput_base
                            mov     pacinput_base, 0
                            mov     pacinput_ptr, 0

                            mov     paclevel_loaded, FALSE
                            mov     pac_input_pair, 0
                    .endif
                    ret

Free_PacInputMem    endp

align 16
Pac_Is_0123         proc

                    mov     eax, currentMachine.RAMREAD0
                    cmp     eax, currentMachine.bank0
                    jnz     @F

                    mov     eax, currentMachine.RAMREAD2
                    cmp     eax, currentMachine.bank1
                    jnz     @F

                    mov     eax, currentMachine.RAMREAD4
                    cmp     eax, currentMachine.bank2
                    jnz     @F

                    mov     eax, currentMachine.RAMREAD6
                    cmp     eax, currentMachine.bank3
                    jnz     @F

                    return  TRUE

            @@:     return  FALSE

Pac_Is_0123         endp

align 16
Set_Pacman_Patches  proc
                    .if     $fnc (Pac_Is_0123) == FALSE
                            ADDMESSAGE  "Cannot patch PACMAN: Not in RAM 0/1/2/3 mode!"
                            ret
                    .endif

PACTRAP_0690        equ     0690h
PACTRAP_0a93        equ     0a93h
PACTRAP_08e8        equ     08e8h
PACTRAP_18c5        equ     18c5h
PACTRAP_0919        equ     0919h
PACTRAP_091f        equ     091fh
PACTRAP_0795        equ     0795h

                    mov     cl, 64h     ; ld h,h
                    invoke  WriteZ80Byte, PACTRAP_0690, cl
                    invoke  WriteZ80Byte, PACTRAP_0a93, cl
                    invoke  WriteZ80Byte, PACTRAP_08e8, cl
                    invoke  WriteZ80Byte, PACTRAP_18c5, cl
                    invoke  WriteZ80Byte, PACTRAP_0919, cl
                    invoke  WriteZ80Byte, PACTRAP_091f, cl

                    invoke  WriteZ80Byte, PACTRAP_0795, cl     ; this filters out garbage making the kill screen "playable"

                    ret

Set_Pacman_Patches  endp

ISPACTRAPPED_ADDR   macro   @trapaddr:REQ
                    cmp     byte ptr [esi+@trapaddr], 64h   ; ld h,h
                    jne     @is_pactrapp_exit
                    endm

align 16
Is_Pacman_Trapped   proc    uses    esi ebx

                    mov     bl, FALSE   ; init return code

                    cmp     HardwareMode, HW_PLUS3
                    jne     @is_pactrapp_exit

                    ; cant make being in 64K RAM mode a part of the test
                    ; as it's not exclusively in 64K RAM mode...
                    ; d'oh - quickest pull and re-release ever!!

                    mov     esi, currentMachine.bank0
                    ISPACTRAPPED_ADDR   PACTRAP_0690
                    ISPACTRAPPED_ADDR   PACTRAP_0a93
                    ISPACTRAPPED_ADDR   PACTRAP_08e8
                    ISPACTRAPPED_ADDR   PACTRAP_18c5
                    ISPACTRAPPED_ADDR   PACTRAP_0919
                    ISPACTRAPPED_ADDR   PACTRAP_091f

                    ISPACTRAPPED_ADDR   PACTRAP_0795       ; this filters out garbage making the kill screen "playable"

                    ; check crc16 for upper 8K of Pacman ROM (bank 0)
                    mov     eax, currentMachine.bank0
                    add     eax, 2000h
                    invoke  Calc_CRC16_Data, eax, 2000h
                    cmp     ax, pacromcrc_upper
                    jne     @is_pactrapp_exit

                    mov     bl, TRUE

@is_pactrapp_exit:  movzx   eax, bl ; return code to eax
                    ret

Is_Pacman_Trapped   endp

;#0690 - pacman initialises level counter, patch loads an input file if playback enabled
;#0a93 - pacman increases level counter, patch loads an input file if playback enabled
;#08e8 - pacman signals end of level, patch purges the level data output stream if recording enabled
;#18c6 - pacman reads controller (#5000), patch writes the byte to output stream or provides the byte from input stream

; these traps all work from a single LD H,H opcode, hence PC is already incremented after opcode fetch
; therefore we test on (pc+1) relative to the patched address
align 16
Handle_Pac_Patches  proc

                    .if     $fnc (Pac_Is_0123) == FALSE
                            ADDMESSAGE  "Cannot handle PACMAN patches: Not in RAM 0/1/2/3 mode!"
                            ret
                    .endif

                    switch  z80registers.pc
                          ; ===================================================================================================================
                            case    PACTRAP_0690+1

                                    ADDMESSAGE  "Pacman Trap: #0690 -- Set level number"
                                  ; ld (#4e13),a  ; initialises level counter for game start (at selected level in pac command)
                                    call    Op32
                                    .if     pacmode == PACMODE_PLAYBACK
                                            invoke  LoadPacLevel_Input
                                    .endif

                          ; ===================================================================================================================
                            case    PACTRAP_0a93+1

                                    ADDMESSAGE  "Pacman Trap: #0a93 -- Increment level number"
                                  ; inc (hl)      ; increments level counter for next level
                                    call    Op34
                                    .if     pacmode == PACMODE_PLAYBACK
                                            invoke  LoadPacLevel_Input
                                    .endif

                          ; ===================================================================================================================
                            case    PACTRAP_08e8+1

                                    ADDMESSAGE  "Pacman Trap: #08e8 -- End of level"
                                  ; ld (hl),#0c   ; signals end of level; we stop recording or playback here if necessary
                                    call    Op36
                                    .if     pacmode == PACMODE_RECORD
                                            pushad
                                            invoke  StreamEndDataOut    ; end input recording for this level
                                            popad
                                    .endif

                                    .if     pacmode == PACMODE_PLAYBACK
                                            invoke  Free_PacInputMem
                                    .endif

                          ; ===================================================================================================================
                            case    PACTRAP_0919+1

                                    ADDMESSAGE  "Pacman Trap: #0919 -- Pacman died"
                                    ; ld a,(#4e14)
                                    call    Op3A

                          ; ===================================================================================================================
                            case    PACTRAP_091f+1

                                    ADDMESSAGE  "Pacman Trap: #091f -- Game Over"
                                    ; ld a,(#4e70)
                                    call    Op3A

;                                    invoke  Disable_Pacmode
                                    .if     pacmode != PACMODE_FREEPLAY
                                            invoke  Disable_Pacmode
                                    .endif

                          ; ===================================================================================================================
                            case    PACTRAP_18c5+1

                                    ;ADDMESSAGE  "PACTRAP_18c5 -- Read/Write controller byte"
                                  ; ld    a,(#5000)   ; A = controller input byte
                                    call    Op3A
                                    .if     pacmode == PACMODE_RECORD
                                            pushad
                                            invoke  StreamPacDataOut, Reg_A
                                            popad

                                    .elseif pacmode == PACMODE_PLAYBACK
                                            invoke  ReadPacController
                                            mov     Reg_A, al
                                    .endif

                          ; ===================================================================================================================
                            case    PACTRAP_0795+1

                                  ; this filters out garbage making the kill screen "playable"
                                    call    OpC9    ; return after drawing fruits

                                    invoke  ReadZ80Byte, 4e13h ; Level counter address
                                    .if     (al == 255) && (pacmode == PACMODE_RECORD)
                                            ADDMESSAGE  "Pacman Trap: #0795 -- Filter kill screen garbage"
                                            invoke  FixupLevel255
                                    .endif

                          ; =======================
                            .else
                                    ADDMESSAGE  "Pacman Trap -- WTF!"

                    endsw

                    mov     ax, z80registers.pc
                    mov     Z80PC, ax

                    ret
Handle_Pac_Patches  endp

; called from within the z80 core when Pacman level is first initialised and then incremented per level
align 16
LoadPacLevel_Input  proc    uses esi edi ebx

                    local   inputfilepath[MAX_PATH]:BYTE

                    local   level:  BYTE

                    invoke  Free_PacInputMem

                    invoke  ReadZ80Byte, 4e13h ; Level counter address
                    mov     level, al

                    ; temp code, make sure no deaths occur from input stream on any level up to level 255
;                    .if     level == 255
;                            invoke  Disable_Pacmode
;                            invoke  PostMessage, hWnd, WM_KEYDOWN, VK_PAUSE, "BRK"
;                            ret
;                    .endif

                    movzx   ecx, level
                    mov     byte ptr inputfilepath[0], 0
                    invoke  szMultiCat, 5, addr inputfilepath,
                                           addr pacmanfilepath, SADD ("recordings\"), SADD ("pac_level_"), str$ (ecx), SADD (".inp")

                    invoke  ReadFileToMemory, addr inputfilepath, addr pacinput_base, addr pacinput_len
                    .if     eax != 0
                            m2m     pacinput_ptr, pacinput_base
                            ; we have an input file for this level
                            mov     paclevel_loaded, TRUE
                            mov     pac_input_pair, 0   ; clear data pair to force data stream read for first pair
                            ret
                    .endif

                    .if     (level >= 20) && (level <= 254)
                            ; use level 20 input file for levels from 20 through to 254

                            mov     byte ptr inputfilepath[0], 0
                            invoke  szMultiCat, 4, addr inputfilepath,
                                                   addr pacmanfilepath, SADD ("recordings\"), SADD ("pac_level_20"), SADD (".inp")

                            invoke  ReadFileToMemory, addr inputfilepath, addr pacinput_base, addr pacinput_len
                            .if     eax != 0
                                    m2m     pacinput_ptr, pacinput_base
                                    ; we have an input file for this level
                                    mov     paclevel_loaded, TRUE
                                    mov     pac_input_pair, 0   ; clear data pair to force data stream read for first pair
                                    ret
                            .endif
                    .endif

                    ; else no input file available
                    CLEARSOUNDBUFFERS
                    invoke  ShowMessageBox, $fnc (GetActiveWindow), SADD ("No input data for this level"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                    invoke  Disable_Pacmode
                    ret

LoadPacLevel_Input  endp

align 16
Draw_Pacman_Level_Text  proc    uses    esi edi ebx

                        local   textstring: TEXTSTRING,
                                pTEXTSTRING:DWORD

                        local   level:      BYTE,
                                numplayers: BYTE

                        ifc     pacmode eq PACMODE_NONE then ret

                      ; (4e00) = 3 for somebody is playing
                        invoke  ReadBankByte, 1, 4e00h
                        ifc     al ne 3 then ret

                        invoke  ReadZ80Byte, 4e70h ; number of players
                        mov     numplayers, al

                        invoke  SetDIBPaper, 0
                        invoke  SetDIBInk,   5

                        invoke  ReadBankByte, 1, 4e13h  ; Level counter address
                        mov     level, al

                        invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                        movzx   eax, level
                        inc     eax             ; start counting from 1 for on-screen level display
                        ADDTEXTDECIMAL  pTEXTSTRING, ax, ATD_ZEROES

                        invoke  SetDIBDrawPosn, (19*8)-2, @EVAL (MACHINE.TopBorderLines + 196)
                        mov     byte ptr textstring[6], 0
                        invoke  DrawDIBText, addr textstring[2]

                        invoke  SetDIBDrawPosn, 18*8, 1*8
                        invoke  DrawDIBText, SADD ("HIGH")
                        invoke  SetDIBDrawPosn, 17*8, 2*8
                        invoke  GetBankAddr, 1
                        add     eax, (4e8ah and 3fffh)  ; High score
                        invoke  DrawPacScore, eax
                        ret

;                        invoke  SetDIBDrawPosn, 12*8, 1*8
;                        invoke  DrawDIBText, SADD ("1UP   HIGH")
;
;                        invoke  SetDIBDrawPosn, 10*8, 2*8
;                        invoke  GetBankAddr, 1
;                        add     eax, (4e82h and 3fffh)  ; Player 1 score
;                        invoke  DrawPacScore, eax
;
;                        invoke  DrawDIBText, SADD (" ")
;                        invoke  GetBankAddr, 1
;                        add     eax, (4e8ah and 3fffh)  ; High score
;                        invoke  DrawPacScore, eax
;
;                        .if     numplayers
;                                invoke  SetDIBDrawPosn, 26*8, 1*8
;                                invoke  DrawDIBText, SADD ("2UP")
;
;                                invoke  SetDIBDrawPosn, 24*8, 2*8
;                                invoke  GetBankAddr, 1
;                                add     eax, (4e86h and 3fffh)  ; Player 2 score
;                                invoke  DrawPacScore, eax
;                        .endif
;                        ret

Draw_Pacman_Level_Text  endp

align 16
DrawPacScore            proc    uses    esi edi ebx,
                                lpBCDTrio:  DWORD

                        local   leadzeroes: BYTE

                        mov     esi, lpBCDTrio
                        mov     bh, " "

                        SETLOOP 3
                                ifc     dword ptr [esp] eq 1 then mov bh, "0"
                                mov     bl, [esi]
                                dec     esi

                                SETLOOP 2
                                        ror     bl, 4
                                        mov     al, bl
                                        and     al, 15
                                        je      @F
                                        mov     bh, "0"
                                    @@: add     al, bh
                                        invoke  DrawDIBChar, al
                                ENDLOOP
                        ENDLOOP

                        ret
DrawPacScore            endp

align 16
DrawBCDByte             proc    uses        edi,
                                value:      BYTE

                        mov     al, value
                        shr     al, 4
                        add     al, "0"
                        invoke  DrawDIBChar, al

                        mov     al, value
                        and     al, 15
                        add     al, "0"
                        invoke  DrawDIBChar, al

                        ret

DrawBCDByte             endp


; see #08de - marks end of Pacman level
; =====================================

; for PACMODE_RECORD
; only called from the (patched) LD A,(nn) opcode in the core where it reads its control input from the game loop only
; we start recording input here for this level if enabled

align 16
StreamPacDataOut    proc    uses     esi edi ebx,
                            io_byte: BYTE

                    local   textstring:     TEXTSTRING,
                            pTEXTSTRING:    DWORD

                    local   inputfilepath[MAX_PATH]:BYTE

                    local   level:  BYTE

                    .if     pac_strm_handle != 0
                            jmp     @@write_pac_byte
                    .endif

                    invoke  ReadZ80Byte, 4e13h ; Level counter address
                    mov     level, al

                    movzx   ecx, level
                    mov     byte ptr inputfilepath[0], 0
                    invoke  szMultiCat, 4, addr inputfilepath,
                                           addr pacmanfilepath, SADD ("pac_level_"), str$ (ecx), SADD (".inp")


                    CLEARSOUNDBUFFERS
                    .if     $fnc (AskOverwriteFile, addr inputfilepath, hWnd, addr szWindowName) == FALSE
                            invoke  Disable_Pacmode
                            return  0
                    .endif

                    mov     pac_strm_handle, $fnc (CreateFileStream, addr inputfilepath, FSA_WRITE, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 1024)
                    ifc     pac_strm_handle eq 0 then invoke  Disable_Pacmode : return 0

                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                    ADDDIRECTTEXTSTRING pTEXTSTRING, "Recording input for level "
                    ADDTEXTDEC          pTEXTSTRING, level

                    invoke  Add_Message_Item, addr textstring

                    mov     al, io_byte
                    xor     ah, ah              ; this will be incremented to 1 on first (certain) byte match below
                    mov     pac_input_pair, ax  ; init first byte pair for new recording file

@@write_pac_byte:   mov     ax, pac_input_pair
                    mov     cl, io_byte

                    .if     (cl != al) || (ah == 255)
                          ; different kempston byte or maxed out counter
                            invoke  StreamPacDataPair

                            mov     al, io_byte
                            mov     ah, 1               ; initialise a new pair
                    .else
                            inc     ah                  ; increase current counter
                    .endif
                    mov     pac_input_pair, ax
                    ret

StreamPacDataOut    endp

align 16
StreamPacDataPair   proc

                    .if     pac_input_pair != 0
                            invoke  WriteFileStream, pac_strm_handle, addr pac_input_pair, 2
                            mov     pac_input_pair , 0
                    .endif
                    ret

StreamPacDataPair   endp

; ends any current recording stream
; called from the patch of the LD (HL),n opcode that increments the level counter
align 16
StreamEndDataOut    proc

                    invoke  StreamPacDataPair   ; stream any final data pair

                    ifc     pac_strm_handle ne 0 then invoke CloseFileStream, pac_strm_handle : mov pac_strm_handle, 0
                    ADDMESSAGE  "Recording stopped"
                    ret

StreamEndDataOut    endp

align 16
ReadPacController   proc    uses esi edi ebx

                    ifc     paclevel_loaded eq FALSE then return 0

                    mov     ax, pac_input_pair
                    .if     ah > 0
                            dec     ah
                            mov     pac_input_pair, ax
                            ret     ; al = kempston byte from data pair
                    .endif

                    .if     $fnc (ReadPacInputPair) == -1
                            ADDMESSAGE  "Out of input data"
                            invoke  Disable_Pacmode

;                            invoke  ReadZ80Byte, 4e13h ; Level counter address
;                            .if     al == 255
;                                    invoke  AddTaskQueue, TASK_WAIT_SECONDS, TASKARG_NUMERIC, SADD ("10")
;                                    invoke  AddTaskQueue, TASK_EXIT, TASKARG_NONE, 0
;                            .endif

                            return  -1   ; out of input data
                    .endif

                    dec     ah                  ; as we're returning the first byte now...
                    mov     pac_input_pair, ax  ; al = kempston byte from data pair
                    ret
ReadPacController   endp

align 16
ReadPacInputPair    proc    uses    esi

                    .if     (pacinput_ptr != 0) && (pacinput_len >= 2)
                            mov     esi, pacinput_ptr
                            movzx   eax, word ptr [esi]
                            add     esi, 2

                            mov     pacinput_ptr, esi
                            sub     pacinput_len, 2
                            ret
                    .endif

                    return  -1      ; return -1 as dword for EOF
                    ret

ReadPacInputPair    endp

align 16
ReadPacInputByte    proc    uses    esi

                    .if     (pacinput_ptr != 0) && (pacinput_len > 0)
                            mov     esi, pacinput_ptr
                            movzx   eax, byte ptr [esi]
                            inc     esi

                            mov     pacinput_ptr, esi
                            dec     pacinput_len
                            ret
                    .endif

                    return  -1      ; return -1 as dword for EOF
                    ret

ReadPacInputByte    endp

;% 11000000 = maze blocked char
;map space =  #40
;pill =       #10
;power pill = #14
;
;stop block = #d3

; draw fruits at 2bf0

align 16
FixupLevel255       proc    uses    esi edi

                    mov     edi, currentMachine.bank1   ; #4000

                    mov     esi, 41h        ; upper right of maze data

                    SETLOOP 17
                            push    esi

                            SETLOOP 32
                                    mov     al, [edi+esi]

                                    switch  al
                                            case    10h, 14h
                                                    ; leave pellets, power pellets alone

                                            .else
                                                    and     al, 192
                                                    .if     al == 192
                                                            mov     byte ptr [edi+esi], 0d3h
                                                    .else
                                                            mov     byte ptr [edi+esi], 40h
                                                    .endif

                                    endsw

                                    inc     esi ; down one maze char
                            ENDLOOP

                            pop     esi
                            add     esi, 20h    ; move left one maze char
                    ENDLOOP

                    ret

FixupLevel255       endp

align 16
GetPacmanFilepath   proc    lpfilepath: DWORD

                    mov     eax, lpfilepath
                    mov     byte ptr [eax], 0
                    invoke  szMultiCat, 2, eax, offset appPath, SADD ("pacman\")

                    ret
GetPacmanFilepath   endp

.data
align 4
pacromptrs          dd      ROMs_PacMan
                    dd      ROMs_PacMan + 1000h
                    dd      ROMs_PacMan + 2000h
                    dd      ROMs_PacMan + 3000h

pacromchars         db      "e", 0
                    db      "f", 0
                    db      "h", 0
                    db      "j", 0

pacromCRCs          dw      1FDDh
                    dw      45B9h
                    dw      0F7CCh
                    dw      1D84h

;ROMs_PacMan

.code
align 16
LoadPacmanROMs      proc    uses esi edi ebx

                    local   filehandle:HANDLE
                    local   pacromfilepath[MAX_PATH]:BYTE

                    ForLp   ebx, 0, 3
                            mov     pacromfilepath, 0
                            invoke  szMultiCat, 4, addr pacromfilepath,
                                                   addr pacmanfilepath, SADD ("roms\"), SADD ("pacman.6"), addr [pacromchars+ebx*2]


                            mov     filehandle, $fnc (CreateFile, addr pacromfilepath, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
                            .if     filehandle != INVALID_HANDLE_VALUE
                                    invoke  ReadFile, filehandle, [pacromptrs+ebx*4], 1000h, addr BytesMoved, NULL
                                    invoke  CloseHandle, filehandle
                            .endif

                            invoke  Calc_CRC16_Data, [pacromptrs+ebx*4], 1000h
                            cmp     ax, [pacromCRCs+ebx*2]
                            jne     @wrongpacromset


                    Next    ebx

                    mov     HavePacmanROMs, TRUE
                    return  TRUE

@wrongpacromset:    mov     HavePacmanROMs, FALSE
                    return  FALSE

LoadPacmanROMs      endp

align 16
PrepPacManEnviron   proc

                    ifc     HavePacmanROMs eq FALSE then return FALSE

                    invoke  LoadSZXMemory, addr pacman_noroms_szx, pacman_noroms_szx_size
                    IFDEF   DEBUGBUILD
                            .if     eax == 0
                                    invoke  ShowMessageBox, $fnc (GetActiveWindow), SADD ("Internal Pac-Man snapshot failed to load"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                    return  FALSE
                            .endif
                    ENDIF

                    IFDEF   DEBUGBUILD
                            .if     $fnc (Pac_Is_0123) == FALSE
                                    ADDMESSAGE  "Internal Pac-Man snapshot has wrong config: Not in RAM 0/1/2/3 mode"
                                    return  FALSE
                            .endif
                    ENDIF

                    ; copy Pac-Man ROMs into +3 memory
                    memcpy  addr ROMs_PacMan, currentMachine.bank0, 4000h   ; bank 0: 0000-3fff - 16K Pac-Man ROM

                    mov     eax, currentMachine.bank3
                    add     eax, (0E000h - 0C000h)
                    memcpy  addr ROMs_PacMan, eax, 2000h                    ; bank 3: e000-ffff - first 8K of Pac-Man ROM (unpatched)

                    ; apply obo's PAC-Man ROM patches
                    ; https://github.com/simonowen/pacemuzx/blob/master/pacemuzx.asm
                    ; "patch_rom" proc

                    ; ==========================================
                    ; check these if switching to new snapshot
                    pac_do_int_hook     equ     0A15Ah
                    pac_text_fix        equ     0A154h

                    ;ld  a,&c3            ; JP nn
                    ;ld  (&0038),a
                    invoke  WriteBankByte, 0, 0038h, 0c3h

                    ;ld  hl,do_int_hook   ; interrupt hook
                    ;ld  (&0039),hl
                    invoke  WriteBankWord, 0, 0039h, pac_do_int_hook

                    ;ld  a,&cd            ; CALL nn
                    ;ld  (&2c62),a
                    invoke  WriteBankByte, 0, 2c62h, 0cdh
                    ;ld  hl,text_fix      ; fix bit 7 being set in horizontal text screen writes
                    ;ld  (&2c63),hl
                    invoke  WriteBankWord, 0, 2c63h, pac_text_fix
                    ; ==========================================

                    ;ld  a,&56            ; ED *56*
                    ;ld  (&233c),a        ; change IM 2 to IM 1
                    invoke  WriteBankByte, 0, 233ch, 56h

                    ;ld  hl,&47ed
                    ;ld  (&233f),hl       ; change OUT (&00),A to LD I,A
                    invoke  WriteBankWord, 0, 233fh, 47edh
                    ;ld  (&3183),hl
                    invoke  WriteBankWord, 0, 3183h, 47edh

                    ;ld  hl,&04d6         ; SUB 4
                    ;ld  (&3181),hl       ; restore original instruction in patched bootleg ROMs
                    invoke  WriteBankWord, 0, 3181h, 04d6h

                    ;ld  a,&01            ; to change &5000 writes to &5001, which is unused
                    ;ld  (&0093),a
                    invoke  WriteBankByte, 0, 0093h, 01h
                    ;ld  (&01d7),a
                    invoke  WriteBankByte, 0, 01d7h, 01h
                    ;ld  (&2347),a
                    invoke  WriteBankByte, 0, 2347h, 01h
                    ;ld  (&238a),a
                    invoke  WriteBankByte, 0, 238ah, 01h
                    ;ld  (&3194),a
                    invoke  WriteBankByte, 0, 3194h, 01h
                    ;ld  (&3248),a
                    invoke  WriteBankByte, 0, 3248h, 01h

                    ;ld  a,1              ; start clearing at &5001, to avoid DIP overwrite
                    ;ld  (&230c),a
                    invoke  WriteBankByte, 0, 230ch, 01h
                    ;ld  (&2353),a
                    invoke  WriteBankByte, 0, 2353h, 01h
                    ;ld  a,7              ; shorten block clear after start adjustment above
                    ;ld  (&230f),a
                    invoke  WriteBankByte, 0, 230fh, 07h
                    ;ld  (&2357),a
                    invoke  WriteBankByte, 0, 2357h, 07h

                    ;ld  a,&41            ; start clearing at &5041, to avoid DIP overwrite
                    ;ld  (&2363),a
                    invoke  WriteBankByte, 0, 2363h, 41h
                    ;ld  a,&3f            ; shorten block clear after start adjustment above
                    ;ld  (&2366),a
                    invoke  WriteBankByte, 0, 2366h, 3fh

                    ;ld  a,&b0            ; LSB of address in look-up table
                    ;ld  (&3ffa),a        ; skip memory test (actual code starts at &3000)
                    invoke  WriteBankByte, 0, 3ffah, 0b0h

                    ;ld  hl,&e0f6         ; change AND &1F to OR &E0 so ROM peeks are from unmodified copy of the ROM
                    ;ld  (&2a2d),hl       ; (used as random number source for blue ghost movements)
                    invoke  WriteBankWord, 0, 2a2dh, 0e0f6h

                    ;ld  a,&dc            ; CALL C,nn
                    ;ld  (&0353),a        ; disable 1UP/2UP flashing to save cycles
                    invoke  WriteBankByte, 0, 0353h, 0dch
                    ;ld  (&035e),a
                    invoke  WriteBankByte, 0, 035eh, 0dch

                    ; create crc16 for upper 8K of Pacman ROM (bank 0)
                    mov     eax, currentMachine.bank0
                    add     eax, 2000h
                    invoke  Calc_CRC16_Data, eax, 2000h
                    mov     pacromcrc_upper, ax

                    ret

PrepPacManEnviron   endp



;patch_rom:     ld  a,&56            ; ED *56*
;               ld  (&233c),a        ; change IM 2 to IM 1
;
;               ld  hl,&47ed
;               ld  (&233f),hl       ; change OUT (&00),A to LD I,A
;               ld  (&3183),hl
;
;               ld  a,&c3            ; JP nn
;               ld  (&0038),a
;               ld  hl,do_int_hook   ; interrupt hook
;               ld  (&0039),hl
;
;               ld  hl,&04d6         ; SUB 4
;               ld  (&3181),hl       ; restore original instruction in patched bootleg ROMs
;
;               ld  a,&01            ; to change &5000 writes to &5001, which is unused
;               ld  (&0093),a
;               ld  (&01d7),a
;               ld  (&2347),a
;               ld  (&238a),a
;               ld  (&3194),a
;               ld  (&3248),a
;
;               ld  a,1              ; start clearing at &5001, to avoid DIP overwrite
;               ld  (&230c),a
;               ld  (&2353),a
;               ld  a,7              ; shorten block clear after start adjustment above
;               ld  (&230f),a
;               ld  (&2357),a
;
;               ld  a,&41            ; start clearing at &5041, to avoid DIP overwrite
;               ld  (&2363),a
;               ld  a,&3f            ; shorten block clear after start adjustment above
;               ld  (&2366),a
;
;               ld  a,&b0            ; LSB of address in look-up table
;               ld  (&3ffa),a        ; skip memory test (actual code starts at &3000)
;
;               ld  hl,&e0f6         ; change AND &1F to OR &E0 so ROM peeks are from unmodified copy of the ROM
;               ld  (&2a2d),hl       ; (used as random number source for blue ghost movements)
;
;               ld  a,&cd            ; CALL nn
;               ld  (&2c62),a
;               ld  hl,text_fix      ; fix bit 7 being set in horizontal text screen writes
;               ld  (&2c63),hl
;
;               ld  a,&dc            ; CALL C,nn
;               ld  (&0353),a        ; disable 1UP/2UP flashing to save cycles
;               ld  (&035e),a


.code

                    ENDIF   ; IFDEF   PACMAN


