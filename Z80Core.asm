;############################################################################################
;
;                                   Z80 Emulation Core
;                                   ==================
;
;############################################################################################

; Z80 memory access to DRAM row select
; (addr >> 7) and 7F
;
; 0011 1111 1111 1111
; =
; 0011 1111 1000 0000


.code
Machine_Create              PROTO   :PTR TMACHINE, :BYTE
Machine_Delete              PROTO   :PTR TMACHINE
Machine_Switch              PROTO   :PTR TMACHINE,:PTR TMACHINE

Machine_Create              proc    uses    esi edi ebx,
                                    machine:ptr TMACHINE,
                                    m_type: byte

                            assume  edi:ptr TMACHINE

                            mov     edi, machine
                            .if     edi != 0
                                    memclr  edi, sizeof TMACHINE

                                    mov     al, m_type
                                    mov     HardwareMode, al

                                    mov     esi, AllocMem (16384 * 8)
                                    .if     esi != 0
                                            lea     ebx, [edi].bank_ptrs

                                            mov     [edi].bank5, esi    ; ptr to bank 5 is also pointer to mem block for Free()
                                            mov     [ebx][5*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank2, esi
                                            mov     [ebx][2*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank0, esi
                                            mov     [ebx][0*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank1, esi
                                            mov     [ebx][1*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank3, esi
                                            mov     [ebx][3*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank4, esi
                                            mov     [ebx][4*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank6, esi
                                            mov     [ebx][6*4], esi
                                            lea     esi, [esi+16384]

                                            mov     [edi].bank7, esi
                                            mov     [ebx][7*4], esi

                                            return  True
                                    .endif
                            .endif

                            return  False

                            assume  edi:nothing
Machine_Create              endp

Machine_Delete              proc    uses    esi edi ebx,
                                    machine:PTR TMACHINE

                            assume  edi:ptr TMACHINE

                            mov     edi, machine
                            .if     edi != 0
                                    invoke  FreeMemory, [edi].bank5
                            .endif
                            ret

                            assume  edi:nothing
Machine_Delete              endp

Machine_Switch              proc    uses    esi edi ebx,
                                    machine1:PTR TMACHINE,
                                    machine2:PTR TMACHINE

                            mov     esi, machine1
                            mov     edi, machine2
                            mov     ebx, sizeof TMACHINE

                        @@: mov     al, [esi]
                            mov     ah, [edi]
                            mov     [esi], ah
                            mov     [edi], al
                            inc     esi
                            inc     edi
                            dec     ebx
                            jnz     @B

                            ret

Machine_Switch              endp

.data
align 4
DRAMFADEMASK                dd      01110111110110111011011111101110b ; 11111111 11111111 11111111 11111111b

.code
align 16
DRAM_Fade                   proc    uses    esi edi ebx

                            local   dram_fade_msg: BOOL

                            mov     dram_fade_msg, FALSE

                            ; increment all refresh counters
                            lea     esi, currentMachine.refresh_counters
                            mov     eax, 01010101h
                            mov     ecx, 128/4

                        @@: add     [esi], eax
                            add     esi, 4
                            dec     ecx
                            jnz     @B

                            DRAM_FRAMES_2_FADE  equ     50

                            lea     esi, currentMachine.refresh_counters
                            xor     edx, edx    ; byte offset into DRAM; advances 128 bytes per RAS row

                            SETLOOP 128     ; 128 RAS rows per DRAM
                                    .if     byte ptr [esi] >= DRAM_FRAMES_2_FADE

                                            mov     dram_fade_msg, TRUE

                                            xor     ebx, ebx
                                            ; for all 8 RAM pages
                                            .while  ebx < 8
                                                    ; if this RAM is fadeable
                                                    .if     [currentMachine.DoesDRAMFade+ebx*4]
                                                            mov     edi, [currentMachine.bank_ptrs+ebx*4]
                                                            add     edi, edx
                                                            mov     eax, DRAMFADEMASK

                                                            ; fade all 128 bytes in this RAM row
                                                            mov     ecx, (128/4)/4
                                                       @@:  and     dword ptr [edi], eax
                                                            and     dword ptr [edi+4], eax
                                                            and     dword ptr [edi+8], eax
                                                            and     dword ptr [edi+12], eax
                                                            add     edi, 4*4

                                                            dec     ecx
                                                            jnz     @B
                                                    .endif

                                                    add     ebx, 1
                                            .endw

                                    .endif

                                    add     esi, 1
                                    add     edx, 128    ; advance 128 bytes to next RAS row
                            ENDLOOP

                            rol     DRAMFADEMASK, 1

                            IFDEF   DEBUGBUILD
                            .if     dram_fade_msg == TRUE
                                    ADDMESSAGE  "DRAM Fade"
                            .endif
                            ENDIF
                            ret

DRAM_Fade                   endp

Clear_Mem_Map               proc
                            memclr  addr Map_Memory, 65536
                            ret
Clear_Mem_Map               endp

.const
szMapFilter                 db  "Map files (*.map)",0,"*.map",0, 0

.data
align 16
Z80JumpTable                dd Op00,Op01,Op02,Op03,Op04,Op05,Op06,Op07
                            dd Op08,Op09,Op0A,Op0B,Op0C,Op0D,Op0E,Op0F
                            dd Op10,Op11,Op12,Op13,Op14,Op15,Op16,Op17
                            dd Op18,Op19,Op1A,Op1B,Op1C,Op1D,Op1E,Op1F
                            dd Op20,Op21,Op22,Op23,Op24,Op25,Op26,Op27
                            dd Op28,Op29,Op2A,Op2B,Op2C,Op2D,Op2E,Op2F
                            dd Op30,Op31,Op32,Op33,Op34,Op35,Op36,Op37
                            dd Op38,Op39,Op3A,Op3B,Op3C,Op3D,Op3E,Op3F
                            dd Op40,Op41,Op42,Op43,Op44,Op45,Op46,Op47
                            dd Op48,Op49,Op4A,Op4B,Op4C,Op4D,Op4E,Op4F
                            dd Op50,Op51,Op52,Op53,Op54,Op55,Op56,Op57
                            dd Op58,Op59,Op5A,Op5B,Op5C,Op5D,Op5E,Op5F
                            dd Op60,Op61,Op62,Op63,Op64,Op65,Op66,Op67
                            dd Op68,Op69,Op6A,Op6B,Op6C,Op6D,Op6E,Op6F
                            dd Op70,Op71,Op72,Op73,Op74,Op75,Op76,Op77
                            dd Op78,Op79,Op7A,Op7B,Op7C,Op7D,Op7E,Op7F
                            dd Op80,Op81,Op82,Op83,Op84,Op85,Op86,Op87
                            dd Op88,Op89,Op8A,Op8B,Op8C,Op8D,Op8E,Op8F
                            dd Op90,Op91,Op92,Op93,Op94,Op95,Op96,Op97
                            dd Op98,Op99,Op9A,Op9B,Op9C,Op9D,Op9E,Op9F
                            dd OpA0,OpA1,OpA2,OpA3,OpA4,OpA5,OpA6,OpA7
                            dd OpA8,OpA9,OpAA,OpAB,OpAC,OpAD,OpAE,OpAF
                            dd OpB0,OpB1,OpB2,OpB3,OpB4,OpB5,OpB6,OpB7
                            dd OpB8,OpB9,OpBA,OpBB,OpBC,OpBD,OpBE,OpBF
                            dd OpC0,OpC1,OpC2,OpC3,OpC4,OpC5,OpC6,OpC7
                            dd OpC8,OpC9,OpCA,OpCB,OpCC,OpCD,OpCE,OpCF
                            dd OpD0,OpD1,OpD2,OpD3,OpD4,OpD5,OpD6,OpD7
                            dd OpD8,OpD9,OpDA,OpDB,OpDC,OpDD,OpDE,OpDF
                            dd OpE0,OpE1,OpE2,OpE3,OpE4,OpE5,OpE6,OpE7
                            dd OpE8,OpE9,OpEA,OpEB,OpEC,OpED,OpEE,OpEF
                            dd OpF0,OpF1,OpF2,OpF3,OpF4,OpF5,OpF6,OpF7
                            dd OpF8,OpF9,OpFA,OpFB,OpFC,OpFD,OpFE,OpFF


Z80JumpTable_DD             dd Op00,Op01,Op02,Op03,Op04,Op05,Op06,Op07
                            dd Op08,OpDD09,Op0A,Op0B,Op0C,Op0D,Op0E,Op0F
                            dd Op10,Op11,Op12,Op13,Op14,Op15,Op16,Op17
                            dd Op18,OpDD19,Op1A,Op1B,Op1C,Op1D,Op1E,Op1F
                            dd Op20,OpDD21,OpDD22,OpDD23,OpDD24,OpDD25,OpDD26,Op27
                            dd Op28,OpDD29,OpDD2A,OpDD2B,OpDD2C,OpDD2D,OpDD2E,Op2F
                            dd Op30,Op31,Op32,Op33,OpDD34,OpDD35,OpDD36,Op37
                            dd Op38,OpDD39,Op3A,Op3B,Op3C,Op3D,Op3E,Op3F
                            dd Op40,Op41,Op42,Op43,OpDD44,OpDD45,OpDD46,Op47
                            dd Op48,Op49,Op4A,Op4B,OpDD4C,OpDD4D,OpDD4E,Op4F
                            dd Op50,Op51,Op52,Op53,OpDD54,OpDD55,OpDD56,Op57
                            dd Op58,Op59,Op5A,Op5B,OpDD5C,OpDD5D,OpDD5E,Op5F
                            dd OpDD60,OpDD61,OpDD62,OpDD63,Op64,OpDD65,OpDD66,OpDD67
                            dd OpDD68,OpDD69,OpDD6A,OpDD6B,OpDD6C,Op6D,OpDD6E,OpDD6F
                            dd OpDD70,OpDD71,OpDD72,OpDD73,OpDD74,OpDD75,Op76,OpDD77
                            dd Op78,Op79,Op7A,Op7B,OpDD7C,OpDD7D,OpDD7E,Op7F
                            dd Op80,Op81,Op82,Op83,OpDD84,OpDD85,OpDD86,Op87
                            dd Op88,Op89,Op8A,Op8B,OpDD8C,OpDD8D,OpDD8E,Op8F
                            dd Op90,Op91,Op92,Op93,OpDD94,OpDD95,OpDD96,Op97
                            dd Op98,Op99,Op9A,Op9B,OpDD9C,OpDD9D,OpDD9E,Op9F
                            dd OpA0,OpA1,OpA2,OpA3,OpDDA4,OpDDA5,OpDDA6,OpA7
                            dd OpA8,OpA9,OpAA,OpAB,OpDDAC,OpDDAD,OpDDAE,OpAF
                            dd OpB0,OpB1,OpB2,OpB3,OpDDB4,OpDDB5,OpDDB6,OpB7
                            dd OpB8,OpB9,OpBA,OpBB,OpDDBC,OpDDBD,OpDDBE,OpBF
                            dd OpC0,OpC1,OpC2,OpC3,OpC4,OpC5,OpC6,OpC7
                            dd OpC8,OpC9,OpCA,OpCB,OpCC,OpCD,OpCE,OpCF
                            dd OpD0,OpD1,OpD2,OpD3,OpD4,OpD5,OpD6,OpD7
                            dd OpD8,OpD9,OpDA,OpDB,OpDC,OpDD,OpDE,OpDF
                            dd OpE0,OpDDE1,OpE2,OpDDE3,OpE4,OpDDE5,OpE6,OpE7
                            dd OpE8,OpDDE9,OpEA,OpEB,OpEC,OpED,OpEE,OpEF
                            dd OpF0,OpF1,OpF2,OpF3,OpF4,OpF5,OpF6,OpF7
                            dd OpF8,OpDDF9,OpFA,OpFB,OpFC,OpFD,OpFE,OpFF


Z80JumpTable_FD             dd Op00,Op01,Op02,Op03,Op04,Op05,Op06,Op07
                            dd Op08,OpFD09,Op0A,Op0B,Op0C,Op0D,Op0E,Op0F
                            dd Op10,Op11,Op12,Op13,Op14,Op15,Op16,Op17
                            dd Op18,OpFD19,Op1A,Op1B,Op1C,Op1D,Op1E,Op1F
                            dd Op20,OpFD21,OpFD22,OpFD23,OpFD24,OpFD25,OpFD26,Op27
                            dd Op28,OpFD29,OpFD2A,OpFD2B,OpFD2C,OpFD2D,OpFD2E,Op2F
                            dd Op30,Op31,Op32,Op33,OpFD34,OpFD35,OpFD36,Op37
                            dd Op38,OpFD39,Op3A,Op3B,Op3C,Op3D,Op3E,Op3F
                            dd Op40,Op41,Op42,Op43,OpFD44,OpFD45,OpFD46,Op47
                            dd Op48,Op49,Op4A,Op4B,OpFD4C,OpFD4D,OpFD4E,Op4F
                            dd Op50,Op51,Op52,Op53,OpFD54,OpFD55,OpFD56,Op57
                            dd Op58,Op59,Op5A,Op5B,OpFD5C,OpFD5D,OpFD5E,Op5F
                            dd OpFD60,OpFD61,OpFD62,OpFD63,Op64,OpFD65,OpFD66,OpFD67
                            dd OpFD68,OpFD69,OpFD6A,OpFD6B,OpFD6C,Op6D,OpFD6E,OpFD6F
                            dd OpFD70,OpFD71,OpFD72,OpFD73,OpFD74,OpFD75,Op76,OpFD77
                            dd Op78,Op79,Op7A,Op7B,OpFD7C,OpFD7D,OpFD7E,Op7F
                            dd Op80,Op81,Op82,Op83,OpFD84,OpFD85,OpFD86,Op87
                            dd Op88,Op89,Op8A,Op8B,OpFD8C,OpFD8D,OpFD8E,Op8F
                            dd Op90,Op91,Op92,Op93,OpFD94,OpFD95,OpFD96,Op97
                            dd Op98,Op99,Op9A,Op9B,OpFD9C,OpFD9D,OpFD9E,Op9F
                            dd OpA0,OpA1,OpA2,OpA3,OpFDA4,OpFDA5,OpFDA6,OpA7
                            dd OpA8,OpA9,OpAA,OpAB,OpFDAC,OpFDAD,OpFDAE,OpAF
                            dd OpB0,OpB1,OpB2,OpB3,OpFDB4,OpFDB5,OpFDB6,OpB7
                            dd OpB8,OpB9,OpBA,OpBB,OpFDBC,OpFDBD,OpFDBE,OpBF
                            dd OpC0,OpC1,OpC2,OpC3,OpC4,OpC5,OpC6,OpC7
                            dd OpC8,OpC9,OpCA,OpCB,OpCC,OpCD,OpCE,OpCF
                            dd OpD0,OpD1,OpD2,OpD3,OpD4,OpD5,OpD6,OpD7
                            dd OpD8,OpD9,OpDA,OpDB,OpDC,OpDD,OpDE,OpDF
                            dd OpE0,OpFDE1,OpE2,OpFDE3,OpE4,OpFDE5,OpE6,OpE7
                            dd OpE8,OpFDE9,OpEA,OpEB,OpEC,OpED,OpEE,OpEF
                            dd OpF0,OpF1,OpF2,OpF3,OpF4,OpF5,OpF6,OpF7
                            dd OpF8,OpFDF9,OpFA,OpFB,OpFC,OpFD,OpFE,OpFF


Z80JumpTable_ED             dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet,EDRet
                            dd OpED40,OpED41,OpED42,OpED43,OpED44,OpED45,OpED46,OpED47
                            dd OpED48,OpED49,OpED4A,OpED4B,OpED4C,OpED4D,OpED4E,OpED4F
                            dd OpED50,OpED51,OpED52,OpED53,OpED54,OpED55,OpED56,OpED57
                            dd OpED58,OpED59,OpED5A,OpED5B,OpED5C,OpED5D,OpED5E,OpED5F
                            dd OpED60,OpED61,OpED62,OpED63,OpED64,OpED65,OpED66,OpED67
                            dd OpED68,OpED69,OpED6A,OpED6B,OpED6C,OpED6D,OpED6E,OpED6F
                            dd OpED70,OpED71,OpED72,OpED73,OpED74,OpED75,OpED76,OpED77
                            dd OpED78,OpED79,OpED7A,OpED7B,OpED7C,OpED7D,OpED7E,OpED7F
                            dd OpED80,OpED81,OpED82,OpED83,OpED84,OpED85,OpED86,OpED87
                            dd OpED88,OpED89,OpED8A,OpED8B,OpED8C,OpED8D,OpED8E,OpED8F
                            dd OpED90,OpED91,OpED92,OpED93,OpED94,OpED95,OpED96,OpED97
                            dd OpED98,OpED99,OpED9A,OpED9B,OpED9C,OpED9D,OpED9E,OpED9F
                            dd OpEDA0,OpEDA1,OpEDA2,OpEDA3,OpEDA4,OpEDA5,OpEDA6,OpEDA7
                            dd OpEDA8,OpEDA9,OpEDAA,OpEDAB,OpEDAC,OpEDAD,OpEDAE,OpEDAF
                            dd OpEDB0,OpEDB1,OpEDB2,OpEDB3,OpEDB4,OpEDB5,OpEDB6,OpEDB7
                            dd OpEDB8,OpEDB9,OpEDBA,OpEDBB,OpEDBC,OpEDBD,OpEDBE,OpEDBF
                            dd OpEDC0,OpEDC1,OpEDC2,OpEDC3,OpEDC4,OpEDC5,OpEDC6,OpEDC7
                            dd OpEDC8,OpEDC9,OpEDCA,OpEDCB,OpEDCC,OpEDCD,OpEDCE,OpEDCF
                            dd OpEDD0,OpEDD1,OpEDD2,OpEDD3,OpEDD4,OpEDD5,OpEDD6,OpEDD7
                            dd OpEDD8,OpEDD9,OpEDDA,OpEDDB,OpEDDC,OpEDDD,OpEDDE,OpEDDF
                            dd OpEDE0,OpEDE1,OpEDE2,OpEDE3,OpEDE4,OpEDE5,OpEDE6,OpEDE7
                            dd OpEDE8,OpEDE9,OpEDEA,OpEDEB,OpEDEC,OpEDED,OpEDEE,OpEDEF
                            dd OpEDF0,OpEDF1,OpEDF2,OpEDF3,OpEDF4,OpEDF5,OpEDF6,OpEDF7
                            dd OpEDF8,OpEDF9,OpEDFA,OpEDFB,OpEDFC,OpEDFD,OpEDFE,OpEDFF

CBFuncJumpTable             dd CB_RLC, CB_RRC, CB_RL,  CB_RR
                            dd CB_SLA, CB_SRA, CB_SLL, CB_SRL
                            dd CB_BIT0,CB_BIT1,CB_BIT2,CB_BIT3
                            dd CB_BIT4,CB_BIT5,CB_BIT6,CB_BIT7
                            dd CB_RES0,CB_RES1,CB_RES2,CB_RES3
                            dd CB_RES4,CB_RES5,CB_RES6,CB_RES7
                            dd CB_SET0,CB_SET1,CB_SET2,CB_SET3
                            dd CB_SET4,CB_SET5,CB_SET6,CB_SET7

;############################################################################################

.data?
align 16

; Complete Z80 system data starts here
; ====================================

Z80SYSTEMSTART  LABEL   BYTE

; Z80 Memory Area   ; MUST remain @ Z80SYSTEMSTART for 'Compare Snapshot Image' function!!!
; ===============

; currently in "Vars.asm"

align 16

currentMachine              TMACHINE <>

RegisterBase                equ     <currentMachine>
z80registers                equ     <currentMachine>
CM                          equ     <currentMachine>

align 16
; Fullspeed variables
; test for any TRUE value with ".if FULLSPEEDMODE != NULL"...
FULLSPEEDMODE               LABEL   DWORD   ; 4 bytes, any of which cause fullspeed emulation
MAXIMUMSPEED                BYTE    ?       ; TRUE if emulator at max speed mode
MAXIMUMDISKSPEED            BYTE    ?       ; frames counter for max disk speed loading
MAXIMUMAUTOLOADTYPE         BYTE    ?       ; TRUE when the 'phantom typist' is typing LOAD "" for tape autoloads
_max_pad_                   BYTE    ?

FramesPerSecond             DWORD   ?   ; FPS counter
GlobalFramesCounter         DWORD   ?   ; increments every frame
Timer_1s_tickcount          DWORD   ?   ; increments every WM_TIMER message (1 second intervals)
uSpeechTimer                DWORD   ?
RealTapeMode                BYTE    ?   ; using real tape input
AYTimer                     BYTE    ?
SampleTimer                 BYTE    ?
RealTapeTimer               BYTE    ?
TapePlaying                 BYTE    ?   ; TRUE if virtual tape is playing
HardReset                   BYTE    ?
DoingBitTest                BYTE    ?
RETCounter                  BYTE    ?

align 16
; Sound chip registers
AYBase                  LABEL   BYTE    ; base address of AY registers and variables
SCTone_A                LABEL   WORD
AY_ToneA                equ 0
SCRegister0             BYTE ?
SCRegister1             BYTE ?

SCTone_B                LABEL   WORD
AY_ToneB                equ 2
SCRegister2             BYTE ?
SCRegister3             BYTE ?

SCTone_C                LABEL   WORD
AY_ToneC                equ 4
SCRegister4             BYTE ?
SCRegister5             BYTE ?

AY_R6                   equ 6
SCRegister6             BYTE ?
AY_R7                   equ 7
SCRegister7             BYTE ?
AY_R8                   equ 8
SCRegister8             BYTE ?
AY_R9                   equ 9
SCRegister9             BYTE ?
AY_R10                  equ 10
SCRegister10            BYTE ?

SCEnvPeriod             LABEL   WORD
AY_EnvPeriod            equ 11
SCRegister11            BYTE ?
SCRegister12            BYTE ?
AY_R13                  equ 13
SCRegister13            BYTE ?
SCRegister14            BYTE ?
SCRegister15            BYTE ?

AY_FinalChanA           equ 16
FinalChanA              WORD ?
AY_FinalChanB           equ 18
FinalChanB              WORD ?
AY_FinalChanC           equ 20
FinalChanC              WORD ?

AY_ChACounter           equ 22
ChACounter              WORD ?
AY_ChBCounter           equ 24
ChBCounter              WORD ?
AY_ChCCounter           equ 26
ChCCounter              WORD ?
AY_EnvCounter           equ 28
EnvCounter              WORD ?

AY_NoiseOutput          equ 30
NoiseOutput             BYTE ?

AY_WhiteNoiseCounter    equ 31
WhiteNoiseCounter       BYTE ?

AY_InternalR6           equ 32
InternalR6              BYTE ?
AY_ChAOutput            equ 33
ChAOutput               BYTE ?
AY_ChBOutput            equ 34
ChBOutput               BYTE ?
AY_ChCOutput            equ 35
ChCOutput               BYTE ?
AY_EnvelopeClock        equ 36
EnvelopeClock           BYTE ?

AY_EnvMode              equ 37
EnvMode                 BYTE ?

ay_pad1                 BYTE ?  ; 38
ay_pad2                 BYTE ?  ; 39

AY_RandomSeed           equ 40
RandomSeed              DWORD ?

AY_Total_ChanA          equ 44
Total_ChanA             DWORD   ?
AY_Total_ChanB          equ 48
Total_ChanB             DWORD   ?
AY_Total_ChanC          equ 52
Total_ChanC             DWORD   ?

AY_EnvVolume            equ     56
EnvVolume               DWORD   ?

AY_SampleCounter        equ     60
SampleCounter           DWORD   ?

BeeperSubTotal          DWORD ?
BeeperSubCount          WORD ?
BeepVal                 WORD ?
EarVal                  WORD ?
BeepHold                WORD ?
MICVal                  BYTE ?
BeeperSub               BYTE ?

                        ; EnvMode equates:
                        RESETENUM
                        ENUM    env_DECAY, env_ATTACK, env_OFF, env_HOLD

SCSelectReg             BYTE ?  ; sound chip register select (last OUT to FFFD)

Last7FFDWrite           BYTE ?
Last1FFDWrite           BYTE ?
Last_FE_Write           BYTE ?

AYShadowRegisters       BYTE    16 dup (?)  ; 16 AY registers
AY_FloatingRegister     BYTE    ?           ; "floating" AY register

SaveHardwareMode        BYTE ?  ; backup of HardwareMode var stored in memory snapshot

; Complete Z80 system data ends here
; ==================================
Z80SYSTEMEND            LABEL   BYTE
Z80SYSTEMSIZE           EQU     Z80SYSTEMEND-Z80SYSTEMSTART ; size of data for mem snapshot
Z80SystemSnapshot       BYTE    Z80SYSTEMSIZE dup (?)       ; memory snapshot area

                      ; required padding
                        DWORD   8   DUP (?)

;############################################################################################


; variables not to be stored in the system snapshot
align 16
PortTotalTStates        DWORD   ?   ; updated with greatest TStates count for all accessed ports
PortDeviceType          DWORD   ?   ; identifier for last accessed device port
PortReadAddress         WORD    ?   ; last port address read
PortWriteAddress        WORD    ?   ; last port address written to
PortReadByte            BYTE    ?   ; byte read from a port
PortWriteByte           BYTE    ?   ; byte being written to a port

                        ; port access values
                        PORT_NONE   equ     0
                        PORT_READ   equ     1
                        PORT_WRITE  equ     2

Floating_Bus_Read       BYTE    ?

MemorySnapshotValid     BYTE    ?   ; TRUE = Got a valid memory snapshot
CPU_Speed               BYTE    ?
MuteSound               BYTE    ?


TPC_History             struct
_Offset                 DWORD   ?
Table                   DWORD   256 dup (?)
TPC_History             ends

align 16
PC_History              TPC_History <>

;############################################################################################

.code
Save_Memory_Map             proc

                            local   ofn:    OPENFILENAME,
                                    mapFH:  DWORD

                            local   tempfile [MAX_PATH]:    BYTE

                            mov     tempfile[0], 0
                            invoke  SaveFileName, hWnd, SADD ("Save Memory Map"), addr szMapFilter, addr ofn, addr tempfile, addr MAPExt, 0
                            .if     eax != 0
                                    invoke  RemoveExtension, addr tempfile
                                    ADDEXTENSION    addr tempfile, addr MAPExt

                                    mov     mapFH, $fnc (CreateFile, addr tempfile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
                                    .if     mapFH != INVALID_HANDLE_VALUE
                                            invoke  WriteFile,   mapFH, addr Map_Memory, 65536, addr BytesSaved, NULL
                                            invoke  CloseHandle, mapFH
                                    .else
                                            invoke  ShowMessageBox, hWnd, SADD ("Unable to write Map file"), addr szWindowName, MB_OK or MB_ICONERROR
                                    .endif
                            .endif
                            ret
Save_Memory_Map             endp


align 16
Add_PC_History:             push    esi
                            lea     esi, PC_History

                            push    eax
                            movzx   eax, PrevzPC

                            push    ecx
                            mov     ecx, [esi].TPC_History._Offset

                            .if     eax != [[esi].TPC_History.Table+ecx*4]
                                    inc     cl
                                    mov     [[esi].TPC_History.Table+ecx*4], eax
                                    mov     [esi].TPC_History._Offset, ecx
                            .endif

                            pop     ecx
                            pop     eax
                            pop     esi
                            ret

ADD_PC_HISTORY              macro
                            call    Add_PC_History
                            endm

SaveMemorySnapshot          proc    hParent:    HWND

                            .if     MemorySnapshotValid
                                    invoke  ShowMessageBox, hParent,
                                                            SADD ("Do you want to overwrite the current memory snapshot ?"),
                                                            SADD ("Confirm overwrite"),
                                                            MB_YESNO or MB_ICONQUESTION
                                    .if     eax == IDNO
                                            ret
                                    .endif
                            .endif

                            mov     al, HardwareMode
                            mov     SaveHardwareMode, al

                            memcpy  addr Z80SYSTEMSTART, addr Z80SystemSnapshot, Z80SYSTEMSIZE

                            ; copy Spectrum memory from first defined bank to the backup memory area
                            memcpy  currentMachine.bank5, addr MemSnapshot, (16384*8)

                            ; enable 'Load memory snapshot' and 'Cheats Finder' main window menu items
                            invoke  EnableMenuItem, MenuHandle, IDM_LOADMEMSNAP, MF_BYCOMMAND or MF_ENABLED
                            mov     MemorySnapshotValid, TRUE
                            ret
SaveMemorySnapshot          endp

LoadMemorySnapshot          proc    hParent:    HWND

                            .if     MemorySnapshotValid
                                    memcpy  addr Z80SystemSnapshot, addr Z80SYSTEMSTART, Z80SYSTEMSIZE

                                    mov     al, SaveHardwareMode
                                    mov     HardwareMode, al    ; restore hardware mode

                                    memcpy  addr MemSnapshot, currentMachine.bank5, (16384*8)

                                    mov     ax, zPC
                                    mov     Z80PC, ax

                                    mov     al, Last_FE_Write
                                    call    Set_BorderColour    ; restore the border colour

                                    invoke  SetSnowEffect

                                    invoke  SetMachineStatusBar
                            .endif
                            ret
LoadMemorySnapshot          endp

;############################################################################################

align 16
GetZ80MemoryAddr        proc    uses    ecx,
                                address:WORD

                        movzx   eax, address
                        mov     ecx, eax

                        shr     eax, 11
                        and     eax, 28
                        mov     eax, [currentMachine.RAMREAD0+eax]

                        and     ecx, 1FFFh
                        add     eax, ecx
                        ret

GetZ80MemoryAddr        endp

align 16
ReadZ80Byte             proc    address:WORD

                        invoke  GetZ80MemoryAddr, address
                        mov     al, [eax]
                        ret

ReadZ80Byte             endp

align 16
ReadZ80Word             proc    address:WORD

                        invoke  GetZ80MemoryAddr, address
                        mov     ax, [eax]
                        ret

ReadZ80Word             endp

align 16
WriteZ80Byte            proc    uses    ecx,
                                address:WORD,
                                data:   BYTE

                        invoke  GetZ80MemoryAddr, address
                        mov     cl, data
                        mov     [eax], cl
                        ret

WriteZ80Byte            endp

align 16
WriteZ80Word            proc    uses    ecx,
                                address:WORD,
                                data:   WORD

                        invoke  GetZ80MemoryAddr, address
                        mov     cx, data
                        mov     [eax], cx
                        ret

WriteZ80Word            endp

align 16
GetBankAddr             proc    bank:BYTE

                        movzx   eax, bank
                        and     eax, 7
                        mov     eax, [currentMachine.bank_ptrs+eax*4]
                        ret

GetBankAddr             endp

align 16
ReadBankByte            proc    uses    ecx,
                                bank:   BYTE,
                                address:WORD

                        invoke  GetBankAddr, bank

                        movzx   ecx, address
                        and     ecx, 3FFFh

                        mov     al, [eax+ecx]
                        ret

ReadBankByte            endp

align 16
ReadBankWord            proc    uses    ecx,
                                bank:   BYTE,
                                address:WORD

                        invoke  GetBankAddr, bank

                        movzx   ecx, address
                        and     ecx, 3FFFh

                        mov     ax, [eax+ecx]
                        ret

ReadBankWord            endp

align 16
WriteBankByte           proc    uses    ecx,
                                bank:   BYTE,
                                address:WORD,
                                data:   BYTE

                        invoke  GetBankAddr, bank

                        movzx   ecx, address
                        and     ecx, 3FFFh

                        add     eax, ecx

                        mov     cl, data
                        mov     [eax], cl
                        ret

WriteBankByte           endp

align 16
WriteBankWord           proc    uses    ecx,
                                bank:   BYTE,
                                address:WORD,
                                data:   WORD

                        invoke  GetBankAddr, bank

                        movzx   ecx, address
                        and     ecx, 3FFFh

                        add     eax, ecx

                        mov     cx, data
                        mov     [eax], cx
                        ret

WriteBankWord           endp
;############################################################################################

align 16
; returns RAM page paged at specified address
; returns -1 if not RAM at that address
GetBankAtAddr               proc    uses    ecx,
                                    address:WORD

                            movzx   ecx, address
                            shr     ecx, 11         ; bits 15+14 >> bits 4+3
                            and     ecx, 24         ; (0 - 3) * 8
                            mov     ecx, [currentMachine.RAMREAD0+ecx]  ; = RAMREAD0/2/4/6

                            xor     eax, eax
                    @@:     cmp     ecx, [currentMachine.bank_ptrs+eax*4]
                            je      @F
                            add     eax, 1
                            cmp     eax, 8
                            jc      @B

                            or      eax, -1

                    @@:     ret
GetBankAtAddr               endp

align 16
GetBankConfig               proc    uses ecx

                            invoke  GetBankAtAddr, 0
                            and     eax, 0Fh
                            shl     ecx, 4
                            or      ecx, eax

                            invoke  GetBankAtAddr, 16384
                            and     eax, 0Fh
                            shl     ecx, 4
                            or      ecx, eax

                            invoke  GetBankAtAddr, 32768
                            and     eax, 0Fh
                            shl     ecx, 4
                            or      ecx, eax

                            invoke  GetBankAtAddr, 49152
                            and     eax, 0Fh
                            shl     ecx, 4
                            or      ecx, eax
                            return  ecx
GetBankConfig               endp

GETRUNBYTE              macro
                        push    ebx
                        movzx   ebx, Reg_PC
                        inc     Reg_PC
                        inc     Reg_InsLength
                        GETOPCODEBYTE
                        pop     ebx
                        endm

;############################################################################################

; Force ULA contention delay for this cycle.

FORCECONTENTION         macro
                        push    edx
                        lea     edx, ContentionTable
                        add     edx, Reg_totaltstates
                        movzx   edx, byte ptr [edx]
                        add     Reg_totaltstates, edx
                        pop     edx
                        endm

; Force ULA contention delays for an address.

FORCEMULTICONTENTION    MACRO   Repetitions:REQ
                        push    edi
                        push    ecx
                        lea     edi, ContentionTable
                        mov     ecx, Reg_totaltstates

                        REPEAT  Repetitions
                                movzx   ebx, byte ptr [edi+ecx]
                                lea     ecx, [ecx+ebx+1]        ; add contention + 1 cycle
                        ENDM

                        mov     Reg_totaltstates, ecx
                        pop     ecx
                        pop     edi
                        ENDM

; Add ULA contention delay for an address.
; bx = address to apply contention to.

ADDCONTENTION           macro
                        push    ebx
                        shr     ebx, 11
                        and     ebx, 28
                        .if     [currentMachine.CONTENTION0+ebx] == TRUE
                                mov     ebx, Reg_totaltstates
                                movzx   ebx, byte ptr [ContentionTable+ebx]
                                add     Reg_totaltstates, ebx
                        .endif
                        pop     ebx
                        endm

; Add ULA contention delays for an address.
; bx = address to apply contention to.

ADDMULTICONTENTION      macro   Repetitions
                        .if     MACHINE.Plus3_Compatible
                                add     Reg_totaltstates, Repetitions
                        .else
                                push    eax
                                mov     eax, Repetitions
                                call    Add_Multi_Contention
                                pop     eax
                        .endif
                        endm

ADD_IR_CYCLES           macro   Repetitions
                        mov     bh, Reg_I
;                        mov     bl, Reg_R    ; R (and bl) don't affect IR contended cycles
                        ADDMULTICONTENTION  Repetitions
                        endm


; Add ULA contention delays for the address in PC.
; - though we actually apply contention to PC-1 as we've incremented past an indexed offset byte
; - used in (IX/Y+dd) opcodes

ADDMULTICONTENTIONPC    macro   Repetitions
                        push    ebx
                        movzx   ebx, Reg_PC
                        dec     ebx         ; apply contention to PC-1 address
                        ADDMULTICONTENTION  Repetitions
                        pop     ebx
                        endm


align 16
; *****************************************************************

                      ; turn on indirect addressing here
                        USEESI  1

; *****************************************************************

ExecZ80Opcode:          lea     esi, RegisterBase

                        ifc     DoLogging then invoke Log_PC

                        inc     Reg_opcodes_executed

                        xor     eax, eax
                        movzx   ebx, Reg_PC

                        ; z80 states cleared to zero before executing an opcode
                        mov     Reg_ClearZ80State1, eax
                        mov     Reg_ClearZ80State2, eax
                        mov     Reg_ClearZ80State3, eax
                        mov     Reg_ClearZ80State4, eax

                        mov     Reg_PrevzPC, bx

                        .if     HardwareMode == HW_PENTAGON128
                                ; TR-DOS maps in when PC = #3Dxx
                                .if     (bh == 3Dh) || (bx == 3C00h) || (bx == 3C03h)
                                        ; only page in if unpaged and ROM 1 (48K ROM) is active
                                        .if     (TrDos_Paged == FALSE) && (currentMachine.RAMREAD0 == offset Rom_Pentagon128+16384)    ; bit 4 of #7ffd = 1 ?
                                                call    TrDos_Page_In
                                        .endif
                                ; TR-DOS maps out when PC > #3FFF
                                .elseif ebx > 3FFFh
                                        .if     TrDos_Paged
                                                call    TrDos_Page_Out
                                        .endif
                                .endif
                        .endif

                        .if     (ebx <= 028Eh) && PLUSD_Enabled
                                .if     (ebx == 8) || (ebx == 3Ah) || (ebx == 66h) || (ebx == 028Eh)
                                        invoke  PLUSD_PageIn
                                .endif
                        .endif

                        .if     (ebx == 2BAEh) && MicroSourceEnabled    ; 2BAE = 11182
                                xor     MicroSourcePaged, TRUE
                                .if     !ZERO?
                                        mov     currentMachine.RAMREAD0,  offset Rom_MicroSource
                                        mov     currentMachine.RAMREAD1,  offset Rom_MicroSource
                                .else
                                        mov     currentMachine.RAMREAD0,  offset Rom_48
                                        mov     currentMachine.RAMREAD1,  offset Rom_48+8192
                                .endif
                        .endif

                        FETCH_OPCODE    offset Z80JumpTable
                        jmp     ecx     ; jump to opcode handler

; =================================================================

align 16
; eax = contended cycle repetitions
; bx = contention address
Add_Multi_Contention:;   .if     MACHINE.Plus3_Compatible   ; +2A/+3 multi-contention now applied via macro before calling here
                                push    ebx
                                shr     ebx, 11
                                and     ebx, 28
                                .if     [currentMachine.CONTENTION0+ebx] == FALSE
                                        pop     ebx
                                        add     Reg_totaltstates, eax   ; SETTS eax
                                        ret
                                .endif
                                push    ecx
                                mov     ecx, Reg_totaltstates
                                push    edi
                                lea     edi, ContentionTable

                            @@: movzx   ebx, byte ptr [edi+ecx]
                                sub     eax, 1
                                lea     ecx, [ecx+ebx+1]        ; Add contention + 1 cycle
                                jnz     @B

                                mov     Reg_totaltstates, ecx
                                pop     edi
                                pop     ecx

                                pop     ebx
                                ret
;                        .endif
;                        add     Reg_totaltstates, eax   ; SETTS eax
                        ret


;############################################################################################

align 16
; bx = addr
Is_Contended:           push    ebx
                        shr     ebx, 11
                        and     ebx, 28
                        mov     eax, [currentMachine.CONTENTION0+ebx]
                        pop     ebx
                        ret

;############################################################################################

; bx = addr

; *** NB: this routine must also preserve ecx for case of multiple DD/FD prefixes ***

align 16
M1_Fetch:
                        ; reset refresh counter entry for current value of R
                        movzx   eax, Reg_R
                        and     eax, 7Fh
                        mov     [currentMachine.refresh_counters][eax], 0

                        sub     RZXREC.rzx_io_recording.Fetch_Counter, 1
                        sub     RZXPLAY.rzx_io_recording.Fetch_Counter, 1

;                        .if     rzx_mode == RZX_RECORD
;                                sub     RZXREC.rzx_io_recording.Fetch_Counter, 1
;                        .elseif rzx_mode == RZX_PLAY
;                                sub     RZXPLAY.rzx_io_recording.Fetch_Counter, 1
;                        .endif

                        GETOPCODEBYTE
                        movzx   eax, al         ; always return with zeroed upper bits

                        ifc     SPGfx.SnowEffect eq FALSE then ret  ; exit if snow effect not currently in effect

                        mov     Reg_proc_temp_byte_1, al ; temp store opcode byte

                        add     Reg_totaltstates, 2
                        RENDERCYCLES

                        ; If an instruction fetch state T3 and T4 occur while the ULA is between fetching bytes 2 and 3, and the refresh address on the bus is between 0x4000 and 0x7FFF, then as described above, the ULA dynamic memory handler will force RAS low.
                        ; Thus it cannot rise as it normally would during the second CAS assertion, but instead remains low as the next row address is placed on the bus, and into the next CAS assertion. The upshot is that the row address of the second byte pair of the four byte fetch will not get latched into the RAM.

                        mov     SPGfx.DoSnow,  TRUE

                        add     Reg_totaltstates, 2
                        mov     Reg_refresh_cycle, 1
                        RENDERCYCLES

;                        inc     Reg_totaltstates
;                        mov     Reg_refresh_cycle, 1
;                        RENDERCYCLES
;
;                        inc     Reg_totaltstates
;                        mov     Reg_refresh_cycle, 2
;                        RENDERCYCLES

                        mov     SPGfx.DoSnow, FALSE
                        sub     Reg_totaltstates, 4
                        mov     Reg_refresh_cycle, 0

                        .if     MACHINE.CrashesOnSnow && Reg_MemoryContendedEvent
                                mov     eax, SPGfx.zxDisplayOrg
                                movzx   ebx, zPC
                                and     ebx, 3FFFh
                                movzx   eax, byte ptr [eax+ebx]
                                ret
                        .endif

                        mov     al, Reg_proc_temp_byte_1 ; restore temp opcode byte
                        ret


align 16
GetByte_NoMemMap:       movzx   ebx, bx

                        mov     Reg_MemoryReadEvent, MEMACCESSBYTE
                        mov     Reg_MemoryContendedEvent, FALSE
;                        mov     Reg_MemoryReadAddress, bx          ; see GetByte_Entry_2
                        jmp     GetByte_Entry_2

align 16
; bx = addr
; NB: this routine must also preserve ecx for case of multiple DD/FD prefixes

GetOpcodeByte:          mov     al, MEMMAPF_EXECUTE
                        jmp     @F

GetByte:                mov     Reg_MemoryReadEvent, MEMACCESSBYTE
                        mov     Reg_MemoryContendedEvent, FALSE
;                        mov     Reg_MemoryReadAddress, bx          ; see GetByte_Entry_2

                        mov     al, MEMMAPF_READ_BYTE

@@:                     movzx   ebx, bx
                        or      byte ptr [Map_Memory+ebx], al

GetByte_Entry_2:        mov     Reg_MemoryReadAddress, bx   ; needed here for RAS refresh for accessed memory (external tests should also check Reg_MemoryReadEvent for validity)

                        cmp     uSpeech_Enabled, TRUE
                        je      uSpeech_GetByte

                        cmp     CBI_Enabled, TRUE
                        je      CBI_GetByte

    std_getbyte:        push    ecx
                        mov     ecx, ebx
                        shr     ebx, 11
                        and     ecx, 1FFFh
                        and     ebx, 28                 ; (0 - 7) * 4
                        add     ecx, [currentMachine.RAMREAD0+ebx]

                        .if     [currentMachine.CONTENTION0+ebx] == FALSE
                                ; Z80 memory address to DRAM row select
                                ; (addr >> 7) and 7F
                                ; reset refresh counter entry for current z80 address
                                movzx   eax, Reg_MemoryReadAddress
                                shr     eax, 7
                                and     eax, 7Fh
                                mov     [currentMachine.refresh_counters+eax], 0
            
                                mov     bx, Reg_MemoryReadAddress
                                mov     al, [ecx]
                                mov     Reg_MemoryReadValueLo, al
                                pop     ecx
                                ret
                        .endif

                        mov     Reg_MemoryContendedEvent, TRUE

                        mov     ebx, Reg_totaltstates
                        movzx   ebx, byte ptr [ContentionTable+ebx]
                        add     Reg_totaltstates, ebx

                        ifc     MACHINE.Plus3_Compatible then RENDERCYCLES    ; +2A/+3 floating bus works with this for some reason

                        mov     bx, Reg_MemoryReadAddress
                        mov     al, [ecx]
                        mov     Reg_MemoryReadValueLo, al
                        mov     SPGfx.plus3_float_byte, al   ; for +3 floating bus

                        pop     ecx
                        ret

uSpeech_GetByte:        and     ebx, 0FFFFh

                        cmp     uSpeech_Paged, TRUE
                        jne     std_getbyte

                        .if     ebx < 0800h
                                mov     al, [uSpeechROM+ebx]
                                mov     Reg_MemoryReadValueLo, al
                                mov     bx, Reg_MemoryReadAddress
                                ret
                        .endif

                        cmp     ebx, 1000h  ; status register?
                        jne     std_getbyte

                        mov     al, uSpeechStatus
                        mov     Reg_MemoryReadValueLo, al
                        mov     bx, Reg_MemoryReadAddress
                        ret

CBI_GetByte:            cmp     ebx, 4000h
                        jnc     std_getbyte

                        ; port 255, bit 7 - Paging the EPROM. If = 0, enables and disables EPROM EPROM OF BASIC. If = 1, the opposite.
                        test    CBI_Port_255, (1 shl 7)
                        je      CBI_Fetch

                        cmp     bh, 3ch
                        jne     std_getbyte

                        ; port 252, bit 6 - If = 1 disables EPROM DOS including in the area and that this priority. If enable = 0 (only 3C00h 3cFFh the area).
                        test    CBI_Port_252, (1 shl 6)
                        jne     std_getbyte

CBI_Fetch:              mov     al, [Rom_CBI+ebx]
                        mov     Reg_MemoryReadValueLo, al
                        mov     bx, Reg_MemoryReadAddress
                        ret


align 16
; bx = addr, al=byte
PokeByte:               movzx   ebx, bx
                        or      byte ptr [Map_Memory+ebx], MEMMAPF_WRITE_BYTE

PokeByte_NoMemMap:      movzx   ebx, bx     ; need incase called directly here
                        mov     Reg_MemoryWriteEvent, MEMACCESSBYTE
                        mov     Reg_MemoryContendedEvent, FALSE
                        mov     Reg_MemoryWriteAddress, bx
                        mov     Reg_MemoryWriteValueLo, al

                        cmp     uSpeech_Enabled, TRUE
                        je      uSpeech_PokeByte

    std_pokebyte:       push    ecx
                        mov     ecx, ebx
                        shr     ebx, 11
                        and     ecx, 1FFFh                  ; ecx = offset into 8K block
                        and     ebx, 28
                        add     ecx, [currentMachine.RAMWRITE0+ebx]        ; ecx = write address in 8K block

                        .if     [currentMachine.CONTENTION0+ebx] == FALSE
                                mov     [ecx], al

                                ; Z80 memory address to DRAM row select
                                ; (addr >> 7) and 7F
                                ; reset refresh counter entry for current z80 address
                                movzx   ecx, Reg_MemoryWriteAddress
                                shr     ecx, 7
                                and     ecx, 7Fh
                                mov     [currentMachine.refresh_counters+ecx], 0

                                mov     bx, Reg_MemoryWriteAddress
                                pop     ecx
                                ret
                        .endif

                        mov     Reg_MemoryContendedEvent, TRUE
                        mov     ebx, Reg_totaltstates
                        movzx   ebx, byte ptr [ContentionTable+ebx]
                        add     Reg_totaltstates, ebx

                        .if     al != [ecx]
                                RENDERCYCLES
                        .endif

                        mov     [ecx], al
                        mov     SPGfx.plus3_float_byte, al  ; for +3 floating bus

                        mov     bx, Reg_MemoryWriteAddress
                        pop     ecx
                        ret

align 16
uSpeech_PokeByte:       cmp     ebx, 4000h
                        jnc     std_pokebyte    ; writing to RAM

                        .if     ebx == 1000h
                                invoke  uSpeech_WriteAllophone, al
                        .elseif ebx == 3000h
                                invoke  uSpeech_SetIntonation, FALSE
                        .elseif ebx == 3001h
                                invoke  uSpeech_SetIntonation, TRUE
                        .endif
                        ret

align 16
; bx = addr, al = byte
MemPokeByte:            push    esi
                        mov     TempMemoryAddress, bx
                        shr     ebx, 11
                        and     ebx, 28
                        mov     esi, [currentMachine.RAMWRITE0+ebx]
                        mov     bx, TempMemoryAddress
                        and     bx, 1FFFh
                        mov     [esi+ebx], al
                        mov     bx, TempMemoryAddress
                        pop     esi
                        ret

align 16
; bx = addr, al = byte,  dl = bank
PokeBankByte:           movzx   ebx, bx

                        .if     ebx < 49152
                                jmp     MemPokeByte
                        .endif

                        and     edx, 7      ; bank 0 - 7
                        mov     edx, [currentMachine.bank_ptrs+edx*4]
                        sub     ebx, 49152  ; zero offset into bank
                        mov     [edx+ebx], al
                        ret

;############################################################################################

align 16
MemPokeWord:            push    eax
                        call    MemPokeByte   ; bx = addr, ax = word
                        mov     al, ah
                        inc     bx
                        call    MemPokeByte
                        dec     bx
                        pop     eax
                        ret

;############################################################################################
align 16
; bx = addr, al = byte
MemGetByte:             movzx   ebx, bx

                        .if     CBI_Enabled && (bx < 4000h)
                                test    CBI_Port_255, (1 shl 7)
                                .if     ZERO?
                                        mov     al, [Rom_CBI+ebx]
                                        ret
                                .endif
                                .if     bh == 3ch
                                        test    CBI_Port_252, (1 shl 6)
                                        .if     ZERO?
                                                mov     al, [Rom_CBI+ebx]
                                                ret
                                        .endif
                                .endif
                        .endif

                        .if     uSpeech_Enabled && uSpeech_Paged
                                .if     ebx < 0800h
                                        mov     al, [uSpeechROM+ebx]
                                        ret
                                .endif
                        .endif

                        push    esi
                        mov     TempMemoryAddress, bx
                        shr     ebx, 11
                        and     ebx, 28
                        mov     esi, [currentMachine.RAMREAD0+ebx]
                        mov     bx, TempMemoryAddress
                        and     bx, 1FFFh
                        mov     al, [esi+ebx]
                        mov     bx, TempMemoryAddress
                        pop     esi
                        ret

;############################################################################################
align 16
GetStackWord:           ; bx = addr
                        movzx   ebx, bx
                        or      word ptr [Map_Memory+ebx], (MEMMAPF_STACK_READ shl 8) or MEMMAPF_STACK_READ
                        jmp     @F

GetWord:                ; bx = addr
                        movzx   ebx, bx
                        or      byte ptr [Map_Memory+ebx], MEMMAPF_READ_WORD

@@:                     mov     Reg_MemoryReadAddress, bx
                        mov     Reg_MemoryReadEvent, MEMACCESSWORD
                        jmp     @F

GetOpcodeWord:          movzx   ebx, bx
                        or      word ptr [Map_Memory+ebx], (MEMMAPF_EXECUTE shl 8) or MEMMAPF_EXECUTE

@@:                     mov     Reg_MemoryContendedEvent, FALSE

                        push    ecx

                        cmp     uSpeech_Enabled, TRUE
                        je      std_getword

                        cmp     CBI_Enabled, TRUE
                        je      std_getword

                        mov     ecx, ebx
                        and     ecx, 1FFFh
                        .if     ecx != 1FFFh    ; not crossing an 8K boundary
                                shr     ebx, 11
                                and     ebx, 28
                                add     ecx, [currentMachine.RAMREAD0+ebx]

                                .if     [currentMachine.CONTENTION0+ebx] == FALSE
                                        ; Z80 memory address to DRAM row select
                                        ; (addr >> 7) and 7F
                                        ; reset refresh counter entry for current z80 address
                                        movzx   eax, Reg_MemoryReadAddress
                                        shr     eax, 7
                                        and     eax, 7Fh
                                        mov     [currentMachine.refresh_counters+eax], 0

                                        add     Reg_totaltstates, 6

                                        mov     bx, Reg_MemoryReadAddress
                                        mov     ax, [ecx]
                                        mov     Reg_MemoryReadValue, ax

                                        pop     ecx
                                        inc     bx  ; bx points to HB on exit
                                        ret
                                .endif

                                mov     Reg_MemoryContendedEvent, TRUE

                                mov     eax, Reg_totaltstates
                                movzx   ebx, byte ptr [ContentionTable+eax]
                                lea     eax, [eax+ebx+3]
                                movzx   ebx, byte ptr [ContentionTable+eax]
                                lea     eax, [eax+ebx+3]
                                mov     Reg_totaltstates, eax

                                mov     bx, Reg_MemoryReadAddress
                                mov     ax, [ecx]
                                mov     Reg_MemoryReadValue, ax
                                mov     SPGfx.plus3_float_byte, ah  ; for +3 floating bus
                                pop     ecx
                                inc     bx  ; bx points to HB on exit
                                ret

                        .else
                            std_getword:
                                call    GetByte_NoMemMap
                                inc     bx
                                add     Reg_totaltstates, 3
                                mov     cl, al
                                call    GetByte_NoMemMap
                                add     Reg_totaltstates, 3
                                mov     ah, al
                                mov     al, cl
                                dec     Reg_MemoryReadAddress    ; point to LB
                                mov     Reg_MemoryReadEvent, MEMACCESSWORD
                                mov     Reg_MemoryReadValue, ax
                        .endif

                        mov     bx, Reg_MemoryReadAddress
                        pop     ecx
                        inc     bx  ; bx points to HB on exit
                        ret

;############################################################################################

align 16
PokeWord:   ; bx = addr, ax = word
                        movzx   ebx, bx
                        or      byte ptr [Map_Memory+ebx], MEMMAPF_WRITE_WORD

                        mov     Reg_MemoryWriteAddress, bx
                        mov     Reg_MemoryWriteEvent, MEMACCESSWORD
                        mov     Reg_MemoryContendedEvent, FALSE
                        mov     Reg_MemoryWriteValue, ax

                        push    ecx
                        mov     ecx, ebx
                        and     ecx, 1FFFh
                        .if     ecx != 1FFFh    ; not crossing an 8K boundary
                                shr     ebx, 11
                                and     ebx, 28
                                add     ecx, [currentMachine.RAMWRITE0+ebx]

                                .if     [currentMachine.CONTENTION0+ebx] == FALSE
                                        mov     [ecx], ax

                                        ; Z80 memory address to DRAM row select
                                        ; (addr >> 7) and 7F
                                        ; reset refresh counter entry for current z80 address
                                        movzx   ecx, Reg_MemoryReadAddress
                                        shr     ecx, 7
                                        and     ecx, 7Fh
                                        mov     [currentMachine.refresh_counters+ecx], 0

                                        add     Reg_totaltstates, 6

                                        mov     bx, Reg_MemoryWriteAddress
                                        pop     ecx
                                        inc     bx  ; bx points to HB on exit
                                        ret
                                .endif

                                mov     Reg_MemoryContendedEvent, TRUE
                                push    edx
                                mov     edx, Reg_totaltstates
                                movzx   ebx, byte ptr [ContentionTable+edx]
                                add     edx, ebx

                                .if     al != [ecx]
                                        mov     Reg_totaltstates, edx
                                        RENDERCYCLES
                                .endif
                                add     edx, 3
                                mov     [ecx], al
                                inc     ecx

                                movzx   ebx, byte ptr [ContentionTable+edx]
                                add     edx, ebx

                                .if     ah != [ecx]
                                        mov     Reg_totaltstates, edx
                                        RENDERCYCLES
                                .endif
                                add     edx, 3
                                mov     Reg_totaltstates, edx
                                mov     [ecx], ah
                                mov     SPGfx.plus3_float_byte, ah  ; for +3 floating bus

                                mov     bx, Reg_MemoryWriteAddress
                                pop     edx
                                pop     ecx
                                inc     bx  ; bx points to HB on exit
                                ret

                        .else
                                call    PokeByte_NoMemMap
                                inc     bx
                                add     Reg_totaltstates, 3
                                mov     al, ah
                                call    PokeByte_NoMemMap
                                add     Reg_totaltstates, 3
                                dec     Reg_MemoryWriteAddress    ; point to LB
                                mov     Reg_MemoryWriteEvent, MEMACCESSWORD
                                mov     Reg_MemoryWriteValue, ax
                        .endif

                        mov     bx, Reg_MemoryWriteAddress
                        pop     ecx
                        inc     bx  ; bx points to HB on exit
                        ret

;############################################################################################

; bx = addr
MemGetWord:             push    cx
                        call    MemGetByte  ; get lowbyte
                        mov     cl, al
                        inc     bx
                        call    MemGetByte  ; get highbyte
                        mov     ah, al
                        mov     al, cl      ; ax = word
                        dec     bx
                        pop     cx
                        ret

;############################################################################################

; start of opcode handlers

; NOP
align 4
Op00:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD BC,nn
align 16
Op01:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_BC, ax
            ret

;####################
; LD (BC),A
align 16
Op02:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_BC
            mov     al, Reg_A
            POKEBYTE
            inc     bl
            mov     bh, al
            SETTS   3
            mov     Reg_MemPtr, bx
            ret

;####################
; INC BC
align 16
Op03:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc     Reg_BC
            ret

;####################

; INC B
align 16
Op04:
            INCBYTE Reg_B
            mov     Reg_B, al
            ret

;####################
; DEC B
align 16
Op05:
            DECBYTE Reg_B
            mov     Reg_B, al
            ret

;####################
; LD B,n
align 16
Op06:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_B, al
            SETTS   3
            ret

;####################
; RLCA
align 16
Op07:
            FLAGS_MODIFIED  TRUE
            mov     bl, Reg_F
            mov     al, Reg_A
            and     bl, NOT @FLAGS (5H3NC)
            rol     al, 1
            adc     bl, 0       ; C to flags
            mov     Reg_A, al
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; EX AF,AF'
align 16
Op08:
            FLAGS_MODIFIED  FALSE       ; ???
            mov     ax, Reg_AF
            mov     bx, Reg_AF_alt
            mov     Reg_AF_alt, ax
            mov     Reg_AF, bx
            ret

;####################
; ADD HL,BC
align 16
Op09:
            ADD_IR_CYCLES   7
            ADDHL   Reg_BC
            ret

; ADD IX,BC
align 16
OpDD09:
            ADD_IR_CYCLES   7
            ADDIX   Reg_BC
            ret

; ADD IY,BC
align 16
OpFD09:
            ADD_IR_CYCLES   7
            ADDIY   Reg_BC
            ret

;####################
; LD A,(BC)
align 16
Op0A:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_BC
            GETBYTE
            inc     bx
            mov     Reg_A, al
            mov     Reg_MemPtr, bx
            SETTS   3
            ret

;####################
; DEC BC
align 16
Op0B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_BC

            movzx   ebx, Reg_PC
            ifc     ebx ne 2145h then ret

            ifc     rzx_mode ne RZX_NONE then ret

          ; turn off indirect addressing here
            USEESI  0

            .if     (HardwareMode == HW_PLUS3) && Plus3FastDiskLoading  ; trap +3DOS delays
                    GETZ80ADDRESS
                    .if     dword ptr [esi] == 0FB20B178h
                            mov     z80registers.bc.w, 0
                            mov     z80registers.af.hi, 0
                            mov     z80registers.af.lo, @FLAGS (ZV)
                            mov     zPC, 2149h
                    .endif

                    lea     esi, RegisterBase
            .endif
            ret

          ; turn on indirect addressing here
            USEESI  1

;####################
; INC C
align 16
Op0C:
            INCBYTE Reg_C
            mov     Reg_C, al
            ret

;####################
; DEC C
align 16
Op0D:
            DECBYTE Reg_C
            mov     Reg_C, al
            ret

;####################
; LD C,n
align 16
Op0E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_C, al
            SETTS   3
            ret

;####################
; RRCA
align 16
Op0F:
            FLAGS_MODIFIED  TRUE
            mov     bl, Reg_F
            and     bl, NOT @FLAGS (5H3NC)
            mov     al, Reg_A
            ror     al, 1
            adc     bl, 0    ; C to flags
            mov     Reg_A, al
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; DJNZ d
align 16
Op10:
            FLAGS_MODIFIED  FALSE   ; ???
            ADD_IR_CYCLES   1

            GETRUNBYTE  ; al = offset
            SETTS   3

            dec     Reg_B
            jz      @F

            cmp     al, 254
            sete    Reg_IsRepeating  ; for single-step, if B!=0 and offset=254, then repeat

            ADD_PC_HISTORY

            mov     bx, Reg_PC
            mov     cx, bx
            ADDOFFSET                               ; sets MEMPTR to target address when jump is taken
            mov     Reg_PC, bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5

@@:         ret         ; =8T for no jump

;####################
; LD DE,nn
align 16
Op11:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_DE, ax
            ret

;####################
; LD (DE),A
align 16
Op12:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_DE
            mov     al, Reg_A
            POKEBYTE
            inc     bl
            mov     bh, al
            SETTS   3
            mov     Reg_MemPtr, bx
            ret

;####################
; INC DE
align 16
Op13:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc   Reg_DE
            ret

;####################
; INC D
align 16
Op14:
            INCBYTE Reg_D
            mov     Reg_D,al
            ret

;####################
; DEC D
align 16
Op15:
            DECBYTE Reg_D
            mov     Reg_D,al
            ret

;####################
; LD D,n
align 16
Op16:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_D,al
            SETTS   3
            ret

;####################
; RLA
align 16
Op17:
            FLAGS_MODIFIED  TRUE
            mov     bl, Reg_F
            mov     cl, bl
            and     bl, NOT @FLAGS (5H3NC)
            mov     al, Reg_A
            ror     cl, 1
            rcl     al, 1
            adc     bl, 0       ; C to flags
            mov     Reg_A, al
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; JR d
align 16
Op18:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY

            GETRUNBYTE ; al = offset
            SETTS   3
            mov     bx, Reg_PC
            mov     cx, bx
            ADDOFFSET
            mov     Reg_PC, bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5
            ret

;####################
; ADD HL,DE
align 16
Op19:
            ADD_IR_CYCLES   7
            ADDHL   Reg_DE
            ret

; ADD IX,DE
align 16
OpDD19:
            ADD_IR_CYCLES   7
            ADDIX   Reg_DE
            ret

; ADD IY,DE
align 16
OpFD19:
            ADD_IR_CYCLES   7
            ADDIY   Reg_DE
            ret

;####################
; LD A,(DE)
align 16
Op1A:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_DE
            GETBYTE
            inc     bx
            mov     Reg_A, al
            mov     Reg_MemPtr, bx
            SETTS   3
            ret

;####################
; DEC DE
align 16
Op1B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_DE
            ret

;####################
; INC E
align 16
Op1C:
            INCBYTE Reg_E
            mov     Reg_E,al
            ret

;####################
; DEC E
align 16
Op1D:
            DECBYTE Reg_E
            mov     Reg_E,al
            ret

;####################
; LD E,n
align 16
Op1E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_E,al
            SETTS   3
            ret

;####################
; RRA
align 16
Op1F:
            FLAGS_MODIFIED  TRUE
            mov     bl, Reg_F
            mov     cl, bl
            and     bl, NOT @FLAGS (5H3NC)
            mov     al, Reg_A
            ror     cl, 1
            rcr     al, 1
            adc     bl, 0    ; C to flags
            mov     Reg_A, al
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; JR NZ,d
align 16
Op20:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            SETTS   3

            test    Reg_F, FLAG_Z
            jnz     @F

            ADD_PC_HISTORY

            mov     bx, Reg_PC
            mov     cx, bx
            ADDOFFSET
            mov     Reg_PC, bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5

@@:         ret

;####################
; LD HL,nn
align 16
Op21:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_HL, ax
            ret

; LD IX,nn
align 16
OpDD21:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_IX, ax

            ; opcode trap for LD IX,16384 (can find loading routines when loading screen$)
            .if     ax == 16384
                    mov     Reg_OpcodeWord, 0DD21h
            .endif
            ret

; LD IY,nn
align 16
OpFD21:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_IY, ax
            ret

;####################
; LD (nn),HL
align 16
Op22:
OpED63:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     ecx, [ebx+1]
            mov     ax, Reg_HL
            POKEWORD
            mov     Reg_MemPtr, cx
            ret

; LD (nn),IX
align 16
OpDD22:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     ecx, [ebx+1]
            mov     ax, Reg_IX
            POKEWORD
            mov     Reg_MemPtr, cx
            ret

; LD (nn),IY
align 16
OpFD22:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     ecx, [ebx+1]
            mov     ax, Reg_IY
            POKEWORD
            mov     Reg_MemPtr, cx
            ret

;####################
; INC HL
align 16
Op23:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc     Reg_HL
            ret

; INC IX
align 16
OpDD23:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc     Reg_IX
            ret

; INC IY
align 16
OpFD23:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc     Reg_IY
            ret

;####################
; INC H
align 16
Op24:
            INCBYTE Reg_H
            mov     Reg_H,al
            ret

; INC IXH
align 16
OpDD24:
            INCBYTE Reg_IXH
            mov     Reg_IXH,al
            ret

; INC IYH
align 16
OpFD24:
            INCBYTE Reg_IYH
            mov     Reg_IYH,al
            ret

;####################
; DEC H
align 16
Op25:
            DECBYTE Reg_H
            mov     Reg_H,al
            ret

; DEC IXH
align 16
OpDD25:
            DECBYTE Reg_IXH
            mov     Reg_IXH,al
            ret

; DEC IYH
align 16
OpFD25:
            DECBYTE Reg_IYH
            mov     Reg_IYH,al
            ret

;####################
; LD H,n
align 16
Op26:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_H,al
            SETTS   3
            ret

; LD IXH,n
align 16
OpDD26:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_IXH,al
            SETTS   3
            ret

; LD IYH,n
align 16
OpFD26:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_IYH,al
            SETTS   3
            ret

;####################

; DAA
align 16
Op27:
            FLAGS_MODIFIED  TRUE
            mov     al, Reg_A
            mov     ah, Reg_F

            mov     cl, ah
            and     cl, FLAG_N

            xor     dl, dl                  ; dl = correction factor

            test    ah, FLAG_C
            .if     !ZERO? || (al > 99h)
                    mov     dl, 60h         ; upper correction factor register
                    or      cl, FLAG_C
            .endif

            and     al, 15
            test    ah, FLAG_H
            .if     !ZERO? || (al > 9)
                    or      dl, 6           ; lower correction factor register
            .endif

            mov     al, Reg_A

            test    ah, FLAG_N
            .if     ZERO?
                    add     al, dl
            .else
                    sub     al, dl
            .endif

            mov     Reg_A, al

            lahf

            and     al, 00101000b
            and     ah, 11010100b
            or      ah, al
            or      ah, cl
            mov     Reg_F, ah         ; apply new flags
            ret

;####################
; JR Z,
align 16
Op28:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            SETTS   3

            test    Reg_F, FLAG_Z
            jz      @F

            ADD_PC_HISTORY

            mov     bx, Reg_PC
            mov     cx, bx
            ADDOFFSET
            mov     Reg_PC, bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5
@@:         ret

;####################
; ADD HL,HL
align 16
Op29:
            ADD_IR_CYCLES   7
            ADDHL   Reg_HL
            ret

; ADD IX,IX
align 16
OpDD29:
            ADD_IR_CYCLES   7
            ADDIX   Reg_IX
            ret

; ADD IY,IY
align 16
OpFD29:
            ADD_IR_CYCLES   7
            ADDIY   Reg_IY
            ret

;####################
; LD HL,(nn)
align 16
Op2A:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     edx, [eax+1]
            GETWORD
            mov     Reg_MemPtr, dx
            mov     Reg_HL, ax
            ret

; LD IX,(nn)
align 16
OpDD2A:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     edx, [eax+1]
            GETWORD
            mov     Reg_MemPtr, dx
            mov     Reg_IX, ax
            ret

; LD IY,(nn)
align 16
OpFD2A:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            lea     edx, [eax+1]
            GETWORD
            mov     Reg_MemPtr, dx
            mov     Reg_IY, ax
            ret

;####################
; DEC HL
align 16
Op2B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_HL
            ret

; DEC IX
align 16
OpDD2B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_IX

            ifc     rzx_mode ne RZX_NONE then ret

            movzx   ebx, Reg_PC
            ifc     ebx ne 04D4h then ret

          ; turn off indirect addressing here
            USEESI  0

            GETZ80ADDRESS
            .if     dword ptr [esi] == 47023EF3h    ; DI; LD A,2; LD B,A
                    call    ROMSaveTapeTrap         ; ROM tape save trap
            .endif

            lea     esi, RegisterBase
            ret

          ; turn on indirect addressing here
            USEESI  1

; DEC IY
align 16
OpFD2B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_IY
            ret

;####################
; INC L
align 16
Op2C:
            INCBYTE Reg_L
            mov     Reg_L,al
            ret

; INC IXL
align 16
OpDD2C:
            INCBYTE Reg_IXL
            mov     Reg_IXL,al
            ret

; INC IYL
align 16
OpFD2C:
            INCBYTE Reg_IYL
            mov     Reg_IYL,al
            ret

;####################
; DEC L
align 16
Op2D:
            DECBYTE Reg_L
            mov     Reg_L,al
            ret

; DEC IXL
align 16
OpDD2D:
            DECBYTE Reg_IXL
            mov     Reg_IXL,al
            ret

; DEC IYL
align 16
OpFD2D:
            DECBYTE Reg_IYL
            mov     Reg_IYL,al
            ret

;####################
; LD L,n
align 16
Op2E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_L, al
            SETTS   3

            ifc     rzx_mode ne RZX_NONE then ret

            movzx   ebx, Reg_PC
            ifc     ebx ne 201Eh then ret

          ; turn off indirect addressing here
            USEESI  0

            .if     (HardwareMode == HW_PLUS3) && Plus3FastDiskLoading  ; trap +3DOS delays
                    dec     ebx     ; ebx = $201D
                    GETZ80ADDRESS
                    cmp     dword ptr [esi], 0FD202DDCh
                    jne     @F
                    cmp     dword ptr [esi+4], 0C9F8203Dh
                    jne     @F

                    mov     z80registers.hl.l,0
                    mov     z80registers.af.hi,0
                    mov     z80registers.af.lo,@FLAGS (ZN)
                    mov     zPC, 2024h
            .endif

@@:         lea     esi, RegisterBase
            ret

          ; turn on indirect addressing here
            USEESI  1

; LD IXL,n
align 16
OpDD2E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_IXL,al
            SETTS   3
            ret

; LD IYL,n
align 16
OpFD2E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_IYL,al
            SETTS   3
            ret

;####################
; CPL
align 16
Op2F:
            FLAGS_MODIFIED  TRUE
            xor      Reg_A, 255
            Setf5_3  Reg_A
            or       Reg_F, @FLAGS (NH)
            ret

;####################
; JR NC,d
align 16
Op30:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            SETTS   3

            test    Reg_F, FLAG_C
            jnz     @F

            ADD_PC_HISTORY

            mov     bx, Reg_PC
            mov     cx, bx
            ADDOFFSET
            mov     Reg_PC, bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5
@@:         ret

;####################
; LD SP,nn
align 16
Op31:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_SP, ax
            ret

;####################
; LD (nn),a
align 16
Op32:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     al, Reg_A
            POKEBYTE
            inc     bl
            mov     bh, al
            SETTS   3
            mov     Reg_MemPtr, bx
            ret

;####################
; INC SP
align 16
Op33:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            inc     Reg_SP
            ret

;####################
; INC (HL)
align 16
Op34:
            mov     bx, Reg_HL
            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1
            INCBYTE al
            POKEBYTE
            SETTS   3
            ret

; pc:4,pc+1:4,pc+2:3,pc+2:1 x 5,ii+n:3,ii+n:1,ii+n(write):3

; INC (IX+n)
align 16
OpDD34:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1

            INCBYTE al
            POKEBYTE
            SETTS   3
            ret

; INC (IY+n)
align 16
OpFD34:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1

            INCBYTE al
            POKEBYTE
            SETTS   3
            ret

;####################
; DEC (HL)
align 16
Op35:
            mov     bx, Reg_HL
            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1
            DECBYTE al
            POKEBYTE
            SETTS   3
            ret

; pc:4,pc+1:4,pc+2:3,pc+2:1 x 5,ii+n:3,ii+n:1,ii+n(write):3

; DEC (IX+n)
align 16
OpDD35:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1

            DECBYTE al
            POKEBYTE
            SETTS   3
            ret

; DEC (IY+n)
align 16
OpFD35:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1

            DECBYTE al
            POKEBYTE
            SETTS   3
            ret

;####################
; LD (HL),n
align 16
Op36:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETRUNBYTE
            SETTS   3
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),n
; (pc:4,pc+1:4),pc+2:3,pc+3:3,pc+3:1,pc+3:1,(ix+nn):3
align 16
OpDD36:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3

            GETINDEXEDOPCODE

            POKEBYTE
            SETTS   3
            ret

; LD (IY+n),n
; (pc:4,pc+1:4),pc+2:3,pc+3:3,pc+3:1,pc+3:1,(iy+nn):3
align 16
OpFD36:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3

            GETINDEXEDOPCODE

            POKEBYTE
            SETTS   3
            ret

;####################
; SCF
align 16
Op37:
            mov     al, Reg_F
            mov     bl, Reg_A

            ; The content of A is copied to flags 5+3 after SCF/CCF if the previous operation did set the flags, whereas it is ORed in there if it didn't set the flags
            .if     Reg_Q == TRUE
                    ; COPY from A to F
                    and     al, NOT @FLAGS (5H3N)   ; for COPY
            .else
                    ; OR from A to F
                    and     al, NOT @FLAGS (HN)     ; for OR
            .endif

            and     bl, @FLAGS (53)
            or      al, FLAG_C
            or      al, bl
            mov     Reg_F, al

            FLAGS_MODIFIED  TRUE
            ret

;####################
; JR C,d
align 16
Op38:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            SETTS   3

            test    Reg_F, FLAG_C
            jz      @F

            ADD_PC_HISTORY

            mov     bx,Reg_PC
            mov     cx,bx
            ADDOFFSET
            mov     Reg_PC,bx

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5
@@:         ret

;####################
; ADD HL,SP
align 16
Op39:
            ADD_IR_CYCLES   7
            ADDHL   Reg_SP
            ret

; ADD IX,SP
align 16
OpDD39:
            ADD_IR_CYCLES   7
            ADDIX   Reg_SP
            ret

; ADD IY,SP
align 16
OpFD39:
            ADD_IR_CYCLES   7
            ADDIY   Reg_SP
            ret

;####################
; LD A,(nn)
align 16
Op3A:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            GETBYTE
            inc     bx
            mov     Reg_A, al
            SETTS   3
            mov     Reg_MemPtr, bx
            ret

;####################
; DEC SP
align 16
Op3B:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            dec     Reg_SP
            ret

;####################
; INC A
align 16
Op3C:
            INCBYTE Reg_A
            mov     Reg_A, al
            ret

;####################
; DEC A
align 16
Op3D:
            DECBYTE Reg_A
            mov     Reg_A, al

            ifc     TapePlaying eq FALSE then ret

            ifc     rzx_mode ne RZX_NONE then ret

            .if     FastTapeLoading && (TZXPause == 0)
                    push    esi
                    call    TrapTurboLoadDECs
                    pop     esi
            .endif
            ret

align 16
          ; turn off indirect addressing here
            USEESI  0

TrapTurboLoadDECs:
            movzx   ebx, zPC
            GETZ80ADDRESS
            cmp     word ptr [esi], 0FD20h
            je      @F
            ret

@@:         .if     z80registers.af.hi != 0
                    movzx   ax, z80registers.af.hi
                    dec     ax
                    shl     ax, 4               ; * 16 (cycles for DEC A + JR NZ)
                    add     ax, 4+7+12          ; 4 for last DEC A; 7 for last false JR NZ; 12 for first JR NZ
                    add     [TapeTStates], ax   ; advance the tape beyond this loop
;                   call    PlayTape
                    add     zPC, 2              ; skip JR NZ
                    mov     z80registers.af.hi, 0
                    or      z80registers.af.lo, FLAG_Z
            .endif
            ret

          ; turn on indirect addressing here
            USEESI  1

;####################
; LD A,n
align 16
Op3E:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; CCF
align 16
Op3F:
            mov     al, Reg_F
            mov     bl, al
            and     bl, NOT @FLAGS (HN)
            test    al, FLAG_C
            jz      @F
            or      bl, FLAG_H     ; H = old C
@@:         xor     bl, FLAG_C
            mov     Reg_F, bl

            ; The content of A is copied to flags 5+3 after SCF/CCF if the previous operation did set the flags, whereas it is ORed in there if it didn't set the flags
            mov     bl, Reg_A
            and     bl, @FLAGS (53)                         ; F5/3 from A

            .if     Reg_Q == TRUE
                    and     Reg_F, NOT @FLAGS (53)   ; clear F5/3 in F for COPY
            .endif

            or      Reg_F, bl

            FLAGS_MODIFIED  TRUE
            ret

;####################
; LD B,B
Op40:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD B,C
align 16
Op41:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_B, al
            ret

;####################
; LD B,D
align 16
Op42:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_B, al
            ret

;####################
; LD B,E
align 16
Op43:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_B, al
            ret

;####################
; LD B,H
align 16
Op44:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_B, al
            ret

; LD B,IXH
align 16
OpDD44:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_B, al
            ret

; LD B,IYH
align 16
OpFD44:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_B, al
            ret

;####################
; LD B,L
align 16
Op45:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_B, al
            ret

; LD B,IXL
align 16
OpDD45:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_B, al
            ret

; LD B,IYL
align 16
OpFD45:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_B, al
            ret

;####################
; LD B,(HL)
align 16
Op46:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_B, al
            SETTS 3
            ret

; LD B,(IX+n)
align 16
OpDD46:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_B, al
            SETTS   3
            ret

; LD B,(IY+n)
align 16
OpFD46:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_B, al
            SETTS   3
            ret

;####################
; LD B,A
align 16
Op47:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_B, al
            ret

;####################
; LD C,B
align 16
Op48:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_C, al
            ret

;####################
; LD C,C
Op49:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD C,D
align 16
Op4A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_C, al
            ret

;####################
; LD C,E
align 16
Op4B:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_C, al
            ret

;####################
; LD C,H
align 16
Op4C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_C, al
            ret

; LD C,IXH
align 16
OpDD4C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_C, al
            ret

; LD C,IYH
align 16
OpFD4C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_C, al
            ret

;####################
; LD C,L
align 16
Op4D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_C, al
            ret

; LD C,IXL
align 16
OpDD4D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_C, al
            ret

; LD C,IYL
align 16
OpFD4D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_C, al
            ret

;####################
; LD C,(HL)
align 16
Op4E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_C, al
            SETTS   3
            ret

; LD C,(IX+n)
align 16
OpDD4E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_C, al
            SETTS   3
            ret

; LD C,(IY+n)
align 16
OpFD4E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_C, al
            SETTS   3
            ret

;####################
; LD C,A
align 16
Op4F:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_C, al
            ret

;####################
; LD D,B
align 16
Op50:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_D, al
            ret

;####################
; LD D,C
align 16
Op51:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_D, al
            ret

;####################
; LD D,D
Op52:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD D,E
align 16
Op53:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_D, al
            ret

;####################
; LD D,H
align 16
Op54:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_D, al
            ret

; LD D,IXH
align 16
OpDD54:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_D, al
            ret

; LD D,IYH
align 16
OpFD54:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_D, al
            ret

;####################
; LD D,L
align 16
Op55:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_D, al
            ret

; LD D,IXL
align 16
OpDD55:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_D, al
            ret

; LD D,IYL
align 16
OpFD55:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_D, al
            ret

;####################
; LD D,(HL)
align 16
Op56:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_D, al
            SETTS 3
            ret

; LD D,(IX+n)
align 16
OpDD56:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_D, al
            SETTS   3
            ret

; LD D,(IY+n)
align 16
OpFD56:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_D, al
            SETTS   3
            ret

;####################
; LD D,A
align 16
Op57:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_D, al
            ret

;####################
; LD E,B
align 16
Op58:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_E, al
            ret

;####################
; LD E,C
align 16
Op59:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_E, al
            ret

;####################
; LD E,D
align 16
Op5A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_E, al
            ret

;####################
; LD E,E
Op5B:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD E,H
align 16
Op5C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_E, al
            ret

; LD E,IXH
align 16
OpDD5C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_E, al
            ret

; LD E,IYH
align 16
OpFD5C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_E, al
            ret

;####################
; LD E,L
align 16
Op5D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_E, al
            ret

; LD E,IXL
align 16
OpDD5D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_E, al
            ret

; LD E,IYL
align 16
OpFD5D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_E, al
            ret

;####################
; LD E,(HL)
align 16
Op5E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_E, al
            SETTS 3
            ret

; LD E,(IX+n)
align 16
OpDD5E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_E, al
            SETTS   3
            ret

; LD E,(IY+n)
align 16
OpFD5E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_E, al
            SETTS 3
            ret

;####################
; LD E,A
align 16
Op5F:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_E, al
            ret

;####################
; LD H,B
align 16
Op60:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_H, al
            ret

; LD IXH,B
align 16
OpDD60:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_IXH, al
            ret

; LD IYH,B
align 16
OpFD60:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_IYH, al
            ret

;####################
; LD H,C
align 16
Op61:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_H, al
            ret

; LD IXH,C
align 16
OpDD61:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_IXH, al
            ret

; LD IYH,C
align 16
OpFD61:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_IYH, al
            ret

;####################
; LD H,D
align 16
Op62:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_H, al
            ret

; LD IXH,D
align 16
OpDD62:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_IXH, al
            ret

; LD IYH,D
align 16
OpFD62:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_IYH, al
            ret

;####################
; LD H,E
align 16
Op63:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_H, al
            ret

; LD IXH,E
align 16
OpDD63:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_IXH, al
            ret

; LD IYH,E
align 16
OpFD63:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_IYH, al
            ret

;####################
; LD H,H
Op64:
            FLAGS_MODIFIED  FALSE

            IFDEF   PACMAN
                    .if     pacmode != PACMODE_NONE
                            invoke  Handle_Pac_Patches
                    .endif
            ENDIF
            ret

;####################
; LD H,L
align 16
Op65:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_H, al
            ret

; LD IXH,IXL
align 16
OpDD65:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_IXH, al
            ret

; LD IYH,IYL
align 16
OpFD65:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_IYH, al
            ret

;####################
; LD H,(HL)
align 16
Op66:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_H, al
            SETTS 3
            ret

; LD H,(IX+n)
align 16
OpDD66:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_H, al
            SETTS 3
            ret

; LD H,(IY+n)
align 16
OpFD66:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_H, al
            SETTS 3
            ret

;####################
; LD H,A
align 16
Op67:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_H, al
            ret

; LD IXH,A
align 16
OpDD67:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_IXH, al
            ret

; LD IYH,A
align 16
OpFD67:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_IYH, al
            ret

;####################
; LD L,B
align 16
Op68:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_L, al
            ret

; LD IXL,B
align 16
OpDD68:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_IXL, al
            ret

; LD IYL,B
align 16
OpFD68:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_IYL, al
            ret

;####################
; LD L,C
align 16
Op69:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_L, al
            ret

; LD IXL,C
align 16
OpDD69:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_IXL, al
            ret

; LD IYL,C
align 16
OpFD69:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_IYL, al
            ret

;####################
; LD L,D
align 16
Op6A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_L, al
            ret

; LD IXL,D
align 16
OpDD6A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_IXL, al
            ret

; LD IYL,D
align 16
OpFD6A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_IYL, al
            ret

;####################
; LD L,E
align 16
Op6B:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_L, al
            ret

; LD IXL,E
align 16
OpDD6B:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_IXL, al
            ret

; LD IYL,E
align 16
OpFD6B:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_IYL, al
            ret

;####################
; LD L,H
align 16
Op6C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_L, al
            ret

; LD IXL,IXH
align 16
OpDD6C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_IXL, al
            ret

; LD IYL,IYH
align 16
OpFD6C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_IYL, al
            ret

;####################
; LD L,L
Op6D:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LD L,(HL)
align 16
Op6E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_L, al
            SETTS 3
            ret

; LD L,(IX+n)
align 16
OpDD6E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_L, al
            SETTS 3
            ret

; LD L,(IY+n)
align 16
OpFD6E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_L, al
            SETTS 3
            ret

;####################
; LD L,A
align 16
Op6F:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_L, al
            ret

; LD IXL,A
align 16
OpDD6F:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_IXL, al
            ret

; LD IYL,A
align 16
OpFD6F:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_A
            mov     Reg_IYL, al
            ret

;####################
; LD (HL),B
align 16
Op70:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_B
            POKEBYTE
            SETTS 3
            ret

; LD (IX+n),B
align 16
OpDD70:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_B
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),B
align 16
OpFD70:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_B
            POKEBYTE
            SETTS 3
            ret

;####################
; LD (HL),C
align 16
Op71:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_C
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),C
align 16
OpDD71:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_C
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),C
align 16
OpFD71:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_C
            POKEBYTE
            SETTS 3
            ret

;####################
; LD (HL),D
align 16
Op72:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_D
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),D
align 16
OpDD72:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_D
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),D
align 16
OpFD72:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_D
            POKEBYTE
            SETTS 3
            ret

;####################
; LD (HL),E
align 16
Op73:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_E
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),E
align 16
OpDD73:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_E
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),E
align 16
OpFD73:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_E
            POKEBYTE
            SETTS 3
            ret

