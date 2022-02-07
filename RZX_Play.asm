

align 16
Open_RZX        proc

                local   ofn:    OPENFILENAME

                ifc     $fnc (GetFileName, hWnd, SADD ("Open RZX"), addr szRZXFilter, addr ofn, addr RZXfilename, addr RZXExt) ne 0 then invoke ReadFileType, addr RZXfilename
                ret
Open_RZX        endp

align 16
Open_RZX_1      proc    lpFilename: DWORD

                local   fileptr:    DWORD

                local   rzx_header  [sizeof RZX_HEADER]:       BYTE,
                        rzx_creator [sizeof RZX_CREATOR_INFO]: BYTE

                invoke  Close_RZX, 0, FALSE

                strncpy lpFilename, addr RZXfilename, sizeof RZXfilename

                invoke  NewList, addr RZXPLAY.BlockList

                invoke  CreateFile, addr RZXfilename, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                ifc     eax eq INVALID_HANDLE_VALUE then ret
                mov     RZXPLAY.RZX_FH, eax

                invoke  ReadFile, RZXPLAY.RZX_FH, addr rzx_header, sizeof RZX_HEADER, addr BytesMoved, NULL

                lea     eax, rzx_header
                ifc     [eax].RZX_HEADER.Signature ne RZX_SIGNATURE then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE

                ; skip the creator block ready for building the RZX block list, including any creator custom data
                invoke  ReadFile, RZXPLAY.RZX_FH, addr rzx_creator, sizeof RZX_CREATOR_INFO, addr BytesMoved, NULL

                mov     edx, rzx_creator.RZX_CREATOR_INFO.Block_Length
                sub     edx, sizeof RZX_CREATOR_INFO
                .if     edx > 0
                        ; skip any extra creator custom data
                        invoke  SetFilePointer, RZXPLAY.RZX_FH, edx, NULL, FILE_CURRENT
                .endif

                mov     fileptr, $fnc (SetFilePointer, RZXPLAY.RZX_FH, 0, NULL, FILE_CURRENT)   ; preserve file pointer to restore after building the RZX block list

                invoke  RZX_BuildBlockList, addr RZXPLAY.BlockList
                ifc     eax eq FALSE then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE

                invoke  SetFilePointer, RZXPLAY.RZX_FH, fileptr, NULL, FILE_BEGIN               ; restore file pointer

                strncpy addr RZXfilename, addr szRecentFileName, sizeof szRecentFileName
                invoke  AddRecentFile   ; add RZX file to recent files list

                mov     RZXPLAY.rzx_curr_block_num_in_file, 0

                mov     RZXPLAY.rzx_in_recording_block, FALSE

                mov     RZXPLAY.rzx_frame_counter, 0

                mov     rzx_mode, RZX_PLAY
                invoke  RZX_EnableMenuItems

                invoke  SetMenuItemText, MenuHandle, IDM_RZX_STOP, CTXT ("Stop Playback")

                ret
Open_RZX_1      endp

