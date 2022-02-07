
            ASSUME  ESI: PTR SpectrumGfx

PrepTVNoise:
            mov     [esi].ScreenVector, OFFSET TVNoiseScanline
            mov     [esi].TVNoiseLines, 24+192+24 ; 48+192+56

PrepNextTVNoise:
            mov     [esi].UDCnt, DIBWidth/8 ; 44

Align 16
TVNoiseScanline:
            mov     byte ptr [ebp], 1
            mov     byte ptr [ebp+1], 1
            mov     byte ptr [ebp+2], 1
            add     ebp, 3
            mov     [esi].FrameChanged, TRUE

.data
even
TVN_NoiseVals   db  CLR_SPECBASE+0, CLR_SPECBASE+15

.code

TVN_ScanLp: mov     edx, 8

@@:         call    TVNoiseBit

            mov     al, [TVN_NoiseVals][eax]
            mov     [edi], al
            add     edi, 1

            dec     edx
            jnz     @B

            dec     [esi].UDCnt
            jnz     TVN_ScanLp

            NEXTSCANLINEADDR
            mov     eax, [esi].ScanTState
            add     eax, MACHINE.ScanlineCycles
            mov     [esi].ScanTState, eax
            mov     [esi].WaitTState, eax

            mov     edx, [esi].ScanTState
            add     edx, MACHINE.ScanlineCycles
            mov     [esi].ScanTState, edx
            mov     [esi].WaitTState, edx

            dec     [esi].TVNoiseLines
            jnz     PrepNextTVNoise

            mov     [esi].ScreenVector, OFFSET UScrExit
            mov     [esi].WaitTState, 180000
            ret

            ASSUME  ESI:NOTHING

.code
align 16
TVNoiseBit: mov     eax, TVRandomSeed

            test    eax, 1
            .if     !ZERO?
                    xor   eax, 24000h
            .endif
            shr     eax, 1

            mov     TVRandomSeed, eax
            and     eax, 1
            ret