;####################
; LD (HL),H
align 16
Op74:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_H
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),H
align 16
OpDD74:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_H
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),H
align 16
OpFD74:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_H
            POKEBYTE
            SETTS 3
            ret

;####################
; LD (HL),L
align 16
Op75:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_L
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),L
align 16
OpDD75:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_L
            POKEBYTE
            SETTS 3
            ret

; LD (IY+n),L
align 16
OpFD75:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_L
            POKEBYTE
            SETTS 3
            ret

;####################
; HALT
align 16
Op76:
            FLAGS_MODIFIED  FALSE
            mov     Reg_HALTED, TRUE
            dec     Reg_PC     ; repeat HALT until interrupt occurs

            .if     AutoPlayTapes == TRUE
                    mov     TapePlaying, False
            .endif
            ret

;####################
; LD (HL),A
align 16
Op77:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            mov     al, Reg_A
            POKEBYTE
            SETTS   3
            ret

; LD (IX+n),A
align 16
OpDD77:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_A
            POKEBYTE
            SETTS   3
            ret

; LD (IY+n),A
align 16
OpFD77:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            mov     al, Reg_A
            POKEBYTE
            SETTS   3
            ret

;####################
; LD A,B
align 16
Op78:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_B
            mov     Reg_A, al
            ret

