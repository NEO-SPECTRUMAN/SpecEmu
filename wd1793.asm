
    include wd1793.inc

;USEDELPHI_WD1793DLL     equ   TRUE

.data?
align 4
wd1793_dllmodule        dd  ?

wd1793_available        db  ?
wd1793procscount        db  ?
wd1793procsfound        db  ?

.code

wd1793_LoadDLL          PROTO
wd1793_UnloadDLL        PROTO
Getwd1793ProcAddress    PROTO   lpFncName:  DWORD

GetDLLProc  macro   fncname:REQ
            .data?
            align 4
            f&fncname&  dd  ?
            .code
            mov     f&fncname&, $fnc (DLLPROC, SADD("&fncname&"))
            endm

wd1793_LoadDLL      proc

                    mov     wd1793_available, FALSE

                    IFDEF   USEDELPHI_WD1793DLL
                            invoke  ShowMessageBox, hWnd, SADD("Using: C:\Program Files\Borland\Delphi5\Projects\wd1793\wd1793.dll"),
                                                    ADDR szWindowName, MB_OK or MB_ICONINFORMATION
                            mov     wd1793_dllmodule, $fnc (LoadLibrary, SADD("C:\Program Files\Borland\Delphi5\Projects\wd1793\wd1793.dll"))
                    ELSE
                            mov     wd1793_dllmodule, $fnc (LoadLibrary, SADD("wd1793.dll"))
                    ENDIF



                    .if     eax != NULL
                            mov     wd1793procscount, 0
                            mov     wd1793procsfound, 0

                            DLLPROC     equ <Getwd1793ProcAddress>
                            GetDLLProc  wd1793_Initialise
                            GetDLLProc  wd1793_ShutDown
                            GetDLLProc  wd1793_ResetDevice
                            GetDLLProc  wd1793_SetActiveCallback
                            GetDLLProc  wd1793_SetDriveStepCallback
                            GetDLLProc  wd1793_InsertTRDOSDisk
                            GetDLLProc  wd1793_InsertPlusDDisk
                            GetDLLProc  wd1793_EjectDisks
                            GetDLLProc  wd1793_EjectDisk
                            GetDLLProc  wd1793_ReadStatusReg
                            GetDLLProc  wd1793_ReadTrackReg
                            GetDLLProc  wd1793_WriteTrackReg
                            GetDLLProc  wd1793_ReadSectorReg
                            GetDLLProc  wd1793_WriteSectorReg
                            GetDLLProc  wd1793_ReadDataReg
                            GetDLLProc  wd1793_WriteDataReg
                            GetDLLProc  wd1793_ReadSystemReg
                            GetDLLProc  wd1793_WriteSystemReg
                            GetDLLProc  wd1793_WriteCommandReg
                            GetDLLProc  wd1793_DiskInserted
                            GetDLLProc  wd1793_SCL2TRD
                            GetDLLProc  wd1793_GetFDCState
                            GetDLLProc  wd1793_SetFDCState
                            GetDLLProc  wd1793_GetDriveState
                            GetDLLProc  wd1793_SetDriveState

                          ; set 'wd1793_available' to True if all wd1793.dll functions located
                            mov     al, wd1793procscount
                            .if     al == wd1793procsfound
                                    mov    wd1793_available, TRUE
                            .endif
                    .endif
                    return  wd1793_available

wd1793_LoadDLL       endp

Getwd1793ProcAddress proc    lpFncName:  DWORD
                    inc     wd1793procscount             ; increment procs searched counter
                    invoke  GetProcAddress, wd1793_dllmodule, lpFncName
                    .if     eax != NULL
                            inc     wd1793procsfound     ; increment procs found counter
                    .endif
                    ret
Getwd1793ProcAddress endp


wd1793_UnloadDLL     proc
                    .if     wd1793_dllmodule != NULL
                            invoke  FreeLibrary, wd1793_dllmodule
                    .endif
                    ret
wd1793_UnloadDLL     endp






