LOCALS @@
.MODEL SMALL
.STACK 300h

;-------------------------------------------------------------
.DATA
buffer      DB 201 dup(?)
buffersize  DW 200 
FILENAME    DB "file.txt", 0
FILEHANDLE  DW ?
BYTES_READ  DW ?
LINES       DW 0

;-------------------------------------------------------------


.CODE 
FILE_OPEN   PROC
            MOV AX, 3D00H               ; Prepare for opening file for reading
            MOV DX, OFFSET FILENAME     ; Prepare file name 
            INT 21H                     ; DOS API - interrupt open file
            MOV [FILEHANDLE], AX        ; Store the file handler in FILEHANDLE variable
            RET
FILE_OPEN   ENDP

FILE_CLOSE  PROC
            MOV AX, 3e00h               ; Prepare file for closing
            MOV BX, [FILEHANDLE]        ; Move file handler to BX
            INT 21H                     ; Close the file
            RET
FILE_CLOSE  ENDP

FILE_READ   PROC
            MOV AX, 3F00h               ; Prepare for file read
            MOV BX, [FILEHANDLE]        ; Move file handle to BX
            MOV CX, buffersize
            MOV DX, OFFSET buffer       ;  
            INT 21H

            MOV [BYTES_READ], AX        ; Save how many bytes i've read
            CMP AX, 0                   
            JE @@EXIT

            MOV BX, DX
            ADD BX, BYTES_READ
            MOV BYTE PTR [BX], '$'

            @@EXIT:
            RET
FILE_READ   ENDP


PRINT_STRING    PROC
                MOV AH, 9H              ; Prepare for displaying the string
                INT 21h                 ; DOS API Interrupt
                RET
PRINT_STRING    ENDP

COUNT_NEWLINES  PROC
                MOV BL, OFFSET buffer
                MOV CX, [BYTES_READ]

		MOV AX, 10
                @@LOOP1:
		MOV DL,[BX]
                CMP DL, AL
                JE @@INCREMENT
                INC BX
                LOOP @@LOOP1
                JMP @@EXIT

                @@INCREMENT:
                INC LINES
                INC BX
                JMP @@LOOP1

                @@EXIT:
                RET
COUNT_NEWLINES  ENDP

START:      MOV AX, @DATA
            MOV DS, AX
            CALL FILE_OPEN

MAIN_LOOP:  CALL FILE_READ
            JZ EXIT
            MOV DX, OFFSET buffer
            CALL PRINT_STRING
            CALL COUNT_NEWLINES
            ADD LINES, 30h
            MOV DX, [LINES]
            MOV AH, 2
            INT 21h
            

EXIT:       CALL FILE_CLOSE
            MOV AX, 4C00H
            INT 21H
            END START

