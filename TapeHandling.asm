
                        include Tapes.inc

StartStopTape           PROTO
SaveTapeChildDlgProc    PROTO   :DWORD,:DWORD,:DWORD,:DWORD

SetBlock19TapePolarity  PROTO   :BYTE

Set_Tape_Pause          PROTO   :WORD
Is_TZX_Data_Block       PROTO   :BYTE

.data
WAVBlockHeader          db   BLOCK_WAV
TapeWavHeader           BYTE WAVHEADERSIZE dup(?)
ERR_WaveFileError       db  "Wave File Error", 0

CSWBlockHeader          db  BLOCK_CSW
TapeCSWHeader           CSWHEADER   <>
ERR_CSWFileError        db  "CSW File Error", 0

szTapeFilter            db  "Tape files (*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx)", 0, "*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx", 0, 0

TZX_End_Pause_Block     db  SPECIAL_PAUSE_BLOCK
                        dw  2   ; 2 ms

.data?
align 4
PZX                     TPZX    <>

;--------------------------------------------------------------------------------
.code

WAIT_PULSE      macro
                local   looplabel

                call    FlipEar
                mov     TZXJump, offset looplabel

looplabel:      mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c

                mov     TapeTStates, ax
                endm

PULSE_LOW   macro
            ifc     EarBit ne 0 then call FlipEar
            endm

PULSE_HIGH  macro
            ifc     EarBit ne 64 then call FlipEar
            endm

InsertTape  proc

            local   ofn:    OPENFILENAME

            invoke  GetFileName, hWnd, SADD ("Insert Tape"), addr szTapeFilter, addr ofn, addr inserttapefilename, addr TZXExt
            ifc     eax eq 0 then ret   ; return error

            invoke  ReadFileType, addr inserttapefilename
            ret

InsertTape  endp

InsertTape_1    proc    uses        ebx esi edi,
                        lpFilename: DWORD

            mov     TapePlaying, FALSE    ; turn the tape off
            mov     SL_LoopCount, 0         ; reset load sensing code parameters
            mov     SL_LoaderPC, 0

            .if     $fnc (szLen, lpFilename) < 5
                    return  FALSE   ; error loading tape
            .endif

            m2m     Filename, lpFilename
            invoke  szRight,  lpFilename, addr TapeExtBuffer, 4
            invoke  lcase,    addr TapeExtBuffer

            mov     TapeDataBlockCnt, 0
            mov     FirstTAPBlockPtr, 0

            switch  dword ptr [TapeExtBuffer]
                    case    "pat."
                            call    OpenTAP_TZXFile
                    case    "klb."
                            call    OpenTAP_TZXFile
                    case    "xzt."
                            call    OpenTAP_TZXFile
                    case    "vaw."
                            call    OpenWAVFile
                    case    "wsc."
                            call    OpenCSWFile
                    case    "xzp."
                            call    OpenPZXFile
                    .else
                            return  FALSE   ; error loading tape
            endsw

            .if     eax == TRUE ; tape loaded successfully?

                    invoke  SetDirtyLines   ; force tape icon in border to appear if enabled in options

                    strncpy lpFilename, addr inserttapefilename, sizeof inserttapefilename

                    .if     inhibit_recent_file == FALSE
                            strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                            invoke      AddRecentFile
                    .endif

                    ; tape autoload is unavailable for DivIDE

                    .if     (AutoloadTapes == TRUE) && (DivIDEEnabled == FALSE)
                            invoke  GetAsyncKeyState, VK_SHIFT
                            test    ax, 8000h
                            .if     ZERO?
                                    ADDMESSAGE  "Autoloading tape"

                                    call    ResetSpectrum

                                    invoke  Set_RunTo_Condition, RUN_TO_AUTOLOADTAPE

                                    mov     autotype_stage, 0

                                    mov     autotype_CODE_block, FALSE
                                    .if     FirstTAPBlockPtr != 0
                                            mov     eax, FirstTAPBlockPtr
                                            .if     dword ptr [eax] == 03000013h
                                                    ; this is a standard code block header
                                                    mov     autotype_CODE_block, TRUE
                                            .endif
                                    .endif

                                    ; turn on maximum emulation speed for the tape autoload typing
                                    mov     MAXIMUMAUTOLOADTYPE, TRUE

                                    invoke  Set_Autotype_Rom_Point  ; sets autotype ROM pointer and PC address

                                    switch  HardwareMode
                                            case    HW_16, HW_48
                                                    mov     autotype_keybuffer, offset autotapekeys_48_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_48_CODE

                                            case    HW_128
                                                    mov     autotype_keybuffer, offset autotapekeys_128_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_128_CODE

                                            case    HW_PLUS2
                                                    mov     autotype_keybuffer, offset autotapekeys_128_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_128_CODE

                                            case    HW_PLUS2A, HW_PLUS3
                                                    mov     autotype_keybuffer, offset autotapekeys_Plus3_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_Plus3_CODE

                                            case    HW_PENTAGON128
                                                    mov     autotype_keybuffer, offset autotapekeys_128_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_128_CODE

                                            case    HW_TC2048
                                                    mov     autotype_keybuffer, offset autotapekeys_48_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_48_CODE

                                            case    HW_TK90X
                                                    mov     autotype_keybuffer, offset autotapekeys_48_BASIC
                                                    ifc     autotype_CODE_block eq TRUE then mov autotype_keybuffer, offset autotapekeys_48_CODE
                                    endsw
                            .endif
                    .endif
                    mov     eax, TRUE   ; tape loaded successfully
            .endif

            ; ensure EAR bit starts as low when loading a new tape; preserve the success/failure return value (EAX) too
            ifc     EarBit ne 0 then push eax : call FlipEar : pop eax

            ret     ; return with success/failure return value

InsertTape_1    endp

OpenCSWFile:
            invoke  CloseTapeFile

            invoke  CreateFile, Filename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            ifc     eax eq INVALID_HANDLE_VALUE then xor eax, eax
            mov     TapeFileHandle, eax

            .if     TapeFileHandle == 0
                    return  FALSE
            .endif

            invoke  ReadFile, TapeFileHandle, ADDR TapeCSWHeader, sizeof CSWHEADER, ADDR BytesMoved, NULL
            cmp     [BytesMoved], sizeof CSWHEADER
            jne     OpenTapeFail

            strncpy Filename, addr CSWfilename, sizeof CSWfilename

            mov     LastDataBlockPauseLocation, 0

            mov     edi, [TZXBlockPtrs]  ; store our block pointers here
            mov     [edi], offset CSWBlockHeader
            add     edi, 4
            xor     eax, eax
            mov     [edi], eax

            mov     CSW_Load_Handle, $fnc (OpenCSW, Filename)
            ifc     eax eq NULL then jmp OpenTapeFail

            mov     LoadTapeType, Type_CSW
            jmp     TapeInit

OpenWAVFile:
            invoke  CloseTapeFile

            invoke  CreateFile, Filename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            ifc     eax eq INVALID_HANDLE_VALUE then xor eax, eax
            mov     TapeFileHandle, eax

            .if     TapeFileHandle == 0
                    return  FALSE
            .endif

            invoke  ReadFile, TapeFileHandle, ADDR TapeWavHeader, WAVHEADERSIZE, ADDR BytesMoved, NULL
            cmp     [BytesMoved], WAVHEADERSIZE
            jne     OpenTapeFail

            strncpy Filename, addr WAVfilename, sizeof WAVfilename

            lea     esi, TapeWavHeader

            mov     ax, [esi+22]            ; num channels
            mov     WAVChannels, ax

            movzx   eax, word ptr [esi+24]  ; sample frequency, Hz
            .if     (eax == 0) || (WAVChannels == 0)
                    invoke  ShowMessageBox, hWnd, SADD("Invalid WAV file"),
                                                  ADDR ERR_WaveFileError,
                                                  MB_OK or MB_ICONINFORMATION
                    jmp      OpenTapeFail
            .endif

