
; save/load keyboard and IF2ROM SZX blocks

;                    SP_DISPLAYLINE SEGMENT PAGE PUBLIC FLAT 'CODE'
;                    [code]
;                    SP_DISPLAYLINE ENDS

; #########################################################################

    .686
    .mmx
    .model flat, stdcall
    option casemap :none   ; case sensitive

; #########################################################################

PACMAN              equ     1

.const
IDC_STATUS          equ     1

; version info -    use SPECEMU_FULLVERSIONSTR or SPECEMU_VERSIONSTR to get textual version data
SPECEMU_MAJOR       equ     3
SPECEMU_MINOR       equ     2
SPECEMU_VERNUMSTR   equ     <3.2>

;LOGGING             equ     TRUE   ; to "E:\SpecEmuLog.txt"
LOGOPCODES          equ     TRUE

WANTSOUND           equ     TRUE
SINGLEINSTANCE      equ     TRUE
ENABLEASSEMBLER     equ     TRUE

;FULLER_BOX          equ     TRUE   ;enabling breaks Multiface 128/3
FULLER_AY_REGISTER  equ     63
FULLER_AY_DATA      equ     95
FULLER_JOYSTICK     equ     127
FULLER_ORATOR_WR    equ     159

                    IFDEF   DEBUGBUILD
;SHOW_FPS            equ     TRUE
;ULATUNING           equ     TRUE
;KEYSTATE_INFO       equ     TRUE
                    ENDIF

AUTOTAPEPLAYFRAMES  equ     50
AUTOTAPEFRAMESKIP   equ     8

; Memory[Read/Write]Event equates:
MEMACCESSNONE       equ     0 ;0
MEMACCESSBYTE       equ     1 ;0
MEMACCESSWORD       equ     2 ;1

; Mapped Memory flags defined in SpecEmu.inc

MouseOn             MACRO
                    push    eax
                    invoke  ShowCursor,      TRUE
                    mov     MenuNoUnattach,  TRUE
                    mov     MouseNoUnattach, TRUE
                    pop     eax
                    ENDM

MouseOff            MACRO
                    push    eax
                    mov     MenuNoUnattach,  FALSE
                    mov     MouseNoUnattach, FALSE
                    invoke  ShowCursor,      FALSE
                    pop     eax
                    ENDM

STARTTIMER          MACRO
                    align 16
                    cpuid
                    cpuid
                    cpuid
                    cpuid
                    rdtsc
                    mov     edi, eax
                    mov     ebx, ebx ; nop
                    mov     edx, edx ; nop
                    ENDM         ; Tested code starts on 16 byte boundary

ENDTIMER            MACRO
                    cpuid
                    rdtsc
                    sub     eax, edi
                    ENDM        ; Result in eax

DISABLEINTS         MACRO
                    mov     currentMachine.iff1, FALSE
                    mov     currentMachine.iff2, FALSE
                    ENDM

ENABLEINTS          MACRO
                    mov     currentMachine.iff1, TRUE
                    mov     currentMachine.iff2, TRUE
                    ENDM

FULLSPEEDFRAMECOUNT equ     1   ; breaks shit like +3 floating bus when > 1

SPECCOLOURTABLESIZE equ     2*8*8*256*8
TIMEXCOLOURTABLESIZE equ    SPECCOLOURTABLESIZE*2
ULA64COLOURTABLESIZE equ    2*2*8*8*256*8

.code

;--------------------------------------------------------------------------------

UPDATEWINDOW        MACRO
                    invoke  InvalidateRect, hWnd, NULL, FALSE
                    invoke  UpdateWindow,   hWnd
                    ENDM

CLEARSOUNDBUFFERS   MACRO
                    IFDEF   WANTSOUND
                    call    ClearSoundBuffers
                    ENDIF
                    ENDM

; ##########################################################################

                        include     SpecEmu.inc
                        include     GenieZlib.inc
                        include     sebasic.inc
                        include     gdos-pd.inc
                        include     AutoloadSnaps.inc
                        include     Macros.inc
                        include     Protos.inc
                        include     Vars.inc

.code
                        include     Messages.asm
                        include     CommandLine.asm

; ##########################################################################
; PROTOs
PrepSpecColourTables    PROTO
PrepTimexColourTables   PROTO
PrepULA64ColourTables   PROTO

MaskSpeccyCorners       PROTO
TopXY                   PROTO       :DWORD,:DWORD
SetClientSize           PROTO       :HWND,:DWORD,:DWORD

AddMainWinToolBar       PROTO       :HWND
AddMainWinStatus        PROTO       :HWND
SetStatusPartSizes      PROTO       :HWND,:HWND,:DWORD,:DWORD
SetStatusPartText       PROTO       :HWND,:DWORD,:DWORD
SetMachineStatusBar     PROTO

GetFilePath             PROTO       :DWORD,:DWORD
GetFN_Hook              PROTO       :DWORD,:DWORD,:DWORD,:DWORD

SaveTempSZXFile         PROTO
LoadTempSZXFile         PROTO
DeleteTempSZXFile       PROTO

SZXSaveTapeBlockDialogProc  PROTO   :DWORD,:DWORD,:DWORD,:DWORD

LoadTRDosROM            PROTO

LoadRegsFromSNASNX      PROTO
SaveRegsToSNASNX        PROTO

; ##########################################################################
dwStyle                 equ     WS_CAPTION or WS_POPUPWINDOW or WS_OVERLAPPEDWINDOW or WS_SIZEBOX or WS_VISIBLE
dwExStyle               equ     WS_EX_LEFT or WS_EX_ACCEPTFILES

;; HardwareMode definitions:-
;; --------------------------
;                        RESETENUM   0
;
;                        ENUM    HW_16, HW_48
;                        ENUM    HW_128, HW_PLUS2
;                        ENUM    HW_PLUS2A, HW_PLUS3
;                        ENUM    HW_PENTAGON128
;                        ENUM    HW_TC2048
;                        ENUM    HW_TK90X
;
;                        ENUM    HW_ENDLIST
;
;HW_FIRSTMACHINE         EQU     HW_16
;HW_LASTMACHINE          EQU     HW_ENDLIST - 1

IDM_FIRSTMACHINE        equ     IDM_HW16k
IDM_LASTMACHINE         equ     IDM_TK90X

BEEPERHIGH              equ     7500
BEEPERCENTRE            equ     BEEPERHIGH/2
BEEPERLOW               equ     0
BEEPERMICBOOST          equ     1200

EarHighVal              EQU     2000
EarLowVal               EQU     0
MICHighVal              EQU     3750
MICLowVal               EQU     0

; ########################################################################

; Constant data area.
; ============================================================
.const
; max size of the backbuffer
DIBWidth                equ 96+512+96   ; width  of our 8 bit DIB
DIBHeight               equ 296         ; height of our 8 bit DIB

;DDWidth                 equ 3840        ; directdraw fullscreen dimensions
;DDHeight                equ 2160
DDWidth                 equ 640         ; directdraw fullscreen dimensions
DDHeight                equ 480
DDBpp                   equ 32 ;16

SPECEMU_FULLVERSIONSTR  db  "Version "
%SPECEMU_VERSIONSTR     db  "&SPECEMU_VERNUMSTR",0

builddate               catstr  <">,@Date,<">
SPECEMU_BUILDDATE       db  "Build ",builddate,0

Rom48Filename           db  "48.rom", 0
Rom128Filename          db  "128.rom", 0
RomPlus2Filename        db  "plus2.rom", 0
RomPlus3Filename        db  "plus3.rom", 0
;RomPlus3Filename        db  "plus3.41.rom", 0
;RomPlus3Filename        db  "plus3-spanish.rom", 0
RomTK90xFilename        db  "tk90x.rom",0

RomPentagon128Filename  db  "pentagon128.rom", 0
RomTrdosFilename        db  "trdos.rom", 0
RomTC2048Filename       db  "tc2048.rom", 0
Mf48Filename            db  "MF1.rom", 0
Mf128Filename           db  "MF128.rom", 0
Mf3Filename             db  "MF3.rom", 0
RomMicroSourceFilename  db  "MicroSource.rom", 0

Rom_CBIFilename         db  "CBI-24.BIN", 0
;Rom_CBIFilename         db  "CAS-1987-16K.BIN", 0

GETMODELNAME            macro   reg32:REQ
                        movzx   reg32, HardwareMode
                        mov     reg32, [_MachineNames_+reg32*4]
                        endm

                        STRINGLIST  _MachineNames_, \
                                    "ZX Spectrum 16K",  "ZX Spectrum 48K",  \
                                    "ZX Spectrum 128K", "ZX Spectrum +2",   \
                                    "ZX Spectrum +2A",  "ZX Spectrum +3",   \
                                    "Pentagon 128K",                        \
                                    "Timex TC2048",     "TK90X"

_ZXTape_str             db      "ZXTape!",26
SZXExt                  db      "szx",0
Z80Ext                  db      "z80",0
SNAExt                  db      "sna",0
TAPExt                  db      "tap",0
TZXExt                  db      "tzx",0
DSKExt                  db      "dsk",0
SCRExt                  db      "scr",0
WAVExt                  db      "wav",0
HDFExt                  db      "hdf",0
ROMExt                  db      "rom",0
RZXExt                  db      "rzx",0
LOGExt                  db      "log",0
ASMExt                  db      "asm",0
MAPExt                  db      "map",0
NullExt                 LABEL   BYTE
NULL_String             db      0
debugstart              db      "Debug Start",0
debugend                db      "Debug End",0

; Initialised data area.
; ============================================================
.data
SwitchingModes          db      FALSE
WindowSizeMove          db      FALSE
MessageBoxDisplayed     db      FALSE   ; True when a messagebox is displayed by ShowMessageBox function; disallows WM_COPYDATA when True

; vars which *must* be pre-initialised
align 4
_tapfileptr             dd      0
WorkFH                  HANDLE  0
TapeFileHandle          HANDLE  0
AudioFH                 HANDLE  0

gl_Courier_New_6        dd      0
gl_Courier_New_9        dd      0


; DIB BITMAPINFO structure
BITMAPINFO_struct       dd      sizeof BITMAPINFOHEADER
                        dd      DIBWidth
                        dd      -DIBHeight
                        dw      1
                        dw      8       ; bits per pixel
                        dd      BI_RGB
                        dd      0       ; size image
                        dd      200
                        dd      200
                        dd      33
                        dd      33

SpectrumPalette         dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        dd      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BITMAPINFOSIZE          equ     $-BITMAPINFO_struct

NUMENTRIES              equ     16

                            ; 16 - 31 = Spectrum colours
SpectrumColours         dd      00000000h, 000000CCh, 00CC0000h, 00CC00CCh, 0000CC00h, 0000CCCCh, 00CCCC00h, 00CCCCCCh
                        dd      00000000h, 000000FFh, 00FF0000h, 00FF00FFh, 0000FF00h, 0000FFFFh, 00FFFF00h, 00FFFFFFh

CLR_SPECBASE            equ     16                  ; colour offset for 32 Spectrum colours (4 bright levels * 8 colours)
CLR_MASKEDCORNER        equ     CLR_SPECBASE + 32   ; masked corners are black

.data?
align 16
                        ; table of 256 colours
                        ; 0 - 15  : reserved for GDI
                        ; 16 - 31 : Spectrum colour table depth converted to BPP
ddSurfacePalette        DWORD   256  DUP (?)
ddULAplusPalette        DWORD   256  DUP (?)


align 4
WindowRect              RECT    <?>     ; window rect when switching window/fullscreen modes

TimerID_1sec            DWORD   ?
TIMER_1_SECOND          equ     1

hCopyDataStruct         COPYDATASTRUCT  <?>

hClipboardData          HANDLE  ?

align 4
DebugResult             DWORD   ?

Time1                   DWORD   ?
TimeTook                DWORD   ?

AudioFileLength         DWORD   ?     ; num bytes written to audio file
TickCnt                 DWORD   ?
MenuHandle              DWORD   ?
MenuTimeout             DWORD   ?
displayptr              DWORD   ?

initZ80PC               WORD    ?

MenuAttached            BYTE    ?
MenuNoUnattach          BYTE    ?
MouseNoUnattach         BYTE    ?
MenuIgnoreMouseMoveCnt  BYTE    ?

ActiveState             BYTE    ?  ; TRUE = App is active Else App is inactive; based on WM_ACTIVATE message

TargetDrive             BYTE    ?  ; Drive unit for the disk to be inserted to

align 4
FDCHandle               LPFDCHANDLE ?
IDEHandle               DWORD   ?
TRDOSHandle             DWORD   ?
CBIHandle               DWORD   ?
PLUSDHandle             DWORD   ?

MAXTZXBLOCKS            equ     16384
TZXBlockPtrs            DWORD   ?
TZXBlockCount           WORD    ?

align 4
CompatibleDC            DWORD   ?
lpDIBSection            DWORD   ?
lpDIBBits               DWORD   ?   ; ptr to DIB bits for direct access
lpEndDIBBits            DWORD   ?   ; ptr to end of DIB bitmap
lpBITMAPINFO            DWORD   ?

winWidth                DWORD   ?
winHeight               DWORD   ?
sWid                    DWORD   ?
sHgt                    DWORD   ?

winClientRect           RECT    <?>
mainwin_hToolBar        HWND    ?
mainwin_hStatus         HWND    ?
MinimumWidth            DWORD   ?
MinimumHeight           DWORD   ?
ToolBarHeight           DWORD   ?
StatusHeight            DWORD   ?
GlobalhInst             DWORD   ?
PCLog_FH                DWORD   ?
Filename                DWORD   ?
ReadStart               DWORD   ?
ReadLen                 DWORD   ?
WriteStart              DWORD   ?
WriteLen                DWORD   ?
hCursor                 DWORD   ?
TickCount               DWORD   ?
inhibit_recent_file     DWORD   ?   ; TRUE inhibits an entry being added into the recent files list

oldzPC                  WORD    ?
ShowDebugzPC            WORD    ?

OldFrameSkipCounter     BYTE    ?
Snapshot_OK             BYTE    ?
LoadError               BYTE    ?
RealTapeSaveSpeed       BYTE    ?   ; TRUE = emulating normal tape saving speed
NewKey                  BYTE    ?
UsePrevzPC              BYTE    ?
SpecKey                 BYTE    ?
FirstFrame              BYTE    ?   ; TRUE = Draw blank scanlines if in fullscreen mode
Sound_Available         BYTE    ?
trdos_active_frames     BYTE    ?

GotMultiface48Rom       BYTE    ?   ; TRUE if Multiface 48 Rom file is present
GotMultiface128Rom      BYTE    ?   ; TRUE if Multiface 128 Rom file is present
GotMultiface3Rom        BYTE    ?   ; TRUE if Multiface 3 Rom file is present
MultifacePaged          BYTE    ?   ; TRUE when Multiface ROM is paged in
Multiface_LockOut       BYTE    ?   ; TRUE when Multiface paging is locked out (default on reset until first NMI)
SoftRomPaged            BYTE    ?   ; TRUE when SoftRom RAM is paged in
MicroSourcePaged        BYTE    ?   ; TRUE when SoftRom RAM is paged in
TrDos_Paged             BYTE    ?   ; TRUE when TRDOS ROM is paged in
PLUSD_Paged             BYTE    ?   ; TRUE when the +D ROM is paged in
uSpeech_Paged           BYTE    ?   ; TRUE when uSpeech ROM is paged in
uSpeechStatus           BYTE    ?   ; uSpeech status register

align 4
uSpeech_Ticks           DWORD   ?

uSpeech_Output          WORD    ?
Covox_Output            WORD    ?
SpecDrum_Output         WORD    ?

Covox_LastVol           BYTE    ?   ; used when saving to Covox SZX blocks
SpecDrum_LastVol        BYTE    ?   ; used when saving to SpecDrum SZX blocks
SafeRun                 BYTE    ?   ; TRUE when emulator frames are safe to run in main message loop
EmuRunning              BYTE    ?

AutoTapeStarted         BYTE    ?
AutoTapeStopFrames      BYTE    ?   ; no. of frames before auto tape stop

sna_snx_header          BYTE    27  dup (?)

.code
                        include C:\RadAsm\Masm\Projects\CustomControls\RawText\RawText.asm

.data?
align 4
iccex                   INITCOMMONCONTROLSEX    <?>

;--------------------------------------------------------------------------------
; Program entry point
.code

