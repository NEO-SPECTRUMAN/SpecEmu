
JOYSTICKINFO        STRUCT
Connected           BOOL        ?
JoystickInfo        JOYINFOEX   <>
joyCaps             JOYCAPS     <>

JoyInfoEx_dwFlags   DWORD       ?

LeftThreshold       DWORD       ?
RightThreshold      DWORD       ?
UpThreshold         DWORD       ?
DownThreshold       DWORD       ?

Joystick_Type       BYTE        ?
Joy_POV_Type        BYTE        ?
_pad_               BYTE        2   dup (?)
JOYSTICKINFO        ENDS


PreloadJoystickComboItems     db    "Not connected", 0
                              db    "Sinclair 1", 0
                              db    "Sinclair 2", 0
                              db    "Cursor", 0
                              db    "Kempston (port 31)", 0
                              db    "Kempston (port 55)", 0
                              db    0

                    RESETENUM   0
                    ENUM        JOY_NOTHING, JOY_SINCLAIR_1, JOY_SINCLAIR_2, JOY_CURSOR, JOY_KEMPSTON_1F, JOY_KEMPSTON_37
                    ENUM        JOY_END

                    RESETENUM
                    ENUM        JOY_POVNONE, JOY_POV4DIR, JOY_POVCTS

JOYCAPS_HASPOV      equ     10h
JOYCAPS_POV4DIR     equ     20h
JOYCAPS_POVCTS      equ     40h

.data?
align 4
Joystick1           JOYSTICKINFO    <?>
Joystick2           JOYSTICKINFO    <?>
Joystick3           JOYSTICKINFO    <?>
Joystick4           JOYSTICKINFO    <?>

.data

.code