;            invoke  IntDiv, 3500000, eax
            invoke  Div2Int, 3500000, eax
            mov     WAVPulseLength, ax

            movzx   eax, word ptr [esi+34]    ; bits per sample
            mov     WAVBits, eax

            .if     (eax != 8) && (eax != 16)
                    invoke  ShowMessageBox, hWnd, SADD("SpecEmu only supports 8 bit and 16 bit wave recordings"),
                                                  ADDR ERR_WaveFileError,
                                                  MB_OK or MB_ICONINFORMATION
                    jmp      OpenTapeFail
            .endif

            mov     LastDataBlockPauseLocation, 0

            mov     edi, [TZXBlockPtrs]  ; store our block pointers here
            mov     [edi], offset WAVBlockHeader
            add     edi, 4
            xor     eax, eax
            mov     [edi], eax

            mov     LoadTapeType, Type_WAV
            jmp     TapeInit

OpenPZXFile:
            invoke  CloseTapeFile

            invoke  ReadFileToMemory, Filename, addr _tapfileptr, addr _tapfilesize
            or      eax, eax
            je      OpenTapeFail

            mov     edi, [TZXBlockPtrs]  ; store our block pointers here
            mov     esi, [_tapfileptr]   ; start of pzx file in memory
            mov     edx, esi
            add     edx, [_tapfilesize]  ; end of pzx file area

            lodsd
            cmp     eax, "TXZP"
            jne     OpenTapeFail

            lodsd                       ; size of the block
            .if     (eax < 2) || (byte ptr [esi] != 1)
                    jmp     OpenTapeFail    ; fail for blocksize < 2 or not a v1 PZX file
            .endif

            add     esi, eax            ; esi = first PZX block

            mov     LoadTapeType, Type_PZX

            mov     TZXAvail, @EVAL (edx - esi) ; TZXAvail = max available PZX bytes left

NextPZXBlock:
            mov     dword ptr [edi], 0

            cmp     esi, edx
            je      AppendPZXBlock   ; reached end of PZX file
            jc      @F              ; more PZX blocks to come

            mov     dword ptr [edi-4], 0  ; null invalid PZX block pointer
            jmp     TapeInit

@@:         mov     [edi], esi      ; store PZX block pointer
            add     edi, 4

            sub     TZXAvail, 8     ; ensure we have at least "block header" bytes available
            jc      OpenTapeFail

            mov     eax, [esi]      ; eax = block ID
            mov     ebx, [esi+4]    ; ebx = block size
            add     esi, 8          ; esi = block data

            sub     TZXAvail, ebx   ; ensure we have at least "block size" bytes available
            jc      OpenTapeFail

            add     esi, ebx        ; advance to next PZX block
            jmp     NextPZXBlock

AppendPZXBlock:
            mov     dword ptr [edi], offset PZX_FinalPulse  ; store PZX_FinalPulse PZX block pointer
            mov     dword ptr [edi+4], 0
            jmp     TapeInit


.data
PZX_FinalPulse  db      "****"
                dd      0

.code

          ; initialise PZX block for playing
Init_PZX_Block:
            mov     esi, BlockData

            mov     eax, [esi]          ; eax = PZX block ID
            mov     ecx, [esi+4]        ; ecx = block size
            add     esi, 8              ; esi = block data

            mov     PZX.BlockData, esi
            mov     PZX.BlockSize, ecx

            cmp     eax, "SLUP"
            je      InitPZX_PULS

            cmp     eax, "ATAD"
            je      InitPZX_DATA

            cmp     eax, "SUAP"
            je      InitPZX_PAUS

            cmp     eax, "POTS"
            je      InitPZX_STOP

            cmp     eax, "****"
            je      InitPZX_FINAL

            jmp     IncPlayNextBlock    ; skip unknown PZX block type


;PULS - Pulse sequence
;---------------------
;0 u16 count -     bits 0-14 optional (see bit 15) repeat count, always greater than zero
;                  bit 15 repeat count present: 0 not present 1 present
;2 u16 duration1 - bits 0-14 low/high (see bit 15) pulse duration bits
;                  bit 15 duration encoding: 0 duration1 1 ((duration1<<16)+duration2)
;4 u16 duration2 - optional (see bit 15 of duration1) low bits of pulse duration
;... ditto repeated until the end of the block

align 16
InitPZX_PULS:
            ifc     EarBit ne 0 then call FlipEar

NextPZX_PULS:
            cmp     PZX.BlockSize, 0
            je      IncPlayNextBlock

            mov     esi, PZX.BlockData

            mov     PZX.Count, 1

            sub     PZX.BlockSize, 2
            jc      IncPlayNextBlock

            movzx   eax, word ptr [esi]             ; u16 count
            add     esi, 2
            mov     PZX.Duration, eax

            .if     eax > 8000h
                    and     eax, 7FFFh
                    mov     PZX.Count, eax
                    sub     PZX.BlockSize, 2
                    jc      IncPlayNextBlock

                    movzx   eax, word ptr [esi]     ; u16 duration1
                    add     esi, 2
                    mov     PZX.Duration, eax
            .endif

            .if     eax >= 8000h
                    and     eax, 7FFFh
                    shl     eax, 16
                    sub     PZX.BlockSize, 2
                    jc      IncPlayNextBlock

                    mov     ax, [esi]               ; u16 duration2
                    mov     PZX.Duration, eax
                    add     esi, 2
            .endif

            mov     PZX.BlockData, esi

            .if     PZX.Duration == 0
                    test    PZX.Count, 1
                    .if     !ZERO?
                            call    FlipEar         ; flip ear if count is odd
                    .endif
                    jmp     NextPZX_PULS            ; back for next pulse from block
            .endif

            .while  PZX.Count > 0
                    dec     PZX.Count

                    m2m     PZX.Duration1, PZX.Duration

                    mov     TZXJump, offset @F
                @@: movzx   eax, TapeTStates
                    mov     ebx, PZX.Duration
                    sub     ebx, eax
                    jbe     @F

                    mov     PZX.Duration, ebx
                    mov     TapeTStates, 0
                    ret

                @@: neg     ebx
                    mov     TapeTStates, bx

                    m2m     PZX.Duration, PZX.Duration1

                    call    FlipEar
            .endw

            jmp     NextPZX_PULS


align 16
InitPZX_DATA:
            lodsd
            mov     ecx, eax
            and     ecx, 7FFFFFFFh
            mov     PZX.NumDataStreamBits, ecx

            and     eax, (1 shl 31)
            .if     ZERO?
                    ifc     EarBit ne 0  then call FlipEar
            .else
                    ifc     EarBit ne 64 then call FlipEar
            .endif

            lodsw
            mov     PZX.TailPulse, ax

            lodsb
            mov     PZX.Data_p0, al
            lodsb
            mov     PZX.Data_p1, al

            mov     PZX.Data_s0, esi

            movzx   eax, PZX.Data_p0
            lea     esi, [esi+eax*2]
            mov     PZX.Data_s1, esi

            movzx   eax, PZX.Data_p1
            lea     esi, [esi+eax*2]
            mov     PZX.DataStream, esi

            mov     PZX.BitNumber, 7

PZXData_NextDataBit:
            cmp     PZX.NumDataStreamBits, 0
            je      PZXData_TailPulse

            dec     PZX.NumDataStreamBits

            mov     esi, PZX.DataStream
            movzx   cx,  PZX.BitNumber

            bt      [esi], cx
            setc    bh

            sub     cl, 1
            adc     esi, 0
            and     cl, 7

            mov     PZX.DataStream, esi
            mov     PZX.BitNumber, cl

            .if     bh == 0
                    mov     esi, PZX.Data_s0
                    movzx   eax, PZX.Data_p0
            .else
                    mov     esi, PZX.Data_s1
                    movzx   eax, PZX.Data_p1
            .endif

            mov     PZX.PulseSequence, esi
            mov     PZX.PulseCount, eax