align 16
Close_RZX       proc    uses                ebx,
                        errorstr:           DWORD,
                        show_during_frame:  BOOL

                local   fileptr:    DWORD

                local   message   [512]: BYTE,
                        szFrame   [12]:  BYTE,
                        szFilePtr [12]:  BYTE,
                        szBlkNum  [12]:  BYTE

                invoke  SetMenuItemText, MenuHandle, IDM_RZX_STOP, CTXT ("Stop")

                mov     fileptr, 0

                .if     rzx_mode == RZX_PLAY
                        .if     RZXPLAY.RZX_FH != 0
                                mov     fileptr, $fnc (SetFilePointer, RZX_IO_FH, 0, NULL, FILE_CURRENT)   ; current file pointer to show file offset for errors

                                .if     rzx_streaming_enabled == TRUE
                                        invoke  Close_Streaming_RZX
                                .endif

                                invoke  CloseHandle, RZXPLAY.RZX_FH
                                mov     RZXPLAY.RZX_FH, 0
                        .endif

                        invoke  RZX_Free_List, addr RZXPLAY.BlockList
                        invoke  NewList,       addr RZXPLAY.BlockList
                .endif

                .if     rzx_mode == RZX_RECORD
                        .if     RZXREC.RZX_FH != 0
                                mov     fileptr, $fnc (SetFilePointer, RZX_IO_FH, 0, NULL, FILE_CURRENT)   ; current file pointer to show file offset for errors
        
                                invoke  Write_IRB, TRUE     ; write the real IRB block into the file
                                invoke  RZX_Write_Snapshot  ; end all recordings with a snapshot

                                ; truncate file to after the final snapshot; rollbacks may've left left-overs ahead of this final snapshot block
                                invoke  SetEndOfFile, RZXREC.RZX_FH

                                ifc     rzx_compressed eq TRUE then DEFLATEEND offset RZXREC.rzx_irb

                                invoke  CloseHandle, RZXREC.RZX_FH
                                mov     RZXREC.RZX_FH, 0
                        .endif

                        invoke  RZX_Free_List, addr RZXREC.BlockList
                        invoke  NewList,       addr RZXREC.BlockList
                .endif

                invoke  RZX_Close_IO_File

                call    InitPort

                mov     rzx_mode, RZX_NONE
                invoke  RZX_EnableMenuItems

                .if     errorstr != 0
                        MouseOn
                        invoke  dwtoa, RZXPLAY.rzx_frame_counter, addr szFrame
                        invoke  dw2hex, fileptr, addr szFilePtr
                        invoke  dwtoa, RZXPLAY.rzx_curr_block_num_in_file, addr szBlkNum

                        lea     ebx, message
                        mov     byte ptr [ebx], 0
                        strcat  ebx, errorstr
                        .if     show_during_frame == TRUE
                                strcat  ebx, SADD (" during frame "), addr szFrame

                                IFDEF   DEBUGBUILD
                                strcat  ebx, SADD (13, 13, "File: "), offset RZX_IO_Filename
                                strcat  ebx, SADD (13, "File offset: 0x"), addr szFilePtr
                                strcat  ebx, SADD (13, 13, "RZX block: "), addr szBlkNum
                                ENDIF
                        .endif

                        invoke  ShowMessageBox, hWnd, ebx, SADD ("RZX Error"), MB_OK or MB_ICONERROR
                        MouseOff
                .endif

                ret
Close_RZX       endp

align 16
RZX_Close_IO_File   proc
                    .if     RZX_IO_FH != 0
                            invoke  CloseHandle, RZX_IO_FH

                            IFNDEF  DEBUGBUILD
                            invoke  DeleteFile,  addr RZX_IO_Filename   ; only deleted if not running in the debug build
                            ENDIF

                            mov     RZX_IO_FH,   0
                    .endif
                    ret
RZX_Close_IO_File   endp

align 16
RZX_EnableMenuItems proc    uses    ebx esi edi

                    mov     edi, MenuHandle

                    mov     ebx, MF_GRAYED  or MF_BYCOMMAND
                    mov     esi, MF_ENABLED or MF_BYCOMMAND

                    switch  rzx_mode
                            case    RZX_NONE
                                    invoke  EnableMenuItem, edi, IDM_RZX_STOP,            ebx

                                    invoke  EnableMenuItem, edi, IDM_RZX_PLAY,            esi
                                    invoke  EnableMenuItem, edi, IDM_RZX_RECORD,          esi
                                    invoke  EnableMenuItem, edi, IDM_RZX_CONTINUE_RECORD, esi

                                    invoke  EnableMenuItem, edi, IDM_RZX_ADD_BOOKMARK,    ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_ROLLBACK,        ebx

                                    invoke  EnableMenuItem, edi, IDM_RZX_CLEANUP,         esi
                                    invoke  EnableMenuItem, edi, IDM_RZX_FINALISE,        esi

                            case    RZX_PLAY
                                    invoke  EnableMenuItem, edi, IDM_RZX_STOP,            esi

                                    invoke  EnableMenuItem, edi, IDM_RZX_PLAY,            ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_RECORD,          ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_CONTINUE_RECORD, ebx

                                    invoke  EnableMenuItem, edi, IDM_RZX_ADD_BOOKMARK,    ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_ROLLBACK,        ebx

                                    invoke  EnableMenuItem, edi, IDM_RZX_CLEANUP,         ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_FINALISE,        ebx

                            case    RZX_RECORD
                                    invoke  EnableMenuItem, edi, IDM_RZX_STOP,            esi

                                    invoke  EnableMenuItem, edi, IDM_RZX_PLAY,            ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_RECORD,          ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_CONTINUE_RECORD, ebx

                                    invoke  EnableMenuItem, edi, IDM_RZX_ADD_BOOKMARK,    esi
                                    invoke  EnableMenuItem, edi, IDM_RZX_ROLLBACK,        esi

                                    invoke  EnableMenuItem, edi, IDM_RZX_CLEANUP,         ebx
                                    invoke  EnableMenuItem, edi, IDM_RZX_FINALISE,        ebx

                    endsw
                    ret
