
ToggleVideoRecording    PROTO
BeginDisplayRecording   PROTO
EndDisplayRecording     PROTO
RecordFrameDataFile     PROTO

.data
FrameBitmapInitColours  dd  00000000h, 000000CCh, 00CC0000h, 00CC00CCh, 0000CC00h, 0000CCCCh, 00CCCC00h, 00CCCCCCh
                        dd  00000000h, 000000FFh, 00FF0000h, 00FF00FFh, 0000FF00h, 0000FFFFh, 00FFFF00h, 00FFFFFFh

FrameImageNumber        dw  0       ; current recording frame number
RecordingFrames         db  FALSE   ; TRUE when recording frames

FrameImageFilename      db  "Frame_"

.data?
align 4
lpAppendFrameNumber     DWORD   ?

FrameBitmapFileHeader   BITMAPFILEHEADER    <>
FrameBitmapInfoHeader   BITMAPINFOHEADER    <>
FrameBitmapColours      BYTE    16*sizeof RGBQUAD   DUP(?)
FrameBitmapBits         BYTE    DIBWidth*DIBHeight  DUP(?)
FrameBitmapEndData      LABEL   BYTE                                        ; marks end of frame bitmap

FRAMEBITMAPSIZE         equ     FrameBitmapEndData-FrameBitmapFileHeader    ; sizeof frame bitmap
FRAMEBITMAPOFFSET       equ     FrameBitmapBits-FrameBitmapFileHeader       ; offset to bitmap data

FrameImagePathFilename  db      512 dup(?)

.code

ToggleVideoRecording    proc

                        .if     RecordingFrames == TRUE
                                invoke  EndDisplayRecording
                        .else
                                invoke  BeginDisplayRecording
                        .endif

                        ret

ToggleVideoRecording    endp

BeginDisplayRecording   proc    uses esi edi ecx

                        mov     [FrameImagePathFilename], 0
                        invoke  BrowseForFolder, hWnd, ADDR FrameImagePathFilename,
                                                 SADD("Browse for folder"),
                                                 SADD("Select a folder for the saving of screen images")

                        lea     edi, FrameImagePathFilename
                        mov     al, [edi]
                        or      al, al
                        jnz     @F

                        ret     ; no path specified

@@:                     inc     edi
                        mov     al, [edi]
                        or      al, al
                        jnz     @B

                        dec     edi     ; points to final character
                        mov     al, [edi]
                        cmp     al, "\"
                        je      @F
                        inc     edi
                        mov     al, "\"
                        mov     [edi], al

@@:                     inc     edi     ; points to byte after final "\" character

                        lea     esi, FrameImageFilename
                        mov     ecx, sizeof FrameImageFilename
                        rep     movsb   ; appends frame filename

                        mov     [lpAppendFrameNumber], edi  ; address to append framenumber to filename


                        ; initialise BITMAPFILEHEADER
                        ASSUME  ESI: PTR BITMAPFILEHEADER
                        lea     esi, FrameBitmapFileHeader
                        mov     [esi].bfType, "MB"
                        mov     [esi].bfSize, FRAMEBITMAPSIZE       ; size of bitmap file
                        mov     [esi].bfReserved1, 0
                        mov     [esi].bfReserved2, 0
                        mov     [esi].bfOffBits, FRAMEBITMAPOFFSET  ; offset to bitmap bits

                        ; initialise BITMAPINFOHEADER
                        ASSUME  ESI: PTR BITMAPINFOHEADER
                        lea     esi, FrameBitmapInfoHeader
                        mov     [esi].biSize, sizeof BITMAPINFOHEADER
                        mov     [esi].biWidth, DIBWidth
                        mov     [esi].biHeight, DIBHeight
                        mov     [esi].biPlanes, 1
                        mov     [esi].biBitCount, 8
                        mov     [esi].biCompression, BI_RGB
                        mov     [esi].biSizeImage, DIBWidth*DIBHeight
                        mov     [esi].biXPelsPerMeter, 0
                        mov     [esi].biYPelsPerMeter, 0
                        mov     [esi].biClrUsed, 16     ; 16 colours actually used
                        mov     [esi].biClrImportant, 16

                        ; setup 16 RGBQUAD entries
                        ASSUME  ESI: NOTHING
                        lea     esi, FrameBitmapInitColours
                        lea     edi, FrameBitmapColours
                        mov     ecx, 16
                        rep     movsd

                        mov     FrameImageNumber, 0 ; first recorded frame is frame 0
                        mov     RecordingFrames, TRUE

                        ret

                        ASSUME  ESI: NOTHING

BeginDisplayRecording   endp

RecordFrameDataFile     proc    uses esi edi ebx ecx

                        local   BmpFileHandle

                        local   textstring: TEXTSTRING,
                                pTEXTSTRING:DWORD

                        .if     FrameImageNumber == 0FFFFh
                                invoke  ShowMessageBox, hWnd, SADD("Frame limit has been exceeded. Recording has been terminated."),
                                                        ADDR szWindowName, MB_OK or MB_ICONINFORMATION

                                mov     RecordingFrames, FALSE  ; no longer recording frames
                                ret                 ; reached maximum allowed recorded frames
                        .endif

                        ; copy our frame bitmap data to the bitmap structure
                        ; Note: later try to save direct from buffer
FRAMECOLOURMODIFIER     equ     (CLR_SPECBASE Shl 24) or (CLR_SPECBASE Shl 16) or (CLR_SPECBASE Shl 8) or CLR_SPECBASE

                        mov     esi, [lpDIBBits]
                        add     esi, (DIBHeight-1)*DIBWidth ; start from bottom of our Spectrum buffer
                        lea     edi, FrameBitmapBits
                        mov     ebx, FRAMECOLOURMODIFIER

                        SETLOOP DIBHeight
                            push    esi

                            mov     ecx, DIBWidth/4
                        @@: mov     eax, [esi]
                            sub     eax, ebx
                            mov     [edi], eax
                            add     esi, 4
                            add     edi, 4
                            dec     ecx
                            jnz     @B

                            pop     esi
                            sub     esi, DIBWidth       ; move up one line
                        ENDLOOP

                        ; create our filename extension based on the frame number
                        lea     eax, textstring
                        invoke  INITTEXTSTRING, addr textstring, addr pTEXTSTRING
                        ADDTEXTDECIMAL      pTEXTSTRING, FrameImageNumber, ATD_ZEROES
                        ADDDIRECTTEXTSTRING pTEXTSTRING, ".bmp"

                        strcpy  addr textstring, [lpAppendFrameNumber]    ; append to file path/name

                        ; save our new bitmap file
                        .if     $fnc (CreateFile, offset FrameImagePathFilename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE
                                mov     BmpFileHandle, eax
                                invoke  WriteFile,  BmpFileHandle, addr FrameBitmapFileHeader, FRAMEBITMAPSIZE, addr BytesSaved, NULL
                                invoke  CloseHandle, BmpFileHandle
                        .else
                                invoke  ShowMessageBox, hWnd, SADD("Error recording frame bitmap"), addr szWindowName, MB_OK or MB_ICONINFORMATION
                                mov     RecordingFrames, FALSE  ; no longer recording frames
                        .endif

                        inc     FrameImageNumber    ; bump frame number
                        ret

RecordFrameDataFile     endp

EndDisplayRecording     proc

                        mov     RecordingFrames, FALSE  ; no longer recording frames
                        ret

EndDisplayRecording     endp
