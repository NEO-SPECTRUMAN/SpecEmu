
;###########################################################################
;       DirectSound API interface to emulate AY-3-8912 sound device
;###########################################################################

InBufferBlock           PROTO   :DWORD

    ;====================================================
    ; The following macro is based on
    ; this Win32 header file macro
    ;
    ; #define MAKEFOURCC(ch0, ch1, ch2, ch3) \
    ;  ((DWORD)(BYTE)(ch0) | ((DWORD)(BYTE)(ch1) << 8) |   \
    ;  ((DWORD)(BYTE)(ch2) << 16) | ((DWORD)(BYTE)(ch3) << 24 ))
    ;
    ; This presumes all params passed in are in bytes
    ;====================================================
mmioFOURCC  MACRO   ch0, ch1, ch2, ch3
            mov     al, ch3
            shl     eax, 8
            mov     al, ch2
            shl     eax, 8
            mov     al, ch1
            shl     eax, 8
            mov     al, ch0
            ENDM


AUDIOFREQ               equ     44100

.data?
align 4
DSBUFFERSIZE            DWORD   ?   ; (AUDIOFREQ/FPS)*8*8 ; must be a multiple of 4


; StereoOutputMode equates:
OUTPUT_NORMAL           equ     0
OUTPUT_ABC              equ     1
OUTPUT_ACB              equ     2
OUTPUT_ECHO             equ     3
OUTPUT_REVERB           equ     4
OUTPUT_PLUS3            equ     5

.data
align 16
PSGDivisor              equ 1                   ; default = 2

PSGVolumes              dd  0                   ; vol 0
                        dd  108  / PSGDivisor   ; vol 1
                        dd  159  / PSGDivisor   ; vol 2
                        dd  223  / PSGDivisor   ; vol 3
                        dd  335  / PSGDivisor   ; vol 4
                        dd  511  / PSGDivisor   ; vol 5
                        dd  703  / PSGDivisor   ; vol 6
                        dd  1119 / PSGDivisor   ; vol 7
                        dd  1343 / PSGDivisor   ; vol 8
                        dd  2143 / PSGDivisor   ; vol 9
                        dd  2943 / PSGDivisor   ; vol 10
                        dd  3679 / PSGDivisor   ; vol 11
                        dd  4655 / PSGDivisor   ; vol 12
                        dd  5759 / PSGDivisor   ; vol 13
                        dd  6911 / PSGDivisor   ; vol 14
                        dd  8191 / PSGDivisor   ; vol 15

PSG_CENTRALISE_RANGE    equ     (8191 / PSGDivisor) / 2

.data?
align 16
lpds                    LPDIRECTSOUND       ?
SecondaryBuffer         LPDIRECTSOUNDBUFFER ?
DriveStepBuffer         LPDIRECTSOUNDBUFFER ?
dsbd                    DSBUFFERDESC        <?>
WaveFormat              WAVEFORMATEX        <?>

align 16
audio_ptr_1             DWORD   ?
audio_ptr_2             DWORD   ?
audio_length_1          DWORD   ?
audio_length_2          DWORD   ?

CurrentPlayCursor       DWORD   ?
CurrentWriteCursor      DWORD   ?

SamplesPerFrame         DWORD   ?
SampleBytesPerFrame     DWORD   ?

lpAYBuffer              DWORD   ?

DSBuff_WritePosn        DWORD   ?
DSBuff_WaitPosn         DWORD   ?
AY_BufferedBytes        DWORD   ?
lpAYBuffer_Posn         DWORD   ?
SamplesBeforeStreaming  DWORD   ?
SamplesToBuffer         DWORD   ?   ; number of samples to buffer before streaming to DirectSound = (SAMPLESPERFRAME * FrameSkipCounter)
SampleBytesToBuffer     DWORD   ?

StereoWide1PtrS         DWORD   ?
StereoWide1PtrM         DWORD   ?
StereoWide2PtrS         DWORD   ?
StereoWide2PtrM         DWORD   ?

StereoWide1BufferS      WORD    768*8  DUP (?)
StereoWide1BufferM      WORD    768*8  DUP (?)
StereoEndBuffer1        WORD    ?

StereoWide2BufferS      WORD    768*8  DUP (?)
StereoWide2BufferM      WORD    768*8  DUP (?)
StereoEndBuffer2        WORD    ?

                      ; equates for Sound_Effect
                        EFFECT_NONE     equ     0
                        EFFECT_ECHO     equ     1
                        EFFECT_REVERB   equ     2

Sound_Effect            BYTE    ?

SoundPlaying            BYTE    ?
DSoundStarted           BYTE    ?

Emulate_AY              BYTE    ?

process_priority_set    BYTE    ?

.code

;#################################################################################

