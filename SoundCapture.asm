
; POKE 23736,181 : No keypress on SAVE

Init_Capture        PROTO
Close_Capture       PROTO
Init_Capture_Fail   PROTO   :DWORD
Resync_Capture      PROTO
Get_Real_Tape_Bit   PROTO

NUM_CAPTURE_BUFFERS equ     30
CAPTURE_BUFFER_LEN  equ     1764 * 2
CAPTURE_BUFFER_SIZE equ     NUM_CAPTURE_BUFFERS * CAPTURE_BUFFER_LEN

.data?
cap_hWaveIn         HANDLE  ?
cap_WaveHdrs        BYTE    NUM_CAPTURE_BUFFERS * sizeof WAVEHDR        dup (?)
cap_buffers         BYTE    NUM_CAPTURE_BUFFERS * CAPTURE_BUFFER_LEN    dup (?)

cap_writeposn       DWORD   ?
cap_readposn        DWORD   ?

.code

Flip_RealTape_Mode  proc

                    .if     RealTapeMode == FALSE
                            invoke  Init_Capture
                    .else
                            invoke  Close_Capture
                    .endif

                    ret
Flip_RealTape_Mode  endp

Init_Capture        proc    uses    esi edi ebx

                    assume  esi: ptr WAVEFORMATEX
                    lea     esi, WaveFormat
                    mov     [esi].wFormatTag,       WAVE_FORMAT_PCM
                    mov     [esi].nChannels,        2
                    mov     [esi].nSamplesPerSec,   44100
                    mov     [esi].nAvgBytesPerSec,  44100
                    mov     [esi].nBlockAlign,      (8*2)/8
                    mov     [esi].wBitsPerSample,   8
                    mov     [esi].cbSize,           0
                    assume  esi: nothing

                    invoke  waveInOpen, addr cap_hWaveIn, WAVE_MAPPER, addr WaveFormat, hWnd, 0, CALLBACK_WINDOW

                    .if     eax == MMSYSERR_NOERROR
                            lea     edi, cap_WaveHdrs
                            assume  edi: PTR WAVEHDR

                            lea     esi, cap_buffers
                            xor     ebx, ebx

                            .while  ebx < NUM_CAPTURE_BUFFERS
                                    mov     [edi].lpData, esi
                                    mov     [edi].dwBufferLength, CAPTURE_BUFFER_LEN
                                    mov     [edi].dwBytesRecorded, 0
                                    mov     [edi].dwUser, ebx
                                    mov     [edi].dwFlags, 0
                                    mov     [edi].dwLoops, 0

                                    invoke  waveInPrepareHeader, cap_hWaveIn, edi, sizeof WAVEHDR
                                    .break  .if eax != MMSYSERR_NOERROR

                                    invoke  waveInAddBuffer,     cap_hWaveIn, edi, sizeof WAVEHDR
                                    .break  .if eax != MMSYSERR_NOERROR

                                    add     esi, CAPTURE_BUFFER_LEN
                                    add     edi, sizeof WAVEHDR
                                    inc     ebx
                            .endw
                            assume  edi: nothing

                            ifc     ebx ne NUM_CAPTURE_BUFFERS then invoke Init_Capture_Fail, eax : ret ; error if not all buffers prepared/added

                            invoke  waveInStart, cap_hWaveIn
                            ifc     eax ne MMSYSERR_NOERROR then invoke Init_Capture_Fail, eax : ret

                            mov     cap_writeposn, 0
                            mov     cap_readposn,  (NUM_CAPTURE_BUFFERS / 2) * CAPTURE_BUFFER_LEN

                            mov     RealTapeMode, TRUE

                    .else
                            invoke  Init_Capture_Fail, eax
                    .endif

                    ret

Init_Capture        endp

Init_Capture_Fail   proc    ErrorNum:   DWORD

                    local   ErrorText[MAXERRORLENGTH+32]: BYTE

                    invoke  Close_Capture

                    invoke  waveInGetErrorText, ErrorNum, addr ErrorText, sizeof ErrorText
                    .if     eax == MMSYSERR_NOERROR
                            invoke  ShowMessageBox, hWnd, addr ErrorText, addr szWindowName, MB_OK or MB_ICONERROR
                    .else
                            invoke  ShowMessageBox, hWnd, SADD ("Unknown error opening recording device"), addr szWindowName, MB_OK or MB_ICONERROR
                    .endif
                    ret
Init_Capture_Fail   endp

Close_Capture       proc    uses esi edi ebx

                    .if     cap_hWaveIn != NULL

                            invoke  waveInStop,  cap_hWaveIn
                            invoke  waveInReset, cap_hWaveIn

                            lea     edi, cap_WaveHdrs
                            assume  edi: PTR WAVEHDR

                            lea     esi, cap_buffers
                            xor     ebx, ebx

                            .while  ebx < NUM_CAPTURE_BUFFERS
                                    mov     [edi].lpData, esi
                                    mov     [edi].dwBufferLength, CAPTURE_BUFFER_LEN
                                    mov     [edi].dwBytesRecorded, 0
                                    mov     [edi].dwUser, ebx
                                    mov     [edi].dwFlags, 0
                                    mov     [edi].dwLoops, 0

                                    invoke  waveInUnprepareHeader, cap_hWaveIn, edi, sizeof WAVEHDR

                                    add     esi, CAPTURE_BUFFER_LEN
                                    add     edi, sizeof WAVEHDR
                                    inc     ebx
                            .endw

                            assume  edi: nothing

                            invoke  waveInClose, cap_hWaveIn
                            mov     cap_hWaveIn, NULL
                    .endif

                    mov     RealTapeMode, FALSE
                    ret
Close_Capture       endp

Resync_Capture      proc
                    .if     RealTapeMode == TRUE
                            mov     eax, cap_writeposn
                            add     eax, (NUM_CAPTURE_BUFFERS / 2) * CAPTURE_BUFFER_LEN
                            .if     eax >= CAPTURE_BUFFER_SIZE
                                    sub     eax, CAPTURE_BUFFER_SIZE
                            .endif
                            mov     cap_readposn, eax
                    .endif
                    ret
Resync_Capture      endp

Get_Real_Tape_Bit   proc    uses    esi

                  ; adjust CyclesPerSample for the next sample period
                    mov     cl, MACHINE.REALTAPEPERIOD.CyclesPerSample
                    mov     al, MACHINE.REALTAPEPERIOD.SampleLoopCount
                    add     al, 1
                    .if     al == MACHINE.REALTAPEPERIOD.SampleLoopAdjustRate
                            add     cl, MACHINE.REALTAPEPERIOD.SampleLoopAdjustValue
                            xor     al, al
                    .endif
                    mov     MACHINE.REALTAPEPERIOD.SampleLoopCount, al
                    mov     MACHINE.REALTAPEPERIOD.CurrentCyclesPerSample, cl


                    mov     esi, cap_readposn
                    mov     al,  [cap_buffers+esi]   ; take left channel sample
                    add     esi, 2

                    .if     al > 128
                            mov     EarBit, 64
                            mov     EarVal, EarHighVal
                    .else
                            mov     EarBit, 0
                            mov     EarVal, EarLowVal
                    .endif

                    .if     esi >= CAPTURE_BUFFER_SIZE
                            sub     esi, CAPTURE_BUFFER_SIZE
                    .endif
                    
                    mov     cap_readposn, esi
                    ret

Get_Real_Tape_Bit   endp


