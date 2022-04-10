LOCALS @@
.MODEL SMALL
.STACK 300h
.386
;TODO: What the fuck, 20 bytes a rozjebava pocitanie riadkov
;TODO: Zadanie vacsieho cisla ako 9 - DONE :-)
;TODO: Viacere subory ( extrn )
;TODO: ostrenie chyb
;TODO: dostatocna technicka dokumentacia v anglictine ( komentare )  
;TODO: PSP -help, cislo, subor, kokot
;-------------------------------------------------------------
.DATA
buffer      	DB 41 dup(?)	
buffersize  	DW 40 
FILENAME    	DB 128 dup(0)
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
ERR_NOT_FOUND   DB "Vyskytla sa chyba so suborom, ukoncujem program!", 13, 10, '$'
ARG_LENGTH		DB 0
CMD_BUFFER		DB 128 dup('$')
HELP			DB 0
FILENAME_CMD	DB 0
N_LINES_CMD		DB 0
HELP_MSG		DB "help??? chod do pixi", 13, 10, '$'
FILE_MISS_MSG   DB "Filename is missing, terminating the program!", 13, 10, '$'
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
            	MOV AX, 3D00H              		; Prepare for opening file for reading
            	MOV DX, OFFSET FILENAME     	; Prepare file name 
            	INT 21H                     	; DOS API - interrupt open file

				JC @@FILE_ERROR					; Jump if there is problem with file

				@@SAVE_FILENAME:
            	MOV FILEHANDLE, AX        		; Store the file handler in FILEHANDLE variable
            	RET

				@@FILE_ERROR:
				NEW_LINE						; Print new line
				MOV DX, OFFSET ERR_NOT_FOUND	; Move error msg string to DX
				MOV AH, 9H						; Set AH to 9H to print error message
				INT 21H							; Interrupt to print the message
				MOV AX, 4C00H					; Save 4C00H to terminate program
        		INT 21H							; Terminate the program
				RET
FILE_OPEN   	ENDP


FILE_CLOSE  	PROC
            	MOV AX, 3e00h               ; Prepare file for closing
            	MOV BX, FILEHANDLE        	; Move file handler to BX
            	INT 21H                    	; Close the file
            	RET
FILE_CLOSE  	ENDP


FILE_READ   	PROC
            	MOV AX, 3F00h               ; Prepare for file read
            	MOV BX, FILEHANDLE        	; Move file handle to BX
            	MOV CX, buffersize
            	MOV DX, OFFSET buffer       ;  
            	INT 21H

            	MOV BYTES_READ, AX        	; Save how many bytes i've read
            	CMP AX, 0    				; If no bytes were read jump to exit               
            	JZ @@EXIT					; Jump to exit

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
            	MOV CX, BYTES_READ			; How many characters were read

				MOV AX, 10					; Line feed ( new line )

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
				JL @@FULL
				
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

				@@FULL:					; Print all lines
				MOV DX, 10				; Set the cursor position to row 1 and column 0
				MOV AH, 02h			
				int 21h

            	@@SAVE_VALUE:
				MOV FILEPOS, BX			; Save the cursor position
				XOR AX, AX				; ZF=1 aby sme vedeli ze sme dosiahli pozadovany riadok	

            	@@EXIT:
            	RET
GET_TO_LINE 	ENDP


MAIN_FUNCTION 	PROC
				MOV COUNTER, 0
				MOV LINES, 0

				@@COUNT_NEWLINES_LOOP:		; Get number of newlines in file
				CALL FILE_READ				; Read the file
				JZ @@RESET_FILE				; We read the whole file, jump to reset file
				CALL COUNT_NEWLINES			; Count newlines in current buffer
				JMP @@COUNT_NEWLINES_LOOP	; Read another 200 characters

				@@RESET_FILE:
				CALL FILE_CLOSE				; We ended counting new lines, let's find Nth last line
				CALL FILE_OPEN				; Ideme hladat N-ty riadok

				MOV AX, LINES
				MOV LINES_TO_SKIP, AX		; Nakopiruj Lines do Lines_to_skip

				MOV AX, N_LINES				; Load N_LINES to AX
				SUB LINES_TO_SKIP, AX		; LINES_TO_SKIP (LINES) - N_LINES - calculate how many lines to skip
				MOV AX, LINES_TO_SKIP		; Move LINES_TO_SKIP to AX
				CMP AX, 0					; Check if line exists
				JL @@ERR					; Line does not exist
				JMP @@FIND_POSITION			; Find position of the line

				@@FIND_POSITION:
				CALL FILE_READ
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

				XOR DX, DX
				XOR BX, BX
				XOR CX, CX
				XOR AX, AX

				MOV DL, 10  
				MOV BL, 0 

				@@SCAN_NUM:
      			MOV AH, 01h     	; STDIN
      			INT 21h         	; INTerrupt pre stdin
				
      			CMP AL, 13      	; Check if user pressed ENTER KEY
      			JE  @@SAVE_NUM  	; save the number 

      			MOV AH, 0  
      			SUB AL, 48   		; ASCII to DECIMAL

      			MOV CL, AL
      			MOV AL, BL  		; Store the previous value in AL

      			MUL DL       		; Multiply the previous value with 10

      			ADD AL, CL   		; Previous value + new value ( after previous value is multiplyed with 10 )
     			MOV BL, AL			; Store the value to BL

      			JMP @@SCAN_NUM 		; Scan another digit
				
				@@SAVE_NUM:
				MOV N_LINES, BX		; Save the number to N_LINES
				RET

INPUT_N_LINES	ENDP



