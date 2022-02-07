
; WAVHEADERSIZE defined in DirectSound.asm
; only required here for soundless build
                        IFNDEF  WANTSOUND
WAVHEADERSIZE           equ     44
                        ENDIF

; tape type definitions:
RESETENUM               0
ENUM                    Type_NONE, Type_TAP, Type_TZX, Type_WAV, Type_CSW, Type_PZX

SPECIAL_PAUSE_BLOCK     equ 0FEh

.data?
align 16
CSW_Load_Handle         DWORD   ?   ; CSW object handle from csw.dll for reading CSW files
CSW_Save_Handle         DWORD   ?   ; CSW object handle from csw.dll for writing CSW files

BlockData               DWORD ?
BytePtr                 DWORD ?
ByteCount               DWORD ?

LastDataBlockPauseLocation	DWORD ?
TapeDataBlockCnt        DWORD   ?
FirstTAPBlockPtr        DWORD   ?

SaveTapeTStates         DWORD   ?
SaveTapePulsePeriod     DWORD   ?

_tapfilesize            DWORD   ?

TZXCallBlockPtr         DWORD   ?

TZXAvail                DWORD   ?
TZXJump                 DWORD   ?

Tape_Pause_ms           DWORD   ?

TZXCurrBlock            WORD    ?

TapeTStates             WORD    ?
TZXCountDown            WORD    ?

TZXPause                WORD    ?
TZXWantPause            WORD    ?

TZXLoopCounter          WORD    ?
TZXLoopBlockNum         WORD    ?
LengthPilotTone         WORD    ?
LengthPilotPulse        WORD    ?
LengthSyncFPulse        WORD    ?
LengthSyncSPulse        WORD    ?

                    ; these two need to remain together in this order (see MainBitLoop)
LengthZeroBitPulse      WORD    ?
LengthOneBitPulse       WORD    ?

TZXNumCalls             WORD    ?
TZXCallReturn           WORD    ?

UsedBitsLastByte        BYTE    ?

TAPEByte                BYTE    ?
TAPENumBits             BYTE    ?
EarBit                  BYTE    ?
EarXor                  BYTE    ? ; default: 0. xor 64 on "tapeinvert" command in debug command parser
EdgeTrigger             BYTE    ?
EdgeTriggerAck          BYTE    ?

; now defined in Z80Core.asm
;LoadTapeType            BYTE    ?
;SaveTapeType            BYTE    ?

TapeExtBuffer           BYTE    8   dup (?)

tape_last_edges_rate    BYTE    ?
tape_last_edges_offset  BYTE    ?
tape_last_edges_buffer  BYTE    15  dup (?)


.data
SaveCSWFileVersion      dd      2       ; default is to save CSW files as version 2
SaveCSWSampleRate       dd      44100   ; default CSW sample rate

CSWHEADER               STRUCT
    IDString            BYTE    23 dup(?)   ; ID string + $1A
    Major               BYTE    ?
    Minor               BYTE    ?
    SampleRate          WORD    ?
    CompressionType     BYTE    ?
    Polarity            BYTE    ?
    Reserved            BYTE    3 dup(?)
CSWHEADER               ENDS

TPZX                    STRUCT
    BlockData           DWORD   ?
    BlockSize           DWORD   ?
    Count               DWORD   ?
    Duration            DWORD   ?
    Duration1           DWORD   ?
    Pause               DWORD   ?
    PulseSequence       DWORD   ?
    PulseCount          DWORD   ?
    DataStream          DWORD   ?
    NumDataStreamBits   DWORD   ?
    Data_s0             DWORD   ?
    Data_s1             DWORD   ?

    TailPulse           WORD    ?

    Data_p0             BYTE    ?
    Data_p1             BYTE    ?
    BitNumber           BYTE    ?
TPZX                    ENDS

.code


