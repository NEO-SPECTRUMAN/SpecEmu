
    ;=====================================
    ; Direct Input Procedures
    ;=====================================
    DI_Init                 PROTO
    DI_ShutDown             PROTO
    DI_Init_Mouse           PROTO
    DI_Init_Keyboard        PROTO
    DI_Read_Mouse           PROTO
    DI_Read_Keyboard        PROTO

    ;========================================
    ; Timer routines
    ;========================================
    Init_Time               PROTO
    Start_Time              PROTO   :DWORD
    Wait_Time               PROTO   :DWORD, :DWORD
    Get_Time                PROTO
    Delay_Time              PROTO   :DWORD

    ;=====================================
    ; Direct Sound Procedures
    ;=====================================
    DS_Init                 PROTO
    DS_ShutDown             PROTO
    Play_Sound              PROTO   :DWORD, :DWORD
    Set_Sound_Volume        PROTO   :DWORD, :DWORD
    Set_Sound_Freq          PROTO   :DWORD, :DWORD
    Set_Sound_Pan           PROTO   :DWORD, :DWORD
    Stop_Sound              PROTO   :DWORD
    Stop_All_Sounds         PROTO
    Delete_Sound            PROTO   :DWORD
    Delete_All_Sounds       PROTO
    Status_Sound            PROTO   :DWORD
    Load_WAV                PROTO   :DWORD, :DWORD
    Init_WAV                PROTO   :DWORD, :DWORD
    Get_Current_Position    PROTO   :DWORD
    Set_Current_Position    PROTO   :DWORD, :DWORD
    Sample_AY               PROTO

    ;=====================================
    ; Misc Procedures
    ;=====================================

    UpdateDisassembly       PROTO
    SetPagingInfo           PROTO

    LoadSZXFile             PROTO   :DWORD
    LoadSZXMemory           PROTO   :DWORD,:DWORD
    EnableControl           PROTO   :DWORD,:DWORD,:DWORD

    LoadMemorySnapshot      PROTO   :HWND
    SaveMemorySnapshot      PROTO   :HWND

    SetDirtyLines           PROTO
    SetDisplayTable         PROTO

    Z80Call_MEMPTR          PROTO   :WORD
    Clear_Mem_Map           PROTO
    Save_Memory_Map         PROTO

    Is_CBI_Paged            PROTO

    Master_Tape             PROTO   :DWORD,:DWORD,:DWORD

    zx7_compress            PROTO   :DWORD, :DWORD, :DWORD

    CreateTapeXORMask       PROTO   :DWORD,:DWORD

    SetAppDataPath          PROTO

    GetZ80TstateCount       PROTO
    SetZ80TstateCount       PROTO   :DWORD

    ;=====================================
    ; Palette Procedures
    ;=====================================

    SetSpectrumPalette      PROTO   :DWORD
    EditCustomPalette       PROTO
    SetCustomPalette        PROTO

    LoadCustomPalettes      PROTO
    SaveCustomPalettes      PROTO

    GetColourAsPercent      PROTO   :BYTE
    GetPercentComponent     PROTO   :DWORD,:WORD

    ;=====================================
    ; ULAplus Procedures
    ;=====================================

    InitULAplus             PROTO
    EnableULAplusMode       PROTO   :BYTE
    SetULAplusState         PROTO
    BuildULAplusPalette     PROTO
    SetULAplusPaletteEntry  PROTO   :DWORD,:BYTE
    SelectULAplusPalette    PROTO   :DWORD

    MapAttr2RGBPercent      PROTO   :BYTE,:DWORD
    Map_hmlhmlml            PROTO   :BYTE

    ULAplus_ReadData        PROTO
    ULAplus_WriteData       PROTO   :BYTE
    ULAplus_WriteReg        PROTO   :BYTE

    ;=====================================
    ; Direct Draw Procedures
    ;=====================================
    InitDirectDraw          PROTO
    ShutdownDirectDraw      PROTO
    InitSurfaces            PROTO   :DWORD
    FreeSurfaces            PROTO
    RestoreSurfaces         PROTO
    FlipDisplayMode         PROTO
    GetDesktopBPP           PROTO
    DumptoDXSurface         PROTO
    DIBToScreen             PROTO   :DWORD
    GetSrcDIBRect           PROTO   :DWORD
    BlitScreen              PROTO   :DWORD
    LockBackBufferSurface   PROTO
    UnlockBackBufferSurface PROTO
    GetSurfaceColours       PROTO
    
    ColourDump              PROTO   :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

    BltFlip_Mirror_Horz     PROTO
    BltFlip_Mirror_Vert     PROTO

    SetDIBDrawPosn          PROTO   :DWORD,:DWORD
    SetDIBPaper             PROTO	:BYTE
    SetDIBInk               PROTO   :BYTE
    DrawDIBText             PROTO   :DWORD
    DrawDIBChar             PROTO   :BYTE


    ;=====================================
    ; Input (Spectrum) Procedures
    ;=====================================
    GetSpeccyInputStates    PROTO
    GetSpeccyKeyState       PROTO
    InitialiseJoystick      PROTO   :DWORD,:PTR
    ResetJoystickStates     PROTO
    GetJoystickStates       PROTO
    GetStickState           PROTO   :DWORD,:PTR
    SetShiftCtrlState       PROTO
    GetPausedKeyState       PROTO


    ;=====================================
    ; Input Procedures
    ;=====================================
    ClearKeyboardState      PROTO
    GetKeyShiftState        PROTO
    Special_Key_Combos      PROTO

    ;=====================================
    ; x86 Code Generator Procedures
    ;=====================================
    AllocPageTable          PROTO   :DWORD
    FreePageTable           PROTO   :DWORD
    FreePageTableList       PROTO
    CompileBreakpointCode   PROTO   :PTR
    x86_Breakpoint          PROTO
    x86_SetOrigin           PROTO   :DWORD
    x86_MemCpy              PROTO   :DWORD,:DWORD
    x86_WriteByte           PROTO   :BYTE
    x86_WriteWord           PROTO   :WORD
    x86_WriteDWord          PROTO   :DWORD

    Set_RunTo_Condition     PROTO	:BYTE
    Set_Autotype_Rom_Point  PROTO

    ;=====================================
    ; Assembler Procedures
    ;=====================================
    Assemble_Source			PROTO	:LPCSTR,:DWORD



