LOCALS @@
.MODEL SMALL
.STACK 300h
.386
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
MSG	    		DB "Input N: $", 13, 10
ERR_MSG_N		DB "Line does not exist!", 13, 10, '$'
ERR_NOT_FOUND   DB "Error with file, terminating the program!", 13, 10, '$'
ARG_LENGTH		DB 0
CMD_BUFFER		DB 128 dup('$')
HELP			DB 0
FILENAME_CMD	DB 0
N_LINES_CMD		DB 0
HELP_MSG    DB "Print N last lines from file",13,10, "Program supports filenames up to 15 characters", 13, 10, "Program supports only 2 digit N line number", 13, 10,"Options:", 13, 10, "h - Help", 13, 10, "f - filename", 13, 10, "n - N last lines", 13, 10, "Example: nlines -f file.txt -n 10 - print last 10 lines from file", 13, 10, '$'
FILE_MISS_MSG   DB "No filename given, terminating the program!", 13, 10, '$'
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
            	MOV DX, OFFSET buffer       
            	INT 21H

            	MOV BYTES_READ, AX        	; Save how many bytes i've read
            	CMP AX, 0    				; If no bytes were read jump to exit               
            	JZ @@EXIT					; Jump to exit

            	MOV BX, DX					; Move BX to DX
            	ADD BX, BYTES_READ			; Add bytes read to BX
            	MOV BYTE PTR [BX], '$'		; Terminate the string

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

				MOV DL, BYTE PTR [BX]		; Load 1 character from buffer
            	CMP DL, AL					; If new line
            	JE @@INCREMENT				; Increment Lines
            	INC BX						; Increment pointer to buffer
            	LOOP @@LOOP1				; Loop
            	JMP @@EXIT					; Exit if done

            	@@INCREMENT:				; Increment lines
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
				TEST CX, CX				; Test if some bytes were read
				JZ @@EXIT

				MOV DL, BYTE PTR [BX]	; Load 1 character from buffer
            	CMP DL, AL				; Check if new line
            	JE @@INCREMENT			; Increment new lines
            	INC BX
            	LOOP @@LOOP1
            	JMP @@EXIT

            	@@INCREMENT:
				MOV SI, COUNTER			
            	CMP LINES_TO_SKIP, SI	; Check if N-th line was found
            	JE @@SAVE_VALUE			; Save the pointer 
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
				CALL FILE_OPEN				; Find N-th line

				MOV AX, LINES
				MOV LINES_TO_SKIP, AX		; Copy Lines to Lines_to_skip

				MOV AX, N_LINES				; Load N_LINES to AX
				SUB LINES_TO_SKIP, AX		; LINES_TO_SKIP (LINES) - N_LINES - calculate how many lines to skip
				MOV AX, LINES_TO_SKIP		; Move LINES_TO_SKIP to AX
				INC AX
				CMP AX, 0					; Check if line exists
				JL @@ERR					; Line does not exist
				JMP @@FIND_POSITION			; Find position of the line

				@@FIND_POSITION:			; Find position of N-th line
				CALL FILE_READ				; Read the file
				CALL GET_TO_LINE			; Get to line
				JZ @@PRINT_FROM_LINE		; Print from line
				INC LINE_ROW				
				JMP @@FIND_POSITION
				
				@@PRINT_FROM_LINE:
				MOV DX, FILEPOS				; Move one of the N-th lines to DX
				CALL PRINT_STRING			; Print the line

				@@LOOPX:					; Print N last lines
				CALL FILE_READ				; Get data to buffer
				JZ @@EXIT					; No data were read
				MOV DX, OFFSET buffer		; Move buffer to DX
				CALL PRINT_STRING			; Print the line
				JMP @@EXIT					
		
				@@ERR:						; Line not found
				NEW_LINE					
				MOV DX, OFFSET ERR_MSG_N
				MOV AH, 9H
				INT 21H
				
				@@EXIT:
				RET
MAIN_FUNCTION	ENDP

