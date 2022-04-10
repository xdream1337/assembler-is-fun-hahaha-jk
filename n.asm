LOCALS @@
.MODEL SMALL
.STACK 300h
.386
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
FILENAME    	DB 128 dup(0)
FILEHANDLE  	DW ?
BYTES_READ  	DW ?
LINES       	DW 0			; How many new lines are counted in buffer
LINES_TO_SKIP	DW 0
COUNTER	    	DW 1
N_LINES     	DW 1			; How many N last lines to print
FILEPOS     	DW 0      
LINE_ROW    	DW 0
MSG	    		DB "Zadaj N: $", 13, 10
ERR_MSG_N		DB "Zadany riadok neexistuje", 13, 10, '$'
ARG_LENGTH		DB 0
CMD_BUFFER		DB 128 dup('$')
HELP			DB 0
FILENAME_CMD	DB 0
N_LINES_CMD		DB 0
HELP_MSG		DB "help??? chod do pixi", 13, 10, '$'
;-------------------------------------------------------------


.CODE 


NEW_LINE		MACRO
				MOV AH, 2H					; Prepare for character output
				MOV DL, 13					; Move Carriage Return to DL register
				INT 21H						; Interupt - DOS API 21H - CHARACTER STDOUT 2H
				MOV DL, 10					; Move Line Feed to DL register
				INT 21H						; Interupt - DOS API 21h - CHARACTER STDOUT 2H
				ENDM


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
				;MOV N_LINES, BX
				MOV AH, 9					; Vypis Zadaj N spravy
                ;MOV BH, 0
	    		MOV DX, BX
	    		INT 21H
				RET

INPUT_N_LINES	ENDP

GET_PSP			PROC
				MOV AH, 62H                 ; ES wskazuje na segment PSP
				INT 21H						; Get PSP address
				MOV ES,BX

				mov ax, seg CMD_BUFFER      ; wstaw do DS:SI adres CMD_BUFFERa
				mov ds, ax
				mov si, offset CMD_BUFFER	; SI = pointer to the first character of parameters

				XOR AX, AX
				MOV al,byte ptr ES:[80H]    ; ustaw ileznakow na liczbe znakow przekazanych w parametrze PSP
				mov [ARG_LENGTH], al		; Save the argument's string length

				mov di, 82h                 
				xor cx, cx                  ; Loop counter
				mov cl, byte ptr es:[80h]   ; Number of bytes of the command line (is one to big)
				sub cx, 1                   ; Decrement the number of bytes

				@@P1:
	 			mov al,byte ptr es:[di]     ; Load one character from PSP...
    			mov byte ptr ds:[si],al     ; ...and store it in CMD_BUFFER
    			inc si                      ; Increment the pointer to CMD_BUFFER
    			inc di                      ; Increment the pointer to PSP
    			loop @@p1                   ; Repeat CX times

				RET
GET_PSP			ENDP

PARSE_PSP		PROC
				
				XOR CX, CX								; Empty the register
				MOV CL, [ARG_LENGTH]

				XOR SI, SI
				XOR DI, DI
				XOR AX, AX
				
				mov si, offset CMD_BUFFER				; SI = pointer to the first character of parameter
				JMP @@LOOP_STRING


				@@PARSE_ARGUMENT:
				DEC CX
				INC SI
				MOV AL, BYTE PTR DS:[si]

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
				INC DI
				MOV BYTE PTR DS:[DI], '$'
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

				CMP CX, 0
				JZ @@EXIT
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_FILENAME:
				MOV DI, offset FILENAME
				MOV FILENAME_CMD, 1
				INC SI
				INC SI
				DEC CX
				DEC CX
				JMP @@PARSE_FILENAME

				@@PREPARE_TO_PARSE_N_LINES:
				MOV DI, offset N_LINES
				MOV N_LINES_CMD, 1
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
				
				MOV BYTE PTR DS:[DI], AL
				INC DI

				CMP CX, 0
				JZ @@EXIT
				JMP @@PARSE_FILENAME

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



START:      
				MOV AX, @DATA
        		MOV DS, AX

                CALL GET_PSP
				CALL PARSE_PSP

EXIT:   		    
				MOV AH, 9					; Vypis Zadaj N spravy
	    		MOV DX, offset N_LINES
	    		INT 21H
				NEW_LINE
				MOV AH, 9					; Vypis Zadaj N spravy
	    		MOV DX, offset FILENAME
	    		INT 21H
				CMP HELP, 1
				JZ HELP_MESSAGE

HELP_MESSAGE:
				NEW_LINE
				MOV AH, 9
				MOV DX, offset HELP_MSG
				INT 21h
				JMP TERMINATE

TERMINATE:
        		MOV AX, 4C00H
        		INT 21H
        		END START