PZXData_PulsesLoop:
            cmp     PZX.PulseCount, 0
            je      PZXData_NextDataBit

            dec     PZX.PulseCount

            mov     esi, PZX.PulseSequence
            movzx   eax, word ptr [esi]
            add     PZX.PulseSequence, 2
            mov     PZX.Duration, eax

            .if     PZX.Duration > 0
                    mov     TZXJump, offset @F
                @@: movzx   eax, TapeTStates
                    mov     ebx, PZX.Duration
                    sub     ebx, eax
                    jbe     @F

                    mov     PZX.Duration, ebx
                    mov     TapeTStates, 0
                    ret

                @@: neg     ebx
                    mov     TapeTStates, bx
            .endif

            call    FlipEar

            jmp     PZXData_PulsesLoop


PZXData_TailPulse:
            .if     PZX.TailPulse > 0
                    mov     TZXJump, offset @F
                @@: mov     ax, TapeTStates
                    mov     bx, PZX.TailPulse
                    sub     bx, ax
                    jbe     @F

                    mov     PZX.TailPulse, bx
                    mov     TapeTStates, 0
                    ret

                @@: neg     bx
                    mov     TapeTStates, bx
            .endif

            jmp     IncPlayNextBlock


align 16
InitPZX_PAUS:
            lodsd
            mov     ecx, eax
            and     ecx, 7FFFFFFFh
            mov     PZX.Pause, ecx

            and     eax, (1 shl 31)
            .if     ZERO?
                    ifc     EarBit ne 0  then call FlipEar
            .else
                    ifc     EarBit ne 64 then call FlipEar
            .endif

            mov     TZXJump, offset PZXPauseDelay

PZXPauseDelay:
            movzx   eax, TapeTStates
            mov     ecx, PZX.Pause
            sub     ecx, eax
            jbe     @F

            mov     PZX.Pause, ecx
            mov     TapeTStates, 0
            ret

@@:         neg     ecx
            mov     TapeTStates, cx
            jmp     IncPlayNextBlock


align 16
InitPZX_STOP:
            switch  word ptr [esi]
                    case    1
                            switch  HardwareMode
                                    case    HW_16, HW_48, HW_TC2048, HW_TK90X
                                            invoke  StartStopTape
                            endsw
                    .else
                            invoke  StartStopTape
            endsw
            jmp     IncPlayNextBlock


; extend the final pulse before ending tape playback - allows for DATA blocks with TAIL pulses of 0...
align 16
InitPZX_FINAL:
                mov     TZXJump, offset @F

@@:             mov     ax, TapeTStates
                sub     ax, 1710
                retcc   c
                mov     TapeTStates, ax

                jmp     IncPlayNextBlock


OpenTAP_TZXFile:
            invoke  CloseTapeFile

            invoke  CreateFile, Filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

            ifc     eax eq INVALID_HANDLE_VALUE then xor eax, eax
            mov     TapeFileHandle, eax

            .if     TapeFileHandle == 0
                    return  FALSE
            .endif

            invoke  GetFileSize, TapeFileHandle, NULL
            .if     (eax == -1) || (eax < 12)
                    jmp     OpenTapeFail
            .endif

            mov     _tapfilesize, eax
            invoke  GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, _tapfilesize
            cmp     eax, NULL
            je      OpenTapeFail

            mov     _tapfileptr, eax

            mov     ReadStart, eax
            mov     eax, _tapfilesize
            mov     ReadLen, eax
            call    ReadTAPFile
            cmp     _tapfilesize, eax
            jne     OpenTapeFail

            mov     LastDataBlockPauseLocation, 0   ; init last data block pause ptr to zero

            mov     esi, [_tapfileptr]
            lea     edi, _ZXTape_str
            mov     cl, 7
@@:         mov     al, [edi]
            inc     edi
            cmp     al, [esi]
            jne     TapeisTAP
            inc     esi
            dec     cl
            jnz     @B

TapeisTZX:  mov     LoadTapeType, Type_TZX

            mov     edi, [TZXBlockPtrs]  ; store our block pointers here
            mov     esi, [_tapfileptr]   ; start of tzx file in memory
            mov     edx, esi
            add     edx, [_tapfilesize]  ; end of tzx file area
            add     esi, 10              ; skip to body of first block

NextTZXBlock:
            xor     eax, eax
            mov     [edi], eax

            cmp     esi, edx
            je      TapeInit        ; reached end of TZX file
            jc      NextTZXBl1      ; more TZX blocks to come

            sub     edi, 4
            xor     eax, eax
            mov     [edi], eax       ; null invalid TZX block pointer
            jmp     TapeInit

NextTZXBl1: mov     [edi], esi
            add     edi, 4

            ; set TZXAvail to the max available TZX bytes left
            mov     TZXAvail, @EVAL (edx - esi)

            xor     ebx, ebx
            mov     al, [esi]
            inc     esi

            .if     al == 10h
                    mov     LastDataBlockPauseLocation, esi
                    inc     TapeDataBlockCnt

                    .if     TapeDataBlockCnt == 1
                            lea     eax, [esi+2]    ; ptr to TAP block data
                            mov     FirstTAPBlockPtr, eax
                    .endif

                    mov     bx, [esi+2]
                    add     ebx, 4
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 11h
                    lea     ecx, [esi+13]
                    mov     LastDataBlockPauseLocation, ecx
                    inc     TapeDataBlockCnt

                    mov     ebx, [esi+15]
                    and     ebx, 00FFFFFFh
                    add     ebx, 12h
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 12h
                    inc     TapeDataBlockCnt
                    add     esi, 4
                    jmp     NextTZXBlock
            .endif

            .if     al == 13h
                    inc     TapeDataBlockCnt
                    xor     eax, eax
                    mov     al, [esi]
                    inc     esi
                    shl     eax, 1
                    add     esi, eax
                    jmp     NextTZXBlock
            .endif

            .if     al == 14h
                    inc     TapeDataBlockCnt
                    lea     ecx, [esi+5]
                    mov     LastDataBlockPauseLocation, ecx

                    mov     ebx, [esi+7]
                    and     ebx, 00FFFFFFh
                    add     ebx, 10
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 15h
                    inc     TapeDataBlockCnt
                    lea     ecx, [esi+2]
                    mov     LastDataBlockPauseLocation, ecx

                    mov     ebx, [esi+5]
                    and     ebx, 00FFFFFFh
                    add     ebx, 8
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 18h
                    inc     TapeDataBlockCnt
                    mov     eax, [esi]
                    add     eax, 4
                    add     esi, eax
                    jmp     NextTZXBlock
            .endif

            .if     al == 19h
                    inc     TapeDataBlockCnt
                    ifc     TZXAvail lt 18  then jmp OpenTapeFail
                    mov     eax, [esi]
                    ifc     TZXAvail lt eax then jmp OpenTapeFail
                    add     eax, 4
                    add     esi, eax
                    jmp     NextTZXBlock
            .endif

            .if     al == 20h
                    add     esi, 2
                    jmp     NextTZXBlock
            .endif

            .if     al == 21h
                    mov     bl, [esi]
                    inc     ebx
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 22h
                    jmp     NextTZXBlock
            .endif

            .if     al == 23h
                    add     esi, 2
                    jmp     NextTZXBlock
            .endif

            .if     al == 24h
                    add     esi, 2
                    jmp     NextTZXBlock
            .endif

            .if     al == 25h
                    jmp     NextTZXBlock
            .endif

            .if     al == 26h
                    mov     bx, [esi]
                    shl     ebx, 1
                    add     ebx, 2
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 27h
                    jmp     NextTZXBlock
            .endif

            .if     al == 28h
                    mov     bx, [esi]
                    add     ebx, 2
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 2Ah
                    add     esi, 4
                    jmp     NextTZXBlock
            .endif

            .if     al == 2Bh
                    add     esi, 5
                    jmp     NextTZXBlock
            .endif

            .if     al == 30h
                    mov     bl, [esi]
                    inc     ebx
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 31h
                    mov     bl, [esi+1]
                    add     ebx, 2
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 32h
                    mov     bx, [esi]
                    add     ebx, 2
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 33h
                    mov     bl, [esi]
                    xor     cx, cx
                    mov     cl, bl
                    shl     bx, 1
                    add     bx, cx
                    inc     ebx
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 34h
                    add     esi, 8
                    jmp     NextTZXBlock
            .endif

            .if     al == 35h
                    mov     ebx, [esi+10h]
                    add     ebx, 14h
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 40h
                    mov     ebx, [esi+1]
                    and     ebx, 00FFFFFFh
                    add     ebx, 4
                    add     esi, ebx
                    jmp     NextTZXBlock
            .endif

            .if     al == 5Ah
                    add     esi, 9
                    jmp     NextTZXBlock
            .endif


            sub     edi, 4
            xor     eax, eax
            mov     [edi], eax   ; null ptr to unknown block type
            jmp     TapeInit