INPUT_N_LINES	PROC

				XOR DX, DX			; Empty the registers
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
				MOV AH, 62H                 			; ES will point to PSP
				INT 21H									; Get PSP address
				MOV ES,BX								; Move PSP address to ES

				MOV AX, SEG CMD_BUFFER      			; Move CMD_BUFFER to AX
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

				XOR SI, SI								; Empty the registers
				XOR DI, DI
				XOR AX, AX
				XOR BX, BX
				XOR DX, DX

				MOV BL, 0								; Prepare registers for loading numbers
				MOV DL, 10								; Add 10 to DL for multiplying
				
				MOV SI, offset CMD_BUFFER				; SI = pointer to the first character of args
				JMP @@LOOP_STRING						; Loop args character one by one

				@@PARSE_ARGUMENT:
				DEC CX
				INC SI
				MOV AL, BYTE PTR DS:[SI]
													; Switch to determine if 
				CMP AL, 104							; -h flag was given
				JZ @@PARSE_HELP						
				CMP AL, 102							; -f flag was given
				JZ @@PREPARE_TO_PARSE_FILENAME
				CMP AL, 110							; -n flag was given
				JZ @@PREPARE_TO_PARSE_N_LINES

				@@PARSE_HELP:
				MOV HELP, 1							; I need to save if help arg was given
				INC SI								; Increase pointer to PSP characters
				DEC CX								; Decrease counter
				JMP @@LOOP_STRING					; Jump to LOOP_STRING

				@@END_FILENAME:						; Check if last character was read
				CMP CX, 0							; If yes, exit the proc
				JZ @@EXIT							
				JMP @@LOOP_STRING					; Loop the PSP string if not

				@@END_N_LINES:
				MOV N_LINES, BX						; Move BX to N_LINES
				CMP CX, 0							; Check if last characters was read
				JZ @@EXIT
				JMP @@LOOP_STRING

				@@PARSE_FILENAME:
				MOV AL, BYTE PTR DS:[SI]			; Load character from PSP string
				INC SI								; Increase pointer
				DEC CX								; Decrease counter
				CMP AL, 45							; Check if space or hyphen
				JZ @@END_FILENAME
				CMP AL, 32							; Check if space or hyphen
				JZ @@END_FILENAME					; I read the whole filename
				
				MOV BYTE PTR DS:[DI], AL			; Save the character from PSP string to FILENAME
				INC DI								; Increase pointer for filename
				MOV FILENAME_CMD, 1					; I've read the filename

				CMP CX, 0
				JZ @@EXIT
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_FILENAME:
				MOV DI, offset FILENAME		; Just move address of FILENAME to DI
				INC SI						; Skip two characters because I want to point to actual arg's value
				INC SI
				DEC CX
				DEC CX
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_N_LINES:
				MOV DI, offset N_LINES		; Just move address of NLINES to DI
				INC SI						; Skip two characters because I want to point to actual arg's value
				INC SI	
				DEC CX
				DEC CX
				JMP @@PARSE_N_LINES

				@@PARSE_N_LINES:
				MOV AL, BYTE PTR DS:[SI]	; Load character from PSP
				INC SI
				DEC CX
				CMP AL, 45					; Check if space or - is found (for another parameter)
				JZ @@END_N_LINES
				CMP AL, 32
				JZ @@END_N_LINES			; If yes, jump to end_n_lines to save n_lines
				
				MOV N_LINES_CMD, 1			; Flag to know if N_LINES arg was given

				CMP CX, 0					; Check if last character was read
				JZ @@END_N_LINES

				MOV AH, 0  
      			SUB AL, 48   				; ASCII to DECIMAL

				PUSH CX						; Push CX to stack
				MOV CH, 0
      			MOV CL, AL
      			MOV AL, BL  				; Store the previous value in AL
				
      			MUL DL       				; Multiply the previous value with 10

      			ADD AL, CL   				; Previous value + new value ( after previous value is multiplyed with 10 )
     			MOV BL, AL					; Store the value to BL
				POP CX						; Pop CX from stack
				
				JMP @@PARSE_N_LINES

				@@LOOP_STRING:
				MOV AL, BYTE PTR DS:[si]	; Load the character from PSP
				CMP AL, 45					; Check if - was read
				JZ @@PARSE_ARGUMENT			; If yes, then argument is found
				INC SI						; Increase SI pointer to PSP characters
				DEC CX						; Decrease CX
				CMP CX, 0					; If we read last character
				JZ @@EXIT
				JMP @@LOOP_STRING			; Loop through another character

				@@EXIT:
				RET

				RET
PARSE_PSP		ENDP

MAIN:      
				MOV AX, @DATA						; Move Data segment to AX
        		MOV DS, AX							; Store AX to DS

INPUT:
				CALL GET_PSP						; Load PSP
				CALL PARSE_PSP						; Parse PSP

				CMP HELP, 1							; Check if -h argument was given
				JZ HELP_MESSAGE

				CMP FILENAME_CMD, 1					; Check if filename is not missing
				JNZ FILENAME_MISSING
				
				CMP N_LINES_CMD, 1					; Check if N_LINES is not missing, if yes, scan the value from keyboard
				JNZ INPUT_LINES_FROM_KEYBOARD

				JMP PROCESS_FILE					; Got the input from PSP

FILENAME_MISSING:
				MOV AH, 9							; Prepare for string output
				MOV DX, offset FILE_MISS_MSG		; Move FILE_MISS_MSG to DX
				INT 21H								; Print the string
				JMP TERMINATE						; Jump to TERMINATE label

INPUT_LINES_FROM_KEYBOARD:
				MOV AH, 9							; Print Input N message
	    		MOV DX, OFFSET MSG					
	    		INT 21H								; Print the string
				CALL INPUT_N_LINES					; Jump to TERMINATE label
				JMP PROCESS_FILE

HELP_MESSAGE:
				NEW_LINE
				MOV AH, 9
				MOV DX, offset HELP_MSG
				INT 21h
				JMP TERMINATE


PROCESS_FILE:
				CALL FILE_OPEN						; Open the file
				CALL MAIN_FUNCTION					; Main function
				CALL FILE_CLOSE						; Close the file after reading

TERMINATE:
        		MOV AX, 4C00H						; Terminate the program
        		INT 21H

END MAIN

