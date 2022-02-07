
; defines for CAPS+SYMBOL SHIFT mappings on keyboard
KEY_SHIFTCTRL           equ 0   ; value for [KeyShiftMode] when using Shift and Ctrl keys
KEY_SHIFTSHIFT          equ 1   ; value for [KeyShiftMode] when using both Shift keys

HandleOptionsDialog     PROTO
DisplayDialogProc       PROTO :DWORD, :DWORD, :DWORD, :DWORD
SoundDialogProc         PROTO :DWORD, :DWORD, :DWORD, :DWORD
HardwareDialogProc      PROTO :DWORD, :DWORD, :DWORD, :DWORD
Plus3DialogProc         PROTO :DWORD, :DWORD, :DWORD, :DWORD
AssociationsDialogProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD
InputDevicesDialogProc  PROTO :DWORD, :DWORD, :DWORD, :DWORD
TapeDialogProc          PROTO :DWORD, :DWORD, :DWORD, :DWORD

SoftRomDialogProc       PROTO :DWORD, :DWORD, :DWORD, :DWORD
HardDiskDialogProc      PROTO :DWORD, :DWORD, :DWORD, :DWORD

SetFileAssociations     PROTO
CreateFileAssociation   PROTO :DWORD, :DWORD, :DWORD
CreateNewKey            PROTO :DWORD
SetKeyValue             PROTO :DWORD, :DWORD, :DWORD

SetHardwareStatus       PROTO :DWORD

GetUserConfig           PROTO
SetUserConfig           PROTO

; Start of "Options" PropertySheet handler
.data?
align 4
OptionsPropertySheetHeader  PROPSHEETHEADER <?>
OptionsPropSheetPage        PROPSHEETPAGE   <?>

.code

SetUserConfig       proc    uses esi edi

                    lea     esi, OPTIONVARS
                    lea     edi, UserConfig
                    mov     ecx, SIZEUSERCONFIG
                    rep     movsb
                    ret
SetUserConfig       endp

GetUserConfig       proc    uses esi edi

                    lea     esi, UserConfig
                    lea     edi, OPTIONVARS
                    mov     ecx, SIZEUSERCONFIG
                    rep     movsb
                    ret
GetUserConfig       endp


.data?
;variables set by commandline switches - not to be set/reset by userconfig settings
align 16
SnowCrash_Enabled       BYTE    ?   ; set by "-snowcrash" commandline arg
CBI95_NMI_enabled       BYTE    ?   ; set by "-cbi95nmi" commandline arg; CBI-95 magic button overrides the Multiface NMI
sna_is_128k_enabled     BYTE    ?   ; set by "-sna128" commandline arg; 128K SNA files are loaded in 128K mode rather than Pentagon mode
save_z80_as_v1_enabled  BYTE    ?   ; set by "-z80v1" commandline arg


.data?
;option variables
; ======================================================================

; These UserConfig options are saved/restored by Get/SetUserConfig functions as set by the user.
; Snapshots may override these to support the snapshot state but they will be restored
; back to the user's settings upon Reset, etc.

align 16
OPTIONVARS          LABEL   BYTE
HardwareMode        BYTE    ?
MultifaceEnabled    BYTE    ?
SoftRomEnabled      BYTE    ?
DivIDEEnabled       BYTE    ?
MicroSourceEnabled  BYTE    ?
PLUSD_Enabled       BYTE    ?
CBI_Enabled         BYTE    ?
uSpeech_Enabled     BYTE    ?
SpecDrum_Enabled    BYTE    ?
Covox_Enabled       BYTE    ?
ULAplus_Enabled     BYTE    ?
LateTimings         BYTE    ?       ; effects the display renderer due to slightly different uOp breakdown
ENDUSERCONFIG       LABEL   BYTE
SIZEUSERCONFIG      equ     ENDUSERCONFIG-OPTIONVARS
; ======================================================================

PreloadPlusDImage   BYTE ?
FrameSkipCounter    BYTE ?
DirectDraw_Acceleration BYTE    ?
ShowScanlines       BYTE ?
RoundEdges          BYTE ?
VSync_Enabled       BYTE ?  ; TRUE = Wait for VSync
Dodgy_TV_Enabled    BYTE ?
Extremely_Dodgy_TV_Enabled  BYTE ?
Display_Border_Icons    BYTE    ?

Snow_Enabled        BYTE    ?

ULA_Artifacts_Enabled  BYTE    ?
RoundedCorners_Enabled  BYTE    ?
UseMMX              BYTE ?  ; TRUE = Use MMX opcodes
StartFullscreen     BYTE ?  ; TRUE = start in Fullscreen mode
FlashLoadROMBlocks  BYTE ?  ; TRUE = Flashload all ROM block data
FastTapeLoading     BYTE ?  ; TRUE = fast tape loading enabled
AutoloadTapes       BYTE ?  ; TRUE = autoload tapes
AutoPlayTapes       BYTE ?  ; TRUE = auto start/stop tapes
BoostLoadingNoise   BYTE ?  ; TRUE = boost loading noise volume for direct-to-tape transfers
BoostSavingNoise    BYTE ?  ; TRUE = boost saving noise volume for direct-to-tape transfers
StereoOutputMode    BYTE ?
HighQualityAY       BYTE ?
AY_in_48_mode       BYTE    ?
Plus3FastDiskLoading BYTE ? ; TRUE = fast +3 disk loading
TrdosFastDiskLoading BYTE ? ; TRUE = fast TRDOS disk loading
AddOnFastDiskLoading BYTE ? ; TRUE = fast disk loading for all external disk drive systems
AutoloadPlus3DSK    BYTE ?  ; TRUE = autoload +3 disks
AutoloadTrdosDSK    BYTE ?  ; TRUE = autoload TRDOS disks
CreateRndData       BYTE ?  ; TRUE = generate random sector data for protected disks
KeyShiftMode        BYTE ?  ; 0=Shift/Ctrl, 1=Left Shift/Right Shift
Issue3Keyboard      BYTE ?  ; TRUE = emulate issue 3 keyboard behaviour

Associate_SZX       BYTE ?
Associate_SNA       BYTE ?
Associate_Z80       BYTE ?
Associate_SP        BYTE ?
Associate_SNX       BYTE ?
Associate_TAP       BYTE ?
Associate_TZX       BYTE ?
Associate_CSW       BYTE ?
Associate_PZX       BYTE ?
Associate_DSK       BYTE ?
Associate_TRD       BYTE ?
Associate_SCL       BYTE ?
Associate_RZX       BYTE ?
ConfirmExit         BYTE ?
RZX_Pause_On_Rollback       BYTE    ?
RZX_Display_End_Play_Dlg    BYTE    ?

Pause_On_Lost_Focus BYTE    ?
OPTIONVARSEND       LABEL   BYTE
OPTIONVARSSIZE      equ OPTIONVARSEND-OPTIONVARS    ;sizeof OPTIONVARS area

DSoundRestart       BYTE    ?   ; TRUE if DirectSound buffers need restarting
NewHDFSelected      BYTE    ?   ; TRUE if any new HDF file has been selected

UserConfig          db      SIZEUSERCONFIG  dup (?)


.data
align 4
PropSheetStartPage  dd  0       ; start page for the PropertySheet options dialogs

