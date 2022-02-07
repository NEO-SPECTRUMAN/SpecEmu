
.data?
align 4
cl_currarg              dword   ?
cl_argstring            db      MAX_PATH * 2 dup (?)

align 4
TaskQueueList           ListHeader  <>

TaskQueue_Node          struct
Node                    ListNode    <>
task_code               dword       ?
task_scratch1           dword       ?
task_scratch2           dword       ?
task_arg_numeric        dword       ?
task_arg_string         byte        MAX_PATH dup (?)
TaskQueue_Node          ends

.code
align 16
Handle_Command_Line proc    uses esi edi ebx

                    local   have_szFileName:    BYTE,
                            cmdline_autoload:   BYTE

                    local   tempbuffer[8]: BYTE

                  ; initialise our task queue list before we can add any queued tasks
                    invoke  NewList, addr TaskQueueList

;                    invoke  AddTaskQueue, TASK_WAIT, TASKARG_NUMERIC, SADD ("3")
;                    invoke  AddTaskQueue, TASK_EXIT, TASKARG_NONE, 0

                    mov     have_szFileName, FALSE
                    mov     cmdline_autoload, FALSE

                    mov     cl_currarg, 1

                    ; loop until cl_NextArgument returns 2 ; "no argument exists at specified arg number"
                    .while  TRUE
                            .break  .if $fnc (cl_NextArgument) == 2

                            .if     byte ptr [cl_argstring] == "-"

                                    ; command line switches
                                    invoke  szLower, addr cl_argstring         ; convert switches to lowercase

                                    switch$ addr cl_argstring
                                            case$   "-fullscreen"
                                                    mov     StartFullscreen, 1

                                            case$   "-windowed"
                                                    mov     StartFullscreen, 0

                                            case$   "-window"
                                                    mov     StartFullscreen, 0

                                            case$   "-snowcrash"
                                                    mov     SnowCrash_Enabled, TRUE

                                            case$   "-cbi95nmi"
                                                    mov     CBI95_NMI_enabled, TRUE

                                            case$   "-sna128"
                                                    mov     sna_is_128k_enabled, TRUE

                                            case$   "-z80v1"
                                                    mov     save_z80_as_v1_enabled, TRUE

                                            case$   "-autoload"
                                                    mov     cmdline_autoload, TRUE

                                            else$
                                                    ; unknown argument
                                    endsw$

                            .elseif byte ptr [cl_argstring] == "/"

                                    ; task list switch
                                    invoke  szLower, addr cl_argstring         ; convert switches to lowercase

                                    switch$ addr cl_argstring

                                            ; one exception to task list queue commands for DamienG's mem dump scripts,
                                            ; "/autoload" is allowed!
                                            case$   "/autoload"
                                                      mov     cmdline_autoload, TRUE

                                            case$   "/wait"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_WAIT_SECONDS, TASKARG_NUMERIC, addr cl_argstring
                                                    .endif

                                            case$   "/waitframes"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_WAIT_FRAMES, TASKARG_NUMERIC, addr cl_argstring
                                                    .endif

                                            case$   "/exit"
                                                    invoke  AddTaskQueue, TASK_EXIT, TASKARG_NONE, 0
                                            case$   "/quit"
                                                    invoke  AddTaskQueue, TASK_EXIT, TASKARG_NONE, 0

                                            case$   "/dump"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_DUMP, TASKARG_STRING, addr cl_argstring
                                                    .endif

                                            case$   "/debug"
                                                    invoke  AddTaskQueue, TASK_DEBUG, TASKARG_NONE, 0

                                            case$   "/savesnap"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_SAVESNAP, TASKARG_STRING, addr cl_argstring
                                                    .endif

                                            case$   "/trace"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_TRACE, TASKARG_STRING, addr cl_argstring
                                                    .endif

                                            case$   "/stoptrace"
                                                    invoke  AddTaskQueue, TASK_STOP_TRACE, TASKARG_NONE, 0
                                            case$   "/tracestop"
                                                    invoke  AddTaskQueue, TASK_STOP_TRACE, TASKARG_NONE, 0

                                            case$   "/stop"
                                                    .if     $fnc (cl_NextArgument) != 2
                                                            ; we have an argument
                                                            invoke  AddTaskQueue, TASK_RUNTO_STOP_CMD, TASKARG_STRING, addr cl_argstring
                                                    .endif

                                            else$
                                                    ; unknown task argument
                                    endsw$

                            .else
                                    strncpy addr cl_argstring, addr szFileName, sizeof szFileName
                                    mov     have_szFileName, TRUE
                            .endif
                    .endw

                    ; we reach here when all command arguments have been processed

                    .if     have_szFileName == TRUE
                            ; we have a file name to load

                            ; process the file type if "-autoload" was issued
                            .if     cmdline_autoload == TRUE

                                    .if     $fnc (szLen, addr szFileName) >= 5
                                            invoke  szRight, addr szFileName, addr tempbuffer, 4
                                            invoke  lcase,   addr tempbuffer
                                            mov     eax,     dword ptr [tempbuffer]

                                            .if     (eax == "pat.") || (eax == "klb.") || (eax == "xzt.") || (eax == "vaw.") || (eax == "wsc.") || (eax == "xzp.")
                                                    .if     $fnc (FilenameHas128K, addr szFileName) == TRUE
                                                            invoke  SwitchModel, HW_128
                                                    .else
                                                            invoke  SwitchModel, HW_48
                                                    .endif

                                                    movzx   eax, AutoloadTapes
                                                    push    eax
                                                            mov     AutoloadTapes, TRUE
                                                            invoke  InsertTape_1, addr szFileName
                                                    pop     eax
                                                    mov     AutoloadTapes, al

                                            .elseif (eax == "ksd.")
                                                    invoke  SwitchModel, HW_PLUS3
                                                    movzx   eax, AutoloadPlus3DSK
                                                    push    eax
                                                            mov     AutoloadPlus3DSK, TRUE
                                                            invoke  InsertDisk_1, addr szFileName
                                                    pop     eax
                                                    mov     AutoloadPlus3DSK, al

                                            .elseif (eax == "drt.") || (eax == "lcs.")
                                                    invoke  SwitchModel, HW_PENTAGON128
                                                    movzx   eax, AutoloadTrdosDSK
                                                    push    eax
                                                            mov     AutoloadTrdosDSK, TRUE
                                                            invoke  InsertDisk_1, addr szFileName
                                                    pop     eax
                                                    mov     AutoloadTrdosDSK, al
                                            .endif


                                    .endif
                            .endif

