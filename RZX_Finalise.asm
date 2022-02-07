
.data?
temp_rzx_FH         HANDLE  ?
temp_irb_FH         HANDLE  ?

temp_rzx_file       db      MAX_PATH    dup (?)
temp_irb_file       db      MAX_PATH    dup (?)

.code
RZX_Finalise        proc    uses        ebx esi edi,
                            Finalise:   BOOL

                    local   rzx_block_ptr:  DWORD,
                            rzx_block_num:  DWORD

                    local   rzx_total_frames:    DWORD,
                            rzx_irb_counter:     DWORD,
                            rzx_destbuffer_size: DWORD,
                            rzx_compressed_len:  DWORD

                    local   rzx_snapshot_fileptr:DWORD

                    local   ofn:    OPENFILENAME

                    local   rzx_header   [sizeof RZX_HEADER]:       BYTE,
                            rzx_creator  [sizeof RZX_CREATOR_INFO]: BYTE,
                            rzx_snapshot [sizeof RZX_SNAPSHOT]:     BYTE

                    local   new_rzx_irb_header [sizeof RZX_INPUT_RECORDING]: BYTE

                    local   message      [MAX_PATH]: BYTE,
                            tempfilename [MAX_PATH]: BYTE

                    mov     temp_rzx_FH, 0
                    mov     temp_irb_FH, 0

                    memclr  addr new_rzx_irb_header, sizeof RZX_INPUT_RECORDING

                    ifc     Finalise eq TRUE then mov ebx, CTXT ("Finalise RZX") else mov ebx, CTXT ("Clean-up RZX")

                    ifc     $fnc (GetFileName, hWnd, ebx, addr szRZXFilter, addr ofn, addr RZXfilename, addr RZXExt) eq FALSE then ret

                    invoke  CreateFile, offset RZXfilename, GENERIC_READ or GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                    ifc     eax eq INVALID_HANDLE_VALUE then return FALSE
                    mov     RZXPLAY.RZX_FH, eax

                    mov     rzx_mode, RZX_PLAY  ; treat as a playback RZX so CloseRZX() can close the file

                    ; *** NOTE: we need to check here that this is a SpecEmu file before allowing clean-up or finalise operations ***
                    invoke  ReadFile, RZXPLAY.RZX_FH, addr rzx_header, sizeof RZX_HEADER, addr BytesMoved, NULL
                    lea     eax, rzx_header
                    ifc     [eax].RZX_HEADER.Signature ne RZX_SIGNATURE then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE

                    invoke  ReadFile, RZXPLAY.RZX_FH, addr rzx_creator, sizeof RZX_CREATOR_INFO, addr BytesMoved, NULL
                    lea     esi, rzx_creator.RZX_CREATOR_INFO.Creator_String
                    invoke  szCmp, esi, addr RZX_CreatorString
                    ifc     eax eq 0 then invoke Close_RZX, SADD ("SpecEmu can only clean-up or finalise its own recording files"), FALSE : return FALSE

                    ; give a final warning for finalising a recording
                    .if     Finalise == TRUE
                            lea     esi, message
                            mov     byte ptr [esi], 0
                            invoke  ExtractFileName, addr RZXfilename, addr tempfilename
                            strcat  esi, SADD ("Finalising a recording prevents further recording to this file.", 13, 13), \
                                         SADD ("Do you really want to finalise '"), \
                                         addr tempfilename, SADD ("' ?")
                            invoke  ShowMessageBox, hWnd, esi, SADD ("Warning"), MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON2
                            ifc     eax eq IDNO then invoke Close_RZX, SADD ("Finalising aborted"), FALSE : return FALSE
                    .endif

                    invoke  NewList, addr RZXPLAY.BlockList

                    invoke  RZX_BuildBlockList, addr RZXPLAY
                    ifc     eax eq FALSE then invoke Close_RZX, SADD ("Invalid RZX format"), FALSE : return FALSE

                    invoke  CreateTempFile, addr temp_rzx_file, addr temp_rzx_FH
                    ifc     eax eq FALSE then invoke RZX_Finalise_Error, SADD ("Internal Error") : return FALSE

                    invoke  CreateTempFile, addr temp_irb_file, addr temp_irb_FH
                    ifc     eax eq FALSE then invoke RZX_Finalise_Error, SADD ("Internal Error") : return FALSE


                    invoke  WriteFile, temp_rzx_FH, addr rzx_header,  sizeof RZX_HEADER,       addr BytesSaved, NULL
                    invoke  WriteFile, temp_rzx_FH, addr rzx_creator, sizeof RZX_CREATOR_INFO, addr BytesSaved, NULL

                    mov     rzx_block_ptr, offset RZXPLAY.BlockList
                    mov     rzx_block_num, 0

                    mov     rzx_total_frames, 0
                    mov     rzx_irb_counter, 0


                    .while  TRUE
                            mov     esi, rzx_block_ptr

                            mov     esi, [esi].ListNode.ln_Succ
                            .break  .if $fnc (IsListHeader, esi) == TRUE

                            mov     rzx_block_ptr, esi
                            inc     rzx_block_num

                            ; the first block has to be a snapshot block
                            .if     (rzx_block_num == 1) && ([esi].RZX_Node.block_type != RZXBLK_SNAPSHOT)
                                    invoke  RZX_Finalise_Error, SADD ("Invalid RZX format")
                                    return  FALSE
                            .endif

                            switch  [esi].RZX_Node.block_type
                                    case    RZXBLK_SNAPSHOT
                                            ; take the successor to the current block
                                            mov     edi, rzx_block_ptr
                                            mov     edi, [edi].ListNode.ln_Succ
                                            ; if the successor is the list header then this snapshot block is the last in the file
                                            mov     ebx, $fnc (IsListHeader, edi)   ; ebx = TRUE for last snapshot in the file, else FALSE

                                            ; take this snapshot into the destination file if:
                                            ; (a) this is the first snapshot in the file,
                                            ; (b) this is the last snapshot in the file and we're only doing a "clean-up" operation (Finalise == FALSE)

                                            .if     (rzx_block_num == 1) || ((ebx == TRUE) && (Finalise == FALSE))
                                                    .if     Finalise == FALSE
                                                            ; copy the snapshot block verbatim if cleaning-up
                                                            invoke  RZX_Copy_Block, rzx_block_ptr, temp_rzx_FH
                                                            ifc     eax eq FALSE then return FALSE
                                                    .else
                                                            ; if finalising, we need to strip tape/disk blocks
                                                            mov     esi, rzx_block_ptr
                                                            invoke  SetFilePointer, RZXPLAY.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                                                            invoke  ReadFile, RZXPLAY.RZX_FH, addr rzx_snapshot, sizeof RZX_SNAPSHOT, addr BytesMoved, NULL
                                                            invoke  SetFilePointer, RZXPLAY.RZX_FH, -sizeof RZX_SNAPSHOT, NULL, FILE_CURRENT

                                                            mov     ebx, rzx_snapshot.RZX_SNAPSHOT.Block_Length
                                                            mov     esi, AllocMem (ebx)
                                                            ifc     esi eq NULL then invoke RZX_Finalise_Error, SADD ("Out of memory") : return FALSE

                                                            ; read the snapshot block
                                                            invoke  ReadFile, RZXPLAY.RZX_FH, esi, ebx, addr BytesMoved, NULL

                                                            ; preserve the current file pointer and write a dummy RZX snapshot header
                                                            mov     rzx_snapshot_fileptr, $fnc (SetFilePointer, temp_rzx_FH, 0, NULL, FILE_CURRENT)
                                                            invoke  WriteFile, temp_rzx_FH, addr rzx_snapshot, sizeof (RZX_SNAPSHOT), addr BytesSaved, NULL

                                                            ; copy valid finalised SZX snapshot blocks over
                                                            lea     ecx, [esi + sizeof RZX_SNAPSHOT]    ; pointer to SZX snapshot
                                                            lea     edx, [ebx - sizeof RZX_SNAPSHOT]    ; size of SZX snapshot
                                                            invoke  LoadSZXStateFromMemory, ecx, edx, addr RZX_Finalise_Snapshots
                                                            ifc     eax eq NULL then FreeMem esi : invoke RZX_Finalise_Error, SADD ("Error in embedded SZX snapshot") : return FALSE
                                                            FreeMem esi

                                                            mov     esi, $fnc (SetFilePointer, temp_rzx_FH, 0, NULL, FILE_CURRENT)
                                                            sub     esi, rzx_snapshot_fileptr   ; = new length of snapshot block

                                                            ; update the new RZX snapshot field values
                                                            mov     rzx_snapshot.RZX_SNAPSHOT.Block_Length, esi
                                                            sub     esi, sizeof RZX_SNAPSHOT
                                                            mov     rzx_snapshot.RZX_SNAPSHOT.Uncompressed_Length, esi

                                                            ; move back to file location for the real snapshot block and write out the real data
                                                            invoke  SetFilePointer, temp_rzx_FH, rzx_snapshot_fileptr, NULL, FILE_BEGIN
                                                            invoke  WriteFile, temp_rzx_FH, addr rzx_snapshot, sizeof (RZX_SNAPSHOT), addr BytesSaved, NULL

                                                            ; then advance beyond the RZX snapshot block
                                                            invoke  SetFilePointer, temp_rzx_FH, 0, NULL, FILE_END
                                                    .endif
                                            .endif

                                    case    RZXBLK_INPUTRECORDING
                                            inc     rzx_irb_counter

                                            .if     Finalise == FALSE
                                                    ; copy the IRB verbatim to the destination RZX for a "clean-up" operation
                                                    invoke  RZX_Copy_Block, rzx_block_ptr, temp_rzx_FH
                                                    ifc     eax eq FALSE then return FALSE
                                            .else
                                                    mov     esi, rzx_block_ptr
                                                    invoke  SetFilePointer, RZXPLAY.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                                                    invoke  ReadFile, RZXPLAY.RZX_FH, addr RZXPLAY.rzx_input_block, sizeof (RZX_INPUT_RECORDING), addr BytesMoved, NULL

                                                    ; keep tab of frames counter for multiple IRB blocks
                                                    mov     eax, RZXPLAY.rzx_input_block.RZX_INPUT_RECORDING.Frames_Count
                                                    add     rzx_total_frames, eax

                                                    mov     ebx, RZXPLAY.rzx_input_block.RZX_INPUT_RECORDING.Block_Length
                                                    sub     ebx, 18                             ; ebx = size of (compressed?) data

                                                    mov     esi, AllocMem (ebx)
                                                    ifc     esi eq NULL then invoke RZX_Finalise_Error, SADD ("Out of memory") : return FALSE

                                                    ; read the recording block data
                                                    invoke  ReadFile, RZXPLAY.RZX_FH, esi, ebx, addr BytesMoved, NULL

                                                    mov     eax, RZXPLAY.rzx_input_block.RZX_INPUT_RECORDING.Flags
                                                    test    eax, 2
                                                    .if     !ZERO?
                                                            ; compressed data
                                                            invoke  ZLIB_DecompressBlockToFileHandle, esi, ebx, temp_irb_FH, 2    ; use inflateinit2_
                                                            push    eax
                                                            FreeMem esi
                                                            pop     eax
                                                            ifc     eax eq -1 then invoke RZX_Finalise_Error, SADD ("Zlib decompression error") : return FALSE
                                                    .else
                                                            invoke  WriteFile, temp_irb_FH, esi, ebx, addr BytesSaved, NULL
                                                            FreeMem esi
                                                    .endif
                                            .endif

                                    .else
                                            invoke  RZX_Finalise_Error, SADD ("Unknown RZX block type")
                                            return  FALSE
                            endsw

                    .endw


                    ; if finalising, we need to write a new IRB for the merged multiple IRB blocks within the source RZX file
                    .if     Finalise == TRUE
                            lea     esi, new_rzx_irb_header
                            mov     [esi].RZX_INPUT_RECORDING.Block_ID,     RZXBLK_INPUTRECORDING
                            m2m     [esi].RZX_INPUT_RECORDING.Frames_Count, rzx_total_frames
                            mov     [esi].RZX_INPUT_RECORDING.Flags,        2   ; compressed data

                            invoke  SetFilePointer, temp_irb_FH, 0, 0, FILE_BEGIN

                            mov     ebx, $fnc (GetFileSize, temp_irb_FH, NULL)
                            ifc     ebx eq -1  then invoke RZX_Finalise_Error, SADD ("Internal Error") : return FALSE

                            mov     esi, AllocMem (ebx)
                            ifc     esi eq NULL then invoke RZX_Finalise_Error, SADD ("Out of memory") : return FALSE

                            mov     eax, ebx
                            add     eax, (1024 * 128)
                            mov     rzx_destbuffer_size, eax

                            mov     edi, AllocMem (rzx_destbuffer_size)
                            ifc     edi eq NULL then FreeMem esi : invoke RZX_Finalise_Error, SADD ("Out of memory") : return FALSE

                            invoke  ReadFile, temp_irb_FH, esi, ebx, addr BytesMoved, NULL

                            invoke  ZLIB_CompressBlock, esi, ebx, edi, rzx_destbuffer_size
                            ifc     eax eq -1 then FreeMem esi : FreeMem edi : invoke RZX_Finalise_Error, SADD ("Zlib compression error") : return FALSE
                            mov     rzx_compressed_len, eax

                            add     eax, sizeof RZX_INPUT_RECORDING
                            mov     new_rzx_irb_header.RZX_INPUT_RECORDING.Block_Length, eax

                            invoke  WriteFile, temp_rzx_FH, addr new_rzx_irb_header, sizeof RZX_INPUT_RECORDING, addr BytesSaved, NULL

                            mov     edx, new_rzx_irb_header.RZX_INPUT_RECORDING.Block_Length
                            sub     edx, sizeof RZX_INPUT_RECORDING
                            invoke  WriteFile, temp_rzx_FH, edi, edx, addr BytesSaved, NULL

                            FreeMem esi
                            FreeMem edi
                    .endif


                    ; finally, attempt to copy the new RZX file over the original one being cleaned-up or finalised
                    invoke  CloseHandle, RZXPLAY.RZX_FH ; close the file so we can copy the new version over it

                    invoke  CopyFile, addr temp_rzx_file, addr RZXfilename, FALSE   ; replace the existing file if it exists
                    ifc     eax eq 0 then invoke RZX_Finalise_Error, SADD ("Internal Error") : return FALSE

                    ifc     Finalise eq TRUE then mov ebx, CTXT ("Finalise complete") else mov ebx, CTXT ("Clean-up complete")
                    MouseOn
                    invoke  ShowMessageBox, hWnd, ebx, SADD ("RZX Info"), MB_OK or MB_ICONINFORMATION
                    MouseOff

                    invoke  RZX_Finalise_Error, 0   ; no error

                    return  TRUE