RZX_EnableMenuItems endp

align 16
RZX_Read_Frame_Data         proc    uses    esi edi ebx

                            local   textstring: TEXTSTRING,
                                    pTEXTSTRING:DWORD

                            local   rzxlogged:  BOOL

                            mov     rzxlogged, FALSE

    RZX_ReadLoop:
                            .if     RZXPLAY.rzx_in_recording_block == TRUE

                                    inc     RZXPLAY.rzx_current_frame   ; current frame counter in IRB
                                    inc     RZXPLAY.rzx_frame_counter   ; frame counter in whole RZX file

                                    ifc     RZXPLAY.rzx_input_block.Frames_Count eq 0 then jmp RZX_NextBlock
                                    dec     RZXPLAY.rzx_input_block.Frames_Count

                                    ifc     $fnc (RZX_Read_Next_Frame_IO) eq -1 then invoke Close_RZX, SADD ("Illegal Frame IO"), TRUE : return FALSE
                                    ifc     rzx_streaming_enabled eq TRUE then invoke RZX_Write_Streaming_Frame

                                    .if     DoLogging && (rzxlogged == FALSE)
                                            mov     rzxlogged, TRUE     ; this routine can loop at RZX_ReadLoop when opening a new recording block but only log the rzx frame once per call

                                            ; frame, fetch count, input count
                                            invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING

                                            ADDCHAR pTEXTSTRING, 13, 10
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "RZX Frame: "
                                            ADDTEXTDECIMAL      pTEXTSTRING, RZXPLAY.rzx_current_frame
                                            ADDCHAR pTEXTSTRING, "."

                                            ADDCHAR pTEXTSTRING, 13, 10
                                            ADDDIRECTTEXTSTRING pTEXTSTRING, "Fetch: "
                                            movzx   ebx, RZXPLAY.rzx_io_recording.Fetch_Counter
                                            ADDTEXTDECIMAL      pTEXTSTRING, ebx

                                            ADDDIRECTTEXTSTRING pTEXTSTRING, ", IN: "
                                            movzx   ebx, RZXPLAY.rzx_io_recording.IN_Counter
                                            ADDTEXTDECIMAL      pTEXTSTRING, ebx

                                            ADDCHAR pTEXTSTRING, 13, 10

                                            mov     ecx, len (addr textstring)
                                            add     PCLog_Filesize, ecx

                                            invoke  WriteFileStream, PCLogFileStream, addr textstring, ecx
                                    .endif

                                    ; temp code
;                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
;
;                                    ADDTEXTDECIMAL      pTEXTSTRING, RZXPLAY.rzx_current_frame, ATD_SPACES
;                                    ADDDIRECTTEXTSTRING pTEXTSTRING, "    "
;                                    movzx   ebx, RZXPLAY.rzx_io_recording.Fetch_Counter
;                                    ADDTEXTDECIMAL      pTEXTSTRING, ebx, ATD_SPACES
;
;                                    movzx   ebx, RZXPLAY.rzx_io_recording.IN_Counter
;                                    ADDTEXTDECIMAL      pTEXTSTRING, ebx, ATD_SPACES
;
;                                    lea     ebx, textstring
;                                    LOGLPSTR    ebx

                                    return  TRUE
                            .endif


    RZX_NextBlock:
                mov     RZXPLAY.rzx_in_recording_block, FALSE

                .while  TRUE

                        invoke  ReadFile, RZXPLAY.RZX_FH, addr RZXPLAY.rzx_block_data, 5, addr BytesMoved, NULL

                        .if     BytesMoved == 0
                                ; we've reached the end of RZX playback without errors
                                invoke  Close_RZX, 0, FALSE
                                ifc     RZX_Display_End_Play_Dlg eq TRUE then invoke  ShowMessageBox, hWnd, SADD ("Finished RZX playback"), SADD ("RZX Info"), MB_OK or MB_ICONINFORMATION
                                return  FALSE   ; terminated
                        .endif

                        ifc     BytesMoved ne 5 then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE    ; invalid RZX file

                        inc     RZXPLAY.rzx_curr_block_num_in_file

                        switch  RZXPLAY.rzx_block_data
                                case    RZXBLK_CREATORINFO
                                        mov     eax, RZXPLAY.rzx_block_data.RZX_CREATOR_INFO.Block_Length
                                        sub     eax, 5
                                        invoke  ReadFile, RZXPLAY.RZX_FH, addr RZXPLAY.rzx_block_data, eax, addr BytesMoved, NULL

                                case    RZXBLK_SECURITYINFO
                                        invoke  Close_RZX, SADD ("Security blocks unsupported"), FALSE
                                        return  FALSE

                                case    RZXBLK_SECURITYSIGNATURE
                                        invoke  Close_RZX, SADD ("Security blocks unsupported"), FALSE
                                        return  FALSE

                                case    RZXBLK_SNAPSHOT
                                        invoke  SetFilePointer, RZXPLAY.RZX_FH, -5, NULL, FILE_CURRENT

                                        invoke  RZX_Load_Snapshot, addr RZXPLAY
                                        ifc     eax eq FALSE then return FALSE  ; the RZX is closed upon error in 'RZX_Load_Snapshot'