TapeisTAP:  mov     LoadTapeType, Type_TAP  ; treat ALL blocks as Standard speed blocks (10h)

            mov     edi, TZXBlockPtrs
            mov     esi, _tapfileptr
            mov     edx, esi
            add     edx, _tapfilesize

@@:         inc     TapeDataBlockCnt
            .if     TapeDataBlockCnt == 1
                    mov     FirstTAPBlockPtr, esi
            .endif

            mov     [edi], esi
            add     edi, 4
            movzx   eax, word ptr [esi]
            add     eax, 2
            add     esi, eax
            cmp     esi, edx
            jc      @B

            ; if non-zero, the last block length overran the filesize, so we remove the last TAP block pointer to prevent a segfault
            .if     !ZERO?
                    sub     edi, 4
            .endif

            xor     eax, eax
            mov     [edi], eax

; come here when a tape (of any type) has been successfully inserted
TapeInit:
            ; terminate TZX files with a special pause block to complete the last edge
            .if     LoadTapeType == Type_TZX
                    mov     [edi], offset TZX_End_Pause_Block
                    mov     dword ptr [edi+4], 0
            .endif

            mov     al, LoadTapeType
            .if     (al == Type_TAP) || (al == Type_TZX)
                    invoke  CloseHandle, TapeFileHandle     ; TAP and TZX files are closed upon loading
                    mov     TapeFileHandle, 0
            .endif

            mov     [TZXCurrBlock], 0
            mov     [TZXJump], offset PlayNextBlock
            mov     [TZXPause], 0
            PULSE_LOW

            mov     esi, [TZXBlockPtrs]
            xor     cx, cx
@@:         lodsd
            or      eax, eax
            je      @F
            inc     cx
            jmp     @B
@@:         mov     [TZXBlockCount], cx
            return  TRUE                ; signal tape loaded successfully

OpenTapeFail:
            invoke  CloseTapeFile
            ret


Is_TZX_Data_Block       proc    tzx_ID: BYTE

                        switch  tzx_ID
                        case    10h..15h, 18h..19h
                                return True
                        endsw

                        return  False
Is_TZX_Data_Block       endp

Set_Tape_Pause          proc    uses        esi edi ebx,
                                pauselen    :WORD

                        .if     LoadTapeType == Type_TZX
                                mov     edi, TZXBlockPtrs
                                movzx   ebx, TZXCurrBlock

                                .while  True
                                        inc     ebx                      ; move beyond the current block
                                        .break  .if bx >= TZXBlockCount

                                        mov     esi, [edi+ebx*4]
                                        or      esi, esi
                                        .break  .if ZERO?

                                        mov     al, [esi]
                                        .break  .if (al == 20h) && (word ptr [esi+1] == 0)  ; fall through to use 2 ms on STOP TAPE block

                                        .if     $fnc (Is_TZX_Data_Block, al) == True    ; test current TZX block ID
                                                mov     ax, pauselen
                                                mov     TZXWantPause, ax
                                                ret
                                        .endif
                                .endw

                                mov     TZXWantPause, 2

                        .elseif LoadTapeType == Type_TAP
                                mov     ax, pauselen
                                mov     TZXWantPause, ax
                        .endif
                        ret
Set_Tape_Pause          endp

; #########################################################################

SaveTapeChildDlgProc    proc    uses     ebx esi edi,
                                hWndDlg: DWORD,
                                uMsg:    DWORD,
                                wParam:  DWORD,
                                lParam:  DWORD

                        LOCAL   wParamLow:WORD, wParamHigh:WORD

            mov     eax, wParam
            mov     wParamLow, ax
            shr     eax, 16
            mov     wParamHigh, ax

            switch  uMsg
                    case    WM_INITDIALOG
                            ifc     SaveCSWFileVersion eq 1 then mov edx, IDC_SAVECSWV1RBN else mov edx, IDC_SAVECSWV2RBN
                            invoke  CheckRadioButton, hWndDlg, IDC_SAVECSWV1RBN, IDC_SAVECSWV2RBN, edx 

                            .if     SaveCSWSampleRate == 11025
                                    mov     edx, IDC_CSW11025RBN
                            .elseif SaveCSWSampleRate == 22050
                                    mov     edx, IDC_CSW22050RBN
                            .else
                                    mov     edx, IDC_CSW44100RBN
                            .endif
                            invoke  CheckRadioButton, hWndDlg, IDC_CSW11025RBN, IDC_CSW44100RBN, edx 
                            return  TRUE

                    case    WM_COMMAND
                            .if     wParamHigh == BN_CLICKED
                                    switch  wParamLow
                                            case    IDC_SAVECSWV1RBN
                                                    mov     SaveCSWFileVersion, 1
                                            case    IDC_SAVECSWV2RBN
                                                    mov     SaveCSWFileVersion, 2

                                            case    IDC_CSW11025RBN
                                                    mov     SaveCSWSampleRate, 11025
                                            case    IDC_CSW22050RBN
                                                    mov     SaveCSWSampleRate, 22050
                                            case    IDC_CSW44100RBN
                                                    mov     SaveCSWSampleRate, 44100
                                    endsw
                            .endif
            endsw
            return  FALSE

SaveTapeChildDlgProc    endp

; #########################################################################

.data
szSvTapeFilter          db  "Tape files (*.tap;*.csw)", 0, "*.tap;*.csw", 0, 0

szAskTurnBoostSavingOff db  "Virtual tape saving requires the save data tone boosting option to be turned off.", 13, 13
                        db  "Would you like the save data tone boosting to be turned off?", 0

.code
InsertSaveTape  proc

                local   ofn:    OPENFILENAME

                .if     BoostSavingNoise == TRUE
                        ; ask if user wants to switch "boost saving tones" option off
                        invoke  ShowMessageBox, hWnd, addr szAskTurnBoostSavingOff, addr szWindowName, MB_YESNO or MB_ICONQUESTION
                        .if     eax != IDYES
                                ret
                        .endif
                        mov     BoostSavingNoise, FALSE
                .endif

                invoke  SaveFileName, hWnd, SADD ("Insert a Tape for Saving"), addr szSvTapeFilter, addr ofn, addr SaveTapeFilename, NULL, 0
                .if     eax != 0
                        .if     $fnc (szLen, addr SaveTapeFilename) < 5
                                ret
                        .endif
                        invoke  szRight,  addr SaveTapeFilename, addr TapeExtBuffer, 4
                        invoke  lcase,    addr TapeExtBuffer

                        switch  dword ptr [TapeExtBuffer]
                                case    "pat."
                                        call    SetSavetoTAPFile
                                case    "wsc."
                                        call    SetSavetoCSWFile
                        endsw
                .endif
                ret