RZX_Finalise        endp

RZX_Copy_Block      proc    uses        ebx esi edi,
                            block_ptr:  DWORD,
                            dest_FH:    HANDLE

                    local   block_temp [5]: BYTE

                    mov     esi, block_ptr
                    invoke  SetFilePointer, RZXPLAY.RZX_FH, [esi].RZX_Node.file_pointer, NULL, FILE_BEGIN
                    invoke  ReadFile, RZXPLAY.RZX_FH, addr block_temp, 5, addr BytesMoved, NULL
                    ifc     BytesMoved ne 5 then invoke RZX_Finalise_Error, SADD ("File I/O Error") : return FALSE

                    invoke  SetFilePointer, RZXPLAY.RZX_FH, -5, NULL, FILE_CURRENT

                    mov     ebx, dword ptr [block_temp+1]   ; block size
                    mov     esi, AllocMem (ebx)
                    ifc     esi eq NULL then invoke RZX_Finalise_Error, SADD ("Out of memory") : return FALSE

                    mov     edi, FALSE  ; assume file I/O error

                    invoke  ReadFile, RZXPLAY.RZX_FH, esi, ebx, addr BytesMoved, NULL
                    .if     BytesMoved == ebx
                            invoke  WriteFile, dest_FH, esi, ebx, addr BytesSaved, NULL
                            ifc     BytesSaved eq ebx then mov edi, TRUE    ; no file I/O error
                    .endif

                    invoke  GlobalFree, esi

                    ifc     edi eq TRUE then return TRUE

                    invoke  RZX_Finalise_Error, SADD ("File I/O Error")
                    return  FALSE