OverridePokedPage   db  FALSE   ; TRUE allows user to select RAM bank for the Poke memory dialog
PokeCurrentPage     db  0       ; current selection in Poke dialog

AssociationsChanged db  FALSE   ; TRUE if any file associations were changed in options

szHDFFilter         db  "Hard Disk files (*.hdf)", 0, "*.hdf", 0, 0
szAllFilter         db  "All files (*.*)", 0, "*.*", 0, 0

NewHardDisk_txt     db  "You have changed the hard disk attachments to this machine.",13,10
                    db  "A hard reset is required for correct hard disk detection.",13,10,13,10
                    db  "Would you like to reset this machine now?",0

BypassConfirmExit   db  FALSE

.code

ADDPROPSHEETPAGE    MACRO   @@DlgID:REQ, @@DlgProc:REQ
                    mov     [OptionsPropSheetPage.pszTemplate], @@DlgID
                    mov     [OptionsPropSheetPage.pfnDlgProc], offset @@DlgProc
                    mov     [OptionsPropSheetPage.lParam], NULL
                    invoke  CreatePropertySheetPage, addr OptionsPropSheetPage
                    mov     [PropertyPagePtrs+(NUMPROPPAGES*4)], eax
                    &@@DlgProc&_Page = NUMPROPPAGES
                    NUMPROPPAGES = NUMPROPPAGES + 1
                    ENDM

HandleOptionsDialog proc    uses    ebx esi edi

                    local   OldHardwareMode:                BYTE,
                            OldDivIDEEnabled:               BYTE,
                            OldCBIEnabled:                  BYTE,
                            OlduSpeech_Enabled:             BYTE,
                            OldDirectDraw_Acceleration:     BYTE

                    local   TempOptionVars[OPTIONVARSSIZE]: BYTE

                    CLEARSOUNDBUFFERS

                    ; make a copy of each option variable
                    lea     esi, OPTIONVARS
                    lea     edi, TempOptionVars
                    mov     ecx, OPTIONVARSSIZE
                    rep     movsb

                    ; FIXME: can cause machine change when only some other unrelated setting was changed
;                    invoke  GetUserConfig

                    memclr  addr OptionsPropertySheetHeader, sizeof PROPSHEETHEADER
                    memclr  addr OptionsPropSheetPage,       sizeof PROPSHEETPAGE

                    ; these copies are for checking if certain settings were changed if user hits Okay for changes
                    mov     al, HardwareMode
                    mov     OldHardwareMode, al             ; preserve hardware mode setting
                    mov     al, DivIDEEnabled
                    mov     OldDivIDEEnabled, al            ; preserve DivIDE setting
                    mov     al, CBI_Enabled
                    mov     OldCBIEnabled, al               ; preserve CBI setting
                    mov     al, uSpeech_Enabled
                    mov     OlduSpeech_Enabled, al          ; preserve uSpeech setting
                    mov     al, DirectDraw_Acceleration
                    mov     OldDirectDraw_Acceleration, al  ; preserve DirectDraw Acceleration setting

                    mov     DSoundRestart, FALSE
                    mov     NewHDFSelected, FALSE

                    ; setup the common default values for the PROPSHEETPAGE structure
                    mov     [OptionsPropSheetPage.dwSize], sizeof PROPSHEETPAGE
                    m2m     [OptionsPropSheetPage.hInstance], GlobalhInst

                    ; now setup each PROPSHEETPAGE structure
                    NUMPROPPAGES = 0

                    ADDPROPSHEETPAGE    IDD_DISPLAY,            DisplayDialogProc
                    ADDPROPSHEETPAGE    IDD_SOUND,              SoundDialogProc
                    ADDPROPSHEETPAGE    IDD_HARDWARE,           HardwareDialogProc
                    ADDPROPSHEETPAGE    IDD_INPUTDEVICES,       InputDevicesDialogProc
                    ADDPROPSHEETPAGE    IDD_TAPE,               TapeDialogProc
                    ADDPROPSHEETPAGE    IDD_PLUS3OPTIONS,       Plus3DialogProc
                    ADDPROPSHEETPAGE    IDD_HARDDISKOPTIONS,    HardDiskDialogProc
                    ADDPROPSHEETPAGE    IDD_ASSOCIATIONS,       AssociationsDialogProc

                    ; now setup the PROPSHEETHEADER structure
                    mov     [OptionsPropertySheetHeader.dwSize], sizeof PROPSHEETHEADER
                    mov     [OptionsPropertySheetHeader.dwFlags], PSH_NOAPPLYNOW
                    mov     eax, hWnd
                    mov     [OptionsPropertySheetHeader.hwndParent], eax
                    mov     eax, GlobalhInst
                    mov     [OptionsPropertySheetHeader.hInstance], eax

                    mov     [OptionsPropertySheetHeader.pszCaption], CTXT ("SpecEmu Options")
                    mov     [OptionsPropertySheetHeader.nPages], NUMPROPPAGES ; number of property sheet pages
                    mov     eax, PropSheetStartPage
                    mov     [OptionsPropertySheetHeader.nStartPage], eax
                    mov     [OptionsPropertySheetHeader.phpage], offset PropertyPagePtrs
                    mov     [OptionsPropertySheetHeader.pfnCallback], NULL

                    mov     [AssociationsChanged], FALSE

                    invoke  PropertySheet, addr OptionsPropertySheetHeader
                    .if     eax == TRUE
                            ; OK selected
                            invoke  SetUserConfig   ; store user's new machine config before resetting

                            .if     AssociationsChanged == TRUE
                                    invoke  SetFileAssociations
                            .endif
                            mov     al, OldHardwareMode
                            .if     al != HardwareMode
                                    mov     HardReset, TRUE
                                    call    ResetSpectrum  ; reset Spectrum if new model selected
                            .endif
                            mov     al, OldDivIDEEnabled
                            .if     al != DivIDEEnabled
                                    mov     HardReset, TRUE
                                    call    ResetSpectrum  ; reset Spectrum if toggling DivIDE emulation
                            .endif
                            mov     al, OldCBIEnabled
                            .if     al != CBI_Enabled
                                    mov     HardReset, TRUE
                                    call    ResetSpectrum  ; reset Spectrum if toggling CBI disk emulation
                            .endif
                            mov     al, OlduSpeech_Enabled
                            .if     al != uSpeech_Enabled
                                    mov     HardReset, TRUE
                                    call    ResetSpectrum  ; reset Spectrum if toggling uSpeech emulation
                            .endif
                            mov     al, OldDirectDraw_Acceleration
                            .if     al != DirectDraw_Acceleration
                                    mov     SwitchingModes, TRUE

                                    invoke  FreeSurfaces
                                    invoke  ShutdownDirectDraw
                                    invoke  InitDirectDraw
                                    invoke  InitSurfaces, hWnd

                                    mov     SwitchingModes, FALSE
                            .endif

                            .if     NewHDFSelected == TRUE
                                    invoke  ShowMessageBox, hWnd, addr NewHardDisk_txt, SADD ("Change in Hard Disk Configuration"), MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON1
                                    .if     eax == IDYES
                                            mov     HardReset, TRUE
                                            call    ResetSpectrum  ; reset Spectrum to detect the new hard disk file(s)
                                    .endif
                            .endif

                            invoke  EnableMultifaceOrSoftRom

                            IFDEF   WANTSOUND
                                    .if     DSoundRestart == TRUE
                                            ; ; re-initialise audio if sound options changed or video update rate changed
                                            call    ReinitAudio
                                    .endif
                            ENDIF
                    .else
                            ; CANCEL selected - restore all original options
                            lea     esi, TempOptionVars
                            lea     edi, OPTIONVARS
                            mov     ecx, OPTIONVARSSIZE
                            rep     movsb
                    .endif
                   ret

