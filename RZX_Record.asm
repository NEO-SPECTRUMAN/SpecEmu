
RZX_ALLOW_REPEAT_FRAMES equ     TRUE

.code
Create_RZX              proc    uses        esi ebx,
                                continue:   BOOL

                        local   ofn:        OPENFILENAME

                        local   rzx_header   [sizeof RZX_HEADER]:       BYTE,
                                rzx_creator  [sizeof RZX_CREATOR_INFO]: BYTE

                        m2m     RZXREC.rzx_continue, continue

                        ifc     RZXREC.rzx_continue eq TRUE then mov ebx, CTXT ("Continue RZX") else mov ebx, CTXT ("Create RZX")

                        invoke  SaveFileName, hWnd, ebx, addr szRZXFilter, addr ofn, addr RZXfilename, addr RZXExt, 0

                        ifc     eax eq 0 then return FALSE

                        invoke  Close_RZX, 0, FALSE

                        invoke  NewList, addr RZXREC.BlockList

                        .if     RZXREC.rzx_continue == FALSE
                                invoke  AskOverwriteFile, addr RZXfilename, hWnd, addr szWindowName
                                ifc     eax eq FALSE then return FALSE
    
                                invoke  CreateFile, addr RZXfilename, GENERIC_READ or GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                                ifc     eax eq INVALID_HANDLE_VALUE then return FALSE
                                mov     RZXREC.RZX_FH, eax

;                                invoke  Start_PC_Logging
                        .else
                                invoke  CreateFile, addr RZXfilename, GENERIC_READ or GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                                ifc     eax eq INVALID_HANDLE_VALUE then return FALSE
                                mov     RZXREC.RZX_FH, eax

                                ; *** NOTE: we need to check here that this is a SpecEmu file before allowing recording to continue ***
                                invoke  ReadFile, RZXREC.RZX_FH, addr rzx_header, sizeof RZX_HEADER, addr BytesMoved, NULL
                                lea     eax, rzx_header
                                ifc     [eax].RZX_HEADER.Signature ne RZX_SIGNATURE then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE

                                invoke  ReadFile, RZXREC.RZX_FH, addr rzx_creator, sizeof RZX_CREATOR_INFO, addr BytesMoved, NULL
                                lea     esi, rzx_creator.RZX_CREATOR_INFO.Creator_String
                                invoke  szCmp, esi, addr RZX_CreatorString
                                ifc     eax eq 0 then invoke Close_RZX, SADD ("SpecEmu can only continue recording to its own recording files"), FALSE : return FALSE
                        .endif

                        strcpy  addr RZXfilename, addr szRecentFileName
                        invoke  AddRecentFile   ; add RZX file to recent files list

                        ; move to the start of the file and write new (or updated) RZX Header and Creator Info blocks
                        invoke  SetFilePointer, RZXREC.RZX_FH, 0, NULL, FILE_BEGIN

                        lea     esi, rzx_header
                        memclr  esi, sizeof RZX_HEADER
                        mov     [esi].RZX_HEADER.Signature, RZX_SIGNATURE
                        mov     [esi].RZX_HEADER.Major,     RZX_MAJOR
                        mov     [esi].RZX_HEADER.Minor,     RZX_MINOR
                        invoke  WriteFile, RZXREC.RZX_FH, esi, sizeof RZX_HEADER, addr BytesSaved, NULL

                        lea     esi, rzx_creator
                        memclr  esi, sizeof RZX_CREATOR_INFO
                        mov     [esi].RZX_CREATOR_INFO.Block_ID,        RZXBLK_CREATORINFO
                        mov     [esi].RZX_CREATOR_INFO.Block_Length,    sizeof RZX_CREATOR_INFO ; no custom data for now...
                        mov     [esi].RZX_CREATOR_INFO.Creator_Major,   SPECEMU_MAJOR
                        mov     [esi].RZX_CREATOR_INFO.Creator_Minor,   SPECEMU_MINOR
                        invoke  @@CopyString, addr RZX_CreatorString,   addr [esi].RZX_CREATOR_INFO.Creator_String
                        invoke  WriteFile, RZXREC.RZX_FH, addr rzx_creator, sizeof RZX_CREATOR_INFO, addr BytesSaved, NULL

                        .if     RZXREC.rzx_continue == FALSE
                                ; create the first set of snapshot and input recording blocks
                                invoke  RZX_Write_Snapshot
                                ifc     eax eq FALSE then invoke Close_RZX, SADD ("I/O file error"), FALSE : return FALSE
                                invoke  RZX_Write_Input_Recording_Block
                        .else
                                ; when continuing, the final block should be a snapshot block,
                                ; so load that snapshot and create a new IRB block immediately afterwards for recording
                                invoke  RZX_BuildBlockList, addr RZXREC
                                ifc     eax eq FALSE then invoke Close_RZX, SADD ("Invalid RZX format"), FALSE : return FALSE

                                lea     esi, RZXREC.BlockList
                                mov     esi, [esi].ListHeader.lh_Tail
                                ifc     $fnc (IsListHeader, esi) eq TRUE then invoke Close_RZX, SADD ("Invalid RZX format"), FALSE : return FALSE

                                mov     al, [esi].RZX_Node.block_type
                                ifc     al ne RZXBLK_SNAPSHOT then invoke Close_RZX, SADD ("Cannot continue recording to this RZX file"), FALSE : return FALSE

                                invoke  SetFilePointer, RZXREC.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                                invoke  RZX_Load_Snapshot, addr RZXREC
                                ifc     eax eq FALSE then return FALSE  ; the RZX is closed upon error in 'RZX_Load_Snapshot'

                                invoke  RZX_Write_Input_Recording_Block
                        .endif

                        invoke  SetMenuItemText, MenuHandle, IDM_RZX_STOP, CTXT ("Stop Recording")

                        mov     RZXREC.RZX_auto_rollback_frames, 0 ; initialise frames before an auto-rollback point

                        mov     rzx_mode, RZX_RECORD
                        invoke  RZX_EnableMenuItems

                        return  TRUE
