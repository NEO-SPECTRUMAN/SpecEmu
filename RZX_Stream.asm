
Create_Streaming_RZX proc   uses esi

                    local   ofn:        OPENFILENAME

                    local   rzx_header   [sizeof RZX_HEADER]:       BYTE,
                            rzx_creator  [sizeof RZX_CREATOR_INFO]: BYTE

                    ifc     rzx_mode ne RZX_PLAY then ret
                    ifc     rzx_streaming_enabled eq TRUE then ret

                    m2m     RZXREC.rzx_continue, FALSE  ; we can't allow to continue a streaming RZX

                    invoke  SaveFileName, hWnd, SADD ("Stream RZX"), addr szRZXFilter, addr ofn, addr RZXfilename, addr RZXExt, 0
                    ifc     eax eq 0 then return FALSE

                    invoke  NewList, addr RZXREC.BlockList

                    invoke  AskOverwriteFile, addr RZXfilename, hWnd, addr szWindowName
                    ifc     eax eq FALSE then return FALSE

                    invoke  CreateFile, addr RZXfilename, GENERIC_READ or GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                    ifc     eax eq INVALID_HANDLE_VALUE then return FALSE
                    mov     RZXREC.RZX_FH, eax

                    strcpy  addr RZXfilename, addr szRecentFileName
                    invoke  AddRecentFile   ; add RZX file to recent files list

                    ; move to the start of the file and write a new RZX Header and Creator Info blocks
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


                    ; create the first set of snapshot and input recording blocks
                    invoke  RZX_Write_Snapshot
                    ifc     eax eq FALSE then invoke Close_RZX, SADD ("I/O file error"), FALSE : return FALSE
                    invoke  RZX_Write_Input_Recording_Block

                    mov     RZXREC.RZX_auto_rollback_frames, 0 ; initialise frames before an auto-rollback point

                    mov     rzx_streaming_enabled, TRUE
                    return  TRUE

Create_Streaming_RZX endp

Close_Streaming_RZX proc   uses esi

                    ifc     rzx_streaming_enabled eq FALSE then ret ; we weren't streaming...

                    invoke  Write_IRB, TRUE     ; write the real IRB block into the file
                    invoke  RZX_Write_Snapshot  ; end all recordings with a snapshot; allows reopening of finalised recordings :-)

                    ; truncate file to after the final snapshot; rollbacks may've left left-overs ahead of this final snapshot block
                    invoke  SetEndOfFile, RZXREC.RZX_FH

                    ifc     rzx_compressed eq TRUE then DEFLATEEND offset RZXREC.rzx_irb

                    invoke  CloseHandle, RZXREC.RZX_FH
                    mov     RZXREC.RZX_FH, 0
                    invoke  RZX_Free_List, addr RZXREC.BlockList
                    invoke  NewList,       addr RZXREC.BlockList

                    mov     rzx_streaming_enabled, FALSE

                    ret

Close_Streaming_RZX endp

RZX_Write_Streaming_Frame proc    uses    esi edi

                    invoke  RZX_Write_Data, addr RZXPLAY.rzx_io_recording, sizeof RZX_IO_RECORDING_FRAME

                    movzx   esi, RZXPLAY.rzx_io_recording.IN_Counter
                    invoke  RZX_Write_Data, addr RZXPLAY.rzx_in_data, esi

                    invoke  Init_Recording_Frame    ; prepare for next frame
                    ret

RZX_Write_Streaming_Frame endp