HandleOptionsDialog endp

.data?
align 4
PropertyPagePtrs        dd  NUMPROPPAGES dup(?)

.code

;########################################################################

DisplayDialogProc   proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                .if     uMsg == WM_INITDIALOG
                        mov     PropSheetStartPage, DisplayDialogProc_Page

                        invoke  CheckDlgButton, hWndDlg, IDC_USE_DIRECTDRAW_ACCELERATION, ZeroExt (DirectDraw_Acceleration)
                        invoke  CheckDlgButton, hWndDlg, IDC_SHOWSCANLINES,               ZeroExt (ShowScanlines)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLESNOWEFFECT,            ZeroExt (Snow_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLE_ULA_ARTIFACTS,        ZeroExt (ULA_Artifacts_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLEVSYNC,                 ZeroExt (VSync_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLE_DODGY_TV,             ZeroExt (Dodgy_TV_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLE_EXTREMELY_DODGY_TV,   ZeroExt (Extremely_Dodgy_TV_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_DISPLAY_BORDER_ICONS,        ZeroExt (Display_Border_Icons)
                        invoke  CheckDlgButton, hWndDlg, IDC_ROUNDED_CORNERS,             ZeroExt (RoundedCorners_Enabled)
                        invoke  CheckDlgButton, hWndDlg, IDC_ENABLEULAPLUS,               ZeroExt (ULAplus_Enabled)

                        dsText  VideoUpdateComboItems,  "Display all frames",    0, \
                                                        "Display 1 in 2 frames", 0, \
                                                        "Display 1 in 4 frames", 0, 0

                        invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_VIDEOUPDATERATE), addr VideoUpdateComboItems
                        .if     FrameSkipCounter == 1
                                xor     edx, edx
                        .elseif FrameSkipCounter == 2
                                mov     edx, 1
                        .else
                                mov     edx, 2
                        .endif
                        invoke  SendDlgItemMessage, hWndDlg, IDC_VIDEOUPDATERATE, CB_SETCURSEL, edx, 0
                        return  TRUE

                .elseif uMsg == WM_COMMAND
                        .if     $HighWord (wParam) == BN_CLICKED
                                .if     $LowWord (wParam) == IDC_USE_DIRECTDRAW_ACCELERATION
                                        xor     DirectDraw_Acceleration, TRUE

                                .elseif $LowWord (wParam) == IDC_SHOWSCANLINES
                                        xor     ShowScanlines, TRUE

                                .elseif $LowWord (wParam) == IDC_ENABLESNOWEFFECT
                                        xor     Snow_Enabled, TRUE
                                        invoke  SetSnowEffect

                                .elseif $LowWord (wParam) == IDC_ENABLEULAPLUS
                                        xor     ULAplus_Enabled, TRUE
                                        invoke  SetULAplusState

                                .elseif $LowWord (wParam) == IDC_ENABLE_ULA_ARTIFACTS
                                        xor     ULA_Artifacts_Enabled, TRUE
                                        invoke  SetDirtyLines

                                .elseif $LowWord (wParam) == IDC_ENABLEVSYNC
                                        xor     VSync_Enabled, TRUE

                                .elseif $LowWord (wParam) == IDC_ENABLE_DODGY_TV
                                        xor     Dodgy_TV_Enabled, TRUE
                                        mov     SPGfx.TVNoiseCounter, 0

                                .elseif $LowWord (wParam) == IDC_ENABLE_EXTREMELY_DODGY_TV
                                        xor     Extremely_Dodgy_TV_Enabled, TRUE
                                        mov     SPGfx.TVNoiseCounter, 0

                                .elseif $LowWord (wParam) == IDC_DISPLAY_BORDER_ICONS
                                        xor     Display_Border_Icons, TRUE

                                .elseif $LowWord (wParam) == IDC_ROUNDED_CORNERS
                                        xor     RoundedCorners_Enabled, TRUE
                                .endif

                        .elseif $HighWord (wParam) == CBN_SELCHANGE
                                .if     $LowWord (wParam) == IDC_VIDEOUPDATERATE
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_VIDEOUPDATERATE, CB_GETCURSEL, 0, 0
                                        and     eax, 3

                                        mov     cl, al
                                        mov     al, 1
                                        shl     al, cl      ; = 1, 2, 4

                                        mov     FrameSkipCounter, al

                                        ; DSound buffers need restarting for a new update rate
                                        mov     DSoundRestart, TRUE
                                .endif
                        .endif
                .endif

                return  FALSE

DisplayDialogProc  endp

;########################################################################

SoundDialogProc proc    uses        ebx esi edi,
                        hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                local   hwnduSPEECHFREQTRB

                dsText  AudioModeStrs,  "Mono",                          0, \
                                        "Stereo ABC",                    0, \
                                        "Stereo ACB",                    0, \
                                        "Simulated +3 audio distortion", 0, 0

                .if     uMsg == WM_INITDIALOG
                        mov     PropSheetStartPage, SoundDialogProc_Page

                        mov     ebx, $fnc (GetDlgItem, hWndDlg, IDC_AUDIOMODE)
                        invoke  AddComboStrings, ebx, addr AudioModeStrs
                        invoke  SendMessage, ebx, CB_SETCURSEL, ZeroExt (StereoOutputMode), 0

                        invoke  CheckDlgButton,   hWndDlg, IDC_HIGHQUALITYAY, ZeroExt (HighQualityAY)
                        invoke  CheckDlgButton,   hWndDlg, IDC_AY_IN_48_MODE, ZeroExt (AY_in_48_mode)
                        invoke  CheckDlgButton,   hWndDlg, IDC_COVOX,         ZeroExt (Covox_Enabled)

                        movzx   edx, Sound_Effect
                        add     edx, IDC_SOUND_NONE
                        invoke  CheckRadioButton, hWndDlg, IDC_SOUND_NONE, IDC_SOUND_REVERB, edx

                        mov     hwnduSPEECHFREQTRB, $fnc (GetDlgItem, hWndDlg, IDC_uSPEECHFREQTRB)
                        invoke  SendMessage, hwnduSPEECHFREQTRB, TBM_SETRANGE, TRUE, MAKELPARAM (0, 4)
                        mov     esi, $fnc (uSpeech_GetFrequency)
                        invoke  SendMessage, hwnduSPEECHFREQTRB, TBM_SETPOS, TRUE, esi
                        invoke  SetDlgItemText, hWndDlg, IDC_uSPEECHFREQSTC, [uSpeech_FreqTextPtrs+esi*4]
                        return  TRUE

                .elseif uMsg == WM_COMMAND
                        .if     $HighWord (wParam) == CBN_SELCHANGE
                                .if     $LowWord (wParam) == IDC_AUDIOMODE   ; Stereo mode ctrl
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_AUDIOMODE, CB_GETCURSEL, 0, 0
                                        mov     StereoOutputMode, al
                                        mov     DSoundRestart, TRUE
                                .endif
                        .elseif $HighWord (wParam) == BN_CLICKED
                                .if     $LowWord (wParam) == IDC_HIGHQUALITYAY
                                        xor     HighQualityAY, TRUE

                                .elseif $LowWord (wParam) == IDC_AY_IN_48_MODE
                                        xor     AY_in_48_mode, TRUE
                                        invoke  Set_Emulate_AY

                                .elseif $LowWord (wParam) == IDC_SOUND_NONE
                                        mov     Sound_Effect, EFFECT_NONE
                                .elseif $LowWord (wParam) == IDC_SOUND_ECHO
                                        mov     Sound_Effect, EFFECT_ECHO
                                .elseif $LowWord (wParam) == IDC_SOUND_REVERB
                                        mov     Sound_Effect, EFFECT_REVERB

                                .elseif $LowWord (wParam) == IDC_COVOX
                                        xor     Covox_Enabled, TRUE
                                .endif

                        .endif

                .elseif uMsg == WM_HSCROLL
                        mov     hwnduSPEECHFREQTRB, $fnc (GetDlgItem, hWndDlg, IDC_uSPEECHFREQTRB)
                        switch  lParam
                                case    hwnduSPEECHFREQTRB
                                        invoke  SendMessage, hwnduSPEECHFREQTRB, TBM_GETPOS, 0, 0
                                        mov     esi, eax
                                        invoke  uSpeech_SetFrequency, esi
                                        invoke  SetDlgItemText, hWndDlg, IDC_uSPEECHFREQSTC, [uSpeech_FreqTextPtrs+esi*4]
                        endsw
                .endif
                return  FALSE

SoundDialogProc endp

;########################################################################

.data
PD_PRELOAD_NOTHING      equ     0
PD_PRELOAD_GDOS         equ     1
PD_PRELOAD_BETADOS      equ     2

PreloadPlusDComboItems  db      "No system image", 0
                        db      "G+DOS system", 0
                        db      "Beta DOS system", 0
                        db      0

.code
HardwareDialogProc  proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   ofn:        OPENFILENAME

            .if     uMsg == WM_INITDIALOG
                    mov     PropSheetStartPage, HardwareDialogProc_Page

                    mov     al, HardwareMode
                    push    eax
                    mov     HardwareMode,   HW_FIRSTMACHINE
                    .while  HardwareMode <= HW_LASTMACHINE
                            GETMODELNAME    eax
                            invoke  SendDlgItemMessage, hWndDlg, IDC_HARDWAREMODEL, CB_ADDSTRING, 0, eax
                            inc     HardwareMode
                    .endw
                    pop     eax
                    mov     HardwareMode, al

                    invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_PRELOADPLUSDCB), addr PreloadPlusDComboItems
                    invoke  SendDlgItemMessage, hWndDlg, IDC_PRELOADPLUSDCB, CB_SETCURSEL, ZeroExt (PreloadPlusDImage), 0

                    invoke  SetHardwareStatus, hWndDlg
                    return  TRUE

            .elseif uMsg == WM_COMMAND
                    .if     $HighWord (wParam) == CBN_SELCHANGE
                            .if     $LowWord (wParam) == IDC_HARDWAREMODEL
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_HARDWAREMODEL, CB_GETCURSEL, 0, 0
                                    mov     HardwareMode, al
                                    invoke  SetHardwareStatus, hWndDlg

                            .elseif $LowWord (wParam) == IDC_PRELOADPLUSDCB
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_PRELOADPLUSDCB, CB_GETCURSEL, 0, 0
                                    mov     PreloadPlusDImage, al
                            .endif

                    .elseif $HighWord (wParam) == BN_CLICKED
                            .if     $LowWord (wParam) == IDC_LATETIMINGS
                                    xor     LateTimings, TRUE

                            .elseif $LowWord (wParam) == IDC_ENABLEDIVIDE
                                    xor     DivIDEEnabled, TRUE
                                    .if     DivIDEEnabled == TRUE
                                            mov     SoftRomEnabled, FALSE
                                            mov     PLUSD_Enabled,  FALSE
                                            mov     CBI_Enabled,    FALSE
                                            mov     MicroSourceEnabled, FALSE
                                            mov     uSpeech_Enabled,  FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLEPLUSD
                                    xor     PLUSD_Enabled, TRUE
                                    .if     PLUSD_Enabled == TRUE
                                            mov     DivIDEEnabled,  FALSE
                                            mov     CBI_Enabled,    FALSE
                                            mov     SoftRomEnabled, FALSE
                                            mov     MicroSourceEnabled, FALSE
                                            mov     uSpeech_Enabled,  FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLE_CBI_DISK
                                    xor     CBI_Enabled, TRUE
                                    .if     CBI_Enabled == TRUE
                                            mov     DivIDEEnabled,  FALSE
                                            mov     PLUSD_Enabled,  FALSE
                                            mov     SoftRomEnabled, FALSE
                                            mov     MicroSourceEnabled, FALSE
                                            mov     uSpeech_Enabled,  FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLESOFTROM
                                    xor     SoftRomEnabled, TRUE
                                    .if     SoftRomEnabled == TRUE
                                            mov     DivIDEEnabled,  FALSE
                                            mov     PLUSD_Enabled,  FALSE
                                            mov     CBI_Enabled,    FALSE
                                            mov     MicroSourceEnabled, FALSE
                                            mov     uSpeech_Enabled,  FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLEMICROSOURCE
                                    xor     MicroSourceEnabled, TRUE
                                    .if     MicroSourceEnabled == TRUE
                                            mov     DivIDEEnabled,  FALSE
                                            mov     PLUSD_Enabled,  FALSE
                                            mov     CBI_Enabled,    FALSE
                                            mov     SoftRomEnabled, FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLEMICROSPEECH
                                    xor     uSpeech_Enabled, TRUE
                                    .if     uSpeech_Enabled == TRUE
                                            mov     DivIDEEnabled,  FALSE
                                            mov     PLUSD_Enabled,  FALSE
                                            mov     CBI_Enabled,    FALSE
                                            mov     SoftRomEnabled, FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_ENABLESPECDRUM
                                    xor     SpecDrum_Enabled, TRUE
                                    .if     SpecDrum_Enabled == TRUE
;                                            mov     DivIDEEnabled,  FALSE
;                                            mov     PLUSD_Enabled,  FALSE
;                                            mov     SoftRomEnabled, FALSE
                                            invoke  SetHardwareStatus, hWndDlg
                                    .endif

                            .elseif $LowWord (wParam) == IDC_BROWSEDIVIDEFIRMWARE
                                    invoke  GetFileName, hWndDlg, SADD ("Select DivIDE Firmware"), offset szAllFilter, addr ofn, addr DivIDEFirmwareFilename, addr NullExt
                                    .if     eax != 0
                                            invoke  SendDlgItemMessage, hWndDlg, IDC_DIVIDEFIRMWAREEDIT, WM_SETTEXT, 0, addr DivIDEFirmwareFilename
                                            invoke  DivIDE_LoadFirmware
                                    .endif

                            .endif

                    .endif
            .endif
            return  FALSE

HardwareDialogProc  endp

NO_DIVIDE       macro
                invoke  EnableControl, hWndDlg, IDC_ENABLEDIVIDE, FALSE
                endm

NO_PLUS_D       macro
                invoke  EnableControl, hWndDlg, IDC_ENABLEPLUSD, FALSE
                endm

NO_SOFTROM      macro
                invoke  EnableControl, hWndDlg, IDC_ENABLESOFTROM, FALSE
                endm

NO_USPEECH      macro
                invoke  EnableControl, hWndDlg, IDC_ENABLEMICROSPEECH, FALSE
                endm

NO_MICROSOURCE  macro
                invoke  EnableControl, hWndDlg, IDC_ENABLEMICROSOURCE, FALSE
                endm

NO_SPECDRUM     macro
                invoke  EnableControl, hWndDlg, IDC_ENABLESPECDRUM, FALSE
                endm

NO_CBI          macro
                invoke  EnableControl, hWndDlg, IDC_ENABLE_CBI_DISK, FALSE
                endm

NO_EARLY_LATE   macro
                invoke  EnableControl, hWndDlg, IDC_LATETIMINGS, FALSE
                endm

SetHardwareStatus   proc    uses        ebx,
                            hWndDlg:    DWORD

                    mov     ebx, TRUE
                    invoke  EnableControl, hWndDlg, IDC_ENABLEDIVIDE,       ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLEPLUSD,        ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLESOFTROM,      ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLEMICROSPEECH,  ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLEMICROSOURCE,  ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLESPECDRUM,     ebx
                    invoke  EnableControl, hWndDlg, IDC_ENABLE_CBI_DISK,    ebx
                    invoke  EnableControl, hWndDlg, IDC_LATETIMINGS,        ebx


                    call    Set_Machine_Config  ; in Machines.asm; enables/disables add-on hardware based on model type

                    switch  ZeroExt (HardwareMode)
                            case    HW_16
    
                            case    HW_48
    
                            case    HW_128
                                    NO_USPEECH
                                    NO_MICROSOURCE
                                    NO_SPECDRUM
                                    NO_CBI
    
                            case    HW_PLUS2
                                    NO_USPEECH
                                    NO_MICROSOURCE
                                    NO_SPECDRUM
                                    NO_CBI
    
                            case    HW_PLUS2A, HW_PLUS3
                                    NO_PLUS_D
                                    NO_SOFTROM
                                    NO_USPEECH
                                    NO_MICROSOURCE
                                    NO_SPECDRUM
                                    NO_CBI
                                    NO_EARLY_LATE
    
                            case    HW_PENTAGON128
                                    NO_DIVIDE
                                    NO_PLUS_D
                                    NO_SOFTROM
                                    NO_USPEECH
                                    NO_MICROSOURCE
                                    NO_SPECDRUM
                                    NO_CBI
    
                            case    HW_TC2048
    
                            case    HW_TK90X
    
                    endsw

                    invoke  SendDlgItemMessage, hWndDlg, IDC_HARDWAREMODEL,     CB_SETCURSEL, ZeroExt (HardwareMode), 0
                    invoke  CheckDlgButton,     hWndDlg, IDC_LATETIMINGS,       ZeroExt (LateTimings)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLESOFTROM,     ZeroExt (SoftRomEnabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLEDIVIDE,      ZeroExt (DivIDEEnabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLE_CBI_DISK,   ZeroExt (CBI_Enabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLEPLUSD,       ZeroExt (PLUSD_Enabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLEMICROSOURCE, ZeroExt (MicroSourceEnabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLEMICROSPEECH, ZeroExt (uSpeech_Enabled)
                    invoke  CheckDlgButton,     hWndDlg, IDC_ENABLESPECDRUM,    ZeroExt (SpecDrum_Enabled)

                    invoke  SendDlgItemMessage, hWndDlg, IDC_DIVIDEFIRMWAREEDIT, WM_SETTEXT, 0, addr DivIDEFirmwareFilename

                    ret

SetHardwareStatus   endp

Plus3DialogProc proc    uses        ebx esi edi,
                        hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                switch  uMsg
                        case    WM_INITDIALOG
                                mov     PropSheetStartPage, Plus3DialogProc_Page

                                invoke  CheckDlgButton, hWndDlg, IDC_PLUS3FASTDISK,       ZeroExt (Plus3FastDiskLoading)
                                invoke  CheckDlgButton, hWndDlg, IDC_AUTOLOADPLUS3DSK,    ZeroExt (AutoloadPlus3DSK)
                                invoke  CheckDlgButton, hWndDlg, IDC_CREATERANDOMDATA,    ZeroExt (CreateRndData)
                                invoke  CheckDlgButton, hWndDlg, IDC_AUTOLOADPENTAGONDSK, ZeroExt (AutoloadTrdosDSK)
                                invoke  CheckDlgButton, hWndDlg, IDC_PENTAGONFASTDISK,    ZeroExt (TrdosFastDiskLoading)
                                invoke  CheckDlgButton, hWndDlg, IDC_ADDONFASTDISK,       ZeroExt (AddOnFastDiskLoading)
                                return  TRUE

                        case    WM_COMMAND
                                .if     $HighWord (wParam) == BN_CLICKED
                                        .if     $LowWord (wParam) == IDC_PLUS3FASTDISK
                                                xor     Plus3FastDiskLoading, TRUE

                                        .elseif $LowWord (wParam) == IDC_AUTOLOADPLUS3DSK
                                                xor     AutoloadPlus3DSK, TRUE

                                        .elseif $LowWord (wParam) == IDC_CREATERANDOMDATA
                                                xor     CreateRndData, TRUE
                                                setz    al
                                                neg     al  ; 0 for rnd, 255 for no rnd
                                                invoke  u765_SetRandomMethod, FDCHandle, al

                                        .elseif $LowWord (wParam) == IDC_PENTAGONFASTDISK
                                                xor     TrdosFastDiskLoading, TRUE

                                        .elseif $LowWord (wParam) == IDC_AUTOLOADPENTAGONDSK
                                                xor     AutoloadTrdosDSK, TRUE

                                        .elseif $LowWord (wParam) == IDC_ADDONFASTDISK
                                                xor     AddOnFastDiskLoading, TRUE
                                        .endif

                                .endif
                endsw
                return FALSE

Plus3DialogProc endp

AssociationsDialogProc  proc    uses        ebx esi edi,
                                hWndDlg:    DWORD,
                                uMsg:       DWORD,
                                wParam:     DWORD,
                                lParam:     DWORD

                .if     uMsg == WM_INITDIALOG
                        mov    PropSheetStartPage, AssociationsDialogProc_Page

                        mov     ebx, [hWndDlg]
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_SZX, ZeroExt (Associate_SZX)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_SNA, ZeroExt (Associate_SNA)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_Z80, ZeroExt (Associate_Z80)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_SP,  ZeroExt (Associate_SP)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_SNX, ZeroExt (Associate_SNX)

                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_TAP, ZeroExt (Associate_TAP)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_TZX, ZeroExt (Associate_TZX)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_CSW, ZeroExt (Associate_CSW)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_PZX, ZeroExt (Associate_PZX)

                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_DSK, ZeroExt (Associate_DSK)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_TRD, ZeroExt (Associate_TRD)
                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_SCL, ZeroExt (Associate_SCL)

                        invoke  CheckDlgButton, ebx, IDC_ASSOCIATE_RZX, ZeroExt (Associate_RZX)

                        invoke  CheckDlgButton, ebx, IDC_RZX_PAUSE_ON_ROLLBACK,   ZeroExt (RZX_Pause_On_Rollback)
                        invoke  CheckDlgButton, ebx, IDC_RZX_END_PLAYBACK_DIALOG, ZeroExt (RZX_Display_End_Play_Dlg)

                        invoke  CheckDlgButton, ebx, IDC_PAUSE_ON_LOST_FOCUS,   ZeroExt (Pause_On_Lost_Focus)
                        invoke  CheckDlgButton, ebx, IDC_CONFIRMEXIT,   ZeroExt (ConfirmExit)
                        return  TRUE

                .elseif uMsg == WM_COMMAND
                        .if     $HighWord (wParam) == BN_CLICKED
                                movzx   eax, $LowWord (wParam)
                                switch  eax
                                        Case    IDC_ASSOCIATE_SZX
                                                xor     [Associate_SZX], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_SNA
                                                xor     [Associate_SNA], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_Z80
                                                xor     [Associate_Z80], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_SP
                                                xor     [Associate_SP], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        case    IDC_ASSOCIATE_SNX
                                                xor     [Associate_SNX], TRUE
                                                mov     [AssociationsChanged], TRUE

                                        Case    IDC_ASSOCIATE_TAP
                                                xor     [Associate_TAP], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_TZX
                                                xor     [Associate_TZX], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_CSW
                                                xor     [Associate_CSW], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_PZX
                                                xor     [Associate_PZX], TRUE
                                                mov     [AssociationsChanged], TRUE

                                        Case    IDC_ASSOCIATE_DSK
                                                xor     [Associate_DSK], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_TRD
                                                xor     [Associate_TRD], TRUE
                                                mov     [AssociationsChanged], TRUE
                                        Case    IDC_ASSOCIATE_SCL
                                                xor     [Associate_SCL], TRUE
                                                mov     [AssociationsChanged], TRUE

                                        case    IDC_ASSOCIATE_RZX
                                                xor     [Associate_RZX], TRUE
                                                mov     [AssociationsChanged], TRUE

                                        case    IDC_RZX_PAUSE_ON_ROLLBACK
                                                xor     [RZX_Pause_On_Rollback], TRUE

                                        case    IDC_RZX_END_PLAYBACK_DIALOG
                                                xor     [RZX_Display_End_Play_Dlg], TRUE

                                        case    IDC_PAUSE_ON_LOST_FOCUS
                                                xor     [Pause_On_Lost_Focus], TRUE

                                        case    IDC_CONFIRMEXIT
                                                xor     [ConfirmExit], TRUE
                                Endsw
                        .endif
                .endif

                return FALSE

AssociationsDialogProc  endp

InputDevicesDialogProc  proc uses       ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

            .if     uMsg == WM_INITDIALOG
                    mov     PropSheetStartPage, InputDevicesDialogProc_Page

                    .if     Issue3Keyboard == FALSE
                            mov     edx, IDC_ISSUE2KEYBOARD
                    .else
                            mov     edx, IDC_ISSUE3KEYBOARD
                    .endif
                    invoke  CheckRadioButton, hWndDlg, IDC_ISSUE2KEYBOARD, IDC_ISSUE3KEYBOARD, edx 

                    invoke  SendDlgItemMessage, hWndDlg, IDC_KEYSHIFTMODE,   CB_ADDSTRING, 0, SADD("Use Shift and Ctrl keys")
                    invoke  SendDlgItemMessage, hWndDlg, IDC_KEYSHIFTMODE,   CB_ADDSTRING, 0, SADD("Use Shift keys only")
                    invoke  SendDlgItemMessage, hWndDlg, IDC_KEYSHIFTMODE,   CB_SETCURSEL, ZeroExt (KeyShiftMode), 0
                    invoke  CheckDlgButton,     hWndDlg, IDC_ISSUE3KEYBOARD, ZeroExt (Issue3Keyboard)

                    invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_CONTROLLER1TYPE), addr PreloadJoystickComboItems
                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER1TYPE, CB_SETCURSEL, ZeroExt (Joystick1.JOYSTICKINFO.Joystick_Type), 0

                    invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_CONTROLLER2TYPE), addr PreloadJoystickComboItems
                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER2TYPE, CB_SETCURSEL, ZeroExt (Joystick2.JOYSTICKINFO.Joystick_Type), 0

                    invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_CONTROLLER3TYPE), addr PreloadJoystickComboItems
                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER3TYPE, CB_SETCURSEL, ZeroExt (Joystick3.JOYSTICKINFO.Joystick_Type), 0

                    invoke  AddComboStrings, $fnc (GetDlgItem, hWndDlg, IDC_CONTROLLER4TYPE), addr PreloadJoystickComboItems
                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER4TYPE, CB_SETCURSEL, ZeroExt (Joystick4.JOYSTICKINFO.Joystick_Type), 0

                    return  TRUE

            .elseif uMsg == WM_COMMAND
                    .if     $HighWord (wParam) == CBN_SELCHANGE
                            .if     $LowWord (wParam) == IDC_KEYSHIFTMODE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_KEYSHIFTMODE, CB_GETCURSEL, 0, 0
                                    mov     KeyShiftMode, al
                            .endif

                            .if     $LowWord (wParam) == IDC_CONTROLLER1TYPE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER1TYPE, CB_GETCURSEL, 0, 0
                                    mov     Joystick1.JOYSTICKINFO.Joystick_Type, al
                            .endif

                            .if     $LowWord (wParam) == IDC_CONTROLLER2TYPE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER2TYPE, CB_GETCURSEL, 0, 0
                                    mov     Joystick2.JOYSTICKINFO.Joystick_Type, al
                            .endif

                            .if     $LowWord (wParam) == IDC_CONTROLLER3TYPE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER3TYPE, CB_GETCURSEL, 0, 0
                                    mov     Joystick3.JOYSTICKINFO.Joystick_Type, al
                            .endif

                            .if     $LowWord (wParam) == IDC_CONTROLLER4TYPE
                                    invoke  SendDlgItemMessage, hWndDlg, IDC_CONTROLLER4TYPE, CB_GETCURSEL, 0, 0
                                    mov     Joystick4.JOYSTICKINFO.Joystick_Type, al
                            .endif

                    .elseif $HighWord (wParam) == BN_CLICKED
                            .if     $LowWord (wParam) == IDC_ISSUE2KEYBOARD
                                    mov     Issue3Keyboard, FALSE
                            .elseif $LowWord (wParam) == IDC_ISSUE3KEYBOARD
                                    mov     Issue3Keyboard, TRUE
                            .endif
                    .endif
            .endif
            return  FALSE

InputDevicesDialogProc  endp

TapeDialogProc      proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

            .if     uMsg == WM_INITDIALOG
                    mov     PropSheetStartPage, TapeDialogProc_Page

                    mov     ebx, hWndDlg
                    invoke  CheckDlgButton, ebx, IDC_AUTOTAPESTARTSTOP,  ZeroExt (AutoPlayTapes)
                    invoke  CheckDlgButton, ebx, IDC_FLASHLOADROMBLOCKS, ZeroExt (FlashLoadROMBlocks)
                    invoke  CheckDlgButton, ebx, IDC_EDGEDETECTION,      ZeroExt (FastTapeLoading)
                    invoke  CheckDlgButton, ebx, IDC_AUTOLOADTAPES,      ZeroExt (AutoloadTapes)
                    invoke  CheckDlgButton, ebx, IDC_BOOSTLOADINGNOISE,  ZeroExt (BoostLoadingNoise)
                    invoke  CheckDlgButton, ebx, IDC_BOOSTSAVINGNOISE,   ZeroExt (BoostSavingNoise)

                    .if     SaveTapeType == Type_NONE
                            invoke  EnableControl, hWndDlg, IDC_BOOSTSAVINGNOISE, TRUE
                    .else
                            invoke  EnableControl, hWndDlg, IDC_BOOSTSAVINGNOISE, FALSE
                    .endif

                    return  TRUE

            .elseif uMsg == WM_COMMAND
                    .if     $HighWord (wParam) == BN_CLICKED
                            .if     $LowWord (wParam) == IDC_FLASHLOADROMBLOCKS
                                    xor     FlashLoadROMBlocks, TRUE

                            .elseif $LowWord (wParam) == IDC_EDGEDETECTION
                                    xor     FastTapeLoading, TRUE

                            .elseif $LowWord (wParam) == IDC_AUTOLOADTAPES
                                    xor     AutoloadTapes, TRUE

                            .elseif $LowWord (wParam) == IDC_AUTOTAPESTARTSTOP
                                    xor     AutoPlayTapes, TRUE

                            .elseif $LowWord (wParam) == IDC_BOOSTLOADINGNOISE
                                    xor     BoostLoadingNoise, TRUE
                                    .if     !ZERO?
                                            mov BoostSavingNoise, FALSE
                                            invoke  CheckDlgButton, hWndDlg, IDC_BOOSTSAVINGNOISE,  ZeroExt (BoostSavingNoise)
                                    .endif

                            .elseif $LowWord (wParam) == IDC_BOOSTSAVINGNOISE
                                    xor     BoostSavingNoise, TRUE
                                    .if     !ZERO?
                                            mov BoostLoadingNoise, FALSE
                                            invoke  CheckDlgButton, hWndDlg, IDC_BOOSTLOADINGNOISE,  ZeroExt (BoostLoadingNoise)
                                    .endif
                            .endif
                    .endif
            .endif
            return  FALSE

TapeDialogProc  endp

SetFileAssociations proc    uses    esi edi

                local   Associated: DWORD

                mov     esi, CTXT("SpecEmu")
                mov     edi, CTXT("SpecEmu ZX Spectrum Emulator")

                mov     Associated, FALSE

                .if     Associate_SZX == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".szx")
                        mov     Associated, TRUE
                .endif
                .if     Associate_SNA == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".sna")
                        mov     Associated, TRUE
                .endif
                .if     Associate_Z80 == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".z80")
                        mov     Associated, TRUE
                .endif
                .if     Associate_SP == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".sp")
                        mov     Associated, TRUE
                .endif
                .if     Associate_SNX == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".snx")
                        mov     Associated, TRUE
                .endif

                .if     Associate_TAP == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".tap")
                        mov     Associated, TRUE
                .endif
                .if     Associate_TZX == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".tzx")
                        mov     Associated, TRUE
                .endif
                .if     Associate_CSW == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".csw")
                        mov     Associated, TRUE
                .endif
                .if     Associate_PZX == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".pzx")
                        mov     Associated, TRUE
                .endif

                .if     Associate_DSK == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".dsk")
                        mov     Associated, TRUE
                .endif
                .if     Associate_TRD == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".trd")
                        mov     Associated, TRUE
                .endif
                .if     Associate_SCL == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".scl")
                        mov     Associated, TRUE
                .endif

                .if     Associate_RZX == TRUE
                        invoke  CreateFileAssociation,  esi, edi, SADD(".rzx")
                        mov     Associated, TRUE
                .endif

                .if     Associated == TRUE
                        invoke  SHChangeNotify, SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NULL, NULL
                .endif
                ret