; "c:\Users\Damien\Downloads\specemu-autotest\SpecEmu.exe" "Wanderer 3D.dsk" /autoload /wait 3 /dump Xybots.dsk.mem
; Will not find "Wanderer 3D.dsk" in the current folder.

                            ; now load the specified commandline filename
                            invoke  ReadFileType, addr szFileName
                    .endif

                    ret

Handle_Command_Line endp

align 16
cl_NextArgument         proc

                        invoke  getcl_ex, cl_currarg, addr cl_argstring
                        inc     cl_currarg
                        ret

cl_NextArgument         endp

align 16
FilenameHas128K         proc    uses        esi ebx,
                                lpFilename: DWORD

                        local   buffer[MAX_PATH]: BYTE

                        lea     esi, buffer
                        invoke  ExtractFileName, lpFilename, esi

                        .if     $fnc (FindExtension, esi) != -1     ; if we have a file extension
                                mov     byte ptr [eax-1], 0         ; then back up 1 char and null the "." char
                        .endif

                        mov     ebx, $fnc (szLen, esi)

                        .while  ebx >= 4
                                mov     eax, [esi]
                                inc     esi
                                dec     ebx

                                .if     (eax == "k821") || (eax == "K821")
                                        return  TRUE
                                .endif
                        .endw

                        return  FALSE

FilenameHas128K         endp

align 16
FreeTaskQueue           proc    uses    esi edi

                        lea     esi, TaskQueueList

                        .while  TRUE
                                .break  .if $fnc (IsListEmpty, esi)

                                mov     edi, [esi].ListHeader.lh_Head
                                invoke  RemoveNode, edi
                                FreeMem edi
                        .endw
                        ret

FreeTaskQueue           endp

; specemu.exe some-file.dsk /autoload /wait 10s /dump some-file.mem /exit
; specemu.exe some-file.dsk -autoload /wait 10s /dump some-file.mem /exit

;TaskQueue_Node          struct
;Node                    ListNode    <>
;task_code               dword       ?
;task_scratch1           dword       ?
;task_scratch2           dword       ?
;task_arg_numeric        dword       ?
;task_arg_string         byte        MAX_PATH dup (?)
;TaskQueue_Node          ends

