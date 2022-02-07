
uSpeech_Initialise      PROTO
uSpeech_PrepSamples     PROTO
uSpeech_WriteAllophone  PROTO   :BYTE
uSpeech_SetIntonation   PROTO   :BOOL
uSpeech_GetSample       PROTO

uSpeech_GetFrequency    PROTO
uSpeech_SetFrequency    PROTO   :DWORD

                        include uSpeech.inc


NUM_ALLOPHONES          equ     59

uSpeechReady            equ     0
uSpeechBusy             equ     1

uSpeechSilence          equ     0

.data?
align 16
AllophonePtrs           DWORD   NUM_ALLOPHONES*2    dup (?) ; ptr/len for samples 05-63

curr_allophone_len      DWORD   ?   ; length of current allophone remaining to play
curr_allophone_ptr      DWORD   ?   ; ptr to current position in allophone sample data
looping_allophone_len   DWORD   ?   ; copy of curr_allophone_len for looping last allophone
looping_allophone_ptr   DWORD   ?   ; copy of curr_allophone_ptr for looping last allophone
curr_allophone_num      BYTE    ?   ; current allophone number playing

Allophones_Ready        BOOL    ?   ; set when allophone table has been created

uPitchRamp              equ     10
uPitchNormal            DWORD   ?      
uPitchHigh              DWORD   ?

.data
align 16
uSpeech_PauseLengths    dd      10  * 3500 / 158
                        dd      30  * 3500 / 158
                        dd      50  * 3500 / 158
                        dd      100 * 3500 / 158
                        dd      200 * 3500 / 158

uSpeech_FreqTable       dd      3500000/(44100+4000)
                        dd      3500000/(33075+4000)
                        dd      3500000/(22050+4000) ; normal speed
                        dd      3500000/(16537+4000)
                        dd      3500000/(11025+4000)

;uSpeech_FreqTable       dd      3500000/44100
;                        dd      3500000/33075
;                        dd      3500000/22050-5 ; normal speed
;                        dd      3500000/16537
;                        dd      3500000/11025

uSpeech_Frequency       db      2   ; default frequency on application startup (range: 0 - 4)

                        STRINGLIST  uSpeech_FreqTextPtrs, "44 KHz", "33 KHz", "22 KHz (Default)", "16 KHz", "11 KHz"


.code

uSpeech_Initialise      proc    uses esi edi ebx

                        invoke  uSpeech_PrepSamples
                        invoke  uSpeech_SetFrequency, ZeroExt (uSpeech_Frequency)
                        invoke  uSpeech_SetIntonation, FALSE

                        mov     curr_allophone_len, 0
                        mov     uSpeech_Output, uSpeechSilence
                        mov     uSpeechStatus, uSpeechReady
                        mov     uSpeech_Paged, FALSE
                        ret

uSpeech_Initialise      endp

uSpeech_GetFrequency    proc
                        return  ZeroExt (uSpeech_Frequency)
uSpeech_GetFrequency    endp

uSpeech_SetFrequency    proc    Frequency:  DWORD

                        mov     eax, Frequency
                        ifc     eax gt 4 then mov eax, 2    ; reset to default if out of range

                        mov     uSpeech_Frequency, al

                        mov     eax, [uSpeech_FreqTable+eax*4]
                        mov     uPitchNormal, eax
                        sub     eax, uPitchRamp
                        mov     uPitchHigh, eax
                        ret

uSpeech_SetFrequency    endp

uSpeech_SetIntonation   proc    Intonation: BOOL

                        .if     Intonation == TRUE
                                mov     eax, uPitchHigh
                        .else
                                mov     eax, uPitchNormal
                        .endif
                        mov     uSpeech_Ticks, eax
                        ret
uSpeech_SetIntonation   endp

uSpeech_WriteAllophone  proc    Allophone: Byte

                        .if     uSpeechStatus == uSpeechReady

;                                test    Allophone, 64
;                                .if     !ZERO?
;                                        invoke  uSpeech_SetIntonation, TRUE
;                                .else
;                                        invoke  uSpeech_SetIntonation, FALSE
;                                .endif

                                movzx   eax, Allophone
                                and     eax, 63
                                mov     curr_allophone_num, al

                                .if     eax >= 5
                                        sub     eax, 5
                                        lea     eax, [AllophonePtrs+eax*8]
                                        mov     ecx, [eax]      ; allophone sample pointer
                                        mov     eax, [eax+4]    ; allophone sample length
                                        mov     curr_allophone_ptr, ecx
                                        mov     curr_allophone_len, eax
        
                                        mov     looping_allophone_ptr, ecx
                                        mov     looping_allophone_len, eax
                                .else
                                        mov     eax, [uSpeech_PauseLengths+eax*4]
                                        mov     curr_allophone_len, eax
                                        mov     uSpeech_Output, uSpeechSilence
                                .endif

                                mov     uSpeechTimer, 0
                                mov     uSpeechStatus, uSpeechBusy
                        .endif
                        ret

uSpeech_WriteAllophone  endp

uSpeech_GetSample       proc

                        cmp     curr_allophone_len, 0
                        jne     @next_sample

                        ; repeat current allophone
                        m2m     looping_allophone_ptr, curr_allophone_ptr
                        m2m     looping_allophone_len, curr_allophone_len
                        mov     uSpeechStatus, uSpeechReady
                        ret


        @next_sample:   mov     eax, uSpeechTimer
                        .if     eax < uSpeech_Ticks
                                ret
                        .endif

                        mov     eax, uSpeechTimer
                        sub     eax, uSpeech_Ticks
                        mov     uSpeechTimer, eax

                        dec     curr_allophone_len

                        .if     curr_allophone_num >= 5
                                mov     eax, curr_allophone_ptr
                                inc     curr_allophone_ptr

                                movzx   eax, byte ptr [eax]
                                shl     eax, 7              ; 0 to 32640
                                sub     eax, 128 shl 7      ; -16384 to 16256

                                mov     uSpeech_Output, ax
                        .endif

                        ret
uSpeech_GetSample       endp

uSpeech_PrepSamples     proc    uses esi edi ebx

                        .if     Allophones_Ready == FALSE
                                lea     esi, uSpeechSamples
                                lea     edi, AllophonePtrs
                                mov     edx, NUM_ALLOPHONES
                            @@: lea     esi, [esi+40]   ; esi = sample length dword
                                lodsd                   ; eax = sample length; esi = sample data
                                mov     [edi],   esi
                                mov     [edi+4], eax
                                add     edi, 8          ; next allophone ptr/len
                                test    eax, 1
                                .if     !ZERO?
                                        inc     eax     ; always even-aligned sample lengths in the WAV files
                                .endif
                                add     esi, eax        ; esi = next sample
                                dec     edx
                                jnz     @B

                                mov     Allophones_Ready, TRUE
                        .endif

                        ret
uSpeech_PrepSamples     endp