InsertSaveTape  endp

SetSavetoTAPFile:
            call    CloseSaveTapeFile

            mov     SaveTapeType, Type_TAP

            strncpy addr SaveTapeFilename, addr szRecentFileName, sizeof szRecentFileName
            invoke  AddRecentFile   ; add saved snapshot to recent files list
            ret

SetSavetoCSWFile:
            call    CloseSaveTapeFile

        RetryOpenCSWTape:
            invoke  CreateCSW, addr SaveTapeFilename, SaveCSWSampleRate, SaveCSWFileVersion
            .if     eax == NULL
                    .if     $fnc (GetLastError) == CSWERR_ALREADY_EXISTS
                            invoke  AppendCSW, addr SaveTapeFilename
                    .else
                            mov     eax, NULL
                    .endif
            .endif

            .if     eax == NULL
                    invoke  ShowMessageBox, hWnd, SADD ("Unable to open CSW file for saving"), addr szWindowName, MB_RETRYCANCEL or MB_ICONWARNING
                    cmp     eax, IDRETRY
                    je      RetryOpenCSWTape
                    ret
            .endif

            mov     CSW_Save_Handle, eax
            mov     SaveTapePulsePeriod, $fnc (GetPulsePeriod, CSW_Save_Handle)
            mov     SaveTapeTStates, 0

            mov     SaveTapeType, Type_CSW

            strncpy addr SaveTapeFilename, addr szRecentFileName, sizeof szRecentFileName
            invoke  AddRecentFile   ; add saved snapshot to recent files list
            ret


CloseSaveTapeFile:
            switch  SaveTapeType
                    case    Type_CSW
                            invoke  CloseCSW, CSW_Save_Handle
                            mov     CSW_Save_Handle, 0
            endsw

            mov     SaveTapeType, Type_NONE
            ret

align 16
WriteTapePulse:
            movzx   eax, [Z80TState]
            add     [SaveTapeTStates], eax

            switch  SaveTapeType
;                    case    Type_TAP
;                            ret
;                    case    Type_TZX
;                            ret
;                    case    Type_WAV
;                            ret
                    case    Type_CSW
                            mov     eax, SaveTapeTStates
                            .if     eax >= SaveTapePulsePeriod
                                    sub     eax, SaveTapePulsePeriod
                                    mov     SaveTapeTStates, eax
                                    movzx   edx, MICVal     ; use MICVal to output tape signal to CSW format
;                                    movzx   edx, EarBit     ; use EarBit to convert loading tape to CSW format
                                    invoke  WritePulseValue, CSW_Save_Handle, edx
                            .endif
                            ret
            endsw
            ret

; #########################################################################

CloseTapeFile proc  uses esi edi ebx

            call    InitTape

            ifc     LoadTapeType eq Type_CSW then invoke  CloseCSW, CSW_Load_Handle : mov CSW_Load_Handle, 0

            ifc     _tapfileptr ne 0 then invoke GlobalFree, _tapfileptr : mov _tapfileptr, 0

            ifc     TapeFileHandle ne 0 then invoke CloseHandle, TapeFileHandle : mov TapeFileHandle, 0

            mov     edi, [TZXBlockPtrs]
            mov     ecx, MAXTZXBLOCKS
            xor     eax, eax
            rep     stosd

            mov     LoadTapeType, Type_NONE     ; no tape inserted
            return  FALSE                       ; signal tape loading failed (if was loading)

CloseTapeFile endp

; #########################################################################

CloseTAPSaveFile:
            ifc     TapSaveFH ne 0 then invoke CloseHandle, TapSaveFH : mov TapSaveFH, 0
            ret

; #########################################################################

ReadTAPFile:
            invoke  ReadFile, TapeFileHandle, ReadStart, ReadLen, addr BytesMoved, NULL
            return  BytesMoved

;--------------------------------------------------------------------------------

align 16
InitTape:       mov     TZXJump, offset PlayNextBlock
                mov     TZXPause, 0
                mov     TapePlaying, FALSE
                ret

align 16
PlayTape:       ifc     EdgeTriggerAck eq TRUE then mov EdgeTrigger, FALSE

                ; last edges buffer is used for the tape icon in the border
                .if     tape_last_edges_rate == 0
                        movzx   eax, tape_last_edges_offset
                        add     eax, 1
                        and     eax, 15
                        mov     cl, EarBit
                        mov     [tape_last_edges_buffer+eax], cl
                        mov     tape_last_edges_offset, al
                .endif
                dec     tape_last_edges_rate

                movzx   ax, Z80TState
                add     TapeTStates, ax
                jmp     [TZXJump]

IncPlayNextBlock:
                inc     TZXCurrBlock

align 16
PlayNextBlock:  mov     TZXJump, offset PlayNextBlock

                xor     eax, eax
                mov     ax, TZXCurrBlock
                cmp     ax, TZXBlockCount
                jnc     ResetTZXTape

                cmp     TZXPause, 0
                jne     DoPauseWait

                mov     esi, TZXBlockPtrs
                mov     eax, [esi+eax*4]
                or      eax, eax
                jne     HandleTZXBlock

ResetTZXTape:   mov     TZXPause, 0
                mov     TapePlaying, FALSE

                mov     TZXJump, offset PlayNextBlock
                ret


RewindTZXTape:  ifc     LoadTapeType eq Type_CSW then invoke RewindTape, CSW_Load_Handle

                call    InitTape
                mov     TZXCurrBlock, 0
                ret

align 16
HandleTZXBlock: mov     BlockData, eax

                cmp     LoadTapeType, Type_PZX
                je      Init_PZX_Block

              ; treat each data block as a TZX block $10 if we're using a TAP file
                cmp     LoadTapeType, Type_TAP
                je      Block_10

              ; else these are real TZX file block IDs
                mov     esi, BlockData
                mov     al, [esi]

                cmp     al, 10h
                je      Block_10

                cmp     al, 11h
                je      Block_11

                cmp     al, 12h
                je      Block_12

                cmp     al, 13h
                je      Block_13

                cmp     al, 14h
                je      Block_14

                cmp     al, 15h
                je      Block_15

                cmp     al, 19h
                je      Block_19

                cmp     al, 20h                 ; PAUSE block
                je      Block_20

                cmp     al, SPECIAL_PAUSE_BLOCK ; we terminate TZX files with this PAUSE block
                je      Block_20

                cmp     al, 21h
                je      Block_21

                cmp     al, 22h
                je      Block_22

                cmp     al, 23h
                je      Block_23

                cmp     al, 24h
                je      Block_24

                cmp     al, 25h
                je      Block_25

                cmp     al, 26h
                je      Block_26

                cmp     al, 27h
                je      Block_27

                cmp     al, 28h
                je      Block_28

                cmp     al, 2Ah
                je      Block_2A

                cmp     al, 2Bh
                je      Block_2B

                cmp     al, 30h
                je      Block_30

                cmp     al, 31h
                je      Block_31

                cmp     al, 32h
                je      Block_32

                cmp     al, 33h
                je      Block_33

                cmp     al, 34h
                je      Block_34

                cmp     al, 35h
                je      Block_35

                cmp     al, 40h
                je      ResetTZXTape    ; snapshot block unsupported!

                cmp     al, 5Ah         ; merged header signature, skip.
                je      IncPlayNextBlock

                cmp     al, BLOCK_WAV
                je      PlayWAVBlock    ; decode and play external WAV file

                cmp     al, BLOCK_CSW
                je      PlayCSWBlock    ; decode and play external CSW file

                jmp     ResetTZXTape    ; unknown block type !!


Block_35:     ; Custom Info Block
Block_34:     ; Emulation Info Block
Block_33:     ; Hardware Type Block
Block_32:     ; Archive Info Block
Block_31:     ; Message Block
Block_30:     ; Test Description Block
Block_28:     ; Select Block
Block_22:     ; Group End Block
Block_21:     ; Group Start Block
Block_18:     ; CSW Recording Block

                jmp     IncPlayNextBlock

