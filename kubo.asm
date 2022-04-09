LOCALS @@
.MODEL SMALL
.STACK 300h
;TODO: What the fuck, 20 bytes a rozjebava pocitanie riadkov
;TODO: Zadanie vacsieho cisla ako 9
;TODO: Viacere subory ( extrn )
;TODO: ostrenie chyb
;TODO: dostatocna technicka dokumentacia v anglictine ( komentare )  
;TODO: PSP -help, cislo, subor, kokot
;-------------------------------------------------------------
.DATA
buffer      	DB 41 dup(?)	
buffersize  	DW 40 
FILENAME    	DB "file.txt", 0
FILEHANDLE  	DW ?
BYTES_READ  	DW ?
LINES       	DW 0			; How many new lines are counted in buffer
LINES_TO_SKIP	DW 0
COUNTER	    	DW 1
N_LINES     	DW 1
FILEPOS     	DW 0      
LINE_ROW    	DW 0
MSG	    		DB "Zadaj N: $", 13, 10
ERR_MSG_N		DB "Zadany riadok neexistuje", 13, 10, '$'
ARG_LENGTH		equ ds:[80h]
;-------------------------------------------------------------


.CODE 





NEW_LINE		MACRO
				MOV AH, 2H					; Prepare for character output
				MOV DL, 13					; Move Carriage Return to DL register
				INT 21H						; Interupt - DOS API 21H - CHARACTER STDOUT 2H
				MOV DL, 10					; Move Line Feed to DL register
				INT 21H						; Interupt - DOS API 21h - CHARACTER STDOUT 2H
				ENDM


FILE_OPEN   	PROC
            	MOV AX, 3D00H               ; Prepare for opening file for reading
            	MOV DX, OFFSET FILENAME     ; Prepare file name 
            	INT 21H                     ; DOS API - interrupt open file
            	MOV FILEHANDLE, AX        ; Store the file handler in FILEHANDLE variable
            	RET
FILE_OPEN   	ENDP


FILE_CLOSE  	PROC
            	MOV AX, 3e00h               ; Prepare file for closing
            	MOV BX, FILEHANDLE        ; Move file handler to BX
            	INT 21H                     ; Close the file
            	RET
FILE_CLOSE  	ENDP


FILE_READ   	PROC
            	MOV AX, 3F00h               ; Prepare for file read
            	MOV BX, FILEHANDLE        ; Move file handle to BX
            	MOV CX, buffersize
            	MOV DX, OFFSET buffer       ;  
            	INT 21H

            	MOV BYTES_READ, AX        ; Save how many bytes i've read
            	CMP AX, 0                   
            	JZ @@EXIT

            	MOV BX, DX
            	ADD BX, BYTES_READ
            	MOV BYTE PTR [BX], '$'

            	@@EXIT:
            	RET
FILE_READ   	ENDP


PRINT_STRING    PROC
                MOV AH, 9H              	; Prepare for displaying the string
                INT 21h                 	; DOS API Interrupt
                RET
PRINT_STRING	ENDP


COUNT_NEWLINES  PROC
            	MOV BX, OFFSET buffer
            	MOV CX, BYTES_READ	; How many characters were read

				MOV AX, 10			; Line feed ( new line )

            	@@LOOP1:

				TEST CX, CX
				JZ @@EXIT	

				MOV DL, BYTE PTR [BX]
            	CMP DL, AL
            	JE @@INCREMENT
            	INC BX
            	LOOP @@LOOP1
            	JMP @@EXIT

            	@@INCREMENT:
            	INC LINES
            	INC BX
				DEC CX
            	JMP @@LOOP1

            	@@EXIT:
            	RET
COUNT_NEWLINES  ENDP


