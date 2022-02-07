
PrintSysError       PROTO   :DWORD

Joy_Left_Press      PROTO   :PTR
Joy_Right_Press     PROTO   :PTR
Joy_Up_Press        PROTO   :PTR
Joy_Down_Press      PROTO   :PTR
Joy_Button1_Press   PROTO   :PTR

; ID1/2 defined in windows.inc
JOYSTICKID3         equ     JOYSTICKID2+1
JOYSTICKID4         equ     JOYSTICKID3+1

align 16
ResetJoystickStates proc

                    mov     Joystick1.Connected, FALSE
                    mov     Joystick2.Connected, FALSE
                    mov     Joystick3.Connected, FALSE
                    mov     Joystick4.Connected, FALSE
                    ret
ResetJoystickStates endp

align 16
GetJoystickStates   proc

                    ifc     keyboard_hasfocus eq FALSE then ret
;                    ifc     ActiveState eq FALSE then ret

                    mov     PORT_1F, 0
                    mov     PORT_37, 0

                    invoke  GetStickState, JOYSTICKID1, addr Joystick1
                    invoke  GetStickState, JOYSTICKID2, addr Joystick2
                    invoke  GetStickState, JOYSTICKID3, addr Joystick3
                    invoke  GetStickState, JOYSTICKID4, addr Joystick4
                    ret
GetJoystickStates   endp

align 16
GetStickState       proc    uses        esi,
                            joyID:      DWORD,
                            lpJoyInfo:  PTR

                    mov     esi, lpJoyInfo
                    assume  esi: ptr JOYSTICKINFO

                    mov     [esi].JoystickInfo.dwSize,  sizeof JOYINFOEX
                    m2m     [esi].JoystickInfo.dwFlags, [esi].JoyInfoEx_dwFlags

                    .if     $fnc (joyGetPosEx, joyID, addr [esi].JoystickInfo) == JOYERR_NOERROR

                            .if     [esi].Connected == FALSE
                                    ; if joystick wasn't connected during last pass then it's newly connected
                                    ; so initialise this joystick's capabilities and deadzones
                                    invoke  InitialiseJoystick, joyID, esi

                                    ; now mark this joystick as connected
                                    mov     [esi].Connected, TRUE
                            .endif

                            mov     eax, [esi].JoystickInfo.dwXpos
                            .if     eax <= [esi].LeftThreshold
                                    invoke  Joy_Left_Press, esi
                            .endif

                            mov     eax, [esi].JoystickInfo.dwXpos
                            .if     eax >= [esi].RightThreshold
                                    invoke  Joy_Right_Press, esi
                            .endif

                            mov     eax, [esi].JoystickInfo.dwYpos
                            .if     eax <= [esi].UpThreshold
                                    invoke  Joy_Up_Press, esi
                            .endif

                            mov     eax, [esi].JoystickInfo.dwYpos
                            .if     eax >= [esi].DownThreshold
                                    invoke  Joy_Down_Press, esi
                            .endif

                            test    [esi].JoystickInfo.dwButtons, JOY_BUTTON1
                            .if     !ZERO?
                                    invoke  Joy_Button1_Press, esi
                            .endif

                            switch  [esi].Joy_POV_Type
                                    case    JOY_POV4DIR
                                            switch  [esi].JoystickInfo.dwPOV
                                                    case    JOY_POVLEFT
                                                            invoke  Joy_Left_Press, esi
                                                    case    JOY_POVRIGHT
                                                            invoke  Joy_Right_Press, esi
                                                    case    JOY_POVFORWARD
                                                            invoke  Joy_Up_Press, esi
                                                    case    JOY_POVBACKWARD
                                                            invoke  Joy_Down_Press, esi
                                            endsw

                                    case    JOY_POVCTS
                            endsw

                    .else
                            mov     [esi].Connected, FALSE
                    .endif

                    ret

                    assume  esi: nothing
GetStickState       endp

align 16
Joy_Left_Press      proc    lpJoyInfo:  PTR

                    mov     eax, lpJoyInfo

                    switch  [eax].JOYSTICKINFO.Joystick_Type
                            case    JOY_SINCLAIR_1
                                    and     PORT_EF, NOT (1 shl 4)
                            case    JOY_SINCLAIR_2
                                    and     PORT_F7, NOT (1 shl 0)
                            case    JOY_CURSOR
                                    and     PORT_F7, NOT (1 shl 4)
                            case    JOY_KEMPSTON_1F
                                    or      PORT_1F, 2
                            case    JOY_KEMPSTON_37
                                    or      PORT_37, 2
                    endsw
                    ret
Joy_Left_Press      endp

align 16
Joy_Right_Press     proc    lpJoyInfo:  PTR

                    mov     eax, lpJoyInfo

                    switch  [eax].JOYSTICKINFO.Joystick_Type
                            case    JOY_SINCLAIR_1
                                    and     PORT_EF, NOT (1 shl 3)
                            case    JOY_SINCLAIR_2
                                    and     PORT_F7, NOT (1 shl 1)
                            case    JOY_CURSOR
                                    and     PORT_EF, NOT (1 shl 2)
                            case    JOY_KEMPSTON_1F
                                    or      PORT_1F, 1
                            case    JOY_KEMPSTON_37
                                    or      PORT_37, 1
                    endsw
                    ret
