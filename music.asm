SONG_LENGTH	= 4	; must be power of two
PATTERN_LENGTH	= 16
TEMPO		= 40

	;*****************************************************************
	; init music
	;*****************************************************************

init_music:
	lda #0			; reset music position
	sta music_pos
	sta music_pos+1
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
	inc music_pos+1		; NOTE: music pos will overflow after 16 song rows!
@skip:

	; loop song
; 	lda music_pos+1
; 	cmp #SONG_LENGTH*PATTERN_LENGTH
; 	bmi @sok
; 	lda #0
; 	sta music_pos+1
; @sok:

	; pattern position
	lda music_pos+1
	and #PATTERN_LENGTH-1
	lsr
	sta pattern_pos
	lda #$f0		; note mask $f0
	bcc @skip2
	lda #$0f		; note mask $0f
@skip2:	sta note_mask

	; song position
	lda music_pos+1
	lsr
	lsr
	;and #$ff-3		; music pos / 4 * 4
	and #(SONG_LENGTH-1)*4
	tax			; x = song position * 4

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
	.byte $00,$00,$00,$07
	.byte $00,$00,$00,$07

	; note lookup tables
notelut:.byte $00,$9c,$bd,$b5,$c1,$a7,$ac	; bass & alto & soprano
noislut:.byte $00,$02,$e0			; noise