;####################
; LD A,C
align 16
Op79:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_C
            mov     Reg_A, al
            ret

;####################
; LD A,D
align 16
Op7A:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_D
            mov     Reg_A, al
            ret

;####################
; LD A,E
align 16
Op7B:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_E
            mov     Reg_A, al
            ret

;####################
; LD A,H
align 16
Op7C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_H
            mov     Reg_A, al
            ret

; LD A,IXH
align 16
OpDD7C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXH
            mov     Reg_A, al
            ret

; LD A,IYH
align 16
OpFD7C:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; LD A,L
align 16
Op7D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_L
            mov     Reg_A, al
            ret

; LD A,IXL
align 16
OpDD7D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IXL
            mov     Reg_A, al
            ret

; LD A,IYL
align 16
OpFD7D:
            FLAGS_MODIFIED  FALSE
            mov     al, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; LD A,(HL)
align 16
Op7E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_HL
            GETBYTE
            mov     Reg_A, al
            SETTS   3
            ret

; LD A,(IX+n)
align 16
OpDD7E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IX
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_A, al
            SETTS   3
            ret

; LD A,(IY+n)
align 16
OpFD7E:
            FLAGS_MODIFIED  FALSE
            mov     bx, Reg_IY
            GETRUNBYTE
            ADDOFFSET
            SETTS   3
            ADDMULTICONTENTIONPC    5
            GETBYTE
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; LD A,A
Op7F:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; ADD A,B
align 16
Op80:
            ADDBYTE Reg_A, Reg_B
            mov     Reg_A ,al
            ret