InitAudio:
            .if     lpAYBuffer != NULL
                    call    ClearSoundBuffers
                    mov     SoundPlaying, 0

                    mov     eax, lpAYBuffer
                    mov     lpAYBuffer_Posn, eax    ; our current write posn in our private buffer

                    mov     RandomSeed, 1

                    mov     [StereoWide1PtrS], offset StereoWide1BufferS
                    mov     [StereoWide1PtrM], offset StereoWide1BufferM
                    mov     [StereoWide2PtrS], offset StereoWide2BufferS
                    mov     [StereoWide2PtrM], offset StereoWide2BufferM

                    mov     eax, AUDIOFREQ ; / Frames Per Second
                    invoke  Div2Int, eax, MACHINE.FramesPerSecond
                    mov     SamplesPerFrame, eax

                    ; SampleBytesPerFrame = SamplesPerFrame * 4
                    shl     eax, 2
                    mov     SampleBytesPerFrame,eax

                    mov     eax, SamplesPerFrame
                    movzx   ecx, FrameSkipCounter
                    mul     ecx
                    mov     SamplesToBuffer, eax        ; = (SamplesPerFrame * FrameSkipCounter)

                    mov     SamplesBeforeStreaming, eax ; number of samples to take before streaming to DirectSound

                    shl     eax, 2
                    mov     SampleBytesToBuffer,eax     ; = (SamplesToBuffer * 4)

                    mov     eax, SampleBytesToBuffer
                    mov     DSBuff_WaitPosn, eax        ; = 1 * SampleBytesToBuffer
                    shl     eax, 1
                    mov     DSBuff_WritePosn, eax       ; = 2 * SampleBytesToBuffer
            .endif
            ret

ReinitAudio:
            call    ShutdownDirectSound
            call    StartupDirectSound
            call    InitAudio
            ret

;#################################################################################

ClearSoundBuffers:
            .if     DSoundStarted == TRUE
                    DSBINVOKE   mLock, SecondaryBuffer, NULL, NULL, addr audio_ptr_1, addr audio_length_1, addr audio_ptr_2, addr audio_length_2, DSBLOCK_ENTIREBUFFER

                    .if     eax == DSERR_BUFFERLOST
                            call    RestoreSoundBuffer
                            jmp     ClearSoundBuffers
                    .endif

                    .if     eax == DS_OK
                            push    edi
                            xor     eax, eax
                            mov     edi, audio_ptr_1
                            mov     ecx, audio_length_1
                            shr     ecx, 2
                            rep     stosd
                            mov     ecx, audio_length_1
                            and     ecx, 3
                            rep     stosb

                            mov     edi, audio_ptr_2
                            mov     ecx, audio_length_2
                            shr     ecx, 2
                            rep     stosd
                            mov     ecx, audio_length_2
                            and     ecx, 3
                            rep     stosb
                            pop     edi

                            DSBINVOKE   Unlock, SecondaryBuffer, audio_ptr_1, audio_length_1, audio_ptr_2, audio_length_2
        
                            .if     eax != DS_OK
                                    FATAL "DirectSound Unlock failed !"
                            .endif
                    .endif
            .endif
            ret

;#################################################################################

BEEPERFADE  MACRO
            .if     BeepHold > 0
                    dec     BeepHold
            .else
                    mov     BeepHold, 12
                    mov     dx, BeepVal
                    mov     ax, BeepCentreVal
                    sub     ax, dx
                    sar     ax, 2
                    add     dx, ax
                    mov     BeepVal, dx
            .endif
            ENDM

align 16
Create_Audio_Sample:
            cmp     lpAYBuffer, NULL
            je      SampleBeepExit      ; exit if we have no private audio buffer

            .if     BoostLoadingNoise   ; transferring loading data direct to Speccy?
                    mov     BeeperSubCount, 0
                    mov     BeeperSubTotal, 0

                    .if     EarBit == 0
                            mov     ax, -30000
                    .else
                            mov     ax, 30000
                    .endif

                    mov     bx, ax
                    jmp     No_Audio_Effects
            .endif

            .if     BoostSavingNoise    ; transferring ROM SAVE data direct to Speccy?
                    mov     BeeperSubCount, 0
                    mov     BeeperSubTotal, 0

                    .if     MICVal == 0        ; use MIC to save direct to Speccy, EAR sends loading tones
                            mov     ax, -30000
                    .else
                            mov     ax, 30000
                    .endif

                    mov     bx, ax
                    jmp     No_Audio_Effects
            .endif

            mov     Total_ChanA, 0
            mov     Total_ChanB, 0
            mov     Total_ChanC, 0
            mov     SampleCounter, 0

;            BEEPERFADE

            mov     dx, BeepVal
            .if     BeeperSubCount > 1
                    mov     eax, BeeperSubTotal
                    mov     edx, eax
                    shr     edx, 16
                    div     BeeperSubCount
                    mov     dx, ax
            .endif

            mov     BeeperSubCount, 0
            mov     BeeperSubTotal, 0

          ; for real tape mode, tape signals are heard from the line-in socket
          ; otherwise, if a virtual tape is playing, take virtual tape signal into output stream
            .if     RealTapeMode == FALSE
                    .if     TapePlaying
                            add     dx, EarVal
                    .endif
            .endif

            .if     uSpeech_Enabled
                    push    edx
                    invoke  uSpeech_GetSample
                    pop     edx
                    mov     ax, uSpeech_Output
                    .if     Sound_Effect != EFFECT_NONE
                            shr     ax, 2
                    .endif
                    add     dx, ax
            .endif

            .if     SpecDrum_Enabled
                    add     dx, SpecDrum_Output
            .endif

            .if     Covox_Enabled && (HardwareMode == HW_PENTAGON128)
                    add     dx, Covox_Output
            .endif

            .if     SPGfx.TVNoiseCounter > 0
                    xor     dx, dx
                    call    TVNoiseBit
                    .if     !ZERO?
                            mov     dx, word ptr [PSGVolumes+15*4]  ; read lower word of (dword) volume 15 entry
                    .endif
                    mov     [FinalChanA], dx
                    mov     [FinalChanB], dx
                    mov     [FinalChanC], dx

                    xor     dx, dx
            .endif