Create_RZX              endp

align 16
RZX_Insert_Bookmark     proc
                        .if     rzx_mode == RZX_RECORD
                                invoke  Write_IRB, TRUE     ; close the current IRB
    
                                ; create a new set of snapshot and input recording blocks
                                invoke  RZX_Write_Snapshot
                                ifc     eax eq FALSE then invoke Close_RZX, SADD ("I/O file error"), FALSE : return FALSE
                                invoke  RZX_Write_Input_Recording_Block
    
                                invoke  FlashWindow, hWnd, TRUE
                                mov     rzx_flash_window_counter, 2
                        .endif
                        ret
RZX_Insert_Bookmark     endp

align 16
RZX_Rollback            proc    uses    ebx esi edi

                        local   rollbackcnt:    DWORD,
                                rollbacknode:   DWORD,
                                rollbacktstates:DWORD

                        local   t_rzx_io_block [sizeof RZX_INPUT_RECORDING]: BYTE

                        .if     rzx_mode == RZX_RECORD
                                mov     rollbacknode, 0

                                .if     (RZX_Pause_On_Rollback == TRUE) && (EmuRunning == TRUE)
                                        invoke  PauseResumeEmulation
                                .endif

                                invoke  Write_IRB, TRUE     ; close the current IRB

                                m2m     rollbacktstates, totaltstates

                                mov     rollbackcnt, 1
                                ifc     RZXREC.rzx_current_frame lt 25 then mov rollbackcnt, 2 ; rollback two snapshots if less than 2 seconds into the current IRB

                                lea     esi, RZXREC.BlockList

                                .while  rollbackcnt > 0
                                        dec     rollbackcnt

                                        .while  TRUE
                                                mov     esi, [esi].ListNode.ln_Pred
                                                .break  .if $fnc (IsListHeader, esi) == TRUE

                                                .if     [esi].RZX_Node.block_type == RZXBLK_SNAPSHOT
                                                        mov     rollbacknode, esi   ; snapshot node we will rollback to

                                                        ; delete all nodes following the rollback node
                                                        push    esi
                                                        mov     esi, [esi].RZX_Node.Node.ln_Succ
                                                        .while  TRUE
                                                                .break  .if $fnc (IsListHeader, esi) == TRUE
                                                                mov     edi, [esi].RZX_Node.Node.ln_Succ
                                                                invoke  RemoveNode, esi
                                                                FreeMem esi
                                                                mov     esi, edi
                                                        .endw
                                                        pop     esi
                                                        .break

                                                .elseif [esi].RZX_Node.block_type == RZXBLK_INPUTRECORDING
                                                        invoke  SetFilePointer, RZXREC.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                                                        invoke  ReadFile, RZXREC.RZX_FH, addr t_rzx_io_block, sizeof RZX_INPUT_RECORDING, addr BytesMoved, NULL
                                                        m2m     rollbacktstates, t_rzx_io_block.RZX_INPUT_RECORDING.Init_TStates
                                                .endif
                                        .endw
                                .endw

                                ; now rollback if applicable
                                .if     rollbacknode != 0
                                        mov     esi, rollbacknode

                                        invoke  SetFilePointer, RZXREC.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                                        invoke  RZX_Load_Snapshot, addr RZXREC
                                        ifc     eax eq FALSE then return FALSE  ; the RZX is closed upon error in 'RZX_Load_Snapshot'

                                        m2m     totaltstates, rollbacktstates
                                        invoke  RZX_Write_Input_Recording_Block
                                .endif
                        .endif
                        ret
