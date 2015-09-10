SONG_LENGTH	= 2
PATTERN_LENGTH	= 16
TEMPO		= 2

	;*****************************************************************
	; init music
	;*****************************************************************

init_music:
	lda #0			; reset music position
	sta music_pos
	sta song_pos
	lda #15			; set music volume
	sta $900e
	sei
	lda #<irq
	sta $0314
	lda #>irq
	sta $0315
	cli
	rts

	;*****************************************************************
	; music interrupt handler
	;*****************************************************************

irq:	lda music_pos		; increment music pos
	clc
	adc #TEMPO 
	sta music_pos
	bcc @skip
	; increment song pos
	inc song_pos
	lda song_pos
	cmp #SONG_LENGTH
	bne @skip
	lda #0
	sta song_pos
@skip:

	; pattern position
	lda music_pos
	lsr
	lsr
	lsr
	lsr			; A = pattern position
	lsr			; A = pattern position/2
	sta pattern_pos
	lda #$f0		; note mask $f0
	bcc @skip2
	lda #$0f		; note mask $0f
@skip2:	sta note_mask

	; song position
	lda song_pos
	asl
	asl
	tax			; x = song position * 4

	.if 0
	; print patterns
	pha
	lda song,x
	clc
	adc #'0'+$80
	sta SCREEN
	lda song+1,x
	clc
	adc #'0'+$80
	sta SCREEN+1
	lda song+2,x
	clc
	adc #'0'+$80
	sta SCREEN+2
	lda song+3,x
	clc
	adc #'0'+$80
	sta SCREEN+3
	pla
	.endif

	; play bass
	lda song,x		; A = bass pattern
	jsr dochan
	sta $900a

	; play alto
	lda song+1,x		; A = alto pattern
	jsr dochan
	sta $900b

	; play soprano
	lda song+2,x		; A = soprano pattern
	jsr dochan
	sta $900c

	; play noise
	lda song+3,x		; A = noise pattern
	jsr dochan
	lda noislut,y		; noise uses a different lut
	sta $900d

	;inc $900f
	jmp $eabf

dochan:	; in: A = pattern
	asl
	asl
	asl
	ora pattern_pos		; A = pattern * 8 | pattern_pos
	tay
	lda paterns,y		; A = packed note
	; unpack note
	ldy note_mask
	bpl @low
	and #$f0
	lsr
	lsr
	lsr
	lsr
	jmp @high
@low:	and #$0f
@high:	tay
	lda notelut,y
	rts

	; pattern data, max 256 bytes (32 patterns * 8 bytes/pattern)
paterns:.byte $10,$00,$10,$10,$00,$10,$10,$00	; bass 1
	.byte $10,$10,$00,$10,$10,$00,$10,$10	; bass 2
	.byte $10,$10,$20,$00,$00,$10,$20,$30	; alto 1
	.byte $10,$10,$20,$00,$00,$10,$20,$40	; alto 2
	.byte $20,$02,$00,$20,$42,$00,$00,$00	; soprano 1
	.byte $00,$00,$00,$00,$10,$10,$50,$60	; soprano 2
	.byte $10,$00,$20,$00,$10,$10,$20,$00	; noise 1
	.byte $10,$00,$20,$00,$10,$10,$20,$10	; noise 2

	; song data, 4 bytes per row
song:	.byte $00,$02,$04,$06
	.byte $01,$03,$05,$07

	; note lookup tables
notelut:.byte $00,$9c,$bd,$b5,$c1,$a7,$ac	; bass & alto & soprano
noislut:.byte $00,$02,$e0			; noise