; process stereomodes ---------------
            movzx   eax, StereoOutputMode
            and     eax, 7
            jmp     [AudioOutProcs+eax*4]

.data
align 16
AudioOutProcs   dd  OUT_NORMAL, OUT_ABC,    OUT_ACB,    OUT_PLUS3
                dd  OUT_NORMAL, OUT_NORMAL, OUT_NORMAL, OUT_NORMAL
.code

; ax = left channel, bx = right channel
;--------------------------------------------------------------------------------
align 16
OUT_NORMAL: mov     ax, [FinalChanA]
            add     ax, [FinalChanB]
            add     ax, [FinalChanC]
            add     ax, dx           ; ax = left-channel output
            mov     bx, ax           ; bx = right-channel output
            jmp     AudioOut_Done

;--------------------------------------------------------------------------------
align 16
OUT_ABC:    mov     ax, [FinalChanB]
            add     ax, dx
            mov     bx, ax
            add     ax, [FinalChanA]
            add     bx, [FinalChanC]
            jmp     AudioOut_Done

;--------------------------------------------------------------------------------
align 16
OUT_ACB:    mov     ax, [FinalChanC]
            add     ax, dx
            mov     bx, ax
            add     ax, [FinalChanA]
            add     bx, [FinalChanB]
            jmp     AudioOut_Done

;--------------------------------------------------------------------------------
align 16
OUT_PLUS3:  xor     eax, eax
            add     ax, [FinalChanA]
            .if     ax > 2000
                    sub     ax, 2000
            .endif
            add     ax, [FinalChanB]
            .if     ax > 2000
                    sub     ax, 2000
            .endif
            add     ax, [FinalChanC]
            .if     ax > 2000
                    sub     ax, 2000
            .endif

            sal     ax, 1

            add     ax, dx          ; ax = left channel output
            .if     ax > 32000
                    mov     ax, 32000
            .endif

            mov     bx,ax           ; bx = right channel output

; end process stereomodes ---------------

AudioOut_Done:
                .if     Sound_Effect == EFFECT_ECHO
                        mov     edi,[StereoWide1PtrS]
                        mov     [edi],ax    ; store left channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer1 then mov edi, offset StereoWide1BufferS
                        mov     [StereoWide1PtrS],edi

                        mov     edi,[StereoWide1PtrM]
                        mov     cx,[edi]    ; cx = old left channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer1 then mov edi, offset StereoWide1BufferS
                        mov     [StereoWide1PtrM],edi

                        mov     edi,[StereoWide2PtrS]
                        mov     [edi],bx    ; store right channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer2 then mov edi, offset StereoWide2BufferS
                        mov     [StereoWide2PtrS],edi

                        mov     edi,[StereoWide2PtrM]
                        mov     dx,[edi]    ; dx = old right channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer2 then mov edi, offset StereoWide2BufferS
                        mov     [StereoWide2PtrM],edi

                        sar     ax, 1
                        sar     bx, 1
                        sar     cx, 2
                        sar     dx, 2

                        add     ax, dx
                        add     bx, cx

                .elseif Sound_Effect == EFFECT_REVERB
                        mov     edi,[StereoWide1PtrM]
                        mov     cx,[edi]    ; cx = old left channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer1 then mov edi, offset StereoWide1BufferS
                        mov     [StereoWide1PtrM],edi
            
                        mov     edi,[StereoWide2PtrM]
                        mov     dx,[edi]    ; dx = old right channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer2 then mov edi, offset StereoWide2BufferS
                        mov     [StereoWide2PtrM],edi

                        sar     ax, 1
                        sar     bx, 1
                        sar     cx, 1
                        sar     dx, 1

                        add     ax, dx
                        add     bx, cx

                        mov     edi,[StereoWide1PtrS]
                        mov     [edi],ax    ; store left channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer1 then mov edi, offset StereoWide1BufferS
                        mov     [StereoWide1PtrS],edi

                        mov     edi,[StereoWide2PtrS]
                        mov     [edi],bx    ; store right channel
                        add     edi,2

                        ifc     edi eq offset StereoEndBuffer2 then mov edi, offset StereoWide2BufferS
                        mov     [StereoWide2PtrS],edi
                .endif

No_Audio_Effects:
                mov     edi, lpAYBuffer_Posn     ; our current buffer posn
                add     lpAYBuffer_Posn, 4       ; update our new current buffer posn
                mov     [edi],   ax              ; store left channel sample
                mov     [edi+2], bx              ; store right channel sample

                dec     SamplesBeforeStreaming
                je      StreamAudioData

SampleBeepExit: ret

StreamAudioData:
                call    StreamAudio             ; stream audio data to DirectSound buffer

                mov     eax, SamplesToBuffer
                mov     SamplesBeforeStreaming, eax
                ret

;#################################################################################

