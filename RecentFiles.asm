
PopulateRecentFilesMenu PROTO
LoadRecentFileList      PROTO
SaveRecentFileList      PROTO
;AddRecentFile           PROTO  ; now in SpecEmu.inc

RECENTFILEMENUID        equ     19500

MAX_RECENT_FILES        equ     10

RecentFileNode          struct
Node                    ListNode    <>
Filename                db          MAX_PATH    dup (?)
RecentFileNode          ends

.data?
align 16
RecentFileList          ListHeader  <?>

RecentFile0             BYTE    MAX_RECENT_FILES * sizeof RecentFileNode dup (?)

.data
Key_RecentFile          db  "File"
Key_RecentFileNum       db  "0", 0

.code
PopulateRecentFilesMenu proc    uses    ebx esi

                        local   Menu_ID:    DWORD

                        mov     ebx, $fnc (GetSubMenu, MenuHandle, 0)
                        invoke  GetMenuItemCount, ebx
                        sub     eax, 2
                        mov     ebx, $fnc (GetSubMenu, ebx, eax)

                        .while  TRUE
                                invoke  DeleteMenu, ebx, 0, MF_BYPOSITION
                                .break  .if eax == 0    ; delete all menu items
                        .endw

                        mov     Menu_ID, RECENTFILEMENUID   ; first menu ID

                        lea     esi, RecentFileList
                        .while  TRUE
                                mov     esi, [esi].ListNode.ln_Succ
                                .break  .if $fnc (IsListHeader, esi)

                                lea     edx, [esi].RecentFileNode.Filename
                                .break  .if byte ptr [edx] == 0

                                invoke  AppendMenu, ebx, MF_STRING, Menu_ID, edx
                                inc     Menu_ID
                        .endw

                        ret
PopulateRecentFilesMenu endp


LoadRecentFileList      proc    uses ebx esi

                        invoke  NewList, addr RecentFileList

                        lea     esi, RecentFile0
                        xor     ebx, ebx

                        .while  ebx < MAX_RECENT_FILES
                                mov     al, bl
                                add     al, "0"
                                mov     [Key_RecentFileNum], al
                                lea     edx, [esi].RecentFileNode.Filename
                                invoke  GetPrivateProfileString, addr SettingsSection, addr Key_RecentFile, addr INIDefaultPath, edx, MAX_PATH, addr INIFilename

                                AddTail offset RecentFileList, esi

                                add     esi, sizeof RecentFileNode
                                inc     ebx
                        .endw
                        ret
LoadRecentFileList      endp

SaveRecentFileList      proc    uses ebx esi

                        lea     esi, RecentFileList
                        xor     ebx, ebx

                        .while  TRUE
                                mov     esi, [esi].ListNode.ln_Succ
                                .break  .if $fnc (IsListHeader, esi)

                                mov     al, bl
                                add     al, "0"
                                mov     [Key_RecentFileNum], al
                                lea     edx, [esi].RecentFileNode.Filename
                                invoke  WritePrivateProfileString, addr SettingsSection, addr Key_RecentFile, edx,  addr INIFilename

                                inc     ebx
                        .endw
                        ret
SaveRecentFileList      endp

AddRecentFile           proc    uses        ebx esi

                        ifc     inhibit_recent_file eq TRUE then ret

                        ; see if we already have this filename in the list
                        lea     esi, RecentFileList
                        .while  TRUE
                                mov     esi, [esi].ListNode.ln_Succ
                                .break  .if $fnc (IsListHeader, esi)

                                lea     edx, [esi].RecentFileNode.Filename
                                invoke  Cmpi, edx, addr szRecentFileName
                                .if     eax == 0
                                        ; we have a match; move it to the head of the list
                                        invoke  RemoveNode, esi
                                        AddHead offset RecentFileList, esi
                                        ret
                                .endif
                        .endw

                        ; else use the last node
                        lea     esi, RecentFileList
                        mov     esi, [esi].ListNode.ln_Pred

                        strcpy  addr szRecentFileName, addr [esi].RecentFileNode.Filename
                        invoke  RemoveNode, esi
                        AddHead offset RecentFileList, esi
                        ret
AddRecentFile           endp



