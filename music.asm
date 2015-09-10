TEMPO = 40

; TODO: change pattern length to 16 rows

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
	inc music_pos+1
@skip:

	; pattern position
	lda music_pos+1
	and #31			; pattern size
	lsr
	tax
	lda #$f0		; note mask $f0
	bcc @skip2
	lda #$0f		; note mask $0f
@skip2:	sta note_mask

	; play bass
	lda bass,x
	jsr unpack_note
	sta $900a

	; play alto
	lda alto,x
	jsr unpack_note
	sta $900b

	; play soprano
	lda soprano,x
	jsr unpack_note
	sta $900c

	; play noise
	lda noise,x
	jsr unpack_note
	lda noislut,y		; noise uses a different lut
	sta $900d

	;inc $900f
	jmp $eabf

unpack_note:
	; in: A = note
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

bass:	.byte $10,$00,$10,$10,$00,$10,$10,$00,$10,$10,$00,$10,$10,$00,$10,$10
alto:	.byte $10,$10,$20,$00,$00,$10,$20,$30,$10,$10,$20,$00,$00,$10,$20,$40
soprano:.byte $20,$02,$00,$20,$42,$00,$00,$00,$00,$00,$00,$00,$10,$10,$50,$60
noise:	.byte $10,$00,$20,$00,$10,$10,$20,$00,$10,$00,$20,$00,$10,$10,$20,$10

notelut:.byte $00,$9c,$bd,$b5,$c1,$a7,$ac
noislut:.byte $00,$02,$e0