; Set Signal Level
align 16
Block_2B:       mov     al, [esi+5]
                .if     al == 0
                        mov     EarBit, 0
                        mov     EarVal, EarLowVal
                .else
                        mov     EarBit, 64
                        mov     EarVal, EarHighVal
                .endif
                jmp     IncPlayNextBlock


; STOP The Tape if in 48K Mode
align 16
Block_2A:       inc     TZXCurrBlock

                switch  HardwareMode
                        case    HW_16, HW_48, HW_TC2048, HW_TK90X
                                PULSE_LOW
                                mov TapePlaying, FALSE
                                ret
                endsw
                jmp     PlayNextBlock

; Return From Sequence Block
Block_27:       jmp     DoNextTZXCall

; Call Block Sequence
align 16
Block_26:       inc     esi
                mov     ax, [esi]
                add     esi, 2
                mov     TZXNumCalls, ax
                mov     TZXCallBlockPtr, esi
                mov     ax, TZXCurrBlock
                mov     TZXCallReturn, ax

DoNextTZXCall:  cmp     TZXNumCalls, 0
                jne     @F

                mov     ax, TZXCallReturn
                mov     TZXCurrBlock, ax
                jmp     IncPlayNextBlock    ; continue playing tape, skipping beyond the CALL block now

@@:             dec     TZXNumCalls
                mov     esi, TZXCallBlockPtr
                mov     ax, [esi]
                add     esi, 2
                mov     TZXCallBlockPtr, esi
                add     ax, TZXCurrBlock
                mov     TZXCurrBlock, ax
                jmp     PlayNextBlock

; Loop End Block
align 16
Block_25:       inc     TZXCurrBlock

                sub     TZXLoopCounter, 1
                jbe     PlayNextBlock           ; continue if CF=1 or ZF=1

                mov     ax, TZXLoopBlockNum     ; else loop back
                mov     TZXCurrBlock, ax
                jmp     PlayNextBlock

; Loop Start Block
align 16
Block_24:       inc     esi
                mov     ax, [esi]
                add     esi, 2
                mov     TZXLoopCounter, ax
                inc     TZXCurrBlock
                mov     ax, TZXCurrBlock
                mov     TZXLoopBlockNum, ax
                jmp     PlayNextBlock

; Jump To Block
align 16
Block_23:       inc     esi
                mov     ax, [esi]
                add     TZXCurrBlock, ax
                jmp     PlayNextBlock

; Pause (silence) or STOP THE TAPE
align 16
Block_20:       inc     TZXCurrBlock
                inc     esi
                mov     ax, [esi]
                add     esi, 2
                or      ax, ax
                jne     B20_Pause

                PULSE_LOW
                mov     TapePlaying, FALSE
                ret

B20_Pause:      mov     TZXPause, ax
                jmp     DoPause


.data?
align 16
TZXBlockPointer         DWORD   ?
TZXDataDataOffset       DWORD   ?
TZXDataSymbolOffset     DWORD   ?
TZXTOTP                 DWORD   ?
TZXTOTD                 DWORD   ?
TZXPilotSymbolOffset    DWORD   ?
TZXPilotDataOffset      DWORD   ?
TZXSymbolCounter        DWORD   ?
TZXSymbolPointer        DWORD   ?
TZXDataPointer          DWORD   ?
TZXBlockEnd             DWORD   ?
TZXNPP                  WORD    ?
TZXASP                  WORD    ?
TZXNPD                  WORD    ?
TZXASD                  WORD    ?

TZXPRLE_Reps            WORD    ?

TZXBitsRequired         BYTE    ?
TZXBitNumber            BYTE    ?
TZXSymbol               BYTE    ?
TZXFlipType             BYTE    ?
.code


; Generalized Data Block
align 16
Block_19:       inc     esi
                mov     TZXBlockPointer, esi

                mov     eax, [esi]          ; block length
                add     eax, esi            ; add block pointer
                add     eax, 4              ; add size of "block length" field
                mov     TZXBlockEnd, eax    ; first byte beyond this block's data

                mov     ax, [esi+4]
                invoke  Set_Tape_Pause, ax

                mov     eax, [esi+6]
                mov     TZXTOTP, eax

                movzx   ax, byte ptr [esi+10]
                mov     TZXNPP, ax

                movzx   ax, byte ptr [esi+11]
                mov     TZXASP, ax

                ifc     TZXASP eq 0 then mov TZXASP, 256

                mov     eax, [esi+12]
                mov     TZXTOTD, eax

                movzx   ax, byte ptr [esi+16]
                mov     TZXNPD, ax

                movzx   ax, byte ptr [esi+17]
                mov     TZXASD, ax

                ifc     TZXASD eq 0 then mov TZXASD, 256

                mov     TZXPilotSymbolOffset, 18    ; offset to pilot SYMDEF [ASP]

                mov     TZXPilotDataOffset, @EVAL (TZXNPP * 2 + 1 * TZXASP + TZXPilotSymbolOffset)  ; offset to PRLE [TOTP]

                .if     TZXTOTP > 0
                        mov     TZXDataSymbolOffset, @EVAL (TZXTOTP * 3 + TZXPilotDataOffset)
                .else
                        m2m     TZXDataSymbolOffset, TZXPilotSymbolOffset
                .endif

                mov     TZXDataDataOffset, @EVAL (TZXNPD * 2 + 1 * TZXASD + TZXDataSymbolOffset)

                switch  TZXASD
                        case    129..256
                                mov     TZXBitsRequired, 8
                        case    65..128
                                mov     TZXBitsRequired, 7
                        case    33..64
                                mov     TZXBitsRequired, 6
                        case    17..32
                                mov     TZXBitsRequired, 5
                        case    9..16
                                mov     TZXBitsRequired, 4
                        case    5..8
                                mov     TZXBitsRequired, 3
                        case    3..4
                                mov     TZXBitsRequired, 2
                        case    1..2
                                mov     TZXBitsRequired, 1
                endsw


Set_Block0x19_Pilot:
                mov     TZXSymbolCounter, 0
                mov     TZXDataPointer,   @EVAL (TZXBlockPointer + TZXPilotDataOffset)
                mov     TZXSymbolPointer, @EVAL (TZXBlockPointer + TZXPilotSymbolOffset)
                mov     TZXPRLE_Reps, 0

Block0x19_Pilot:
                .if     (TZXTOTP == 0) && (TZXSymbolCounter == 0) && (TZXPRLE_Reps == 0)
                        jmp     Set_Block0x19_Data
                .endif

Expired0x19PilotSymbols:
                .if     TZXSymbolCounter == 0
                        .if     TZXPRLE_Reps == 0

                                dec     TZXTOTP

                                mov     ecx, TZXDataPointer
                                mov     al, [ecx]
                                mov     TZXSymbol, al
                                mov     ax, [ecx+1]
                                dec     ax
                                mov     TZXPRLE_Reps, ax
                                add     TZXDataPointer, 3
                        .else
                                dec     TZXPRLE_Reps
                        .endif

                        mov     TZXSymbolCounter, @EVAL (TZXNPP - 1)

                        mov     TZXSymbolPointer, @EVAL (TZXBlockPointer + TZXPilotSymbolOffset)
                        add     TZXSymbolPointer, @EVAL (TZXNPP * 2 + 1 * TZXSymbol)

                        mov     ecx, TZXSymbolPointer
                        mov     al, [ecx]
                        mov     TZXFlipType, al

                        mov     ax, [ecx+1]
                        mov     TZXCountDown, ax
                        add     TZXSymbolPointer, 3
                .else
                        mov     eax, TZXSymbolPointer
                        mov     ax, [eax]
                        mov     TZXCountDown, ax
                        add     TZXSymbolPointer, 2

                        ifc     TZXCountDown ne 0 then mov TZXFlipType, 0   ; opposite polarity

                        .if     TZXCountDown == 0
                                dec     TZXSymbolCounter
                                jmp     Block0x19_Pilot
                        .endif
                        dec     TZXSymbolCounter
                .endif

                invoke  SetBlock19TapePolarity, TZXFlipType

                mov     TZXJump, @F