align 16
Sample_AY       proc

                .if     HighQualityAY && (FULLSPEEDMODE == NULL)

                        .if     Emulate_AY
                                movzx   eax, AYTimer
                                shr     eax, 4          ; /16
                                .if     !ZERO?
                                        SETLOOP eax
                                                call    UpdateAYState_HQ
                                                ifc     SampleCounter lt 4 then call GetAYSample
                                        ENDLOOP
                                .endif
                        .endif
                        and     AYTimer, 15

                        mov     al, MACHINE.AUDIOPERIOD.CurrentCyclesPerSample
                        .if     SampleTimer >= al

                                .if     Emulate_AY
                                        .while  SampleCounter < 4
                                                call    GetAYSample
                                        .endw

                                        mov     eax, Total_ChanA
                                        mov     ebx, Total_ChanB
                                        mov     ecx, Total_ChanC

                                      ; take the average over 4 samples
                                        sar     eax, 2
                                        sar     ebx, 2
                                        sar     ecx, 2

                                      ; centralise output around zero point
                                        sub     eax, PSG_CENTRALISE_RANGE
                                        sub     ebx, PSG_CENTRALISE_RANGE
                                        sub     ecx, PSG_CENTRALISE_RANGE

                                        mov     FinalChanA, ax
                                        mov     FinalChanB, bx
                                        mov     FinalChanC, cx
                                .endif

                                call    Create_Audio_Sample

                                mov     al, MACHINE.AUDIOPERIOD.CurrentCyclesPerSample
                                sub     SampleTimer, al

                              ; adjust CyclesPerSample for the next sample period
                                mov     cl, MACHINE.AUDIOPERIOD.CyclesPerSample
                                mov     al, MACHINE.AUDIOPERIOD.SampleLoopCount
                                add     al, 1
                                .if     al == MACHINE.AUDIOPERIOD.SampleLoopAdjustRate
                                        add     cl, MACHINE.AUDIOPERIOD.SampleLoopAdjustValue
                                        xor     al, al
                                .endif
                                mov     MACHINE.AUDIOPERIOD.SampleLoopCount, al
                                mov     MACHINE.AUDIOPERIOD.CurrentCyclesPerSample, cl
                        .endif
                        ret
                .else
                        mov     al, MACHINE.AUDIOPERIOD.CurrentCyclesPerSample
                        .if     SampleTimer >= al

                                .if     Emulate_AY
                                        movzx   eax, AYTimer
                                        shr     eax, 4          ; /16
                                        .if     !ZERO?
                                                SETLOOP eax
                                                        call    UpdateAYState_HQ
                                                ENDLOOP
                                        .endif
                                        call    GetAYSample
                                .endif
                                and     AYTimer, 15

                                mov     eax, Total_ChanA
                                mov     ebx, Total_ChanB
                                mov     ecx, Total_ChanC

                              ; centralise output around zero point
                                sub     eax, PSG_CENTRALISE_RANGE
                                sub     ebx, PSG_CENTRALISE_RANGE
                                sub     ecx, PSG_CENTRALISE_RANGE

                                mov     FinalChanA, ax
                                mov     FinalChanB, bx
                                mov     FinalChanC, cx

                                call    Create_Audio_Sample

                                mov     al, MACHINE.AUDIOPERIOD.CurrentCyclesPerSample
                                sub     SampleTimer, al

                              ; adjust CyclesPerSample for the next sample period
                                mov     cl, MACHINE.AUDIOPERIOD.CyclesPerSample
                                mov     al, MACHINE.AUDIOPERIOD.SampleLoopCount
                                add     al, 1
                                .if     al == MACHINE.AUDIOPERIOD.SampleLoopAdjustRate
                                        add     cl, 1
                                        xor     al, al
                                .endif
                                mov     MACHINE.AUDIOPERIOD.SampleLoopCount, al
                                mov     MACHINE.AUDIOPERIOD.CurrentCyclesPerSample, cl
                        .endif

                .endif
                ret
Sample_AY       endp

align 16
UpdateAYState_HQ:       lea     esi, AYBase

                        xor     byte ptr [esi+AY_EnvelopeClock], 1
                        je      HandleChannels_HQ   ;HandleWhiteNoise_HQ

                        ; we only handle the envelope clock if a channel is using it
                        ; a write to reg 13 will reset the envelope counter to zero anyway
                        test    dword ptr [esi+AY_R8], 101010h
                        je      HandleWhiteNoise_HQ

                        mov     ax, word ptr [esi+AY_EnvCounter]
                        add     ax, 1
                        .if     ax >= [esi+AY_EnvPeriod]
                                movzx   ebx, byte ptr [esi+AY_R13]
                                mov     word ptr [esi+AY_EnvCounter], 0
                                call    [ExecEnvVectors+ebx*4]

                                xor     eax, eax    ; reset envelope counter
                        .endif

                        mov     [esi+AY_EnvCounter], ax

HandleWhiteNoise_HQ:    mov     al, [esi+AY_WhiteNoiseCounter]
                        add     al, 1
                        .if     al >= [esi+AY_InternalR6]
                                mov     al, [esi+AY_R6]
                                cmp     al, 1
                                adc     al, 0
                                mov     [esi+AY_InternalR6], al

                              ; create new white noise output value
                                shr     dword ptr [esi+AY_RandomSeed], 1
                                setc    byte ptr [esi+AY_NoiseOutput]

                                .if     CARRY?
                                        xor   dword ptr [esi+AY_RandomSeed], 24000h shr 1
                                .endif

                                xor     eax, eax    ; reset white noise counter
                        .endif     

                        mov     [esi+AY_WhiteNoiseCounter], al


HandleChannels_HQ:      xor     di, di
                        mov     dx, 1

                        mov     ax, [esi+AY_ChACounter]
                        mov     bx, [esi+AY_ChBCounter]
                        mov     cx, [esi+AY_ChCCounter]

                        add     ax, dx
                        add     bx, dx
                        add     cx, dx

                        cmp     [esi+AY_ToneA], ax
                        setbe   dl
                        cmovbe  ax, di
                        xor     byte ptr [esi+AY_ChAOutput], dl
                        mov     word ptr [esi+AY_ChACounter], ax

                        cmp     [esi+AY_ToneB], bx
                        setbe   dl
                        cmovbe  bx, di
                        xor     byte ptr [esi+AY_ChBOutput], dl
                        mov     word ptr [esi+AY_ChBCounter], bx

                        cmp     [esi+AY_ToneC], cx
                        setbe   dl
                        cmovbe  cx, di
                        xor     byte ptr [esi+AY_ChCOutput], dl
                        mov     word ptr [esi+AY_ChCCounter], cx
                        ret