RZX_Rollback            endp

align 16
RZX_Write_Input_Recording_Block proc    uses    esi

                                lea     esi, RZXREC.rzx_input_block
                                memclr  esi, sizeof RZX_INPUT_RECORDING
                                mov     [esi].RZX_INPUT_RECORDING.Block_ID,         RZXBLK_INPUTRECORDING
                                mov     [esi].RZX_INPUT_RECORDING.Block_Length,     sizeof RZX_INPUT_RECORDING  ; initial block length
                                mov     [esi].RZX_INPUT_RECORDING.Frames_Count,     -1
                                m2m     [esi].RZX_INPUT_RECORDING.Init_TStates,     totaltstates
                                mov     [esi].RZX_INPUT_RECORDING.Flags,            0           ; not compressed atm

                                mov     RZXREC.rzx_current_frame, 0

                                invoke  Init_Recording_Frame

                                ; create a new node for this block at the start of the block data
                                invoke  RZX_Add_Block_Tail, addr RZXREC, RZXBLK_INPUTRECORDING

                                invoke  Write_IRB, FALSE    ; write this block to the RZX file
                                invoke  SetFilePointer, RZXREC.RZX_FH, sizeof RZX_INPUT_RECORDING, 0, FILE_CURRENT ; advance beyond the IRB header

                                return  TRUE

RZX_Write_Input_Recording_Block endp