;####################
; ADD A,C
align 16
Op81:
            ADDBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; ADD A,D
align 16
Op82:
            ADDBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; ADD A,E
align 16
Op83:
            ADDBYTE Reg_A, Reg_E
            mov     Reg_A,al
            ret

;####################
; ADD A,H
align 16
Op84:
            ADDBYTE Reg_A, Reg_H
            mov     Reg_A,al
            ret

; ADD A,IXH
align 16
OpDD84:
            ADDBYTE Reg_A, Reg_IXH
            mov     Reg_A,al
            ret

; ADD A,IYH
align 16
OpFD84:
            ADDBYTE Reg_A, Reg_IYH
            mov     Reg_A,al
            ret

;####################
; ADD A,L
align 16
Op85:
            ADDBYTE Reg_A, Reg_L
            mov     Reg_A,al
            ret

; ADD A,IXL
align 16
OpDD85:
            ADDBYTE Reg_A, Reg_IXL
            mov     Reg_A,al
            ret

; ADD A,IYL
align 16
OpFD85:
            ADDBYTE Reg_A, Reg_IYL
            mov     Reg_A,al
            ret

;####################
; ADD A,(HL)
align 16
Op86:
            movzx   ebx, Reg_HL
            GETBYTE
            mov     bl, al
            ADDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; ADD A,(IX+n)
