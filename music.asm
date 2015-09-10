TEMPO = 40

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
	and #31
	tax

	; play note
	lda bass,x
	sta $900a
	lda alto,x
	sta $900b
	lda soprano,x
	sta $900c
	lda noise,x
	sta $900d

	;inc $900f
	jmp $eabf

bass:	.byte $9c,$00,$00,$00,$9c,$00,$9c,$00,$00,$00,$9c,$00,$9c,$00,$00,$00
	.byte $9c,$00,$9c,$00,$00,$00,$9c,$00,$9c,$00,$00,$00,$9c,$00,$9c,$00

alto:	.byte $9c,$00,$9c,$00,$bd,$00,$00,$00,$00,$00,$9c,$00,$bd,$00,$b5,$00
	.byte $9c,$00,$9c,$00,$bd,$00,$00,$00,$00,$00,$9c,$00,$bd,$00,$c1,$00

soprano:.byte $bd,$00,$00,$bd,$00,$00,$bd,$00,$c1,$bd,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$9c,$00,$9c,$00,$a7,$00,$ac,$00

noise:	.byte $02,$00,$00,$00,$e0,$00,$00,$00,$02,$00,$02,$00,$e0,$00,$00,$00
	.byte $02,$00,$00,$00,$e0,$00,$00,$00,$02,$00,$02,$00,$e0,$00,$02,$00
