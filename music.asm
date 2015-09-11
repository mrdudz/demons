PATTERN_LENGTH	= 32
TEMPO		= 32
VOLUME		= 0		; music muted!

	;*****************************************************************
	; init music
	;*****************************************************************

init_music:
	lda #VOLUME		; set music volume
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

irq:	lda tempo_counter	; increment music pos
	clc
	adc #TEMPO 
	sta tempo_counter
	bcc @skip
	; tempo counter overflow -> increment pattern row
	inc pattern_row
	lda pattern_row
	cmp #PATTERN_LENGTH	; sets carry
	bne @skip
	lda #0
	sta pattern_row
	; pattern row overflow -> increment song pos
	lda song_pos
	;clc			; carry is always set here
	adc #1
	cmp #songend-song
	bne @skips
	; song pos overflow -> loop back
	lda #0
@skips:	sta song_pos
@skip:

	; pattern position
	lda pattern_row
	lsr			; A = pattern position/2
	sta pattern_row2
	lda #$f0		; note mask $f0
	bcc @skip2
	lda #$0f		; note mask $0f
@skip2:	sta note_mask

	ldx song_pos		; x = song position

	; play bass
	lda song,x		; A = bass pattern
	lsr
	lsr
	lsr
	lsr
	jsr dochan
	sta $900a

	; play alto
	lda song,x		; A = alto pattern
	and #$f
	jsr dochan
	sta $900b

	; play soprano
	lda song+1,x		; A = soprano pattern
	lsr
	lsr
	lsr
	lsr
	jsr dochan
	sta $900c

	; play noise
	lda song+1,x		; A = noise pattern
	and #$f
	jsr dochan
	lda noislut,y		; noise uses a different lut
	sta $900d

	;inc $900f
	jmp $eabf

dochan:	; in: A = pattern
	asl
	asl
	asl
	asl
	ora pattern_row2	; A = pattern * 5 | pattern_pos
	tay
	lda paterns,y		; A = packed note
	; unpack note
	ldy note_mask
	bpl @low
	;and #$f0
	lsr
	lsr
	lsr
	lsr
	jmp @high
@low:	and #$0f
@high:	tay
	lda notelut,y
	rts

	; pattern data, 256 bytes (16 patterns * 16 bytes/pattern)
paterns:.byte $10,$00,$10,$10,$00,$10,$10,$00,$10,$10,$00,$10,$10,$00,$10,$10	; bass
	.byte $10,$10,$20,$00,$00,$10,$20,$30,$10,$10,$20,$00,$00,$10,$20,$40	; alto
	.byte $20,$02,$00,$20,$42,$00,$00,$00,$00,$00,$00,$00,$10,$10,$50,$60	; soprano
	.byte $10,$00,$20,$00,$10,$10,$20,$00,$10,$00,$20,$00,$10,$10,$20,$10	; noise
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	; song data, 2 bytes per row
song:	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
	.byte $01,$23
	.byte $00,$03
songend:

	; note lookup tables
notelut:.byte $00,$9c,$bd,$b5,$c1,$a7,$ac,$00,$00,$00,$00,$00,$00,$00,$00,$00	; bass & alto & soprano
noislut:.byte $00,$02,$e0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	; noise
