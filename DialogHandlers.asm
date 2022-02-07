;
;                               DialogBox handlers
;                               ------------------

        include TapeBrowser.asm

TRECENTPOKE         STRUCT
Address             DWORD   ?
Value               DWORD   ?
UsedEntry           BOOL    ?
RamBank             BYTE    ?
TRECENTPOKE         ENDS

.data?
align 4
;LoadBinAddress      DWORD   ?
lpTranslated        BOOL    ?

MAXPOKEENTRIES      equ     10
RecentPokesList     BYTE    (MAXPOKEENTRIES*sizeof TRECENTPOKE) dup(?)

.data
LoadBinAddress      dd      -1
SaveBinAddress      dd      -1
SaveBinLength       dd      -1
.code

;########################################################################

    AboutDialogProc       PROTO :DWORD, :DWORD, :DWORD, :DWORD
    TapeBrowserDlgProc    PROTO :DWORD, :DWORD, :DWORD, :DWORD
    PokeDlgProc           PROTO :DWORD, :DWORD, :DWORD, :DWORD
    LoadBinaryDlgProc     PROTO :DWORD, :DWORD, :DWORD, :DWORD
    SaveBinaryDlgProc     PROTO :DWORD, :DWORD, :DWORD, :DWORD

    PopulateRecentPokesList   PROTO   :DWORD

;########################################################################

HandleTapeBrowserDialog:    invoke  DialogBoxParam, GlobalhInst, IDD_TAPEBROWSER, hWnd, addr TapeBrowserDlgProc, NULL
                            ret
LoadBinaryDialog:           invoke  DialogBoxParam, GlobalhInst, IDD_LOADBINARY,  hWnd, addr LoadBinaryDlgProc,  NULL
                            ret
SaveBinaryDialog:           invoke  DialogBoxParam, GlobalhInst, IDD_SAVEBINARY,  hWnd, addr SaveBinaryDlgProc,  NULL
                            ret
HandleAboutDialog:          invoke  DialogBoxParam, GlobalhInst, IDD_ABOUT,       hWnd, addr AboutDialogProc,    NULL
                            ret

LoadBinaryDlgProc   proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   ofn:        OPENFILENAME

                    local   wParamLow:  WORD,
                            wParamHigh: WORD

                    local   Buffer1[33]:BYTE,
                            tempbyte:   BYTE


                RESETMSG

OnInitDialog
                invoke  SendDlgItemMessage, hWndDlg, IDC_LOADBINFILENAME, WM_SETTEXT, 0, addr loadbinaryfilename

                mov     eax, LoadBinAddress
                ifc     eax eq -1 then mov eax, 32768
                invoke  SetDlgItemInt, hWndDlg, IDC_LOADBINADDRESS, eax, FALSE

                return  TRUE