align 16
RZX_Write_Snapshot  proc    uses    esi edi ebx

                    local   snapmem:    DWORD,
                            snaplen:    DWORD

                    local   rzx_snapshot [sizeof RZX_SNAPSHOT]: BYTE,
                            tempsnapfile [MAX_PATH]           : BYTE

                    invoke  CreateTempFile, addr tempsnapfile, addr SnapFH
                    ifc     eax eq FALSE then return FALSE

                    call    Save_SZXFormat

                    invoke  CloseHandle, SnapFH
                    mov     SnapFH, 0

                    .if     $fnc (ReadFileToMemory, addr tempsnapfile, addr snapmem, addr snaplen) == 0
                            invoke  DeleteFile, addr tempsnapfile
                            return  FALSE
                    .endif

                    ; create a new node for this block at the start of the block data
                    invoke  RZX_Add_Block_Tail, addr RZXREC, RZXBLK_SNAPSHOT

                    lea     esi, rzx_snapshot
                    memclr  esi, sizeof RZX_SNAPSHOT
                    mov     [esi].RZX_SNAPSHOT.Block_ID,            RZXBLK_SNAPSHOT
                    mov     [esi].RZX_SNAPSHOT.Extension,           "XZS"
                    mov     eax, snaplen
                    mov     [esi].RZX_SNAPSHOT.Uncompressed_Length, eax
                    add     eax, sizeof RZX_SNAPSHOT
                    mov     [esi].RZX_SNAPSHOT.Block_Length,        eax

                    invoke  WriteFile, RZXREC.RZX_FH, esi, sizeof RZX_SNAPSHOT, addr BytesSaved, NULL
                    invoke  WriteFile, RZXREC.RZX_FH, snapmem, snaplen, addr BytesSaved, NULL

                    invoke  GlobalFree, snapmem
                    invoke  DeleteFile, addr tempsnapfile
                    return  TRUE

RZX_Write_Snapshot  endp

align 16
Init_Recording_Frame    proc
                        mov     [RZXREC.rzx_io_recording].RZX_IO_RECORDING_FRAME.Fetch_Counter, 0
                        mov     [RZXREC.rzx_io_recording].RZX_IO_RECORDING_FRAME.IN_Counter,    0

                        mov     RZXREC.rzx_in_ptr, offset RZXREC.rzx_in_data
                        mov     RZXREC.rzx_in_len, 0

                        inc     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Frames_Count
                        inc     RZXREC.rzx_current_frame

;                        .if     RZXREC.rzx_current_frame > 2
;                                invoke  Close_RZX, 0, FALSE
;                                invoke  Stop_PC_Logging
;                        .endif

                        ret

Init_Recording_Frame    endp

align 16
RZX_Write_Port_Byte proc    value:  BYTE

                    mov     ecx, RZXREC.rzx_in_ptr
                    mov     al, value
                    mov     [ecx], al
                    inc     RZXREC.rzx_in_ptr
                    inc     RZXREC.rzx_in_len
                    inc     [RZXREC.rzx_io_recording].RZX_IO_RECORDING_FRAME.IN_Counter

                    .if     RZXREC.rzx_in_len > RZX_IN_BUFFER_SIZE
                            invoke  Close_RZX, SADD ("Too many INs in this frame"), TRUE
                    .endif
                    ret
RZX_Write_Port_Byte endp

align 16
RZX_Write_Frame     proc    uses    esi edi

                    neg     [RZXREC.rzx_io_recording].RZX_IO_RECORDING_FRAME.Fetch_Counter ; counts down from zero in the core

                    IF      RZX_ALLOW_REPEAT_FRAMES eq TRUE
                    .if     RZXREC.rzx_current_frame > 1
                            mov     eax, RZXREC.rzx_in_len
                            .if     eax == RZXREC.rzx_last_frame_in_len
                                    ; identical IN counter to last frame
                                    .if     $fnc (CompareMemory, addr RZXREC.rzx_in_data, addr RZXREC.rzx_last_frame_in_data, RZXREC.rzx_in_len) == TRUE
                                            ; identical port values to last frame
                                            mov     [RZXREC.rzx_io_recording].RZX_IO_RECORDING_FRAME.IN_Counter, 65535
                                            invoke  RZX_Write_Data, addr RZXREC.rzx_io_recording, sizeof RZX_IO_RECORDING_FRAME
                                            invoke  Init_Recording_Frame    ; prepare for next frame
                                            ret
                                    .endif
                            .endif
                    .endif
                    ENDIF

                    m2m     RZXREC.rzx_last_frame_in_len, RZXREC.rzx_in_len
                    .if     RZXREC.rzx_in_len > 0
                            memcpy  addr RZXREC.rzx_in_data, addr RZXREC.rzx_last_frame_in_data, RZXREC.rzx_in_len
                    .endif

                    mov     eax, sizeof RZX_IO_RECORDING_FRAME
                    add     eax, RZXREC.rzx_in_len
                    invoke  RZX_Write_Data, addr RZXREC.rzx_io_recording, eax

                    invoke  Init_Recording_Frame    ; prepare for next frame
                    ret
