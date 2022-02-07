
; SpecEmuWin.ini file handling functions.
; use GetPrivateProfileInt etc.

;ReadQuickLoadPath       PROTO  ; defined in SpecEmu.inc
;WriteQuickLoadPath      PROTO

.data
;INIFilename             db  "SpecEmuWindow.ini",0
;INILegacyFilename       db  "SpecEmuWindow.ini",0

SettingsSection         db  "Settings",0
Key_HWModel             db  "SpectrumModel",0
Key_DDrawAcceleration   db  "DirectDraw Acceleration",0
Key_ShowScanlines       db  "Scanlines",0
Key_SnowEffect          db  "ULA Snow Effect",0
Key_ULAplusEnabled      db  "ULAplus Enabled",0
Key_ULAArtifacts        db  "ULA Colour Ramping",0
Key_RoundedCorners      db  "Rounded Corners",0
Key_VSync               db  "VSync",0
Key_Dodgy_TV            db  "Dodgy TV",0
Key_Extremely_Dodgy_TV  db  "Extremely Dodgy TV",0
Key_Display_Border_Icons db "Display Border Icons",0
Key_VideoUpdate         db  "Video Update",0
Key_UseMMX              db  "MMX",0
Key_StartFullscreen     db  "StartFullscreen",0
Key_StereoMode          db  "StereoMode",0
Key_HQAY                db  "HighQualityAY",0
Key_SoundEffect         db  "SoundEffect",0
Key_AY_In_48_Mode       db  "AY In 48 Mode", 0
Key_Covox               db  "Covox", 0
Key_Plus3FastDiskLoading db	"Plus3FastDiskLoading",0
Key_TrdosFastDiskLoading db "PentagonFastDiskLoading",0
Key_AddOnFastDiskLoading db "AddOnFastDiskLoading",0
Key_AutoloadPlus3DSK    db  "AutoloadPlus3DSK",0
Key_AutoloadTrdosDSK    db  "AutoloadTrdosDSK",0
Key_GenerateRandomData  db  "GenerateRandomData",0
Key_OpenFilePath        db  "OpenFilePath",0
Key_SnapshotPath        db  "SnapshotPath",0
Key_TapePath            db  "TapePath",0
Key_Plus3DiskPath       db  "Plus3DiskPath",0
Key_TrdosDiskPath       db  "TrdosDiskPath",0
Key_PlusDDiskPath       db  "PlusDDiskPath",0
Key_CBIDiskPath         db  "CBIDiskPath",0
Key_LoadBinaryFilePath  db  "LoadBinaryPath",0
Key_SaveBinaryFilePath  db  "SaveBinaryPath",0
Key_IF2ROMFilePath      db  "IF2ROMPath",0
Key_RZXPath             db  "RZXPath",0
Key_Palette				db	"Palette",0
Key_FlashLoadROMBlocks  db  "FlashloadROMBlocks", 0
Key_FastTapeLoading     db  "FastTapeLoading", 0
Key_AutoloadTapes       db  "AutoloadTapes",0
Key_AutoPlayTapes       db  "AutoPlayTapes",0
Key_LateTimings         db  "LateTimings", 0
Key_KeyShiftMode        db  "KeyShiftMode", 0
Key_Issue3Keyboard      db  "Issue3Keyboard", 0

Key_Controller1Type     db  "Controller1Type", 0
Key_Controller2Type     db  "Controller2Type", 0
Key_Controller3Type     db  "Controller3Type", 0
Key_Controller4Type     db  "Controller4Type", 0

Key_Associate_SZX       db  "Associate_SZX", 0
Key_Associate_SNA       db  "Associate_SNA", 0
Key_Associate_Z80       db  "Associate_Z80", 0
Key_Associate_SP        db  "Associate_SP", 0
Key_Associate_SNX       db  "Associate_SNX", 0

