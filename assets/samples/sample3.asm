; Example 3:
; Draws a sprite in the visual display that can be
; moved using the keypad:
; 2: UP, 4: LEFT; 6: RIGHT; 8: DOWN

	JMP boot
	JMP isr

sprite:	DB "\x35\xFF\xFF\x35"	; Sprite line 0
		DB "\xFF\x35\x35\xFF"	; Sprite line 1
		DB "\xFF\x35\x35\xFF"	; Sprite line 2
		DB "\x35\xFF\xFF\x35"	; Sprite line 3

clear:  DB "\xFF\xFF\xFF\xFF"	; Blank line 0
		DB "\xFF\xFF\xFF\xFF"	; Blank line 1
		DB "\xFF\xFF\xFF\xFF"	; Blank line 2
		DB "\xFF\xFF\xFF\xFF"	; Blank line 3

pos:	DB 0		; Current row
		DB 0		; Current column
	
boot:
	MOV SP, 511		; Set SP
	MOV C, sprite	; Set to draw the sprite
	CALL draw		; Call drawing function
	MOV A, 1		; Set bit 0 of IRQMASK
	OUT 0			; Unmask keypad irq
	STI				; Enable interrupts
	HLT				; Halt execution

isr:
	PUSH A
	PUSH B
	IN 6			; Load KPDDATA register to A
	MOV B, [pos]	; Load position variable
	CMP A, 0x32		; If key pressed != 2 -> .not2
	JNZ .not2		; else
	DECB BH			; row--
	JNC .save		; if row < 0 -> .end
	JMP .end		; else -> .save position
.not2:
	CMP A, 0x34		; If key pressed != 4 -> .not4
	JNZ .not4		; else
	DECB BL			; column--
	JNC .save		; if column < 0 -> .end
	JMP .end		; else -> .save position
.not4:
	CMP A, 0x36		; If key pressed != 6 -> .not6
	JNZ .not6		; else
	INCB BL			; column++
	CMPB BL, 4		; if column == 4 -> .end
	JNZ .save		; else -> .save position
	JMP .end
.not6:	CMP A, 0x38	; If key pressed != 8 -> .end
	JNZ .end		; else
	INCB BH			; row++
	CMPB BH, 4		; if row == 4 -> .end
	JZ .end		
.save:
	MOV C, clear	; Set to clear the sprite
	CALL draw		; Call drawing function
	MOV [pos], B	; Store the new position
	MOV C, sprite	; Set to draw the sprite
	CALL draw		; Call drawing function
.end:
	MOV A, 1
	OUT 2		; Write to signal IRQEOI
	POP B
	POP A
	IRET			; Return from IRQ

draw:				; Draw (C: pointer to img)
	PUSH A
	PUSH B
	PUSH C
	PUSH D
	MOV D, 0x300	; Point register D to framebuffer
	MOV B, [pos]	; Load current position
	MOVB AL, 64		; Initial pixel =
	MULB BH			; row * 64 + column * 4
	ADD D, A	
	MOVB AL, 4
	MULB BL
	ADD D, A		; D points to initial pixel
	MOV A, C		; Point A to the image
	MOV C, 0		; CH: total pixel counter
.line:				; CL: line pixel counter\n
	MOVB BL, [A]	; Get pixel to print
	MOVB [D], BL	; Print pixel
	INC A
	INC D
	INCB CL
	INCB CH
	CMPB CL, 4		; End of current line?
	JNZ .line		; NO: keep drawing
	MOVB CL, 0		; YES: Next line
	ADD D, 12		; Pixel + 12 === CRLF
	CMPB CH, 16		; End of sprite?
	JNZ .line		; Jump back to .line if not
	POP D
	POP C
	POP B
	POP A
	RET