SetFileAssociations endp

CreateFileAssociation   proc    AppName:    DWORD,
                                AppDesc:    DWORD,
                                ExtName:    DWORD

                LOCAL   PostFilenamePtr:  DWORD

                STRING  SpecEmuFile_txt,     "SpecEmu.File"
                STRING  SpecEmuFileOpen_txt, "SpecEmu.File\shell\open\command"

                invoke  GetModuleFileName, 0, ADDR temppathstring+1, 128  ; return length in eax
                .if     eax == NULL
                        ret         ; exit now if error
                .endif
                lea     eax, [temppathstring+1+eax]
                mov     PostFilenamePtr, eax        ; ptr beyond module filename

                invoke  CreateNewKey, ExtName
                invoke  SetKeyValue,  ExtName, ADDR NULL_String, ADDR SpecEmuFile_txt

                invoke  CreateNewKey, ADDR SpecEmuFile_txt
                invoke  SetKeyValue,  ADDR SpecEmuFile_txt, ADDR NULL_String, AppDesc

                mov     eax, PostFilenamePtr
                mov     byte ptr [eax],   ","
                mov     byte ptr [eax+1], "1"
                mov     byte ptr [eax+2], 0
                invoke  SetKeyValue,  ADDR SpecEmuFile_txt, SADD("DefaultIcon"), ADDR temppathstring+1

                mov     byte ptr [temppathstring], 34
                mov     eax, PostFilenamePtr
                mov     byte ptr [eax],   34
                mov     byte ptr [eax+1], " "
                mov     byte ptr [eax+2], 34
                mov     byte ptr [eax+3], "%"
                mov     byte ptr [eax+4], "1"
                mov     byte ptr [eax+5], 34
                mov     byte ptr [eax+6], 0

                invoke  CreateNewKey, ADDR SpecEmuFileOpen_txt
                invoke  SetKeyValue,  ADDR SpecEmuFileOpen_txt, ADDR NULL_String, ADDR temppathstring
                ret