Key_Associate_TAP       db  "Associate_TAP", 0
Key_Associate_TZX       db  "Associate_TZX", 0
Key_Associate_CSW       db  "Associate_CSW", 0
Key_Associate_PZX       db  "Associate_PZX", 0

Key_Associate_DSK       db  "Associate_DSK", 0
Key_Associate_TRD       db  "Associate_TRD", 0
Key_Associate_SCL       db  "Associate_SCL", 0

Key_Associate_RZX       db  "Associate_RZX", 0

Key_RZX_PauseOnRollback db  "PauseOnRollback" ,0
Key_RZX_PauseOnLostFocus    db  "PauseOnLostFocus", 0
Key_RZX_DiaglogOnEndRZXPlayback db  "DlgOnEndRZXPlayback" ,0

Key_ConfirmExit         db  "ConfirmExit",0
Key_IDEUnit0            db  "IDE Unit 0",0
Key_IDEUnit1            db  "IDE Unit 1",0
Key_DivIDEFirmware      db  "DivIDEFirmware",0
Key_DivIDEEnabled       db  "DivIDEEnabled",0
Key_SoftROMEnabled      db  "SoftROMEnabled",0
Key_MicroSourceEnabled  db  "MicroSourceEnabled",0
Key_uSpeechEnabled      db  "uSpeechEnabled",0
Key_SpecDrumEnabled     db  "SpecDrumEnabled",0
Key_PLUSDEnabled        db  "PLUSDEnabled",0
Key_PreloadPlusDImage   db  "Preload +D Image",0
Key_CBIEnabled          db  "CBIEnabled",0
Key_AssemblerFilePath   db  "AssemblerPath",0

Key_MainWin_X           db  "MainWin_X",0
Key_MainWin_Y           db  "MainWin_Y",0
Key_MainWin_W           db  "MainWin_W",0
Key_MainWin_H           db  "MainWin_H",0

INIDefaultPath          db	0

DefaultDivIDEFirmware   db  "FATware-0-12.bin",0

.data?
INIFilename             db  MAX_PATH dup(?)

CSIDL_COMMON_APPDATA = 23h
CSIDL_WINDOWS        = 24h

CSIDL_FLAG_CREATE    = 8000h

.code
SetAppDataPath  proc

                ; create the full path and filename for the appdata INI file
                .if     $fnc (SHGetFolderPath, 0, CSIDL_COMMON_APPDATA, NULL, NULL, addr INIFilename) == 0
                        invoke  PathAppend, addr INIFilename, SADD ("specemu.ini")
                        LOG     "SpecEmu settings location:"
                        LOGLPSTR offset INIFilename
                .else
                        FATAL   "SHGetFolderPath (CSIDL_COMMON_APPDATA) failed"
                .endif

                ; create the full path and filename for the legacy INI file
                t_legacy_ini    equ DummyMem
                .if     $fnc (SHGetFolderPath, 0, CSIDL_WINDOWS, NULL, NULL, addr t_legacy_ini) == 0
                        invoke  PathAppend, addr t_legacy_ini, SADD ("SpecEmuWindow.ini")
                        LOG     "SpecEmu legacy settings location:"
                        LOGLPSTR offset t_legacy_ini
                .else
                        FATAL   "SHGetFolderPath (CSIDL_WINDOWS) failed"
                .endif

                ; if we have no appdata INI file, attempt to import the legacy INI file settings
                .if     $fnc (exist, addr INIFilename) == 0
                        invoke  CopyFile, addr t_legacy_ini, addr INIFilename, TRUE
                        .if     eax != 0
                                LOG     "Imported SpecEmu legacy settings"
                        .endif
                .endif
                ret
SetAppDataPath  endp

ReadProfileInt  proc    lpKeyName  :DWORD,
                        DefaultVal :DWORD

                invoke  GetPrivateProfileInt, addr SettingsSection, lpKeyName, DefaultVal, addr INIFilename
                ret
ReadProfileInt  endp