OnCommand
                mov     eax, [wParam]
                mov     [wParamLow], ax
                shr     eax, 16
                mov     [wParamHigh], ax

                .if     wParamHigh == BN_CLICKED
                        .if     wParamLow == IDCANCEL       ; Cancel button
                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE

                        .elseif wParamLow == IDOK       ; Load button
                                dsText  LoadBinTitle1, "Load Binary File"
                                dsText  LoadBinFilter, "All files", 0, "*.*", 0, 0

                                invoke  SendDlgItemMessage, hWndDlg, IDC_LOADBINFILENAME, WM_GETTEXT, MAX_PATH, addr loadbinaryfilename

                                invoke  GetDlgItemText, hWndDlg, IDC_LOADBINADDRESS, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                ifc     lpTranslated == TRUE then mov LoadBinAddress, eax

                                .if     ((HardwareMode == HW_PLUS2A) || (HardwareMode == HW_PLUS3)) && (lpTranslated == TRUE)
                                        switch  dword ptr [currentMachine.RAMWRITE0]
                                                case    currentMachine.bank0, currentMachine.bank4
                                                        mov     Filename, offset loadbinaryfilename
                                                        call    OpenMyReadFile
                                                        .if     eax == 0
                                                                invoke  ShowMessageBox, hWndDlg, SADD ("Failed to open binary file"), addr LoadBinTitle1, MB_OK
                                                                return  TRUE
                                                        .endif

                                                        lea     eax, tempbyte
                                                        mov     ReadStart, eax
                                                        mov     ReadLen, 1

                                                        mov     esi, LoadBinAddress

                                                        .while  esi <= 65535
                                                                call    ReadMyFile
                                                                .break  .if !ZERO?

                                                                mov     bx, si
                                                                mov     al, tempbyte
                                                                call    MemPokeByte

                                                                inc     esi
                                                        .endw

                                                        call    CloseMyFile
                                                        invoke  EndDialog, hWndDlg, NULL
                                                        return  TRUE
                                        endsw
                                .endif

                                .if     (HardwareMode <= HW_PLUS2) && (SoftRomEnabled == TRUE) && (lpTranslated == TRUE)
                                        .if     LoadBinAddress < 16384
                                                mov     Filename, offset loadbinaryfilename
                                                call    OpenMyReadFile
                                                .if     eax == 0
                                                        invoke  ShowMessageBox, hWndDlg, SADD ("Failed to open binary file"), addr LoadBinTitle1, MB_OK
                                                        return  TRUE
                                                .endif
                                                lea     eax, SoftRom_RAM
                                                add     eax, LoadBinAddress
                                                mov     ReadStart, eax
                                                mov     eax, 16384
                                                sub     eax, LoadBinAddress
                                                mov     ReadLen, eax    ; max softrom length
                                                call    ReadMyFile

                                                call    CloseMyFile
                                                invoke  EndDialog, hWndDlg, NULL
                                                return  TRUE
                                        .endif
                                .endif

                                .if     (lpTranslated == FALSE) || (LoadBinAddress < 16384) || (LoadBinAddress > 65535)
                                        invoke  ShowMessageBox, hWndDlg, SADD ("Memory Address = (16384-65535)"), ADDR LoadBinTitle1, MB_OK
                                        return  TRUE
                                .endif

                                mov     Filename, offset loadbinaryfilename
                                call    OpenMyReadFile
                                .if     eax == 0
                                        invoke  ShowMessageBox, hWndDlg, SADD ("Failed to open binary file"), ADDR LoadBinTitle1, MB_OK
                                        return  TRUE
                                .endif

                                mov     eax, LoadBinAddress
                                sub     eax, 16384
                                add     eax, currentMachine.bank5
                                mov     ReadStart, eax

                                mov     eax, 65536
                                sub     eax, LoadBinAddress
                                mov     ReadLen, eax            ; max bytes we can load at this address

                                call    ReadMyFile
                                call    CloseMyFile

                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE

                        .elseif wParamLow == IDC_LOADBINBROWSEFILE    ; File browser
                                invoke  GetFileName, hWndDlg, SADD ("Open Binary File"), addr LoadBinFilter, addr ofn, addr loadbinaryfilename, NULL
                                .if     eax != FALSE
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_LOADBINFILENAME, WM_SETTEXT, 0, addr loadbinaryfilename
                                .endif
                                return  TRUE
                        .endif
                .endif

OnDefault
                return  FALSE

                DOMSG

LoadBinaryDlgProc   endp

;########################################################################


SaveBinaryDlgProc   proc    uses        ebx esi edi,
                            hWndDlg:    DWORD,
                            uMsg:       DWORD,
                            wParam:     DWORD,
                            lParam:     DWORD

                    local   ofn:        OPENFILENAME

                    local   wParamLow:  WORD,
                            wParamHigh: WORD

                    local   Buffer1[33]:BYTE,
                            Buffer2[33]:BYTE

                RESETMSG

OnInitDialog
                invoke  SendDlgItemMessage, hWndDlg, IDC_SAVEBINFILENAME, WM_SETTEXT, 0, addr savebinaryfilename

                mov     eax, SaveBinAddress
                ifc     eax eq -1 then mov eax, 32768
                invoke  SetDlgItemInt, hWndDlg, IDC_SAVEBINADDRESS, eax, FALSE

                mov     eax, SaveBinLength
                ifc     eax eq -1 then mov eax, 32768
                invoke  SetDlgItemInt, hWndDlg, IDC_SAVEBINLENGTH, eax, FALSE

                return  TRUE

