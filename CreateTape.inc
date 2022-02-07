
ifndef  createtapeinc_i
        createtapeinc_i = 1

.data

  ; File C:\RadASM\Masm\Projects\SpecEmu\Mastering\main.bin opened at 582 bytes

Tape_BASIC      db 243,33,237,176,34,199,92,33,24,24,34,201,92,96,105,17
                db 203,92,1,200,2,195,199,92,33,18,95,126,183,40,23,1
                db 253,127,33,0,192,17,17,16,175,237,81,119,61,237,89,119
                db 60,237,81,190,32,28,175,205,66,93,33,152,93,205,51,93
                db 33,237,176,34,62,91,33,51,94,17,64,91,1,96,1,195
                db 62,91,251,62,56,205,66,93,33,80,93,205,51,93,33,8
                db 92,175,119,118,190,40,252,199,229,62,2,205,1,22,225,126
                db 254,255,200,215,35,24,248,50,141,92,31,31,31,230,7,205
                db 155,34,195,107,13,22,8,6,84,104,105,115,32,103,97,109
                db 101,32,114,101,113,117,105,114,101,115,32,97,22,10,8,18
                db 1,49,50,56,75,32,90,88,32,83,112,101,99,116,114,117
                db 109,18,0,22,13,5,80,114,101,115,115,32,97,110,121,32
                db 107,101,121,32,116,111,32,114,101,115,101,116,255,17,0,16
                db 5,22,7,3,84,104,105,115,32,108,111,97,100,105,110,103
                db 32,115,111,102,116,119,97,114,101,32,117,115,101,115,22,8
                db 6,90,88,55,32,98,121,32,69,105,110,97,114,32,83,97
                db 117,107,97,115,46,22,10,2,90,88,55,32,105,115,32,97
                db 110,32,111,112,116,105,109,97,108,32,76,90,55,55,47,76
                db 90,83,83,22,11,4,100,97,116,97,32,99,111,109,112,114
                db 101,115,115,111,114,32,102,111,114,32,97,108,108,22,12,4
                db 112,108,97,116,102,111,114,109,115,44,32,105,110,99,108,117
                db 100,105,110,103,32,116,104,101,22,13,10,90,88,32,83,112
                db 101,99,116,114,117,109,46,255,49,64,91,33,88,92,1,8
                db 0,9,34,68,91,126,35,78,35,70,35,94,35,86,35,254
                db 255,40,73,203,127,40,20,203,191,205,209,91,126,33,0,192
                db 17,1,192,1,255,63,119,237,176,24,208,213,197,229,197,221
                db 225,205,209,91,205,198,91,225,126,35,209,193,183,40,14,229
                db 213,235,95,123,174,119,237,161,234,139,91,209,225,78,35,70
                db 120,177,40,167,235,80,89,205,217,91,24,159,217,62,16,205
                db 209,91,33,32,92,17,192,255,1,64,0,237,176,58,30,92
                db 95,230,223,246,16,205,209,91,123,217,235,249,197,201,205,250
                db 5,159,8,205,98,5,216,207,26,197,1,253,127,237,121,193
                db 201,62,128,237,160,205,24,92,48,249,213,1,0,0,80,20
                db 205,24,92,48,250,212,24,92,203,17,203,16,56,31,21,32
                db 244,3,94,35,203,51,48,12,22,16,205,24,92,203,18,48
                db 249,20,203,58,203,27,227,229,237,82,209,237,176,225,48,197
                db 135,192,126,35,23,201

Tape_BASIC_end  label   byte
Tape_BASIC_size equ     Tape_BASIC_end-Tape_BASIC


                ; enters from BASIC loader with ints disabled, correct RAM paged in and correct SP set
Tape_Stack_Code db  0F5h        ;push af (correct 7FFD paging byte)

                db  221, 33     ;ld ix,23296
                dw  23296

                db  17          ;ld de,23808-23296
                dw  23808-23296

                db  205         ;call #05FA; signal MIC off ready for tape loading, always sets Carry on return
                dw  05FAh
                db  9Fh         ;sbc a,a; A = 255 for data block, Carry set for LOAD (clear for Verify), Zero clear for needing flag byte
                db  8           ;ex af,af'
                db  205         ;call #0562
                dw  0562h

                db  0D2h        ;jp nc,#0806
                dw  0806h       ;rst 8, tape loading error

                db  0F1h        ;pop af
                db  1           ;ld bc,#7FFD
                dw  7FFDh
                db  0EDh, 79h   ;out (c),a, set correct 128K paging mode

                ; restore AY registers
                db  33          ;ld hl,AYregs
Tape_Stack_AY   dw  0
                db  17          ;ld de,#1000
                dw  1000h
                db  1           ;loop: ld bc,#fffd
                dw  0FFFDh
                db  0EDh, 59h   ;out (c),e
                db  1Ch         ;inc e
                db  6,0C0h      ;ld b,#bf+1
                db  0EDh,0A3h   ;outi
                db  15h         ;dec d
                db  20h, 0F3h   ;jr nz,loop

                db  42h         ;ld b,d (b=ff+1)
                db  0EDh,0A3h   ;outi

                ; restore Z80 registers and run game
                db  49          ;LD SP,nnnn
Tape_Stack_SP   dw  0

                db  0F1h        ;pop af
                db  211, 254    ;out (254),a

                db  0FDh, 0E1h  ;pop iy
                db  0DDh, 0E1h  ;pop ix

                db  0E1h        ;pop hl
                db  0D1h        ;pop de
                db  0C1h        ;pop bc
                db  0F1h        ;pop af
                db  0D9h        ;exx
                db  8           ;ex af,af'

                db  0E1h        ;pop hl
                db  0D1h        ;pop de
                db  0C1h        ;pop bc

                db  0F1h        ;pop af
                db  0EDh, 047h  ;ld i,a
                db  0F1h        ;pop af
                db  0EDh, 04Fh  ;ld r,a; R will be adjusted correctly during stack code creation

                db  0F1h        ;pop af

                db  0EDh        ;IM0/1/2
Tape_Stack_IM   db  0           ;46h = IM0, 56h = IM1, 5Eh = IM2

Tape_Stack_INTS db  0           ; DI/EI

                db  0C9h        ; RET (to game)

Tape_Stack_end  label   byte
Tape_Stack_size equ     Tape_Stack_end-Tape_Stack_Code


.code

endif