CreateFileAssociation endp

CreateNewKey    proc    KeyName:        DWORD,

                LOCAL   Result:         DWORD,
                        hKey:           DWORD

                invoke  RegCreateKeyEx, HKEY_CLASSES_ROOT, KeyName,
                                        0, ADDR NULL_String,
                                        REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL,
                                        ADDR hKey,
                                        ADDR Result
                invoke  RegCloseKey,    hKey
                ret

CreateNewKey    endp

SetKeyValue     proc    KeyName:        DWORD,
                        KeyValueName:   DWORD,
                        KeyValue:       DWORD

                LOCAL   hKey:           DWORD

                invoke  RegOpenKeyEx,   HKEY_CLASSES_ROOT,
                                        KeyName, 0,
                                        KEY_ALL_ACCESS,
                                        ADDR hKey
                invoke  StrLen,         KeyValue
                inc     eax                         ; include final null byte in length
                invoke  RegSetValueEx,  hKey, KeyValueName, 0, REG_SZ, KeyValue, eax
                invoke  RegCloseKey,    hKey
                ret

SetKeyValue     endp


SoftRomDialogProc  proc     uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

            .if     uMsg == WM_INITDIALOG
                    invoke  CheckRadioButton, hWndDlg, IDC_SETWD, IDC_SETWE, IDC_SETWD
                    invoke  CheckRadioButton, hWndDlg, IDC_NORM,  IDC_SOFT,  IDC_NORM
                    invoke  EnableControl,    hWndDlg, IDC_SOFTROMNMI, FALSE
                    return  FALSE

            .elseif uMsg == WM_COMMAND
                    .if     $HighWord (wParam) == BN_CLICKED
                            .if     $LowWord (wParam) == IDC_SETWD
                                    mov     currentMachine.RAMWRITE0, offset DummyMem
                                    mov     currentMachine.RAMWRITE1, offset DummyMem

                            .elseif $LowWord (wParam) == IDC_SETWE
                                    mov     currentMachine.RAMWRITE0, offset SoftRom_RAM
                                    mov     currentMachine.RAMWRITE1, offset SoftRom_RAM+8192

                            .elseif $LowWord (wParam) == IDC_NORM
                                    mov     SoftRomPaged, FALSE
                                    switch  ZeroExt (HardwareMode)
                                            case    HW_16..HW_48
                                                    mov     currentMachine.RAMREAD0, offset Rom_48
                                                    mov     currentMachine.RAMREAD1, offset Rom_48+8192
                                            case    HW_128..HW_PLUS2
                                                    mov     al, Last7FFDWrite
                                                    call    Page_ROM
                                    endsw

                                    invoke  SetPagingInfo
                                    invoke  EnableControl, hWndDlg, IDC_SOFTROMNMI, FALSE

                            .elseif $LowWord (wParam) == IDC_SOFT
                                    mov     SoftRomPaged, TRUE
                                    mov     currentMachine.RAMREAD0, offset SoftRom_RAM
                                    mov     currentMachine.RAMREAD1, offset SoftRom_RAM+8192

                                    invoke  SetPagingInfo
                                    invoke  EnableControl, hWndDlg, IDC_SOFTROMNMI, TRUE

                            .elseif $LowWord (wParam) == IDC_SOFTROMRESET
                                    mov     zPC, 0

                            .elseif $LowWord (wParam) == IDC_SOFTROMNMI
                                    pushad
                                    call    z80_NMI
                                    popad

                            .elseif $LowWord (wParam) == IDC_COPYROMTOSOFTROM
                                    switch  ZeroExt (HardwareMode)
                                            case    HW_16..HW_48
                                                    lea     eax, Rom_48
                                            case    HW_128
                                                    lea     eax, Rom_128+16384
                                            case    HW_PLUS2
                                                    lea     eax, Rom_Plus2+16384
                                    endsw
                                    memcpy  eax, addr SoftRom_RAM, 16384

                            .endif
                    .endif
            .endif
            return  FALSE