RZX_Write_Frame     endp

align 16
RZX_Write_Data      proc    uses    esi,
                            lpMem:  DWORD,
                            Len:    DWORD

                    mov     esi, lpMem
                    .while  Len > 0
                            dec     Len
                            invoke  RZX_Write_Buffer, byte ptr [esi]
                            inc     esi
                    .endw
                    ret
RZX_Write_Data      endp

align 16
RZX_Write_Buffer    proc    RZXByte:    BYTE

                    lea     ecx, RZXREC.RZXWriteBuffer
                    add     ecx, RZXREC.RZXWriteBufferPosn
                    mov     al,  RZXByte
                    mov     [ecx], al

                    inc     RZXREC.RZXWriteBufferPosn
                    .if     RZXREC.RZXWriteBufferPosn == sizeof RZXREC.RZXWriteBuffer
                            invoke  PurgeRZXWriteBuffer
                    .endif
                    ret
RZX_Write_Buffer    endp

align 16
PurgeRZXWriteBuffer proc

                    local   Error:  DWORD,
                            Len:    DWORD

                    .if     RZXREC.RZXWriteBufferPosn > 0

                            .if     rzx_compressed == TRUE

                                    ; purge input stream
                                    m2m     RZXREC.rzx_irb.z_stream.avail_in, RZXREC.RZXWriteBufferPosn
                                    mov     RZXREC.rzx_irb.z_stream.next_in,  offset RZXREC.RZXWriteBuffer

                                    .while  RZXREC.rzx_irb.z_stream.avail_in > 0
                                            DEFLATE offset RZXREC.rzx_irb, Z_SYNC_FLUSH ;Z_NO_FLUSH
                                            mov     Error, eax

                                            .if     RZXREC.rzx_irb.z_stream.avail_out == 0
                                                    invoke  WriteFile, RZXREC.RZX_FH, addr RZXREC.rzx_compressed_in_data, sizeof RZXREC.rzx_compressed_in_data, addr BytesSaved, NULL
                                                    mov     RZXREC.rzx_irb.z_stream.next_out,  offset RZXREC.rzx_compressed_in_data
                                                    mov     RZXREC.rzx_irb.z_stream.avail_out, sizeof RZXREC.rzx_compressed_in_data
                                                    add     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Block_Length, sizeof RZXREC.rzx_compressed_in_data
                                            .endif
                                    .endw

                                    ; purge output stream once input stream expires
                                    mov     eax, sizeof RZXREC.rzx_compressed_in_data
                                    sub     eax, RZXREC.rzx_irb.z_stream.avail_out
                                    mov     Len, eax
                                    .if     Len > 0
                                            invoke  WriteFile, RZXREC.RZX_FH, addr RZXREC.rzx_compressed_in_data, Len, addr BytesSaved, NULL
                                            mov     RZXREC.rzx_irb.z_stream.next_out,  offset RZXREC.rzx_compressed_in_data
                                            mov     RZXREC.rzx_irb.z_stream.avail_out, sizeof RZXREC.rzx_compressed_in_data
                                            mov     eax, Len
                                            add     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Block_Length, eax
                                    .endif

                            .else
                                    invoke  WriteFile, RZXREC.RZX_FH, addr RZXREC.RZXWriteBuffer, RZXREC.RZXWriteBufferPosn, addr BytesSaved, NULL
                                    mov     eax, RZXREC.RZXWriteBufferPosn
                                    add     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Block_Length, eax

                                    invoke  SetFilePointer, RZXREC.RZX_FH, 0, 0, FILE_CURRENT  ; temp
                            .endif
                    .endif

                    mov     RZXREC.RZXWriteBufferPosn, 0
                    ret