align 16
AddTaskQueue            proc    uses        esi ebx,
                                task_code:  DWORD,
                                arg_type:   DWORD,
                                lpargstring:DWORD

                        local   lpTranslated:DWORD

                        mov     ebx, FALSE  ; init our success/failure flag to failed

                        mov     esi, AllocMem (sizeof TaskQueue_Node)
                        ifc     esi eq 0 then return FALSE

                        ; we know esi points to a newly allocated node here
                        mov     eax, task_code
                        mov     [esi].TaskQueue_Node.task_code, eax

                        switch  arg_type
                                case    TASKARG_NONE
                                        mov     ebx, TRUE   ; success

                                case    TASKARG_NUMERIC
                                        .if     lpargstring != 0
                                                ; we have an argument
                                                strncpy lpargstring, addr [esi].TaskQueue_Node.task_arg_string[0], sizeof TaskQueue_Node.task_arg_string

                                                invoke  StringToDWord, addr [esi].TaskQueue_Node.task_arg_string[0], addr lpTranslated
                                                .if     lpTranslated == TRUE
                                                        ; store numeric argument
                                                        mov     [esi].TaskQueue_Node.task_arg_numeric, eax

                                                        mov     ebx, TRUE   ; success
                                                .endif
                                        .endif

                                case    TASKARG_STRING
                                        .if     lpargstring != 0
                                                ; we have an argument
                                                strncpy lpargstring, addr [esi].TaskQueue_Node.task_arg_string[0], sizeof TaskQueue_Node.task_arg_string

                                                mov     ebx, TRUE   ; success
                                        .endif
                        endsw

                        .if     ebx == TRUE
                                AddTail offset TaskQueueList, esi
                        .else
                                FreeMem esi
                        .endif

                        return  ebx

AddTaskQueue            endp

; these tasks run after every normal emulation frame unless the emulator is paused
; they don't run during running the debugging or RZX frame code
align 16
ExecTaskQueueTask       proc    uses esi edi ebx

                        local   restore_curdir: BOOL
                        local   tempcurdir[MAX_PATH]: BYTE

                        mov     restore_curdir, FALSE

                        lea     edi, TaskQueueList

                        .while  TRUE
                                .break  .if $fnc (IsListEmpty, edi)

                                ; we need to restore SpecEmu's initial current directory for relative command line paths to work
                                .if     restore_curdir == FALSE
                                        invoke  GetCurrentDirectory, sizeof tempcurdir, addr tempcurdir ; preserve current currdir
                                        invoke  SetCurrentDirectory, addr startup_currentdirectory      ; restore initial currdir when SpecEmu started up
                                        mov     restore_curdir, TRUE
                                .endif

                                mov     esi, [edi].ListHeader.lh_Head

                                switch  [esi].TaskQueue_Node.task_code
                                       ;====================================================================
                                        case    TASK_WAIT_SECONDS
                                                .if     [esi].TaskQueue_Node.task_arg_numeric > 0                   ; > 0 seconds delay?
                                                        mov     eax, Timer_1s_tickcount                             ; global 1 second tick counter
                                                        add     eax, [esi].TaskQueue_Node.task_arg_numeric          ; + delay in seconds
                                                        mov     [esi].TaskQueue_Node.task_scratch1, eax             ; set our target tick counter
                                                        mov     [esi].TaskQueue_Node.task_code, TASK_WAIT_SECONDS_2 ; change task code
                                                        .break                                                      ; keep task queued
                                                .endif

                                        case    TASK_WAIT_SECONDS_2
                                                mov     eax, Timer_1s_tickcount
                                                .break  .if eax <= [esi].TaskQueue_Node.task_scratch1               ; keep task queued until tick counter exceeds target count
                                       ;====================================================================
                                        case    TASK_WAIT_FRAMES
                                                .if     [esi].TaskQueue_Node.task_arg_numeric > 0                   ; > 0 frames delay?
                                                        mov     [esi].TaskQueue_Node.task_code, TASK_WAIT_FRAMES_2  ; change task code
                                                        .break                                                      ; keep task queued
                                                .endif

                                        case    TASK_WAIT_FRAMES_2
                                                dec     [esi].TaskQueue_Node.task_arg_numeric           ; dec frames counter
                                                .break  .if !ZERO?                                      ; keep task queued until frames counter expires
                                       ;====================================================================
                                        case    TASK_EXIT
                                              ; exit SpecEmu
                                                mov     BypassConfirmExit, TRUE                         ; bypass Confirm Exit dialog in this case
                                                invoke  PostMessage, hWnd, WM_CLOSE, 0, 0               ; send WM_CLOSE to main window
                                       ;====================================================================
                                        case    TASK_DUMP
                                                invoke  ExecTaskMemDump, esi
                                       ;====================================================================
                                        case    TASK_DEBUG
                                                invoke  PostMessage, hWnd, WM_KEYDOWN, VK_ESCAPE, "BRK"
                                       ;====================================================================
                                        case    TASK_SAVESNAP
                                                invoke  SaveSnapshotByExtension, addr [esi].TaskQueue_Node.task_arg_string[0]
                                       ;====================================================================
                                        case    TASK_TRACE
                                                invoke  Start_PC_Logging, addr [esi].TaskQueue_Node.task_arg_string[0]
                                       ;====================================================================
                                        case    TASK_STOP_TRACE
                                                invoke  Stop_PC_Logging
                                       ;====================================================================
                                        case    TASK_RUNTO_STOP_CMD
                                                .if     $fnc (CompileBreakpointCode, addr [esi].TaskQueue_Node.task_arg_string[0])
                                                        invoke  Set_RunTo_Condition, RUN_TO_USER_CONDITION
                                                .endif
                                       ;====================================================================

                                endsw

                                ; exiting via here frees and removes the executed task node.
                                ; .break within a handler exits the .while loop skipping this, so that task remains queued to execute again.
                                invoke  RemoveNode, esi
                                FreeMem esi
                        .endw

                        ; restore the current directory here if required
                        .if     restore_curdir == TRUE
                                invoke  SetCurrentDirectory, addr tempcurdir    ; restore current currdir on exit
                        .endif

                        ret

