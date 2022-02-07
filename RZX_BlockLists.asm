
.code
RZX_BuildBlockList  proc    uses        ebx esi,
                            lpRZXStruct:DWORD

                    local   textstring:     TEXTSTRING,
                            pTEXTSTRING:    DWORD

                    local   tempinputblock: RZX_INPUT_RECORDING

                    mov     esi, lpRZXStruct
                    assume  esi: ptr TRZX

                    mov     [esi].rzx_max_playback_frames, 0

                    .while  TRUE
                            invoke  ReadFile, [esi].RZX_FH, addr [esi].rzx_block_data, 5, addr BytesMoved, NULL
                            ifc     BytesMoved eq 0 then return TRUE                                                        ; end of RZX file
                            ifc     BytesMoved ne 5 then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE  ; invalid RZX file

                            switch  [esi].rzx_block_data, ebx
                                    case    RZXBLK_SECURITYINFO, RZXBLK_SECURITYSIGNATURE
                                            invoke  Close_RZX, SADD ("Security blocks unsupported"), FALSE
                                            return  FALSE

                                    case    RZXBLK_SNAPSHOT, RZXBLK_INPUTRECORDING
                                            ; create a new node for this block at the start of the block data
                                            invoke  SetFilePointer, [esi].RZX_FH, -5, NULL, FILE_CURRENT
                                            invoke  RZX_Add_Block_Tail, lpRZXStruct, [esi].rzx_block_data

                                            .if     ebx == RZXBLK_INPUTRECORDING
                                                    invoke  ReadFile, [esi].RZX_FH, addr tempinputblock, sizeof RZX_INPUT_RECORDING, addr BytesMoved, NULL
                                                    invoke  SetFilePointer, [esi].RZX_FH, -sizeof RZX_INPUT_RECORDING, NULL, FILE_CURRENT
                                                    mov     eax, tempinputblock.Frames_Count
                                                    add     [esi].rzx_max_playback_frames, eax
                                            .endif

                                            ; and skip forwards to the next block
                                            invoke  SetFilePointer, [esi].RZX_FH, [esi].rzx_block_data.RZX_CREATOR_INFO.Block_Length, NULL, FILE_CURRENT

                                    .else
                                            ; skip unknown RZX block type
                                            ; debug build indicates unknown RZX block type ID

                                            IFDEF   DEBUGBUILD
                                                    invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                                                    ADDDIRECTTEXTSTRING     pTEXTSTRING, "Unknown RZX block type: 0x"
                                                    ADDTEXTHEX              pTEXTSTRING, ebx
                                                    invoke  ShowMessageBox, hWnd, addr textstring, SADD ("RZX Info"), MB_OK or MB_ICONINFORMATION
                                            ENDIF

                                            ; skip forwards to next RZX block
                                            invoke  SetFilePointer, [esi].RZX_FH, -5, NULL, FILE_CURRENT
                                            invoke  SetFilePointer, [esi].RZX_FH, [esi].rzx_block_data.RZX_CREATOR_INFO.Block_Length, NULL, FILE_CURRENT
;                                            invoke  Close_RZX, SADD ("Unknown RZX block type"), FALSE
;                                            return  FALSE

                            endsw
                    .endw
                    return  TRUE    ; all OK

                    assume  esi: nothing
RZX_BuildBlockList  endp

RZX_Add_Block_Tail  proc    uses    esi,
                            lpRZXStruct:DWORD,
                            blocktype:  BYTE

                    mov     esi, AllocMem (sizeof RZX_Node)
                    ifc     esi eq 0 then return FALSE

                    mov     al, blocktype
                    mov     [esi].RZX_Node.block_type, al

                    mov     ecx, lpRZXStruct
                    invoke  SetFilePointer, [ecx].TRZX.RZX_FH, 0, NULL, FILE_CURRENT
                    mov     [esi].RZX_Node.file_pointer, eax

                    mov     ecx, lpRZXStruct
                    lea     ecx, [ecx].TRZX.BlockList
                    AddTail ecx, esi
                    ret

RZX_Add_Block_Tail  endp

RZX_Free_List       proc    uses    esi edi,
                            lpBlockList:DWORD

                    mov     esi, lpBlockList

                    .while  TRUE
                            .break  .if $fnc (IsListEmpty, esi)

                            mov     edi, [esi].ListHeader.lh_Head
                            invoke  RemoveNode, edi
                            FreeMem edi
                    .endw
                    ret
RZX_Free_List       endp

; loads a snapshot from the RZX snapshot block at the current file position
; the specified block ID must be a snapshot block else the RZX file is closed
; the file position is left immediately beyond the snapshot block