SoftRomDialogProc  endp


HardDiskDialogProc proc uses        ebx esi edi,
                        hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                local   ofn:        OPENFILENAME

                switch  uMsg
                        case    WM_INITDIALOG
                                mov     PropSheetStartPage, HardDiskDialogProc_Page

                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT0EDIT, WM_SETTEXT, 0, addr IDEUnit0Filename
                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT1EDIT, WM_SETTEXT, 0, addr IDEUnit1Filename

                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT0, $fnc (Atapi_IsAttached, 0)
                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT1, $fnc (Atapi_IsAttached, 1)
                                return  TRUE

                        case    WM_COMMAND
                                .if     $HighWord (wParam) == BN_CLICKED
                                        .if     $LowWord (wParam) == IDC_BROWSEUNIT0
                                                invoke  GetFileName, hWndDlg, SADD ("Select Hard Disk File for Unit 0"), addr szHDFFilter, addr ofn, addr IDEUnit0Filename, addr HDFExt
                                                .if     eax != 0
                                                        IDE_SelectHDF   IDEHandle, 0, offset IDEUnit0Filename
                                                        .if     $fnc (Atapi_IsAttached, 0) == TRUE
                                                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT0EDIT, WM_SETTEXT, 0, addr IDEUnit0Filename
                                                                mov     NewHDFSelected, TRUE
                                                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT0, TRUE
                                                        .else
                                                                invoke  ShowMessageBox, hWnd, SADD("Failed to attach a hard disk to Unit 0"),
                                                                                        ADDR szWindowName, MB_OK or MB_ICONINFORMATION
                                                        .endif
                                                .endif

                                        .elseif $LowWord (wParam) == IDC_BROWSEUNIT1
                                                strcpy  addr IDEUnit1Filename, addr szFileName
                                                mov     ofn.lpstrDefExt, offset HDFExt
                                                invoke  GetFileName, hWndDlg, SADD ("Select Hard Disk File for Unit 1"), addr szHDFFilter, addr ofn, addr IDEUnit1Filename, addr HDFExt
                                                .if     eax != 0
                                                        IDE_SelectHDF   IDEHandle, 1, offset IDEUnit1Filename
                                                        .if     $fnc (Atapi_IsAttached, 1) == TRUE
                                                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT1EDIT, WM_SETTEXT, 0, addr IDEUnit1Filename
                                                                mov     NewHDFSelected, TRUE
                                                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT1, TRUE
                                                        .else
                                                                invoke  ShowMessageBox, hWnd, SADD("Failed to attach a hard disk to Unit 1"),
                                                                                        ADDR szWindowName, MB_OK or MB_ICONINFORMATION
                                                        .endif
                                                .endif

                                        .elseif $LowWord (wParam) == IDC_REMOVEUNIT0
                                                invoke  Atapi_RemoveUnit, 0
                                                mov     byte ptr IDEUnit0Filename[0], 0
                                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT0EDIT, WM_SETTEXT, 0, addr IDEUnit0Filename
                                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT0, FALSE
                                                mov     NewHDFSelected, TRUE

                                        .elseif $LowWord (wParam) == IDC_REMOVEUNIT1
                                                invoke  Atapi_RemoveUnit, 1
                                                mov     byte ptr IDEUnit1Filename[0], 0
                                                invoke  SendDlgItemMessage, hWndDlg, IDC_UNIT1EDIT, WM_SETTEXT, 0, addr IDEUnit1Filename
                                                invoke  EnableControl, hWndDlg, IDC_REMOVEUNIT1, FALSE
                                                mov     NewHDFSelected, TRUE
                                        .endif
                                .endif
                endsw
                return FALSE

HardDiskDialogProc endp

EnableMultifaceOrSoftRom    proc

            .if     HardwareMode > HW_PLUS3
                    mov     DivIDEEnabled, FALSE
            .endif

            .if     DivIDEEnabled
                    mov     SoftRomEnabled, FALSE
            .endif

            .if     SoftRomEnabled
                    .if     HardwareMode <= HW_PLUS2
                            mov     eax, SW_SHOW
                    .else
                            mov     SoftRomEnabled, FALSE
                            mov     eax, SW_HIDE
                    .endif
            .else
                    mov     eax, SW_HIDE
            .endif

            invoke  ShowWindow, SoftRomDlg, eax

            .if     (DivIDEEnabled == FALSE) && (SoftRomEnabled == FALSE)
                    mov     MultifaceEnabled, TRUE
            .else
                    mov     MultifaceEnabled, FALSE
            .endif

            ret

EnableMultifaceOrSoftRom    endp