PurgeRZXWriteBuffer endp

; call at RZX creation
; and again when closing recorded RZX files
; we need to restore the file position before exit (or advance it beyond any unwritten IRB data)

align 16
Write_IRB           proc    ReallyWrite:    DWORD

                    local   currfileposn:   DWORD,
                            Done:           BOOL,
                            Len:            DWORD,
                            Error:          DWORD

                    mov     currfileposn, $fnc (SetFilePointer, RZXREC.RZX_FH, 0, 0, FILE_CURRENT)

                    .if     ReallyWrite == TRUE

                            invoke  PurgeRZXWriteBuffer

                            .if     rzx_compressed == TRUE

                                    mov     Done, FALSE
                                    .while  TRUE
                                            mov     eax, sizeof RZXREC.rzx_compressed_in_data
                                            sub     eax, RZXREC.rzx_irb.z_stream.avail_out
                                            mov     Len, eax
                                            .if     Len > 0
                                                    invoke  WriteFile, RZXREC.RZX_FH, addr RZXREC.rzx_compressed_in_data, Len, addr BytesSaved, NULL
                                                    mov     eax, Len
                                                    add     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Block_Length, eax
                                                    mov     RZXREC.rzx_irb.z_stream.next_out,  offset RZXREC.rzx_compressed_in_data
                                                    mov     RZXREC.rzx_irb.z_stream.avail_out, sizeof RZXREC.rzx_compressed_in_data
                                            .endif
                                            .break  .if Done == TRUE
                                            DEFLATE offset RZXREC.rzx_irb, Z_FINISH
                                            mov     Error, eax
                                            .if     (RZXREC.rzx_irb.z_stream.avail_out > 0) || (Error == Z_STREAM_END)
                                                    mov     Done, TRUE
                                            .endif
                                    .endw
                                    DEFLATEEND  offset RZXREC.rzx_irb
                                    mov     [RZXREC.rzx_input_block].RZX_INPUT_RECORDING.Flags, 2  ; IRB is compressed
                            .endif

                            mov     currfileposn, $fnc (SetFilePointer, RZXREC.RZX_FH, 0, 0, FILE_CURRENT) ; store file pointer beyond unwritten IRB data

                            ; write to the proper file offset for the current IRB
                            invoke  SetFilePointer, RZXREC.RZX_FH, RZXREC.rzx_irb_fileptr, 0, FILE_BEGIN  ; this is ALWAYS relative to the start of the file

                    .else
                            ; store the file offset where we will write the real Input Recording Block after recording
                            mov     RZXREC.rzx_irb_fileptr, $fnc (SetFilePointer, RZXREC.RZX_FH, 0, 0, FILE_CURRENT)

                            mov     RZXREC.RZXWriteBufferPosn, 0

                            .if     rzx_compressed == TRUE
                                    memclr  addr RZXREC.rzx_irb, sizeof z_stream
                                    mov     RZXREC.rzx_irb.z_stream.avail_in,  0
                                    mov     RZXREC.rzx_irb.z_stream.avail_out, sizeof RZXREC.rzx_compressed_in_data
                                    mov     RZXREC.rzx_irb.z_stream.next_out,  offset RZXREC.rzx_compressed_in_data
                                    DEFLATEINIT2 offset RZXREC.rzx_irb, 9, Z_DEFLATED, 15, 9, Z_DEFAULT_STRATEGY

                            .endif
                    .endif

                    invoke  WriteFile, RZXREC.RZX_FH, addr RZXREC.rzx_input_block, sizeof RZX_INPUT_RECORDING, addr BytesSaved, NULL

                    ; restore file position
                    invoke  SetFilePointer, RZXREC.RZX_FH, currfileposn, 0, FILE_BEGIN

                    ret
