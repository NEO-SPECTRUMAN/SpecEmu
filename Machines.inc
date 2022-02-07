
SAMPLEPERIOD            STRUCT
SampleLoopCount         BYTE    ?
SampleLoopAdjustRate    BYTE    ?
SampleLoopAdjustValue   BYTE    ?
CyclesPerSample         BYTE    ?
CurrentCyclesPerSample  BYTE    ?
SAMPLEPERIOD            ENDS

MACHINESPEC             STRUCT
FrameCycles             DWORD   ?
InterruptCycles         DWORD   ?
ScanlineCycles          DWORD   ?
ULAFrameStart           DWORD   ?
RendererEntryPoint      DWORD   ?   ; renderer's entry point at each frame start

FramesPerSecond         DWORD   ?

RomSpaceUpperCheck      WORD    ?   ; used in Leave ROM space debugger option

AUDIOPERIOD             SAMPLEPERIOD    <?>
REALTAPEPERIOD          SAMPLEPERIOD    <?>

align 4
DisplayWidth            DWORD   ?   ; width (in pixels) of this machine's display
DisplayHeight           DWORD   ?   ; height (in pixels) of this machine's display
PixelWidth              DWORD   ?   ; number of horizontal pixels
BorderWidth             DWORD   ?   ; width (in pixels) of this machine's border spanning the display area
TopBorderLines          BYTE    ?
DisplayLines            BYTE    ?
BottomBorderLines       BYTE    ?

DoesSnow                BYTE    ?
CrashesOnSnow           BYTE    ?
HasFloatingBus          BYTE    ?
HasLowPortContention    BYTE    ?
Has_AY                  BYTE    ?
Has_ULAColourArtifacts  BYTE    ?
Has_ULAplus             BYTE    ?

Plus3_Compatible        BYTE    ?   ; true for +2a/+3 machines; allows for quicker way of checking for +3 compatible hardware (esp. useful in the Z80 core)

MACHINESPEC             ENDS

.data?
align 16
MACHINE                 MACHINESPEC <?>

.code

INTPERIOD_48K       equ     32
INTPERIOD_128K      equ     36
INTPERIOD_PLUS3     equ     32
INTPERIOD_PENTAGON  equ     36
;LATE_INTPERIOD      equ     TRUE    ; allow late timings to affect interrupt period; off gives correct A100 result for early.tap
