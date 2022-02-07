
; 240 display lines
TOPBORDERLINES      equ 24
DISPLAYLINES        equ 192
BOTTOMBORDERLINES   equ 24

DIRTYLINESCOUNT     equ (TOPBORDERLINES+DISPLAYLINES+BOTTOMBORDERLINES)*3

SpectrumGfx         STRUCT
TargetAddr          DWORD   ?
zxDisplayOrg        DWORD   ?   ; pointer to current display file
DisplayOffset       DWORD   ?
AttrOffset          DWORD   ?
ScreenVector        DWORD   ?
WaitTState          DWORD   ?
ScanTState          DWORD   ?
TargetScanlineAddr  DWORD   ?
BorderColour        DWORD   ?   ; 4 bytes of border colour (0-7) + CLR_SPECBASE
TimexBorderColour   DWORD   ?   ; 4 bytes of border colour (0-7) + CLR_SPECBASE for Timex machine
ULAPlusBorderColour DWORD   ?   ; 4 bytes of border colour (0-7) + 8 for ULAplus mode
VerticalOffset      DWORD   ?
TVNoiseLines        DWORD   ?
TVNoiseCounter      DWORD   ?
ptrSpecColourTable  DWORD   ?
ptrULA64ColourTable DWORD   ?
ptrTimexColourTable DWORD   ?
UDCnt               BYTE    ?
FetchCycle          BYTE    ?
SnowEffect          BYTE    ?
DoSnow              BYTE    ?
TopBorderCnt        BYTE    ?
BottomBorderCnt     BYTE    ?
CurrDisplayLine     BYTE    ?
FrameCnt            BYTE    ?
FrameBlit           BYTE    ?   ; TRUE if on-screen display needs re-blitting
FrameChanged        BYTE    ?   ; TRUE if display changed during frame
FlashInverterByte   BYTE    ?   ; toggles 0/255; xors with display byte for flashing chars
DisplayByte         BYTE    ?
AttrByte            BYTE    ?
PrevAttrByte        BYTE    ?
PixelCount          BYTE    ?
IsPaper             BYTE    ?
LastColour          BYTE    ?
ULA64_Active        BYTE    ?   ; TRUE if 64 colour mode enabled
float_byte          BYTE    ?
plus3_float_byte    BYTE    ?
CurrScreen          BYTE    ?   ; currently paged display (0/1) (128k models)
SpectrumGfx         ENDS

.data?
align 16
SPGfx               SpectrumGfx <?>

align 4
Timex_Hires_Border  DWORD   ?   ; for hi-res mode
Timex_Screen_Colour BYTE    ?   ; for hi-res mode
Timex_Port_FF       BYTE    ?
Timex_Screen_Mode   BYTE    ?

align 16
have_pasmo          BOOL    ?
have_mmx            BOOL    ?
TVRandomSeed        DWORD   ?
ULATune             DWORD   ?
DisplayTablePtr     DWORD   ?
DisplayTable        DWORD   192*2 DUP (?)
DirtyLinesPtr       DWORD   ?
DirtyLines          BYTE    DIRTYLINESCOUNT DUP (?)



ULAFRAMESTART_48K       equ  14340-16-(224*TOPBORDERLINES)
ULAFRAMESTART_128K      equ  14366-16-(228*TOPBORDERLINES)
ULAFRAMESTART_PLUS3     equ  14369-16-(228*TOPBORDERLINES)
ULAFRAMESTART_PENTAGON  equ  18007-16-20-(224*TOPBORDERLINES) ;18007-32-12-(224*TOPBORDERLINES)
ULAFRAMESTART_TC2048    equ  14325-16-(224*TOPBORDERLINES)
ULAFRAMESTART_TK90X     equ  8763-16-(228*TOPBORDERLINES) ; 8764-16-(228*TOPBORDERLINES)

.code

; preserve eax for RestoreSurfaces call
align 16
SetDirtyLines       proc    uses    eax edi
                    lea     edi, DirtyLines
                    mov     ecx, DIRTYLINESCOUNT
                    mov     al, 1
                    rep     stosb
                    mov     SPGfx.FrameChanged, TRUE
                    ret
SetDirtyLines       endp

SetDisplayTable     proc

                    lea     edx, DisplayTable
                    xor     eax, eax            ; offset from display memory into bitmap memory
                    mov     ecx, 6144           ; offset from display memory into attribute memory

                    SETLOOP 192
                            mov     [edx],   eax        ; store bitmap offset
                            mov     [edx+4], ecx        ; store attribute offset
                            add     edx, 8

                            inc     ah
                            test    ah, 7
                            .if     ZERO?
                                    sub     ah, 8
                                    add     ecx, 32
                                    add     al, 32
                                    ifc     CARRY? then add ah, 8
                            .endif
                    ENDLOOP
                    ret