WriteProfileInt proc    lpKeyName   :DWORD,
                        Value       :DWORD

                local   Buffer[16]  :BYTE

                invoke  dw2a, Value, addr Buffer
                invoke  WritePrivateProfileString, addr SettingsSection, lpKeyName, addr Buffer, addr INIFilename

                .if     eax == 0
                        LOG     "WriteProfileInt() failed"
                        invoke  GetLastError
                        LOGHEX  "Error = ", eax
                .endif
                ret
WriteProfileInt endp

;--------------------------------------------------------------------------------

ReadProfile:
            ; these are modified in WM_CREATE
            ; WindowRect.left = X origin, WindowRect.top = Y origin
            ; WindowRect.right = width, WindowRect.bottom = height
            mov     WindowRect.left,   $fnc (ReadProfileInt, addr Key_MainWin_X, 100)   ; X
            mov     WindowRect.top,    $fnc (ReadProfileInt, addr Key_MainWin_Y, 100)   ; Y
            mov     WindowRect.right,  $fnc (ReadProfileInt, addr Key_MainWin_W, 352)   ; W
            mov     WindowRect.bottom, $fnc (ReadProfileInt, addr Key_MainWin_H, 296)   ; H

            ifc     WindowRect.right  lt 352 then mov WindowRect.right,  352            ; min width
            ifc     WindowRect.bottom lt 296 then mov WindowRect.bottom, 296            ; min height

            ; validate the window rect is in the desktop working area
            invoke  SystemParametersInfo, SPI_GETWORKAREA, NULL, addr DummyMem, NULL
            mov     eax, WindowRect.left
            ifc     eax  ge DummyMem.RECT.right  then mov WindowRect.left, 100
            mov     eax, WindowRect.top
            ifc     eax  ge DummyMem.RECT.bottom then mov WindowRect.top,  100


            invoke  ReadProfileInt, addr Key_Associate_SZX, 0
            and     al, 1
            mov 	[Associate_SZX], al
            invoke  ReadProfileInt, addr Key_Associate_SNA, 0
            and     al, 1
            mov 	[Associate_SNA], al
            invoke  ReadProfileInt, addr Key_Associate_Z80, 0
            and     al, 1
            mov 	[Associate_Z80], al
            invoke  ReadProfileInt, addr Key_Associate_SP, 0
            and     al, 1
            mov 	[Associate_SP], al
            invoke  ReadProfileInt, addr Key_Associate_SNX, 0
            and     al, 1
            mov 	[Associate_SNX], al

            invoke  ReadProfileInt, addr Key_Associate_TAP, 0
            and     al, 1
            mov 	[Associate_TAP], al
            invoke  ReadProfileInt, addr Key_Associate_TZX, 0
            and     al, 1
            mov 	[Associate_TZX], al
            invoke  ReadProfileInt, addr Key_Associate_CSW, 0
            and     al, 1
            mov 	[Associate_CSW], al
            invoke  ReadProfileInt, addr Key_Associate_PZX, 0
            and     al, 1
            mov 	[Associate_PZX], al

            invoke  ReadProfileInt, addr Key_Associate_DSK, 0
            and     al, 1
            mov 	[Associate_DSK], al
            invoke  ReadProfileInt, addr Key_Associate_TRD, 0
            and     al, 1
            mov 	[Associate_TRD], al
            invoke  ReadProfileInt, addr Key_Associate_SCL, 0
            and     al, 1
            mov 	[Associate_SCL], al

            invoke  ReadProfileInt, addr Key_Associate_RZX, 0
            and     al, 1
            mov 	[Associate_RZX], al

            invoke  ReadProfileInt, addr Key_RZX_PauseOnRollback, 1
            and     al, 1
            mov 	[RZX_Pause_On_Rollback], al

            invoke  ReadProfileInt, addr Key_RZX_DiaglogOnEndRZXPlayback, 1
            and     al, 1
            mov 	[RZX_Display_End_Play_Dlg], al

            invoke  ReadProfileInt, addr Key_RZX_PauseOnLostFocus, 0
            and     al, 1
            mov 	[Pause_On_Lost_Focus], al

            invoke  ReadProfileInt, addr Key_ConfirmExit, 1
            and     al, 1
            mov 	[ConfirmExit], al

            invoke  ReadProfileInt, addr Key_KeyShiftMode, 0
            and     al, 1
            mov 	[KeyShiftMode], al

            invoke  ReadProfileInt, addr Key_Issue3Keyboard, 1
            and     al, 1
            mov 	[Issue3Keyboard], al


