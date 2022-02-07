
PLUSD_Initialise        PROTO
PLUSD_PageIn            PROTO
PLUSD_PageOut           PROTO
PLUSD_PreloadRAMImage   PROTO

PLUSD_Initialise        proc
                        mov     PLUSD_Paged, FALSE

                        wd1793_ResetDevice          PLUSDHandle
                        wd1793_SetActiveCallback    PLUSDHandle, offset AddOnFastDiskCallback
                        wd1793_SetDriveStepCallback PLUSDHandle, offset AddOnDriveStepCallback  ; in Machines.asm
                        ret
PLUSD_Initialise        endp

PLUSD_PageIn            proc

                        mov     currentMachine.RAMREAD0,  offset gdos_rom
                        mov     currentMachine.RAMWRITE0, offset DummyMem

                        mov     currentMachine.RAMREAD1,  offset gdos_ram
                        mov     currentMachine.RAMWRITE1, offset gdos_ram

                        mov     PLUSD_Paged, TRUE
                        ret
PLUSD_PageIn            endp

PLUSD_PageOut           proc
                        mov     al, Last7FFDWrite
                        call    Page_ROM

                        mov     PLUSD_Paged, FALSE
                        ret
PLUSD_PageOut           endp

; PLUSD_PreloadRAMImage is called during a hard reset to reinitialise the selected preloaded RAM image

PLUSD_PreloadRAMImage   proc
                        switch  PreloadPlusDImage
                                case    PD_PRELOAD_NOTHING
                                        memclr  addr gdos_ram, 8192

                                case    PD_PRELOAD_GDOS
                                        memcpy  addr GDOS_RamImage, addr gdos_ram, 8192

                                case    PD_PRELOAD_BETADOS
                                        memcpy  addr BETADOS_RamImage, addr gdos_ram, 8192
                        endsw
                        ret
PLUSD_PreloadRAMImage   endp