GET_PSP			PROC
				MOV AH, 62H                 			; ES wskazuje na segment PSP
				INT 21H									; Get PSP address
				MOV ES,BX

				MOV AX, SEG CMD_BUFFER      			; wstaw do DS:SI adres CMD_BUFFERa
				MOV ds, AX
				MOV si, offset CMD_BUFFER				; SI = pointer to the first character of parameters

				XOR AX, AX
				MOV AL, BYTE PTR ES:[80H]    			; ustaw ileznakow na liczbe znakow przekazanych w parametrze PSP
				MOV [ARG_LENGTH], AL					; Save the argument's string length

				MOV DI, 82h                 
				XOR CX, CX                  			; Loop counter
				MOV CL, BYTE PTR ES:[80h]   			; Number of bytes of the command line (is one to big)
				SUB CX, 1                   			; Decrement the number of bytes

				@@P1:
	 			MOV AL, BYTE PTR ES:[DI]     			; Load one character from PSP...
    			MOV BYTE PTR DS:[SI], AL    			; ...and store it in CMD_BUFFER
    			INC SI                      			; Increment the pointer to CMD_BUFFER
    			INC DI                      			; Increment the pointer to PSP
    			LOOP @@p1                   			; Repeat CX times

				RET
GET_PSP			ENDP

PARSE_PSP		PROC
				
				XOR CX, CX								; Empty the register
				MOV CL, [ARG_LENGTH]

				XOR SI, SI
				XOR DI, DI
				XOR AX, AX
				XOR BX, BX
				XOR DX, DX

				MOV BL, 0
				MOV DL, 10
				
				MOV SI, offset CMD_BUFFER				; SI = pointer to the first character of parameter
				JMP @@LOOP_STRING

				@@PARSE_ARGUMENT:
				DEC CX
				INC SI
				MOV AL, BYTE PTR DS:[SI]

				CMP AL, 104
				JZ @@PARSE_HELP
				CMP AL, 102
				JZ @@PREPARE_TO_PARSE_FILENAME
				CMP AL, 110
				JZ @@PREPARE_TO_PARSE_N_LINES

				@@PARSE_HELP:
				MOV HELP, 1
				INC SI
				DEC CX
				JMP @@LOOP_STRING

				@@END_FILENAME:
				INC DI
				MOV BYTE PTR DS:[DI], '$'
				CMP CX, 0
				JZ @@EXIT
				JMP @@LOOP_STRING

				@@END_N_LINES:
				;INC DI
				;MOV BYTE PTR DS:[DI], '$'
				MOV [N_LINES], BX
				CMP CX, 0
				JZ @@EXIT
				JMP @@LOOP_STRING

				@@PARSE_FILENAME:
				MOV AL, BYTE PTR DS:[SI]
				INC SI
				DEC CX
				CMP AL, 45
				JZ @@END_FILENAME
				CMP AL, 32
				JZ @@END_FILENAME
				
				MOV BYTE PTR DS:[DI], AL
				INC DI
				MOV FILENAME_CMD, 1

				CMP CX, 0
				JZ @@EXIT
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_FILENAME:
				MOV DI, offset FILENAME
				INC SI
				INC SI
				DEC CX
				DEC CX
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_N_LINES:
				MOV DI, offset N_LINES
				INC SI
				INC SI
				DEC CX
				DEC CX
				JMP @@PARSE_N_LINES

				@@PARSE_N_LINES:
				MOV AL, BYTE PTR DS:[SI]
				INC SI
				DEC CX
				CMP AL, 45
				JZ @@END_N_LINES
				CMP AL, 32
				JZ @@END_N_LINES
				
				MOV N_LINES_CMD, 1

				CMP CX, 0
				JZ @@EXIT

				MOV AH, 0  
      			SUB AL, 48   		; ASCII to DECIMAL

				PUSH CX
      			MOV CL, AL
      			MOV AL, BL  		; Store the previous value in AL
				
      			MUL DL       		; Multiply the previous value with 10

      			ADD AL, CL   		; Previous value + new value ( after previous value is multiplyed with 10 )
     			MOV BL, AL			; Store the value to BL
				POP CX

				JMP @@PARSE_N_LINES

				@@LOOP_STRING:
				MOV AL, BYTE PTR DS:[si]
				CMP AL, 45
				JZ @@PARSE_ARGUMENT
				INC SI
				DEC CX
				CMP CX, 0
				JZ @@EXIT
				JMP @@LOOP_STRING

				@@EXIT:
				RET

				RET
PARSE_PSP		ENDP

MAIN:      
				MOV AX, @DATA						; Move Data segment to AX
        		MOV DS, AX							; Store AX to DS

INPUT:
				CALL GET_PSP						
				CALL PARSE_PSP

				CMP FILENAME_CMD, 1
				JNZ FILENAME_MISSING
				
				CMP N_LINES_CMD, 1
				JNZ INPUT_LINES_FROM_KEYBOARD

				JMP PROCESS_FILE					; Got the input from PSP

FILENAME_MISSING:
				MOV AH, 9
				MOV DX, offset FILE_MISS_MSG
				INT 21H
				JMP TERMINATE

INPUT_LINES_FROM_KEYBOARD:
				MOV AH, 9							; Vypis Zadaj N spravy
	    		MOV DX, OFFSET MSG
	    		INT 21H
				CALL INPUT_N_LINES


PROCESS_FILE:
				CALL FILE_OPEN						; Open the file
				CALL MAIN_FUNCTION
				CALL FILE_CLOSE

TERMINATE:
        		MOV AX, 4C00H
        		INT 21H

END MAIN