Write_IRB           endp


RZX_Rec_Frame           proc    uses    esi edi ebx

                        local   EI_Last_Count:  BYTE,
                                frame_extended: BYTE

                        mov     al, FrameSkipCounter
                        mov     FrameSkipLoop, al

                        .if     TapePlaying && FastTapeLoading && (RealTapeMode == FALSE)
                                mov    FrameSkipLoop, AUTOTAPEFRAMESKIP
                        .endif

                        call    UpdatePortState     ; preserves all registers

                        mov     CPU_Speed, 0        ; only allow recordings at 3.54 MHz

                        mov     frame_extended, FALSE
                        mov     EI_Last_Count,  5

RZX_Record_Frame_Init:  mov     eax, totaltstates

;--------------------------------------------------------------------------------
align 16
                        .while  (eax < MACHINE.FrameCycles) && (rzx_mode != RZX_NONE)

rzx_rec_frame_extend:           call    Exec_Opcode

                                .if     RealTapeMode == TRUE
                                        mov     al, MACHINE.REALTAPEPERIOD.CurrentCyclesPerSample
                                        .if     RealTapeTimer >= al
                                                sub     RealTapeTimer, al
                                                invoke  Get_Real_Tape_Bit
                                        .endif
                                .else
                                        ifc     TapePlaying eq TRUE then call PlayTape
                                .endif

                                ifc     SaveTapeType ne Type_NONE then call WriteTapePulse

                                IFDEF   WANTSOUND
                                .if     MuteSound == FALSE
                                        movzx   eax, [BeepVal]
                                        add     [BeeperSubTotal], eax
                                        inc     [BeeperSubCount]

                                        invoke  Sample_AY
                                .endif
                                ENDIF

                                mov     eax, totaltstates
                        .endw
;--------------------------------------------------------------------------------

                        .if     EI_Last == TRUE
                                mov     frame_extended, TRUE
                                dec     EI_Last_Count
                                jnz     rzx_rec_frame_extend
                        .endif

                        IFDEF   DEBUGBUILD
                                .if     frame_extended == TRUE
                                        ADDMESSAGE  "** RZX Recording Frame Extended **"
                                .endif
                        ENDIF

                        invoke  RZX_Write_Frame

                        ifc     currentMachine.iff1 eq TRUE then call z80_Interrupt

                        RENDERCYCLES

                        mov     eax, MACHINE.FrameCycles
                        sub     totaltstates, eax

                        .if     AutoPlayTapes == TRUE
                                .if     AutoTapeStarted == TRUE
                                        .if     (LoadTapeType == Type_TZX) && (TZXPause > 0) && (SL_AND_32_64 == TRUE)
                                        .elseif (LoadTapeType == Type_PZX) && (PZX.Pause > 0) && (SL_AND_32_64 == TRUE)
                                        .else
                                                .if    AutoTapeStopFrames == 0
                                                       mov     TapePlaying, FALSE
                                                       mov     AutoTapeStarted, FALSE
                                                .else
                                                       dec     AutoTapeStopFrames
                                                .endif
                                        .endif
                                .endif
                        .endif

                        call    InitUpdateScreen

                        inc     FramesPerSecond
                        inc     GlobalFramesCounter

                        inc     RZXREC.RZX_auto_rollback_frames

                        dec     FrameSkipLoop
                        jnz     RZX_Record_Frame_Init

                        .if     RZXREC.RZX_auto_rollback_frames >= (50 * 60 * 5)   ; 5 minutes
                                invoke  RZX_Insert_Bookmark
                                mov     RZXREC.RZX_auto_rollback_frames, 0
                        .endif

                        ret

RZX_Rec_Frame           endp


