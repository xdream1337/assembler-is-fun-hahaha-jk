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
COUNTER	    DW 0
N_LINES     DW 1
FILEPOS     DW 0      
LINE_ROW    DW 0
MSG	    DB "Zadaj N: $", 13, 10
;-------------------------------------------------------------


.CODE 

NEW_LINE	MACRO
		MOV AH, 2H			; Prepare for character output
		MOV DL, 13			; Move Carriage Return to DL register
		INT 21H				; Interupt - DOS API 21H - CHARACTER STDOUT 2H
		MOV DL, 10			; Move Line Feed to DL register
		INT 21H				; Interupt - DOS API 21h - CHARACTER STDOUT 2H
		ENDM

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

GET_TO_LINE     PROC
                MOV BL, OFFSET buffer
                MOV CX, [BYTES_READ]
		MOV [COUNTER], 0

		MOV AX, 10

                @@LOOP1:
		MOV DL,[BX]
                CMP DL, AL

                JE @@INCREMENT
                INC BX
                LOOP @@LOOP1
                JMP @@EXIT

                @@INCREMENT:
		MOV SI, [COUNTER]	
                CMP [LINES], SI
                JE @@SAVE_VALUE
                INC COUNTER
                INC BX
                JMP @@LOOP1

                @@SAVE_VALUE:
		PUSH CX
		MOV CX, BYTES_READ
		MOV FILEPOS, CX
		POP CX	
                SUB FILEPOS, CX
                MOV AX, 0
                TEST AX, AX

                @@EXIT:
                RET
GET_TO_LINE     ENDP

SEEK_TO_POS     PROC
		MOV AX, buffersize
		MUL LINE_ROW
		ADD AX, FILEPOS
                MOV DX, AX
                MOV AX, 4200H
		MOV CX, 0
                MOV BX, [FILEHANDLE]
                INT 21h
                RET
SEEK_TO_POS     ENDP


MAIN_FUNCTION 	PROC
		@@COUNT_LOOP:
		CALL FILE_READ
		JZ @@RESET_FILE
		CALL COUNT_NEWLINES
		JMP @@COUNT_LOOP

		@@RESET_FILE:
		CALL FILE_CLOSE
		CALL FILE_OPEN
		MOV AX, [N_LINES]
		SUB [LINES], AX
		JMP @@FIND_POSITION

		@@FIND_POSITION:
		CALL FILE_READ
		CALL GET_TO_LINE
		JZ @@PRINT_FROM_LINE
		INC LINE_ROW
		JMP @@FIND_POSITION
		
		@@PRINT_FROM_LINE:
		CALL SEEK_TO_POS

		@@LOOPX:
		CALL FILE_READ
		JZ @@EXIT
		MOV DX, OFFSET buffer
		CALL PRINT_STRING
		
		@@EXIT:
		RET
MAIN_FUNCTION	ENDP

START:      MOV AX, @DATA       ; Presuniem premenne data
            MOV DS, AX          ; do registra Data Segment
            CALL FILE_OPEN      ; Zavolam proceduru FILE_OPEN

MAIN_LOOP:
	    MOV AH, 9           ; Do AH vlozim 9
	    MOV DX, OFFSET MSG  ; Do DX vlozim string
	    INT 21H             ; Kroky vyssie som urobil na to, aby interrupt vypisal spravu MSG
	    MOV AH, 1           ; Vloz do AH 1 na pripravu citania z konzole
	    INT 21H             ; Citanie z konzole
	    ;NEW_LINE
	    MOV AH, 0
	    CMP AL, 13
	    JE EXIT
	    SUB AX, 30h
	    MOV N_LINES, AX  
	    CALL MAIN_FUNCTION
	    ;NEW_LINE
            JMP MAIN_LOOP

EXIT:       CALL FILE_CLOSE
            MOV AX, 4C00H
            INT 21H
            END START