;    invoke  SaveSnapshotByExtension, SADD ("G:\zmanicwtf.szx")

                                        .if     rzx_streaming_enabled == TRUE
                                                invoke  Write_IRB, TRUE     ; write the real IRB block into the file
                                                invoke  RZX_Write_Snapshot  ; clone the new snapshot into the RZX stream
                                                invoke  RZX_Write_Input_Recording_Block ; start a new recording block in the stream
                                        .endif

                                case    RZXBLK_INPUTRECORDING
                                        invoke  RZX_Close_IO_File   ; closes any IO file currently open

                                        invoke  SetFilePointer, RZXPLAY.RZX_FH, -5, NULL, FILE_CURRENT
                                        invoke  ReadFile, RZXPLAY.RZX_FH, addr RZXPLAY.rzx_input_block, sizeof (RZX_INPUT_RECORDING), addr BytesMoved, NULL

                                        invoke  GetTempPath, MAX_PATH, addr RZX_IO_Filename
                                        invoke  szCatStr,   addr RZX_IO_Filename, addr szProcessID
                                        invoke  szCatStr,   addr RZX_IO_Filename, SADD ("rzxstream.bin")

                                        mov     ebx, RZXPLAY.rzx_input_block.Block_Length
                                        sub     ebx, 18                             ; ebx = size of (compressed?) data

                                        mov     esi, AllocMem (ebx)
                                        ifc     esi eq NULL then invoke Close_RZX, SADD ("Out of memory"), FALSE : return FALSE

                                        ; read the recording block data
                                        invoke  ReadFile, RZXPLAY.RZX_FH, esi, ebx, addr BytesMoved, NULL

                                        mov     eax, RZXPLAY.rzx_input_block.Flags
                                        test    eax, 2
                                        .if     !ZERO?
                                                ; compressed data
                                                invoke  ZLIB_DecompressBlockToFile, esi, ebx, addr RZX_IO_Filename, 2    ; use inflateinit2_
                                                push    eax
                                                FreeMem esi
                                                pop     eax
                                                ifc     eax eq -1 then invoke Close_RZX, SADD ("Zlib decompression error"), FALSE : return FALSE
                                        .else
                                                invoke  CreateFile, addr RZX_IO_Filename,
                                                                    GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL,
                                                                    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                                                ifc     eax eq INVALID_HANDLE_VALUE then FreeMem esi : invoke Close_RZX, SADD ("I/O file error"), FALSE : return FALSE
                                                mov     edi, eax
                                                invoke  WriteFile, edi, esi, ebx, addr BytesSaved, NULL
                                                invoke  CloseHandle, edi
                                                FreeMem esi
                                        .endif

