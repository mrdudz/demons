	;*****************************************************************
	; initialize player
	;*****************************************************************

init_player:
	ldx #10
	ldy #11
	stx py
	sty px
	lda #CHR_PLAYER
	jmp plot	; jsr plot + rts

	;*****************************************************************
	; update player
	;*****************************************************************

update_player:
	; handle movement
	ldy px
	ldx py
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
	cmp #CHR_F1
	bne @skipf1
	jmp use_potion
@skipf1:cmp #CHR_F3
	bne @skipf3
	jmp use_gem
@skipf3:cmp #CHR_F5
	bne @skipf5
	jmp use_scroll
@skipf5:cmp #CHR_F7
	bne @skipf7
	jmp use_skull
@skipf7:rts

@up:	dex
	bne @move		; always branches
@down:	inx
	bne @move		; always branches
@left:	dey
	bne @move		; always branches
@right:	iny

@move:	; X,Y = move target
	jsr move
	; check obstacle
	lda (line_ptr),y
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
movepl:	sty px			; store new pos
	stx py
	lda #COLOR_UNSEEN
	sta cur_color
	lda #CHR_PLAYER
	jsr plot		; draw player at new pos
	ldx $0			; restore old pos
	ldy $1
	lda #CHR_FLOOR		; erase old player
	jmp plot		; jsr print_msg + rts

blocked:
	ldx #<block
	ldy #>block
	jmp print_msg		; jsr print_msg + rts

open_door:
	lda #COLOR_UNSEEN
	sta cur_color
	lda #CHR_FLOOR
	jsr plot
	ldx #<opened
	ldy #>opened
	jmp print_msg		; jsr print_msg + rts

enter_stairs:
	ldx #<descend
	ldy #>descend
	jsr print_msg
	inc dungeon_level
	jmp random_level	; jsr random_level + rts

pickup_item:
	txa				; save X,Y
	pha
	tya
	pha
	lda (line_ptr),y		; store name
	sta cur_name
	cmp #SCR_GOLD
	bne @notgp
	; gold found
	lda #SCORE_GOLD
	jsr add_score
	jmp @skip
@notgp:	tax
	lda mul3-SCR_POTION,x
	tax				; X = item type * 3
	lda potions,x
	cmp #'9'+$80			; max 9 items per type
	beq @skip
	inc potions,x 		
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
	lda #COLOR_WHITE
	sta plcolor			; end invisibility
	stx mon_y			; save target's coordinates
	sty mon_x
	lda (line_ptr),y
	sta cur_name			; store current monster
	jsr rand8
	cmp #PLAYER_ACCURACY
	bcc @hit
	ldx #<youmiss
	ldy #>youmiss
	jsr print_msg
	ldx mon_y			; restore X,Y
	ldy mon_x
	jmp miss_flash			; jsr miss_flash + rts
	;rts
 @hit:	ldx #<youhit
	ldy #>youhit
	jsr print_msg
	ldx mon_y			; restore X,Y
	ldy mon_x
	jsr damage_flash
	lda (color_ptr),y
	and #7
	cmp #COLOR_RED
	bne @wound			; monster wounded
	; remove enemy
@killit:lda #COLOR_EXPLORED
	sta cur_color
	lda #CHR_FLOOR
	jsr plot
	; drop loot
	jsr rand8
	cmp #LOOT_DROP
	bcs @noloot
	ldx mon_y			; restore X,Y
	ldy mon_x
	jsr random_loot
	; set loot color
	and #$ff-64
	tay
	lda colors,y
	ldy mon_x
	sta (color_ptr),y
@noloot:lda #SCORE_MONSTER		; add score
	ldy cur_name
	cpy #SCR_DEMON
	bne @ndemon
	inc demons_killed
	lda #SCORE_DEMON
	; TODO: place stairs!
@ndemon:jsr add_score
	ldx #<mondie
	ldy #>mondie
@pr:	jsr print_msg			; jsr print_msg + rts
	lda demons_killed		; win game when 3rd demon is killed
	cmp #3
	beq wingame
	rts

@wound: jsr rand8			; 50% chance of killing when monster is wounded
	cmp #$80
	bpl @killit
	lda #COLOR_RED
	sta (color_ptr),y
	ldx #<monwoun
	ldy #>monwoun
	bne @pr	

	;*****************************************************************
	; win game
	;*****************************************************************

wingame:; clear screen effect
	lda #1			; set smaller delay
	sta delay_length
	ldx #0
@clear:	jsr rand8
	tay
	lda #SCR_SPACE
	sta SCREEN+22,y
	sta SCREEN+228,y
	jsr delay
	dex
	bne @clear
	; draw ankh
	ldx #6		; X = row
@yloop:	ldy #6		; Y = column
	jsr move	; move cursor to top-left corner on screen
	lda #$80
	sta $0
@xloop:	lda ankh-6,x
	and $0
	beq @skip
	lda #35+$80
	sta (line_ptr),y
	lda #COLOR_WHITE
	sta (color_ptr),y
@skip:	lda $0
	lsr
	sta $0
	iny
	cpy #6+8
	bne @xloop
	inx
	cpx #6+8
	bne @yloop
	; you win
	ldx #<youwin
	ldy #>youwin
	bne gameover	; always branches

	;*****************************************************************
	; player damage
	;*****************************************************************

player_damage:
	dec hp
	jsr update_hp
	lda hp
	beq player_die
	rts

player_die:
	ldx #<youdie
	ldy #>youdie
gameover:
	jsr print_msg
	; print score
	lda #COLOR_YELLOW
	sta cur_color
	ldx #0
	ldy #16
	jsr move
	ldx score
	lda score+1
	jsr PRINT_INT
	lda #'0'			; print extra zero so that scores look higher
	jsr CHROUT
	ldx #6				; rebase characters to start from $80
@reb: 	lda SCREEN+16,x
	ora #$80
	sta SCREEN+16,x
	dex
	bpl @reb

@loop:	jsr waitkey			; wait space
	cmp #32
	bne @loop
	jmp start
