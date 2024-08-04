#include "P16F877A.inc"
	cblock 0x20
	Key1L 
	Key1H
	Key2L
	Key2H
	Key3L
	Key3H
	NumOfRounds
	RL
	RH
	TEMP1
	TEMP2
	TEMP3
	check
	COUNTER
	endc

	org 0x0000
	goto START
	org 0x0004
	goto ISR

START
	movlw D'5'
	movwf COUNTER
	clrf PORTD
	clrf PORTB
	clrf PORTC
	movlw 0x25
	movwf Key1L
	movlw 0x40
	movwf Key1H
	movlw 0xB3
	movwf Key2L
	movlw 0x4E
	movwf Key2H
	movlw 0x2D
	movwf Key3L
	movlw 0x6B
	movwf Key3H
	bsf STATUS, RP0 ;select Bank1
	bsf INTCON, GIE ;setting global interrupts enable
	bsf INTCON, TMR0IE
	bsf PIE1, RCIE
	bsf INTCON, PEIE
	bcf TXSTA, SYNC
	bcf TRISC, 0
	bsf TRISC, 7
	clrf TRISD
	clrf TRISB
	bsf TXSTA, BRGH
	movlw B'10000111'
	movwf OPTION_REG
	movlw D'25'
	movwf SPBRG
	bcf STATUS, RP0
	movlw D'61' ; preload T0, it overflows after 196 counts 
	movwf TMR0
	bsf RCSTA, SPEN
	bsf RCSTA, CREN
loop1
	btfss check,0
	goto loop1
	goto Decrypt

Decrypt 
	clrw
	movlw D'2'
	movwf NumOfRounds
	bcf STATUS,C
LOOP1
	movf RL, W
	movwf TEMP1
	btfsc RH, 0
	bsf STATUS, C
	rrf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP1,0
	bsf STATUS, C
	rrf RH, W
	movwf RH
	movf RL, W	
	xorwf Key3L, W
	movwf RL
	movf RH, W
	xorwf Key3H, W
	movwf RH
	bcf STATUS, C

	movf RL, W
	movwf TEMP2
	btfsc RH, 0
	bsf STATUS, C
	rrf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP2,0
	bsf STATUS, C
	rrf RH, W
	movwf RH
	movf RL, W	
	xorwf Key2L, W
	movwf RL
	movf RH, W
	xorwf Key2H, W
	movwf RH
	bcf STATUS, C

	
	movf RL, W
	movwf TEMP3
	btfsc RH, 0
	bsf STATUS, C
	rrf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP3,0
	bsf STATUS, C
	rrf RH, W
	movwf RH
	movf RL, W	
	xorwf Key1L, W
	movwf RL
	movf RH, W
	xorwf Key1H, W
	movwf RH
	bcf STATUS, C

	decfsz NumOfRounds ,1
	goto LOOP1

	movf RL, W
	movwf PORTD
	movf RH, W
	movwf PORTB

	bcf check,0
	goto loop1


ISR
	btfsc PIR1, RCIF
	goto Receive
	btfsc INTCON, TMR0IF
	goto timer0
Receive
	movf RCREG, W
	movwf RH
loop
	btfss PIR1, RCIF
	goto loop

	movf RCREG , W
	movwf RL
	bsf check,0

	retfie


timer0	
	bcf INTCON,TMR0IF ;clear Timer Overflow flag
	decfsz COUNTER,F
	goto load
	movlw 0x01
	xorwf PORTC , F
	movlw D'5'
	movwf COUNTER
	retfie

load movlw D'61'
	movwf TMR0
	retfie

end