;#################################################################################

.data
align 4
ExecEnvVectors  dd  ExecEnv0, ExecEnv1, ExecEnv2,  ExecEnv3,  ExecEnv4,  ExecEnv5,  ExecEnv6,  ExecEnv7
                dd  ExecEnv8, ExecEnv9, ExecEnv10, ExecEnv11, ExecEnv12, ExecEnv13, ExecEnv14, ExecEnv15
.code

DoDECAY     MACRO
            dec     dword ptr [esi+AY_EnvVolume]
            ENDM

DoATTACK    MACRO
            inc     dword ptr [esi+AY_EnvVolume]
            ENDM

align 16
ExecEnv1:
ExecEnv2:
ExecEnv3:
ExecEnv0:   cmp     byte ptr [esi+AY_EnvMode], env_OFF
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 0
            je      Set_OFF
            DoDECAY
@@:         ret

align 16
ExecEnv5:
ExecEnv6:
ExecEnv7:
ExecEnv4:   cmp     byte ptr [esi+AY_EnvMode], env_OFF
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 15
            je      Set_OFF
            DoATTACK
@@:         ret

align 16
ExecEnv8:   cmp     dword ptr [esi+AY_EnvVolume], 0
            je      Set_DECAY
            DoDECAY
            ret

align 16
ExecEnv9:   cmp     byte ptr [esi+AY_EnvMode], env_OFF
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 0
            je      Set_OFF
            DoDECAY
@@:         ret

align 16
ExecEnv10:  .if     byte ptr [esi+AY_EnvMode] == env_DECAY
                    cmp     dword ptr [esi+AY_EnvVolume], 0
                    je      Set_ATTACK
                    DoDECAY
                    ret
            .else
                    cmp     dword ptr [esi+AY_EnvVolume], 15
                    je      Set_DECAY
                    DoATTACK
                    ret
            .endif
            ret

align 16
ExecEnv11:  cmp     byte ptr [esi+AY_EnvMode], env_HOLD
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 0
            je      Set_HOLD
            DoDECAY
@@:         ret

align 16
ExecEnv12:  cmp     dword ptr [esi+AY_EnvVolume], 15
            je      Set_ATTACK
            DoATTACK
            ret

align 16
ExecEnv13:  cmp     byte ptr [esi+AY_EnvMode], env_HOLD
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 15
            je      Set_HOLD
            DoATTACK
@@:         ret

align 16
ExecEnv14:  .if     byte ptr [esi+AY_EnvMode] == env_ATTACK
                    cmp     dword ptr [esi+AY_EnvVolume], 15
                    je      Set_DECAY
                    DoATTACK
                    ret
            .else
                    cmp     dword ptr [esi+AY_EnvVolume], 0
                    je      Set_ATTACK
                    DoDECAY
                    ret
            .endif
            ret

align 16
ExecEnv15:  cmp     byte ptr [esi+AY_EnvMode], env_OFF
            je      @F
            cmp     dword ptr [esi+AY_EnvVolume], 15
            je      Set_OFF
            DoATTACK
@@:         ret

Set_OFF:    mov     byte ptr [esi+AY_EnvMode],   env_OFF
            mov     dword ptr [esi+AY_EnvVolume], 0
            ret
Set_ATTACK: mov     byte ptr [esi+AY_EnvMode],   env_ATTACK
            mov     dword ptr [esi+AY_EnvVolume], 0
            ret
Set_DECAY:  mov     byte ptr [esi+AY_EnvMode],   env_DECAY
            mov     dword ptr [esi+AY_EnvVolume], 15
            ret
Set_HOLD:   mov     byte ptr [esi+AY_EnvMode],   env_HOLD
            mov     dword ptr [esi+AY_EnvVolume], 15
            ret

;#################################################################################

align 16
GetAYSample:
            lea     esi, AYBase
            inc     dword ptr [esi+AY_SampleCounter]

            mov     dh, [esi+AY_R7]
            mov     bh, [esi+AY_NoiseOutput]

            mov     al, [esi+AY_ChAOutput]
            mov     cl, [esi+AY_R8]
            call    MixOutput
            add     [esi+AY_Total_ChanA], ecx
            mov     [esi+AY_FinalChanA],  cx

            shr     dh, 1
            mov     al, [esi+AY_ChBOutput]
            mov     cl, [esi+AY_R9]
            call    MixOutput
            add     [esi+AY_Total_ChanB], ecx
            mov     [esi+AY_FinalChanB],  cx

            shr     dh, 1
            mov     al, [esi+AY_ChCOutput]
            mov     cl, [esi+AY_R10]
            call    MixOutput
            add     [esi+AY_Total_ChanC], ecx
            mov     [esi+AY_FinalChanC],  cx
            ret

 align 16
