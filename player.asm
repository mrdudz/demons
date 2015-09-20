	;*****************************************************************
	; update player
	;*****************************************************************

update_player:
	; store old pos
	ldy px
	ldx py
	stx $0
	sty $1
	;
	;
use_potion:
	cmp #CHR_F1
	bne use_gem
	lda #0
	jsr use_item
	bcs rts1
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	ldx #128
@sfx:	stx vic_bass
	lda #1
	jsr delay2
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	lda max_hp
	sta hp
	jsr update_hp
	ldy #usepot-textbase
	jmp print_msg		; jsr + rts

use_gem:
	cmp #CHR_F3
	bne use_scroll
	lda #1
	jsr use_item
	bcs rts1
	lda #93
	sta $900f
	; play sound
	jsr pause_music
	ldx #50
@sfx:	jsr rand8
	ora #$80
	sta vic_soprano
	lda #1
	jsr delay2
	dex
	bne @sfx
	;
	jsr resume_music	
	ldx #1
	jsr @gemreveal
	ldx #11
	jsr @gemreveal
	lda #8
	sta $900f
	ldy #usegem-textbase
	jmp print_msg		; jsr + rts

@gemreveal: ; reveal 256 bytes
	ldy #0
	jsr move
@loop:	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	bne @skip
	lda (line_ptr),y
	tax
	lda colors,x
	sta (color_ptr),y
@skip:	iny
	bne @loop
rts1:	rts

use_scroll:
	cmp #CHR_F5
	bne use_skull
	lda #2
	jsr use_item
	bcs rts1
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	ldx #192
@sfx:	stx vic_soprano
	lda #1
	jsr delay2
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	lda #INVISIBLE_TIME
	sta invisibility
	lda #COLOR_BLUE
	sta plcolor
	ldy px
	ldx py
	jsr move
	sta (color_ptr),y
	ldy #usescr-textbase
	jmp print_msg		; jsr + rts

use_skull:
	cmp #CHR_F7
	bne move_player
	lda #3
	jsr use_item
	bcs rts1
	ldy #useskul-textbase
	jsr print_msg
	jsr tremor
	; kill visible monsters
	ldx #1
	jsr @killall
	ldx #11
	jsr @killall
	jmp resume_music	; jsr + rts

@killall: ; reveal 256 bytes
	ldy #0
	jsr move
	ldx #0
@kloop:	jsr rand8
	tay
	lda (line_ptr),y
	sta cur_name
	cmp #SCR_BAT
	bmi @skip		; skip non-monster cells
	cmp #SCR_DEMON
	bpl @skip		; demons are immune to skulls
	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	beq @skip		; skip unseen cells
	; kill
	sty cursor_x
	txa
	pha
	jsr damage_flash
	ldy #mondies-textbase
	jsr print_msg
	pla
	tax
	ldy cursor_x
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda flcolor
	sta (color_ptr),y
	lda #50
	jsr delay2
@skip:	dex
	bne @kloop
	rts

move_player:
	cmp #'W'
	beq up
	cmp #'S'
	beq down
	cmp #'A'
	beq left
	cmp #'D'
	beq right
	.if ZAP
	cmp #'Z'
	bne @nzap
	jmp zap			; TODO: inline code
@nzap:	.endif
	rts

up:	dex
	bne trymove		; always branches
down:	inx
	bne trymove		; always branches
left:	dey
	bpl trymove		; can't use bne here, in case player is on left edge of map
right:	iny

trymove:jsr move		; X,Y = move target
	; check obstacle
	lda (line_ptr),y
	cmp #SCR_WALL
	bne @nblock
	; blocked
	ldy #block-textbase
	jmp print_msg		; jsr print_msg + rts
@nblock:cmp #SCR_STAIRS
	beq enter_stairs
	cmp #SCR_DOOR
	bne @nopen
	; open door
	lda #COLOR_UNSEEN
	sta cur_color
	lda #SCR_FLOOR
	jsr plot
	ldy #opened-textbase
	jmp print_msg		; jsr print_msg + rts
@nopen:	cmp #SCR_BAT
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
	; sound effect
	jsr pause_music
	lda #235
	sta vic_soprano
	lda #5
	jsr delay2
	lda #245
	sta vic_soprano
	lda #5
	jsr delay2
	jsr resume_music
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
	beq @nwound			; monster already wounded
	lda #COLOR_RED
	sta (color_ptr),y
	ldy #monwoun-textbase
	bne @pr				; always branches
@nwound:lda cur_name
	cmp #SCR_DEMON
	bne @killit
	dec demon_hp			; dec demon hp
	bne @done2
	jsr tremor			; demon died
	jsr resume_music
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
	lda #7
	sta cur_color
@loop:	ldx #6		; X = row
@yloop:	ldy #6		; Y = column
	jsr move	; move cursor to top-left corner on screen
	lda #$80
	sta $0
@xloop:	lda ankh-6,x
	and $0
	beq @skip
	lda #SCR_ANKH
	sta (line_ptr),y
	lda cur_color
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
	lda #10
	jsr delay2
	dec cur_color
	bne @loop
	; you win
	ldy #youwin-textbase
	bne gameover	; always branches

	;*****************************************************************
	; player damage
	;*****************************************************************

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

player_damage:
	dec hp
	jsr update_hp
	lda hp
	beq player_die
rts3:	rts

	;*****************************************************************
	; zap staff
	;*****************************************************************

	.if ZAP
zap:	jsr move
	ldy #askdir-textbase
	jsr print_msg
@waitkb:jsr waitkey
	ldx #0
@loop:	cmp wdsa,x
	beq shoot
	inx
	cpx #4
	beq @waitkb		; invalid key
	bne @loop		; always branch
	;
	;
	.endif

	;*****************************************************************
	; shoot projectile
	; X = direction (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

shoot:	stx shoot_dir
	lda projch,x
	sta shoot_char
	lda cursor_x			; store cursor
	pha
	lda cursor_y
	pha
@loop:	ldx shoot_dir
	jsr movedir
	lda (line_ptr),y		; check obstacle
	;cmp #SCR_BAT
	;bpl @hitenemy
	cmp #SCR_PLAYER
	beq @hitplayer
	cmp #SCR_FLOOR
	bne @block
	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	beq @block
	lda shoot_char
	sta (line_ptr),y
	lda #COLOR_WHITE
	sta (color_ptr),y
	lda #4
	jsr delay2
	bcs @loop			; always branch (delay2 always sets carry)
@block:	; erase projectile
	pla				; restore cursor
	tax
	pla
	tay
	jsr move
@loop2:	ldx shoot_dir
	jsr movedir
	lda (line_ptr),y		; check obstacle
	cmp shoot_char
	bne rts3
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda flcolor
	sta (color_ptr),y
	lda #4
	jsr delay2
	bcs @loop2			; always branch (delay2 always sets carry)

; @hitenemy:
; 	jsr damage_flash
; 	jmp @block

@hitplayer:
	jsr damage_flash
	jsr player_damage
	jmp @block