align 16
OpDD86:
            GETRUNBYTE
            SETTS   3

            movzx   ebx, Reg_PC
            dec     ebx             ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ADDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; ADD A,(IY+n)
align 16
OpFD86:
            GETRUNBYTE
            SETTS   3

            movzx   ebx, Reg_PC
            dec     ebx             ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ADDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; ADD A,A
align 16
Op87:
            ADDBYTE Reg_A, Reg_A
            mov     Reg_A, al
            ret

;####################
; ADC A,B
align 16
Op88:
            ADCBYTE Reg_A, Reg_B
            mov     Reg_A, al
            ret

;####################
; ADC A,C
align 16
Op89:
            ADCBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; ADC A,D
align 16
Op8A:
            ADCBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; ADC A,E
align 16
Op8B:
            ADCBYTE Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; ADC A,H
align 16
Op8C:
            ADCBYTE Reg_A, Reg_H
            mov     Reg_A, al
            ret

; ADC A,IXH
align 16
OpDD8C:
            ADCBYTE Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; ADC A,IYH
align 16
OpFD8C:
            ADCBYTE Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; ADC A,L
align 16
Op8D:
            ADCBYTE Reg_A, Reg_L
            mov     Reg_A, al
            ret

; ADC A,IXL
align 16
OpDD8D:
            ADCBYTE Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; ADC A,IYL
align 16
OpFD8D:
            ADCBYTE Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; ADC A,(HL)
align 16
Op8E:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            ADCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; ADC A,(IX+n)
align 16
OpDD8E:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ADCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; ADC A,(IY+n)
align 16
OpFD8E:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ADCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; ADC A,A
align 16
Op8F:
            ADCBYTE Reg_A, Reg_A
            mov     Reg_A, al
            ret

;####################
; SUB B
align 16
Op90:
            SUBBYTE Reg_A, Reg_B
            mov     Reg_A, al
            ret

;####################
; SUB C
align 16
Op91:
            SUBBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; SUB D
align 16
Op92:
            SUBBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; SUB E
align 16
Op93:
            SUBBYTE Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; SUB H
align 16
Op94:
            SUBBYTE Reg_A, Reg_H
            mov     Reg_A, al
            ret

; SUB IXH
align 16
OpDD94:
            SUBBYTE Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; SUB IYH
align 16
OpFD94:
            SUBBYTE Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; SUB L
align 16
Op95:
            SUBBYTE Reg_A, Reg_L
            mov     Reg_A, al
            ret

; SUB IXL
align 16
OpDD95:
            SUBBYTE Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; SUB IYL
align 16
OpFD95:
            SUBBYTE Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; SUB (HL)
align 16
Op96:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            SUBBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; SUB (IX+n)
align 16
OpDD96:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            SUBBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; SUB (IY+n)
align 16
OpFD96:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            SUBBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; SUB A
align 16
Op97:
            mov     al, Reg_A
            SUBBYTE al, al
            mov     Reg_A, al
            ret

;####################
; SBC A,B
align 16
Op98:
            SBCBYTE Reg_A, Reg_B
            mov     Reg_A, al
            ret

;####################
; SBC A,C
align 16
Op99:
            SBCBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; SBC A,D
align 16
Op9A:
            SBCBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; SBC A,E
align 16
Op9B:
            SBCBYTE Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; SBC A,H
align 16
Op9C:
            SBCBYTE Reg_A, Reg_H
            mov     Reg_A, al
            ret

; SBC A,IXH
align 16
OpDD9C:
            SBCBYTE Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; SBC A,IYH
align 16
OpFD9C:
            SBCBYTE Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; SBC A,L
align 16
Op9D:
            SBCBYTE Reg_A, Reg_L
            mov     Reg_A, al
            ret

; SBC A,IXL
align 16
OpDD9D:
            SBCBYTE Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; SBC A,IYL
align 16
OpFD9D:
            SBCBYTE Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; SBC A,(HL)
align 16
Op9E:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            SBCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; SBC A,(IX+n)
align 16
OpDD9E:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            SBCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; SBC A,(IY+n)
align 16
OpFD9E:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            SBCBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; SBC A,A
align 16
Op9F:
            mov     al, Reg_A
            SBCBYTE al, al
            mov     Reg_A, al
            ret

;####################
; AND B
align 16
OpA0:
            ANDBYTE Reg_A, Reg_B
            mov     Reg_A, al
            ret

;####################
; AND C
align 16
OpA1:
            ANDBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; AND D
align 16
OpA2:
            ANDBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; AND E
align 16
OpA3:
            ANDBYTE Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; AND H
align 16
OpA4:
            ANDBYTE Reg_A, Reg_H
            mov     Reg_A, al
            ret

; AND IXH
align 16
OpDDA4:
            ANDBYTE Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; AND IYH
align 16
OpFDA4:
            ANDBYTE Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; AND L
align 16
OpA5:
            ANDBYTE Reg_A, Reg_L
            mov     Reg_A, al
            ret

; AND IXL
align 16
OpDDA5:
            ANDBYTE Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; AND IYL
align 16
OpFDA5:
            ANDBYTE Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; AND (HL)
align 16
OpA6:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            ANDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; pc:4,pc+1:4,pc+2:3,pc+2:1 x 5,ii+n:3

; AND (IX+n)
align 16
OpDDA6:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ANDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; AND (IY+n)
align 16
OpFDA6:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ANDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; AND A
align 16
OpA7:
            mov     al, Reg_A
            ANDBYTE al, al
            mov     Reg_A, al
            ret

;####################
; XOR B
align 16
OpA8:
            XORBYTE Reg_A, Reg_B
            mov     Reg_A, al
            ret

;####################
; XOR C
align 16
OpA9:
            XORBYTE Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; XOR D
align 16
OpAA:
            XORBYTE Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; XOR E
align 16
OpAB:
            XORBYTE Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; XOR H
align 16
OpAC:
            XORBYTE Reg_A, Reg_H
            mov     Reg_A, al
            ret

; XOR IXH
align 16
OpDDAC:
            XORBYTE Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; XOR IYH
align 16
OpFDAC:
            XORBYTE Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; XOR L
align 16
OpAD:
            XORBYTE Reg_A, Reg_L
            mov     Reg_A, al
            ret

; XOR IXL
align 16
OpDDAD:
            XORBYTE Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; XOR IYL
align 16
OpFDAD:
            XORBYTE Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; XOR (HL)
align 16
OpAE:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            XORBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; XOR (IX+n)
align 16
OpDDAE:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            XORBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; XOR (IY+n)
align 16
OpFDAE:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            XORBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; XOR A
align 16
OpAF:
            mov     al, Reg_A
            XORBYTE al, al
            mov     Reg_A, al
            ret

;####################
; OR B
align 16
OpB0:
            ORBYTE  Reg_A, Reg_B
            mov     Reg_A, al
            ret


;####################
; OR C
align 16
OpB1:
            ORBYTE  Reg_A, Reg_C
            mov     Reg_A, al
            ret

;####################
; OR D
align 16
OpB2:
            ORBYTE  Reg_A, Reg_D
            mov     Reg_A, al
            ret

;####################
; OR E
align 16
OpB3:
            ORBYTE  Reg_A, Reg_E
            mov     Reg_A, al
            ret

;####################
; OR H
align 16
OpB4:
            ORBYTE  Reg_A, Reg_H
            mov     Reg_A, al
            ret

; OR IXH
align 16
OpDDB4:
            ORBYTE  Reg_A, Reg_IXH
            mov     Reg_A, al
            ret

; OR IYH
align 16
OpFDB4:
            ORBYTE  Reg_A, Reg_IYH
            mov     Reg_A, al
            ret

;####################
; OR L
align 16
OpB5:
            ORBYTE  Reg_A, Reg_L
            mov     Reg_A, al
            ret

; OR IXL
align 16
OpDDB5:
            ORBYTE  Reg_A, Reg_IXL
            mov     Reg_A, al
            ret

; OR IYL
align 16
OpFDB5:
            ORBYTE  Reg_A, Reg_IYL
            mov     Reg_A, al
            ret

;####################
; OR (HL)
align 16
OpB6:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            ORBYTE  Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; OR (IX+n)
align 16
OpDDB6:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ORBYTE  Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

; OR (IY+n)
align 16
OpFDB6:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            ORBYTE  Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; OR A
align 16
OpB7:
            mov     al, Reg_A
            ORBYTE  al, al
            mov     Reg_A, al
            ret

;####################
; CP B
align 16
OpB8:
            CMPBYTE Reg_B
            ret

;####################
; CP C
align 16
OpB9:
            CMPBYTE Reg_C
            ret

;####################
; CP D
align 16
OpBA:
            CMPBYTE Reg_D
            ret

;####################
; CP E
align 16
OpBB:
            CMPBYTE Reg_E
            ret

;####################
; CP H
align 16
OpBC:
            CMPBYTE Reg_H
            ret

; CP IXH
align 16
OpDDBC:
            CMPBYTE Reg_IXH
            ret

; CP IYH
align 16
OpFDBC:
            CMPBYTE Reg_IYH
            ret

;####################
; CP L
align 16
OpBD:
            CMPBYTE Reg_L
            ret

; CP IXL
align 16
OpDDBD:
            CMPBYTE Reg_IXL
            ret

; CP IYL
align 16
OpFDBD:
            CMPBYTE Reg_IYL
            ret

;####################
; CP (HL)
align 16
OpBE:
            mov     bx, Reg_HL
            GETBYTE
            mov     bl, al
            CMPBYTE bl
            SETTS   3
            ret

; CP (IX+n)
align 16
OpDDBE:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IX
            ADDOFFSET

            GETBYTE
            mov     bl, al

            CMPBYTE bl
            SETTS   3
            ret

; CP (IY+n)
align 16
OpFDBE:
            GETRUNBYTE
            SETTS   3

            mov     bx, Reg_PC
            dec     bx              ; back to pc+2
            ADDMULTICONTENTION  5

            mov     bx, Reg_IY
            ADDOFFSET

            GETBYTE
            mov     bl, al

            CMPBYTE bl
            SETTS   3
            ret

;####################
; CP A
align 16
OpBF:
            CMPBYTE Reg_A

            ifc     rzx_mode ne RZX_NONE then ret

            .if     (Reg_PC == 056Bh) && (Reg_LoadTapeType != Type_NONE)
                    push    esi
                    call    ROMLoadTapeTrap     ; ROM tape load trap
                    pop     esi
            .endif
            ret

;####################
; RET NZ
align 16
OpC0:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_Z
            jnz     @F

            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################
; POP BC
align 16
OpC1:
            FLAGS_MODIFIED  FALSE
            POPSTACK
            mov     Reg_BC,ax
            ret

;####################
; JP NZ,nn
align 16
OpC2:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_Z
            jnz     @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; JP nn
align 16
OpC3:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     Reg_PC, ax
            ret

;####################
; CALL NZ,nn
align 16
OpC4:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_Z
            jnz     @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION
            SETTS   1

            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; PUSH BC
align 16
OpC5:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     ax, Reg_BC
            PUSHSTACK
            ret

;####################
; ADD A,n
align 16
OpC6:
            GETRUNBYTE
            mov     bl, al
            ADDBYTE Reg_A, bl
            mov     Reg_A, al
            SETTS   3
            ret

;####################
; RST 0
align 16
OpC7:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            xor     ax, ax
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET Z
align 16
OpC8:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_Z
            jz      @F
            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################
; RET
align 16
OpC9:
            FLAGS_MODIFIED  FALSE

Z80Ret:     ADD_PC_HISTORY
            Z80RET
            ret

;####################
; JP Z,nn
align 16
OpCA:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_Z
            jz      @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; CALL Z,nn
align 16
OpCC:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_Z
            jz      @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; CALL nn
align 16
OpCD:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION
            SETTS   1

            mov     ax, cx
            Z80CALL
            ret

;####################
; ADC A,n
align 16
OpCE:
            GETRUNBYTE
            mov     bl, al
            ADCBYTE Reg_A,bl
            mov     Reg_A,al
            SETTS   3
            ret

;####################
; RST 8
align 16
OpCF:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            ADD_IR_CYCLES     1
            mov     ax, 8
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET NC
align 16
OpD0:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_C
            jnz     @F
            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################

; POP DE
align 16
OpD1:
            FLAGS_MODIFIED  FALSE
            POPSTACK
            mov     Reg_DE,ax
            ret

;####################
; JP NC,nn
align 16
OpD2:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_C
            jnz     @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; OUT (n),A
align 16
OpD3:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE
            mov     bl, al
            mov     bh, Reg_A
            SETTS   3
            inc     bl
            mov     Reg_MemPtr, bx
            dec     bl
            mov     al, bh

            jmp     OutPort

;####################
; CALL NC
align 16
OpD4:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_C
            jnz     @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL

@@:         ret

;####################
; PUSH DE
align 16
OpD5:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     ax, Reg_DE
            PUSHSTACK
            ret

;####################
; SUB n
align 16
OpD6:
            GETRUNBYTE
            mov     bl, al
            SETTS   3
            SUBBYTE Reg_A, bl
            mov     Reg_A, al
            ret

;####################
; RST 16
align 16
OpD7:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 16
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET C
align 16
OpD8:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_C
            .if     !ZERO?
                    ADD_PC_HISTORY
                    Z80RET
            .endif
            ret

;####################
; EXX
align 16
OpD9:
            FLAGS_MODIFIED  FALSE
            mov     ax, Reg_HL
            mov     bx, Reg_HL_alt
            mov     Reg_HL_alt, ax
            mov     Reg_HL, bx

            mov     ax, Reg_DE
            mov     bx, Reg_DE_alt
            mov     Reg_DE_alt, ax
            mov     Reg_DE, bx

            mov     ax, Reg_BC
            mov     bx, Reg_BC_alt
            mov     Reg_BC_alt, ax
            mov     Reg_BC, bx

            ret

;####################
; JP C,nn
align 16
OpDA:
            FLAGS_MODIFIED  FALSE

            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_C
            jz      @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################

.data?
align 16
DiffRegPtr          dd  ?

SL_OldTStates       dd  ?

SL_LoaderPC         dw  ?
SL_LoopCycles       dw  ?

SL_BC               LABEL   WORD
SL_C                db  ?
SL_B                db  ?
SL_DE               LABEL   WORD
SL_E                db  ?
SL_D                db  ?
SL_HL               LABEL   WORD
SL_L                db  ?
SL_H                db  ?
SL_PC               dw  ?

SL_A                db  ?
SL_LoopCount        db  ?
SL_FrameCnt         db  ?

DiffRegVal          db  ?
SL_AND_32_64        db  ?


.code
; ** cx needs loading with 01FFh prior to using the GETREGDIFF macro **
GETREGDIFF          macro   reg:REQ, oldreg:REQ
                    mov     al, reg
                    sub     al, oldreg
                    je      @F                          ; skip for unchanged registers
                    .if     (al != ch) && (al != cl)    ; compare with +1 and -1
                            jmp     SL_LoopFail
                    .endif
                    inc     bl                          ; increment counter of registers that changed by 1 or -1
                    mov     DiffRegPtr, offset reg      ; store pointer to the register that changed (valid if only one register value changes)
                    mov     DiffRegVal, al              ; store register value difference (1 or -1)
@@:
                    endm

                ; *** SenseLoader is only called if AutoPlayTapes == TRUE ***
                ; ===========================================================
align 16
SenseLoader:
                    .if     (TapePlaying == TRUE) && (SL_LoopCount >= 8)
                            mov     ax, zPC
                            .if     ax == SL_LoaderPC
                                    mov     AutoTapeStarted, TRUE                   ; start/keep the tape playing
                                    mov     AutoTapeStopFrames, AUTOTAPEPLAYFRAMES  ; minimum frames before auto tape stop

                                    .if     FastTapeLoading == TRUE

                                          ; initialise for entry into SL_Loop
                                            mov     eax, DiffRegPtr
                                            mov     cx,  01FFh

                                align 16
                                          ; on entry, eax must hold [DiffRegPtr]
                                          ;           cx  must hold 01FFh
                                SL_Loop:    mov     al, [eax]
                                            cmp     al, cl              ; 255 ?
                                            je      SL_TimeOut
                                            cmp     al, ch              ; 1 ?
                                            je      SL_TimeOut

                                            call    PlayTape
                                            cmp     EdgeTrigger, TRUE   ; has a new pulse arrived?
                                            je      SL_Pulse

                                            mov     cx,  SL_LoopCycles
                                            mov     eax, DiffRegPtr     ; pointer to the edge loop timeout register
                                            mov     bl,  DiffRegVal     ; edge loop differential (+1/-1)
                                            add     TapeTStates, cx     ; advance tape tstates
                                            mov     cx,  01FFh          ; +1/-1 for SL_Loop entry
                                            add     [eax], bl           ; adds the differential (+1/-1) to the diff register
                                            mov     Z80TState, 0        ; every other loop has no extra ts (beyond TapeTStates += SL_LoopCycles)
                                            jmp     SL_Loop             ; eax holds [DiffRegPtr] for SL_Loop entry
                                    .endif
                                    ret

                        SL_Pulse:   mov     EdgeTriggerAck, TRUE        ; acknowledge the new pulse and exit

                        SL_TimeOut:

                        SL_Exit:    lea     esi, RegisterBase           ; restore RegisterBase to esi before exit
                                    ret

                            .endif
                    .endif

                  ; we reach here only if the tape is not playing
            align 16
                    mov     ax, [TZXCurrBlock]
                    cmp     ax, [TZXBlockCount]
                    jnc     SL_LoopFail             ; end of tape

                    mov     cl, SPGfx.FrameCnt
                    sub     cl, SL_FrameCnt         ; all loops must occur in the same frame
                    jnz     SL_LoopFail

                    mov     eax, totaltstates
                    sub     eax, SL_OldTStates      ; elapsed cycles between ULA INs
                    mov     bx,  zPC

                    .if     (eax <= 96) && (bx == SL_PC)
                            mov     SL_LoopCycles, ax

                            mov     al, z80registers.af.hi
                            cmp     al, SL_A
                            jne     SL_LoopFail     ; A must not change for all 8 loops

                            mov     cx, 01FFh       ; ** cx needs loading with 01FFh prior to using the GETREGDIFF macro **
                            xor     bl, bl          ; counter for registers whose value has changed by 1 or -1 since last loop
                            GETREGDIFF  z80registers.bc.hi, SL_B
                            GETREGDIFF  z80registers.bc.lo, SL_C
                            GETREGDIFF  z80registers.de.hi, SL_D
                            GETREGDIFF  z80registers.de.lo, SL_E
                            GETREGDIFF  z80registers.hl.hi, SL_H
                            GETREGDIFF  z80registers.hl.lo, SL_L

                          ; one (and only one) register can change by 1 or -1 between loops
                          ; to be regarded as a potential tape loader
                            .if     bl == 1
                                    inc     SL_LoopCount

                                  ; we need eight such loops in sequence to be regarded as a tape loader
                                    .if     SL_LoopCount >= 8
                                            ; start loading
                                            mov     TapePlaying, TRUE
                                            mov     AutoTapeStarted, TRUE
                                            mov     AutoTapeStopFrames, AUTOTAPEPLAYFRAMES  ; minimum frames before auto tape stop

                                            mov     ax, zPC
                                            mov     SL_LoaderPC, ax
                                    .endif

                                    ; must still copy registers even if loading started
                                    jmp     SL_CopyLoadRegs
                            .endif
                    .endif

align 16
SL_LoopFail:        mov     SL_LoopCount, 0

SL_CopyLoadRegs:    mov     ax, z80registers.bc.w
                    mov     bx, z80registers.de.w
                    mov     cx, z80registers.hl.w
                    mov     dx, zPC

                    mov     SL_BC, ax
                    mov     SL_DE, bx
                    mov     SL_HL, cx
                    mov     SL_PC, dx

                    mov     eax, totaltstates
                    mov     bl, z80registers.af.hi
                    mov     cl, SPGfx.FrameCnt

                    mov     SL_OldTStates, eax
                    mov     SL_A, bl
                    mov     SL_FrameCnt, cl
                    ret