MixOutput:  xor     edi, edi

            mov     dl, dh
            mov     ch, dh
            and     dl, 1
            shr     ch, 3
            or      al, dl                  ; (Tone OR ToneEnable)
            or      ch, bh                  ; (Noise OR NoiseEnable)
            and     al, ch                  ; al = 0 OR 1 for this channel's final output

            shr     al, 1
            sbb     edi, edi                ; edi = 0 for no output, -1 for output

            test    cl, 16
            cmovnz  ecx, [esi+AY_EnvVolume]

            and     ecx, 15
            mov     ecx, [PSGVolumes+ecx*4]

            and     ecx, edi
            ret

;#################################################################################

align 16
StreamAudio:
            .if     lpAYBuffer == NULL       ; exit if we have no private buffer
                    ret
            .endif

; retrieve the number of bytes of audio data we have buffered
            mov     eax,lpAYBuffer_Posn
            sub     eax,lpAYBuffer          ; bytes of audio data = (current buffer posn - base buffer posn)
            mov     AY_BufferedBytes,eax    ; AY_BufferedBytes = number of bytes of audio data we have

; now we lock the DS buffer and stream our audio data

LockBeepBuffer:
            DSBINVOKE   mLock,  SecondaryBuffer, DSBuff_WritePosn, AY_BufferedBytes, \
                                addr audio_ptr_1, addr audio_length_1, \
                                addr audio_ptr_2, addr audio_length_2, \
                                NULL

            .if     eax == DSERR_BUFFERLOST
                    call    RestoreSoundBuffer
                    jmp     LockBeepBuffer
            .endif

            .if     eax == DS_OK
                    mov     esi, lpAYBuffer
                    mov     edi, audio_ptr_1
                    mov     ecx, audio_length_1
                    shr     ecx, 2
                    rep     movsd
                    mov     ecx, audio_length_1
                    and     ecx, 3
                    rep     movsb

                    mov     esi, lpAYBuffer
                    add     esi, audio_length_1
                    mov     edi, audio_ptr_2
                    mov     ecx, audio_length_2
                    shr     ecx, 2
                    rep     movsd
                    mov     ecx, audio_length_2
                    and     ecx, 3
                    rep     movsb

                    DSBINVOKE   Unlock, SecondaryBuffer, audio_ptr_1, audio_length_1, \
                                                         audio_ptr_2, audio_length_2

                    .if     eax != DS_OK
                            FATAL "DirectSound Unlock failed !"
                    .endif

                    .if     SoundPlaying == 0
                            DSBINVOKE   SetCurrentPosition, SecondaryBuffer, 0
                            DSBINVOKE   Play, SecondaryBuffer, 0, 0, DSBPLAY_LOOPING
                            mov         SoundPlaying, 1
                    .endif
            .endif

            mov     eax, lpAYBuffer
            mov     lpAYBuffer_Posn, eax    ; reset our current buffer posn to the base of the buffer


; DSBuff_WritePosn = (DSBuff_WritePosn + AY_BufferedBytes) MOD DSBUFFERSIZE

            mov     eax, DSBuff_WritePosn
            add     eax, AY_BufferedBytes
            .if     eax >= DSBUFFERSIZE
                    sub     eax, DSBUFFERSIZE
            .endif
            mov     DSBuff_WritePosn, eax

;-----------------------------------------

; stream audio to wave file if required

            .if     AudioFH != 0
                    .if     AudioFileLength < (200*(1024*1024))  ; limit to approx 200MB
                            invoke  WriteFile, AudioFH, lpAYBuffer, AY_BufferedBytes, addr BytesSaved, NULL
                            mov     eax, AY_BufferedBytes
                            add     AudioFileLength, eax
                    .endif
            .endif

;-----------------------------------------

            mov     process_priority_set, FALSE

            .if     (TapePlaying == TRUE) && (FastTapeLoading == TRUE)
                    jmp     BWP_Cont    ; skip DSound buffer syncing
            .endif

            .if     FULLSPEEDMODE == NULL
                    jmp     WaitForPosn_1

WaitForPosn:        .if     process_priority_set == FALSE
                            invoke  SetPriorityClass, $fnc (GetCurrentProcess), HIGH_PRIORITY_CLASS
                            mov     process_priority_set, TRUE
                    .endif

                    invoke  Sleep, 1

WaitForPosn_1:      DSBINVOKE GetCurrentPosition, SecondaryBuffer, addr CurrentPlayCursor, addr CurrentWriteCursor

                    .if     eax != DS_OK
                            FATAL   "DirectSound GetCurrentPosition() failed!"
                    .endif

                    ; loop back until (CurrentWriteCursor >= DSBuff_WaitPosn) && (CurrentWriteCursor < DSBuff_WaitPosn + (SAMPLEBYTESPERFRAME-1))

                    ; are we in the buffer block we're waiting for?
                    invoke  InBufferBlock, DSBuff_WaitPosn
                    cmp     eax, TRUE
                    je      BWP_Cont    ; exit if we are

                    ; else are we in the preceding buffer block still?
                    mov     ecx, DSBuff_WaitPosn
                    sub     ecx, SampleBytesToBuffer
                    .if     CARRY?
                            add     ecx, DSBUFFERSIZE
                    .endif
                    invoke  InBufferBlock, ecx
                    cmp     eax, TRUE
                    je      WaitForPosn     ; loop with sleep if we're in this buffer block
            .endif
;-----------------------------------------

BWP_Cont:       .if     process_priority_set == TRUE
                        invoke  SetPriorityClass, $fnc (GetCurrentProcess), NORMAL_PRIORITY_CLASS
                        mov     process_priority_set, FALSE
                .endif

                ; DSBuff_WaitPosn = (DSBuff_WaitPosn + AY_BufferedBytes) MOD DSBUFFERSIZE
                mov     eax, DSBuff_WaitPosn
                add     eax, AY_BufferedBytes
                .if     eax >= DSBUFFERSIZE
                        sub     eax, DSBUFFERSIZE
                .endif
                mov     DSBuff_WaitPosn, eax