Joy_Right_Press     endp

align 16
Joy_Down_Press      proc    lpJoyInfo:  PTR

                    mov     eax, lpJoyInfo

                    switch  [eax].JOYSTICKINFO.Joystick_Type
                            case    JOY_SINCLAIR_1
                                    and     PORT_EF, NOT (1 shl 2)
                            case    JOY_SINCLAIR_2
                                    and     PORT_F7, NOT (1 shl 2)
                            case    JOY_CURSOR
                                    and     PORT_EF, NOT (1 shl 4)
                            case    JOY_KEMPSTON_1F
                                    or      PORT_1F, 4
                            case    JOY_KEMPSTON_37
                                    or      PORT_37, 4
                    endsw
                    ret
Joy_Down_Press      endp

align 16
Joy_Up_Press        proc    lpJoyInfo:  PTR

                    mov     eax, lpJoyInfo

                    switch  [eax].JOYSTICKINFO.Joystick_Type
                            case    JOY_SINCLAIR_1
                                    and     PORT_EF, NOT (1 shl 1)
                            case    JOY_SINCLAIR_2
                                    and     PORT_F7, NOT (1 shl 3)
                            case    JOY_CURSOR
                                    and     PORT_EF, NOT (1 shl 3)
                            case    JOY_KEMPSTON_1F
                                    or      PORT_1F, 8
                            case    JOY_KEMPSTON_37
                                    or      PORT_37, 8
                    endsw
                    ret
Joy_Up_Press        endp

align 16
Joy_Button1_Press   proc    lpJoyInfo:  PTR

                    mov     eax, lpJoyInfo

                    switch  [eax].JOYSTICKINFO.Joystick_Type
                            case    JOY_SINCLAIR_1
                                    and     PORT_EF, NOT (1 shl 0)
                            case    JOY_SINCLAIR_2
                                    and     PORT_F7, NOT (1 shl 4)
                            case    JOY_CURSOR
                                    and     PORT_EF, NOT (1 shl 0)
                            case    JOY_KEMPSTON_1F
                                    or      PORT_1F, 16
                            case    JOY_KEMPSTON_37
                                    or      PORT_37, 16
                    endsw
                    ret
Joy_Button1_Press   endp

align 16
InitialiseJoystick  proc    uses        esi,
                            joyID:      DWORD,
                            lpJoyInfo:  PTR

                    local   XCentre:    DWORD,
                            YCentre:    DWORD

                    mov     esi, lpJoyInfo
                    assume  esi: ptr JOYSTICKINFO

                    .if     $fnc (joyGetDevCaps, joyID, addr [esi].joyCaps, sizeof JOYCAPS) == JOYERR_NOERROR
                            mov     XCentre, @EVAL ([esi].joyCaps.wXmin + [esi].joyCaps.wXmax / 2)
                            mov     YCentre, @EVAL ([esi].joyCaps.wYmin + [esi].joyCaps.wYmax / 2)

                            mov     [esi].LeftThreshold,  @EVAL ([esi].joyCaps.wXmin + XCentre / 2)
                            mov     [esi].RightThreshold, @EVAL ([esi].joyCaps.wXmax + XCentre / 2)

                            mov     [esi].UpThreshold,    @EVAL ([esi].joyCaps.wYmin + YCentre / 2)
                            mov     [esi].DownThreshold,  @EVAL ([esi].joyCaps.wYmax + YCentre / 2)

                            ; the info we want returned for this joystick on joyGetPosEx()
                            mov     [esi].JoyInfoEx_dwFlags, JOY_RETURNBUTTONS or JOY_RETURNX or JOY_RETURNY

                            ; see if joystick has a POV, and what type it is
                            mov     [esi].Joy_POV_Type, JOY_POVNONE

                            test    [esi].joyCaps.wCaps, JOYCAPS_HASPOV
                            .if     !ZERO?
                                    test    [esi].joyCaps.wCaps, JOYCAPS_POVCTS
                                    .if     !ZERO?
                                            mov     [esi].Joy_POV_Type,      JOY_POVCTS
                                            or      [esi].JoyInfoEx_dwFlags, JOY_RETURNPOVCTS       ; we want continuous, one-hundredth degree units
                                    .else
                                            test    [esi].joyCaps.wCaps, JOYCAPS_POV4DIR
                                            .if     !ZERO?
                                                    mov     [esi].Joy_POV_Type,      JOY_POV4DIR
                                                    or      [esi].JoyInfoEx_dwFlags, JOY_RETURNPOV  ; we want discrete units
                                            .endif
                                    .endif
                            .endif
                    .endif

                    ret

                    assume  esi: nothing
InitialiseJoystick  endp

align 16
PrintSysError       proc    error:      DWORD

                    local   lpMsgBuf:   DWORD
                    local   tstr[32]: byte

                    invoke  FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM, NULL, error, 0, addr lpMsgBuf, 0, NULL
;                    print   lpMsgBuf
                    invoke  dwtoa, error, addr tstr
                    invoke  ShowMessageBox, hWnd, addr tstr, SADD ("blah"), MB_OK or MB_ICONWARNING
                    invoke  LocalFree, lpMsgBuf
                    ret

PrintSysError       endp

