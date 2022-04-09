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
N_LINES     	DW 1			; How many N last lines to print
FILEPOS     	DW 0      
LINE_ROW    	DW 0
MSG	    		DB "Zadaj N: $", 13, 10
ERR_MSG_N		DB "Zadany riadok neexistuje", 13, 10, '$'
ARG_LENGTH		DW 0
CMD_BUFFER		DB 128 dup('$')
;-------------------------------------------------------------


.CODE 


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


START:      
                
				MOV AX, @DATA
        		MOV DS, AX

                MOV AH, 62H                 ;ES wskazuje na segment PSP
				INT 21H						; Get PSP address
				MOV ES,BX

				mov si, offset CMD_BUFFER	; SI = pointer to the first character of parameters

				XOR BX, BX
				MOV BL, byte ptr ES:[80H]    ; ustaw ileznakow na liczbe znakow przekazanych w parametrze PSP
				
				mov [ARG_LENGTH], BX		; Save the argument's string length

				XOR AX, AX
				MOV AH, 5
				MOV DX, offset ARG_LENGTH
				INT 21H

			;	mov di, 82h                 
			;	xor cx, cx                  ; Loop counter
			;	mov cl, byte ptr es:[80h]   ; Number of bytes of the command line (is one to big)
			;	sub cx, 1                   ; Decrement the number of bytes

;p1: 			mov al,byte ptr es:[di]     ; Load one character from PSP...
    		;	mov byte ptr ds:[si],al     ;     ...and store it in CMD_BUFFER
    		;	inc si                      ; Increment the pointer to CMD_BUFFER
    		;	inc di                      ; Increment the pointer to PSP
    		;	loop p1                     ; Repeat CX times


EXIT:   		    
			;	MOV AH, 9					; Vypis Zadaj N spravy
	    	;	MOV DX, OFFSET CMD_BUFFER
	    	;	INT 21H
			;	MOV AH, 5					; Vypis Zadaj N spravy
	    	;	MOV DL, ARG_LENGTH
	    	;	INT 21H
        		MOV AX, 4C00H
        		INT 21H
        		END START