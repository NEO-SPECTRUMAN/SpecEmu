
Open_RZX                PROTO
Open_RZX_1              PROTO   :DWORD
Close_RZX               PROTO   :DWORD,:BOOL
RZX_Close_IO_File       PROTO
Init_RZX                PROTO
RZX_Play_Frame          PROTO
RZX_Read_Frame_Data     PROTO
RZX_Read_Next_Frame_IO  PROTO
RZX_Read_Port_Byte      PROTO

Create_RZX              PROTO   :BOOL
RZX_Write_Snapshot      PROTO
RZX_Write_Input_Recording_Block PROTO
RZX_Rec_Frame           PROTO
Init_Recording_Frame    PROTO
Write_IRB               PROTO   :DWORD
RZX_Write_Port_Byte     PROTO   :BYTE
RZX_Write_Frame         PROTO
RZX_Write_Streaming_Frame   PROTO
RZX_Write_Data          PROTO   :DWORD,:DWORD
RZX_Write_Buffer        PROTO   :BYTE
PurgeRZXWriteBuffer     PROTO

RZX_BuildBlockList      PROTO   :DWORD
RZX_Add_Block_Tail      PROTO   :DWORD,:BYTE
RZX_Free_List           PROTO   :DWORD
RZX_Load_Snapshot       PROTO   :DWORD
RZX_Insert_Bookmark     PROTO
RZX_Rollback            PROTO

RZX_Finalise            PROTO   :BOOL
RZX_Finalise_Error      PROTO   :DWORD
RZX_Copy_Block          PROTO   :DWORD,:HANDLE
RZX_Finalise_Snapshots  PROTO   STDCALL, :DWORD,:DWORD,:DWORD
RZX_EnableMenuItems     PROTO

Create_Streaming_RZX    PROTO
Close_Streaming_RZX     PROTO


RZX_MAJOR               equ     0
RZX_MINOR               equ     0Dh

RZX_HEADER              STRUCT
Signature               DWORD   ?
Major                   BYTE    ?
Minor                   BYTE    ?
Flags                   DWORD   ?
RZX_HEADER              ENDS

RZX_CREATOR_INFO        STRUCT
Block_ID                BYTE    ?
Block_Length            DWORD   ?
Creator_String          BYTE    20  dup (?)
Creator_Major           WORD    ?
Creator_Minor           WORD    ?
RZX_CREATOR_INFO        ENDS

RZX_SNAPSHOT            STRUCT
Block_ID                BYTE    ?
Block_Length            DWORD   ?
Flags                   DWORD   ?
Extension               DWORD   ?   ; BYTE    4   dup (?)
Uncompressed_Length     DWORD   ?
RZX_SNAPSHOT            ENDS

RZX_INPUT_RECORDING     STRUCT
Block_ID                BYTE    ?
Block_Length            DWORD   ?
Frames_Count            DWORD   ?
Reserved                BYTE    ?
Init_TStates            DWORD   ?
Flags                   DWORD   ?
RZX_INPUT_RECORDING     ENDS

RZX_IO_RECORDING_FRAME  STRUCT
Fetch_Counter           WORD    ?
IN_Counter              WORD    ?
RZX_IO_RECORDING_FRAME  ENDS


RZX_Node                struct
Node                    ListNode    <>
block_type              BYTE        ?
file_pointer            DWORD       ?
RZX_Node                ends

.data
szRZXFilter                 db  "RZX files (*.rzx)",0,"*.rzx",0, 0

RZX_CreatorString           db  "SpecEmu            ", 0    ; ASCII_Z [20]

                            RESETENUM
                            ENUM    RZX_NONE, RZX_PLAY, RZX_RECORD
rzx_mode                    db      RZX_NONE

rzx_compressed              db      TRUE
rzx_streaming_enabled       db      FALSE

.data?
RZX_IO_FH                   HANDLE  ?   ; input recording block data file - used only for playback

RZX_IN_BUFFER_SIZE          equ     8192

TRZX                        STRUCT
BlockList                   ListHeader  <>
RZX_FH                      HANDLE      ?

RZX_auto_rollback_frames    DWORD   ?

rzx_irb_fileptr             DWORD   ?

rzx_continue                BOOL    ?   ; continuing a recording?

rzx_max_playback_frames     DWORD   ?

rzx_curr_block_num_in_file  DWORD   ?   ; current RZX block number in RZX file 

rzx_current_frame           DWORD   ?   ; current frame counter in current IRB
rzx_frame_counter           DWORD   ?   ; current frame counter in whole RZX playback file

RZXWriteBufferPosn          DWORD   ?

rzx_in_ptr                  DWORD   ?
rzx_in_len                  DWORD   ?

rzx_last_frame_in_len       DWORD   ?
rzx_last_frame_in_data      BYTE    RZX_IN_BUFFER_SIZE  dup (?)
rzx_last_frame_in_counter   WORD    ?

rzx_block_data              BYTE    256     dup (?)

rzx_input_block             RZX_INPUT_RECORDING <?>

rzx_irb                     z_stream    <>  ; IRB zlib stream

rzx_INs_expected            WORD    ?
rzx_INs_executed            WORD    ?

; ================          these two fields need to be a contiguous block for zlib compression as a single block of memory
rzx_io_recording            RZX_IO_RECORDING_FRAME  <?>
rzx_in_data                 BYTE    RZX_IN_BUFFER_SIZE  dup (?)
; ================

RZXWriteBuffer              BYTE    16384   dup (?)

rzx_compressed_in_data      BYTE    16384   dup (?)
                            BYTE    1024    dup (?)     ; safety buffer for possible overflow

rzx_in_recording_block      BYTE    ?                   ; currently playing an input recording block?

TRZX                        ENDS

.data?
align 16
RZXPLAY                     TRZX        <>
align 16
RZXREC                      TRZX        <>



.data?
rzx_flash_window_counter    BYTE    ?

RZX_SIGNATURE               equ     "!XZR" ; RZX!
RZXBLK_CREATORINFO          equ     10h
RZXBLK_SECURITYINFO         equ     20h
RZXBLK_SECURITYSIGNATURE    equ     21h
RZXBLK_SNAPSHOT             equ     30h
RZXBLK_INPUTRECORDING       equ     80h

.code