BWP_Exit:       ret

align 16
InBufferBlock   proc    uses            ebx ecx,
                        DSBlockOffset:  DWORD

                mov     eax, CurrentWriteCursor     ; eax = current writecursor position
                mov     ebx, DSBlockOffset          ; ebx = block start position
                mov     ecx, ebx
                add     ecx, SampleBytesToBuffer    ; add (SAMPLEBYTESPERFRAME - 1)
                dec     ecx                         ; ecx = block end position

                .if     (eax >= ebx) && (eax <= ecx)
                        return  TRUE                ; return TRUE if within this block
                .endif

                return  FALSE                       ; else return FALSE

InBufferBlock   endp

;#################################################################################

RestoreSoundBuffer:
            DSBINVOKE   Restore, SecondaryBuffer
            cmp         eax, DS_OK
            jne         RestoreSoundBuffer
            ret

;#################################################################################

StopDirectSoundPlayback:
            DSBINVOKE   Stop, SecondaryBuffer
            ret

;#################################################################################

StartupDirectSound:
            push        esi
            mov         Sound_Available, FALSE

            mov         eax,    AUDIOFREQ
            invoke      Div2Int, eax, MACHINE.FramesPerSecond
            shl         eax, 6  ; *8*8
            mov         DSBUFFERSIZE, eax

            invoke      DirectSoundCreate, 0, addr lpds, 0
            .if         eax != DS_OK
                        pop     esi
                        ret
                        FATAL   "DirectSoundCreate failed", eax
            .endif

            DSINVOKE    SetCooperativeLevel, lpds, hWnd, DSSCL_PRIORITY
            .if         eax != DS_OK
                        pop     esi
                        ret
                        FATAL   "DirectSound SetCooperativeLevel failed", eax
            .endif

            ; create the primary Spectrum directsound buffer
            invoke      RtlFillMemory, addr dsbd, sizeof DSBUFFERDESC, 0

            assume      esi: ptr DSBUFFERDESC
            lea         esi, dsbd
            mov         [esi].dwSize,           sizeof DSBUFFERDESC
            mov         [esi].dwFlags,          DSBCAPS_GETCURRENTPOSITION2 or DSBCAPS_GLOBALFOCUS
            m2m         [esi].dwBufferBytes,    DSBUFFERSIZE
            mov         [esi].lpwfxFormat,      offset WaveFormat

            assume      esi: ptr WAVEFORMATEX
            lea         esi, WaveFormat
            mov         [esi].wFormatTag,       WAVE_FORMAT_PCM
            mov         [esi].nChannels,        2
            mov         [esi].nSamplesPerSec,   AUDIOFREQ
            mov         [esi].nAvgBytesPerSec,  AUDIOFREQ*4
            mov         [esi].nBlockAlign,      (16*2)/8
            mov         [esi].wBitsPerSample,   16
            mov         [esi].cbSize,           0

            DSINVOKE    CreateSoundBuffer, lpds, addr dsbd, addr SecondaryBuffer, NULL
            .if         eax != DS_OK
                        FATAL   "CreateSoundBuffer failed", eax
            .endif

            mov         ecx, DSBUFFERSIZE
            shl         ecx, 1
            mov         lpAYBuffer, AllocMem (ecx) ; (DSBUFFERSIZE*2)

            ; create the drive step directsound buffer
            invoke      RtlFillMemory, addr dsbd, sizeof DSBUFFERDESC, 0

            assume      esi: ptr DSBUFFERDESC
            lea         esi, dsbd
            mov         [esi].dwSize,           sizeof DSBUFFERDESC
            mov         [esi].dwFlags,          DSBCAPS_STATIC
            mov         [esi].dwBufferBytes,    StepSampleSize    ; *** size of drive step sample ***
            mov         [esi].lpwfxFormat,      offset WaveFormat

            assume      esi: ptr WAVEFORMATEX
            lea         esi, WaveFormat
            mov         [esi].wFormatTag,       WAVE_FORMAT_PCM
            mov         [esi].nChannels,        1
            mov         [esi].nSamplesPerSec,   8000
            mov         [esi].nAvgBytesPerSec,  8000
            mov         [esi].nBlockAlign,      (8*1)/8
            mov         [esi].wBitsPerSample,   8
            mov         [esi].cbSize,           0

            DSINVOKE    CreateSoundBuffer, lpds, addr dsbd, addr DriveStepBuffer, NULL
            .if         eax != DS_OK
                        FATAL   "CreateSoundBuffer failed", eax
            .endif

            DSBINVOKE   mLock,  DriveStepBuffer, 0, 0, addr audio_ptr_1, addr audio_length_1, NULL, NULL, DSBLOCK_ENTIREBUFFER

            lea     esi, StepSample
            mov     edi, audio_ptr_1
            mov     ecx, audio_length_1
            rep     movsb

            DSBINVOKE   Unlock, DriveStepBuffer, audio_ptr_1, audio_length_1, NULL, 0


            ; finished directsound setup
            mov         DSoundStarted, TRUE

            mov         Sound_Available, TRUE

            pop         esi
            ret

            assume      esi: nothing

