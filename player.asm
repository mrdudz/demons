	;*****************************************************************
	; initialize player
	;*****************************************************************

init_player:
	ldx #10
	ldy #11
	stx PY
	sty PX
	lda #CHR_PLAYER
	jsr plot
	rts

	;*****************************************************************
	; update player
	;*****************************************************************

update_player:
	; handle movement
	ldy PX
	ldx PY
	; store old pos
	stx $0
	sty $1
	cmp #'W' ;CHR_UP
	beq @up
	cmp #'S' ;CHR_DOWN
	beq @down
	cmp #'A' ;CHR_LEFT
	beq @left
	cmp #'D' ;CHR_RIGHT
	beq @right
	rts

@up:	dex
	jmp @move
@down:	inx
	jmp @move
@left:	dey
	jmp @move
@right:	iny

@move:	; X,Y = move target
	jsr move
	; check obstacle
	lda (LINE_PTR),y
	cmp #SCR_WALL
	beq blocked
	cmp #SCR_STAIRS
	beq enter_stairs
	cmp #SCR_DOOR
	beq open_door
	cmp #SCR_BAT
	bpl player_attack
	cmp #SCR_POTION
	bpl pickup_item

	; move player to X,Y
movepl:	sty PX			; store new pos
	stx PY
	lda #COLOR_UNSEEN
	sta CUR_COLOR
	lda #CHR_PLAYER
	jsr plot		; draw player at new pos
	ldx $0			; restore old pos
	ldy $1
	lda #CHR_FLOOR
	jsr plot		; erase old player
	rts

blocked:
	ldx #<block
	ldy #>block
	jsr print_msg
	rts

open_door:
	lda #COLOR_UNSEEN
	sta CUR_COLOR
	lda #CHR_FLOOR
	jsr plot
	jsr reveal_area
	ldx #<opened
	ldy #>opened
	jsr print_msg
	rts

enter_stairs:
	ldx #<descend
	ldy #>descend
	jsr print_msg
	inc DUNGEON_LEVEL
	jsr random_level
	rts

pickup_item:
	txa				; save X,Y
	pha
	tya
	pha
	lda (LINE_PTR),y		; store name
	sta CUR_NAME
	tax
	lda mul3-SCR_POTION,x
	tax				; X = item type * 3
	lda POTIONS,x
	cmp #'9'+$80			; max 9 items per type
	beq @skip
	inc POTIONS,x 		
@skip:	ldx #<found			; print found
	ldy #>found
	jsr print_msg
	pla				; restore X,Y
	tay
	pla
	tax
	jmp movepl

mul3:	.byte 0,3,6,9

	;*****************************************************************
	; player attack, in: X,Y = target coordinates
	;*****************************************************************

player_attack:
	lda (LINE_PTR),y
	sta CUR_NAME			; store current monster
	jsr rand8
	cmp #PLAYER_ACCURACY
	bcc @hit
	ldx #<youmiss
	ldy #>youmiss
	bne @pr				; same as 'jmp @pr' but saves 1 byte
 @hit:	stx TMP_MY			; save X,Y
	sty TMP_MX
	ldx #<youhit
	ldy #>youhit
	jsr print_msg
	ldx TMP_MY			; restore X,Y
	ldy TMP_MX
	jsr damage_flash
	jsr remove_enemy
	; drop loot
	jsr rand8
	cmp #LOOT_DROP
	bcs @noloot
	ldx TMP_MY			; restore X,Y
	ldy TMP_MX
	jsr random_loot
	; set loot color
	and #$ff-64
	tay
	lda colors-SCR_WALL,y
	ldy TMP_MX
	sta (COLOR_PTR),y
@noloot:ldx #<mondie
	ldy #>mondie
@pr:	jsr print_msg
	rts

	;*****************************************************************
	; player damage
	;*****************************************************************

player_damage:
	dec HP
	jsr update_hp
	lda HP
	beq player_die
	rts

player_die:
	ldx #<youdie
	ldy #>youdie
	jsr print_msg
@loop:	jsr waitkey	; wait space
	cmp #32
	bne @loop
	jmp start
	