;    RZX_SHOW_IO_FILENAME = 1
                                        ifdef   DEBUGBUILD
                                                ifdef   RZX_SHOW_IO_FILENAME
                                                        invoke  ShowMessageBox, hWnd, addr RZX_IO_Filename, addr szWindowName, MB_OK or MB_ICONINFORMATION
                                                endif
                                        endif

                                        ; now reopen this recording block file
                                        invoke  CreateFile, addr RZX_IO_Filename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL,
                                                                                  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                                        ifc     eax eq INVALID_HANDLE_VALUE then invoke Close_RZX, SADD ("I/O file error"), FALSE : return FALSE
                                        mov     RZX_IO_FH, eax

                                        m2m     totaltstates, RZXPLAY.rzx_input_block.Init_TStates
                                        mov     RZXPLAY.rzx_current_frame, 0
                                        mov     RZXPLAY.rzx_in_recording_block, TRUE
                                        jmp     RZX_ReadLoop

                                .else
                                        ; skip unknown RZX block type
                                        invoke  SetFilePointer, RZXPLAY.RZX_FH, -5, NULL, FILE_CURRENT
                                        invoke  SetFilePointer, RZXPLAY.RZX_FH, RZXPLAY.rzx_block_data.RZX_CREATOR_INFO.Block_Length, NULL, FILE_CURRENT

;                                        invoke  Close_RZX, SADD ("Unknown RZX block type"), FALSE
;                                        return  FALSE

                        endsw

                .endw

                return  TRUE    ; all OK

RZX_Read_Frame_Data endp

align 16
RZX_Read_Next_Frame_IO      proc    uses ebx

                            invoke  ReadFile, RZX_IO_FH, addr RZXPLAY.rzx_io_recording, sizeof RZX_IO_RECORDING_FRAME, addr BytesMoved, NULL
                            ifc     BytesMoved ne sizeof RZX_IO_RECORDING_FRAME then return -1

                            mov     RZXPLAY.rzx_in_ptr, offset RZXPLAY.rzx_in_data

                            mov     ax, RZXPLAY.rzx_io_recording.IN_Counter
                            .if     ax == 65535
                                    ; repeating frame
                                    ifc     RZXPLAY.rzx_current_frame eq 1 then return -1   ; repeating frame on frame 1?!

                                    mov     ax, RZXPLAY.rzx_last_frame_in_counter
                                    mov     RZXPLAY.rzx_io_recording.IN_Counter, ax
                                    return  TRUE
                            .endif

                            mov     RZXPLAY.rzx_last_frame_in_counter, ax

                            ifc     ax == 0 then return TRUE

                            movzx   ebx, ax ; number of port read values
                            invoke  ReadFile, RZX_IO_FH, addr RZXPLAY.rzx_in_data, ebx, addr BytesMoved, NULL
                            ifc     ebx ne BytesMoved then return -1
            
                            return  TRUE

RZX_Read_Next_Frame_IO      endp

align 16
RZX_Read_Port_Byte          proc

                            inc     RZXPLAY.rzx_INs_executed

                            .if     RZXPLAY.rzx_io_recording.IN_Counter == 0
                                    return  -1
                            .endif
                            dec     RZXPLAY.rzx_io_recording.IN_Counter

                            mov     eax, RZXPLAY.rzx_in_ptr
                            movzx   eax, byte ptr [eax]
                            inc     RZXPLAY.rzx_in_ptr
                            ret

RZX_Read_Port_Byte          endp

align 16
RZX_Play_Frame              proc    uses    esi edi ebx

                            local   message  [1024]: BYTE,
                                    fetchmod [12]:   BYTE,
                                    pcmod    [12]:   BYTE

                            mov     al, FrameSkipCounter
                            mov     FrameSkipLoop, al

                            .if     FULLSPEEDMODE == TRUE
                                    mov FrameSkipLoop, FULLSPEEDFRAMECOUNT
                            .endif

;                            call    UpdatePortState     ; preserves all registers

RZX_Play_Frame_Init:
                            .if     $fnc (RZX_Read_Frame_Data) == FALSE
                                    mov     rzx_mode, RZX_NONE
                                    ret     ; error reading frame data/next RZX block/unsupported block type
                            .endif

                            mov     ax, RZXPLAY.rzx_io_recording.IN_Counter
                            mov     RZXPLAY.rzx_INs_expected, ax

                            mov     RZXPLAY.rzx_INs_executed, 0

                            mov     totaltstates, 0

    ;--------------------------------------------------------------------------------