SetDisplayTable     endp

align 16
InitUpdateScreen:           push    esi

                            lea     esi, SPGfx
                            assume  esi: ptr SpectrumGfx

                            mov     al, [esi].FrameCnt
                            inc     al
                            and     al, 31
                            mov     [esi].FrameCnt, al

                            cmp     al, 16
                            cmc
                            sbb     al, al
                            mov     [esi].FlashInverterByte, al     ; 0 or 255

                            .if     Extremely_Dodgy_TV_Enabled == TRUE
                                    .if     [esi].TVNoiseCounter > 0
                                            dec     [esi].TVNoiseCounter
                                            lea     eax, PrepTVNoise
                                    .else
                                            invoke  nrandom, 255
                                            .if     eax < 2
                                                    invoke  nrandom, 30
                                                    add     eax, 15
                                                    mov     [esi].TVNoiseCounter, eax
                                            .endif
                                            mov     eax, MACHINE.RendererEntryPoint
                                    .endif
                                    mov     [esi].ScreenVector, eax
                            .endif

                            .if     [esi].TVNoiseCounter > 0
                                    dec     [esi].TVNoiseCounter
                                    lea     eax, PrepTVNoise
                            .else
                                    mov     eax, MACHINE.RendererEntryPoint
                            .endif
                            mov     [esi].ScreenVector, eax

                            mov     eax, lpDIBBits
                            mov     [esi].TargetAddr, eax
                            mov     [esi].TargetScanlineAddr, eax

                            mov     DirtyLinesPtr,   offset DirtyLines
                            mov     DisplayTablePtr, offset DisplayTable

                            mov     al, MACHINE.TopBorderLines
                            mov     [esi].TopBorderCnt, al
                            mov     al, MACHINE.BottomBorderLines
                            mov     [esi].BottomBorderCnt, al
                            mov     [esi].CurrDisplayLine, 0

                            movzx   eax, LateTimings
                            .if     (HardwareMode == HW_PLUS2A) || (HardwareMode == HW_PLUS3) || (HardwareMode == HW_TK90X)
                                    xor     eax, eax            ; +2A/+3 and TK90X don't have late timings
                            .endif
                            add     eax, MACHINE.ULAFrameStart

                            IFDEF   ULATUNING
                                    add     eax, ULATune
                            ENDIF

                            mov     [esi].WaitTState, eax
                            mov     [esi].ScanTState, eax

                            pop     esi
                            ret


RENDERCYCLES    MACRO
                .if     FrameSkipLoop == 1
                        push    ebx
                        mov     ebx, totaltstates
                        .if     ebx >= [SPGfx.WaitTState]
                                call    UpdateScreen
                        .endif
                        pop     ebx
                .endif
                ENDM


; "UpdateScreen" must always be called via the "RENDERCYCLES" macro

align 16
UpdateScreen:
            sub     esp, 24
            mov     [esp],    esi
            lea     esi, SPGfx
            mov     [esp+4],  edi
            mov     edi, [esi].TargetAddr
            mov     [esp+8],  ecx
            mov     [esp+12], edx
            mov     [esp+16], eax
            mov     [esp+20], ebp

            mov     ebp, DirtyLinesPtr

UpdateLoop: call    [esi].ScreenVector
            cmp     ebx, [esi].WaitTState
            jnc     UpdateLoop

            mov     [esi].TargetAddr, edi
            mov     DirtyLinesPtr, ebp

            mov     esi, [esp]
            mov     edi, [esp+4]
            mov     ecx, [esp+8]
            mov     edx, [esp+12]
            mov     eax, [esp+16]
            mov     ebp, [esp+20]
            add     esp, 24
UScrExit:   ret

            assume  esi: nothing


RENDERFRAME MACRO
            call    Render_Frame
            ENDM

align 16
; render the whole Spectrum display
Render_Frame:
            pushad
            invoke  SetDirtyLines   ; do first as renderer may write ULAplus control bits into dirty array for renderer

            push    totaltstates
            mov     al, FrameSkipLoop
            push    eax

            call    InitUpdateScreen
            mov     FrameSkipLoop, 1
            mov     totaltstates, 71680
            RENDERCYCLES

            pop     eax
            mov     FrameSkipLoop, al
            pop     totaltstates

            UPDATEWINDOW
            popad
            ret

            include SpectrumRenderer.asm
            include PentagonRenderer.asm
            include TimexRenderer.asm
            include TVNoiseRenderer.asm