; joystick inf
            invoke  ReadProfileInt, addr Key_Controller1Type, JOY_NOTHING
            and     eax, 255
            ifc     al ge JOY_END then mov al, JOY_NOTHING
            mov 	[Joystick1.JOYSTICKINFO.Joystick_Type], al

            invoke  ReadProfileInt, addr Key_Controller2Type, JOY_NOTHING
            and     eax, 255
            ifc     al ge JOY_END then mov al, JOY_NOTHING
            mov 	[Joystick2.JOYSTICKINFO.Joystick_Type], al

            invoke  ReadProfileInt, addr Key_Controller3Type, JOY_NOTHING
            and     eax, 255
            ifc     al ge JOY_END then mov al, JOY_NOTHING
            mov 	[Joystick3.JOYSTICKINFO.Joystick_Type], al

            invoke  ReadProfileInt, addr Key_Controller4Type, JOY_NOTHING
            and     eax, 255
            ifc     al ge JOY_END then mov al, JOY_NOTHING
            mov 	[Joystick4.JOYSTICKINFO.Joystick_Type], al

; /joystick inf

            invoke  ReadProfileInt, addr Key_LateTimings, 0
            and     al, 1
            mov     [LateTimings], al

            invoke  ReadProfileInt, addr Key_FlashLoadROMBlocks, 1
            and     al, 1
            mov     [FlashLoadROMBlocks], al

            invoke  ReadProfileInt, addr Key_FastTapeLoading, 1
            mov     [FastTapeLoading], al
            invoke  ReadProfileInt, addr Key_AutoloadTapes, 0
            mov     [AutoloadTapes], al
            invoke  ReadProfileInt, addr Key_AutoPlayTapes, 1
            mov     [AutoPlayTapes], al

            invoke  ReadProfileInt, addr Key_HWModel, HW_48
            mov 	[HardwareMode], al

            invoke  ReadProfileInt, addr Key_Palette, 0
            mov     [UserPalette], eax

            invoke  ReadProfileInt, addr Key_DDrawAcceleration, 1
            and     al, 1
            mov 	[DirectDraw_Acceleration], al

            invoke  ReadProfileInt, addr Key_ShowScanlines, 0
            mov 	[ShowScanlines], al

            invoke  ReadProfileInt, addr Key_SnowEffect, 0
            mov 	[Snow_Enabled], al

            invoke  ReadProfileInt, addr Key_ULAArtifacts, 0
            mov 	[ULA_Artifacts_Enabled], al

            invoke  ReadProfileInt, addr Key_RoundedCorners, 0
            mov 	[RoundedCorners_Enabled], al

            invoke  ReadProfileInt, addr Key_ULAplusEnabled, 0
            mov 	[ULAplus_Enabled], al

            invoke  ReadProfileInt, addr Key_VSync, 0
            mov 	[VSync_Enabled], al

            invoke  ReadProfileInt, addr Key_Dodgy_TV, 0
            mov 	[Dodgy_TV_Enabled], al

            invoke  ReadProfileInt, addr Key_Extremely_Dodgy_TV, 0
            mov 	[Extremely_Dodgy_TV_Enabled], al

            invoke  ReadProfileInt, addr Key_Display_Border_Icons, 0
            mov 	[Display_Border_Icons], al

            invoke  ReadProfileInt, addr Key_UseMMX, 0
            mov 	[UseMMX], al

            invoke  ReadProfileInt, addr Key_VideoUpdate, 1
            switch  al
                    case    1, 2, 4
                    .else
                            mov     al, 4
            endsw
            mov 	[FrameSkipCounter], al

            invoke  ReadProfileInt, addr Key_StartFullscreen, 0
            mov 	[StartFullscreen], al

            invoke  ReadProfileInt, addr Key_StereoMode, 0
            mov		[StereoOutputMode], al

            invoke  ReadProfileInt, addr Key_HQAY, 0
            mov		[HighQualityAY], al

            invoke  ReadProfileInt, addr Key_SoundEffect, 0
            mov		[Sound_Effect], al

            invoke  ReadProfileInt, addr Key_AY_In_48_Mode, 0
            mov		[AY_in_48_mode], al

            invoke  ReadProfileInt, addr Key_Covox, 0
            mov		[Covox_Enabled], al

            invoke  ReadProfileInt, addr Key_Plus3FastDiskLoading, 0
            mov 	[Plus3FastDiskLoading], al
            invoke  ReadProfileInt, addr Key_AutoloadPlus3DSK, 0
            mov 	[AutoloadPlus3DSK], al
            invoke  ReadProfileInt, addr Key_GenerateRandomData, 1
            mov 	[CreateRndData], al

            invoke  ReadProfileInt, addr Key_AutoloadTrdosDSK, 0
            mov 	[AutoloadTrdosDSK], al
            invoke  ReadProfileInt, addr Key_TrdosFastDiskLoading, 0
            mov 	[TrdosFastDiskLoading], al

            invoke  ReadProfileInt, addr Key_AddOnFastDiskLoading, 0
            mov 	[AddOnFastDiskLoading], al

            invoke  ReadProfileInt, addr Key_SoftROMEnabled, 0
            mov 	[SoftRomEnabled], al
            invoke  ReadProfileInt, addr Key_DivIDEEnabled, 0
            mov 	[DivIDEEnabled], al
            invoke  ReadProfileInt, addr Key_PLUSDEnabled, 0
            mov 	[PLUSD_Enabled], al
            invoke  ReadProfileInt, addr Key_PreloadPlusDImage, 0
            mov 	[PreloadPlusDImage], al

            invoke  ReadProfileInt, addr Key_CBIEnabled, 0
            mov 	[CBI_Enabled], al

            invoke  ReadProfileInt, addr Key_MicroSourceEnabled, 0
            mov 	[MicroSourceEnabled], al

            invoke  ReadProfileInt, addr Key_uSpeechEnabled, 0
            mov 	[uSpeech_Enabled], al

            invoke  ReadProfileInt, addr Key_SpecDrumEnabled, 0
            mov 	[SpecDrum_Enabled], al

            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_OpenFilePath,       addr INIDefaultPath, addr openfiletypefilename,     sizeof openfiletypefilename,    addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_SnapshotPath,       addr INIDefaultPath, addr loadsnapfilename,         sizeof loadsnapfilename,        addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_TapePath,           addr INIDefaultPath, addr inserttapefilename,       sizeof inserttapefilename,      addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_Plus3DiskPath,      addr INIDefaultPath, addr insertplus3diskfilename,  sizeof insertplus3diskfilename, addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_TrdosDiskPath,      addr INIDefaultPath, addr inserttrdosdiskfilename,  sizeof inserttrdosdiskfilename, addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_PlusDDiskPath,      addr INIDefaultPath, addr insertplusddiskfilename,  sizeof insertplusddiskfilename, addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_CBIDiskPath,        addr INIDefaultPath, addr insertCBIdiskfilename,    sizeof insertCBIdiskfilename,   addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_LoadBinaryFilePath, addr INIDefaultPath, addr loadbinaryfilename,       sizeof loadbinaryfilename,      addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_SaveBinaryFilePath, addr INIDefaultPath, addr savebinaryfilename,       sizeof savebinaryfilename,      addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_IF2ROMFilePath,     addr INIDefaultPath, addr loadIF2ROMfilename,       sizeof loadIF2ROMfilename,      addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_RZXPath,            addr INIDefaultPath, addr RZXfilename,              sizeof RZXfilename,             addr INIFilename

            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_IDEUnit0,           addr INIDefaultPath, addr IDEUnit0Filename,         sizeof IDEUnit0Filename,        addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_IDEUnit1,           addr INIDefaultPath, addr IDEUnit1Filename,         sizeof IDEUnit1Filename,        addr INIFilename
            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_DivIDEFirmware,     addr INIDefaultPath, addr DivIDEFirmwareFilename,   sizeof DivIDEFirmwareFilename,  addr INIFilename

            invoke  GetPrivateProfileString, addr SettingsSection, addr Key_AssemblerFilePath,  addr INIDefaultPath, addr szAsmFileName,            sizeof szAsmFileName,           addr INIFilename

            ; provide default FATware firmware for DivIDE if none specified
            .if     byte ptr [DivIDEFirmwareFilename] == 0
                    invoke  GetAppPath, addr DivIDEFirmwareFilename
                    APPENDTEXTSTRING    offset DivIDEFirmwareFilename, offset DefaultDivIDEFirmware ; = "FATware-0-12.bin"
            .endif
            ret