RZX_Load_Snapshot   proc    uses ebx esi edi,
                            lpRZXStruct:DWORD

                    local   fhandle:    HANDLE

                    local   oldloadsnapfilename  [MAX_PATH]: BYTE,
                            externalsnapfilename [MAX_PATH]: BYTE,
                            embeddedsnapfilename [MAX_PATH]: BYTE

                    local   tRZX_block_data[5]: BYTE

                    mov     eax, lpRZXStruct
                    mov     eax, [eax].TRZX.RZX_FH
                    mov     fhandle, eax

                    invoke  ReadFile, fhandle, addr tRZX_block_data, 5, addr BytesMoved, NULL
                    ifc     BytesMoved ne 5 then invoke Close_RZX, SADD ("Invalid RZX file"), FALSE : return FALSE    ; invalid RZX file

                    mov     ebx, tRZX_block_data.RZX_SNAPSHOT.Block_Length
                    mov     edi, AllocMem (ebx)
                    ifc     edi eq NULL then invoke Close_RZX, SADD ("Out of memory"), FALSE : return FALSE

                    invoke  SetFilePointer, fhandle, -5, NULL, FILE_CURRENT
                    invoke  ReadFile, fhandle, edi, ebx, addr BytesMoved, NULL

                    mov     eax, [edi].RZX_SNAPSHOT.Flags
                    test    eax, 1
                    .if     !ZERO?
                            ; external snapshot
                            lea     ecx, [edi + sizeof (RZX_SNAPSHOT)]      ; ecx = snapshot descriptor for external snapshot
                            add     ecx, 4                                  ; ecx = snapshot filename
                            invoke  @@CopyString, ecx, addr externalsnapfilename

                            invoke  @@CopyString, addr loadsnapfilename, addr oldloadsnapfilename   ; preserve last snapshot filename

                            mov     inhibit_recent_file, TRUE
                            invoke  LoadSnapshot_1, addr externalsnapfilename
                            mov     inhibit_recent_file, FALSE

                            invoke  @@CopyString, addr oldloadsnapfilename, addr loadsnapfilename   ; restore last snapshot filename
                    .else
                            ; embedded snapshot
                            invoke  GetTempPath, MAX_PATH, addr embeddedsnapfilename
                            invoke  szCatStr,   addr embeddedsnapfilename, SADD ("tempsnapshot.")
                            lea     ecx,        [edi].RZX_SNAPSHOT.Extension
                            invoke  szCatStr,   addr embeddedsnapfilename, ecx

                            mov     eax, [edi].RZX_SNAPSHOT.Flags
                            test    eax, 2          ; compressed snapshot?
                            .if     !ZERO?
                                    mov     esi, AllocMem ([edi].RZX_SNAPSHOT.Uncompressed_Length)
                                    ifc     esi eq NULL then FreeMem edi : invoke Close_RZX, SADD ("Out of memory"), FALSE : return FALSE

                                    lea     edx, [ebx-17]       ; 17+SL 	DWORD 	Block length
                                    lea     ecx, [edi] + sizeof (RZX_SNAPSHOT)
                                    invoke  ZLIB_DecompressBlock, ecx, edx, esi, [edi].RZX_SNAPSHOT.Uncompressed_Length
                                    ifc     eax eq -1 then FreeMem esi : FreeMem edi : invoke Close_RZX, SADD ("Zlib decompression error"), FALSE : return FALSE

                                    invoke  WriteMemoryToFile, addr embeddedsnapfilename, esi, [edi].RZX_SNAPSHOT.Uncompressed_Length
                                    FreeMem esi
                            .else
                                    lea     edx, [ebx-17]       ; 17+SL     DWORD   Block length
                                    lea     ecx, [edi] + sizeof (RZX_SNAPSHOT)
                                    invoke  WriteMemoryToFile, addr embeddedsnapfilename, ecx, edx
                            .endif

                            invoke  @@CopyString, addr loadsnapfilename, addr oldloadsnapfilename   ; preserve last snapshot filename

                            mov     inhibit_recent_file, TRUE
                            invoke  LoadSnapshot_1, addr embeddedsnapfilename
                            mov     inhibit_recent_file, FALSE

                            invoke  @@CopyString, addr oldloadsnapfilename, addr loadsnapfilename   ; restore last snapshot filename

                            invoke  DeleteFile, addr embeddedsnapfilename         ; delete the snapshot file after loading
                    .endif

                    FreeMem edi

                    ifc     Snapshot_OK eq FALSE then return FALSE

                    return  TRUE
RZX_Load_Snapshot   endp




