
IDE_Initialise          macro
                        call    [fIDE_Initialise]
                        endm

IDE_ShutDown            macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ShutDown]
                        endm

IDE_SelectHDF           macro   lpIDEHandle, IDEUnitNumber, lpFileName
                        push    lpFileName
                        push    IDEUnitNumber
                        push    lpIDEHandle
                        call    [fIDE_SelectHDF]
                        endm

IDE_CloseHDFFile        macro   lpIDEHandle, IDEUnitNumber
                        push    IDEUnitNumber
                        push    lpIDEHandle
                        call    [fIDE_CloseHDFFile]
                        endm

IDE_CloseHDFFiles       macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_CloseHDFFiles]
                        endm

IDE_HardwareReset       macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_HardwareReset]
                        endm

IDE_WriteCommand        macro   lpIDEHandle, CmdByte
                        push    CmdByte
                        push    lpIDEHandle
                        call    [fIDE_WriteCommand]
                        endm

IDE_WriteData           macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteData]
                        endm

IDE_WriteFeature        macro   lpIDEHandle, ArgByte
                        push    ArgByte
                        push    lpIDEHandle
                        call    [fIDE_WriteFeature]
                        endm

IDE_WriteSectorCount    macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteSectorCount]
                        endm

IDE_WriteSectorNumber   macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteSectorNumber]
                        endm

IDE_WriteCylinderLow    macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteCylinderLow]
                        endm

IDE_WriteCylinderHigh   macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteCylinderHigh]
                        endm

IDE_WriteDrive_Head     macro   lpIDEHandle, DataByte
                        push    DataByte
                        push    lpIDEHandle
                        call    [fIDE_WriteDrive_Head]
                        endm

IDE_ReadData            macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadData]
                        endm

IDE_ReadError           macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadError]
                        endm

IDE_ReadSectorCount     macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadSectorCount]
                        endm

IDE_ReadSectorNumber    macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadSectorNumber]
                        endm

IDE_ReadCylinderLow     macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadCylinderLow]
                        endm

IDE_ReadCylinderHigh    macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadCylinderHigh]
                        endm

IDE_ReadDrive_Head      macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadDrive_Head]
                        endm

IDE_ReadStatus          macro   lpIDEHandle
                        push    lpIDEHandle
                        call    [fIDE_ReadStatus]
                        endm

IDE_GetHDFSectorSize    macro   lpIDEHandle, IDEUnitNumber
                        push    IDEUnitNumber
                        push    lpIDEHandle
                        call    [fIDE_GetHDFSectorSize]
                        endm

IDE_SetHDFAccessSize    macro   lpIDEHandle, IDEUnitNumber, AccessSize
                        push    AccessSize
                        push    IDEUnitNumber
                        push    lpIDEHandle
                        call    [fIDE_SetHDFAccessSize]
                        endm






