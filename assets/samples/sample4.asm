; Example 4:
; Program a periodic interrupt that increments
; a counter [0 to 99] and prints its value into
; the textual display
 
	JMP boot 
	JMP isr

counter:		; the counter
	DW 0

boot:
	MOV SP, 255		; Set SP
	MOV A, 2		; Set bit 1 of IRQMASK
	OUT 0			; Unmask timer IRQ
	MOV A, 0x20		; Set timer preload
	OUT 3
	STI
	HLT

isr:
	PUSH A
	PUSH B
	PUSH C
	MOV A, [counter]	; Increment the
	INC A				; counter
	CMP A, 100			; [0 to 99]
	JNZ .print
	MOV A, 0

.print:
	MOV [counter], A	; Print the
	MOV B, A			; decimal value
	DIV 10				; of the counter
	MOV C, A
	MUL 10
	SUB B, A
	ADDB CL, 0x30
	ADDB BL, 0x30
	MOVB [0x2E0], CL
	MOVB [0x2E1], BL
	MOV A, 2
	OUT 2				; Write to signal IRQEOI
	POP C
	POP B
	POP A
	IRET