GET_TO_LINE		PROC
            	MOV BX, OFFSET buffer
            	MOV CX, BYTES_READ

				MOV AX, LINES_TO_SKIP
				CMP AX, 0
				JZ @@FULL
				
				MOV AX, 10
            	@@LOOP1:

				TEST CX, CX
				JZ @@EXIT

				MOV DL, BYTE PTR [BX]
            	CMP DL, AL
            	JE @@INCREMENT
            	INC BX
            	LOOP @@LOOP1
            	JMP @@EXIT

            	@@INCREMENT:
				MOV SI, COUNTER	
            	CMP LINES_TO_SKIP, SI
            	JE @@SAVE_VALUE
            	INC COUNTER
            	INC BX
				DEC CX
            	JMP @@LOOP1

				@@FULL:
				MOV DX, 10
				MOV AH, 02h
				int 21h

            	@@SAVE_VALUE:
				MOV FILEPOS, BX
				XOR AX, AX			; ZF=1 aby sme vedeli ze sme dosiahli pozadovany riadok	

            	@@EXIT:
            	RET
GET_TO_LINE 	ENDP


MAIN_FUNCTION 	PROC
				MOV COUNTER, 0
				MOV LINES, 0
				@@COUNT_LOOP:			; Pocitame celkovy pocet riadkov v subore

				CALL FILE_READ
				JZ @@RESET_FILE
				CALL COUNT_NEWLINES

				JMP @@COUNT_LOOP		

				@@RESET_FILE:
				CALL FILE_CLOSE			; Skoncili sme s pocitanim riadkov
				CALL FILE_OPEN			; Ideme hladat N-ty riadok

				MOV AX, LINES
				MOV LINES_TO_SKIP, AX	; Nakopiruj Lines do Lines_to_skip

				MOV AX, N_LINES			; Nacitaj Nko do AX
				SUB LINES_TO_SKIP, AX			; Odpocitaj od celkoveho poctu riadkov Nko - kolko riadkov treba preskocit
				MOV AX, LINES_TO_SKIP
				CMP AX, 0
				JL @@ERR
				JMP @@FIND_POSITION

				@@FIND_POSITION:
				CALL FILE_READ
				; Maybe kontrola ci uz je prazdny subor	
				CALL GET_TO_LINE
				JZ @@PRINT_FROM_LINE
				INC LINE_ROW
				JMP @@FIND_POSITION
				
				@@PRINT_FROM_LINE:
				MOV DX, FILEPOS
				CALL PRINT_STRING

				@@LOOPX:
				CALL FILE_READ
				JZ @@EXIT
				MOV DX, OFFSET buffer
				CALL PRINT_STRING
				JMP @@EXIT
		
				@@ERR:
				NEW_LINE
				MOV DX, OFFSET ERR_MSG_N
				MOV AH, 9H
				INT 21H
				
				@@EXIT:
				RET
MAIN_FUNCTION	ENDP

INPUT_N_LINES	PROC

				mov dl, 10  
				mov bl, 0 


				@@SCAN_NUM:
      			mov ah, 01h     ; STDIN
      			int 21h         ; INTerrupt pre stdin
				
      			cmp al, 13      ; Check if user pressed ENTER KEY
      			je  @@SAVE_NUM  ; save the number 

      			mov ah, 0  
      			sub al, 48   ; ASCII to DECIMAL

      			mov cl, al
      			mov al, bl   ; Store the previous value in AL

      			mul dl       ; multiply the previous value with 10

      			add al, cl   ; previous value + new value ( after previous value is multiplyed with 10 )
     			mov bl, al

      			JMP @@SCAN_NUM 
				
				@@SAVE_NUM:
				MOV N_LINES, BX
				RET

INPUT_N_LINES	ENDP

START:      
				MOV AX, @DATA
        		MOV DS, AX

        		CALL FILE_OPEN

MAIN_LOOP:
	    		MOV AH, 9					; Vypis Zadaj N spravy
	    		MOV DX, OFFSET MSG
	    		INT 21H

	    		
				CALL INPUT_N_LINES
	    		CALL MAIN_FUNCTION
				CALL FILE_CLOSE
				CALL FILE_OPEN
	    		;NEW_LINE
        		JMP MAIN_LOOP

EXIT:   		    
				CALL FILE_CLOSE
        		MOV AX, 4C00H
        		INT 21H
        		END START

