	;*****************************************************************
	; update player
	;*****************************************************************

blocked:
	ldy #block-textbase
	jmp print_msg		; jsr print_msg + rts

open_door:
	lda #COLOR_UNSEEN
	sta cur_color
	lda #SCR_FLOOR
	jsr plot
	ldy #opened-textbase
	jmp print_msg		; jsr print_msg + rts

update_player:
	; handle movement
	ldy px
	ldx py
	; store old pos
	stx $0
	sty $1
	cmp #'W'
	beq @up
	cmp #'S'
	beq @down
	cmp #'A'
	beq @left
	cmp #'D'
	beq @right
	; cmp #'Z'
	; bne @nshoot
	; jsr move
	; ldx #1
	; jmp shoot
@nshoot:cmp #CHR_F1
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
	bpl @move		; can't use bne here, in case player is on left edge of map
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
	lda #SCR_PLAYER
	jsr plot		; draw player at new pos
	ldx $0			; restore old pos
	ldy $1
	lda #SCR_FLOOR		; erase old player
	jmp plot		; jsr print_msg + rts

enter_stairs:
	ldy #descend-textbase
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
	jsr add_score			; always clears carry
	bcc @skip			; always branches
@notgp:	tax
	lda mul3-SCR_POTION,x
	tax				; X = item type * 3
	lda potions,x
	cmp #'9'+$80			; max 9 items per type
	beq @skip
	inc potions,x 		
@skip:	ldy #found-textbase
	jsr print_msg
	pla				; restore X,Y
	tay
	pla
	tax
	bne movepl			; always branches

	;*****************************************************************
	; player attack, in: X,Y = target coordinates
	;*****************************************************************

player_attack:
	lda #1				; end invisibility
	sta invisibility		
	stx mon_y			; save target's coordinates
	sty mon_x
	lda (line_ptr),y
	sta cur_name			; store current monster
	jsr rand8
	cmp #PLAYER_ACCURACY
	bcc @hit
	ldy #youmiss-textbase
	jsr print_msg
	ldx mon_y			; restore X,Y
	ldy mon_x
	jmp miss_flash			; jsr miss_flash + rts
@done2:	rts

@wound: lda #COLOR_RED
	sta (color_ptr),y
	ldy #monwoun-textbase
	bne @pr	

 @hit:	ldy #youhit-textbase
	jsr print_msg
	ldx mon_y			; restore X,Y
	ldy mon_x
	jsr damage_flash
	jsr rand8
	cmp #$80
	bpl @done2			; 50% chance of not doing damage
	jsr rand8			; 50% chance of skipping wounded state
	cmp #$80
	bpl @nwound
	lda (color_ptr),y
	and #7
	cmp #COLOR_RED
	bne @wound			; monster wounded
@nwound:lda cur_name
	cmp #SCR_DEMON
	bne @killit
	dec demon_hp			; dec demon hp
	lda demon_hp
	bne @done2
	; remove enemy
@killit:lda flcolor
	sta cur_color
	lda #SCR_FLOOR
	jsr plot
	; drop loot
	lda cur_name
	cmp #SCR_SLIME
	beq @noloot			; slimes never drop loot
	jsr rand8
	cmp #LOOT_DROP
	bcs @noloot
	ldx mon_y			; restore X,Y
	ldy mon_x
	jsr random_loot
	; set loot color
	lda (line_ptr),y
	tay
	lda colors,y
	ldy mon_x
	sta (color_ptr),y
@noloot:lda #SCORE_MONSTER		; add score
	ldy cur_name
	cpy #SCR_DEMON
	bne @ndemon
	inc demons_killed
	lda dungeon_level		; no stairs on 18th level
	cmp #FINAL_LEVEL
	beq @nstair			
	ldy mon_x			; place stairs
	jsr move
	lda #SCR_STAIRS
	sta (line_ptr),y
	lda #COLOR_WHITE
	sta (color_ptr),y
@nstair:lda #SCORE_DEMON
@ndemon:jsr add_score
	ldy #mondies-textbase
	inc player_xp			; add xp
@pr:	jsr print_msg
	; win game when 3rd demon is killed
	lda demons_killed
	cmp #3
	beq wingame
	; check level up
	lda player_level
	asl
	asl
	asl				; required xp level * 8
	cmp player_xp
	bpl @done
	; level up
	lda player_level
	lsr
	bcs @nohp			; +2 hp every second level
	inc max_hp			
	inc max_hp
@nohp:	ldy #levelup-textbase
	jsr print_msg
	; level up effect
	jsr pause_music
	lda #150
	sta vic_soprano
	ldx #7
@floop: txa
	ldy #8
@floop2:sta COLOR_RAM,y
	inc vic_soprano
	dey
	bpl @floop2
	lda #7
	jsr delay2
	dex
	bne @floop
	jsr resume_music
	;
	inc player_level
	lda #0
	sta player_xp
	lda max_hp
	sta hp
	jsr update_hp
@done:	rts

	;*****************************************************************
	; win game
	;*****************************************************************

wingame:; clear screen effect
	ldx #0
@clear:	jsr rand8
	tay
	lda #SCR_SPACE
	sta SCREEN+22,y
	sta SCREEN+228,y
	lda #1
	jsr delay2
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
	ldy #youwin-textbase
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
	ldy #youdie-textbase
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
	ldx #5				; rebase characters to start from $80
@reb: 	lda SCREEN+16,x
	ora #$80
	sta SCREEN+16,x
	dex
	bpl @reb

@loop:	jsr waitkey			; wait space
	cmp #32
	bne @loop
	jmp start
