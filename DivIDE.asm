
; and be sure to disable NMIs when the divide is paged in (Activated)

DIVIDE_CONMEM           equ     128
DIVIDE_MAPRAM           equ     64


DivIDE_Initialise       PROTO   :BOOL
DivIDE_LoadFirmware     PROTO
DivIDE_PageOut          PROTO
DivIDE_ControlOUT       PROTO   :BYTE
DivIDE_MemTestA         PROTO
DivIDE_MemTestB         PROTO
DivIDE_Paging           PROTO

TDivIDE                 STRUCT
Mapped                  BYTE    ?
JP2                     BYTE    ?
PortValue               BYTE    ?
TDivIDE                 ENDS


.data?
align 4
DivIDE                  TDivIDE <>

.data
HardDiskNotDivIDE_cap   db  "The hard disk file in Unit "
HardDiskNotDivIDE_unit  db  " "
                        db  " is not fully compatible with the DivIDE interface.",13,10,13,10
                        db  "Would you like to detach this hard disk in order to prevent possible data corruption?",0
HardDiskNotDivIDE_title db  "Hard Disk Corruption Warning",0
.code

DivIDE_Initialise       proc    HardReset: BOOL

                        mov     DivIDE.JP2,    FALSE
                        mov     DivIDE.Mapped, FALSE
                        mov     DivIDE.PortValue, 0

                        ifc     HardReset eq TRUE then invoke DivIDE_LoadFirmware

                        memset  addr DivIDE_Mem, 32768, 255

                        IDE_GetHDFSectorSize    IDEHandle, 0
                        .if     eax == 256
                                mov     HardDiskNotDivIDE_unit, "0"
                                invoke  ShowMessageBox, hWnd, addr HardDiskNotDivIDE_cap,
                                                              addr HardDiskNotDivIDE_title, MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON1
                                .if     eax == IDYES
                                        invoke  Atapi_RemoveUnit, 0
                                        mov     byte ptr IDEUnit0Filename[0], 0
                                .endif
                        .endif

                        IDE_GetHDFSectorSize    IDEHandle, 1
                        .if     eax == 256
                                mov     HardDiskNotDivIDE_unit, "1"
                                invoke  ShowMessageBox, hWnd, addr HardDiskNotDivIDE_cap,
                                                              addr HardDiskNotDivIDE_title, MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON1
                                .if     eax == IDYES
                                        invoke  Atapi_RemoveUnit, 1
                                        mov     byte ptr IDEUnit1Filename[0], 0
                                .endif
                        .endif

                        ret
DivIDE_Initialise       endp

DivIDE_LoadFirmware     proc    uses    ebx esi edi

                        mov     Filename, offset DivIDEFirmwareFilename
                        call    OpenMyReadFile
                        .if     eax != 0
                                mov     ReadStart, offset DivIDE_FirmwareMem
                                mov     ReadLen,   8192
                                call    ReadMyFile
                                call    CloseMyFile
                        .endif
                        ret
DivIDE_LoadFirmware     endp

DivIDE_ControlOUT       proc    Value:  BYTE

                        ; Once set to '1', MAPRAM can only be reset again with a power-on. RESET leaves it unchanged.

                        mov     cl, DivIDE.PortValue
                        and     cl, 64                  ; last MAPRAM value

                        mov     al, Value
                        and     al, 11000011b           ; mask out unused bits
                        or      al, cl                  ; set MAPRAM if previously set
                        mov     DivIDE.PortValue, al

                        invoke  DivIDE_Paging
                        ret
DivIDE_ControlOUT       endp