@@:             mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c

                mov     TapeTStates, ax
                jmp     Block0x19_Pilot


Set_Block0x19_Data:
                mov     TZXSymbolCounter, 0
                mov     TZXDataPointer,   @EVAL (TZXBlockPointer + TZXDataDataOffset)
                mov     TZXSymbolPointer, @EVAL (TZXBlockPointer + TZXDataSymbolOffset)
                mov     TZXBitNumber, 7

Block0x19_Data:.if     (TZXTOTD == 0) && (TZXSymbolCounter == 0)
                        jmp     Block0x19_Pause     ; symbols expired
                .endif

                mov     eax, TZXDataPointer
                .if     eax > TZXBlockEnd
                        jmp     Block0x19_Pause     ; ran out of data in this TZX block
                .endif

Expired0x19DataSymbols:
                .if     TZXSymbolCounter == 0

                        mov     esi, TZXDataPointer
                        mov     bl,  TZXBitsRequired
                        movzx   cx,  TZXBitNumber
                        mov     bh, 0

@@:                     bt      [esi], cx
                        rcl     bh, 1

                        sub     cl, 1
                        adc     esi, 0
                        and     cl, 7

                        dec     bl
                        jnz     @B

                        mov     TZXBitNumber, cl
                        mov     TZXDataPointer, esi
                        mov     TZXSymbol, bh

                        mov     TZXSymbolCounter, @EVAL (TZXNPD - 1)

                        mov     TZXSymbolPointer, @EVAL (TZXBlockPointer + TZXDataSymbolOffset)
                        add     TZXSymbolPointer, @EVAL (TZXNPD * 2 + 1 * TZXSymbol)

                        mov     ecx, TZXSymbolPointer
                        mov     al, [ecx]
                        mov     TZXFlipType, al

                        mov     ax, [ecx+1]
                        mov     TZXCountDown, ax
                        add     TZXSymbolPointer, 3
                .else
                        mov     eax, TZXSymbolPointer
                        mov     ax, [eax]
                        mov     TZXCountDown, ax
                        add     TZXSymbolPointer, 2

                        ifc     TZXCountDown ne 0 then mov TZXFlipType, 0   ; opposite polarity

                        .if     TZXCountDown == 0
                                mov     TZXSymbolCounter, 0
                                dec     TZXTOTD
                                jmp     Block0x19_Data
                        .endif

                        dec     TZXSymbolCounter
                        .if     TZXSymbolCounter == 0
                                dec     TZXTOTD
                        .endif
                .endif

                invoke  SetBlock19TapePolarity, TZXFlipType

                mov     TZXJump, @F

@@:             mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c

                mov     TapeTStates, ax
                jmp     Block0x19_Data

Block0x19_Pause:
End_Block19:
                inc     TZXCurrBlock
                mov     ax, TZXWantPause
                mov     TZXPause, ax
                jmp     DoPause


;Symbol flags
;b0-b1: starting symbol polarity
;     00: opposite to the current level (make an edge, as usual) - default
;     01: same as the current level (no edge - prolongs the previous pulse)
;     10: force low level
;     11: force high level

align 16
SetBlock19TapePolarity      proc    Polarity: BYTE

                            mov     al, Polarity
                            and     al, 3
                            switch  al
                                    case    0
                                            call    FlipEar
                                    case    2
                                            .if     EarBit != 0
                                                    call    FlipEar
                                            .endif
                                    case    3
                                            .if     EarBit != 64
                                                    call    FlipEar
                                            .endif
                            endsw
                            ret
SetBlock19TapePolarity      endp


; Direct Recording Block
.data?
align 4
B15_ByteCount           DWORD ?
B15_BytePtr             DWORD ?
B15_TStatesPerSample    WORD ?
.code
align 16
Block_15:       inc     esi

                lodsw
                mov     TZXCountDown, ax
                lodsw
                invoke  Set_Tape_Pause, ax

                lodsb
                mov     UsedBitsLastByte, al
                lodsd                           ; byte count is a 3 byte argument
                dec     esi
                and     eax, 00FFFFFFh
                je      B15_End                 ; no data

                mov     B15_BytePtr, esi
                mov     B15_ByteCount, eax

B15_ByteLoop:   mov     eax, B15_BytePtr
                inc     B15_BytePtr
                mov     al, [eax]
                mov     TAPEByte, al

                ifc     B15_ByteCount eq 1 then mov al, UsedBitsLastByte else mov al, 8
                mov     TAPENumBits, al

B15_BitLoop:    shl     TAPEByte, 1
                .if     CARRY?
                        PULSE_HIGH
                .else
                        PULSE_LOW
                .endif

                mov     TZXJump, offset @F

@@:             mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c

                mov     TapeTStates, ax

                dec     TAPENumBits
                jne     B15_BitLoop

                dec     B15_ByteCount
                jne     B15_ByteLoop

B15_End:        inc     [TZXCurrBlock]
                mov     ax, TZXWantPause
                mov     TZXPause, ax
                jmp     DoPause


; Pure Data Block
align 16
Block_14:       inc     esi
                lodsw
                mov     LengthZeroBitPulse, ax
                lodsw
                mov     LengthOneBitPulse, ax
                lodsb
                mov     UsedBitsLastByte, al
                lodsw
                invoke  Set_Tape_Pause, ax
                lodsd                           ; byte count is a 3 byte argument
                dec     esi
                and     eax, 00FFFFFFh

                mov     ByteCount, eax
                mov     BytePtr, esi

                mov     TZXJump, offset MainByteLoop
                jmp     MainByteLoop

; Sequence of pulses of different lengths
.data?
align 4
B13_PulseLengthsPtr DWORD ?
B13_NumPulses       BYTE ?
.code
align 16
Block_13:       inc     esi
                lodsb
                or      al, al
                je      IncPlayNextBlock

                mov     B13_NumPulses, al
                mov     B13_PulseLengthsPtr, esi

B13_Loop:       mov     eax, B13_PulseLengthsPtr
                add     B13_PulseLengthsPtr, 2

                mov     ax, [eax]
                mov     TZXCountDown, ax

                WAIT_PULSE

                dec     B13_NumPulses
                jne     B13_Loop

                jmp     IncPlayNextBlock


; Pure Tone Block
align 16
Block_12:       inc     esi
                lodsw
                mov     TZXCountDown, ax
                lodsw
                or      ax, ax
                je      IncPlayNextBlock

                mov     LengthPilotTone, ax

@@:             WAIT_PULSE

                dec     LengthPilotTone
                jne     @B

                jmp     IncPlayNextBlock


; Turbo Loading Data Block
align 16
Block_11:       inc     esi

                lodsw
                mov     LengthPilotPulse, ax
                lodsw
                mov     LengthSyncFPulse, ax
                lodsw
                mov     LengthSyncSPulse, ax
                lodsw
                mov     LengthZeroBitPulse, ax
                lodsw
                mov     LengthOneBitPulse, ax
                lodsw
                mov     LengthPilotTone, ax
                lodsb
                mov     UsedBitsLastByte, al
                lodsw
                invoke  Set_Tape_Pause, ax
                lodsd                           ; byte count is a 3 byte argument
                dec     esi
                and     eax, 00FFFFFFh

                mov     ByteCount, eax
                mov     BytePtr, esi

                jmp     Block10_Entry2