align 16
                            .while  rzx_mode != RZX_NONE

                                    test    RZXPLAY.rzx_io_recording.Fetch_Counter, -1
                                    .break .if ZERO?

                                    .if     SIGN?
                                            .if     RZXPLAY.rzx_io_recording.Fetch_Counter == -1    ; FIXME: allow this? (seems to fix Stormbringer 128K recording)
                                                    IFDEF   DEBUGBUILD
                                                            invoke  ShowMessageBox, hWnd, SADD ("Fetch counter = -1"), SADD ("RZX Warning"), MB_OK or MB_ICONWARNING
                                                    ENDIF
                                                    .break
                                            .endif

                                            invoke  Close_RZX, SADD ("Fetch counter overflow"), TRUE

                                            IFDEF   DEBUGBUILD
                                                    ifc     EmuRunning eq TRUE then invoke PauseResumeEmulation ; debug build pauses on IN count errors
                                            ENDIF
                                            .break
                                    .endif

                                    mov     eax, MACHINE.FrameCycles
                                    .if     eax <= totaltstates
                                            mov     totaltstates, eax
                                    .endif

                                    IFDEF   DEBUGBUILD
                                            mov     ax, RZXPLAY.rzx_io_recording.Fetch_Counter
                                            push    eax
                                            call    Exec_Opcode
                                            pop     eax
                                            mov     bx, RZXPLAY.rzx_io_recording.Fetch_Counter  ; gets decremented during execution
                                            sub     ax, bx
                                            .if     (ax != 1) && (ax != 2)
                                                    movzx   ebx, ax
                                                    invoke  dw2hex, ebx, addr fetchmod

                                                    movzx   ecx, zPC
                                                    invoke  dw2hex, ecx, addr pcmod

                                                    lea     esi, message
                                                    mov     byte ptr [esi], 0
                                                    strcat  esi, SADD ("Illegal fetch counter modification during opcode execution"), SADD (13, 13)
                                                    strcat  esi, SADD ("Modified by: 0x"), addr fetchmod, SADD (13, 13)
                                                    strcat  esi, SADD ("PC: 0x"), addr pcmod

                                                    invoke  Close_RZX, addr message, TRUE
                                                    ifc     EmuRunning eq TRUE then invoke PauseResumeEmulation ; debug build pauses on IN count errors
                                                    .break
                                            .endif
                                    ELSE
                                            call    Exec_Opcode
                                    ENDIF

                                    .if     SaveTapeType != Type_NONE
                                            call    WriteTapePulse
                                    .endif

                                    IFDEF   WANTSOUND
                                    .if     MuteSound == FALSE
                                            movzx   eax, [BeepVal]
                                            add     [BeeperSubTotal], eax
                                            inc     [BeeperSubCount]

                                            invoke  Sample_AY
                                    .endif
                                    ENDIF

                            .endw
    ;--------------------------------------------------------------------------------

;                            IFDEF   DEBUGBUILD
;                                    .if RZXPLAY.rzx_frame_counter < 9
;                                        mov     eax, RZXPLAY.rzx_frame_counter
;                                        dec     eax
;                                        ADDMESSAGEDEC   "Frame : ", eax
;                                        movzx   eax, RZXPLAY.rzx_INs_expected
;                                        ADDMESSAGEDEC   "INs expected: ", eax
;                                        movzx   eax, RZXPLAY.rzx_INs_executed
;                                        ADDMESSAGEDEC   "INs executed: ", eax
;                                    .endif
;                            ENDIF

                            mov     ax, RZXPLAY.rzx_INs_executed
                            .if     ax != RZXPLAY.rzx_INs_expected

                                    IFDEF   DEBUGBUILD
                                    ifc     EmuRunning eq TRUE then invoke PauseResumeEmulation ; debug build pauses on IN count errors
                                    ENDIF

                                    movzx   ecx, RZXPLAY.rzx_INs_expected
                                    invoke  dw2a, ecx, addr fetchmod

                                    movzx   ecx, RZXPLAY.rzx_INs_executed
                                    invoke  dw2a, ecx, addr pcmod

                                    lea     esi, message
                                    mov     byte ptr [esi], 0
                                    strcat  esi, SADD ("Incorrect IN count", 13, 13)
                                    strcat  esi, SADD ("Expected: "), addr fetchmod, SADD (", executed: "), addr pcmod

                                    invoke  Close_RZX, addr message, TRUE
                            .endif

                            mov     eax, MACHINE.FrameCycles
                            mov     totaltstates, eax

                            RENDERCYCLES

                            .if     currentMachine.iff1
                                    call    z80_Interrupt
                            .endif

                            call    InitUpdateScreen

                            inc     FramesPerSecond
                            inc     GlobalFramesCounter

                            dec     FrameSkipLoop
                            jnz     RZX_Play_Frame_Init

                            ret
RZX_Play_Frame              endp