OnCommand
                mov     eax, [wParam]
                mov     [wParamLow], ax
                shr     eax, 16
                mov     [wParamHigh], ax

                .if     wParamHigh == BN_CLICKED
                        .if     wParamLow == IDCANCEL       ; Cancel button
                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE

                        .elseif wParamLow == IDOK           ; Save button
                                dsText  SaveBinTitle1, "Save Binary File"
                                dsText  SaveBinFilter, "All files", 0, "*.*", 0, 0

                                invoke  SendDlgItemMessage, hWndDlg, IDC_SAVEBINFILENAME, WM_GETTEXT, MAX_PATH, addr savebinaryfilename

                                invoke  GetDlgItemText, hWndDlg, IDC_SAVEBINADDRESS, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                ifc     lpTranslated == TRUE then mov SaveBinAddress, eax

                                invoke  GetDlgItemText, hWndDlg, IDC_SAVEBINLENGTH, addr Buffer2, sizeof Buffer2
                                invoke  StringToDWord, addr Buffer2, addr lpTranslated
                                ifc     lpTranslated == TRUE then mov SaveBinLength, eax

                                mov     ecx, SaveBinAddress
                                add     ecx, SaveBinLength
                                .if     (lpTranslated == FALSE) || (SaveBinAddress > 65535) || (SaveBinLength == 0) || (ecx > 65536)
                                        invoke  ShowMessageBox, hWndDlg, SADD("Memory Address Range = (0-65535)"), addr SaveBinTitle1, MB_OK
                                        return  TRUE
                                .endif

                                mov     Filename, offset savebinaryfilename
                                call    OpenMyWriteFile
                                .if     eax == 0
                                        invoke  ShowMessageBox, hWndDlg, SADD("Failed to open binary file for writing"), addr SaveBinTitle1, MB_OK
                                        return  TRUE
                                .endif

                                lea     edi, TempMemBuffer
                                mov     esi, SaveBinLength
                                mov     WriteStart, edi
                                mov     WriteLen,   esi

                                mov     ebx, SaveBinAddress

                        @@:     call    MemGetByte
                                mov     [edi], al
                                inc     edi
                                inc     bx
                                dec     esi
                                jnz     @B

                                call    WriteMyFile
                                call    CloseMyFile

                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE

                        .elseif wParamLow == IDC_SAVEBINBROWSEFILE    ; File browser
                                invoke  SaveFileName, hWndDlg, SADD ("Save Binary File As"), addr SaveBinFilter, addr ofn, addr savebinaryfilename, NULL, 0
                                .if     eax != FALSE
                                        invoke  SendDlgItemMessage, hWndDlg, IDC_SAVEBINFILENAME, WM_SETTEXT, 0, addr savebinaryfilename
                                .endif
                                return  TRUE
                        .endif
                .endif

OnDefault
                return  FALSE

                DOMSG

SaveBinaryDlgProc   endp

AboutDialogProc proc    hWndDlg:    DWORD,
                        uMsg:       DWORD,
                        wParam:     DWORD,
                        lParam:     DWORD

                local   app_path[MAX_PATH]: BYTE

                .if     uMsg == WM_INITDIALOG
                        strcpy  addr SPECEMU_BUILDDATE, addr TempMemBuffer
                        mov     ax, word ptr [TempMemBuffer+6]
                        mov     cx, word ptr [TempMemBuffer+9]
                        mov     word ptr [TempMemBuffer+6], cx
                        mov     word ptr [TempMemBuffer+9], ax
                        invoke  SetDlgItemText, hWndDlg, IDC_ABOUTVERSIONSTR,   addr SPECEMU_FULLVERSIONSTR
                        invoke  SetDlgItemText, hWndDlg, IDC_ABOUTBUILDDATESTR, addr TempMemBuffer
                        return  TRUE

                .elseif uMsg == WM_COMMAND
                        .if     (wParam == IDOK) || (wParam == IDCANCEL)
                                invoke  EndDialog, hWndDlg, NULL
                                return  TRUE