; Standard Speed Data Block (as in TAP files)
align 16
Block_10:       mov     LengthPilotPulse, 2168
                mov     LengthSyncFPulse, 667
                mov     LengthSyncSPulse, 735
                mov     LengthZeroBitPulse, 855
                mov     LengthOneBitPulse, 1710
                mov     UsedBitsLastByte, 8

                .if     LoadTapeType == Type_TAP
                        mov     esi, BlockData
                        mov     ax, 1000        ; pause 1000 ms for TAP
                .else
                        mov     esi, BlockData
                        inc     esi
                        lodsw                   ; pick up pause length from TZX block
                .endif
                invoke  Set_Tape_Pause, ax       ; and set the pause length

                movzx   eax, word ptr [esi] ; eax = TAP block length
                add     esi, 2              ; esi points to TAP block data

                or      eax, eax
                je      IncPlayNextBlock    ; no bytes available

                mov     ByteCount, eax
                mov     BytePtr, esi

                test    byte ptr [esi], 128 ; flag byte
                ifc     ZERO? then mov LengthPilotTone, 8063 else mov LengthPilotTone, 3223


Block10_Entry2: cmp     LengthPilotTone, 0
                je      FirstSync

                mov     ax, LengthPilotPulse
                mov     TZXCountDown, ax

LeaderToneLoop: WAIT_PULSE

                dec     LengthPilotTone
                jne     LeaderToneLoop


FirstSync:      mov     ax, LengthSyncFPulse
                mov     TZXCountDown, ax

                WAIT_PULSE

SecondSync:     mov     ax, LengthSyncSPulse
                mov     TZXCountDown, ax

                WAIT_PULSE

                mov     TZXJump, offset MainByteLoop

                cmp     ByteCount, 0
                je      End_MainByteLoop    ; branch if no data


MainByteLoop:   mov     eax, BytePtr
                inc     BytePtr
                mov     al, [eax]
                mov     TAPEByte, al

                ifc     ByteCount eq 1 then mov al, UsedBitsLastByte else mov al, 8
                mov     TAPENumBits, al

MainBitLoop:    xor     eax, eax
                shl     TAPEByte, 1
                adc     eax, 0
                mov     ax, [LengthZeroBitPulse+eax*2]  ; pick up the pulse length for this bit
                mov     TZXCountDown, ax

                WAIT_PULSE  ; wait for first pulse
                WAIT_PULSE  ; wait for second pulse

                dec     TAPENumBits
                jne     MainBitLoop

                dec     ByteCount
                jne     MainByteLoop

End_MainByteLoop:
                inc     TZXCurrBlock
                mov     ax, TZXWantPause
                mov     TZXPause, ax
;                jmp     DoPause        ; continue into DoPause


; A 'Pause' block consists of a 'low' pulse level of some duration.
; To ensure that the last edge produced is properly finished there should be at least 1 ms. pause of the opposite level and only after that the pulse should go to 'low'.
; At the end of a 'Pause' block the 'current pulse level' is low (note that the first pulse will therefore not immediately produce an edge).
; A 'Pause' block of zero duration is completely ignored, so the 'current pulse level' will NOT change in this case. This also applies to 'Data' blocks that have some pause duration included in them.

DoPause:        mov     TZXJump, offset PlayNextBlock
                cmp     TZXPause, 0
                je      PlayNextBlock

                call    FlipEar
                mov     Tape_Pause_ms, 1

DoPauseWait:    mov     ax, TapeTStates
                sub     ax, 3500        ; 1 ms in T-States
                retcc   c
                mov     TapeTStates, ax

                dec     Tape_Pause_ms
                .if     ZERO?
                        PULSE_LOW
                .endif

                dec     TZXPause
                ret

align 16
FlipEar:        xor     EarBit, 64
                mov     EdgeTrigger, TRUE
                mov     EdgeTriggerAck, FALSE

                .if     EarBit == 0
                        mov     EarVal, EarLowVal
                .else
                        mov     EarVal, EarHighVal
                .endif
                ret

StartStopTape   proc
                ifc     LoadTapeType ne Type_NONE then xor TapePlaying, TRUE     ; toggles Tape On/Off
                ret
StartStopTape   endp


.data?
align 16
MAXWAVDATA      equ     1024    ; must be a multiple of 4

WAVDataLen      DWORD   ?
WAVBits         DWORD   ?
WAVSampleSize   DWORD   ?
WAVBytesAvail   DWORD   ?
WAVSamplePtr    DWORD   ?
WAVChannels     WORD    ?
WAVPulseLength  WORD    ?

TZXWavData      BYTE    MAXWAVDATA dup (?)

WAVLevelState   BYTE    ?

;--------------------------------------------------------------------------------
.code
align 16
PlayWAVBlock:
                ; move filepointer beyond the WAV header ready for loading
                invoke  SetFilePointer, TapeFileHandle, WAVHEADERSIZE, NULL, FILE_BEGIN

                mov     ax, WAVPulseLength
                mov     TZXCountDown, ax

                mov     eax, WAVBits            ; bits per sample
                shr     ax, 3                   ; eax = 1 for 8 bit, 2 for 16 bit WAV
                mul     WAVChannels
                and     eax, 0FFFFh
                mov     WAVSampleSize, eax      ; bytes to read per sample from WAV file

                invoke  GetFileSize, TapeFileHandle, NULL
                sub     eax, 44                 ; subtract header size
                mov     WAVDataLen, eax

                mov     WAVBytesAvail, 0
                mov     WAVLevelState, 0


PlayWAVDataLoop:.if     WAVBytesAvail == 0
                        cmp     WAVDataLen, 0
                        je      PlayWAVNextBlock    ; no more WAV data available

                        mov     eax, MAXWAVDATA
                        ifc     WAVDataLen lt eax then mov eax, WAVDataLen

                        mov     WAVBytesAvail, eax
                        sub     WAVDataLen, eax

                        invoke  ReadFile, TapeFileHandle, addr TZXWavData, WAVBytesAvail, addr BytesMoved, NULL
                        or      eax, eax
                        je      PlayWAVNextBlock    ; file read error

                        mov     WAVSamplePtr, offset TZXWavData
                .endif

                mov     ecx, WAVSamplePtr

                mov     dl, WAVLevelState

                WAVTRIGGER  equ 7FFFh

                switch  WAVBits
                        case    8
                                ; 8 bit recording
                                mov     al, [ecx]
                                .if     al <= (WAVTRIGGER shr 8)
                                        mov     dl, 0
                                .else
                                        mov     dl, 64
                                .endif
                        case    16
                                ; 16 bit recording
                                mov     ax, [ecx]
                                .if     ax > WAVTRIGGER
                                        mov     dl, 0
                                .else
                                        mov     dl, 64
                                .endif
                endsw

                mov     WAVLevelState, dl
                ifc     dl ne EarBit then call FlipEar

                mov     TZXJump, offset @F

@@:             mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c
                mov     TapeTStates, ax

                mov     eax, WAVSampleSize
                add     WAVSamplePtr, eax
                sub     WAVBytesAvail, eax

                jmp     PlayWAVDataLoop

PlayWAVNextBlock:
                jmp     IncPlayNextBlock    ; effectively end of tape

;--------------------------------------------------------------------------------

align 16
PlayCSWBlock:   invoke  GetPulsePeriod, CSW_Load_Handle
                mov     TZXCountDown, ax

PlayCSWDataLoop:invoke  ReadPulseValue, CSW_Load_Handle ; eax: 0 = low, 1 = high, CSWERR_EOF = Error.
                cmp     eax, CSWERR_EOF
                je      PlayWAVNextBlock                ; out of CSW data

                shl     al, 6                           ; pulse value = 0 or 64
                ifc     al ne EarBit then call FlipEar

                mov     TZXJump, offset @F

@@:             mov     ax, TapeTStates
                sub     ax, TZXCountDown
                retcc   c
                mov     TapeTStates, ax

                jmp     PlayCSWDataLoop