RZX_Copy_Block      endp

; strip tape/disk blocks from SZX snapshots when finalising
; SZX callbacks called with all registers preserved by caller
RZX_Finalise_Snapshots  proc    STDCALL,
                                lpSZXBlock: DWORD,
                                arg2:       DWORD,
                                arg3:       DWORD

                        mov     esi, lpSZXBlock

                        switch  [esi].ZXSTBLOCK.dwId
                                case    ZXSTBID_ZXSTTAPE, ZXSTBID_ZXSTDSKFILE, ZXSTBID_ZXSTBETADISK
                                        ; these blocks are simply dropped from the finalised SZX snapshot within RZX files
                                .else
                                        ; simply copy the remaining block types over
                                        invoke  SaveSZXBlockToFilehandle, temp_rzx_FH, lpSZXBlock, arg2, arg3
                                        ifc     eax eq NULL then return -1  ; return a callback error if this fails
                        endsw
                        return  0   ; return no callback error
RZX_Finalise_Snapshots  endp

RZX_Finalise_Error  proc    lpErrMsg:   DWORD

                    .if     temp_rzx_FH != 0
                            invoke  CloseHandle, temp_rzx_FH
                            invoke  DeleteFile,  addr temp_rzx_file
                            mov     temp_rzx_FH, 0
                    .endif

                    .if     temp_irb_FH != 0
                            invoke  CloseHandle, temp_irb_FH
                            invoke  DeleteFile,  addr temp_irb_file
                            mov     temp_irb_FH, 0
                    .endif

                    invoke  Close_RZX, lpErrMsg, FALSE
                    ret

RZX_Finalise_Error  endp

