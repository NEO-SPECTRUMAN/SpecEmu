
LOG             MACRO   msg:req, cr:=<TRUE>
                LOCAL   @@msg
                IFDEF   LOGGING
                .DATA
                IF      cr eq TRUE
                        @@msg   db  msg, 13, 10
                ELSE
                        @@msg   db  msg
                ENDIF

                .CODE
                pushad
                .if     $fnc (CreateFile, SADD ("E:\SpecEmuLog.txt"), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE
                        mov     ebx, eax
                        invoke  SetFilePointer, ebx, 0, NULL, FILE_END
                        invoke  WriteFile, ebx, addr @@msg, sizeof @@msg, addr BytesSaved, NULL
                        invoke  CloseHandle, ebx
                .endif
                popad
                ENDIF
                ENDM

LOGLPSTR        MACRO   msgptr:req
                LOCAL   @@msg
                IFDEF   LOGGING
                .DATA
                @@msg   db 13, 10
                .CODE
                pushad
                mov     ebx, msgptr
                .if     $fnc (CreateFile, SADD ("E:\SpecEmuLog.txt"), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE
                        push    eax
                        invoke  SetFilePointer, eax, 0, NULL, FILE_END

                        invoke  StrLen, ebx
                        mov     edx, eax
                        pop     eax
                        push    eax
                        invoke  WriteFile, eax, ebx, edx, addr BytesSaved, NULL
                        pop     eax
                        push    eax
                        invoke  WriteFile, eax, addr @@msg, sizeof @@msg, addr BytesSaved, NULL
                        pop     eax
                        invoke  CloseHandle, eax
                .endif
                popad
                ENDIF
                ENDM

LOGHEX          MACRO   msg:req, arg:req
                LOCAL   @@msg, @@buffer1
                IFDEF   LOGGING
                .DATA?
                @@buffer1   BYTE 12 dup (?)
                .CODE
                LOG     msg, FALSE
                pushad
                mov     edx, arg
                invoke  dw2hex, edx, addr @@buffer1
                LOGLPSTR    offset @@buffer1
                popad
                ENDIF
                ENDM

LOGRECT         macro   rectname:req, lprect:req
                ifdef   LOGGING
                        pushad
                        mov     ebx, lprect
                        LOG     "Rect: ", FALSE
                        LOG     rectname, FALSE
                        LOG     ": ", TRUE
                        LOGHEX  "  .left   = ", [ebx].RECT.left
                        LOGHEX  "  .right  = ", [ebx].RECT.right
                        LOGHEX  "  .top    = ", [ebx].RECT.top
                        LOGHEX  "  .bottom = ", [ebx].RECT.bottom
                        popad
                endif
                endm

CHECKACTIVESTATE    MACRO
                    cmp     EmuThreadState, ThreadStopped
                    je      @F
                    cmp     EmuThreadState, ThreadStopping
@@:
                    ENDM

STARTBOX        MACRO
                pushad
                invoke   MessageBox, hWnd, addr debugstart, addr szDisplayName, MB_OK or MB_ICONEXCLAMATION
                popad
                ENDM

ENDBOX          MACRO
                pushad
                invoke   MessageBox, hWnd, addr debugend, addr szDisplayName, MB_OK or MB_ICONEXCLAMATION
                popad
                ENDM

STARTTICKCOUNT  MACRO
                LOCAL   @@loop
                call    GetTickCount
                mov     Time1, eax

@@loop:         call    GetTickCount
                cmp     eax, Time1
                je      @@loop
                mov     Time1, eax
                ENDM

ENDTICKCOUNT    MACRO
                call    GetTickCount
                sub     eax, Time1
                mov     TimeTook, eax
                ENDM

;PRINTSTRING     MACRO       pstring
;                LOCAL       @@pstring
;                .data
;                @@pstring   db  pstring,0
;                .code
;                lea     esi, @@pstring
;                call    PrtString
;                ENDM
;
;PRINTHEX8       MACRO   phex8
;                mov     al, phex8
;                call    PrtHex8
;                ENDM
;
;PRINTHEX16      MACRO   phex16
;                mov     ax, phex16
;                call    PrtHex16
;                ENDM
;
;PRINTHEX32      MACRO   phex32
;                mov     eax, phex32
;                call    PrtHex32
;                ENDM
;
;PRINTDEC16      MACRO   pdec16
;                mov     ax, pdec16
;                call    PrtDec16
;                ENDM
;
;PRINTDEC32      MACRO   pdec32
;                mov     eax, pdec32
;                call    PrtDec32
;                ENDM
;
;SETPAPER        MACRO   newpapercol
;                mov     al, newpapercol
;                mov     PAPERCOL, al
;                ENDM
;
;SETINK          MACRO   newinkcol
;                mov     al, newinkcol
;                mov     INKCOL, al
;                ENDM
;
;CLS             MACRO
;                call    ClearMyScreen
;                ENDM
;
;HOME            MACRO
;                call    Cursor_HOME
;                ENDM