.const
align 16
; C:\RadAsm\Masm\Projects\SpecEmu\DriveStep.wav is 466 bytes long
StepSample  db 128,128,128,128
            db 128,128,128,128,128,128,128,128,128,128,128,127,124,122,126,129
            db 129,128,129,134,133,130,132,136,142,149,150,142,139,149,155,147
            db 143,144,143,143,140,127,118,126,136,128,112,111,120,118,108,104
            db 112,123,125,122,122,127,135,141,139,141,157,164,149,143,152,153
            db 142,133,129,129,130,121,112,126,142,127,101,107,125,124,117,120
            db 122,122,121,112,98,103,120,119,116,134,143,133,138,153,150,139
            db 146,156,145,134,136,131,128,136,132,114,117,132,130,128,143,147
            db 139,143,152,145,139,144,144,136,130,127,120,115,114,110,108,119
            db 130,126,114,111,115,118,119,124,131,141,154,156,145,143,154,156
            db 151,155,164,166,154,134,119,117,121,121,119,123,130,130,119,112
            db 119,126,125,128,135,141,138,127,118,120,126,124,121,124,127,122
            db 113,109,113,122,125,126,132,139,136,130,132,138,144,147,149,152
            db 157,154,145,141,141,140,141,141,141,140,135,129,128,128,128,128
            db 128,128,126,123,118,116,121,126,126,126,128,130,130,132,136,143
            db 148,149,147,145,145,142,137,133,134,139,140,139,139,140,139,138
            db 140,143,146,148,148,145,140,134,129,128,128,129,132,135,136,133
            db 129,125,123,126,128,128,130,131,129,128,127,127,128,131,133,133
            db 133,131,128,128,132,138,145,149,151,151,147,144,146,150,153,156
            db 157,153,149,145,143,141,140,140,140,137,133,128,126,126,127,129
            db 132,135,137,138,139,141,145,150,154,155,154,151,146,141,138,139
            db 140,141,141,139,136,133,134,135,138,140,141,141,141,140,139,138
            db 138,139,140,140,139,137,135,135,135,138,140,141,140,140,138,136
            db 134,132,128,128,128,128
StepSampleEnd   LABEL   BYTE

StepSampleSize  equ     StepSampleEnd-StepSample
.code

;#################################################################################

ShutdownDirectSound:
            .if         Sound_Available == TRUE
                        DSBINVOKE   Stop,    SecondaryBuffer
                        DSBINVOKE   Release, SecondaryBuffer

                        DSBINVOKE   Stop,    DriveStepBuffer
                        DSBINVOKE   Release, DriveStepBuffer
            .endif

            .if         lpds != 0
                        DSINVOKE Release, lpds
                        mov     lpds, 0
            .endif

            .if         lpAYBuffer != 0
                        invoke  GlobalFree, lpAYBuffer
                        mov     lpAYBuffer, 0
            .endif
            mov         DSoundStarted, FALSE
            ret

;#################################################################################

.data
align 4
AudioDummyLength    dd  0

WavHeader       db  "RIFF"
                dd  0               ; RIFF size
                db  "WAVE"

                ; Format chunk
                db  "fmt "
                dd  16              ; fmt length
                dw  1               ; wFormat tag
                dw  2               ; wChannels
WavHd1          dd  0               ; AUDIOFREQ    = dwSamplesPerSec
WavHd2          dd  0               ; AUDIOFREQ*4  = dwAvgBytesPerSec
                dw  4               ; wBlockAlign
                dw  16              ; wBitsPerSample

                ; Data chunk
                db  "data"
                dd  0               ; DATA chunk size
WavEnd          db  0

WAVHEADERSIZE   equ WavEnd-WavHeader    ; = 44 bytes

szAudioFilter   db "WAV files", 0, "*.wav", 0, 0

.code

;#################################################################################

OpenAudioFile   proc

                local   ofn:    OPENFILENAME,
                        _saved: DWORD

                mov     AudioFH, 0
                mov     AudioFileLength, 0

                invoke  SaveFileName, hWnd, SADD ("Save WAV File"), addr szAudioFilter, addr ofn, addr audiofilename, addr WAVExt, 0
                .if     eax != 0
                        invoke  CreateFile, addr audiofilename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL, NULL
                        .if     eax != INVALID_HANDLE_VALUE
                                mov     AudioFH, eax

                                mov     eax, AUDIOFREQ
                                mov     WavHd1, eax
                                shl     eax, 2
                                mov     WavHd2, eax
                                invoke  WriteFile, AudioFH, addr WavHeader, WAVHEADERSIZE, addr _saved, NULL
                        .endif
                .endif
                ret

OpenAudioFile   endp

;#################################################################################

CloseAudioFile:
            .if     AudioFH != 0

; write RIFF chunk size
                    invoke  SetFilePointer, AudioFH, 4, NULL, FILE_BEGIN
                    mov     eax, [AudioFileLength]
                    add     eax, WAVHEADERSIZE-8
                    mov     [AudioDummyLength], eax
                    invoke  WriteFile, AudioFH, addr AudioDummyLength, 4, addr BytesSaved, NULL

; write DATA chunk size
                    invoke  SetFilePointer, AudioFH, 40, NULL, FILE_BEGIN
                    mov     eax, [AudioFileLength]
                    mov     [AudioDummyLength], eax
                    invoke  WriteFile, AudioFH, addr AudioDummyLength, 4, addr BytesSaved, NULL
                    
                    invoke  CloseHandle, AudioFH
                    mov     AudioFH, 0
            .endif
            ret

;#################################################################################

