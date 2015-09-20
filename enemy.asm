	;*****************************************************************
	; update enemy, in: X,Y = current position
	;*****************************************************************

update_enemy:
	lda cur_name
	cmp #SCR_SLIME
	beq slime_update
	cmp #SCR_WIZARD
	beq wiz_update
	; move up
monupd:	cpx py			
	bmi @skip1
	beq @skip1
	ldx #0			
	jsr move_enemy
	bcc @done		; done if moved
@skip1: ; move right
	cpy px			
	bpl @skip2
	beq @skip2
	ldx #1			
	jsr move_enemy
	bcs @skip2
	; moving right is tricky: skip next cell to prevent monster getting updated twice
	iny
	rts
@skip2:	; move down
	cpx py			
	bpl @skip3
	beq @skip3
	ldx #2			
	jsr move_enemy
	bcs @skip3		; done if moved
	; moving down is tricky: we have to mark the cell to prevent monster getting updated again in same turn
	lda #$ff
	sta blocked_cells,y
	rts
@skip3:	; move left
	cpy px			
	bmi @done
	beq @done
	ldx #3			
	jsr move_enemy
@done:	rts

	;*****************************************************************
	; wizard update
	;*****************************************************************

wiz_update:			; try to shoot in random direction
	lda #WIZARD_TRIGGER
	sta shoot_counter
@tloop:	jsr movemon
	jsr rand8
	and #3
	sta shoot_dir
@loop:	ldx shoot_dir
	jsr movedir
	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	beq @fail		; unseen cell -> can't shoot
	lda (line_ptr),y
	cmp #SCR_PLAYER
	beq @shoot
	cmp #SCR_FLOOR
	beq @loop
@fail:	jsr movemon
	dec shoot_counter
	bne @tloop
	beq monupd		; always branch

@shoot:	jsr movemon
	ldx shoot_dir
	jsr shoot
	;
	;

	;*****************************************************************
	; move cursor to current monster position
	;*****************************************************************

movemon:ldy mon_x
	ldx mon_y
	jmp move

	;*****************************************************************
	; slime update
	;*****************************************************************

slime_update:			; slimes move randomly
	jsr rand8
	and #7
	cmp #6
	bpl monupd		; -> move
	cmp #4
	bpl rts4
	tax
	;
	;

	;*****************************************************************
	; moves enemy at cursor towards a direction, in:
	; X = direction (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

move_enemy:
	; check obstacles
	jsr movedir
	lda (line_ptr),y
	cmp #SCR_PLAYER
	beq enemy_attack
	cmp #SCR_FLOOR
	bne @block		; blocked
	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	beq @block		; can't move to unseen cells
	; draw monster to new cell
	lda mon_color
	sta (color_ptr),y
	lda cur_name
	sta (line_ptr),y
	cmp #SCR_SLIME
	beq @skip
	; clear monster from old cell
	jsr movemon
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda flcolor
	sta (color_ptr),y
@skip:	clc			; success => clear carry
	rts

@block: jsr movemon		; move cursor back
	sec			; blocked => set carry
rts4:	rts

	;*****************************************************************
	; enemy attacks player
	;*****************************************************************

enemy_attack:
	jsr rand8
	cmp #ENEMY_ACCURACY
	bcc @hit
	; miss
	ldy #monmiss-textbase
	jsr print_msg
	ldx py
	ldy px
	jsr move
	jsr miss_flash
	beq @end		; always branches (assumes that miss_flash sets Z=1)
@hit:	; hit
	ldy #monhit-textbase
	jsr print_msg
	ldx py
	ldy px
	jsr move
	jsr damage_flash
	jsr player_damage
@end:	jsr movemon		; restore X,Y
	clc			; success => clear carry
	rts