DivIDE_Paging           proc

                        test    DivIDE.PortValue, DIVIDE_CONMEM
                        .if     !ZERO?
                                ; CONMEM set:
                                ; 0000h-1FFFh - EEPROM/EPROM/NOTHING (if empty socket), writable if 'E' link absent
                                ; 2000h-3FFFh - 8K RAM selected by BANK bits, always writable.

                                mov     currentMachine.RAMREAD0,  offset DivIDE_FirmwareMem
                                mov     currentMachine.RAMWRITE0, offset DummyMem

                                movzx   eax, DivIDE.PortValue
                                and     eax, 3
                                shl     eax, 13         ; * 8192
                                add     eax, offset DivIDE_Mem
                                mov     currentMachine.RAMREAD1,  eax
                                mov     currentMachine.RAMWRITE1, eax
                                ret
                        .endif

                        ; page the DivIDE out now if it's not currently mapped
                        .if     DivIDE.Mapped == FALSE
                                invoke  DivIDE_PageOut
                                ret
                        .endif

                        ; continue here if DivIDE is currently mapped
                        test    DivIDE.PortValue, DIVIDE_MAPRAM
                        .if     !ZERO?
                                ; CONMEM clear, MAPRAM set, entrypoint executed:
                                ; 0000h-1FFFh - Bank 3, read-only
                                ; 2000h-3FFFh - 8K RAM selected by BANK bits. Writable, unless bank 3.

                                mov     currentMachine.RAMREAD0,  offset DivIDE_Mem+(3*8192)
                                mov     currentMachine.RAMWRITE0, offset DummyMem

                                movzx   eax, DivIDE.PortValue
                                and     eax, 3
                                mov     ecx, eax        ; bank number to ecx
                                shl     eax, 13         ; * 8192
                                add     eax, offset DivIDE_Mem
                                mov     currentMachine.RAMREAD1,  eax
                                mov     currentMachine.RAMWRITE1, eax
                                .if     ecx == 3
                                        mov     currentMachine.RAMWRITE1, offset DummyMem  ; bank 3 is not writeable
                                .endif
                                ret
                        .endif

                        ; CONMEM clear, MAPRAM clear, entrypoint executed:
                        ; 0000h-1FFFh - EEPROM/EPROM/NOTHING (if empty socket), read-only.
                        ; 2000h-3FFFh - 8K RAM selected by BANK bits, always writable.

                        mov     currentMachine.RAMREAD0,  offset DivIDE_FirmwareMem
                        mov     currentMachine.RAMWRITE0, offset DummyMem

                        movzx   eax, DivIDE.PortValue
                        and     eax, 3
                        shl     eax, 13         ; * 8192
                        add     eax, offset DivIDE_Mem
                        mov     currentMachine.RAMREAD1,  eax
                        mov     currentMachine.RAMWRITE1, eax
                        ret
DivIDE_Paging           endp

DivIDE_PageOut          proc

                        mov     DivIDE.Mapped, FALSE

                        mov     al, Last7FFDWrite
                        call    Page_ROM
                        ret
DivIDE_PageOut          endp

DivIDE_MemTestA         proc

                      ; this area will activate the DivIDE (almost) instantly - 100ns after the falling edge of /MREQ
                        movzx   eax, zPC
                        and     eax, 0FF00h
                        .if     eax == 3D00h
                                mov     DivIDE.Mapped, TRUE
                                invoke  DivIDE_Paging
                        .endif
                        ret
DivIDE_MemTestA         endp

DivIDE_MemTestB         proc

                      ; these regions activate or deactivate the DivIDE after the opcode fetch
                        movzx   eax, zPC
                        .if     eax <= 0562h
                                .if     (eax == 0) || (eax == 8) || (eax == 38h) || (eax == 66h) || (eax == 04C6h) || (eax == 0562h)
                                        mov     DivIDE.Mapped, TRUE
                                        invoke  DivIDE_Paging
                                .endif
                        .else
                                and     eax, 0FFF8h
                                .if     eax == 1FF8h
                                        mov     DivIDE.Mapped, FALSE
                                        test    DivIDE.PortValue, DIVIDE_CONMEM
                                        .if     ZERO?
                                                invoke  DivIDE_PageOut
                                        .endif
                                .endif
                        .endif
                        ret
DivIDE_MemTestB         endp



