;====================================================================
; DEFINITIONS
;====================================================================
printPort equ P1
regTable equ R0
nPrint equ R2
memTable equ 200
displayX equ P2.7
displayY equ P2.6
;====================================================================
; VARIABLES
;====================================================================

;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================

    ; Reset Vector
	org   0000h
	JMP   Start
	  
	;Externa 0
	org 0003h
	CALL externa0
	RETI
	
	; Timer0
	org 000Bh
	CPL P1.0
	CALL timer0Rotina
	RETI
	
	;externa 1
	org 0013h
	CALL externa1
	RETI
	
	
	;Timer 1
	ORG 1BH
	
;====================================================================
; CODE SEGMENT
;====================================================================

    ORG   0100h
Start:
	;MainBemFeita
	;Coloca a distancia em R5 e o tempo em R4
	MOV R4,#1
	MOV R5,#38
	CALL checkSpeed
	JMP $
	
	CALL Reset_inicial
	JMP $

Reset_inicial:	
	;P0.1 indica que esta na fase da captura de dados
	SETB P0.1	
	;Habilitando as interupções
	SETB EA	
	;Habilitando a interupção externa 0
	SETB EX0
	;Transformando em interupção por borda
	SETB IT0	
	SETB IT1	
	
	CALL Arruma_Timer
	MOV R5,#0
	MOV R6,#0
	RET
	


Arruma_Timer:
	; Timer 0 e Timer 1, modo 1 (contador de 16 bits)
	MOV TMOD, #00010001b 	
	;Liga interrupções, e liga interrupção de timer0	
	;SETB ET0
	RET

externa0:
	CLR EX1
	CLR EX0
	CPL P2.3
	JNB P2.3,FinalizaContagem ;if(P2.3 != 0) FinalizaContagem
	CALL inicia_contagem_frequencia ;inicia contagem		
	SETB EX0
	RET
FinalizaContagem:
	CALL para_contagem_frequencia
	;SETB EX0
	RET
	
inicia_contagem_frequencia:
	MOV TH0,#0
	MOV TL0,#0
		
	;Inicializa o timer0
    SETB TR0
	RET

para_contagem_frequencia:
	CLR TR0
	;Salvando o valor contado
	MOV A,TL0
	MOV R3,A
	MOV A,TH0
	MOV R4,A
	
	CJNE R5,#0,compara_valores ; if(R5 != 0) vai para compara_valores
	CJNE R6,#0,compara_valores ; if(R6 != 0) vai para compara_valores
carrega_tempos:
	MOV A,R3
	MOV R5,A
	MOV A,R4
	MOV R6,A
	CALL inicia_contagem_frequencia
	SETB EX0
	RET
		
	;Compara os valores
compara_valores:
	;Tempo L novo
	MOV A,R6
	;Tempo L antigo
	SUBB A,R4
	
	;Nosso threshold eh de 1 unidades de timer
	;A esta segurando a diferença entre TL
	CLR C
	SUBB A,#1
	
	JNC mudou_frequecia
	SETB EX0
	RET
mudou_frequecia:
	;Inicializa o timer1
    SETB TR1
	;liga a interrupcao 1
	SETB EX1
	SETB P2.3
	MOV R6,#0
	MOV R5,#0
	MOV P1, #10101010B
	RET
	
Delay:	;Um segundo de delay			
					MOV R7,#200
LOOP:				MOV R6,#1
					DJNZ R5,$
					DJNZ R7,LOOP
					RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;ESPELHO P/ EX1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



externa1:
	CLR EX1
	CPL P2.3; OLHAR
	JNB P2.3,FinalizaContagem2 ;if(P2.3 != 0) FinalizaContagem
	CALL inicia_contagem_frequencia2 ;inicia contagem		
	SETB EX1
	RET
FinalizaContagem2:
	CALL para_contagem_frequencia2
	;SETB EX1
	RET
	
inicia_contagem_frequencia2:
	MOV TH0,#0
	MOV TL0,#0
		
	;Inicializa o timer0
    SETB TR0
	SETB EX1
	RET

para_contagem_frequencia2:
	CLR TR0
	;Salvando o valor contado
	MOV A,TL0
	MOV R3,A
	MOV A,TH0
	MOV R4,A
	
	CJNE R5,#0,compara_valores2; if(R5 != 0) vai para compara_valores
	CJNE R6,#0,compara_valores2 ; if(R6 != 0) vai para compara_valores