start:
                mov     have_mmx, $fnc (IsProcessorFeaturePresent, PF_MMX_INSTRUCTIONS_AVAILABLE)

                invoke  GetCurrentDirectory, sizeof startup_currentdirectory, addr startup_currentdirectory
                invoke  GetAppPath, addr appPath

                ; see if Pasmo assembler is present in SpecEmu's directory
                invoke  szMultiCat, 2, addr DummyMem, offset appPath, CTXT ("pasmo.exe")
                mov     have_pasmo, $fnc (exist, addr DummyMem)

                IFDEF   PACMAN
                        invoke  GetPacmanFilepath, addr pacmanfilepath

                        invoke  LoadPacmanROMs
                        IFDEF   DEBUGBUILD
                                .if     eax == FALSE
                                        invoke  ShowMessageBox, $fnc (GetActiveWindow), SADD ("Pac-Man ROMs missing or incorrect set"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                .endif
                        ENDIF
                ENDIF   ; /PACMAN

                mov     iccex.dwICC, ICC_WIN95_CLASSES or ICC_STANDARD_CLASSES or ICC_USEREX_CLASSES
                mov     iccex.dwSize, sizeof (INITCOMMONCONTROLSEX)
                invoke  InitCommonControlsEx, addr iccex

                invoke  InitRawTextControl

                mov     hScintilla, $fnc (LoadLibrary, SADD ("Scintilla.dll"))
                .if     hScintilla == NULL
                        FATAL   "Scintilla.dll could not be loaded"
                .endif

                mov     hInstance,   $fnc (GetModuleHandle, NULL)
                mov     CommandLine, $fnc (GetCommandLine)
                mov     hIcon,       $fnc (LoadIcon, hInstance, 20000)    ; "spectrum.ico" - icon ID
                mov     hCursor,     $fnc (LoadCursor, NULL, IDC_ARROW)

                mov     sWid,        $fnc (GetSystemMetrics, SM_CXSCREEN)
                mov     sHgt,        $fnc (GetSystemMetrics, SM_CYSCREEN)

                mov     ProcessID,   $fnc (GetCurrentProcessId)
                invoke  dw2hex, ProcessID, addr szProcessID

                invoke  GetWindowDC, $fnc (GetDesktopWindow)
                .if     eax != NULL
                        push    ebx
                        mov     ebx, eax
                        invoke  GetSystemPaletteEntries, ebx, 0, 256, addr SpectrumPalette
                        invoke  ReleaseDC, $fnc (GetDesktopWindow), ebx
                        pop     ebx
                .endif
                memcpy  addr SpectrumColours, addr SpectrumPalette+(16*4), NUMENTRIES

                invoke  ExitProcess, $fnc (WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT)

; ########################################################################

; special TZX block IDs for external files
BLOCK_WAV       equ     0A0h
BLOCK_CSW       equ     0A1h

                include z80assembler.asm

                include uSpeech.asm
                include Machines.inc

                IFDEF   WANTSOUND
                include DirectSound.asm     ; DirectSound API stuff
                ENDIF

                include SoundCapture.asm

                include atapi.asm
                include DivIDE.asm
                include wd1793.asm

                include MainOptions.asm     ; main options propertysheet handlers
                include Tools1.asm
                include MainWinMemoryViewer.asm
                include PLUS-D.asm

                include Keyboard.asm
                include Joystick.asm

                include DisplayRecording.asm

                include DirectDraw.asm
                include Palettes.asm        ; palette handling code
                include PaletteULAplus.asm  ; ULAplus palette handling code

                include Z80Macros.inc       ; Z80 support macros and functions
                include Display.asm         ; Spectrum display renderer
                include Z80Core.asm         ; Z80 Emulation Core
                include PortRead.asm
                include PortWrite.asm

                include RunFrame.asm
                include DialogHandlers.asm  ; other dialog handlers
                include Machines.asm
                include Debugger.asm
                include Compare.asm

                include RZX_BlockLists.asm
                include RZX_Play.asm
                include RZX_Record.asm
                include RZX_Stream.asm
                include RZX_Finalise.asm

                include DrawIcons.asm

                include TapeHandling.asm
                include IniProfile.asm
                include RecentFiles.asm
                include Opcodes.asm         ; opcode mnemonics for disassembler

                include PCLogging.asm
                include Assembler.asm

                include CreateTape.asm

                include Pacman.asm

                include x86gen.asm

                include Snapshots\Format_SZX.asm

; ########################################################################

WinMain         proc    uses        ebx esi edi,
                        hInst:      DWORD,
                        hPrevInst:  DWORD,
                        CmdLine:    DWORD,
                        CmdShow:    DWORD

                local   wc:         WNDCLASSEX
                local   msg:        MSG
                local   hMutex:     DWORD
                local   hPrevWnd:   DWORD

                local   temp1:      DWORD

; ##################################################

                invoke  OleInitialize, NULL
                .if     eax != S_OK
                        LOG     "OleInitialize ne S_OK"
                .endif

                invoke  SetAppDataPath

                mov     SafeRun, FALSE
                mov     hMutex, NULL

                IFDEF   SINGLEINSTANCE
                ; the control key bypasses the single instance code
                invoke  GetAsyncKeyState, VK_CONTROL
                test    ax, 8000h
                .if     ZERO?
                        mov     hMutex, $fnc (CreateMutex, NULL, TRUE, SADD ("_T_SpecEmu_0A33-4644-SpecEmu-6721"))
                        invoke  GetLastError
                        .if     eax == ERROR_ALREADY_EXISTS
                                ; we have another running instance
                                mov     hPrevWnd, $fnc (FindWindow, addr szClassName, NULL)
                                .if     hPrevWnd != NULL
                                        .if     $fnc (IsIconic, hPrevWnd) != NULL
                                                invoke  ShowWindow, hPrevWnd, SW_RESTORE
                                        .endif
                                        invoke  SetForegroundWindow, hPrevWnd
                                        ; pass any arg to previous instance
                                        .if     $fnc (getcl_ex, 1, addr szFileName) == 1
                                                mov     [hCopyDataStruct.dwData], "SPEC"
                                                mov     [hCopyDataStruct.cbData], sizeof szFileName
                                                mov     [hCopyDataStruct.lpData], offset szFileName
                                                invoke  SendMessage, hPrevWnd, WM_COPYDATA, NULL, addr hCopyDataStruct
                                        .endif
                                .endif
                                return  FALSE   ; exit this instance

                        .elseif eax != ERROR_SUCCESS
                                FATAL   "Internal Mutex error"
                                return  FALSE
                        .endif

                .endif
                ENDIF

                m2m     GlobalhInst, hInst

                .if     $fnc (Atapi_LoadDLL) == FALSE
                        FATAL   "atapi.dll unavailable or incorrect version"
                .endif

                .if     $fnc (wd1793_LoadDLL) == FALSE
                        FATAL   "wd1793.dll unavailable or incorrect version"
                .endif

                IDE_Initialise              ; initialise any hard disk image
                mov     IDEHandle, eax

                wd1793_Initialise
                mov     TRDOSHandle, eax

                wd1793_Initialise
                mov     PLUSDHandle, eax

                wd1793_Initialise
                mov     CBIHandle, eax

                call    AllocateResources
                .if     eax == FALSE
                        call    FreeResources       ; free up resources that were allocated before the failure
                        FATAL   "Couldn't allocate resources"
                .endif

                call    ReadProfile
                invoke  SetFileAssociations

                ; after reading saved profile options we can insert any previously selected IDE Hard Disk files
                IDE_SelectHDF   IDEHandle, 0, offset IDEUnit0Filename
                IDE_SelectHDF   IDEHandle, 1, offset IDEUnit1Filename
                ; and select the DivIDE Firmware selected
                invoke  DivIDE_LoadFirmware

                invoke  SetDirtyLines
                invoke  SetDisplayTable

                invoke  LoadCustomPalettes

                call    LoadFiles
                .if     LoadError == TRUE
                        FATAL   "ROM file(s) missing from application folder"
                .endif

                invoke  u765_Initialise
                mov     FDCHandle, eax

                invoke  SetUserConfig   ; set user's config settings before reset

                call    InitPort

                call    ClearDIB

                mov     EmuRunning, TRUE
                mov     SPGfx.FrameCnt, 0
                mov     SPGfx.FlashInverterByte, 0

                mov     FirstFrame, TRUE

                mov     AYTimer, 0
                mov     SampleTimer, 0
                mov     TVRandomSeed, 1

                mov     ActiveState, TRUE

                ;==================================================
                ; Fill WNDCLASSEX structure with required variables
                ;==================================================

                mov     wc.cbSize,          sizeof WNDCLASSEX
                mov     wc.style,           CS_HREDRAW or CS_VREDRAW
                mov     wc.lpfnWndProc,     offset WndProc
                mov     wc.cbClsExtra,      NULL
                mov     wc.cbWndExtra,      NULL
                m2m     wc.hInstance,       hInst

                mov     wc.hbrBackground,   $fnc (GetStockObject, LTGRAY_BRUSH)
                mov     wc.lpszMenuName,    NULL
                mov     wc.lpszClassName,   offset szClassName
                m2m     wc.hIcon,           hIcon
                m2m     wc.hIconSm,         hIcon
                m2m     wc.hCursor,         hCursor

                invoke  RegisterClassEx,    addr wc

                mov     DesktopBPP, $fnc (GetDesktopBPP)    ; get desktop colour depth for rendering

                mov     hWnd, $fnc (CreateWindowEx, dwExStyle, addr szClassName, addr szWindowName, dwStyle, 0, 0, 0, 0, NULL, NULL, hInst, NULL)
                .if     eax == NULL
                        call    FreeResources               ; free up allocated resources
                        FATAL   "Failed to create main window"
                .endif

                invoke  LoadRecentFileList

                invoke  NewList, addr PageTableList

                invoke  NewList, addr RZXPLAY.BlockList
                invoke  NewList, addr RZXREC.BlockList
                mov     rzx_mode, RZX_NONE
                invoke  RZX_EnableMenuItems

                invoke  GetWindowRect, hWnd, addr WindowRect    ; save the window position


              ; We must initialise DirectDraw before DirectSound
                mov     FullScreenMode, FALSE       ; directdraw starts in windowed mode
                invoke  InitDirectDraw
                invoke  InitSurfaces, hWnd

                IFDEF   WANTSOUND
                mov     MACHINE.FramesPerSecond, 50 ; valid FPS for initial directsound buffer size
                call    StartupDirectSound
                call    InitAudio
                ENDIF

                ; reset has to come after audio initialised
                mov     al, HardwareMode    ; initial value read by 'ReadProfile'
                invoke  Machine_Create, addr currentMachine, al
                .if     eax == False
                        FATAL   "Cannot create a Spectrum machine instance"
                .endif

                mov     HardReset, TRUE
                call    ResetSpectrum

                invoke  ShowWindow,   hWnd, CmdShow
                invoke  UpdateWindow, hWnd

                call    InitTape

                ; ===== simple startup hardware sanity checks =====
                ifc     HardwareMode    gt HW_PLUS3 then mov DivIDEEnabled,  FALSE
                ifc     DivIDEEnabled   eq TRUE     then mov PLUSD_Enabled,  FALSE
                ifc     PLUSD_Enabled   eq TRUE     then mov CBI_Enabled,    FALSE
                ifc     CBI_Enabled     eq TRUE     then mov SoftRomEnabled, FALSE
                ifc     SoftRomEnabled  eq TRUE     then mov MultifaceEnabled, FALSE else mov MultifaceEnabled, TRUE
                ; ===== end simple startup hardware sanity checks =====

                mov     MultifacePaged,   FALSE     ; multiface memory not paged in
                mov     SoftRomPaged,     FALSE     ; softrom memory not paged in
                mov     MicroSourcePaged, FALSE     ; microsource ROM not paged in
                mov     PLUSD_Paged,      FALSE     ; +D ROM not paged in
                mov     uSpeech_Paged,    FALSE     ; uSpeech ROM not paged in

                invoke  ResetJoystickStates

                mov     SoftRomDlg, $fnc (CreateDialogParam, hInst, IDD_SOFTROM, hWnd, addr SoftRomDialogProc, NULL)
                ifc     SoftRomEnabled eq TRUE then invoke ShowWindow, SoftRomDlg, SW_SHOW

                ; create the Messages dialog and show it in Debug build
                mov     MessagesDlg, $fnc (CreateDialogParam, hInst, IDD_MESSAGESDLG, hWnd, addr MessagesDialogProc, NULL)
                IFDEF   DEBUGBUILD
                        invoke  ShowWindow, MessagesDlg, SW_SHOW
                ENDIF




                invoke  x86_Breakpoint





                ; handle command line parameters (this needs doing before Tools1 dialog is created which steals CurrentDirectory setting)
                invoke  Handle_Command_Line

                mov     Tools1Dlg,     $fnc (CreateDialogParam, hInst, IDD_TOOLS1,              hWnd,   addr Tools1DialogProc,          NULL)
                mov     MW_MemViewDlg, $fnc (CreateDialogParam, hInst, IDD_MAINWINMEMVIEWDLG,   hWnd,   addr MainWinMemViewDialogProc,  NULL)
                mov     AssemblerDlg,  $fnc (CreateDialogParam, hInst, IDD_ASSEMBLERDLG,        hWnd,   addr AssemblerDialogProc,       NULL)

                invoke  SetFocus, hWnd


                IFDEF   LOGGING
                invoke  ShowMessageBox, hWnd, SADD ("Logging is enabled in this build"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                ENDIF

                .if     StartFullscreen == TRUE
                        invoke  FlipDisplayMode
                        invoke  AttachMenu, hWnd
                .endif

                mov     SafeRun, TRUE   ; always last thing before entering message loop

                ;===================================
                ; Loop until PostQuitMessage is sent
                ;===================================

                mov     TickCount, $fnc (GetTickCount)

StartLoop:
                .if     $fnc (PeekMessage,  addr msg, NULL, 0, 0, PM_REMOVE) != 0

                        cmp     msg.message, WM_QUIT
                        je      ExitLoop    ; received WM_QUIT

                        invoke  TranslateMessage, addr msg
                        invoke  DispatchMessage,  addr msg
                        jmp     StartLoop
                .else
                        .if     EmuRunning == FALSE
                                .if     (SPGfx.FrameBlit == TRUE) && (SurfacesReady == TRUE)
                                        invoke  BlitScreen, hWnd
                                        ifc     eax eq DD_OK then mov SPGfx.FrameBlit, FALSE
                                        invoke  Sleep, 1
                                .else
                                        invoke  WaitMessage
                                        invoke  GetPausedKeyState   ; check for message window combo
                                .endif
                                jmp     StartLoop
                        .endif

                        .if     ActiveState == FALSE
                                .if     (FullScreenMode == TRUE) || (Pause_On_Lost_Focus == TRUE)
                                        invoke  WaitMessage
                                        jmp     StartLoop
                                .endif
                        .endif

                        .if     (SafeRun == TRUE) && (WindowSizeMove == FALSE)

                                ; if logging, register values are dumped before the first opcode of each frame
                                mov     InitialLogOpcode, TRUE

                                .if     rzx_mode != RZX_NONE
                                        .if     rzx_mode == RZX_PLAY
                                                invoke  ExecTaskQueueTask   ; execute any pending queued tasks in RZX playback frame code (suspended if emulator paused)

                                                invoke  RZX_Play_Frame
                                        .else
                                                invoke  GetSpeccyInputStates
                                                invoke  RZX_Rec_Frame
                                        .endif

                                .elseif (RunDebugFrame1 == NULL) && (RunDebugFrame2 == NULL)
                                        invoke  ExecTaskQueueTask   ; execute any pending queued tasks in normal frame code (suspended if emulator paused)

                                        invoke  GetSpeccyInputStates

                                        call    Run_Frame

;                                        invoke  MW_Populate_Memory  ; re-populates main win memory viewer if enabled
                                .else
                                        invoke  GetSpeccyInputStates

                                        invoke  Run_DebugFrame
                                        .if     eax == TRUE
                                                ; a trap causes the debugger to activate
                                                ; simulated by a forced ESC keypress
                                                invoke  PostMessage, hWnd, WM_KEYDOWN, VK_ESCAPE, "BRK" ; debugger traps always set lParam to "BRK"
                                        .endif
                                .endif

                                .if     SPGfx.FrameChanged == TRUE
                                        mov     SPGfx.FrameChanged, FALSE

                                        ifc     RecordingFrames eq TRUE then invoke RecordFrameDataFile
                                        mov     SPGfx.FrameBlit, TRUE

                                        ifc     FullScreenMode eq TRUE then invoke MaskSpeccyCorners

                                        .if     SurfacesReady == TRUE
                                                invoke  DIBToScreen, hWnd
                                                ifc     eax eq DD_OK then mov SPGfx.FrameBlit, FALSE
                                        .endif
                                .else
                                        ; else handle any pending screen updates or the vertical offset scrolling
                                        .if     (SPGfx.FrameBlit == TRUE) || (SPGfx.VerticalOffset > 0)
                                                .if     SurfacesReady == TRUE
;                                                        invoke  BlitScreen, hWnd
                                                        invoke  DIBToScreen, hWnd
                                                        ifc     eax eq DD_OK then mov SPGfx.FrameBlit, FALSE
                                                .endif
                                        .endif
                                .endif

                                ifc     MAXIMUMDISKSPEED gt 0 then dec MAXIMUMDISKSPEED

                                IFNDEF  WANTSOUND
                                .if     FULLSPEEDMODE != NULL
                                        mov     TickCount, $fnc (GetTickCount)
                                .else
                                        movzx   eax, FrameSkipCounter
                                        mov     ecx, 20
                                        mul     ecx
                                        add     TickCount, eax
                                        invoke  GetTickCount
                                        .while  eax < TickCount
                                                invoke  Sleep, 1
                                                invoke  GetTickCount
                                        .endw
                                        mov     TickCount, eax
                                .endif
                                ELSE
                                .if     (MuteSound == TRUE) || (Sound_Available == FALSE)
                                        .if     (FULLSPEEDMODE != NULL) || ((TapePlaying == TRUE) && (FastTapeLoading == TRUE))
                                                mov     TickCount, $fnc (GetTickCount)
                                        .else
                                                movzx   eax, FrameSkipCounter
                                                mov     ecx, 20
                                                mul     ecx
                                                add     TickCount, eax
                                                invoke  GetTickCount
                                                .while  eax < TickCount
                                                        invoke  Sleep, 1
                                                        invoke  GetTickCount
                                                .endw
                                                mov     TickCount, eax
                                        .endif
                                .endif
                                ENDIF
                        .endif
                        jmp     StartLoop
                .endif

ExitLoop:       invoke  Stop_PC_Logging

                LOG     "Exiting SpecEmu"
                invoke  DestroyIcon, hIcon

                ifc     hMutex ne NULL then invoke ReleaseMutex, hMutex

                invoke  OleUninitialize

                return  msg.wParam

WinMain         endp

; #########################################################################

                include WndProc.asm


PauseResumeEmulation    proc    uses    ebx

                        CLEARSOUNDBUFFERS
                        movzx   ebx, EmuRunning
                        xor     EmuRunning, TRUE
                        invoke  SendMessage, mainwin_hToolBar, TB_CHECKBUTTON, IDM_PAUSE, ebx

                        .if     DebuggerActive == TRUE
                                invoke  SendMessage, hDbgToolBar, TB_CHECKBUTTON, IDM_PAUSE, ebx
                        .endif
                        ret

PauseResumeEmulation    endp


; resizes the client area of the passed window handle to the requested size

SetClientSize   proc    uses        esi edi,
                        hWin:       HWND,
                        w_Width:    DWORD,
                        w_Height:   DWORD

                local   nWindowDx:  DWORD,
                        nWindowDy:  DWORD

                local   Rct:        RECT,
                        ClientRect: RECT,
                        DesktopRect:RECT

                local   rClient:    RECT

                invoke  GetWindowRect, [hWin], addr Rct

                mov     eax, ToolBarHeight
                add     w_Height, eax

                mov     eax, StatusHeight
                add     w_Height, eax

                mov     [ClientRect.left],   0
                mov     [ClientRect.top],    0
                m2m     [ClientRect.right],  w_Width
                m2m     [ClientRect.bottom], w_Height

                invoke  AdjustWindowRectEx, addr ClientRect, dwStyle, TRUE, dwExStyle
                mov     esi, @EVAL (ClientRect.right - ClientRect.left)
                mov     edi, @EVAL (ClientRect.bottom - ClientRect.top)
                invoke  SetWindowPos, hWin, HWND_NOTOPMOST, 0, 0, esi, edi, SWP_NOMOVE

                ; get the actual client rectangle
                invoke  GetClientRect, hWin, addr rClient

                ; ensure the client area is exactly what we wanted, and adjust it if not
                ; this can happen if a menu wraps because the window is small, or on buggy Vista versions
                mov     esi, rClient.right
                mov     edi, rClient.bottom
                .if     (esi != w_Width) || (edi != w_Height)
                        mov     esi, @EVAL (w_Width - esi + ClientRect.right - ClientRect.left)
                        mov     edi, @EVAL (w_Height - edi + ClientRect.bottom - ClientRect.top)
                        invoke  SetWindowPos, hWin, HWND_NOTOPMOST, 0, 0, esi, edi, SWP_NOMOVE
                .endif

                invoke  GetWindowRect, [hWin], addr Rct
                invoke  SystemParametersInfo, SPI_GETWORKAREA, NULL, addr DesktopRect, NULL

                mov     eax, [Rct.right]
                sub     eax, [DesktopRect.right]
                .if     !CARRY?
                        sub     [Rct.left], eax
                        .if     CARRY?
                                mov     [Rct.left], 0
                        .endif
                .endif

                mov     eax, [Rct.bottom]
                sub     eax, [DesktopRect.bottom]
                .if     !CARRY?
                        sub     [Rct.top], eax
                        .if     CARRY?
                                mov     [Rct.top], 0
                        .endif
                .endif

                invoke  SetWindowPos, hWin, HWND_NOTOPMOST, [Rct.left], [Rct.top], 0, 0, SWP_NOSIZE
                UPDATEWINDOW
                ret

SetClientSize   endp

TopXY           proc    wDim:DWORD, sDim:DWORD

                shr     sDim, 1      ; divide screen dimension by 2
                shr     wDim, 1      ; divide window dimension by 2
                mov     eax, wDim    ; copy window dimension into eax
                sub     sDim, eax    ; sub half win dimension from half screen dimension
                return  sDim

TopXY           endp

; #########################################################################

SwitchModel     proc    NewModel:   BYTE

                mov     al, NewModel
                mov     HardwareMode, al
                call    ResetSpectrum
                ret
SwitchModel     endp

ResetSpectrum:
                IFDEF   PACMAN
                invoke  Disable_Pacmode
                ENDIF

;                invoke  GetUserConfig   ; gets user's current machine config

                memset  addr PC_History.Table, sizeof PC_History.Table, -1
                mov     PC_History._Offset, 0

                call    Speaker_Low

                DISABLEINTS
                xor     eax, eax
                mov     z80registers.intmode, al
                mov     z80registers.i, al
                mov     z80registers.r, al
                mov     z80registers.r_msb, al
                mov     zPC, ax
                mov     Z80PC, ax

                mov     HALTED, FALSE

;                dec     eax        ; all must be zero for Esxdos under DivIDE to function correctly
                mov     z80registers._sp,   ax
                mov     z80registers.af.w,  ax
                mov     z80registers.bc.w,  ax

                mov     z80registers.de.w,  ax
                mov     z80registers.hl.w,  ax
                mov     z80registers.af_.w, ax
                mov     z80registers.bc_.w, ax
                mov     z80registers.de_.w, ax
                mov     z80registers.hl_.w, ax
                mov     z80registers.ix.w,  ax
                mov     z80registers.iy.w,  ax

                ifc     HardwareMode gt HW_LASTMACHINE then mov HardwareMode, HW_16

                .if     HardReset
                        invoke  FuzzScreenMemory
                        ifc     DivIDEEnabled then invoke DivIDE_Initialise, TRUE
                        ifc     PLUSD_Enabled then invoke PLUSD_PreloadRAMImage

                        .if     Dodgy_TV_Enabled
                                mov     SPGfx.VerticalOffset, 255
                                mov     SPGfx.TVNoiseCounter, 15    ; TV display noise for 15 frames
                        .endif
                .endif

                invoke  EnableMultifaceOrSoftRom

                mov     al, HardwareMode
                .if     al == HW_16
                        call  Reset_16K
                .elseif al == HW_48
                        call  Reset_48K
                .elseif al == HW_128
                        call  Reset_128K
                .elseif al == HW_PLUS2
                        call  Reset_Plus2
                .elseif al == HW_PLUS2A
                        call  Reset_Plus2A
                .elseif al == HW_PLUS3
                        call  Reset_Plus3
                .elseif al == HW_PENTAGON128
                        call  Reset_Pentagon
                .elseif al == HW_TC2048
                        call  Reset_TC2048
                .elseif al == HW_TK90X
                        call  Reset_TK90X
                .endif

                mov     HardReset, FALSE
                ret

Reset_16K:      mov     HardwareMode, HW_16
                call    Machine_Initialise
                ret

Reset_48K:      mov     HardwareMode, HW_48
                call    Machine_Initialise
                ret

Reset_128K:     mov     HardwareMode, HW_128
                call    Machine_Initialise
                ret

Reset_Plus2:    mov     HardwareMode, HW_PLUS2
                call    Machine_Initialise
                ret

Reset_Plus2A:   mov     HardwareMode, HW_PLUS2A
                call    Machine_Initialise
                ret

Reset_Plus3:    mov     HardwareMode, HW_PLUS3
                call    Machine_Initialise
                ret

Reset_Pentagon: mov     HardwareMode, HW_PENTAGON128
                call    Machine_Initialise
                ret

Reset_TC2048:   mov     HardwareMode, HW_TC2048
                call    Machine_Initialise
                ret

Reset_TK90X:    mov     HardwareMode, HW_TK90X
                call    Machine_Initialise
                ret

; #########################################################################

; Init_AY - resets AY chip

Init_AY         proc    uses esi edi ebx

                xor     al, al
@@:             push    eax
                call    OutPort_FFFD
                xor     al, al
                call    OutPort_BFFD
                pop     eax
                inc     al
                cmp     al, 16
                jc      @B
                ret
Init_AY         endp

; ########################################################################

GetFileName     proc    uses        ebx esi edi,
                        hParent:    DWORD, lpTitle:DWORD, lpFilter:DWORD,
                        lpOfn:      DWORD,
                        lpFilename: DWORD,
                        lpDefExt:   DWORD

                local   t_file  [MAX_PATH]: BYTE,
                        t_path  [MAX_PATH]: BYTE

                CLEARSOUNDBUFFERS

                strncpy lpFilename, addr t_file, sizeof t_file

                mov     ebx, lpOfn
                assume  ebx: ptr OPENFILENAME

                memclr  ebx, sizeof OPENFILENAME
                mov     [ebx].Flags, OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_LONGNAMES

                .if     FullScreenMode
                        or      [ebx].Flags,    OFN_ENABLEHOOK
                        mov     [ebx].lpfnHook, offset GetFN_Hook
                .endif

                mov     [ebx].lStructSize,      sizeof OPENFILENAME
                m2m     [ebx].hWndOwner,        hParent
                m2m     [ebx].hInstance,        hInstance

                m2m     [ebx].lpstrFilter,      lpFilter
                lea     eax, t_file
                mov     [ebx].lpstrFile,        eax
                mov     [ebx].nMaxFile,         sizeof t_file
                m2m     [ebx].lpstrTitle,       lpTitle
                m2m     [ebx].lpstrDefExt,      lpDefExt

                invoke  ExtractFilePath,        lpFilename, addr t_path
                lea     eax,                    t_path
                mov     [ebx].lpstrInitialDir,  eax

                mov     byte ptr [t_file], 0
                .if     $fnc (GetOpenFileName, ebx) != 0
                        push    eax
                        strncpy addr t_file, lpFilename, sizeof t_file
                        pop     eax
                .endif
                ret

                assume  ebx: nothing
GetFileName     endp

SaveFileName    proc    uses            ebx esi edi,
                        hParent:        DWORD, lpTitle:DWORD, lpFilter:DWORD,
                        lpOfn:          DWORD,
                        lpFilename:     DWORD,
                        lpDefExt:       DWORD,
                        lpFilterIndex:  DWORD

                local   t_file  [MAX_PATH]: BYTE,
                        t_path  [MAX_PATH]: BYTE

                CLEARSOUNDBUFFERS

                strncpy lpFilename, addr t_file, sizeof t_file

                mov     ebx, lpOfn
                assume  ebx: ptr OPENFILENAME

                memclr  ebx, sizeof OPENFILENAME
                mov     [ebx].Flags, OFN_EXPLORER or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_HIDEREADONLY

                .if     FullScreenMode
                        or      [ebx].Flags,    OFN_ENABLEHOOK
                        mov     [ebx].lpfnHook, offset GetFN_Hook
                .endif

                mov     [ebx].lStructSize,      sizeof OPENFILENAME
                m2m     [ebx].hWndOwner,        hParent
                m2m     [ebx].hInstance,        hInstance

                m2m     [ebx].lpstrFilter,      lpFilter
                lea     eax, t_file
                mov     [ebx].lpstrFile,        eax
                mov     [ebx].nMaxFile,         sizeof t_file
                m2m     [ebx].lpstrTitle,       lpTitle
                m2m     [ebx].lpstrDefExt,      lpDefExt

                invoke  ExtractFilePath,        lpFilename, addr t_path
                lea     eax,                    t_path
                mov     [ebx].lpstrInitialDir,  eax

                mov     esi, lpFilterIndex
                ifc     esi ne 0 then mov eax, [esi] : mov [ebx].nFilterIndex, eax

                .if     $fnc (GetSaveFileName, ebx) != 0
                        push    eax
                        strncpy addr t_file, lpFilename, sizeof t_file
                        pop     eax
                .endif

                mov     esi, lpFilterIndex
                ifc     esi ne 0 then mov ecx, [ebx].nFilterIndex : mov [esi], ecx
                ret

                assume  ebx: nothing
SaveFileName    endp

GetFN_Hook              proc    hChildDlg:  DWORD,
                                uMsg:       DWORD,
                                wParam:     DWORD,
                                lParam:     DWORD

                        local   hWndDlg:    DWORD

                        RESETMSG

OnInitDialog
                        .if     FullScreenMode
                                mov     hWndDlg, $fnc (GetParent, hChildDlg)
                                ifc     hWndDlg ne NULL then invoke SetWindowPosition, hWndDlg, 0, 20
                        .endif
                        return  TRUE

OnDefault
                        return  FALSE

                        DOMSG

GetFN_Hook              endp

; bx = display offset, cx = attribute offset
ULA_OOS:                sub     cx, 32

                        add     bx, 256-32
                        test    bh, 7
                        jnz     @F

                        sub     bh, 8
                        add     cx, 32
                        add     bl, 32
                        test    bl, 224
                        jnz     @F

                        add     bh, 8
@@:                     ret

; #########################################################################

.const
szSvSnapFilter          db      "SZX file (*.szx)", 0, "*.szx", 0,
                                "Z80 file (*.z80)", 0, "*.z80", 0,
                                "SNA file (*.sna)", 0, "*.sna", 0,
                                0

AskSaveSNA              db      "The .SNA snapshot format doesn't natively support this emulated machine.", 13
                        db      "This program may cease to function correctly on reloading or may reload as a different emulated machine.", 13, 13
                        db      "Do you wish to continue with saving this snapshot?"
                        db      0

AskSaveZ80              db      "The .Z80 snapshot format doesn't natively support this emulated machine.", 13
                        db      "This program may cease to function correctly on reloading or may reload as a different emulated machine.", 13, 13
                        db      "Do you wish to continue with saving this snapshot?"
                        db      0

AskSaveSZX              db      "The .SZX snapshot format doesn't natively support this emulated machine.", 13
                        db      "This program may cease to function correctly on reloading or may reload as a different emulated machine.", 13, 13
                        db      "Do you wish to continue with saving this snapshot?"
                        db      0

.data
align 4
snap_filterindex        dd      1       ; previous snapshot filterindex value for OPENFILENAME

savesnap_ofn            OPENFILENAME    <>

.code

                        RESETENUM
                        ENUM    SSBE_NONE, SSBE_SZX, SSBE_Z80, SSBE_SNA

SaveSnapshotByExtension proc    uses    esi edi ebx,
                                lpFilename: DWORD

                        .if     $fnc (FindExtension, lpFilename) != -1
                                mov     esi, eax
                                mov     ebx, SSBE_NONE

                                switch$ esi
                                        case$   "szx"
                                                mov     ebx, SSBE_SZX
                                        case$   "z80"
                                                mov     ebx, SSBE_Z80
                                        case$   "sna"
                                                mov     ebx, SSBE_SNA
                                endsw$

                                .if     ebx != SSBE_NONE
                                        .if     $fnc (CreateFile, lpFilename, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE
                                                mov     SnapFH, eax

                                                switch  ebx
                                                        case    SSBE_SZX
                                                                call    Save_SZXFormat
                                                        case    SSBE_Z80
                                                                call    Save_Z80Format
                                                        case    SSBE_SNA
                                                                call    Save_SNAFormat
                                                endsw

                                                invoke  CloseHandle, SnapFH
                                                mov     SnapFH, 0
                                                return  TRUE
                                        .endif
                                .endif
                        .endif

                        return  FALSE
SaveSnapshotByExtension endp

SaveSnapshot            proc    hParent:    DWORD

                        .if     $fnc (Is_Pacman_Trapped)
                                invoke  ShowMessageBox, hWnd, SADD ("SpecEmu cannot write a PAC-MAN snapshot file"), addr szWindowName, MB_OK
                                ret
                        .endif

                        .if     $fnc (SaveFileName, hParent, SADD ("Save Snapshot"), addr szSvSnapFilter, addr savesnap_ofn, addr szSnapSaveFilename, NULL, addr snap_filterindex) != 0
                                call    SaveSnapshot_1
                        .endif
                        ret

SaveSnapshot            endp

SaveSnapshot_1:         switch  savesnap_ofn.nFilterIndex
                                case    1
                                        ADDEXTENSION    offset szSnapSaveFilename, offset SZXExt
                                        switch  HardwareMode
                                                case    HW_TK90X
                                                        invoke  ShowMessageBox, hWnd, addr AskSaveSZX, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                                        ifc     eax eq IDNO then ret
                                        endsw
                                case    2
                                        ADDEXTENSION    offset szSnapSaveFilename, offset Z80Ext
                                        switch  HardwareMode
                                                case    HW_TK90X
                                                        invoke  ShowMessageBox, hWnd, addr AskSaveZ80, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                                        ifc     eax eq IDNO then ret
                                        endsw
                                .else
                                        ADDEXTENSION    offset szSnapSaveFilename, offset SNAExt
                                        switch  HardwareMode
                                                case    HW_128, HW_PLUS2, HW_PLUS2A, HW_PLUS3, HW_TC2048, HW_TK90X
                                                        invoke  ShowMessageBox, hWnd, addr AskSaveSNA, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                                        ifc     eax eq IDNO then ret
                                        endsw
                        endsw

                        invoke  AskOverwriteFile, addr szSnapSaveFilename, hWnd, addr szWindowName
                        cmp     eax, FALSE
                        je      SvSnap_Exit

                        .if     $fnc (CreateFile, offset szSnapSaveFilename, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE

                                mov     SnapFH, eax

                                switch  savesnap_ofn.nFilterIndex
                                        case    1
                                                .if     LoadTapeType != Type_NONE
                                                        ; we have a tape inserted...
                                                        MouseOn
                                                        invoke  DialogBoxParam, GlobalhInst, IDD_SZXSAVETAPEBLOCK, hWnd, addr SZXSaveTapeBlockDialogProc, NULL
                                                        mov     SZX_SaveTape_Method, al
                                                        MouseOff
                                                .endif
                                                call    Save_SZXFormat
                                        case    2
                                                call    Save_Z80Format
                                        .else
                                                call    Save_SNAFormat
                                endsw

                                invoke  CloseHandle, SnapFH

                                strncpy addr szSnapSaveFilename, addr szRecentFileName, sizeof szRecentFileName
                                invoke  AddRecentFile   ; add saved snapshot to recent files list
                        .else
                                invoke  ShowMessageBox, hWnd, SADD ("Unable to write snapshot file"), addr szWindowName, MB_OK
                        .endif

SvSnap_Exit:            mov     SnapFH, 0
                        ret

SZXSaveTapeBlockDialogProc proc uses        ebx,
                                hWndDlg:    DWORD,
                                uMsg:       DWORD,
                                wParam:     DWORD,
                                lParam:     DWORD

                        .if     uMsg == WM_INITDIALOG
                                invoke  SetWindowText, hWndDlg, addr szWindowName

                                mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_SZX_CURRENT_TAPE_EDT)
                                invoke  SetWindowText, ebx, addr inserttapefilename
                                invoke  SendMessage,   ebx, WM_KEYDOWN, VK_END, 0   ; move editbox caret to end of filename text
                                invoke  SendMessage,   ebx, WM_KEYUP,   VK_END, 0
                                return  TRUE

                        .elseif uMsg == WM_COMMAND
                                switch  $HighWord (wParam)
                                        case    BN_CLICKED
                                                switch  $LowWord (wParam)
                                                        case    IDC_LINKEDTAPEBTN
                                                                invoke  EndDialog, hWndDlg, SZXTAPE_SAVELINKED
                                                                return  TRUE

                                                        case    IDC_EMBEDDEDTAPEBTN
                                                                invoke  EndDialog, hWndDlg, SZXTAPE_SAVEEMBEDDED
                                                                return  TRUE

                                                        case    IDC_IGNOREDTAPEBTN
                                                                invoke  EndDialog, hWndDlg, SZXTAPE_SAVEIGNORE
                                                                return  TRUE
                                                endsw
                                endsw

                        .endif
                        return  FALSE

SZXSaveTapeBlockDialogProc endp

.data?
align 4
temp_szx_FH             DWORD   ?

.code
; called before loading a snapshot so we can restore current state if a snapshot fails to load properly
SaveTempSZXFile         proc    uses esi edi ebx

                        .if     $fnc (CreateTempFile, addr szTempSZXFile, addr temp_szx_FH) == TRUE
                                m2m     SnapFH, temp_szx_FH
                                call    Save_SZXFormat      ; saves a current SZX state file to SnapFH
                                mov     SnapFH, 0

                                invoke  CloseHandle, temp_szx_FH
                        .endif
                        ret
SaveTempSZXFile         endp

; reloads a temporary SZX snapshot
LoadTempSZXFile         proc

                        .if     temp_szx_FH != 0
                                invoke  LoadSZXStateFromFile, addr szTempSZXFile, addr LoadSZXStateCallback
                        .endif
                        ret
LoadTempSZXFile         endp

DeleteTempSZXFile   proc

                    .if     temp_szx_FH != 0
                            invoke  DeleteFile, addr szTempSZXFile
                            mov     temp_szx_FH, 0
                    .endif
                    ret
DeleteTempSZXFile   endp

; ########################################################################

.data?
SNA128_PC               WORD    ?
SNA128_7FFD             BYTE    ?
SNA128_TRDOS            BYTE    ?

.code
Save_SNAFormat:         .if     (HardwareMode == HW_16) || (HardwareMode == HW_48) || (HardwareMode == HW_TC2048) || (HardwareMode == HW_TK90X)
                                mov     ax, zPC
                                call    MemPushStack  ; Push PC on the stack so that RETN can restart it

                                call    SaveRegsToSNASNX

                                invoke  WriteFile, SnapFH, addr sna_snx_header, 27, addr BytesSaved, NULL
                                invoke  WriteFile, SnapFH, currentMachine.bank5, 16384, addr BytesSaved, NULL
                                invoke  WriteFile, SnapFH, currentMachine.bank2, 16384, addr BytesSaved, NULL
                                invoke  WriteFile, SnapFH, currentMachine.bank0, 16384, addr BytesSaved, NULL

                                call    MemPopStack   ; equalize stack again before exiting
                                ret

                        .else   ; 128K sna file
                                call    SaveRegsToSNASNX

                                invoke  WriteFile, SnapFH, addr sna_snx_header, 27, addr BytesSaved, NULL
                                invoke  WriteFile, SnapFH, currentMachine.bank5, 16384, addr BytesSaved, NULL
                                invoke  WriteFile, SnapFH, currentMachine.bank2, 16384, addr BytesSaved, NULL

                                mov     edx, [currentMachine.RAMREAD6]  ; currently paged ram
                                invoke  WriteFile, SnapFH, edx,        16384, addr BytesSaved, NULL

                                mov     ax, zPC
                                mov     SNA128_PC, ax
                                mov     al, Last7FFDWrite
                                mov     SNA128_7FFD, al

                                mov     al, TrDos_Paged     ; TRUE/FALSE (1/0)
                                mov     SNA128_TRDOS, al

                                invoke  WriteFile, SnapFH, addr SNA128_PC, 4, addr BytesSaved, NULL

                                xor     al, al
                                call    SaveSNARamPage
                                mov     al, 1
                                call    SaveSNARamPage
                                mov     al, 3
                                call    SaveSNARamPage
                                mov     al, 4
                                call    SaveSNARamPage
                                mov     al, 6
                                call    SaveSNARamPage
                                mov     al, 7
                                call    SaveSNARamPage
                                ret
                        .endif

SaveSNARamPage:         mov     bl, Last7FFDWrite
                        and     bl, 7
                        cmp     al, bl
                        je      @F          ; don't save the same page twice

                        and     eax, 7
                        mov     eax, [currentMachine.bank_ptrs+eax*4]
                        invoke  WriteFile, SnapFH, eax, 16384, addr BytesSaved, NULL

@@:                     ret

; ########################################################################

SnapBlock               equ     TempMemBuffer

.const
_z80_v1_end_marker      db      0, 0EDh, 0EDh, 0

.data?
save_as_v1              db      ?

.code
Save_Z80Format:         .if     save_z80_as_v1_enabled == True
                                ifc HardwareMode eq HW_48 then mov save_as_v1, True else mov save_as_v1, False
                        .endif

                        lea     edi, SnapBlock
                        xor     al, al
                        mov     ecx, 87     ; clear the whole of the additional header block up to the final +3 byte (last OUT to 1FFD)
                        rep     stosb

                        lea     edi, SnapBlock

                        mov     al, z80registers.af.hi
                        stosb
                        mov     al, z80registers.af.lo
                        stosb
                        mov     ax, z80registers.bc.w
                        stosw
                        mov     ax, z80registers.hl.w
                        stosw

                        .if     save_as_v1 == True
                                mov     ax, zPC
                                stosw
                        .else
                                xor     ax, ax
                                stosw               ; PC = 0 = V2.01 or later Z80 format
                        .endif

                        mov     ax, z80registers._sp
                        stosw
                        mov     al, z80registers.i
                        stosb
                        mov     al, z80registers.r
                        stosb
                        mov     al, byte ptr [SPGfx.BorderColour]
                        sub     al, CLR_SPECBASE
                        and     al, 7
                        shl     al, 1
                        mov     bl, Reg_R_msb
                        shr     bl, 7
                        or      al, bl
                        and     al, 15
                        ifc     save_as_v1 eq TRUE then or al, 32   ; bit 5 set = block of data is compressed (no meaning after v1 z80 snaps, should be 0)
                        stosb                                       ; byte 12 (flags)

                        mov     ax, z80registers.de.w
                        stosw
                        mov     ax, z80registers.bc_.w
                        stosw
                        mov     ax, z80registers.de_.w
                        stosw
                        mov     ax, z80registers.hl_.w
                        stosw
                        mov     al, z80registers.af_.hi
                        stosb
                        mov     al, z80registers.af_.lo
                        stosb
                        mov     ax, z80registers.iy.w
                        stosw
                        mov     ax, z80registers.ix.w
                        stosw

                      ; Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
                        mov     al, currentMachine.iff2
                        shl     al, 2
                        and     al, 4
                        mov     z80registers.interrupt, al

                        mov     al, z80registers.interrupt
                        and     al, 4
                        je      @F          ; 0 = DI
                        mov     al, 0FFh    ; FF = EI
            @@:         stosb

                        mov     al, 0FFh
                        stosb
                        mov     al, z80registers.intmode
                        stosb

                        mov     ax, 54              ; 23 for v2.01 format; 54 or 55 for v3 format
                        .if     (HardwareMode == HW_PLUS2A) || (HardwareMode == HW_PLUS3)
                                mov     al, Last1FFDWrite
                                mov     [SnapBlock+86], al
                                mov     ax, 55      ; 55 for +2A/+3 mode
                        .endif
                        stosw   ; store length of additional header block

                        mov     ax, zPC
                        stosw

                        mov     byte ptr [SnapBlock+36], 0          ; needs setting if in TC2048 mode below

                        switch  HardwareMode
                                case    HW_16
                                        or      [SnapBlock+37], 128 ; modify hardware bit set = 16K machine
                                        xor     al, al              ; now treat as a 48K machine

                                case    HW_48
                                        xor     al, al              ; 48K machine

                                case    HW_TC2048
                                        mov     al, Timex_Port_FF
                                        mov     [SnapBlock+36], al
                                        mov     al, 14              ; TC2048 machine

                                case    HW_128
                                        mov     al, 4               ; 128K machine

                                case    HW_PLUS2
                                        or      [SnapBlock+37], 128 ; modify hardware bit set = +2 machine
                                        mov     al, 4               ; now treat as a 128K machine

                                case    HW_PLUS2A
                                        mov     al, 13              ; +2A machine

                                case    HW_PLUS3
                                        mov     al, 7               ; +3 machine

                                case    HW_PENTAGON128
                                        mov     al, 9               ; Pentagon 128K machine

                                case    HW_TK90X
                                        xor     al, al              ; treat as 48K machine
                        endsw
                        stosb

                        mov     al, Last7FFDWrite
                        stosb                       ; [SnapBlock+35]

                        inc     edi                 ; skip [SnapBlock+36]

                        ; Bit 0: 1 if R register emulation on
                        ; Bit 1: 1 if LDIR emulation on
                        ; Bit 2: AY sound in use, even on 48K machines
                        ; Bit 6: (if bit 2 set) Fuller Audio Box emulation
                        ; Bit 7: Modify hardware (see above)

                        mov     al, 7
                        or      byte ptr [edi], al  ; stores at [SnapBlock+37]
                        inc     edi

                        mov     al, SCSelectReg
                        stosb
                        lea     esi, SCRegister0
                        mov     ecx, 16
                        rep     movsb

                        .if     save_as_v1 == TRUE  ; only true for 48K mode
                                invoke  WriteFile, SnapFH, addr SnapBlock, 30, addr BytesSaved, NULL   ; save main z80 header (v1 = 30 bytes)

                                lea     edi, SnapBlock+3
                                mov     esi, currentMachine.bank5
                                xor     cx, cx
                                mov     dx, 49152  ; block size limit
                                call    SaveRP_Main

                                invoke  WriteFile, SnapFH, addr _z80_v1_end_marker, 4, addr BytesSaved, NULL   ; z80 v1 end marker

                        .else
                                invoke  SetZ80TstateCount, addr SnapBlock+55

                                invoke  WriteFile, SnapFH, addr SnapBlock, 32, addr BytesSaved, NULL   ; save main z80 header + additional header block length

                                movzx   edx, word ptr [SnapBlock+30]
                                invoke  WriteFile, SnapFH, addr SnapBlock+32, edx, addr BytesSaved, NULL   ; save additional header block

                                .if     (HardwareMode == HW_16) || (HardwareMode == HW_48) || (HardwareMode == HW_TC2048) || (HardwareMode == HW_TK90X)
                                        mov     bl, 4           ; Z80 format page number
                                        mov     bh, 2           ; actual Ram page number
                                        call    Save_Z80RamPage
                                        mov     bl, 5
                                        mov     bh, 0
                                        call    Save_Z80RamPage
                                        mov     bl, 8
                                        mov     bh, 5
                                        call    Save_Z80RamPage
                                .else
                                        mov     bl, 3
                                        mov     bh, 0
                                        mov     cl, 8
                    @@SaveZ80Pages:     push    ecx
                                        push    ebx
                                        call    Save_Z80RamPage
                                        pop     ebx
                                        pop     ecx
                                        inc     bl
                                        inc     bh
                                        dec     cl
                                        jne     @@SaveZ80Pages
                                .endif
                        .endif
                        ret

.data?
align 4
SRamP_esi               DWORD   ?
SRamP_cx                WORD    ?

.code
Save_Z80RamPage:
;                        jmp     SaveRP_Uncompressed    ; uncomment if we want uncompressed Z80 snapshots

                        lea     edi, SnapBlock+2
                        mov     al, bl   ; Z80 format page number
                        stosb

                        movzx   eax, bh   ; actual Ram page number
                        mov     esi, [currentMachine.bank_ptrs+eax*4]
                        xor     cx, cx
                        mov     dx, 16384   ; block size limit

SaveRP_Main:            cmp     cx, dx
                        je      SaveRP_Done

                        dec     dx
                        cmp     cx, dx          ; 16383/49151 for v1
                        je      SaveRP_Last
                        inc     dx

                        mov     SRamP_esi, esi  ; temp storage for esi
                        mov     SRamP_cx, cx    ; temp storage for cx

                        mov     bh, 1           ; no. of multiple bytes
                        mov     al, [esi]

SaveRP_L1:              inc     esi
                        inc     cx
                        cmp     al, [esi]
                        je      @F

SaveRP_L2:              cmp     bh, 1
                        je      SaveRP_1
                        cmp     al, 0EDh
                        je      Save_Multiple
                        cmp     bh, 5
                        jnc     Save_Multiple
                        jmp     SaveRP_1

@@:                     inc     esi
                        inc     cx
                        inc     bh
                        cmp     bh, 255
                        je      Save_Multiple
                        dec     esi
                        dec     cx
                        cmp     cx, dx
                        jc      SaveRP_L1
                        dec     bh
                        jmp     SaveRP_L2

SaveRP_1:               mov     esi, SRamP_esi
                        mov     cx,  SRamP_cx
                        lodsb
                        stosb
                        inc     cx
                        cmp     al, 0EDh
                        jne     SaveRP_Main
                        cmp     cx, dx
                        je      SaveRP_Done
                        movsb
                        inc     cx
                        jmp     SaveRP_Main

Save_Multiple:          mov     bl, al
                        mov     ax, 0EDEDh
                        stosw
                        mov     al, bh
                        stosb
                        mov     al, bl
                        stosb
                        jmp     SaveRP_Main

SaveRP_Last:
                        movsb

SaveRP_Done:            mov     eax, edi
                        sub     eax, offset SnapBlock+3     ; eax = length of compressed data
                        mov     edx, eax                    ; edx = length of compressed data

                        .if     save_as_v1 == TRUE  ; only true for 48K mode
                                invoke  WriteFile, SnapFH, addr SnapBlock+3, edx, addr BytesSaved, NULL
                        .else
                                mov     word ptr [SnapBlock], ax    ; store length of data (as word) in header
                                add     edx, 3                      ; edx = length of data + 3 byte header
                                invoke  WriteFile, SnapFH, addr SnapBlock, edx, addr BytesSaved, NULL
                        .endif
                        ret

; this saves data uncompressed
SaveRP_Uncompressed:    lea     edi, SnapBlock

                        mov     ax, -1
                        stosw               ; length = -1 = not compressed

                        mov     al, bl      ; Z80 format page number
                        stosb

                        movzx   eax, bh     ; actual Ram page number
                        mov     esi, [currentMachine.bank_ptrs+eax*4]
                        mov     ecx, 16384/4
                        rep     movsd

                        invoke  WriteFile, SnapFH, addr SnapBlock, 16384+3, addr BytesSaved, NULL
                        ret

; ########################################################################

.const
szOpenFileFilter        db  "All files (*.szx;*.z80;*.sna;*.snx;*.sp;*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx;*.dsk;*.trd;*.scl;*.mgt;*.img;*.rzx;*.rom)", 0,
                            "*.szx;*.z80;*.sna;*.snx;*.sp;*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx;*.dsk;*.trd;*.scl;*.mgt;*.img;*.rzx;*.rom", 0
                        db  "Snapshot files (*.szx;*.z80;*.sna;*.snx;*.sp)", 0, "*.szx;*.z80;*.sna;*.snx;*.sp", 0
                        db  "Tape files (*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx)", 0, "*.tap;*.blk;*.tzx;*.wav;*.csw;*.pzx", 0
                        db  "Disk files (*.dsk;*.trd;*.scl;*.mgt;*.img)", 0, "*.dsk;*.trd;*.scl;*.mgt;*.img", 0
                        db  "Action Recordings (*.rzx)", 0, "*.rzx", 0
                        db  "Interface 2 ROM Cartridges (*.rom)", 0, "*.rom", 0
                        db  0

szIF2ROMFilter          db  "Interface 2 ROM Cartridges (*.rom)", 0, "*.rom", 0, 0

.code
OpenFileType            proc

                        local   ofn: OPENFILENAME

                        .if     $fnc (GetFileName, hWnd, SADD ("Open File"), addr szOpenFileFilter, addr ofn, addr openfiletypefilename, 0) != 0
                                invoke  ReadFileType, addr openfiletypefilename
                        .endif
                        ret
OpenFileType            endp

; ########################################################################

.code
LoadIF2_ROM             proc    hParent:    DWORD

                        local   ofn:        OPENFILENAME

                        invoke  GetFileName, hParent, SADD ("Load Interface 2 ROM Cartridge"), addr szIF2ROMFilter, addr ofn, addr loadIF2ROMfilename, addr ROMExt
                        ifc     eax ne 0 then invoke ReadFileType, addr loadIF2ROMfilename
                        ret

LoadIF2_ROM             endp

LoadIF2ROM_1    proc    uses        esi edi ebx,
                        lpFilename: DWORD

                invoke  SaveTempSZXFile

                mov     HardwareMode, HW_48
                call    Machine_Initialise
                mov     zPC, 0
                DISABLEINTS

                m2m     Filename, lpFilename
                call    OpenMyReadFile
                .if     eax != NULL
                        strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                        invoke  AddRecentFile

                        memset  addr Rom_IF2ROM, 16384, 255

                        mov     ReadStart, offset Rom_IF2ROM
                        mov     ReadLen, 16384
                        call    ReadMyFile
                        call    CloseMyFile

                        mov     currentMachine.RAMREAD0, offset Rom_IF2ROM
                        mov     currentMachine.RAMREAD1, offset Rom_IF2ROM+8192
                .else
                        invoke  LoadTempSZXFile ; else reload temp SZX file
                .endif

                invoke  DeleteTempSZXFile
                ret

LoadIF2ROM_1    endp

.const
szLoadFilter    db  "Snapshot files (*.szx;*.z80;*.sna;*.snx;*.sp)", 0, "*.szx;*.z80;*.sna;*.snx;*.sp", 0, 0

.code
LoadSnapshot            proc    hParent:    DWORD

                        local   ofn:                    OPENFILENAME,
                                tempfile [MAX_PATH]:    BYTE

                        invoke  @@CopyString, addr loadsnapfilename, addr tempfile

                        invoke  GetFileName, hParent, SADD ("Load Snapshot"), addr szLoadFilter, addr ofn, addr tempfile, addr SZXExt
                        ifc     eax ne 0 then invoke ReadFileType, addr tempfile
                        ret

LoadSnapshot            endp

LoadSnapshot_1          proc    uses        ebx esi edi,
                                lpFilename: DWORD

                        ; first save a current SZX snapshot incase of an error loading new snapshot file
                        invoke  SaveTempSZXFile

                        mov     Snapshot_OK, FALSE
                        mov     TapePlaying, FALSE
                        mov     HALTED, FALSE

                        invoke  AttemptLoadSnapshot, lpFilename

                        ; if error loading snap, reload previous temporary SZX state snap
                        .if     Snapshot_OK == FALSE
                                invoke  LoadTempSZXFile
                        .else
                                strncpy lpFilename, addr loadsnapfilename, sizeof loadsnapfilename
                                strncpy lpFilename, addr SCRSavefilename, sizeof SCRSavefilename

                                strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                                invoke  AddRecentFile
                        .endif
                        invoke  DeleteTempSZXFile

                        invoke  EnableMultifaceOrSoftRom

                        RENDERFRAME
                        ret

LoadSnapshot_1          endp

AttemptLoadSnapshot     proc    uses        esi edi,
                                lpFilename: DWORD

                        mov     esi, lpFilename                 ; all snapshot loaders take a filename pointer in esi on entry

                        mov     edi, $fnc (FindExtension, esi)
                        .if     edi  != -1
                                ; if entension found; edi addresses the extension (beyond the '.')

                                invoke  szLower, edi   ; convert extension to lowercase
                                switch$ edi
                                        case$   "z80"
                                                call    Loadz80file
                                                invoke  FixSnapOnHalt

                                        case$   "sna"
                                                call    Loadsnafile
                                                invoke  FixSnapOnHalt

                                        case$   "snx"
                                                call    Loadsnxfile
                                                invoke  FixSnapOnHalt

                                        case$   "sp"
                                                call    LoadSPfile
                                                invoke  FixSnapOnHalt

                                        case$   "szx"
                                                call    LoadSzxfile
                                endsw$
                        .endif
                        ret

AttemptLoadSnapshot     endp

; call after loading snaps from formats that don't handle re-executing on HALT
FixSnapOnHalt           proc    uses    ebx esi edi

                        mov     bx, zPC
                        GETZ80ADDRESS
                        .if     byte ptr [esi] == 76h   ; HALT?
                                mov     HALTED, TRUE
                        .endif
                        ret
FixSnapOnHalt           endp


; #########################################################################

; entry point when filetype is known to be ".z80"

Loadz80file:            ADDMESSAGE  "Loading Z80 snapshot"

                        invoke  WipeSpeccyMem

                        invoke  Init_AY

                        mov     Filename, esi
                        call    OpenMyReadFile
                        or      eax, eax
                        jz      LdCancel

                        mov     Snapshot_OK, FALSE

                        mov     ReadStart, offset z80headerblk
                        mov     ReadLen, 30
                        call    ReadMyFile
                        jnz     LoadSnapError

DoMoveOrigin = 0

DOSTOSB                 MACRO   DoMoveAddr:REQ
                        mov     [edi+(DoMoveAddr-DoMoveOrigin)], al
                        ENDM
DOSTOSW                 MACRO   DoMoveAddr:REQ
                        mov     [edi+(DoMoveAddr-DoMoveOrigin)], ax
                        ENDM
DOSTOSD                 MACRO   DoMoveAddr:REQ
                        mov     [edi+(DoMoveAddr-DoMoveOrigin)], eax
                        ENDM

DOMOVSB                 MACRO   DoMoveDest:REQ, MoveOrigin  ; destination address
                        IFNB    <MoveOrigin>
                                DoMoveOrigin = MoveOrigin
                                lea     edi, DoMoveOrigin
                        ENDIF
                        lodsb
                        DOSTOSB DoMoveDest
                        ENDM

DOMOVSW                 MACRO   DoMoveDest:REQ, MoveOrigin  ; destination address
                        IFNB    <MoveOrigin>
                                DoMoveOrigin = MoveOrigin
                                lea     edi, DoMoveOrigin
                        ENDIF
                        lodsw
                        DOSTOSW DoMoveDest
                        ENDM

DOMOVSD                 MACRO   DoMoveDest:REQ, MoveOrigin  ; destination address
                        IFNB    <MoveOrigin>
                                DoMoveOrigin = MoveOrigin
                                lea     edi, DoMoveOrigin
                        ENDIF
                        lodsd
                        DOSTOSD DoMoveDest
                        ENDM

                        mov     z80tstatecount, 0   ; we will use 0 unless set by a v3 snap

                        lea     esi, z80headerblk
                        DOMOVSB z80registers.af.hi, RegisterBase

                        DOMOVSB z80registers.af.lo
                        DOMOVSB z80registers.bc.lo
                        DOMOVSB z80registers.bc.hi
                        DOMOVSB z80registers.hl.lo
                        DOMOVSB z80registers.hl.hi

                        DOMOVSW zPC
                        DOSTOSW Z80PC

                        DOMOVSW z80registers._sp

                        DOMOVSB z80registers.i
                        DOMOVSB z80registers.r
                        and     z80registers.r, 127

                        lodsb
                        ifc     al eq 255 then mov al, 1
                        mov     bl, al
                        shl     al, 7
                        and     al, 128
                        mov     Reg_R_msb, al
                        or      z80registers.r, al
                        mov     al, bl
                        shr     al, 1
                        and     al, 7
                        mov     snap_bordercol, al  ; store because +2A/+3 machine initialisation set border to black
                        call    Set_BorderColour

                        DOMOVSB z80registers.de.lo
                        DOMOVSB z80registers.de.hi
                        DOMOVSB z80registers.bc_.lo
                        DOMOVSB z80registers.bc_.hi
                        DOMOVSB z80registers.de_.lo
                        DOMOVSB z80registers.de_.hi
                        DOMOVSB z80registers.hl_.lo
                        DOMOVSB z80registers.hl_.hi
                        DOMOVSB z80registers.af_.hi   ; hi first for AF'
                        DOMOVSB z80registers.af_.lo
                        DOMOVSB z80registers.iy.lo
                        DOMOVSB z80registers.iy.hi
                        DOMOVSB z80registers.ix.lo
                        DOMOVSB z80registers.ix.hi

                        lodsb       ; 0 = DI, else EI
                        ifc     al eq 0 then DISABLEINTS else ENABLEINTS

                        inc     esi     ; skip byte 28

                        lodsb
                        and     al, 3
                        mov     z80registers.intmode, al

                        mov     ax, zPC
                        or      ax, ax
                        jne     LoadOldz8048K   ; jump if a version 1.45 file

                        ; ==================================================
                        ; if we get here, then this is a new format Z80 file
                        ; ie: a version 2.01 or version 3 format
                        ; ==================================================

                        mov     ReadStart, offset z80addblklen
                        mov     ReadLen, 2
                        call    ReadMyFile
                        jnz     LoadSnapError

                        mov     ReadStart, offset z80addblk
                        movzx   ecx, z80addblklen
                        mov     ReadLen, ecx
                        push    ecx
                        call    ReadMyFile
                        pop     ecx
                        jnz     LoadSnapError

                        lea     esi, z80addblk
                        lodsw
                        mov     zPC, ax
                        mov     Z80PC, ax

                        DOMOVSB HardwareMode

                        mov     ax, z80addblklen
                        cmp     ax, 54
                        jnc     z80v3file

                        cmp     ax, 23
                        je      z80v201file

                        ADDMESSAGE      "Invalid length of additional Z80 header block"
                        movzx   eax, ax
                        ADDMESSAGEDEC   " - length = ", eax

.const
AskLoadInvsnap          db  "This z80 snapshot has an invalid block length.", 13
                        db  "This program may cease to function correctly on reloading or may reload as a different emulated machine.", 13, 13
                        db  "Do you wish to continue with this snapshot?"
                        db  0

.code
                        .if     eax > 23    ; additional block length > 23 bytes?
                                invoke  ShowMessageBox, hWnd, addr AskLoadInvsnap, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                                ifc     eax eq IDYES then jmp z80v201file
                        .endif

                        jmp     LoadSnapError


z80v201file:            ADDMESSAGE  "v2.01 Z80 format"
                        mov     al, HardwareMode
                        or      al, al
                        je      LoadNewz8048K
                        cmp     al, 1
                        je      LoadNewz8048K
                        cmp     al, 3
                        je      LoadNewz80128K
                        cmp     al, 4
                        je      LoadNewz80128K
                        cmp     al, 9
                        je      LoadNewz80Pentagon128K
                        cmp     al, 12
                        je      LoadNewz80Plus2
                        cmp     al, 14
                        je      LoadNewz80TC2048

                        jmp     LoadSnapError

z80v3file:              ADDMESSAGE  "v3 Z80 format"

                        mov     al, HardwareMode
                        or      al, al
                        je      LoadNewz8048K
                        cmp     al, 1
                        je      LoadNewz8048K
                        cmp     al, 3
                        je      LoadNewz8048K

                        cmp     al, 4
                        je      LoadNewz80128K
                        cmp     al, 5
                        je      LoadNewz80128K
                        cmp     al, 6
                        je      LoadNewz80128K
                        cmp     al, 7
                        je      LoadNewz80Plus3
                        cmp     al, 9
                        je      LoadNewz80Pentagon128K
                        cmp     al, 12
                        je      LoadNewz80Plus2
                        cmp     al, 13
                        je      LoadNewz80Plus2A
                        cmp     al, 14
                        je      LoadNewz80TC2048

                        jmp     LoadSnapError

LoadOldz8048K:          ADDMESSAGE  "v1 Z80 format"
                        ADDMESSAGE  "...Spectrum 48K"

                        mov     HardwareMode, HW_48
                        call    Machine_Initialise

                        mov     ReadStart, offset z80pagedata
                        mov     ReadLen, 49152
                        call    ReadMyFile  ; v1.45 has no data length in file so we just read max allowable 49152 bytes

                        call    CloseMyFile
                        mov     Snapshot_OK, TRUE

                        lea     esi, z80pagedata
                        mov     edi, currentMachine.bank5
                        mov     ecx, 49152

                        test    [z80headerblk+12], 32
                        .if     ZERO?
                                rep     movsb
                        .else
                                call    ExpandZ80
                                cmp     Z80BadFormat, TRUE
                                je      LoadSnapError
                        .endif
                        mov     totaltstates, 0
                        ret

LoadNewz80TC2048:       ADDMESSAGE  "...TC2048 48K"
                        mov     HardwareMode, HW_TC2048
                        call    Machine_Initialise

                        mov     al, [z80headerblk+36]   ; contains last OUT to 0xff
                        invoke  Timex_Write_FF, al
                        jmp     LoadZ8048KRAM

LoadNewz8048K:          test    [z80headerblk+37], 128    ; modify hardware bit
                        .if     !ZERO?
                                ADDMESSAGE  "...Spectrum 16K"
                                mov     HardwareMode, HW_16
                        .else
                                ADDMESSAGE  "...Spectrum 48K"
                                mov     HardwareMode, HW_48
                        .endif
                        call    Machine_Initialise

LoadZ8048KRAM:          call    LoadAllZ80Pages
                        jnz     LoadSnapError

                        .if     HardwareMode == HW_16
                                mov     eax, z80pageloadedflags
                                and     eax, 100000b
                                cmp     eax, 100000b ; page 5 loaded?
                                jnz     LoadSnapError
                        .else
                                mov     eax, z80pageloadedflags
                                and     eax, 100101b
                                cmp     eax, 100101b ; page 5/2/0 loaded?
                                jnz     LoadSnapError
                        .endif

                        mov     z80tstatecount, $fnc (GetZ80TstateCount)
                        m2m     totaltstates, z80tstatecount

                        call    CloseMyFile
                        mov     Snapshot_OK, TRUE
                        ret

LoadNewz80Pentagon128K: ADDMESSAGE  "...Pentagon 128K"
                        mov     HardwareMode, HW_PENTAGON128
                        call    Machine_Initialise
                        jmp     LoadZ80128KRAM

LoadNewz80Plus2:        ADDMESSAGE  "...Spectrum +2"
                        mov     HardwareMode, HW_PLUS2
                        call    Machine_Initialise
                        jmp     LoadZ80128KRAM

LoadNewz80Plus2A:       ifc     word ptr [z80addblklen] ne 55 then jmp LoadSnapError

                        ADDMESSAGE  "...Spectrum +2A"
                        mov     HardwareMode, HW_PLUS2A
                        call    Machine_Initialise

                        mov     al, snap_bordercol      ; restore because +2A/+3 machine initialisation set border to black
                        call    Set_BorderColour

                        call    LoadZ80128KRAM

                        mov     al, [z80headerblk+86]
                        call    Do_Out1FFD  ; needs to be done last in case we're in 64K RAM mode. fixes soviet.rzx

                        m2m     totaltstates, z80tstatecount
                        ret

LoadNewz80Plus3:        ifc     word ptr [z80addblklen] ne 55 then jmp LoadSnapError

                        ADDMESSAGE  "...Spectrum +3"
                        mov     HardwareMode, HW_PLUS3
                        call    Machine_Initialise

                        mov     al, snap_bordercol      ; restore because +2A/+3 machine initialisation set border to black
                        call    Set_BorderColour

                        call    LoadZ80128KRAM

                        mov     al, [z80headerblk+86]
                        call    Do_Out1FFD  ; needs to be done last in case we're in 64K RAM mode. fixes soviet.rzx

                        m2m     totaltstates, z80tstatecount
                        ret

z80_copy_AY_registers:  lea     esi, z80headerblk+39
                        xor     al, al
                @@:     push    eax
                        push    esi
                        call    OutPort_FFFD
                        pop     esi
                        push    esi
                        mov     al, [esi]
                        call    OutPort_BFFD
                        pop     esi
                        inc     esi
                        pop     eax
                        inc     al
                        cmp     al, 16
                        jc      @B
            
                        mov     al, z80headerblk+38
                        call    OutPort_FFFD
                        ret

LoadNewz80128K:         test    [z80headerblk+37], 128    ; modify hardware bit
                        .if     !ZERO?
                                mov     HardwareMode, HW_PLUS2
                                ADDMESSAGE  "...Spectrum +2"
                        .else
                                mov     HardwareMode, HW_128
                                ADDMESSAGE  "...Spectrum 128K"
                        .endif

                        call    Machine_Initialise

LoadZ80128KRAM:         call    z80_copy_AY_registers   ; done here to be after calls to 'Machine_Initialise' which clears AY registers

                        call    LoadAllZ80Pages
                        jnz     LoadSnapError

                        mov     eax, z80pageloadedflags
                        and     eax, 11111111b
                        cmp     eax, 11111111b ; all pages 0-7 loaded?
                        jnz     LoadSnapError

                        call    CloseMyFile
                        mov     Snapshot_OK, TRUE

                        mov     al, z80headerblk+35
                        mov     Last7FFDWrite, al
                        call    Paging_128

                        mov     z80tstatecount, $fnc (GetZ80TstateCount)
                        m2m     totaltstates, z80tstatecount
                        ret

.data?
align 4
z80pageloadedflags      DWORD   ?   ; bit flags per page loaded
z80tstatecount          DWORD   ?
z80_templength          DWORD   ?

destbank                DWORD   ?
z80pageheader           WORD    ?   ; = length of data (not including header)
z80pagenum              BYTE    ?



.code
ReadZ80PageHeader:      mov     ReadStart, offset z80pageheader
                        mov     ReadLen, 3
                        call    ReadMyFile
                        ret

LoadAllZ80Pages:        mov     z80pageloadedflags, 0       ; set all pages unloaded

                        .while  TRUE
                                call    ReadZ80PageHeader

                                .if     !ZERO?              ; out of page data?
                                        xor     al, al      ; Zero flag = loaded OK
                                        ret
                                .endif

                                mov     ReadStart, offset z80pagedata
                                movzx   ecx, z80pageheader

                                ; page length of -1 = page is not compressed and is exactly 16384 bytes long

                                ifc     cx eq -1 then mov ecx, 16384
                                mov     z80_templength, ecx

                                mov     ReadLen, ecx
                                push    ecx
                                call    ReadMyFile
                                pop     ecx
                                retcc   nz                  ; return with any !ZERO error status

                                call    ExpandZ80Page
                                retcc   nz                  ; return with any !ZERO error status
                        .endw

                        xor     al, al      ; Zero flag = loaded OK
                        ret

ExpandZ80Page:          switch  HardwareMode
                                case    HW_16, HW_48, HW_TC2048
                                        switch  z80pagenum
                                                case    4
                                                        invoke  AddZ80MsgItem, 2, 4
                                                        m2m     destbank, currentMachine.bank2
                                                        or      z80pageloadedflags, (1 shl 2)

                                                case    5
                                                        invoke  AddZ80MsgItem, 0, 5
                                                        m2m     destbank, currentMachine.bank0
                                                        or      z80pageloadedflags, (1 shl 0)

                                                case    8
                                                        invoke  AddZ80MsgItem, 5, 8
                                                        m2m     destbank, currentMachine.bank5
                                                        or      z80pageloadedflags, (1 shl 5)

                                                .else
                                                        invoke  AddZ80MsgIgnoredItem, z80pagenum
                                                        xor     al, al      ; Zero flag = loaded OK
                                                        ret
                                        endsw

                                case    HW_128, HW_PLUS2, HW_PLUS2A, HW_PLUS3, HW_PENTAGON128
                                        switch  z80pagenum
                                                case    3
                                                        or      z80pageloadedflags, (1 shl 0)
                                                        invoke  AddZ80MsgItem, 0, 3
                                                        m2m     destbank, currentMachine.bank0

                                                case    4
                                                        or      z80pageloadedflags, (1 shl 1)
                                                        invoke  AddZ80MsgItem, 1, 4
                                                        m2m     destbank, currentMachine.bank1

                                                case    5
                                                        or      z80pageloadedflags, (1 shl 2)
                                                        invoke  AddZ80MsgItem, 2, 5
                                                        m2m     destbank, currentMachine.bank2

                                                case    6
                                                        or      z80pageloadedflags, (1 shl 3)
                                                        invoke  AddZ80MsgItem, 3, 6
                                                        m2m     destbank, currentMachine.bank3

                                                case    7
                                                        or      z80pageloadedflags, (1 shl 4)
                                                        invoke  AddZ80MsgItem, 4, 7
                                                        m2m     destbank, currentMachine.bank4

                                                case    8
                                                        or      z80pageloadedflags, (1 shl 5)
                                                        invoke  AddZ80MsgItem, 5, 8
                                                        m2m     destbank, currentMachine.bank5

                                                case    9
                                                        or      z80pageloadedflags, (1 shl 6)
                                                        invoke  AddZ80MsgItem, 6, 9
                                                        m2m     destbank, currentMachine.bank6

                                                case    10
                                                        or      z80pageloadedflags, (1 shl 7)
                                                        invoke  AddZ80MsgItem, 7, 10
                                                        m2m     destbank, currentMachine.bank7

                                                .else
                                                        invoke  AddZ80MsgIgnoredItem, z80pagenum
                                                        xor     al, al      ; Zero flag = loaded OK
                                                        ret
                                        endsw
                                .else
                                        jmp     LoadNewError
                        endsw

                        mov     ax, z80pageheader ; = length of data

                        cmp     ax, -1
                        jne     @F

                        lea     esi, z80pagedata
                        mov     edi, destbank
                        mov     ecx, 16384/4
                        rep     movsd
                        xor     al, al       ; Z = OK !
                        ret

@@:                     lea     esi, z80pagedata
                        mov     edi, destbank
                        mov     cx, 16384
                        call    ExpandZ80

                        .if     Z80BadFormat == TRUE
                                ADDMESSAGE  "Z80 page expansion != 16384 bytes"
                                jmp     LoadNewError
                        .endif

                        xor     al, al       ; Z = OK !
                        ret

LoadNewError:           xor     al, al
                        cmp     al, 1        ; NZ = Error !
                        ret

.data
_z80msgitem1            db      "...bank ", 0
_z80msgitem2            db      " (z80 page ", 0
_z80msgitem3            db      ", length ", 0
_z80msgend              db      ")", 0

_z80msgignoring         db      "...(ignoring z80 page ", 0

.code
AddZ80MsgItem           proc    banknum:    DWORD,
                                pagenum:    DWORD

                        local   buffer1[256]: BYTE

                        mov     buffer1, 0
                        invoke  szMultiCat, 7, addr buffer1, addr _z80msgitem1, str$ (banknum), addr _z80msgitem2, str$ (pagenum), addr _z80msgitem3, str$ (z80_templength), addr _z80msgend
                        invoke  Add_Message_Item, addr buffer1
                        ret

AddZ80MsgItem           endp

AddZ80MsgIgnoredItem    proc    pagenum:    BYTE

                        local   buffer1[256]: BYTE

                        mov     buffer1, 0
                        movzx   ecx, pagenum

                        invoke  szMultiCat, 5, addr buffer1, addr _z80msgignoring, str$ (ecx), addr _z80msgitem3, str$ (z80_templength), addr _z80msgend
                        invoke  Add_Message_Item, addr buffer1
                        ret

AddZ80MsgIgnoredItem    endp


.data?
Z80BadFormat            BYTE    ?

.code
; esi = ptr to z80 compressed data
; edi = ptr to mem to expand data into (generally Speccy RAM bank)
; cx  = length of expected expanded data

;ExpandZ80:
;;    INT3
;            movzx   ecx, cx
;            invoke  speccpp_ExpandZ80, esi, edi, ecx
;
;            xor     al, TRUE
;            mov     Z80BadFormat, al
;            ret

ExpandZ80:              mov     Z80BadFormat, False

                        xor     bh, bh

z80decode:              mov     al, [esi]
                        inc     esi
                        cmp     al, 0EDh
                        je      z80EDx1
                        mov     [edi], al
                        inc     edi
                        dec     cx
                        jnz     z80decode
                        ret

z80EDx1:                cmp     cx, 1           ; length of data = 1 byte?
                        jne     @F
                        mov     [edi], al
                        inc     edi
                        ret

                    @@: mov     al, [esi]
                        inc     esi
                        cmp     al, 0EDh
                        je      z80EDx2         ; jump if we have 2x ED bytes

                        mov     byte ptr [edi], 0EDh
                        mov     [edi+1], al
                        add     edi, 2

                        sub     cx, 2           ; we know length of data expected (cx) is >= 2 bytes here
                        jnz     z80decode       ; branch back if expecting more data
                        ret

z80EDx2:                mov     bl, [esi]       ; repeat byte count
                        inc     esi
                        mov     al, [esi]       ; repeat byte
                        inc     esi

                        sub     cx, bx          ; test for repeat byte count overflowing expected length of data
                        jc      SetZ80BadFormat

                    @@: mov     [edi], al
                        inc     edi
                        dec     bl
                        jnz     @B

                        or      cx, cx
                        jnz     z80decode       ; branch back if expecting more data
                        ret

SetZ80BadFormat:        mov     Z80BadFormat, True
                        ret


;; ix = ptr to z80 compressed data
;; de = ptr to mem to expand data into (generally Speccy RAM bank)
;; hl  = length of expected expanded data
;
;ExpandZ80   proc
;
;            xor     a
;            ld      (z80badformat), a
;
;z80decode:  ld      a, (ix+0)
;            inc     ix
;            cp      #ED
;            jr      z,_z80EDx1
;            dec     hl
;_z80exit:   ld      (de), a
;            inc     de
;    _loop:  ld      a,h
;            or      l
;            jr      nz,z80decode    ; loop back if expecting more data
;            ret
;
;_z80EDx1:   ld      c, a
;            dec     hl              ; length of data = 1 byte?
;            ld      a, h
;            or      l
;            ld      a, c
;            jr      z,_z80exit       ; branch back to store the ED if so, then exit (hl=0)
;
;            inc     hl
;            ld      a, (ix+0)
;            inc     ix
;            cp      #ED
;            jr      z,_z80EDx2       ; jump if we have 2x ED bytes
;
;            ex      de, hl
;            ld      (hl), #ED
;            inc     hl
;            ld      (hl), a
;            inc     hl
;            ex      de, hl
;
;            dec     hl              ; we know length of data expected (hl) is >= 2 bytes here
;            dec     hl
;            jr      _loop
;
;_z80EDx2:   ld      c, (ix+0)       ; repeat byte count
;            inc     ix
;            ld      a, (ix+0)       ; repeat byte
;            inc     ix
;
;            ld      b, 0            ; test for repeat byte count overflowing expected length of data
;            or      a
;            sbc     hl, bc
;            jr      c, _setz80badformat
;
;            ld      b, c
;    _rept:  ld      (de), a
;            inc     de
;            djnz    _rept
;
;            jr      _loop
;
;_setz80badformat:
;            ld      a, 255
;            ld      (z80badformat), a
;            ret
;
;            endp
;
;z80badformat: db 0


GetZ80TstateCount       proc    uses ebx ecx edx

                        xor     ebx, ebx

                        .if     z80addblklen >= 54
                                mov     edx, MACHINE.FrameCycles
                                shr     edx, 2                          ; edx = quarter tstates

                                movzx   ebx, byte ptr [z80headerblk+57] ; ebx = ts high counter
                                inc     ebx                             ; + 1
                                and     ebx, 3                          ; % 4
                                inc     ebx                             ; ebx = ((ts high counter + 1) % 4) + 1
                                imul    ebx, edx                        ; ebx * quarter tstates

                                movzx   ecx, word ptr [z80headerblk+55]
                                mov     ecx, $fnc (Mod2Int, ecx, edx)   ; bring into quarter tstates range if naughty
                                inc     ecx                             ; ecx = ts low counter + 1

                                sub     ebx, ecx

                                ; reduce to a safe tstate count for naughty z80 snaps
                                mov     ebx, $fnc (Mod2Int, ebx, MACHINE.FrameCycles)
                        .endif

                        return  ebx
GetZ80TstateCount       endp


SetZ80TstateCount       proc    uses    esi ebx ecx edx,
                                lpz80tstates: DWORD

                        mov     esi, lpz80tstates

                        mov     ebx, MACHINE.FrameCycles
                        shr     ebx, 2                                  ; ebx = quarter tstates

                        mov     ecx, $fnc (Mod2Int, totaltstates, ebx)  ; (tstates % quarter_states)

                        mov     eax, ebx
                        sub     eax, ecx                                ; quarter_states - (tstates % quarter_states)
                        dec     eax                                     ; quarter_states - (tstates % quarter_states) - 1
                        mov     [esi], ax

                        invoke  Div2Int, totaltstates, ebx              ; (tstates / quarter_states)
                        add     eax, 3
                        and     eax, 3                                  ; (tstates / quarter_states) + 3 ) % 4
                        mov     [esi+2], al
                        ret
SetZ80TstateCount       endp

; #########################################################################

.data?
align 4
snxheaderbytes          LABEL   DWORD
snafilesize             DWORD   ?
.code

;Offset   Size   Description
;   ------------------------------------------------------------------------
;   0        1      byte   I
;   1        8      word   HL',DE',BC',AF'
;   9        10     word   HL,DE,BC,IY,IX
;   19       1      byte   Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
;   20       1      byte   R
;   21       4      words  AF,SP
;   25       1      byte   IntMode (0=IM0/1=IM1/2=IM2)
;   26       1      byte   BorderColor (0..7, not used by Spectrum 1.7)
;   ===================================================================
;   27       49152  bytes  RAM dump 16384..65535

LoadRegsFromSNASNX      proc    uses    esi edi ebx

                        lea     esi, sna_snx_header

                        DOMOVSB z80registers.i, z80registers
                        DOMOVSW z80registers.hl_.w
                        DOMOVSW z80registers.de_.w
                        DOMOVSW z80registers.bc_.w
                        DOMOVSW z80registers.af_.w

                        DOMOVSW z80registers.hl.w
                        DOMOVSW z80registers.de.w
                        DOMOVSW z80registers.bc.w

                        DOMOVSW z80registers.iy.w
                        DOMOVSW z80registers.ix.w

                        DOMOVSB z80registers.interrupt
                        DOMOVSB z80registers.r

                        DOMOVSW z80registers.af.w
                        DOMOVSW z80registers._sp

                        DOMOVSB z80registers.intmode
    
                        lodsb
                        mov     CM.border, al

                        ret
LoadRegsFromSNASNX      endp

SaveRegsToSNASNX        proc    uses    esi edi ebx

                        lea     edi, sna_snx_header
                        cld

                        mov     al, z80registers.i
                        stosb

                        mov     ax, z80registers.hl_.w
                        stosw

                        mov     ax, z80registers.de_.w
                        stosw

                        mov     ax, z80registers.bc_.w
                        stosw

                        mov     ax, z80registers.af_.w
                        stosw

                        mov     ax, z80registers.hl.w
                        stosw

                        mov     ax, z80registers.de.w
                        stosw

                        mov     ax, z80registers.bc.w
                        stosw

                        mov     ax, z80registers.iy.w
                        stosw

                        mov     ax, z80registers.ix.w
                        stosw

                      ; Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
                        mov     al, currentMachine.iff2
                        shl     al, 2
                        and     al, 4
                        stosb

                        mov     al, z80registers.r
                        and     al, 127
                        or      al, Reg_R_msb
                        stosb

                        mov     ax, z80registers.af.w
                        stosw

                        mov     ax, z80registers._sp
                        stosw

                        mov     al, z80registers.intmode
                        stosb

                        mov     al, CM.border
                        stosb

                        ret

SaveRegsToSNASNX        endp

; entry point when filetype is known to be ".sna"

Loadsnafile:            invoke  Init_AY

                        invoke  WipeSpeccyMem

                        mov     Filename, esi
                        call    OpenMyReadFile
                        or      eax, eax
                        jz      LdCancel

                        mov     Snapshot_OK, FALSE

                        mov     snafilesize, $fnc (GetFileSize, WorkFH, NULL)

                        mov     ReadStart, offset sna_snx_header
                        mov     ReadLen, 27
                        call    ReadMyFile
                        jnz     LoadSnapError

                        invoke  LoadRegsFromSNASNX

                        mov     al, z80registers.r
                        and     al, 128
                        mov     Reg_R_msb, al

                        mov     al, z80registers.interrupt      ; bit 2 contains IFF2, 1=EI/0=DI
                        shr     al, 2
                        and     al, 1
                        mov     currentMachine.iff1, al
                        mov     currentMachine.iff2, al

                        m2m     ReadStart, currentMachine.bank5
                        mov     ReadLen, 16384
                        call    ReadMyFile
                        jnz     LoadSnapError

                        m2m     ReadStart, currentMachine.bank2
                        mov     ReadLen, 16384
                        call    ReadMyFile
                        jnz     LoadSnapError

                        .if     snafilesize == 49179
                                ; 48K sna file
                                mov     HardwareMode, HW_48
                                call    Machine_Initialise
            
                                m2m     ReadStart, currentMachine.bank0
                                mov     ReadLen, 16384
                                call    ReadMyFile
                                jnz     LoadSnapError

                                mov     bx, z80registers._sp
                                call    MemGetWord  ; get PC return address from stack
                                mov     zPC, ax     ; and set it
                                mov     Z80PC, ax
                                xor     ax, ax
                                call    MemPokeWord ; zero the snapshot return address
                                add     z80registers._sp, 2      ; equalize stack pointer

                        .else
                                ; 128K sna file
                                .if     sna_is_128k_enabled == TRUE
                                        mov     al, HW_128          ; -sna128 switch specified
                                .else
                                        mov     al, HW_PENTAGON128  ; default machine
                                .endif
                                mov     HardwareMode, al
                                call    Machine_Initialise

                                mov     ReadStart, offset z80pagedata    ; 48k available here
                                mov     ReadLen, 16384+4         ; = 1 Ram page + 4 bytes extra header data
                                call    ReadMyFile
                                jnz     LoadSnapError

                                mov     al, [z80pagedata+16386]  ; port 7FFD setting
                                mov     Last7FFDWrite, al
                                call    Paging_128

                                .if     sna_is_128k_enabled == FALSE
                                        mov     al, [z80pagedata+16387]  ; TR-DOS rom paged (1) or not (0)
                                        .if     al == 1
                                                call    TrDos_Page_In
                                        .else
                                                call    TrDos_Page_Out
                                        .endif
                                .endif

                                mov     edi, currentMachine.RAMWRITE6           ; ptr to currently paged ram
                                lea     esi, z80pagedata
                                mov     ecx, 16384/4
                                rep     movsd

                                mov     ax, word ptr [z80pagedata+16384]
                                mov     zPC, ax
                                mov     Z80PC, ax

                                ; load remaining Ram pages
                                xor     al, al
                                call    LoadSnaRamPage
                                jnz     LoadSnapError

                                mov     al, 1
                                call    LoadSnaRamPage
                                jnz     LoadSnapError

                                mov     al, 3
                                call    LoadSnaRamPage
                                jnz     LoadSnapError

                                mov     al, 4
                                call    LoadSnaRamPage
                                jnz     LoadSnapError

                                mov     al, 6
                                call    LoadSnaRamPage
                                jnz     LoadSnapError

                                mov     al, 7
                                call    LoadSnaRamPage
                                jnz     LoadSnapError
                        .endif

; 48K and 128K sna loader paths re-merge here

                                call    CloseMyFile
                                mov     Snapshot_OK, TRUE

                                mov     al, CM.border
                                call    Set_BorderColour
                                ret

LoadSnaRamPage:                 mov     bl, [z80pagedata+16386] ; port 7FFD setting
                                and     bl, 7
                                cmp     al, bl
                                je      @F                      ; page is already loaded; Z=No error!

                                and     eax, 7
                                mov     eax, [currentMachine.bank_ptrs+eax*4]   ; ptr to Ram page

                                mov     ReadStart, eax
                                mov     ReadLen, 16384
                                call    ReadMyFile
                                cmp     eax, 16384              ; Z=No error else error!

@@:                             ret

; #########################################################################

; entry point when filetype is known to be ".sna"

Loadsnxfile:
            invoke  Init_AY

                        invoke  WipeSpeccyMem

            mov     Filename, esi
            call    OpenMyReadFile
            or      eax, eax
            jz      LdCancel

            mov     Snapshot_OK, FALSE

            mov     ReadStart, offset DummyMem
            mov     ReadLen, 6
            call    ReadMyFile
            jnz     LoadSnapError

            cmp     dword ptr [DummyMem], "ANSX"
            jnz     LoadSnapError

            mov     ah, DummyMem+4                  ; bytes in following header
            mov     al, DummyMem+5
            and     eax, 0FFFFh
            mov     snxheaderbytes, eax

            cmp     eax, 27                         ; header too short?
            jc      LoadSnapError
            cmp     eax, 1024                       ; header too long?
            jnc     LoadSnapError

            mov     HardwareMode, HW_48
            call    Machine_Initialise

            mov     ReadStart, offset sna_snx_header ;z80registers.i ; read the registers
            mov     ReadLen, 27
            call    ReadMyFile
            jnz     LoadSnapError

            invoke  LoadRegsFromSNASNX

            mov     al, z80registers.r
            and     al, 128
            mov     Reg_R_msb, al

            mov     al, z80registers.interrupt                  ; bit 2 contains IFF2, 1=EI/0=DI
            shr     al, 2
            and     al, 1
            mov     currentMachine.iff1, al
            mov     currentMachine.iff2, al

            mov     ReadStart, offset DummyMem+32   ; read additional header bytes
            mov     eax, snxheaderbytes
            sub     eax, 27
            mov     ReadLen, eax
            call    ReadMyFile
            jnz     LoadSnapError

snxcounthi  equ     DummyMem    ; byte
snxcountlo  equ     DummyMem+1  ; byte
snxflag     equ     DummyMem+2  ; byte
snxfillbyte equ     DummyMem+3  ; byte

            mov     edi, currentMachine.bank5
            mov     ebx, 49152      ; bytes to read in total

            .while  ebx > 0
                    mov     ReadStart, offset snxcounthi
                    mov     ReadLen, 1
                    call    ReadMyFile
                    jnz     LoadSnapError

                    .if     snxcounthi >= 0E0h
                            mov     cl, snxcounthi

                            movzx   ax, cl
                            and     ax, 15
                            inc     ax
                            mov     snxcounthi, ah
                            mov     snxcountlo, al

                            shr     cl, 4
                            .if     cl == 0Eh
                                    mov     snxflag, 0      ; uncompressed
                            .else
                                    mov     snxflag, 0FFh   ; compressed
                            .endif
                    .else
                            mov     ReadStart, offset snxcountlo    ; read second 'count' byte and the flag byte
                            mov     ReadLen, 2
                            call    ReadMyFile
                            jnz     LoadSnapError
                    .endif

                    switch  snxflag
                            case    0       ; not compressed
                                    mov     ReadStart, edi
                                    mov     ah, snxcounthi
                                    mov     al, snxcountlo
                                    and     eax, 0FFFFh
                                    mov     ReadLen, eax

                                    sub     ebx, eax
                                    jc      LoadSnapError
                                    add     edi, eax

                                    call    ReadMyFile
                                    jnz     LoadSnapError

                            case    0FFh    ; compressed
                                    mov     ReadStart, offset snxfillbyte
                                    mov     ReadLen, 1
                                    call    ReadMyFile
                                    jnz     LoadSnapError

                                    mov     cl, snxfillbyte
                                    mov     dh, snxcounthi
                                    mov     dl, snxcountlo
                                    .while  dx > 0
                                            dec     dx

                                            mov     [edi], cl
                                            inc     edi
                                            sub     ebx, 1
                                            jc      LoadSnapError
                                    .endw

                            .else
                                    jmp     LoadSnapError
                    endsw
            .endw

            call    CloseMyFile
            mov     Snapshot_OK, TRUE

            mov     bx, z80registers._sp
            call    MemGetWord  ; get PC return address from stack
            mov     zPC, ax     ; and set it
            mov     Z80PC, ax
            xor     ax, ax
            call    MemPokeWord ; zero the snapshot return address
            add     z80registers._sp, 2      ; equalize stack pointer

            mov     al, CM.border
            call    Set_BorderColour
            ret

; #########################################################################

; entry point when filetype is known to be ".sp"

LoadSPfile:
            invoke  Init_AY

            invoke  WipeSpeccyMem

            mov     Filename, esi
            call    OpenMyReadFile
            or      eax, eax
            jz      LdCancel

            mov     Snapshot_OK, FALSE

            mov     ReadStart, offset SPHeader
            mov     ReadLen, 38
            call    ReadMyFile
            jnz     LoadSnapError

            lea     esi, SPHeader
            lodsw
            cmp     ax, "PS"
            jne     LoadSnapError

            xor     eax, eax
            lodsw
            mov     ReadLen, eax    ; set ReadLen param
            mov     bx, ax          ; program length

            lodsw
            mov     ReadStart, eax

            mov     cx, ax          ; program location
            cmp     ax, 16384
            jc      LoadSnapError   ; can't load in Rom area

            sub     ReadStart, 16384
            push    eax
            mov     eax, currentMachine.bank5
            add     ReadStart, eax  ; ReadStart = actual load address in Z80 memory
            pop     eax

            add     bx, cx
            jnc     @F              ; <= 65535 is fine
            jne     LoadSnapError   ; else must be = 0!

@@:         lodsw
            mov     z80registers.bc.w, ax
            lodsw
            mov     z80registers.de.w, ax
            lodsw
            mov     z80registers.hl.w, ax
            lodsw
            mov     z80registers.af.w, ax
            lodsw
            mov     z80registers.ix.w, ax
            lodsw
            mov     z80registers.iy.w, ax

            lodsw
            mov     z80registers.bc_.w, ax
            lodsw
            mov     z80registers.de_.w, ax
            lodsw
            mov     z80registers.hl_.w, ax
            lodsw
            mov     z80registers.af_.w, ax

            lodsb
            mov     z80registers.r, al
            and     al, 128
            mov     Reg_R_msb, al

            lodsb
            mov     z80registers.i, al

            lodsw
            mov     z80registers._sp, ax
            lodsw
            mov     zPC, ax
            mov     Z80PC, ax

            lodsw   ; skip reserved

            lodsb   ; border colour
            and     al, 7
            call    Set_BorderColour

            lodsb   ; skip reserved

            lodsw   ; status word
            mov     dx, ax

            test    al, 1
            .if     ZERO?
                    DISABLEINTS
            .else
                    ENABLEINTS
            .endif

            xor     al, al      ; = IM0
            bt      dx, 3
            jc      @F
            inc     al          ; = IM1
            bt      dx, 1
            jnc     @F
            inc     al          ; = IM2
@@:         mov     z80registers.intmode, al

            call    ReadMyFile ; ReadStart & ReadLen setup earlier
            jnz     LoadSnapError

            call    CloseMyFile
            mov     Snapshot_OK, TRUE

            mov     HardwareMode, HW_48
            call    Machine_Initialise
            ret

; #########################################################################

; entry point when filetype is known to be ".szx"

LoadSzxfile:
            ; close the currently inserted tape file, the SZX snapshot will insert any specified tape
            ; the currently inserted tape will be restored if the SZX snapshot fails to load
            invoke  CloseTapeFile

            mov     uSpeech_Enabled,    FALSE
            mov     SpecDrum_Enabled,   FALSE
            mov     CBI_Enabled,        FALSE
            mov     DivIDEEnabled,      FALSE
            mov     MicroSourceEnabled, FALSE

            invoke  LoadSZXFile, esi

            .if     eax == 0
                    push    esi
                    switch  $fnc (GetLastError)
                            case    SZX_FIRSTERROR..SZX_LASTERROR - 1
                                    mov     esi, $fnc (GetSZXErrorString, eax)

                            case    SZXERR_EMU_UNSUPPORTED_HARDWARE
                                    mov     esi, CTXT ("Unsupported hardware specified in this snapshot")

                            .else
                                    mov     esi, CTXT ("Unknown error")
                    endsw
                    invoke  ShowMessageBox, $fnc (GetActiveWindow), esi, addr szWindowName, MB_OK or MB_ICONINFORMATION

                    pop     esi
                    mov     Snapshot_OK, FALSE
                    ret
            .endif

            mov     Snapshot_OK, TRUE
            ret

; #########################################################################

.const
DiskHeaderStr       db  "MV - CPC"
szPlus3DiskFilter   db  "+3 Disk files (*.dsk)", 0, "*.dsk", 0, 0
szTRDOSDiskFilter   db  "TRDOS Disk files (*.trd;*.scl)", 0, "*.trd;*.scl", 0, 0
szPLUSDDiskFilter   db  "PLUS-D Disk files (*.mgt;*.img)", 0, "*.mgt;*.img", 0, 0

.code
InsertDisk  proc

            local   ofn:    OPENFILENAME

            switch  HardwareMode
                    case    HW_PLUS3
                            invoke  GetFileName, hWnd, SADD ("Insert +3 Disk"), addr szPlus3DiskFilter, addr ofn, addr insertplus3diskfilename, 0
                            ifc     eax ne 0 then invoke  ReadFileType, addr insertplus3diskfilename
                            ret

                    case    HW_PENTAGON128
                            invoke  GetFileName, hWnd, SADD ("Insert TR-DOS Disk"), addr szTRDOSDiskFilter, addr ofn, addr inserttrdosdiskfilename, 0
                            ifc     eax ne 0 then invoke  ReadFileType, addr inserttrdosdiskfilename
                            ret
                    .else
                            .if     PLUSD_Enabled == TRUE
                                    invoke  GetFileName, hWnd, SADD ("Insert PLUS-D Disk"), addr szPLUSDDiskFilter, addr ofn, addr insertplusddiskfilename, 0
                                    ifc     eax ne 0 then invoke  ReadFileType, addr insertplusddiskfilename
                                    ret
                            .endif

                            .if     CBI_Enabled == TRUE
                                    invoke  GetFileName, hWnd, SADD ("Insert CBI Beta Disk"), addr szTRDOSDiskFilter, addr ofn, addr insertCBIdiskfilename, 0
                                    ifc     eax ne 0 then invoke  ReadFileType, addr insertCBIdiskfilename
                                    ret
                            .endif
            endsw
            ret
InsertDisk  endp

; 'targetdrive' var is set to 0 for dropped files in WM_DROPFILES handler

InsertDisk_1 proc   uses        esi edi ebx,
                    lpFilename: DWORD

            local   ext [8]:    BYTE

            .if     $fnc (szLen, lpFilename) < 5
                    ret
            .endif

            invoke  szRight, lpFilename, addr ext, 4
            invoke  lcase,   addr ext
            mov     esi,     dword ptr [ext]

            switch  HardwareMode
                    case    HW_PLUS3
                            .if     esi == "ksd."
                                    invoke  LoadPlus3Diskfile, lpFilename
                            .endif

                    case    HW_PENTAGON128
                            .if     (esi == "drt.") || (esi == "lcs.")
                                    invoke  LoadTRDOSDiskfile, lpFilename
                            .endif
                    .else
                            .if     PLUSD_Enabled == TRUE
                                    .if     (esi == "tgm.") || (esi == "gmi.")
                                            invoke  LoadPLUSDDiskfile, lpFilename
                                    .endif
                            .endif

                            .if     CBI_Enabled == TRUE
                                    .if     (esi == "drt.") || (esi == "lcs.")
                                            invoke  LoadCBIDiskfile, lpFilename
                                    .endif
                            .endif
            endsw
            ret

InsertDisk_1 endp

LoadPlus3Diskfile   proc    lpFilename: DWORD

                    strncpy lpFilename, addr insertplus3diskfilename, sizeof insertplus3diskfilename

                    .if     AutoloadPlus3DSK == TRUE
                            invoke  GetAsyncKeyState, VK_SHIFT
                            and     eax, 80000000h
                            .if     ZERO?
                                    invoke  LoadSZXMemory, addr Snap_Plus3DSK, Snap_Plus3DSKSize
                            .endif
                    .endif

                    invoke  u765_InsertDisk, FDCHandle, lpFilename, TargetDrive

                    .if     inhibit_recent_file == FALSE
                            strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                            invoke      AddRecentFile
                    .endif
                    ret
LoadPlus3Diskfile   endp

LoadTRDOSDiskfile   proc    lpFilename: DWORD

                    strncpy lpFilename, addr inserttrdosdiskfilename, sizeof inserttrdosdiskfilename

                    .if     (TargetDrive == 0) && (AutoloadTrdosDSK == TRUE)
                            invoke  GetAsyncKeyState, VK_SHIFT
                            and     eax, 80000000h
                            .if     ZERO?
                                    invoke  LoadSZXMemory, addr SnapPentagonDisk, SnapPentagonDiskSize
                            .endif
                    .endif

                    wd1793_InsertTRDOSDisk   TRDOSHandle, ZeroExt (TargetDrive), lpFilename

                    .if     inhibit_recent_file == FALSE
                            strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                            invoke      AddRecentFile
                    .endif
                    ret
LoadTRDOSDiskfile   endp

LoadPLUSDDiskfile   proc    lpFilename: DWORD

                    strncpy lpFilename, addr insertplusddiskfilename, sizeof insertplusddiskfilename

                    inc     TargetDrive     ; +D disk units are 1-based

                    wd1793_InsertPlusDDisk   PLUSDHandle, ZeroExt (TargetDrive), lpFilename

                    .if     inhibit_recent_file == FALSE
                            strncpy lpFilename, addr szRecentFileName, sizeof szRecentFileName
                            invoke      AddRecentFile
                    .endif
                    ret
LoadPLUSDDiskfile   endp

LoadCBIDiskfile     proc    lpFilename: DWORD

                    strncpy lpFilename, addr insertCBIdiskfilename, sizeof insertCBIdiskfilename

;                    .if     (TargetDrive == 0) && (AutoloadTrdosDSK == TRUE)
;                            invoke  GetAsyncKeyState, VK_SHIFT
;                            and     eax, 80000000h
;                            .if     ZERO?
;                                    invoke  LoadSZXMemory, addr SnapPentagonDisk, SnapPentagonDiskSize
;                            .endif
;                    .endif

                    wd1793_InsertTRDOSDisk   CBIHandle, ZeroExt (TargetDrive), lpFilename

                    .if     inhibit_recent_file == FALSE
                            strncpy lpFilename, addr szRecentFileName, sizeof insertCBIdiskfilename
                            invoke      AddRecentFile
                    .endif
                    ret
LoadCBIDiskfile     endp

; #########################################################################

LoadSnapError:
            ADDMESSAGE  "Snapshot loading failed"
            mov     Snapshot_OK, FALSE  ; signal error loading snapshot

            call    CloseMyFile
            mov     zPC, 0
            mov     Z80PC, 0

            invoke  ShowMessageBox, $fnc (GetActiveWindow), SADD ("Invalid snapshot file"), addr szWindowName, MB_OK or MB_ICONINFORMATION

LdCancel:   ret

; #########################################################################

.data?
loadfilestext   TEXTSTRING  <>
ploadfilestext  DWORD       ?

.code
LoadFiles:      mov     GotMultiface48Rom,  FALSE
                mov     GotMultiface128Rom, FALSE
                mov     GotMultiface3Rom,   FALSE

                invoke  GetAppPath,          addr temppathstring
                invoke  SetCurrentDirectory, addr temppathstring
                or      eax, eax
                je      LoadFilesFail

                invoke  INITTEXTSTRING, addr loadfilestext, addr ploadfilestext

                mov     LoadError,   FALSE
                invoke  LoadROMFile, addr Mf48Filename, addr Mf48_Mem, 8192
                ifc     LoadError    eq FALSE then mov GotMultiface48Rom, TRUE

                mov     LoadError,   FALSE
                invoke  LoadROMFile, addr Mf128Filename, addr Mf128_Mem, 8192
                ifc     LoadError    eq FALSE then mov GotMultiface128Rom, TRUE

                mov     LoadError,   FALSE
                invoke  LoadROMFile, addr Mf3Filename, addr Mf3_Mem, 8192
                ifc     LoadError    eq FALSE then mov GotMultiface3Rom, TRUE

                invoke  INITTEXTSTRING, addr loadfilestext, addr ploadfilestext

                mov     LoadError, FALSE
                invoke  LoadROMFile, addr Rom48Filename,          addr Rom_48,          16384
                invoke  LoadROMFile, addr Rom128Filename,         addr Rom_128,         32768
                invoke  LoadROMFile, addr RomPlus2Filename,       addr Rom_Plus2,       32768
                invoke  LoadROMFile, addr RomPlus3Filename,       addr Rom_Plus3,       65536
                invoke  LoadROMFile, addr RomPentagon128Filename, addr Rom_Pentagon128, 32768

                invoke  LoadTRDosROM

                invoke  LoadROMFile, addr RomTK90xFilename,       addr Rom_TK90x,       16384
                invoke  LoadROMFile, addr Rom_CBIFilename,        addr Rom_CBI,         16384

                invoke  LoadROMFile, addr RomTC2048Filename,      addr Rom_TC2048,      16384
                invoke  LoadROMFile, addr RomMicroSourceFilename, addr Rom_MicroSource, 8192

                .if     byte ptr [loadfilestext] != 0
                        ; some ROM files are missing
                        ADDCHAR             ploadfilestext, 10
                        ADDDIRECTTEXTSTRING ploadfilestext, "Do you wish emulation to continue?"
                        invoke  ShowMessageBox, hWnd, addr loadfilestext, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2
                        .if     eax == IDYES
                                mov     LoadError, FALSE
                        .endif
                .endif
                ret

LoadFilesFail:  ifc     WorkFH ne 0 then call CloseMyFile

                mov     LoadError, TRUE
                ret

LoadTRDosROM    proc    uses    esi

                lea     esi, RomTrdosFilename

                switch  $fnc (filesize, esi)
                        case    16384
                                invoke  LoadROMFile, esi, addr Rom_Trdos, 16384
                        case    8192
                                invoke  LoadROMFile, esi, addr Rom_Trdos, 8192
                                memcpy  addr Rom_Trdos, addr Rom_Trdos+8192, 8192
                        .else
                                ; we couldn't open this file or file was illegal size
                                ADDDIRECTTEXTSTRING ploadfilestext, "Missing ROM file: "
                                ADDCHAR             ploadfilestext, 34
                                ADDTEXTSTRING       ploadfilestext, esi
                                ADDCHAR             ploadfilestext, 34, 10
                                mov     LoadError, TRUE
                endsw
                ret

LoadTRDosROM    endp

LoadROMFile     proc    lpROMFilename:DWORD, lpAddress:DWORD, Filesize:DWORD

                m2m     Filename, lpROMFilename
                call    OpenMyReadFile
                .if     eax != 0
                        ; we opened this file
                        m2m     ReadStart, lpAddress
                        m2m     ReadLen,   Filesize
                        call    ReadMyFile
                        .if     eax != Filesize
                                mov     LoadError, TRUE
                        .endif
                        call    CloseMyFile
                        ret
                .else
                        ; we couldn't open this file
                        ADDDIRECTTEXTSTRING ploadfilestext, "Missing ROM file: "
                        ADDCHAR             ploadfilestext, 34
                        ADDTEXTSTRING       ploadfilestext, lpROMFilename
                        ADDCHAR             ploadfilestext, 34, 10
                        mov     LoadError, TRUE
                .endif
                ret

LoadROMFile     endp

; #########################################################################

OpenMyReadFile: ifc     WorkFH ne 0 then return 0
                invoke  CreateFile, Filename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

                ifc     eax eq INVALID_HANDLE_VALUE then xor eax, eax
                mov     WorkFH, eax
                ret

OpenMyWriteFile:ifc     WorkFH ne 0 then return 0
                invoke  CreateFile, Filename, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL

                ifc     eax eq INVALID_HANDLE_VALUE then xor eax, eax
                mov     WorkFH, eax
                ret

; #########################################################################

CloseMyFile:    ifc     WorkFH ne 0 then invoke CloseHandle, WorkFH : mov WorkFH, 0
                ret

; #########################################################################

ReadMyFile:     invoke  ReadFile, WorkFH, ReadStart, ReadLen, addr BytesMoved, NULL
                mov     eax, BytesMoved     ; eax returns with number of bytes read
                cmp     eax, ReadLen        ; ZERO set if 'ReadLen' bytes successfully loaded
                ret

WriteMyFile:    invoke  WriteFile, WorkFH, WriteStart, WriteLen, addr BytesSaved, NULL
                mov     eax, BytesSaved     ; eax returns with number of bytes read
                cmp     eax, WriteLen       ; ZERO set if 'WriteLen' bytes successfully written
                ret

; #########################################################################

ToggleFullSpeed:
                cmp     MAXIMUMSPEED, TRUE
                je      SetNormalSpeed

SetFullSpeed:
                mov     al, FrameSkipCounter
                mov     OldFrameSkipCounter, al
                mov     MAXIMUMSPEED, TRUE
                ret

SetNormalSpeed:
                mov     al, OldFrameSkipCounter
                mov     FrameSkipCounter, al
                mov     MAXIMUMSPEED, FALSE
                ret

; #########################################################################

.data
szScrFilter     db  "SCR files",0,"*.scr",0, 0

.code
SaveScreenFile  proc

                local   ofn:    OPENFILENAME,
                        ScrFH:  DWORD

                local   tempfile [MAX_PATH]:    BYTE

                strncpy addr SCRSavefilename, addr tempfile, sizeof SCRSavefilename

                invoke  RemoveExtension, addr tempfile

                invoke  SaveFileName, hWnd, SADD ("Save Screen"), addr szScrFilter, addr ofn, addr tempfile, addr SCRExt, 0
                .if     eax != 0
                        strncpy         addr tempfile, addr SCRSavefilename, sizeof SCRSavefilename
                        ADDEXTENSION    addr SCRSavefilename, addr SCRExt

                        mov     ScrFH, $fnc (CreateFile, addr SCRSavefilename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL)
                        .if     ScrFH != INVALID_HANDLE_VALUE
                                ifc     SPGfx.zxDisplayOrg eq 0 then m2m SPGfx.zxDisplayOrg, currentMachine.bank5
                                invoke  WriteFile,   ScrFH, SPGfx.zxDisplayOrg, 6912, addr BytesSaved, NULL
                                invoke  CloseHandle, ScrFH
                        .else
                                invoke  ShowMessageBox, hWnd, SADD ("Unable to write SCR file"), addr szWindowName, MB_OK or MB_ICONERROR
                        .endif
                .endif
                ret

SaveScreenFile  endp

; #########################################################################

ClearDIB:       mov     edi, lpDIBBits
                mov     ecx, (DIBWidth*DIBHeight)/4 ; size of display
                xor     eax, eax
                rep     stosd
                ret

; #########################################################################

AllocateResources:
                    mov     lpBITMAPINFO, AllocMem (2048)
                    or      eax, eax
                    je      AllocError

                    mov     CompatibleDC, $fnc (CreateCompatibleDC, NULL)
                    or      eax, eax
                    je      AllocError

                    memcpy  addr BITMAPINFO_struct, lpBITMAPINFO, BITMAPINFOSIZE

                    mov     lpDIBSection, $fnc (CreateDIBSection, CompatibleDC, lpBITMAPINFO, DIB_RGB_COLORS, addr lpDIBBits, NULL, NULL)
                    or      eax, eax
                    je      AllocError

                    mov     eax, lpDIBBits
                    add     eax, DIBWidth*DIBHeight
                    mov     lpEndDIBBits, eax

                    mov     displayptr,     AllocMem (DIBWidth*DIBHeight)
                    or      eax, eax
                    je      AllocError

                    mov     ULAReadAddress, AllocMem (72000*2)
                    or      eax, eax
                    je      AllocError

                    mov     TZXBlockPtrs,   AllocMem (MAXTZXBLOCKS*4) ; dword for each block ptr
                    or      eax, eax
                    je      AllocError

                    mov     SPGfx.ptrSpecColourTable, AllocMem (SPECCOLOURTABLESIZE)
                    or      eax, eax
                    je      AllocError

                    mov     SPGfx.ptrTimexColourTable, AllocMem (TIMEXCOLOURTABLESIZE)
                    or      eax, eax
                    je      AllocError

                    mov     SPGfx.ptrULA64ColourTable, AllocMem (ULA64COLOURTABLESIZE)
                    or      eax, eax
                    je      AllocError

                    invoke  PrepSpecColourTables
                    invoke  PrepTimexColourTables
                    invoke  PrepULA64ColourTables

                    return  TRUE    ; all is OK

AllocError:         return  FALSE   ; something failed

; #########################################################################

FreeResources:      ifc     lpDIBSection  ne NULL then invoke  DeleteObject, lpDIBSection
                    ifc     CompatibleDC  ne NULL then invoke  DeleteDC,     CompatibleDC
                    ifc     lpBITMAPINFO  ne NULL then invoke  GlobalFree,   lpBITMAPINFO

                    invoke  FreeMemory, ULAReadAddress
                    invoke  FreeMemory, displayptr
                    invoke  FreeMemory, TZXBlockPtrs

                    invoke  FreeMemory, SPGfx.ptrSpecColourTable
                    invoke  FreeMemory, SPGfx.ptrTimexColourTable
                    invoke  FreeMemory, SPGfx.ptrULA64ColourTable

                    IFDEF   PACMAN
                    invoke  Disable_Pacmode
                    ENDIF
                    ret

FreeMemory          proc    MemPtr:DWORD
                    ifc     MemPtr ne NULL then invoke GlobalFree, MemPtr
                    ret
FreeMemory          endp

align 16
RenderSpeccy        proc    hWin:   DWORD

                    local   PaintStruct: PAINTSTRUCT

                    invoke  BeginPaint, hWin, addr PaintStruct

                    ifc     FullScreenMode then invoke MaskSpeccyCorners

                    .if     SurfacesReady
                            invoke  DIBToScreen, hWin
                            ifc     eax ne DD_OK then mov SPGfx.FrameBlit, TRUE
                    .endif

                    invoke  EndPaint, hWin, addr PaintStruct
                    ret

RenderSpeccy        endp

align 16
; called when fullscreen only
MaskSpeccyCorners   proc    uses esi edi ebx

                    ifc     RoundedCorners_Enabled eq FALSE then ret

                    invoke  GetSrcDIBRect, addr SrcRect

                    mov     esi, @EVAL (SrcRect.top * DIBWidth + lpDIBBits)
                    mov     edi, esi

                    add     esi, SrcRect.left
                    add     edi, SrcRect.right
                    sub     edi, 2

                    push    esi
                    push    edi

                    mov     al,  CLR_MASKEDCORNER
                    mov     edx, DIBWidth
                    call    MaskCorners

                    pop     edi
                    pop     esi

                    mov     ecx, @EVAL (SrcRect.bottom - SrcRect.top - 1 * DIBWidth)
                    add     esi, ecx
                    add     edi, ecx

                    mov     al,  CLR_MASKEDCORNER
                    mov     edx, -DIBWidth
                    call    MaskCorners
                    ret

MaskSpeccyCorners   endp

align 16
MaskCorners:        mov     bh, 12
                    call    DrawMaskLine
                    mov     bh, 8
                    call    DrawMaskLine
                    mov     bh, 6
                    call    DrawMaskLine
                    mov     bh, 4
                    call    DrawMaskLine
                    mov     bh, 3
                    call    DrawMaskLine
                    mov     bh, 3
                    call    DrawMaskLine
                    mov     bh, 2
                    call    DrawMaskLine
                    mov     bh, 2
                    call    DrawMaskLine
                    mov     bh, 1
                    call    DrawMaskLine
                    mov     bh, 1
                    call    DrawMaskLine
                    mov     bh, 1
                    call    DrawMaskLine
                    mov     bh, 1
                    call    DrawMaskLine
                    ret

align 16
DrawMaskLine:       push    esi
                    push    edi
@@:                 mov     [esi], al
                    inc     esi
                    mov     [edi], al
                    dec     edi
                    dec     bh
                    jnz     @B
                    pop     edi
                    pop     esi
                    add     edi, edx
                    add     esi, edx
                    ret

PrepSpecColourTables proc   uses esi edi ebx

                    local   Bright:   BYTE,
                            Paper:    BYTE,
                            Ink:      BYTE,
                            ByteNum:  BYTE,
                            BitMask:  BYTE,
                            BrightCol:BYTE

                    mov edi, SPGfx.ptrSpecColourTable

                    mov Bright, 0

                    SETLOOP 2
                        mov al, Bright
                        shl al, 4
                        mov BrightCol, al    ; 16 * Bright

                        mov Paper, 0
                        SETLOOP 8

                            mov Ink, 0
                            SETLOOP 8

                                mov ByteNum, 0
                                SETLOOP 256
                                    mov BitMask, 128

                                    SETLOOP 8
                                        mov     al, ByteNum
                                        and     al, BitMask

                                        .if     !ZERO?
                                                mov al, Ink
                                        .else   
                                                mov al, Paper
                                        .endif

                                        add     al, BrightCol
                                        add     al, CLR_SPECBASE
                                        stosb

                                        shr     BitMask, 1
                                    ENDLOOP

                                    inc ByteNum
                                ENDLOOP

                                inc Ink
                            ENDLOOP

                            inc Paper
                        ENDLOOP

                        inc Bright
                    ENDLOOP
                    ret

PrepSpecColourTables endp


PrepTimexColourTables proc  uses esi edi ebx

                    local   Bright:   BYTE,
                            Paper:    BYTE,
                            Ink:      BYTE,
                            ByteNum:  BYTE,
                            BitMask:  BYTE,
                            BrightCol:BYTE

                    mov edi, SPGfx.ptrTimexColourTable

                    mov Bright, 0

                    SETLOOP 2
                        mov al, Bright
                        shl al, 4
                        mov BrightCol, al    ; 16 * Bright
                        mov Paper, 0

                        SETLOOP 8
                            mov Ink, 0

                            SETLOOP 8
                                mov ByteNum, 0

                                SETLOOP 256
                                    mov BitMask, 128

                                    SETLOOP 8
                                        mov     al, ByteNum
                                        and     al, BitMask

                                        .if     !ZERO?
                                                mov al, Ink
                                        .else   
                                                mov al, Paper
                                        .endif

                                        add     al, BrightCol
                                        add     al, CLR_SPECBASE
                                        stosb
                                        stosb   ; store twice for Timex to pixel double to 512 pixels in normal screen modes

                                        shr     BitMask, 1
                                    ENDLOOP

                                    inc ByteNum
                                ENDLOOP

                                inc Ink
                            ENDLOOP

                            inc Paper
                        ENDLOOP

                        inc Bright
                    ENDLOOP

                    ret
PrepTimexColourTables   endp


PrepULA64ColourTables proc  uses esi edi ebx

                    local   Flash:    BYTE,
                            Bright:   BYTE,
                            Paper:    BYTE,
                            Ink:      BYTE,
                            ByteNum:  BYTE,
                            BitMask:  BYTE,
                            FlashCol: BYTE,
                            BrightCol:BYTE

                    mov edi, SPGfx.ptrULA64ColourTable

                    mov Flash, 0
                    SETLOOP 2
                            mov al, Flash
                            shl al, 5
                            mov FlashCol, al    ; 32 * Flash

                        mov Bright, 0
                        SETLOOP 2
                            mov al, Bright
                            shl al, 4
                            mov BrightCol, al    ; 16 * Bright

                            mov Paper, 0
                            SETLOOP 8

                                mov Ink, 0
                                SETLOOP 8

                                    mov ByteNum, 0
                                    SETLOOP 256

                                        ; The complete index can be calculated as 
                                        ; ink_colour = (FLASH * 2 + BRIGHT) * 16 + INK
                                        ; paper_colour = (FLASH * 2 + BRIGHT) * 16 + PAPER + 8

                                        mov BitMask, 128
                                        SETLOOP 8
                                            mov     al, ByteNum
                                            and     al, BitMask

                                            .if     !ZERO?
                                                    mov al, Ink
                                            .else
                                                    mov al, Paper
                                                    add al, 8
                                            .endif

                                            add     al, FlashCol
                                            add     al, BrightCol
                                            stosb

                                            shr     BitMask, 1
                                        ENDLOOP

                                        inc ByteNum
                                    ENDLOOP

                                    inc Ink
                                ENDLOOP

                                inc Paper
                            ENDLOOP

                            inc Bright
                        ENDLOOP

                        inc Flash
                    ENDLOOP

                    ret

PrepULA64ColourTables endp


.const
AskPlus3Mode    db  "+3 disk images are only supported in Spectrum +3 mode.",13,10,13,10
                db  "Would you like to switch to Spectrum +3 mode now?",0
AskPentagonMode db  "TR-DOS disk images are only supported in Pentagon 128K mode.",13,10,13,10
                db  "Would you like to switch to Pentagon 128K mode now?",0

AskStopRecording db "An RZX is currently being recorded.", 13, 10, 13, 10
                db  "Would you like to end this recording?",0

.code
CheckRZXRecording   proc
                    switch  rzx_mode
                            case    RZX_PLAY
                                    invoke  Close_RZX, 0, 0

                            case    RZX_RECORD
                                    .if     $fnc (ShowMessageBox, hWnd, addr AskStopRecording, addr szWindowName, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) == IDNO
                                            return  FALSE
                                    .endif
                                    invoke  Close_RZX, 0, 0
                    endsw
                    return  TRUE
CheckRZXRecording   endp

ReadFileType    proc    lpFilename: DWORD

                local   tempcurdir[MAX_PATH]: BYTE

                ; preserve current currdir
                invoke  GetCurrentDirectory, sizeof tempcurdir, addr tempcurdir

                ; restore initial currdir when SpecEmu started up
                invoke  SetCurrentDirectory, addr startup_currentdirectory

                invoke  ReadFileType_2, lpFilename

                ; restore current currdir on exit
                invoke  SetCurrentDirectory, addr tempcurdir

                ret
ReadFileType    endp

ReadFileType_2  proc    uses        esi edi ebx,
                        lpFilename: DWORD

                local   tempbuffer[8]:BYTE

                local   textstring: TEXTSTRING,
                        pTEXTSTRING:DWORD

                IFDEF   PACMAN
                invoke  Disable_Pacmode
                ENDIF

                ifc     $fnc (CheckRZXRecording) eq FALSE then ret

                .if     $fnc (szLen, lpFilename) < 5
                        ret
                .endif

                .if     $fnc (exist, lpFilename) == 0
                        invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                        ADDDIRECTTEXTSTRING pTEXTSTRING, "Cannot find "
                        ADDCHAR             pTEXTSTRING, 34
                        ADDTEXTSTRING       pTEXTSTRING, lpFilename
                        ADDCHAR             pTEXTSTRING, 34

                        invoke  ShowMessageBox, hWnd, addr textstring, addr szWindowName, MB_OK
                        ret
                .endif

                invoke  szRight, lpFilename, addr tempbuffer, 4
                invoke  lcase,  addr tempbuffer
                mov     eax,    dword ptr [tempbuffer]

                .if     (eax == "ans.") || (eax == "xns.") || (eax == "08z.") || (eax == "xzs.")
                        invoke  LoadSnapshot_1, lpFilename

                .elseif (eax == "pat.") || (eax == "klb.") || (eax == "xzt.") || (eax == "vaw.") || (eax == "wsc.") || (eax == "xzp.")
                        invoke  InsertTape_1, lpFilename

                .elseif (eax == "ksd.")
                        .if     HardwareMode != HW_PLUS3
                                .if     $fnc (ShowMessageBox, hWnd, addr AskPlus3Mode, addr szWindowName, MB_YESNO or MB_ICONQUESTION) == IDYES
                                        invoke  SwitchModel, HW_PLUS3
                                .endif
                        .endif
                        .if     HardwareMode == HW_PLUS3
                                invoke  InsertDisk_1, lpFilename
                        .endif

                .elseif (eax == "drt.") || (eax == "lcs.")
;                        .if     HardwareMode != HW_PENTAGON128
;                                .if     $fnc (ShowMessageBox, hWnd, addr AskPentagonMode, addr szWindowName, MB_YESNO or MB_ICONQUESTION) == IDYES
;                                        invoke  SwitchModel, HW_PENTAGON128
;                                .endif
;                        .endif
                        .if     HardwareMode == HW_PENTAGON128
                                invoke  InsertDisk_1, lpFilename
                        .endif

                        .if     CBI_Enabled == TRUE
                                invoke  InsertDisk_1, lpFilename
                        .endif

                .elseif (eax == "tgm.") || (eax == "gmi.")
                        .if     PLUSD_Enabled == TRUE
                                invoke  InsertDisk_1, lpFilename
                        .endif

                .elseif (eax == "rcs.")
                        invoke  Read_SCR, lpFilename

                .elseif (eax == "mor.")
                        invoke  LoadIF2ROM_1, lpFilename

                .elseif (eax == "xzr.")
                        invoke  Open_RZX_1, lpFilename

                .else
                        mov     ecx, eax
                        and     ecx, 0FFFFFF00h
                        .if     ecx == ("ps." shl 8)
                                invoke  LoadSnapshot_1, lpFilename

                        .else
                              ; any other file type can be loaded as a binary import
                                CLEARSOUNDBUFFERS
                                strncpy lpFilename, addr loadbinaryfilename, sizeof loadbinaryfilename
                                call    LoadBinaryDialog
                        .endif
                .endif

                ret

ReadFileType_2  endp

Read_SCR        proc    lpFilename: DWORD

                local   filehandle: DWORD

                .if     $fnc (filesize, lpFilename) != 6912
                        invoke  ShowMessageBox, hWnd, SADD ("Invalid .SCR file"), addr szWindowName, MB_OK
                        ret
                .endif

                mov     filehandle, $fnc (CreateFile, lpFilename, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
                .if     filehandle != INVALID_HANDLE_VALUE
                        invoke  ReadFile, filehandle, SPGfx.zxDisplayOrg, 6912, addr BytesMoved, NULL
                        invoke  CloseHandle, filehandle
                        RENDERFRAME
                .else
                        invoke  ShowMessageBox, hWnd, SADD ("Error opening .SCR file"), addr szWindowName, MB_OK
                .endif
                ret

Read_SCR        endp

AttachMenu      proc    hWin:   DWORD

                invoke  SetMenu, hWin, MenuHandle
                mov     MenuAttached, TRUE
                mov     MenuTimeout, 0

@@:             invoke  ShowCursor, TRUE
                or      eax, eax
                js      @B
                ret

AttachMenu      endp

DetachMenu      proc

                .if     MenuNoUnattach == FALSE
                        invoke  SetMenu, hWnd, NULL
                        mov     MenuAttached, FALSE
                        mov     MenuIgnoreMouseMoveCnt, 3

                        invoke  SetDirtyLines

                        .if     MouseNoUnattach == FALSE
                            @@: invoke  ShowCursor, FALSE
                                or      eax, eax
                                jns     @B
                        .endif
                .endif
                ret

DetachMenu      endp

.data
align 4
nrandom_seed    dd  0a6049434h

.code
FuzzScreenMemory    proc    uses    edi ebx

                    mov     edi, currentMachine.bank5
                    mov     ebx, 6912
                @@: invoke  nrandom, 255
                    stosb
                    dec     ebx
                    jnz     @B
                    ret
FuzzScreenMemory    endp

ShowMessageBox  proc    hWin:       DWORD,
                        lpText:     DWORD,
                        lpCaption:  DWORD,
                        uType:      DWORD

                CLEARSOUNDBUFFERS

                mov     MessageBoxDisplayed, TRUE
                MouseOn
                invoke  MessageBox, hWin, lpText, lpCaption, uType
                MouseOff
                mov     MessageBoxDisplayed, FALSE
                ret
ShowMessageBox  endp

.const
IDT_MAINWINTOOLBAR  equ         100
mainwin_tbrbtns     TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
                    TBBUTTON    <STD_FILEOPEN,IDM_OPENFILETYPE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <STD_FILESAVE,IDM_SAVESNAPSHOT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>

                    TBBUTTON    <15,IDM_RESET,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>

                    TBBUTTON    <17,IDM_FULLSCREEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <18,IDM_TAPEBROWSER,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <19,IDM_DEBUGGER,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
                    TBBUTTON    <20,IDM_OPTIONS,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

                    TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
                    TBBUTTON    <16,IDM_PAUSE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

MAINWIN_NTBRBTNS    equ         ((THIS BYTE - mainwin_tbrbtns) / sizeof TBBUTTON)

.code
SetTbrColorMap      proc

                    mov     TbrColorMap.COLORMAP.From, 00FF00FFh
                    mov     TbrColorMap.COLORMAP.To,   $fnc (GetSysColor, COLOR_BTNFACE)
                    ret

SetTbrColorMap      endp

AddMainWinToolBar   proc    hOwner: HWND

                    local   tbab:           TBADDBITMAP
                    local   ToolBarRect:    RECT

                    ; create the toolbar
                    invoke  CreateWindowEx, 0, addr szToolBarClass, 0,
                                            WS_CHILD or WS_VISIBLE or WS_BORDER or TBSTYLE_TOOLTIPS,
                                            0, 0, 0, 0, hOwner, IDT_MAINWINTOOLBAR, hInstance, 0
                    mov     mainwin_hToolBar, eax

                    .if     mainwin_hToolBar == NULL
                            FATAL   "Failed to create toolbar"
                    .endif

                    ; set toolbar struct size
                    invoke  SendMessage, mainwin_hToolBar, TB_BUTTONSTRUCTSIZE, sizeof TBBUTTON, 0

                    ; set bitmap size
                    invoke  SendMessage, mainwin_hToolBar, TB_SETBITMAPSIZE, 0, (16 shl 16) + 16

                    ; add toolbar bitmaps
                    push    HINST_COMMCTRL
                    pop     tbab.hInst
                    mov     tbab.nID, IDB_STD_SMALL_COLOR
                    invoke  SendMessage, mainwin_hToolBar, TB_ADDBITMAP, 15, addr tbab

                    invoke  SetTbrColorMap
                    invoke  CreateMappedBitmap, hInstance, IDB_MAINWINTOOLBAR, 0, addr TbrColorMap, 1
                    mov     tbab.nID, eax
                    mov     tbab.hInst, NULL
                    invoke  SendMessage, mainwin_hToolBar, TB_ADDBITMAP, 6, addr tbab

                    ; set toolbar buttons
                    invoke  SendMessage, mainwin_hToolBar, TB_ADDBUTTONS, MAINWIN_NTBRBTNS, addr mainwin_tbrbtns

                    invoke  SendMessage, mainwin_hToolBar, TB_AUTOSIZE, 0, 0
 
                    ; return toolbar height
                    invoke  GetWindowRect, mainwin_hToolBar, addr ToolBarRect
                    mov     eax, ToolBarRect.bottom
                    sub     eax, ToolBarRect.top
                    ret

AddMainWinToolBar   endp

AddMainWinStatus    proc    hOwner: HWND

                    local   statusRect: RECT

                    invoke  CreateStatusWindow, WS_CHILD or WS_VISIBLE or SBARS_SIZEGRIP, NULL, hOwner, IDC_STATUS
                    mov     mainwin_hStatus, eax

                    .if     mainwin_hStatus == NULL
                            FATAL   "Failed to create status bar"
                    .endif

                    invoke  SetStatusPartSizes, mainwin_hStatus, hOwner, addr statusdiffs, numStatusParts

                    IFDEF   DEBUGBUILD
                            invoke  SetStatusPartText, mainwin_hStatus, statuspart_info,    SADD ("(C) Hamish McCat, 2021")
                    else
                            invoke  SetStatusPartText, mainwin_hStatus, statuspart_info,    SADD (" ")
                    endif
                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_machine, SADD ("ZX Spectrum 128K")
                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_speed,   SADD ("100%")

                    ; return status height
                    invoke  GetWindowRect, mainwin_hStatus, addr statusRect
                    mov     eax, statusRect.bottom
                    sub     eax, statusRect.top
                    ret

AddMainWinStatus    endp

SetStatusPartText   proc    hStatus:    HWND,
                            part:       DWORD,
                            lpText:     DWORD

                    invoke  SendMessage, hStatus, SB_SETTEXT, part, lpText
                    ret
SetStatusPartText   endp

SetStatusPartSizes  proc    uses        ebx esi edi,
                            hStatus:    HWND,
                            hOwner:     HWND,
                            lpDiffs:    DWORD,
                            count:      DWORD

                    local   ownerRect:  RECT

                    local   offsets[256]:DWORD

                    .if     (count > 0) && (count <= 255)
                            invoke  GetWindowRect, hOwner, addr ownerRect
                            mov     eax, ownerRect.right
                            sub     eax, ownerRect.left

                            mov     ebx, eax

                            mov     esi, lpDiffs
                            lea     edi, offsets

                            mov     eax, count
                            sub     eax, 1
                            lea     edi, [edi+eax*4]

                            SETLOOP count
                                    mov     ecx, [esi]
                                    add     esi, 4

                                    .if     ecx == -1
                                            mov     dword ptr [edi], ebx
                                            sub     edi, 4
                                    .else
                                            mov     [edi], ebx
                                            add     ebx, ecx        ; table holds -ve offsets from previous status area
                                            sub     edi, 4
                                    .endif
                            ENDLOOP

                            invoke  SendMessage, hStatus, SB_SETPARTS, count, addr offsets
                    .endif
                    ret

SetStatusPartSizes  endp

SetMachineStatusBar proc

                    GETMODELNAME    ecx
                    invoke  SetStatusPartText, mainwin_hStatus, statuspart_machine, ecx
                    ret

SetMachineStatusBar endp

.const
szTempMemoryFail    db  "Failed to allocate temporary memory buffer", 0

.code
ShowTempMemoryFail: invoke  ShowMessageBox, hWnd, addr szTempMemoryFail, addr szWindowName, MB_ICONWARNING
                    ret

                    nop

; -------------------------------------------------
                            IFDEF   DEBUGBUILD
.data?
                            esireported byte ?
.code
esi_error:                  pushad
                            invoke  ShowMessageBox, $fnc (GetActiveWindow), SADD ("*** ESI ne RegisterBase ***"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                            popad
                            ret
                            ENDIF

end start