ExecTaskQueueTask       endp

align 16
ExecTaskMemDump         proc    uses        esi edi ebx,
                                lpTaskNode: DWORD

                        local   dump_strm_handle:   HANDLE,
                                bankssaved[8]:      DWORD

                        mov     esi, lpTaskNode

                        mov     dump_strm_handle, $fnc (CreateFileStream, addr [esi].TaskQueue_Node.task_arg_string[0], FSA_WRITE, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 16384)

                        .if     dump_strm_handle != 0
                                lea     esi, currentMachine.bank_ptrs
                                mov     al, HardwareMode
                                switch  al
                                        case    HW_16
                                                mov     ebx, 5
                                                invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384

                                        case    HW_48, HW_TC2048, HW_TK90X
                                                mov     ebx, 5
                                                invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384
                                                mov     ebx, 2
                                                invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384
                                                mov     ebx, 0
                                                invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384

                                        case    HW_128, HW_PLUS2, HW_PLUS2A, HW_PLUS3, HW_PENTAGON128
                                                memclr  addr bankssaved, sizeof bankssaved

                                                lea     edi, currentMachine.RAMREAD0

                                                ; saves up to 4 currently paged banks (will only be 4 pages if in +2A/+3 64K RAM mode)
                                                SETLOOP 4
                                                        xor     ebx, ebx
                                                        .while  ebx < 8                     ; testing 8 bank address
                                                                mov     eax, [esi+ebx*4]    ; this bank address
                                                                .if     eax == [edi]        ; = this RAMREADx address?

                                                                        ADDMESSAGEDEC   "Saved bank: ", ebx
                                                                        invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384
                                                                        mov     [bankssaved+ebx*4], TRUE

                                                                        ; skip to outer loop for next RAMREADx test
                                                                        .break
                                                                .endif
                                                                inc     ebx
                                                        .endw

                                                        add     edi, 8  ; to RAMREAD2/4/6 etc
                                                ENDLOOP

                                                ; save remaining unsaved banks in ascending order
                                                xor     ebx, ebx
                                                .while  ebx < 8
                                                        .if     [bankssaved+ebx*4] == FALSE
                                                                ADDMESSAGEDEC   "Saved bank: ", ebx
                                                                invoke  WriteFileStream, dump_strm_handle, [esi+ebx*4], 16384
                                                        .endif
                                                        inc     ebx
                                                .endw

                                endsw

                                invoke  CloseFileStream, dump_strm_handle
                                mov     dump_strm_handle, 0
                        .endif

                        ret
ExecTaskMemDump         endp