;--------------------------------------------------------------------------------

WriteProfile:
            invoke  GetUserConfig   ; bring back user's config before saving settings

            invoke  GetWindowRect, hWnd, addr DummyMem
            invoke  GetClientRect, hWnd, addr WindowRect
            invoke  WriteProfileInt, addr Key_MainWin_X, DummyMem.RECT.left
            invoke  WriteProfileInt, addr Key_MainWin_Y, DummyMem.RECT.top
          % invoke  WriteProfileInt, addr Key_MainWin_W, @Eval (WindowRect.right-WindowRect.left)
          % invoke  WriteProfileInt, addr Key_MainWin_H, @Eval (WindowRect.bottom-WindowRect.top-ToolBarHeight-StatusHeight)

            invoke  WriteProfileInt, addr Key_Associate_SZX,        ZeroExt (Associate_SZX)
            invoke  WriteProfileInt, addr Key_Associate_SNA,        ZeroExt (Associate_SNA)
            invoke  WriteProfileInt, addr Key_Associate_Z80,        ZeroExt (Associate_Z80)
            invoke  WriteProfileInt, addr Key_Associate_SP,         ZeroExt (Associate_SP)
            invoke  WriteProfileInt, addr Key_Associate_SNX,        ZeroExt (Associate_SNX)

            invoke  WriteProfileInt, addr Key_Associate_TAP,        ZeroExt (Associate_TAP)
            invoke  WriteProfileInt, addr Key_Associate_TZX,        ZeroExt (Associate_TZX)
            invoke  WriteProfileInt, addr Key_Associate_CSW,        ZeroExt (Associate_CSW)
            invoke  WriteProfileInt, addr Key_Associate_PZX,        ZeroExt (Associate_PZX)

            invoke  WriteProfileInt, addr Key_Associate_DSK,        ZeroExt (Associate_DSK)
            invoke  WriteProfileInt, addr Key_Associate_TRD,        ZeroExt (Associate_TRD)
            invoke  WriteProfileInt, addr Key_Associate_SCL,        ZeroExt (Associate_SCL)

            invoke  WriteProfileInt, addr Key_Associate_RZX,        ZeroExt (Associate_RZX)

            invoke  WriteProfileInt, addr Key_RZX_PauseOnRollback,  ZeroExt (RZX_Pause_On_Rollback)
            invoke  WriteProfileInt, addr Key_RZX_PauseOnLostFocus, ZeroExt (Pause_On_Lost_Focus)
            invoke  WriteProfileInt, addr Key_RZX_DiaglogOnEndRZXPlayback,  ZeroExt (RZX_Display_End_Play_Dlg)

            invoke  WriteProfileInt, addr Key_ConfirmExit,          ZeroExt (ConfirmExit)

            invoke  WriteProfileInt, addr Key_KeyShiftMode,         ZeroExt (KeyShiftMode)
            invoke  WriteProfileInt, addr Key_Issue3Keyboard,       ZeroExt (Issue3Keyboard)

            invoke  WriteProfileInt, addr Key_Controller1Type,      ZeroExt (Joystick1.JOYSTICKINFO.Joystick_Type)
            invoke  WriteProfileInt, addr Key_Controller2Type,      ZeroExt (Joystick2.JOYSTICKINFO.Joystick_Type)
            invoke  WriteProfileInt, addr Key_Controller3Type,      ZeroExt (Joystick3.JOYSTICKINFO.Joystick_Type)
            invoke  WriteProfileInt, addr Key_Controller4Type,      ZeroExt (Joystick4.JOYSTICKINFO.Joystick_Type)

            invoke  WriteProfileInt, addr Key_LateTimings,          ZeroExt (LateTimings)

            invoke  WriteProfileInt, addr Key_FlashLoadROMBlocks,   ZeroExt (FlashLoadROMBlocks)

            invoke  WriteProfileInt, addr Key_FastTapeLoading,      ZeroExt (FastTapeLoading)
            invoke  WriteProfileInt, addr Key_AutoloadTapes,        ZeroExt (AutoloadTapes)
            invoke  WriteProfileInt, addr Key_AutoPlayTapes,        ZeroExt (AutoPlayTapes)

            invoke  WriteProfileInt, addr Key_HWModel,              ZeroExt (HardwareMode)

            invoke  WriteProfileInt, addr Key_Palette,              [UserPalette]

            invoke  WriteProfileInt, addr Key_DDrawAcceleration,    ZeroExt (DirectDraw_Acceleration)
            invoke  WriteProfileInt, addr Key_ShowScanlines,        ZeroExt (ShowScanlines)
            invoke  WriteProfileInt, addr Key_SnowEffect,           ZeroExt (Snow_Enabled)
            invoke  WriteProfileInt, addr Key_ULAArtifacts,         ZeroExt (ULA_Artifacts_Enabled)
            invoke  WriteProfileInt, addr Key_RoundedCorners,       ZeroExt (RoundedCorners_Enabled)

            invoke  WriteProfileInt, addr Key_ULAplusEnabled,       ZeroExt (ULAplus_Enabled)
            invoke  WriteProfileInt, addr Key_VSync,                ZeroExt (VSync_Enabled)
            invoke  WriteProfileInt, addr Key_Dodgy_TV,             ZeroExt (Dodgy_TV_Enabled)
            invoke  WriteProfileInt, addr Key_Extremely_Dodgy_TV,   ZeroExt (Extremely_Dodgy_TV_Enabled)
            invoke  WriteProfileInt, addr Key_Display_Border_Icons, ZeroExt (Display_Border_Icons)
            invoke  WriteProfileInt, addr Key_UseMMX,               ZeroExt (UseMMX)
            invoke  WriteProfileInt, addr Key_StartFullscreen,      ZeroExt (StartFullscreen)
            invoke  WriteProfileInt, addr Key_VideoUpdate,          ZeroExt (FrameSkipCounter)
            invoke  WriteProfileInt, addr Key_StereoMode,           ZeroExt (StereoOutputMode)
            invoke  WriteProfileInt, addr Key_HQAY,                 ZeroExt (HighQualityAY)
            invoke  WriteProfileInt, addr Key_AY_In_48_Mode,        ZeroExt (AY_in_48_mode)
            invoke  WriteProfileInt, addr Key_Covox,                ZeroExt (Covox_Enabled)
            invoke  WriteProfileInt, addr Key_SoundEffect,          ZeroExt (Sound_Effect)

            invoke  WriteProfileInt, addr Key_Plus3FastDiskLoading, ZeroExt (Plus3FastDiskLoading)
            invoke  WriteProfileInt, addr Key_AutoloadPlus3DSK,     ZeroExt (AutoloadPlus3DSK)
            invoke  WriteProfileInt, addr Key_GenerateRandomData,   ZeroExt (CreateRndData)

            invoke  WriteProfileInt, addr Key_TrdosFastDiskLoading, ZeroExt (TrdosFastDiskLoading)
            invoke  WriteProfileInt, addr Key_AutoloadTrdosDSK,     ZeroExt (AutoloadTrdosDSK)

            invoke  WriteProfileInt, addr Key_AddOnFastDiskLoading, ZeroExt (AddOnFastDiskLoading)

            invoke  WriteProfileInt, addr Key_SoftROMEnabled,       ZeroExt (SoftRomEnabled)
            invoke  WriteProfileInt, addr Key_DivIDEEnabled,        ZeroExt (DivIDEEnabled)
            invoke  WriteProfileInt, addr Key_PLUSDEnabled,         ZeroExt (PLUSD_Enabled)
            invoke  WriteProfileInt, addr Key_CBIEnabled,           ZeroExt (CBI_Enabled)
            invoke  WriteProfileInt, addr Key_MicroSourceEnabled,   ZeroExt (MicroSourceEnabled)
            invoke  WriteProfileInt, addr Key_uSpeechEnabled,       ZeroExt (uSpeech_Enabled)
            invoke  WriteProfileInt, addr Key_SpecDrumEnabled,      ZeroExt (SpecDrum_Enabled)

            invoke  WriteProfileInt, addr Key_PreloadPlusDImage,    ZeroExt (PreloadPlusDImage)

            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_OpenFilePath,        addr openfiletypefilename,      addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_SnapshotPath,        addr loadsnapfilename,          addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_TapePath,            addr inserttapefilename,        addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_Plus3DiskPath,       addr insertplus3diskfilename,   addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_TrdosDiskPath,       addr inserttrdosdiskfilename,   addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_PlusDDiskPath,       addr insertplusddiskfilename,   addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_CBIDiskPath,         addr insertCBIdiskfilename,     addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_LoadBinaryFilePath,  addr loadbinaryfilename,        addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_SaveBinaryFilePath,  addr savebinaryfilename,        addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_IF2ROMFilePath,      addr loadIF2ROMfilename,        addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_RZXPath,             addr RZXfilename,               addr INIFilename

            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_IDEUnit0,            addr IDEUnit0Filename,          addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_IDEUnit1,            addr IDEUnit1Filename,          addr INIFilename
            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_DivIDEFirmware,      addr DivIDEFirmwareFilename,    addr INIFilename

            invoke  WritePrivateProfileString,  addr SettingsSection, addr Key_AssemblerFilePath,   addr szAsmFileName,             addr INIFilename
            ret

.data
Key_QuickLoadFilePath   db  "QuickLoadPath", 0

.code
ReadQuickLoadPath   proc
                    invoke  GetPrivateProfileString, addr SettingsSection, addr Key_QuickLoadFilePath, addr INIDefaultPath, addr QuickLoadFilePath, MAX_PATH, addr INIFilename
                    .if     byte ptr [QuickLoadFilePath] == 0
                            invoke  GetCurrentDirectory, MAX_PATH, addr QuickLoadFilePath
                    .endif
                    strncpy addr QuickLoadFilePath, addr INI_QuickLoadFilePath, sizeof INI_QuickLoadFilePath
                    ret
ReadQuickLoadPath   endp

WriteQuickLoadPath  proc
                    invoke  WritePrivateProfileString, addr SettingsSection, addr Key_QuickLoadFilePath, addr INI_QuickLoadFilePath, addr INIFilename
                    ret
WriteQuickLoadPath  endp