;                        .elseif wParam == $WPARAM (BN_CLICKED, IDC_BUYBEERBTN)
;                                invoke  GetAppPath, addr app_path
;                                invoke  ShellExecute, hWndDlg, SADD ("open"),
;                                                      SADD ("https://www.paypal.me/Woodster"),
;                                                      NULL, addr app_path, SW_SHOWNORMAL

                        .endif

                .elseif uMsg == WM_CLOSE
                        invoke  EndDialog, hWndDlg, NULL
                        return  TRUE

                .endif
                return  FALSE

AboutDialogProc endp


;########################################################################

.data?
PokeAddressInit		DWORD ?
PokeValueInit		DWORD ?
PokeUpdatesDebugger	BYTE ?
.code

HandlePokeDialog:
                ; no default values
                mov     PokeAddressInit, -1
                mov     PokeValueInit, -1
                mov     PokeUpdatesDebugger, FALSE

                invoke  DialogBoxParam, [GlobalhInst], IDD_POKE, [hWnd], ADDR PokeDlgProc, NULL
                ret

PokeDlgProc     proc    uses            ebx esi edi,
                        hWndDlg:        DWORD,
                        uMsg:           DWORD,
                        wParam:         DWORD,
                        lParam:         DWORD

                LOCAL   PokeAddress:    DWORD,
                        PokeValue:      DWORD,
                        wParamLow:      WORD,
                        wParamHigh:     WORD,
                        PokeRamBank:    BYTE

                LOCAL   Buffer1[33]:    BYTE

        .if     uMsg == WM_INITDIALOG
                .if     PokeAddressInit != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_POKEADDRESS, PokeAddressInit, FALSE
                .endif
                .if     PokeValueInit != -1
                        invoke  SetDlgItemInt, hWndDlg, IDC_POKEVALUE, PokeValueInit, FALSE
                .endif

                dsText  @PokeRAM, "RAM 0"
                mov     ebx, "0"
            @@: mov     [@PokeRAM+4], bl
                invoke  SendDlgItemMessage, hWndDlg, IDC_POKERAMPAGE, CB_ADDSTRING, 0, ADDR @PokeRAM
                inc     ebx
                cmp     ebx, "8"
                jc      @B

                invoke  SendDlgItemMessage, hWndDlg, IDC_POKERAMPAGE, CB_SETCURSEL, ZeroExt(PokeCurrentPage), 0

                movzx   ebx, OverridePokedPage
                invoke  CheckDlgButton, hWndDlg, IDC_OVERRIDEBANK, ebx
                invoke  EnableControl, hWndDlg, IDC_POKERAMPAGE, ebx
                invoke  PopulateRecentPokesList, hWndDlg
                return  TRUE

        .elseif uMsg == WM_COMMAND
                mov     eax, [wParam]
                mov     [wParamLow], ax
                shr     eax, 16
                mov     [wParamHigh], ax

                .if     wParam == IDCANCEL
                        invoke  EndDialog, [hWndDlg], NULL
                        return  TRUE
                .endif

                .if     wParamHigh == CBN_SELCHANGE
                        .if     wParamLow == IDC_POKERAMPAGE	; current bank ctrl
                                invoke  SendDlgItemMessage, [hWndDlg], IDC_POKERAMPAGE, CB_GETCURSEL, 0, 0
                                mov     [PokeCurrentPage], al
                                return  TRUE

                        .elseif wParamLow == IDC_RECENTPOKESCOMBO    ; recent pokes ctrl
                                invoke  SendDlgItemMessage, [hWndDlg], IDC_RECENTPOKESCOMBO, CB_GETCURSEL, 0, 0
                                mov     edx, sizeof TRECENTPOKE
                                mul     edx
                                lea     esi, [RecentPokesList+eax]
                                .if     [esi].TRECENTPOKE.UsedEntry == TRUE
                                        invoke  SetDlgItemInt, [hWndDlg], IDC_POKEADDRESS, [esi].TRECENTPOKE.Address, FALSE
                                        invoke  SetDlgItemInt, [hWndDlg], IDC_POKEVALUE, [esi].TRECENTPOKE.Value, FALSE
                                        .if     [esi].TRECENTPOKE.RamBank == -1
                                                invoke  CheckDlgButton, [hWndDlg], IDC_OVERRIDEBANK, BST_UNCHECKED
                                                invoke  EnableControl, [hWndDlg], IDC_POKERAMPAGE, FALSE
                                        .else
                                                invoke  CheckDlgButton, [hWndDlg], IDC_OVERRIDEBANK, BST_CHECKED
                                                invoke  EnableControl, [hWndDlg], IDC_POKERAMPAGE, TRUE
                                                movzx   eax, [esi].TRECENTPOKE.RamBank
                                                invoke  SendDlgItemMessage, [hWndDlg], IDC_POKERAMPAGE, CB_SETCURSEL, eax, 0
                                        .endif
                                .endif
                                return  TRUE
                        .endif

                .elseif wParamHigh == BN_CLICKED
                        .if     wParamLow == IDC_OVERRIDEBANK ; Override RAM bank
                                invoke  IsDlgButtonChecked, [hWndDlg], IDC_OVERRIDEBANK ; BST_UNCHECKED = 0, BST_CHECKED = 1
                                invoke  EnableControl, [hWndDlg], IDC_POKERAMPAGE, eax
                                return  TRUE

                        .elseif (wParamLow == IDC_POKEINCADDR) || (wParamLow == IDC_POKEDECADDR)    ; inc/dec poke address
                                .if     wParamLow == IDC_POKEINCADDR
                                        mov     bx, 1
                                .else
                                        mov     bx, -1
                                .endif

                                mov     PokeAddress, $fnc (GetDlgItemInt, hWndDlg, IDC_POKEADDRESS, ADDR lpTranslated, FALSE)
                                add     word ptr PokeAddress, bx
                                movzx   ebx, word ptr PokeAddress
                                invoke  SetDlgItemInt, hWndDlg, IDC_POKEADDRESS, ebx, FALSE

                                call    MemGetByte
                                movzx   eax, al
                                invoke  SetDlgItemInt, hWndDlg, IDC_POKEVALUE, eax, FALSE
                                return  TRUE

                        .elseif wParamLow == IDC_POKEMEMORY      ; Poke button
                                invoke  GetDlgItemText, [hWndDlg], IDC_POKEADDRESS, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                mov     [PokeAddress], eax
                                .if     (lpTranslated == FALSE) || (PokeAddress > 65535)
                                        szText  ILPokeTitle1,  "Poke Memory"
                                        szText  ILPokeAddress, "Poke Address = (0-65535)"
                                        invoke  ShowMessageBox, hWndDlg, ADDR ILPokeAddress, ADDR ILPokeTitle1, MB_OK
                                        return  TRUE
                                .endif

                                invoke  GetDlgItemText, [hWndDlg], IDC_POKEVALUE, addr Buffer1, sizeof Buffer1
                                invoke  StringToDWord, addr Buffer1, addr lpTranslated
                                mov     [PokeValue],eax
                                .if     (lpTranslated == FALSE) || (PokeValue > 255)
                                        szText  ILPokeValue, "Poke Value = (0-255)"
                                        invoke  ShowMessageBox, hWndDlg, ADDR ILPokeValue, ADDR ILPokeTitle1, MB_OK
                                        return  TRUE
                                .endif

                                pushad
                                invoke  IsDlgButtonChecked, [hWndDlg], IDC_OVERRIDEBANK
                                .if     (eax == BST_CHECKED) && ([PokeAddress] >= 49152)
                                        ; bx = addr, al = byte,  dl = bank
                                        invoke  SendDlgItemMessage, [hWndDlg], IDC_POKERAMPAGE, CB_GETCURSEL, 0, 0
                                        mov     [PokeRamBank], al
                                        mov     dl, al              ; dl = bank
                                        mov     ebx, [PokeAddress]  ; bx = address
                                        mov     eax, [PokeValue]    ; al = byte
                                        call    PokeBankByte
                                .else
                                        mov     [PokeRamBank], -1   ; = N/A
                                        mov     ebx, [PokeAddress]  ; bx = address
                                        mov     eax, [PokeValue]    ; al = byte
                                        call    MemPokeByte
                                .endif

                                ; scan recent pokes list for a matching poke entry
                                ; skip adding a new poke entry if we find a match
                                lea     esi, RecentPokesList
                                xor     ebx, ebx
                                .while  (ebx < MAXPOKEENTRIES) && ([esi].TRECENTPOKE.UsedEntry == TRUE)
                                        mov     eax, [PokeAddress]
                                        cmp     [esi].TRECENTPOKE.Address, eax
                                        jne     @F
                                        mov     eax, [PokeValue]
                                        cmp     [esi].TRECENTPOKE.Value, eax
                                        jne     @F
                                        mov     al, [PokeRamBank]
                                        cmp     [esi].TRECENTPOKE.RamBank, al
                                        je      SkipNewPokeListEntry    ; found a matching poke in recent pokes list

                                    @@: add     esi, sizeof TRECENTPOKE
                                        inc     ebx
                                .endw

                                ; add this as a new Recent Pokes List entry
                                lea     edi, RecentPokesList+((MAXPOKEENTRIES-1)*sizeof TRECENTPOKE)
                                lea     esi, [edi]-sizeof TRECENTPOKE
                                mov     ecx, ((MAXPOKEENTRIES-1)*sizeof TRECENTPOKE)
                                std
                                rep     movsb
                                cld

                                lea     edi, RecentPokesList
                                m2m     [edi].TRECENTPOKE.Address, [PokeAddress]
                                m2m     [edi].TRECENTPOKE.Value, [PokeValue]
                                mov     al, [PokeRamBank]
                                mov     [edi].TRECENTPOKE.RamBank, al
                                mov     [edi].TRECENTPOKE.UsedEntry, TRUE
                                invoke  PopulateRecentPokesList, [hWndDlg]

        SkipNewPokeListEntry:
                                .if     PokeUpdatesDebugger == TRUE
                                        invoke  UpdateDisassembly	; update disassembly display
                                        invoke  PopulateMemoryDlg   ; update memory dialog
                                .endif

                                popad
                                return  TRUE
                        .endif
                .endif

        .elseif uMsg == WM_DESTROY
                invoke  IsDlgButtonChecked, [hWndDlg], IDC_OVERRIDEBANK ; BST_UNCHECKED = 0, BST_CHECKED = 1
                mov     [OverridePokedPage], al
                return  TRUE

        .endif
        return  FALSE