carrega_tempos2:
	MOV A,R3
	MOV R5,A
	MOV A,R4
	MOV R6,A
	CALL inicia_contagem_frequencia2
	RET
		
	;Compara os valores
compara_valores2:
	;Tempo L novo
	MOV A,R6
	;Tempo L antigo
	SUBB A,R4
	
	;Nosso threshold eh de 1 unidades de timer
	;A esta segurando a diferença entre TL
	CLR C
	SUBB A,#1
	
	JNC mudou_frequecia2
	SETB EX1
	RET
mudou_frequecia2:
	;Finaliza o timer1 
    CLR TR1
	
	;Implementar o que precisa fazer para chamar as funções do display
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ROTINA:
       CPL P2.5 ; complementa estado do bit 0 do PORT 1
       RETI ; retorno da rotina interrupção
	   
configTimersToDisplay:
	;Configurando tempo do timer0
	MOV R3,#30
	
	; Timer 0 e Timer 1, modo 1 (contador de 16 bits)
	MOV TMOD, #00010001b 
	
	;Liga interrupções, e liga interrupção de timer0
	SETB EA
	SETB ET0
	;SETB ET1
	
	;Inicializa o timer0
    SETB TR0
	;SETB TR1
	
	;Configuração da quantidade de tempo
	MOV TH0, 255
	MOV TL0, 0
	
	RET
	
loadNumbers:
	MOV regTable,#memTable
	;Caso seja o número 0 
	MOV @regTable,#11000000b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 1 
	MOV @regTable,#1111001b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 2 
	MOV @regTable,#10100100b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 3 
	MOV @regTable,#10110000b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 4 
	MOV @regTable,#00011001b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 5 
	MOV @regTable,#00010010b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 6 
	MOV @regTable,#10000010b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 7 
	MOV @regTable,#1111000b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 8 
	MOV @regTable,#00000000b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	;Caso seja o número 9 
	MOV @regTable,#01100000b
	
	;Passando para próximo endereço
	MOV A, regTable
	ADD A,#1
	MOV regTable, A
	
	RET
	
writeNumber:
	;Colocando o ponteiro pra posição inicial dos números
	MOV regTable,#memTable
	
	;Colocando o ponteiro no número correto a ser escrito
	MOV A, nPrint
	ADD A, regTable
	
	;Escrevendo na porta o valor
	MOV regTable, A
	MOV printPort, @regTable
	
	RET
	
write2Displays:
	;Salvando o número a ser impresso
	MOV A, nPrint
	MOV R7,A
	
	;Indo para a rotina de printar dezena, caso o displayX nao esteja setado
	JB displayX, printDezena 
	
	;Fazendo rotina para pegar unidade
	MOV A,R7
	
	;Pegando a parte inteira da divisão por 10, as dezenas
	MOV B,#10
	DIV AB
	
	MOV B,#10
	;Pegando as unidades
	MUL AB
	MOV B,A
	MOV A,R7
	MOV R6,B
	SUBB A, R6
	
	;Printando as unidades
	SETB displayX
	CLR displayY
	MOV nPrint,A
	CALL writeNumber
	
	MOV A,R7
	MOV nPrint, A
	
	RETI
	
printDezena:
	MOV A,R7
	;Pegando a parte inteira da divisão por 10, as dezenas
	MOV B,#10
	DIV AB
	
	;Printando no display da dezena
	CLR displayX
	SETB displayY
	MOV nPrint,A
	CALL writeNumber
	
	MOV A,R7
	MOV nPrint, A
	RETI

checkSpeed:
	;Supondo que tenha o tempo em R4 e a Distancia em R5
	MOV B, R4
	MOV A, R5
	
	;Pegando a Velocidade por hr
	DIV AB
	MOV nPrint,A
	
	;Checando se passou de 40
	CLR C
	SUBB A,#40
	
	;Decide se liga led/buzzer ou só escreve nos displays
	JC writingSpeed
	CLR P0.0
	
writingSpeed:
	;Escrevendo
	CALL loadNumbers
	CALL configTimersToDisplay
	RET
	
timer0Rotina:
	DJNZ R3, t0r
	;Desligando display, buzzer e led
	SETB P0.0
	CLR displayX
	CLR displayY
	CLR TR0
	RET
t0r:
	AJMP write2Displays
	RET
	
;====================================================================
      END