; IN A,(n)
align 16
OpDB:
            FLAGS_MODIFIED  FALSE
            GETRUNBYTE      ; fetch port address
            SETTS   3

            movzx   ebx, Reg_F       ; IN A,(n) does not affect Z80 flags register
            push    ebx

          ; if this is a ULA port address and we have a tape inserted then scan for a potential tape loader
            .if     (Reg_LoadTapeType != Type_NONE) && AutoPlayTapes
                    .if     (RealTapeMode == FALSE) && (rzx_mode == RZX_NONE)
                            test    al, 1
                            .if     ZERO?
                                    .if     SL_AND_32_64
                                            push    eax             ; preserve port address
                                            call    SenseLoader
                                            pop     eax             ; restore port address
                                    .endif
                            .endif
                    .endif
            .endif

            mov     bl, al
            mov     bh, Reg_A
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx

            call    InPort

            mov     Reg_A, al

            pop     ebx
            mov     Reg_F, bl       ; restore Z80 flags register

            mov     SL_AND_32_64, FALSE
            ret

;####################
; CALL C,nn
align 16
OpDC:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_C
            jz      @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; DEFB $DD
align 16
OpDD:
            mov     Reg_UseIXIY, UsingIX                ; still need this for CB opcodes and in case of multiple DD/FD prefixes

            mov     ecx, Reg_totaltstates     ; we need to preserve the totaltstates count in case of multiple DD/FD prefixes

            mov     bx, Reg_PC
            M1_FETCH

            mov     edx, [Z80JumpTable_DD+eax*4]

            mov     bl, al
            and     bl, 11011101b                   ; catch DD/FD opcodes
            cmp     bl, 11011101b
            je      Multi_DDFD                      ; branch on multiple DD/FD prefixes

            SETTS   4                               ; 4 TStates for M1 cycle
            add     Reg_PC,    1
            add     Reg_R,     1
            add     Reg_InsLength, 1

            jmp     edx

;####################
; DEFB $FD
align 16
OpFD:
            mov     Reg_UseIXIY, UsingIY                ; still need this for CB opcodes and in case of multiple DD/FD prefixes

            mov     ecx, Reg_totaltstates     ; we need to preserve the totaltstates count in case of multiple DD/FD prefixes

            mov     bx,  Reg_PC
            M1_FETCH

            mov     edx, [Z80JumpTable_FD+eax*4]

            mov     bl, al
            and     bl, 11011101b                   ; catch FD/DD opcodes
            cmp     bl, 11011101b
            je      Multi_DDFD                      ; branch on multiple DD/FD prefixes

            SETTS   4                               ; 4 TStates for M1 cycle
            add     Reg_PC,    1
            add     Reg_R,     1
            add     Reg_InsLength, 1

            jmp     edx


Multi_DDFD: mov     Reg_EI_Last, TRUE                   ; block interrupts in a prefix chain

            ; we restore the totaltstate count prior to fetching the multiple DD/FD prefix ready for normal opcode fetch cycle
            mov     Reg_totaltstates, ecx

            .if     rzx_mode == RZX_PLAY
                    add     RZXPLAY.rzx_io_recording.Fetch_Counter, 1   ; this was decremented in M1_FETCH macro
            .elseif rzx_mode == RZX_RECORD
                    add     RZXREC.rzx_io_recording.Fetch_Counter, 1    ; this was decremented in M1_FETCH macro
            .endif
            ret

;####################
; SBC A,n
align 16
OpDE:
            GETRUNBYTE
            mov     bl, al
            SETTS   3
            SBCBYTE Reg_A, bl
            mov     Reg_A, al
            ret

;####################
; RST 24
align 16
OpDF:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 24
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET PO
align 16
OpE0:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_V
            .if     ZERO?
                    ADD_PC_HISTORY
                    Z80RET
            .endif
            ret

;####################
; POP HL
align 16
OpE1:
            FLAGS_MODIFIED  FALSE
            POPSTACK
            mov     Reg_HL, ax
            ret

; POP IX
align 16
OpDDE1:
            FLAGS_MODIFIED  FALSE
            POPSTACK
            mov     Reg_IX, ax
            ret

; POP IY
align 16
OpFDE1:
            FLAGS_MODIFIED  FALSE
            POPSTACK
            mov     Reg_IY, ax
            ret

;####################
; JP PO,nn
align 16
OpE2:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_V
            .if     ZERO?
                    ADD_PC_HISTORY
                    mov     Reg_PC, ax
            .endif
            ret

;####################

; pc:4,sp:3,sp+1:3,sp+1:1,sp+1(write):3,sp(write):3,sp(write):1 x 2

; EX (SP),HL
align 16

OpE3:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            mov     bx, Reg_SP
            GETBYTE
            SETTS   3
            mov     cl, al
            inc     bx
            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1
            mov     ch, al
            mov     al, Reg_H
            POKEBYTE
            SETTS   3
            dec     bx
            mov     al, Reg_L
            POKEBYTE
            SETTS   3
            ADDMULTICONTENTION  2
            mov     Reg_HL, cx
            mov     Reg_MemPtr, cx

            mov     Reg_MemoryReadAddress, bx
            mov     Reg_MemoryReadEvent, MEMACCESSWORD

            mov     Reg_MemoryWriteAddress, bx
            mov     Reg_MemoryWriteEvent, MEMACCESSWORD
            ret


; EX (SP),IX
; (pc:4),pc:4,sp:3,sp+1:3,sp+1:1,sp+1(write):3,sp(write):3,sp(write):1 x 2

align 16
OpDDE3:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            mov     bx, Reg_SP
            GETBYTE
            SETTS   3
            mov     cl, al
            inc     bx
            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1
            mov     ch, al
            mov     al, Reg_IXH
            POKEBYTE
            SETTS   3
            dec     bx
            mov     al, Reg_IXL
            POKEBYTE
            SETTS   3
            ADDMULTICONTENTION  2
            mov     Reg_IX, cx
            mov     Reg_MemPtr, cx

            mov     Reg_MemoryReadAddress, bx
            mov     Reg_MemoryReadEvent, MEMACCESSWORD

            mov     Reg_MemoryWriteAddress, bx
            mov     Reg_MemoryWriteEvent, MEMACCESSWORD
            ret


; EX (SP),IY
; (pc:4),pc:4,sp:3,sp+1:3,sp+1:1,sp+1(write):3,sp(write):3,sp(write):1 x 2
align 16
OpFDE3:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            mov     bx, Reg_SP
            GETBYTE
            SETTS   3
            mov     cl, al
            inc     bx
            GETBYTE
            SETTS   3
            ADDMULTICONTENTION  1
            mov     ch, al
            mov     al, Reg_IYH
            POKEBYTE
            SETTS   3
            dec     bx
            mov     al, Reg_IYL
            POKEBYTE
            SETTS   3
            ADDMULTICONTENTION  2
            mov     Reg_IY, cx
            mov     Reg_MemPtr, cx

            mov     Reg_MemoryReadAddress, bx
            mov     Reg_MemoryReadEvent, MEMACCESSWORD

            mov     Reg_MemoryWriteAddress, bx
            mov     Reg_MemoryWriteEvent, MEMACCESSWORD
            ret

;####################
; CALL PO,nn
align 16
OpE4:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_V
            .if     ZERO?
                    ADD_PC_HISTORY
                    mov     bx, Reg_PC
                    dec     bx
                    ADDCONTENTION
                    SETTS   1
                    mov     ax, cx
                    Z80CALL
            .endif
            ret

;####################
; PUSH HL
align 16
OpE5:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     ax, Reg_HL
            PUSHSTACK
            ret

; PUSH IX
align 16
OpDDE5:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     ax, Reg_IX
            PUSHSTACK
            ret

; PUSH IY
align 16
OpFDE5:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     ax, Reg_IY
            PUSHSTACK
            ret

;####################
; AND n
align 16
OpE6:
            GETRUNBYTE

            mov     bl, al
            SETTS   3
            ANDBYTE Reg_A, bl
            mov     Reg_A, al
            ret

;####################
; RST 32
align 16
OpE7:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 32
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET PE
align 16
OpE8:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_V
            jz      @F
            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################
; JP (HL)
align 16
OpE9:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            mov     ax, Reg_HL
            mov     Reg_PC, ax
            ret

; JP (IX)
align 16
OpDDE9:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            mov     ax, Reg_IX
            mov     Reg_PC, ax
            ret

; JP (IY)
align 16
OpFDE9:
            FLAGS_MODIFIED  FALSE
            ADD_PC_HISTORY
            mov     ax, Reg_IY
            mov     Reg_PC, ax
            ret

;####################
; JP PE,nn
align 16
OpEA:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_V
            jz      @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; EX DE,HL
align 16
OpEB:
            FLAGS_MODIFIED  FALSE
            mov     ax, Reg_DE
            mov     bx, Reg_HL
            mov     Reg_DE, bx
            mov     Reg_HL, ax
            ret

;####################
; CALL PE,nn
align 16
OpEC:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F,FLAG_V
            jz      @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; XOR n
align 16
OpEE:
            GETRUNBYTE
            mov     bl, al
            SETTS   3
            XORBYTE Reg_A, bl
            mov     Reg_A, al
            ret

;####################
; RST 40
align 16
OpEF:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 40
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET P
align 16
OpF0:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_S
            jnz     @F
            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################
; POP AF
align 16
OpF1:
            FLAGS_MODIFIED  FALSE       ; ???
            POPSTACK
            mov     Reg_AF, ax
            ret

;####################
; JP P,nn
align 16
OpF2:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_S
            jnz     @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; DI
align 16
OpF3:
            FLAGS_MODIFIED  FALSE
            mov     Reg_OpcodeWord, 0F3h
            DISABLEINTS
            ret

;####################
; CALL P,nn
align 16
OpF4:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_S
            jnz     @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; PUSH AF
align 16
OpF5:
            FLAGS_MODIFIED  FALSE
            .if     (Reg_PC == 57) && (uSpeech_Enabled == TRUE)
                    xor     uSpeech_Paged, TRUE
            .endif

            ADD_IR_CYCLES   1
            mov     ax, Reg_AF
            PUSHSTACK
            ret

;####################
; OR n
align 16
OpF6:
            GETRUNBYTE
            mov     bl, al
            SETTS   3
            ORBYTE  Reg_A, bl
            mov     Reg_A, al
            ret

;####################
; RST 48
align 16
OpF7:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 48
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;####################
; RET M
align 16
OpF8:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            test    Reg_F, FLAG_S
            jz      @F
            ADD_PC_HISTORY
            Z80RET
@@:         ret

;####################
; LD SP,HL
align 16
OpF9:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            mov     ax, Reg_HL
            mov     Reg_SP, ax
            ret

; LD SP,IX
align 16
OpDDF9:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            mov     ax, Reg_IX
            mov     Reg_SP, ax
            ret

; LD SP,IY
align 16
OpFDF9:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   2
            mov     ax, Reg_IY
            mov     Reg_SP, ax
            ret

;####################
; JP M,nn
align 16
OpFA:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax

            test    Reg_F, FLAG_S
            jz      @F

            ADD_PC_HISTORY
            mov     Reg_PC, ax
@@:         ret

;####################
; EI
align 16
OpFB:
            FLAGS_MODIFIED  FALSE
            mov     Reg_OpcodeWord, 0FBh
            ENABLEINTS
            mov     Reg_EI_Last, TRUE
            ret

;####################
; CALL M,nn
align 16
OpFC:
            FLAGS_MODIFIED  FALSE
            GETRUNWORD
            mov     Reg_MemPtr, ax
            mov     cx, ax

            test    Reg_F, FLAG_S
            jz      @F

            ADD_PC_HISTORY
            mov     bx, Reg_PC
            dec     bx
            ADDCONTENTION

            SETTS   1
            mov     ax, cx
            Z80CALL
@@:         ret

;####################
; CP n
align 16
OpFE:
            GETRUNBYTE
            mov     bl, al
            SETTS   3
            CMPBYTE bl
            ret

;####################
; RST 56
align 16
OpFF:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES     1
            ADD_PC_HISTORY
            mov     ax, 56
            mov     Reg_MemPtr, ax
            Z80CALL
            ret

;#######################################################

align 16
OpED:
Do_EDInstrs:
            mov     Reg_UseIXIY, 0  ; DD/FD have no effect on ED instructions

            FETCH_OPCODE    offset Z80JumpTable_ED
            jmp     ecx

;            jmp     [Z80JumpTable_ED+eax*4]

EDRet:      ret

;####################################################
; IN B,(C)
align 16
OpED40:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_B, al
            ret

;####################
; OUT (C),B
align 16
OpED41:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_B
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; SBC HL,BC
align 16
OpED42:
            ADD_IR_CYCLES   7
            SBCHL   Reg_BC
            ret

;####################
; LD (nn),BC
align 16
OpED43:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            mov     ax, Reg_BC
            POKEWORD
            ret

;####################
; IM 0
align 16
OpED46:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  0
            ret

;####################
; LD I,A
align 16
OpED47:
            FLAGS_MODIFIED  FALSE
            ADD_IR_CYCLES   1
            mov     al, Reg_A
            mov     Reg_I, al

            invoke  SetSnowEffect
            ret

;####################
; IN C,(C)
align 16
OpED48:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_C, al
            ret

;####################
; OUT (C),C
align 16
OpED49:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_C
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; ADC HL,BC
align 16
OpED4A:
            ADD_IR_CYCLES   7
            ADCHL   Reg_BC
            ret

;####################
; LD BC,(nn)
align 16
OpED4B:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETWORD
            mov     Reg_BC, ax
            ret

;####################
; IM0/1
align 16
OpED4E:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  1
            ret

;####################
; LD R,A
align 16
OpED4F:
            FLAGS_MODIFIED  FALSE
            mov     Reg_OpcodeWord, 0ED4Fh
            ADD_IR_CYCLES   1
            mov     al, Reg_A
            mov     Reg_R, al
            and     al, 128
            mov     Reg_R_msb,al
            ret

;####################
; IN D,(C)
align 16
OpED50:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_D, al
            ret

;####################
; OUT (C),D
align 16
OpED51:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_D
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; SBC HL,DE
align 16
OpED52:
            ADD_IR_CYCLES   7
            SBCHL   Reg_DE
            ret

;####################
; LD (nn),DE
align 16
OpED53:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            mov     ax, Reg_DE
            POKEWORD
            ret

;####################
; IM 1
align 16
OpED56:
            FLAGS_MODIFIED  FALSE
            mov     Reg_OpcodeWord, 0ED56h
            SETINTMODE  1
            ret

;####################

; LD A,I
align 16
OpED57:
            FLAGS_MODIFIED  TRUE
            ADD_IR_CYCLES   1
            mov     al, Reg_I
            mov     Reg_A, al

            mov     Reg_IFF2_Read, TRUE
            jmp     Set_AIFlags

;####################
; IN E,(C)
align 16
OpED58:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_E, al
            ret

;####################
; OUT (C),E
align 16
OpED59:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_E
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; ADC HL,DE
align 16
OpED5A:
            ADD_IR_CYCLES   7
            ADCHL   Reg_DE
            ret

;####################
; LD DE,(nn)
align 16
OpED5B:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETWORD
            mov     Reg_DE, ax
            ret

;####################
; IM 2
align 16
OpED5E:
            FLAGS_MODIFIED  FALSE
            mov     Reg_OpcodeWord, 0ED5Eh
            SETINTMODE  2
            ret

;####################
; LD A,R
align 16
OpED5F:
            FLAGS_MODIFIED  TRUE
            mov     Reg_OpcodeWord, 0ED5Fh
            ADD_IR_CYCLES   1
            mov     al, Reg_R
            and     al, 127
            or      al, Reg_R_msb
            mov     Reg_A, al

            mov     Reg_IFF2_Read, TRUE
            call    Set_AIFlags

          ; turn off indirect addressing here
            USEESI  0

            .if     (RealTapeMode == FALSE) && (rzx_mode == RZX_NONE)
                    .if     FastTapeLoading && (TapePlaying == FALSE)
                            push    esi

                            movzx   ebx, zPC
                            GETZ80ADDRESS

                            ; speedlock decryption accelerator test 1
                            ; ED 5F	LD   A,R   ;hits on multiple Speedlock 7 decryption tapes ; Guerilla War 128k, Gryzor 128k Hit squad
                            ; --------------
                            ; DD AC	XOR  IXH
                            ; 96	SUB  (HL)
                            ; DD AD	XOR  IXL
                            ; 77	LD   (HL),A
                            ; 0B	DEC  BC
                            ; 79	LD   A,C
                            ; 23	INC  HL
                            ; B0	OR   B
                            ; C2	JP   NZ

        ld_ar_speedlock_t1: cmp     dword ptr [esi], 0DD96ACDDh
                            jne     ld_ar_speedlock_t2
                            cmp     dword ptr [esi+4], 790B77ADh
                            jne     ld_ar_speedlock_t2
                            mov     eax, [esi+8]
                            and     eax, 00FFFFFFh
                            cmp     eax, 00C2B023h
                            je      ld_ar_tape_hit

                            ; speedlock decryption accelerator test 2
                            ; ED 5F	LD   A,R   ;hits on multiple Speedlock 7 decryption tapes ; Operation Wolf
                            ; --------------
                            ; AE	XOR  (HL)
                            ; 77	LD   (HL),A
                            ; ED A0	LDI
                            ; 1B	DEC  DE
                            ; E0	RET  PO
                            ; 18	JR

        ld_ar_speedlock_t2: cmp     dword ptr [esi], 0A0ED77AEh
                            jne     ld_ar_alkatraz
                            mov     eax, [esi+4]
                            and     eax, 00FFFFFFh
                            cmp     eax, 0018E01Bh
                            je      ld_ar_tape_hit

                            ; alkatraz decryption accelerator
                            ; ED 5F	LD   A,R
                            ; --------------
                            ; 4F	LD   C,A
                            ; D1	POP  DE
                            ; 7B	LD   A,E
                            ; A9	XOR  C
                            ; 5A	LD   E,D
                            ; 57	LD   D,A
                            ; D5	PUSH DE
                            ; C1	POP  BC
                            ; 2B	DEC  HL
                            ; 7D	LD   A,L
                            ; B4	OR   H
                            ; C2	JP   NZ

        ld_ar_alkatraz:     cmp     dword ptr [esi], 0A97BD14Fh
                            jne     ld_ar_exit
                            cmp     dword ptr [esi+4], 0C1D5575Ah
                            jne     ld_ar_exit
                            cmp     dword ptr [esi+8], 0C2B47D2Bh
                            jne     ld_ar_exit

        ld_ar_tape_hit:     .if     AutoPlayTapes
                                    mov     TapePlaying, TRUE
                                    mov     AutoTapeStarted, TRUE
                                    mov     AutoTapeStopFrames, AUTOTAPEPLAYFRAMES  ; minimum frames before auto tape stop
                            .endif

        ld_ar_exit:         pop     esi

                    .endif
            .endif
            ret

          ; turn on indirect addressing here
            USEESI  1

;;####################
;; LD A,R
;align 16
;OpED5F:
;            FLAGS_MODIFIED  TRUE
;            mov     Reg_OpcodeWord, 0ED5Fh
;            ADD_IR_CYCLES   1
;            mov     al, Reg_R
;            and     al, 127
;            or      al, zR_Bit7
;            mov     Reg_A, al
;
;            mov     Reg_IFF2_Read, TRUE
;            jmp     Set_AIFlags

;####################
; IN H,(C)
align 16
OpED60:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_H, al
            ret

;####################
; OUT (C),H
align 16
OpED61:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_H
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; SBC HL,HL
align 16
OpED62:
            ADD_IR_CYCLES   7
            SBCHL   Reg_HL
            ret

;####################
; IM 0
align 16
OpED66:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  0
            ret

;####################
; RRD
align 16
OpED67:
            FLAGS_MODIFIED  TRUE
            mov     bx, Reg_HL
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETBYTE

            SETTS   3
            ADDMULTICONTENTION  4

            mov     dl, al              ; dl = (HL)

            mov     al, Reg_A
            mov     cl, dl
            shl     al, 4
            shr     cl, 4
            or      al, cl
            POKEBYTE
            SETTS   3

            mov     al, Reg_A
            and     al, 240
            and     dl, 15
            or      al, dl
            mov     Reg_A, al

            mov     bl, Reg_F
            and     bl, FLAG_C
            test    al, 255             ; al = A register
            lahf
            and     ah, @FLAGS (SZV)
            or      bl, ah
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; IN L,(C)
align 16
OpED68:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_L, al
            ret

;####################
; OUT (C),L
align 16
OpED69:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_L
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; ADC HL,HL
align 16
OpED6A:
            ADD_IR_CYCLES   7
            ADCHL   Reg_HL
            ret

;####################
; LD HL,(nn)
align 16
OpED6B:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess,TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETWORD
            mov     Reg_HL,ax
            ret

;####################
; IM0/1
align 16
OpED6E:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  1
            ret

;####################
; RLD
align 16
OpED6F:
            FLAGS_MODIFIED  TRUE
            mov     bx, Reg_HL
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETBYTE

            SETTS   3
            ADDMULTICONTENTION  4

            mov     dl, al              ; dl = (HL)

            mov     al, Reg_A
            mov     cl, dl
            and     al, 15
            shl     cl, 4
            or      al, cl
            POKEBYTE
            SETTS   3

            mov     al, Reg_A
            and     al, 240
            shr     dl, 4
            or      al, dl
            mov     Reg_A, al

            mov     bl, Reg_F
            and     bl, FLAG_C
            test    al, 255             ; al = A register
            lahf
            and     ah, @FLAGS (SZV)
            or      bl, ah
            and     al, @FLAGS (53)
            or      bl, al
            mov     Reg_F, bl
            ret

;####################
; IN F,(C)
align 16
OpED70:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort     ; set flags only (throw result away)
            ret

;####################
; OUT (C),0
align 16
OpED71:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            xor     al, al                      ; output 0
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; SBC HL,SP
align 16
OpED72:
            ADD_IR_CYCLES   7
            SBCHL   Reg_SP
            ret

;####################
; LD (nn),SP
align 16
OpED73:
            FLAGS_MODIFIED  FALSE
            mov     Reg_WordLengthAccess,TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            mov     ax, Reg_SP
            POKEWORD
            ret

;####################
; IM 1
align 16
OpED76:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  1
            ret