PokeDlgProc     endp

;########################################################################

PopulateRecentPokesList proc    uses        esi edi ebx,
                                hWndDlg:    DWORD

                        local   textstring: TEXTSTRING,
                                pTEXTSTRING:DWORD

                invoke  SendDlgItemMessage, hWndDlg, IDC_RECENTPOKESCOMBO, CB_RESETCONTENT, 0, 0

                lea     esi, RecentPokesList
                SETLOOP MAXPOKEENTRIES
                        .if     [esi].TRECENTPOKE.UsedEntry == TRUE
                                invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                                ADDDIRECTTEXTSTRING pTEXTSTRING, "POKE "
                                ADDTEXTDECIMAL      pTEXTSTRING, [esi].TRECENTPOKE.Address
                                ADDCHAR             pTEXTSTRING, ","
                                ADDTEXTDECIMAL      pTEXTSTRING, [esi].TRECENTPOKE.Value

                                .if     [esi].TRECENTPOKE.RamBank != -1
                                        ADDDIRECTTEXTSTRING pTEXTSTRING, "  (RAM: "
                                        movzx   eax, [esi].TRECENTPOKE.RamBank
                                        ADDTEXTDECIMAL  pTEXTSTRING, eax
                                        ADDCHAR         pTEXTSTRING, ")"
                                .endif
                                invoke  SendDlgItemMessage, hWndDlg, IDC_RECENTPOKESCOMBO, CB_ADDSTRING, 0, addr textstring
                        .endif
                        add     esi, sizeof TRECENTPOKE
                ENDLOOP

                invoke  SendDlgItemMessage, hWndDlg, IDC_RECENTPOKESCOMBO, CB_SETCURSEL, 0, 0
                ret

PopulateRecentPokesList endp




