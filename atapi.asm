
    include atapi.inc

.data?
align 4
atapi_dllmodule         dd  ?

atapi_available         db  ?
atapiprocscount         db  ?
atapiprocsfound         db  ?
.code

Atapi_LoadDLL           PROTO
Atapi_UnloadDLL         PROTO
GetAtapiProcAddress     PROTO   lpFncName:  DWORD

Atapi_RemoveUnit        PROTO   :BYTE
Atapi_IsAttached        PROTO   :BYTE

GetDLLProc  macro   fncname:REQ
            .data?
            align 4
            f&fncname&  dd  ?
            .code
            mov     f&fncname&, $fnc (DLLPROC, SADD("&fncname&"))
            endm

Atapi_LoadDLL       proc

                    mov     atapi_available, FALSE

                    mov     atapi_dllmodule, $fnc (LoadLibrary, SADD("atapi.dll"))

                    .if     eax != NULL
                            mov     atapiprocscount, 0
                            mov     atapiprocsfound, 0

                            DLLPROC     equ <GetAtapiProcAddress>
                            GetDLLProc  IDE_Initialise
                            GetDLLProc  IDE_ShutDown
                            GetDLLProc  IDE_HardwareReset
                            GetDLLProc  IDE_SelectHDF
                            GetDLLProc  IDE_CloseHDFFiles
                            GetDLLProc  IDE_CloseHDFFile
                            GetDLLProc  IDE_WriteData
                            GetDLLProc  IDE_WriteFeature
                            GetDLLProc  IDE_WriteSectorCount
                            GetDLLProc  IDE_WriteSectorNumber
                            GetDLLProc  IDE_WriteCylinderLow
                            GetDLLProc  IDE_WriteCylinderHigh
                            GetDLLProc  IDE_WriteDrive_Head
                            GetDLLProc  IDE_WriteCommand
                            GetDLLProc  IDE_ReadData
                            GetDLLProc  IDE_ReadError
                            GetDLLProc  IDE_ReadSectorCount
                            GetDLLProc  IDE_ReadSectorNumber
                            GetDLLProc  IDE_ReadCylinderLow
                            GetDLLProc  IDE_ReadCylinderHigh
                            GetDLLProc  IDE_ReadDrive_Head
                            GetDLLProc  IDE_ReadStatus

                            GetDLLProc  IDE_GetHDFSectorSize
                            GetDLLProc  IDE_SetHDFAccessSize

                          ; set 'atapi_available' to True if all atapi.dll functions located
                            mov     al, atapiprocscount
                            .if     al == atapiprocsfound
                                    mov    atapi_available, TRUE
                            .endif
                    .endif
                    return  atapi_available

Atapi_LoadDLL       endp

GetAtapiProcAddress proc    lpFncName:  DWORD
                    inc     atapiprocscount             ; increment procs searched counter
                    invoke  GetProcAddress, atapi_dllmodule, lpFncName
                    .if     eax != NULL
                            inc     atapiprocsfound     ; increment procs found counter
                    .endif
                    ret
GetAtapiProcAddress endp


Atapi_UnloadDLL     proc
                    .if     atapi_dllmodule != NULL
                            invoke  FreeLibrary, atapi_dllmodule
                    .endif
                    ret
Atapi_UnloadDLL     endp


Atapi_RemoveUnit    proc    Unit: BYTE
                    switch  Unit
                            case    0
                                    IDE_CloseHDFFile    IDEHandle, 0
                            case    1
                                    IDE_CloseHDFFile    IDEHandle, 1
                    endsw
                    ret
Atapi_RemoveUnit    endp

Atapi_IsAttached    proc    Unit: BYTE
                    switch  Unit
                            case    0
                                    IDE_GetHDFSectorSize    IDEHandle, 0
                                    .if     eax != 0
                                            return  TRUE
                                    .endif
                            case    1
                                    IDE_GetHDFSectorSize    IDEHandle, 1
                                    .if     eax != 0
                                            return  TRUE
                                    .endif
                    endsw
                    return  FALSE
Atapi_IsAttached    endp