;####################
; NOP
align 16
OpED77:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; IN A,(C)
align 16
OpED78:
            FLAGS_MODIFIED  TRUE
            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx

            call    InPort
            mov     Reg_A, al
            ret

;####################
; OUT (C),A
align 16
OpED79:
            FLAGS_MODIFIED  FALSE
            movzx   ebx, Reg_BC
            mov     al, Reg_A
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort
            ret

;####################
; ADC HL,SP
align 16
OpED7A:
            ADD_IR_CYCLES   7
            ADCHL   Reg_SP
            ret

;####################
; LD SP,(nn)
align 16
OpED7B:
            FLAGS_MODIFIED  FALSE
            FLAGS_MODIFIED

            mov     Reg_WordLengthAccess, TRUE

            GETRUNWORD
            inc     bx
            mov     Reg_MemPtr, bx
            dec     bx
            GETWORD
            mov     Reg_SP, ax
            ret

;####################
; IM 2
OpED7E:
            FLAGS_MODIFIED  FALSE
            SETINTMODE  2
            ret

;####################
; NOP
OpED7F:
            FLAGS_MODIFIED  FALSE
            ret

;####################

OpED80:
OpED81:
OpED82:
OpED83:
OpED84:
OpED85:
OpED86:
OpED87:
OpED88:
OpED89:
OpED8A:
OpED8B:
OpED8C:
OpED8D:
OpED8E:
OpED8F:
OpED90:
OpED91:
OpED92:
OpED93:
OpED94:
OpED95:
OpED96:
OpED97:
OpED98:
OpED99:
OpED9A:
OpED9B:
OpED9C:
OpED9D:
OpED9E:
OpED9F:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LDI
align 16
OpEDA0:
            FLAGS_MODIFIED  TRUE
            mov     bx, Reg_HL
            GETBYTE
            SETTS   3
            mov     bx, Reg_DE
            POKEBYTE
            SETTS   3

            mov     bx, Reg_DE
            ADDMULTICONTENTION  2

            inc     Reg_HL
            inc     Reg_DE

            add     al, Reg_A
            mov     dl, Reg_F
            and     dl, NOT @FLAGS (5H3VN)

            test    al, 2
            setnz   cl
            test    al, 8
            setnz   ch

            shl     cl, 5
            shl     ch, 3
            or      dl, cl
            or      dl, ch

            dec     Reg_BC
            setnz   al
            shl     al, 2       ; V set if BC>0
            or      dl, al

@@:         mov     Reg_F, dl
            ret

;####################
; CPI
align 16
OpEDA1:
            FLAGS_MODIFIED  TRUE
            inc     Reg_MemPtr

            mov     bx, Reg_HL
            GETBYTE
            SETTS   3

            mov     bx, Reg_HL
            ADDMULTICONTENTION  5

            mov     bl, al
            mov     bh, Reg_F
            and     bh, FLAG_C     ; preserve Carry flag in bh

            push    ebx
            SUBBYTE Reg_A, bl
            pop     ebx

            inc     Reg_HL

            mov     dl, Reg_F
            and     dl, NOT @FLAGS (53VC)
            mov     al, Reg_A
            sub     al, bl

            test    dl, FLAG_H     ; al = al - H
            setnz   cl
            sub     al, cl

            test    al, 2       ; test bit 1
            setnz   cl
            test    al, 8       ; test bit 3
            setnz   ch

            shl     cl, 5
            shl     ch, 3
            or      dl, cl
            or      dl, ch

            dec     Reg_BC
            setnz   al
            shl     al, 2       ; V set if BC>0
            or      dl, al

            or      dl, bh      ; restore Carry flag
            mov     Reg_F, dl
            ret

;####################
; INI
align 16
OpEDA2:
            FLAGS_MODIFIED  TRUE
            ADD_IR_CYCLES     1

            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    InPort

            push    eax     ; (HL)

            mov     bx, Reg_HL
            POKEBYTE

            SETTS   3

            inc     Reg_HL

            DECBYTE Reg_B
            mov     Reg_B, al

            and     Reg_F, NOT @FLAGS (HVNC) ; clear H, V, N, C

            pop     edx             ; dl = (HL)
            mov     cl, Reg_C
            add     cl, 1           ; cl = (C + 1)

          ; NF: A copy of bit 7 of the value read from or written to an I/O port.
            mov     al, dl          ; (HL)
            shr     al, 6           ; bit 7 >> NF
            and     al, 2
            or      Reg_F, al

          ; PF: The parity of (((HL) + ((C + 1) & 255)) & 7) xor B)
            mov     al, dl          ; (HL)
            add     al, cl          ; + (C + 1)
            and     al, 7
            xor     al, Reg_B
            lahf
            and     ah, FLAG_V
            or      Reg_F, ah

          ; HF and CF: Both set if ((HL) + ((C + 1) & 255) > 255)
            mov     al, dl          ; (HL)
            add     al, cl          ; + (C + 1)
            .if     CARRY?
                    or      Reg_F, @FLAGS (HC)
            .endif
            ret

;####################
; 48/128: pc:4,pc+1:4,ir:1,hl:3,I/O
; +2a/+3: pc:4,pc+1:5,hl:3,I/O

; OUTI
align 16
OpEDA3:
            FLAGS_MODIFIED  TRUE
            DECBYTE Reg_B
            mov     Reg_B, al
            ADD_IR_CYCLES     1

            mov     bx, Reg_HL
            GETBYTE
            SETTS   3

            push    eax     ; (HL)

            movzx   ebx, Reg_BC
            lea     ecx, [ebx+1]
            mov     Reg_MemPtr, cx
            call    OutPort

            inc     Reg_HL

            and     Reg_F, NOT @FLAGS (HVNC) ; clear H, V, N, C

            pop     edx             ; dl = (HL)
            mov     cl, Reg_L ; cl = L

          ; NF: A copy of bit 7 of the value read from or written to an I/O port.
            mov     al, dl          ; (HL)
            shr     al, 6           ; bit 7 >> NF
            and     al, 2
            or      Reg_F, al

          ; PF The parity of ((((HL) + L) & 7) xor B)
            mov     al, dl          ; (HL)
            add     al, cl          ; + L
            and     al, 7
            xor     al, Reg_B
            lahf
            and     ah, FLAG_V
            or      Reg_F, ah

          ; HF and CF: Both set if ((HL) + L > 255)
            mov     al, dl          ; (HL)
            add     al, cl          ; + L
            .if     CARRY?
                    or      Reg_F, @FLAGS (HC)
            .endif
            ret

;####################

align 16
OpEDA4:
OpEDA5:
OpEDA6:
OpEDA7:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LDD
align 16
OpEDA8:
            FLAGS_MODIFIED  TRUE
            mov     bx, Reg_HL
            GETBYTE
            SETTS   3
            mov     bx, Reg_DE
            POKEBYTE
            SETTS   3

            mov     bx, Reg_DE
            ADDMULTICONTENTION  2

            dec     Reg_HL
            dec     Reg_DE

            add     al, Reg_A
            mov     dl, Reg_F
            and     dl, NOT @FLAGS (5H3VN)

            test    al, 2
            setnz   cl
            test    al, 8
            setnz   ch

            shl     cl, 5
            shl     ch, 3
            or      dl, cl
            or      dl, ch

            dec     Reg_BC
            setnz   al
            shl     al, 2       ; V set if BC>0
            or      dl, al

            mov     Reg_F, dl
            ret

;####################
; CPD
align 16
OpEDA9:
            FLAGS_MODIFIED  TRUE
            dec     Reg_MemPtr

            mov     bx, Reg_HL
            GETBYTE
            SETTS   3

            mov     bx, Reg_HL
            ADDMULTICONTENTION  5

            mov     bl, al
            mov     bh, Reg_F
            and     bh, FLAG_C     ; preserve Carry flag in bh

            push    ebx
            SUBBYTE Reg_A, bl
            pop     ebx

            dec     Reg_HL

            mov     dl, Reg_F
            and     dl, NOT @FLAGS (53VC)
            mov     al, Reg_A
            sub     al, bl

            test    dl, FLAG_H     ; al = al - H
            setnz   cl
            sub     al, cl

            test    al, 2       ; test bit 1
            setnz   cl
            test    al, 8       ; test bit 3
            setnz   ch

            shl     cl, 5
            shl     ch, 3
            or      dl, cl
            or      dl, ch

            dec     Reg_BC
            setnz   al
            shl     al, 2       ; V set if BC>0
            or      dl, al

            or      dl, bh      ; restore Carry flag
            mov     Reg_F, dl
            ret

;####################
; IND
align 16
OpEDAA:
            FLAGS_MODIFIED  TRUE
            ADD_IR_CYCLES     1

            movzx   ebx, Reg_BC
            lea     ecx, [ebx-1]
            mov     Reg_MemPtr, cx

            call    InPort

            push    eax     ; (HL)

            mov     bx, Reg_HL
            POKEBYTE
            SETTS   3
            dec     Reg_HL
            DECBYTE Reg_B
            mov     Reg_B, al

            and     Reg_F, NOT @FLAGS (HVNC) ; clear H, V, N, C

            pop     edx             ; dl = (HL)
            mov     cl, Reg_C
            sub     cl, 1           ; cl = (C - 1)

          ; NF: A copy of bit 7 of the value read from or written to an I/O port.
            mov     al, dl          ; (HL)
            shr     al, 6           ; bit 7 >> NF
            and     al, 2
            or      Reg_F, al

          ; PF The parity of (((HL) + ((C - 1) & 255)) & 7) xor B)
            mov     al, dl          ; (HL)
            add     al, cl          ; + (C - 1)
            and     al, 7
            xor     al, Reg_B
            lahf
            and     ah, FLAG_V
            or      Reg_F, ah

          ; HF and CF Both set if ((HL) + ((C - 1) & 255) > 255)
            mov     al, dl          ; (HL)
            add     al, cl          ; + (C - 1)
            .if     CARRY?
                    or      Reg_F, @FLAGS (HC)
            .endif
            ret

;####################
; OUTD
align 16
OpEDAB:
            FLAGS_MODIFIED  TRUE
            DECBYTE Reg_B
            mov     Reg_B, al
            ADD_IR_CYCLES     1

            mov     bx, Reg_HL
            GETBYTE
            SETTS   3

            push    eax     ; (HL)

            movzx   ebx, Reg_BC
            lea     ecx, [ebx-1]
            mov     Reg_MemPtr, cx

            call    OutPort

            dec     Reg_HL

            and     Reg_F, NOT @FLAGS (HVNC) ; clear H, V, N, C

            pop     edx             ; dl = (HL)
            mov     cl, Reg_L ; cl = L

          ; NF: A copy of bit 7 of the value read from or written to an I/O port.
            mov     al, dl          ; (HL)
            shr     al, 6           ; bit 7 >> NF
            and     al, 2
            or      Reg_F, al

          ; PF The parity of ((((HL) + L) & 7) xor B)
            mov     al, dl          ; (HL)
            add     al, cl          ; + L
            and     al, 7
            xor     al, Reg_B
            lahf
            and     ah, FLAG_V
            or      Reg_F, ah

          ; HF and CF: Both set if ((HL) + L > 255)
            mov     al, dl          ; (HL)
            add     al, cl          ; + L
            .if     CARRY?
                    or      Reg_F, @FLAGS (HC)
            .endif
            ret

;####################
OpEDAC:
OpEDAD:
OpEDAE:
OpEDAF:
            FLAGS_MODIFIED  FALSE
            ret

; https://github.com/hoglet67/Z80Decoder/wiki/Undocumented-Flags#interrupted-block-instructions

;####################
; LDIR
align 16
OpEDB0:
            call    OpEDA0     ; LDI
            cmp     Reg_BC, 0
            je      @F

            movzx   ecx, Reg_DE

            movzx   ebx, Reg_PC
            lea     eax, [ebx-2]
            dec     ebx
            mov     Reg_PC, ax
            mov     Reg_MemPtr, bx

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (53) ; clear 5, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah
            mov     Reg_F, bl

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5

            mov     Reg_IsRepeating, TRUE
@@:         ret

;####################
; CPIR
align 16
OpEDB1:
            call    OpEDA1     ; CPI
            test    Reg_F, FLAG_Z
            jnz     @F
            cmp     Reg_BC, 0
            je      @F

            movzx   ecx, Reg_HL

            movzx   ebx, Reg_PC
            lea     eax, [ebx-2]
            dec     ebx
            mov     Reg_PC, ax
            mov     Reg_MemPtr, bx

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (53) ; clear 5, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah
            mov     Reg_F, bl

            lea     ebx, [ecx-1]
            ADDMULTICONTENTION  5

            mov     Reg_IsRepeating, TRUE
@@:         ret

;####################
; INIR
align 16
OpEDB2:
            call    OpEDA2 ; INI
            cmp     Reg_B, 0
            je      @F

            mov     bx, Reg_HL
            dec     bx
            ADDMULTICONTENTION  5

            mov     ax, Reg_PC
            sub     ax, 2
            mov     Reg_PC, ax              ; ax = address of ED for flags below

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (5H3)    ; clear 5, H, 3
            and     ah, @FLAGS (53)         ; 5, 3 from address of ED prefix when repeating
            or      bl, ah

            xor     edx, edx

            test    bl, @FLAGS (C)
            .if     !ZERO?
                    test    PortReadByte, 80h
                    .if     !ZERO?
                            mov     dx, 0FF00h
                    .else
                            mov     dx, 001FFh
                    .endif

                    mov     cl, Reg_B
                    and     cl, 15
                    cmp     cl, dl
                    sete    ch
                    shl     ch, 4
                    or      bl, ch  ; set H
            .endif

            mov     cl, Reg_B
            add     cl, dh
            and     cl, 7
            setpo   ch
            shl     ch, 2
            xor     ch, bl
            and     bl, NOT @FLAGS (P)
            and     ch, @FLAGS (P)
            or      bl, ch

            mov     Reg_F, bl

            mov     Reg_IsRepeating, TRUE
@@:         ret

;####################
; OTIR
align 16
OpEDB3:
            call    OpEDA3 ; OUTI
            cmp     Reg_B, 0
            je      @F

            mov     bx, Reg_BC            ; apply contention on port address, as if a memory address
            ADDMULTICONTENTION  5

            mov     ax, Reg_PC
            sub     ax, 2
            mov     Reg_PC, ax          ; ax = address of ED for flags below

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (5H3); clear 5, H, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah

            xor     edx, edx

            test    bl, @FLAGS (C)
            .if     !ZERO?
                    test    PortWriteByte, 80h
                    .if     !ZERO?
                            mov     dx, 0FF00h
                    .else
                            mov     dx, 001FFh
                    .endif

                    mov     cl, Reg_B
                    and     cl, 15
                    cmp     cl, dl
                    sete    ch
                    shl     ch, 4
                    or      bl, ch  ; set H
            .endif

            mov     cl, Reg_B
            add     cl, dh
            and     cl, 7
            setpo   ch
            shl     ch, 2
            xor     ch, bl
            and     bl, NOT @FLAGS (P)
            and     ch, @FLAGS (P)
            or      bl, ch

            mov     Reg_F, bl

            mov     Reg_IsRepeating, TRUE
@@:         ret

align 16
OpEDB4:
OpEDB5:
OpEDB6:
OpEDB7:
            FLAGS_MODIFIED  FALSE
            ret

;####################
; LDDR
align 16
OpEDB8:
            call    OpEDA8     ; LDD
            cmp     Reg_BC, 0
            je      @F

            movzx   ecx, Reg_DE

            movzx   ebx, Reg_PC
            lea     eax, [ebx-2]
            dec     ebx
            mov     Reg_PC, ax
            mov     Reg_MemPtr, bx

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (53) ; clear 5, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah
            mov     Reg_F, bl

            lea     ebx, [ecx+1]
            ADDMULTICONTENTION  5

            mov     Reg_IsRepeating, TRUE
@@:         ret

;####################
; CPDR
align 16
OpEDB9:
            call    OpEDA9  ; CPD
            test    Reg_F, FLAG_Z
            jnz     @F
            cmp     Reg_BC, 0
            je      @F

            movzx   ecx, Reg_HL

            movzx   ebx, Reg_PC
            lea     eax, [ebx-2]
            dec     ebx
            mov     Reg_PC, ax
            mov     Reg_MemPtr, bx

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (53) ; clear 5, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah
            mov     Reg_F, bl

            lea     ebx, [ecx+1]
            ADDMULTICONTENTION  5

            mov     Reg_IsRepeating, TRUE
@@:         ret

;####################
; INDR
align 16
OpEDBA:
            call    OpEDAA ; IND
            cmp     Reg_B, 0
            je      @F

            mov     bx, Reg_HL
            inc     bx
            ADDMULTICONTENTION  5

            mov     ax, Reg_PC
            sub     ax, 2
            mov     Reg_PC, ax          ; ax = address of ED for flags below

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (5H3); clear 5, H, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah

            xor     edx, edx

            test    bl, @FLAGS (C)
            .if     !ZERO?
                    test    PortReadByte, 80h
                    .if     !ZERO?
                            mov     dx, 0FF00h
                    .else
                            mov     dx, 001FFh
                    .endif

                    mov     cl, Reg_B
                    and     cl, 15
                    cmp     cl, dl
                    sete    ch
                    shl     ch, 4
                    or      bl, ch  ; set H
            .endif

            mov     cl, Reg_B
            add     cl, dh
            and     cl, 7
            setpo   ch
            shl     ch, 2
            xor     ch, bl
            and     bl, NOT @FLAGS (P)
            and     ch, @FLAGS (P)
            or      bl, ch

            mov     Reg_F, bl

            mov     Reg_IsRepeating, TRUE
@@:         ret

; OTDR
align 16
OpEDBB:
            call    OpEDAB ; OUTD
            cmp     Reg_B, 0
            je      @F

            mov     bx, Reg_BC            ; apply contention on port address, as if a memory address
            ADDMULTICONTENTION  5

            mov     ax, Reg_PC
            sub     ax, 2
            mov     Reg_PC, ax          ; ax = address of ED for flags below

            mov     bl, Reg_F
            and     bl, NOT @FLAGS (5H3); clear 5, H, 3
            and     ah, @FLAGS (53)     ; 5, 3 from address of ED prefix when repeating
            or      bl, ah

            xor     edx, edx

            test    bl, @FLAGS (C)
            .if     !ZERO?
                    test    PortWriteByte, 80h
                    .if     !ZERO?
                            mov     dx, 0FF00h
                    .else
                            mov     dx, 001FFh
                    .endif

                    mov     cl, Reg_B
                    and     cl, 15
                    cmp     cl, dl
                    sete    ch
                    shl     ch, 4
                    or      bl, ch  ; set H
            .endif

            mov     cl, Reg_B
            add     cl, dh
            and     cl, 7
            setpo   ch
            shl     ch, 2
            xor     ch, bl
            and     bl, NOT @FLAGS (P)
            and     ch, @FLAGS (P)
            or      bl, ch

            mov     Reg_F, bl

            mov     Reg_IsRepeating, TRUE
@@:         ret

align 4
OpEDBC:
OpEDBD:
OpEDBE:
OpEDBF:
OpEDC0:
OpEDC1:
OpEDC2:
OpEDC3:
OpEDC4:
OpEDC5:
OpEDC6:
OpEDC7:
OpEDC8:
OpEDC9:
OpEDCA:
OpEDCB:
OpEDCC:
OpEDCD:
OpEDCE:
OpEDCF:
OpEDD0:
OpEDD1:
OpEDD2:
OpEDD3:
OpEDD4:
OpEDD5:
OpEDD6:
OpEDD7:
OpEDD8:
OpEDD9:
OpEDDA:
OpEDDB:
OpEDDC:
OpEDDD:
OpEDDE:
OpEDDF:
OpEDE0:
OpEDE1:
OpEDE2:
OpEDE3:
OpEDE4:
OpEDE5:
OpEDE6:
OpEDE7:
OpEDE8:
OpEDE9:
OpEDEA:
OpEDEB:
OpEDEC:
OpEDED:
OpEDEE:
OpEDEF:
OpEDF0:
OpEDF1:
OpEDF2:
OpEDF3:
OpEDF4:
OpEDF5:
OpEDF6:
OpEDF7:
OpEDF8:
OpEDF9:
OpEDFA:
OpEDFB:
OpEDFC:
OpEDFD:
OpEDFE:
OpEDFF:
            FLAGS_MODIFIED  FALSE
            ret

                      ; turn off indirect addressing here
                        USEESI  0

.data?
align 16
TapSaveFH           HANDLE  ?
TAPBytesNeeded      DWORD   ?
TAPSaveBuffer       DWORD   ?

TAPSaveStart        WORD    ?
TAPSaveLen          WORD    ?

.data
szAskForSaveTape    db  "A program is trying to save data to tape.", 13
                    db  "There is no tape inserted for saving.", 13, 13
                    db  "Would you like to insert a tape for saving to now?", 0

