
TWD1793FDCState         STRUCT
TrackReg                BYTE    ?
SectorReg               BYTE    ?
StatusReg               BYTE    ?
DataReg                 BYTE    ?
SystemReg               BYTE    ?
StepDir                 BYTE    ?
CommandReg              BYTE    ?
TWD1793FDCState         ENDS

TWD1793DriveState       STRUCT
Cylinder                BYTE    ?
DiskType                BYTE    ?
TWD1793DriveState       ENDS

; Disk image types
DISKTYPE_NONE           equ     0
DISKTYPE_TRD            equ     1
DISKTYPE_SCL            equ     2
DISKTYPE_MGT            equ     3
DISKTYPE_IMG            equ     4

wd1793_Initialise       macro
                        call    [fwd1793_Initialise]
                        endm

wd1793_ShutDown         macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ShutDown]
                        endm

wd1793_ResetDevice      macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ResetDevice]
                        endm

wd1793_SetActiveCallback    macro   WD1793Handle, lpActiveCallback
                            push    lpActiveCallback
                            push    WD1793Handle
                            call    [fwd1793_SetActiveCallback]
                            endm

wd1793_SetDriveStepCallback macro   WD1793Handle, lpDriveStepCallback
                            push    lpDriveStepCallback
                            push    WD1793Handle
                            call    [fwd1793_SetDriveStepCallback]
                            endm

wd1793_InsertTRDOSDisk  macro   WD1793Handle, UnitNum, lpFileName
                        push    lpFileName
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_InsertTRDOSDisk]
                        endm

wd1793_InsertPlusDDisk  macro   WD1793Handle, UnitNum, lpFileName
                        push    lpFileName
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_InsertPlusDDisk]
                        endm

wd1793_EjectDisks       macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_EjectDisks]
                        endm

wd1793_EjectDisk        macro   WD1793Handle, UnitNum
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_EjectDisk]
                        endm

wd1793_ReadStatusReg    macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ReadStatusReg]
                        endm

wd1793_ReadTrackReg     macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ReadTrackReg]
                        endm

wd1793_WriteTrackReg    macro   WD1793Handle, NewTrack
                        push    NewTrack
                        push    WD1793Handle
                        call    [fwd1793_WriteTrackReg]
                        endm

wd1793_ReadSectorReg    macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ReadSectorReg]
                        endm

wd1793_WriteSectorReg   macro   WD1793Handle, NewSector
                        push    NewSector
                        push    WD1793Handle
                        call    [fwd1793_WriteSectorReg]
                        endm

wd1793_ReadDataReg      macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ReadDataReg]
                        endm

wd1793_WriteDataReg     macro   WD1793Handle, NewData
                        push    NewData
                        push    WD1793Handle
                        call    [fwd1793_WriteDataReg]
                        endm

wd1793_ReadSystemReg    macro   WD1793Handle
                        push    WD1793Handle
                        call    [fwd1793_ReadSystemReg]
                        endm

wd1793_WriteSystemReg   macro   WD1793Handle, NewSystem
                        push    NewSystem
                        push    WD1793Handle
                        call    [fwd1793_WriteSystemReg]
                        endm

wd1793_WriteCommandReg  macro   WD1793Handle, NewCmd
                        push    ZeroExt (zPC)
                        push    NewCmd
                        push    WD1793Handle
                        call    [fwd1793_WriteCommandReg]
                        endm

wd1793_DiskInserted     macro   WD1793Handle, UnitNum
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_DiskInserted]
                        movzx   eax, al
                        endm

wd1793_SCL2TRD          macro   lpInFile, lpOutFile
                        push    lpOutFile
                        push    lpInFile
                        call    [fwd1793_SCL2TRD]
                        endm

wd1793_GetFDCState      macro   WD1793Handle, pWD1793FDCState
                        push    pWD1793FDCState
                        push    WD1793Handle
                        call    [fwd1793_GetFDCState]
                        endm

wd1793_SetFDCState      macro   WD1793Handle, pWD1793FDCState
                        push    pWD1793FDCState
                        push    WD1793Handle
                        call    [fwd1793_SetFDCState]
                        endm

wd1793_GetDriveState    macro   WD1793Handle, UnitNum, pWD1793DriveState
                        push    pWD1793DriveState
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_GetDriveState]
                        endm

wd1793_SetDriveState    macro   WD1793Handle, UnitNum, pWD1793DriveState
                        push    pWD1793DriveState
                        push    UnitNum
                        push    WD1793Handle
                        call    [fwd1793_SetDriveState]
                        endm



