; #########################################################################

;		include files
;		~~~~~~~~~~~~~
        include windows.inc
        include mymacros.inc
        include Resource.inc
        include Strings.inc
        include lists.inc

        include     \masm32\com\include\oaidl.inc
;        include C:\masm32\com\include\colib.inc
        include C:\masm32\com\include\component.inc

        inclib  masm32
        inclib  gdi32
        inclib  user32
        inclib  kernel32
        inclib  comctl32
        inclib  comdlg32
        inclib  shell32
        inclib  shlwapi
        inclib  ole32
        inclib  advapi32
        inclib  winmm
        inclib  ddraw
        inclib  woodylib
        inclib  csw
        inclib  fdc765
        inclib  szx

        inclib  cryptohash

        inclib  speccpp

        include zlib1.inc
        include filestream.inc

        IFDEF   WANTSOUND
                inclib      dsound
        ENDIF

        include z80core.inc
        include RZX.inc
        include DrawIcons.inc
        include Joystick.inc

; #########################################################################

        ;==================
        ; Global prototypes
        ;==================

        ;=================
        ; Local prototypes
        ;=================
        WinMain                     PROTO   :DWORD,:DWORD,:DWORD,:DWORD
        WndProc                     PROTO   :DWORD,:DWORD,:DWORD,:DWORD
        TopXY                       PROTO   :DWORD,:DWORD
        Paint_Proc                  PROTO   :DWORD,:DWORD

        GetFileName                 PROTO   :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
        SaveFileName                PROTO   :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

        ReadProfileInt              PROTO   :DWORD,:DWORD
        WriteProfileInt             PROTO   :DWORD,:DWORD

        AttachMenu                  PROTO   :DWORD
        DetachMenu                  PROTO
        EnableMultifaceOrSoftRom    PROTO

        SetTbrColorMap              PROTO

        PopulateMemoryDlg           PROTO
        Populate_Stack              PROTO
        Populate_Memory             PROTO
        SetMemoryViewAddr           PROTO   :WORD

        SetSnowEffect               PROTO
        Set_Emulate_AY              PROTO
        ParseUserCondition          PROTO   :DWORD
        DisassembleLine             PROTO   :PTR @@textstringptr

        AddRecentFile               PROTO
        ReadQuickLoadPath           PROTO
        WriteQuickLoadPath          PROTO

        Timex_Write_FF              PROTO   :BYTE
        Set_Timex_Border_Colour     PROTO   :BYTE

        SwitchModel                 PROTO   :BYTE

        WipeSpeccyMem               PROTO
        LoadSnapshot                PROTO   :DWORD
        LoadSnapshot_1              PROTO   :DWORD
        AttemptLoadSnapshot         PROTO   :DWORD
        SaveSnapshot                PROTO   :DWORD
        SaveSnapshotByExtension     PROTO   :DWORD
        InsertTape                  PROTO
        InsertTape_1                PROTO   :DWORD
        CloseTapeFile               PROTO
        OpenFileType                PROTO
        InsertDisk                  PROTO
        InsertDisk_1                PROTO   :DWORD
        LoadPlus3Diskfile           PROTO   :DWORD
        LoadTRDOSDiskfile           PROTO   :DWORD
        LoadPLUSDDiskfile           PROTO   :DWORD
        LoadCBIDiskfile             PROTO   :DWORD
        LoadIF2_ROM                 PROTO   :DWORD
        LoadIF2ROM_1                PROTO   :DWORD

        Init_AY                     PROTO
        FixSnapOnHalt               PROTO

        AddZ80MsgItem               PROTO   :DWORD, :DWORD
        AddZ80MsgIgnoredItem        PROTO   :BYTE

        SaveScreenFile              PROTO

        CheckRZXRecording           PROTO

        PopulateBrkListbox          PROTO

        RenderSpeccy                PROTO   :DWORD
        FreeMemory                  PROTO   :DWORD
        ReadFileType                PROTO   :DWORD
        ReadFileType_2              PROTO   :DWORD
        PauseResumeEmulation        PROTO
        Read_SCR                    PROTO   :DWORD
        LoadROMFile                 PROTO   :DWORD,:DWORD,:DWORD
        ShowMessageBox              PROTO   :DWORD,:DWORD,:DWORD,:DWORD
        FuzzScreenMemory            PROTO

        Start_PC_Logging            PROTO   :PTR
        Stop_PC_Logging             PROTO
        Log_PC                      PROTO
        Log_Registers               PROTO
        SetDebuggerLogButtonState   PROTO

        PrtBase8                    PROTO   :DWORD,:BYTE
        PrtBase16                   PROTO   :DWORD,:WORD,:BYTE
        PrtBase32                   PROTO   :DWORD,:DWORD
        OutBase8                    PROTO   :DWORD,:BYTE
        OutBase16                   PROTO   :DWORD,:WORD,:BYTE

        DRAM_Fade                   PROTO

        GetZ80MemoryAddr            PROTO   :WORD
        ReadZ80Byte                 PROTO   :WORD
        ReadZ80Word                 PROTO   :WORD

        WriteZ80Byte                PROTO   :WORD,:BYTE
        WriteZ80Word                PROTO   :WORD,:WORD

        GetBankAddr                 PROTO   :BYTE
        ReadBankByte                PROTO   :BYTE,:WORD
        ReadBankWord                PROTO   :BYTE,:WORD

        WriteBankByte               PROTO   :BYTE,:WORD,:BYTE
        WriteBankWord               PROTO   :BYTE,:WORD,:WORD
        GetBankAtAddr               PROTO   :WORD
        GetBankConfig               PROTO

        Handle_Command_Line         PROTO
        cl_NextArgument             PROTO
        FilenameHas128K             PROTO   :DWORD

        AddTaskQueue                PROTO	:DWORD,:DWORD,:DWORD
        FreeTaskQueue               PROTO
        ExecTaskQueueTask           PROTO
        ExecTaskMemDump             PROTO   :DWORD

        wsprintfA PROTO C :DWORD,:VARARG
        wsprintf equ <wsprintfA>


    .const
    align 4
        numStatusParts          equ     4
        statusdiffs             dd      -80, -140, -80, -1

        statuspart_info         equ     0
        statuspart_rzx          equ     1
        statuspart_machine      equ     2
        statuspart_speed        equ     3

        szWindowName            db      "SpecEmu", 0

        szApplicationName       db      "SpecEmu", 0
        szClassName             db      "SpecEmuClass", 0

        szLOGFilter             db      "LOG files (*.log)",0,"*.log",0, 0

        ; fonts
        Courier_8               LOGFONT <-11,0,0,0,400,0,0,0,0,1,2,1,49,"Courier">
        Courier_New_6           LOGFONT <-8,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">
        Courier_New_9           LOGFONT <-12,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

        char_quote              db      34, 0
        char_space              db      " ", 0
        chars_newline           db      13, 10  ; sizeof chars_newline = 2 by having NULL on following source line
                                db      0
        char_quote_space        db      34, " ", 0

    .data
        DoLogging               db      FALSE
        InitialLogOpcode        db      FALSE

    .data?
    align 4
        PCLogFileStream         DWORD   ?
        PCLog_Filesize          DWORD   ?
        PCLog_Warnsize          DWORD   ?

        CommandLine             DWORD   ?
        hWnd                    DWORD   ?
        hInstance               DWORD   ?
        hIcon                   DWORD   ?

        lastmousemovelParam     DWORD   ?

        ProcessID               DWORD   ?

        SoftRomDlg              DWORD   ?
        Tools1Dlg               DWORD   ?
        MW_MemViewDlg           DWORD   ?
        AssemblerDlg            DWORD   ?

        MessagesDlg             DWORD   ?

        RemoteStepCounter       DWORD   ?

        loadtime_minutes        DWORD   ?   ; total loading time of mastered TAP image
        loadtime_seconds        DWORD   ?
        loadtime_tstates        DWORD   ?

        hScintilla              DWORD   ?
        UserPalette             DWORD   ?   ; current Spectrum palette in use

        ProcessInfo             PROCESS_INFORMATION <>
        StartupInfo             STARTUPINFO         <>

        BytesMoved              DWORD   ?
        BytesSaved              DWORD   ?

        FDCCommandBytes         BYTE    16  dup (?)

        TbrColorMap             BYTE    1 * sizeof COLORMAP dup(?)

        szProcessID             BYTE    9   dup (?) ; gets 8 char hex representation of this app's process ID + null terminator

        snap_bordercol          BYTE    ?   ; temp z80 file border colour because +2A/+3 machine initialisation set border to black


        ; Mapped Memory flags:
        BITDEF	MEMMAP, EXECUTE,        0

        BITDEF	MEMMAP, READ_BYTE,      1
        BITDEF	MEMMAP, READ_WORD,      2
        BITDEF	MEMMAP, WRITE_BYTE,     3
        BITDEF	MEMMAP, WRITE_WORD,     4

        BITDEF	MEMMAP, STACK_READ,     5
        BITDEF	MEMMAP, STACK_WRITE,    6

        ; HardwareMode definitions:-
        ; --------------------------
        RESETENUM   0
        ENUM    HW_16, HW_48
        ENUM    HW_128, HW_PLUS2
        ENUM    HW_PLUS2A, HW_PLUS3
        ENUM    HW_PENTAGON128
        ENUM    HW_TC2048
        ENUM    HW_TK90X

        ENUM    HW_ENDLIST

        HW_FIRSTMACHINE EQU     HW_16
        HW_LASTMACHINE  EQU     HW_ENDLIST - 1


        IFDEF   PACMAN
                Enable_Pacmode              PROTO   :BYTE,:BYTE
                Disable_Pacmode             PROTO
                Free_PacInputMem            PROTO
                LoadPacLevel_Input          PROTO
                ReadPacInputPair            PROTO
                ReadPacInputByte            PROTO
                ReadPacController           PROTO
                StreamPacDataOut            PROTO   :BYTE
                StreamPacDataPair           PROTO
                StreamEndDataOut            PROTO
                Pac_Is_0123                 PROTO
                Set_Pacman_Patches          PROTO
                Is_Pacman_Trapped           PROTO
                Handle_Pac_Patches          PROTO
                Draw_Pacman_Level_Text      PROTO
                DrawPacScore                PROTO   :DWORD
                DrawBCDByte                 PROTO   :BYTE

                FixupLevel255               PROTO
                GetPacmanFilepath           PROTO   :DWORD

                LoadPacmanROMs              PROTO
                PrepPacManEnviron           PROTO

                align   4
                pac_strm_handle             DWORD   ?
                pacinput_base               DWORD   ?
                pacinput_ptr                DWORD   ?
                pacinput_len                DWORD   ?
                paclevel_loaded             DWORD   ?
                pacdrawaddr                 DWORD   ?

                pac_input_pair              WORD    ?   ; low = kempston data, high = count

                pacromcrc_upper             WORD    ?   ; crc16 of upper 8K of Pacman ROM (in bank 0)

                HavePacmanROMs              BYTE    ?
                pacmode                     BYTE    ?

                pacmanfilepath              BYTE    MAX_PATH dup (?)

                ; values for pacmode flag
                RESETENUM   0
                ENUM    PACMODE_NONE
                ENUM    PACMODE_FREEPLAY
                ENUM    PACMODE_RECORD, PACMODE_PLAYBACK
        ENDIF

        ; values for Debug Run To conditions
      ; enumerate Device Port Identifiers
        RESETENUM
        ENUM    DEVICE_NONE
        ENUM    TRDOS_SYSTEM_REGISTER, TRDOS_STATUS_REGISTER, TRDOS_TRACK_REGISTER, TRDOS_SECTOR_REGISTER, TRDOS_DATA_REGISTER, TRDOS_COMMAND_REGISTER
        ENUM    ULA_FE, PAGING_7FFD, PAGING_1FFD

      ; enumerate RUN_TO condition types
        RESETENUM
        ENUM    RUN_TO_PC
        ENUM    RUN_TO_INTERRUPT,           RUN_TO_INTERRUPT_RETRIGGER
        ENUM    RUN_TO_CYCLE
        ENUM    RUN_TO_PORT_READ,           RUN_TO_PORT_WRITE
        ENUM    RUN_TO_DEVICE_PORT_READ,    RUN_TO_DEVICE_PORT_WRITE
        ENUM    RUN_TO_FLOATING_BUS_PORT_READ
        ENUM    RUN_TO_HALTED
        ENUM    RUN_TO_USER_CONDITION
        ENUM    RUN_TO_AUTOLOADTAPE
        ENUM    RUN_TO_TAPE_STARTS,         RUN_TO_TAPE_STOPS
        ENUM    RUN_TO_DISK_MOTOR_ON,       RUN_TO_DISK_MOTOR_OFF
        ENUM    RUN_TO_OPCODE




        ; values for task queue commands
        RESETENUM   0
        ENUM    TASK_WAIT_SECONDS, TASK_WAIT_FRAMES
        ENUM    TASK_EXIT
        ENUM    TASK_DUMP
        ENUM    TASK_DEBUG
        ENUM    TASK_SAVESNAP
        ENUM    TASK_TRACE, TASK_STOP_TRACE
        ENUM    TASK_RUNTO_STOP_CMD

        ; some task queue commands, when run, can initialise and then change the task code to a second execution stage task code
        ENUM   TASK_WAIT_SECONDS_2, TASK_WAIT_FRAMES_2

        ; expected argument type per task queue command
        TASKARG_NONE            equ         0
        TASKARG_NUMERIC         equ         1
        TASKARG_STRING          equ         2