.code
; #####################################################################################
; used as trap in ROM save routine
ROMSaveTapeTrap:
                .if     BoostSavingNoise == TRUE
                        ret         ; continue to emulate normal tape saving
                .endif

                mov     TapSaveFH, 0

                .if     SaveTapeType == Type_NONE
                        ; no tape file inserted for saving to
                        invoke  ShowMessageBox, hWnd, addr szAskForSaveTape, addr szWindowName, MB_YESNO or MB_ICONQUESTION
                        .if     eax != IDYES
                                jmp     TAPSaveExit
                        .endif
                        call    InsertSaveTape
                .endif

                ; a tape file is (possibly) inserted for saving to
                .if     SaveTapeType != Type_TAP
                        jmp     TAPSaveExit
                .endif

                RetryOpenSaveTape:
                invoke  CreateFile, addr SaveTapeFilename, GENERIC_WRITE, NULL, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                .if     eax == INVALID_HANDLE_VALUE
                        invoke  ShowMessageBox, hWnd, SADD ("Unable to open tape file for saving"), addr szWindowName, MB_RETRYCANCEL or MB_ICONWARNING
                        cmp     eax, IDRETRY
                        je      RetryOpenSaveTape
                        jmp     TAPSaveExit
                .endif
                mov     TapSaveFH, eax    ; store filehandle for TAP file

                ; always append to end of a TAP file
                invoke  SetFilePointer, TapSaveFH, 0, NULL, FILE_END

                mov     ax, z80registers.ix.w
                inc     ax
                mov     TAPSaveStart, ax
                mov     ax, z80registers.de.w
                dec     ax
                mov     TAPSaveLen, ax

                add     ax, 4           ; 1 for flag, 1 for parity, 2 for total length
                and     eax, 0FFFFh
                mov     TAPBytesNeeded, eax

                mov     TAPSaveBuffer, AllocMem (TAPBytesNeeded)
                .if     eax == 0
                        call    ShowTempMemoryFail
                        jmp     TAPSaveFree
                .endif

                mov     edi, TAPSaveBuffer
                mov     eax, TAPBytesNeeded
                sub     ax, 2
                stosw
                mov     al, z80registers.af_.hi       ; flag byte (which is in Z80 A` register)
                stosb

                mov     bx, TAPSaveStart
                mov     cx, TAPSaveLen
                mov     dl, z80registers.af_.hi       ; checksum byte starts as flag byte

                or      cx, cx
                je      TAPSaveChecksum

@@:             call    MemGetByte
                movzx   ebx, bx
                or      byte ptr [Map_Memory+ebx], MEMMAPF_READ_BYTE ; saved bytes are read from memory

                xor     dl, al          ; update checksum byte
                stosb
                inc     bx
                dec     cx
                jne     @B

TAPSaveChecksum:
                mov     al, dl
                stosb                   ; store checksum byte

                .if     $fnc (WriteFile, TapSaveFH, TAPSaveBuffer, TAPBytesNeeded, addr BytesSaved, NULL) == 0
                        invoke  ShowMessageBox, hWnd, SADD ("WriteFile() failed when writing to tape file"), addr szWindowName, MB_ICONWARNING
                .endif

TAPSaveFree:    ifc     TAPSaveBuffer ne 0 then invoke GlobalFree, TAPSaveBuffer
                invoke  CloseHandle, TapSaveFH
                mov     TapSaveFH, 0

TAPSaveExit:    lea     esi, RegisterBase   ; restore for Z80RET macro

                mov     al, SaveTapeType
                .if     (al == Type_CSW) || (al == Type_WAV)
                        ; continue to emulate normal tape saving for these tape types
                        ret
                .endif

                .if     RealTapeSaveSpeed == FALSE
                        or    Reg_F, FLAG_C  ; indicate that BREAK didn't abort saving
                        Z80RET                              ; and exit to code that called ROM save bytes code
                .endif                                      ; else continue to emulate normal tape saving
                ret

; #####################################################################################
; used as tape loading trap opcode
; IX = load address, DE = length in bytes, A` = Flag byte

; this trap emulates a Z80 RET instruction on exit

align 16
ROMLoadTapeTrap:
            switch  LoadTapeType
                    case    Type_NONE
                            ret
                    case    Type_TAP, Type_TZX  ; allowed tape types for ROM Loading trap
                    .else
                            ret
            endsw

            cmp     FlashLoadROMBlocks, TRUE
            je      @F

OpEDFF_1:   .if     AutoPlayTapes == TRUE
                    mov     TapePlaying, TRUE
                    mov     EarBit, 0
            .endif
            ret

@@:         cmp     TapePlaying, TRUE   ; if tape already playing
            je      OpEDFF_1            ; then must continue

OpEDFF_NextBlock:
            xor     eax, eax
            mov     ax, TZXCurrBlock
            cmp     ax, TZXBlockCount
            jnc     OpEDFF_EndOfTape

            mov     esi, TZXBlockPtrs
            mov     eax, [esi+eax*4]
            or      eax, eax
            jne     OpEDFF_Cnt1

OpEDFF_EndOfTape:
            ret     ; return here for no auto-rewind
            mov     TZXCurrBlock, -1
            jmp     LoadingError    ; will inc TZXCurrBlock back to zero !

OpEDFF_Cnt1:
@@:         mov     esi, eax     ; esi = blockdata

            cmp     LoadTapeType, Type_TAP
            je      NrmLoad1

            mov     al, [esi]
            cmp     al, 10h
            je      NLBlock10

            cmp     al, 16h      ; skip C64 ROM type data block
            je      SkipToNextTapeBlock

            cmp     al, 17h      ; skip C64 Turbo Tape data block
            je      SkipToNextTapeBlock

            cmp     al, 20h      ; start actual tape if < Pause block
            jc      OpEDFF_1
            cmp     al, 23h
            jc      SkipToNextTapeBlock
            je      Do_JumpToBlock

            cmp     al, 28h
            je      SelectTapeBlock

            cmp     al, 36h
            jnc     OpEDFF_1
            cmp     al, 30h
            jc      OpEDFF_1

SkipToNextTapeBlock:
            inc     TZXCurrBlock
            jmp     OpEDFF_NextBlock

Do_JumpToBlock:
            inc     esi
            mov     bx, [esi]
            mov     ax, TZXCurrBlock
            add     ax, bx
            mov     TZXCurrBlock, ax
            jmp     OpEDFF_NextBlock

SelectTapeBlock:
            jmp     SkipToNextTapeBlock

NLBlock10:  inc     esi
            mov     ax, [esi]                               ; read Pause value
            add     esi, 2
;            cmp     ax, 1000
;            jnc     @F
;            mov     ax, 1000                               ; amendment - minimum pause of 1s  ; breaks ping pong
@@:         mov     TZXPause, ax
            jmp     NrmLoad2

NrmLoad1:   mov     TZXPause, 1000

NrmLoad2:   movzx   eax, word ptr [esi]                     ; read ByteCount value from TAP block
            add     esi, 2                                  ; advance to TAP Spectrum data

            mov     ByteCount, eax                          ; available bytes in TAP block
            mov     BytePtr, esi

            lea     esi, RegisterBase
            mov     edi, BytePtr                            ; edi points to TAP block data

            mov     z80registers.hl.hi, 0                   ; checksum initialised in H

LoadByteLoop:
            .if     ByteCount == 0                          ; if available TAP bytes == 0
                    mov     al, z80registers.bc.lo
                    and     al, 32
                    mov     z80registers.af.hi, al          ; reg_A = (reg_C & 32)
                    mov     z80registers.bc.hi, 0           ; reg_B = 0
                    mov     z80registers.af.lo, 01010000b   ; reg_F = %01010000
                    jmp     LoadExitRET                     ; exit via RET opcode
            .endif

            mov     al, [edi]                               ; fetch TAP byte
            inc     edi                                     ; advance TAP pointer
            dec     ByteCount                               ; dec available TAP bytes

            mov     z80registers.hl.lo, al                  ; tape byte to L register
            xor     z80registers.hl.hi, al                  ; maintain checksum in H register

            cmp     z80registers.de.w, 0
            je      Load_DE_Zero                            ; branch forwards if DE = 0

          ; handle loaded bytes as per alternate flags
            call    Op08                    ; ex af,af'

            test    z80registers.af.lo, FLAG_Z
            .if     ZERO?
                    ; if Zero flag clear then we're testing the flag byte (#05B3 in ROM)
                    mov     al, Reg_F
                    ror     al, 1                           ; set x86 Carry as with Z80 Carry
                    rcl     z80registers.bc.lo, 1           ; RL C (#05b3)
                    call    OpAD                            ; XOR L
                    test    z80registers.af.lo, FLAG_Z      ; RET NZ
                    jz      LoadExitRET                     ; exit via RET if flag byte mismatch

                    call    Op79                            ; LD A,C
                    call    Op1F                            ; RRA
                    call    Op4F                            ; LD C,A

                    call    Op08                            ; ex af,af' (Zero is now set and so load routine enters the Load/Verify routine)
                    jmp     LoadByteLoop                    ; loop for next TAP byte
            .endif

            test    z80registers.af.lo, FLAG_C
            .if     ZERO?
                    ; verify byte at #05BD in ROM
                    mov     bx, z80registers.ix.w
                    call    MemGetByte
                    mov     z80registers.af.hi, al
                    call    OpAD                            ; XOR L
                    test    z80registers.af.lo, FLAG_Z      ; RET NZ
                    jz      LoadExitRET                     ; exit via RET if TAP byte mismatch
            .else
                  ; load byte at #05AE in ROM
                    movzx   ebx, z80registers.ix.w
                    or      byte ptr [Map_Memory+ebx], MEMMAPF_WRITE_BYTE    ; loaded bytes are written to memory
                    mov     al, z80registers.hl.lo
                    call    MemPokeByte                     ; write TAP byte to (IX)
            .endif

            inc     z80registers.ix.w
            dec     z80registers.de.w

            call    Op08                    ; ex af,af'
            jmp     LoadByteLoop


Load_DE_Zero:
            mov     al, z80registers.hl.hi
            mov     z80registers.af.hi, al  ; LD A,H
            CMPBYTE 1                       ; CP 1
            jmp     LoadExitRET             ; exit via RET


LoadingError:
            and     z80registers.af.lo, NOT FLAG_C

LoadExitRET:lea     esi, RegisterBase       ; restore for Z80Ret
            inc     TZXCurrBlock
            mov     ax, TZXCurrBlock
            cmp     ax, TZXBlockCount
            jc      Z80Ret
            mov     TZXCurrBlock, 0
            jmp     Z80Ret

                      ; turn on indirect addressing here
                        USEESI  1

;############################################################################################

align 16
Set_AIFlags:
            mov     dl, Reg_F
            and     dl, NOT  @FLAGS (SZ5H3VN)
            mov     al, Reg_A
            test    al, 255
            lahf
            and     ah, @FLAGS (SZ)
            or      dl, ah

            cmp     currentMachine.iff2, FALSE
            jz      @F

            or      dl, FLAG_V   ; V flag = interrupts state (EI/DI)

@@:         and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

; NEG

align 16
OpED44:
OpED4C:
OpED54:
OpED5C:
OpED64:
OpED6C:
OpED74:
OpED7C:

Do_NEG:
            FLAGS_MODIFIED  TRUE
            mov     dl, FLAG_N
            neg     Reg_A
            lahf
            jno     @F
            or      dl, FLAG_V
@@:         and     ah, @FLAGS (SZHC)
            or      dl, ah
            mov     al, Reg_A
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

; RETN
align 16
OpED45:
OpED55:
OpED5D:
OpED65:
OpED6D:
OpED75:
OpED7D:

Do_RETN:    ADD_PC_HISTORY

_RETN:
            FLAGS_MODIFIED  FALSE
            mov     al, currentMachine.iff2
            mov     currentMachine.iff1, al

;            Z80RET
;            ret

; Speedlock beep section trap
;    LD   A,(DE)
;    LD   C,A
;    DEC  DE
;    DEC  DE
;    DEC  DE
;    DEC  DE
;    DEC  DE
;    LD   A,(DE)
;    RETN

          ; turn off indirect addressing here
            USEESI  0

            .if     (RealTapeMode == FALSE) && (rzx_mode == RZX_NONE)
                    .if     FastTapeLoading && (TapePlaying == FALSE)
                            push    esi
                            movzx   ebx, zPC
                            sub     ebx, 10
                            GETZ80ADDRESS
                            cmp     dword ptr [esi], 1B1B4F1Ah
                            jne     @F
                            cmp     dword ptr [esi+4], 1A1B1B1Bh
                            jne     @F

                            .if     AutoPlayTapes
                                    mov     TapePlaying, TRUE
                                    mov     AutoTapeStarted, TRUE
                                    mov     AutoTapeStopFrames, AUTOTAPEPLAYFRAMES  ; minimum frames before auto tape stop
                            .endif

                        @@: pop     esi
                    .endif
            .endif

          ; turn on indirect addressing here
            USEESI  1

            Z80RET
            ret

;############################################################################################

; RETI
align 16
OpED4D:

; RETI also copies IFF2 into IFF1, like RETN

Do_RETI:    ADD_PC_HISTORY

_RETI:
            FLAGS_MODIFIED  FALSE
            mov     al, currentMachine.iff2
            mov     currentMachine.iff1, al

            Z80RET
            ret

;############################################################################################

align 16
OpCB:
Do_CBInstrs:
            mov     DoingBitTest, 0

            .if     Reg_UseIXIY != 0

                    ; case for (IX/Y+n); 20/23 Ts opcodes
                    GETRUNBYTE                      ; al = read offset
                    SETTS   3

                    cmp     Reg_UseIXIY, UsingIX      ; bx = base address
                    cmove   bx, Reg_IX
                    cmovne  bx, Reg_IY

                    ADDOFFSET
                    mov    Reg_CBAbsAddr, bx  ; bx = effective address

                    ; read opcode
                    GETINDEXEDOPCODE                ; 5 Ts
                    mov    Reg_CBOpcode, al
                    and    al, 7
                    mov    Reg_CBDestReg, al

                    GETBYTE                         ; read (IX+n)
                    SETTS   3
                    ADDMULTICONTENTION  1
                    mov     Reg_CBDestVal, al

            .else

                    ; case for Register/(HL); 12/15 Ts opcodes
                    FETCH_OPCODE

                    mov     Reg_CBOpcode, al
                    and     eax,7
                    mov     Reg_CBDestReg, al

                    lea     eax, [SD_Case0+eax*8]   ; 8 bytes/case offset
                    jmp     eax

                    ; these can't be done as [esi+n] offsets
                    ; **************************************

SD_Case0:           mov     bl, z80registers.bc.hi  ; 6 bytes
                    jmp     SD_EndCase              ; 2 bytes

SD_Case1:           mov     bl, z80registers.bc.lo
                    jmp     SD_EndCase

SD_Case2:           mov     bl, z80registers.de.hi
                    jmp     SD_EndCase

SD_Case3:           mov     bl, z80registers.de.lo
                    jmp     SD_EndCase

SD_Case4:           mov     bl, z80registers.hl.hi
                    jmp     SD_EndCase

SD_Case5:           mov     bl, z80registers.hl.lo
                    jmp     SD_EndCase

SD_Case6:           jmp     SD_Case6_1              ; 2 bytes
                    nop                             ; 6x1 bytes
                    nop
                    nop
                    nop
                    nop
                    nop

SD_Case7:           mov     bl, z80registers.af.hi
                    jmp     SD_EndCase

SD_Case6_1:         mov     bx, Reg_HL
                    mov     Reg_CBAbsAddr, bx
                    GETBYTE
                    SETTS   3
                    ADDMULTICONTENTION  1
                    mov     bl, al

SD_EndCase:         mov     Reg_CBDestVal, bl

            .endif

            movzx   ebx, Reg_CBOpcode   ; call the main opcode handler
            shr     ebx, 1
            and     ebx, 124
            mov     al, Reg_CBDestVal
            call    [CBFuncJumpTable+ebx]

            cmp     DoingBitTest, 1
            jne     Do_CB_02                        ; branch if wasn`t a BIT instruction

            .if     (Reg_UseIXIY != 0) || (Reg_CBDestReg == 6)
                    ; BIT n,(IX/Y+d), BIT n,(HL)
                    mov     al, Reg_F
                    and     al, NOT @FLAGS (53)
                    mov     bl, CM.memptr.hi ;[esi+Reg_MemPtrHigh]
                    and     bl, @FLAGS (53)
                    or      al, bl
                    mov     Reg_F, al
            .endif
            ret

Do_CB_02:   cmp     Reg_UseIXIY, 0
            je      Do_CB_03

            mov     bx, Reg_CBAbsAddr
            mov     al, Reg_CBDestVal
            POKEBYTE
            SETTS   3       ; writeback now if IX/IY, takes 3 T-States

            cmp     Reg_CBDestReg, 6
            je      WD_CaseRET  ; no point writing back twice!

Do_CB_03:   movzx   eax, Reg_CBDestReg
            mov     cl, Reg_CBDestVal

            and     eax, 7

            lea     eax, [WD_Case0+eax*8]   ; 8 bytes/case offset
            jmp     eax

            ; these can't be done as [esi+n] offsets
            ; **************************************

WD_Case0:   mov     z80registers.bc.hi, cl  ; 6 bytes
WD_CaseRET: ret                             ; 1 byte
            nop                             ; 1 byte

WD_Case1:   mov     z80registers.bc.lo, cl
            ret
            nop

WD_Case2:   mov     z80registers.de.hi, cl
            ret
            nop

WD_Case3:   mov     z80registers.de.lo, cl
            ret
            nop

WD_Case4:   mov     z80registers.hl.hi, cl
            ret
            nop

WD_Case5:   mov     z80registers.hl.lo, cl
            ret
            nop

WD_Case6:   jmp     WD_Case6_1          ; 2 bytes
            nop                         ; 6x1 bytes
            nop
            nop
            nop
            nop
            nop

WD_Case7:   mov     z80registers.af.hi, cl
            ret

WD_Case6_1: mov     bx, Reg_CBAbsAddr
            mov     al, cl
            POKEBYTE
            SETTS   3
            ret

;;############################################################################################

align 16
CB_RLC:
            FLAGS_MODIFIED  TRUE
            xor     dl,dl
            rol     al,1
            adc     dl,0                ; C to flags
            mov     Reg_CBDestVal,al
            test    al,255
            lahf
            and     ah, @FLAGS (SZV)    ; V as Parity
            or      dl,ah
            and     al,@FLAGS (53)
            or      dl,al
            mov     Reg_F,dl
            ret

;############################################################################################

align 16
CB_RRC:
            FLAGS_MODIFIED  TRUE
            xor     dl,dl
            ror     al,1
            adc     dl,0                ; C to flags
            mov     Reg_CBDestVal,al

            test    al,255
            lahf
            and     ah,@FLAGS (SZV)     ; V as Parity
            or      dl,ah
            and     al,@FLAGS (53)
            or      dl,al
            mov     Reg_F,dl
            ret

;############################################################################################

align 16
CB_RL:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            mov     dh, Reg_F
            ror     dh, 1                   ; set Carry as with Z80 Carry
            rcl     al, 1
            adc     dl, 0                   ; C to flags
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)        ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

align 16
CB_RR:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            mov     dh, Reg_F
            ror     dh, 1                    ; set Carry as with Z80 Carry
            rcr     al, 1
            adc     dl, 0                    ; C to flags
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)         ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F,dl
            ret

;############################################################################################

align 16
CB_SLA:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            sal     al, 1
            adc     dl, 0                    ; C to flags
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)         ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

align 16
CB_SRA:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            sar     al, 1
            adc     dl, 0                    ; C to flags
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)         ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

align 16
CB_SLL:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            shl     al, 1        ; this will clear bit 0 so an inc will set it
            adc     dl, 0        ; C to flags
            inc     al          ; Z80 shifts a 1 into Bit 0
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)     ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

align 16
CB_SRL:
            FLAGS_MODIFIED  TRUE
            xor     dl, dl
            shr     al, 1
            adc     dl, 0    ; C to flags
            mov     Reg_CBDestVal, al
            test    al, 255
            lahf
            and     ah, @FLAGS (SZV)     ; V as Parity
            or      dl, ah
            and     al, @FLAGS (53)
            or      dl, al
            mov     Reg_F, dl
            ret

;############################################################################################

; BIT opcodes
CB_BIT7:    mov     bl, 128
            call    TestBit
            .if     al == 1     ; if bit is set
                    or  Reg_F, FLAG_S
            .endif
            ret

CB_BIT0:    mov     bl, 1
            jmp     TestBit

CB_BIT1:    mov     bl, 2
            jmp     TestBit

CB_BIT2:    mov     bl, 4
            jmp     TestBit

CB_BIT3:    mov     bl, 8
            jmp     TestBit

CB_BIT4:    mov     bl, 16
            jmp     TestBit

CB_BIT5:    mov     bl, 32
            jmp     TestBit

CB_BIT6:    mov     bl, 64

TestBit:    FLAGS_MODIFIED  TRUE
            mov     DoingBitTest, 1
            mov     dl, al
            and     dl, @FLAGS (53)     ; bits 5+3 come from source
            mov     cl, Reg_F
            and     cl, NOT @FLAGS (S53N)
            or      cl, dl
            or      cl, FLAG_H

            and     al, bl
            setnz   al          ; al = 1 if bit is set, else 0 if bit is clear
            jnz     BitisSet

            or      cl, @FLAGS (ZV)
            mov     Reg_F, cl
            ret

BitisSet:   and     cl, NOT @FLAGS (ZV)
            mov     Reg_F, cl
            ret

;############################################################################################

CB_RES0:    and     al, 254
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES1:    and     al, 253
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret


CB_RES2:    and     al, 251
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES3:    and     al, 247
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES4:    and     al, 239
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES5:    and     al, 223
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES6:    and     al, 191
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_RES7:    and     al, 127
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

;############################################################################################

CB_SET0:    or      al, 1
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET1:    or      al, 2
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET2:    or      al, 4
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET3:    or      al, 8
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET4:    or      al, 16
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET5:    or      al, 32
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET6:    or      al, 64
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

CB_SET7:    or      al, 128
            mov     Reg_CBDestVal,al
            FLAGS_MODIFIED  FALSE
            ret

;############################################################################################

MemPushStack:   pushad
                lea     esi, RegisterBase
                call    PushStack
                popad
                ret

MemPopStack:    pushad
                lea     esi, RegisterBase
                call    PopStack
                popad
                ret


; PUSH ax onto the Z80 stack
align 16
PushStack:
            mov     bx, Reg_SP
            ror     ax, 8           ; swap low/high byte order
            dec     bx
            POKEBYTE                ; PUSH high byte
            SETTS   3
            dec     bx
            mov     al, ah          ; PUSH low byte
            POKEBYTE
            SETTS   3
            mov     Reg_SP, bx
            ret

;############################################################################################

; POP ax off the Z80 stack
align 16
PopStack:
            mov     bx, Reg_SP
            GETBYTE
            inc     bx
            mov     ah, al      ; ah = low byte
            SETTS   3
            GETBYTE             ; al = high byte
            inc     bx
            ror     ax, 8       ; swap low/high byte order
            SETTS   3
            mov     Reg_SP, bx
            ret

;############################################################################################

                      ; turn off indirect addressing here
                        USEESI  0

