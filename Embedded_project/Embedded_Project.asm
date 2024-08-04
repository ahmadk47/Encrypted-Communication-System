#include "P16F877A.inc"
	cblock 0x20
	Key1H ; KEY1 = 16421
	Key1L
	Key2H ; KEY2 = 20147
	Key2L
	Key3H ; KEY3 = 27437
	Key3L
	NumOfRounds 
	RH	; RESULT HIGH
	RL	; RESULT LOW
	TEMP1
	TEMP2
	TEMP3
	check1
	endc
	org 0x0000
	goto Start
	org 0x0004
	goto ISR
Start
	clrf PORTC
	clrf PORTD
	clrf check1
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
	bsf STATUS, RP0 
	bsf OPTION_REG, INTEDG 
	bsf INTCON, INTE ;setting interrupts enables
	bsf INTCON, GIE 
	bsf INTCON, PEIE
	bcf TXSTA, SYNC	 ; enabel Asynchronous serial port
	bsf TXSTA, TXEN  ; enable serial transmission
	bsf TXSTA, BRGH	;setting the baud rate
	movlw D'25'
	movwf SPBRG
	movlw B'00001111' ;configure RD3-RD0 as input to read the switches' values
	movwf TRISD
	bcf TRISC,6 ;configure RC6 as output to transmit the data
	bcf STATUS, RP0
	bsf RCSTA, SPEN

WAIT btfss check1, 0 ; Wait for an external interrupt to occur
	 goto WAIT
	goto getValues ;retrieve data to be encrypted, depending on the switches' values

getValues
	btfsc PORTD, 0
	goto NOTZ1
	goto Zero1
Zero1
	btfss PORTD, 1
	goto Zero2
	movlw 0x1E ;J
	movwf RL
	goto checkSW3
NOTZ1
	btfsc PORTD, 1
	goto NOTZ2
	movlw 0x06;1
	movwf RL
	goto checkSW3

Zero2
	movlw 0x7D;6
	movwf RL
	goto checkSW3


NOTZ2
	movlw 0x39;C
	movwf RL
	goto checkSW3

checkSW3
	btfss PORTD, 2
	goto Zero3
	goto NOTZ3
Zero3
	btfss PORTD, 3
	goto Zero4
	movlw 0x3E ;U
	movwf RH
	goto Encrypt

NOTZ3
	btfsc PORTD, 3
	goto NOTZ4
	movlw 0x4F ;3
	movwf RH
	goto Encrypt

Zero4
	movlw 0x79 ;E
	movwf RH
	goto Encrypt

NOTZ4
	movlw 0x7F ;8
	movwf RH
	goto Encrypt

Encrypt	
	movlw D'2'
	movwf NumOfRounds
	clrw
	bcf STATUS, C
LOOP
	movf RL, W	;XORING with KEY1 then rotating
	xorwf Key1L, W
	movwf RL
	movwf TEMP1
	movf RH, W
	xorwf Key1H, W
	movwf RH
	btfsc RH, 7
	bsf STATUS, C
	rlf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP1,7
	bsf STATUS, C
	rlf RH, W
	movwf RH
	bcf STATUS, C

	movf RL, W	;XORING with KEY2 then rotating
	xorwf Key2L, W
	movwf RL
	movwf TEMP2
	movf RH, W
	xorwf Key2H, W
	movwf RH
	btfsc RH, 7
	bsf STATUS, C
	rlf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP2, 7
	bsf STATUS, C
	rlf RH, W
	movwf RH
	bcf STATUS, C

	movf RL, W	;XORING with KEY3 then rotating
	xorwf Key3L, W
	movwf RL
	movwf TEMP3
	movf RH, W
	xorwf Key3H, W
	movwf RH
	btfsc RH, 7
	bsf STATUS, C
	rlf  RL, W
	movwf RL
	bcf STATUS, C
	btfsc TEMP3, 7
	bsf STATUS, C
	rlf RH, W
	movwf RH
	bcf STATUS, C

	decfsz NumOfRounds ,1
	goto LOOP

banksel PIE1
	bsf PIE1, TXIE ;set the transmitter interrupt enable, to set TXIF, to start transmitting after the encryption is done
	clrf check1
	goto WAIT
	

ISR 
	bcf STATUS,RP0
	btfsc INTCON, INTF
	goto EXT_INT
	btfsc PIR1, TXIF
	goto TX

EXT_INT
	bsf check1,0
	bcf INTCON, INTF
	retfie

TX
	movlw 0x27
	movwf FSR
loop	
	movf INDF, W
	movwf TXREG
	incf FSR, F
	movf FSR,W
	sublw 0x29
	btfss STATUS, Z
	goto loop
banksel PIE1 
	bcf PIE1, TXIE
	retfie
	
done nop
end	
