	;*****************************************************************
	; Demons of Dex
	; A roguelike for the unexpanded VIC-20
	; (C) 2015 Petri Hakkinen. All rights reserved.
	;*****************************************************************

	; constants
	SCREEN 		= $1e00
	COLOR_RAM	= $9600
	SCREEN_WIDTH	= 22
	SCREEN_HEIGHT	= 23
	INITIAL_HP	= 6
	MAX_ENEMIES	= 16
	PLAYER_ACCURACY	= 140
	ENEMY_ACCURACY	= 70
	LOOT_DROP	= 30
	DEBUG		= 0		; set to 0 for strip debug code
	MUSIC		= 0

	; kernal routines
	CHROUT		= $ffd2
	PLOT		= $fff0
	GETIN		= $ffe4
	LINE_PTR	= $d1		; pointer to current line is stored in $d1-$d2
	CURSOR_X	= $d3
	CURSOR_Y	= $d6
	CUR_COLOR	= $0286

	; char codes
	CHR_WHITE	= 5
	CHR_RED		= 28
	CHR_GREEN	= 30
	CHR_BLUE	= 31
	CHR_BLACK	= 144
	CHR_PURPLE	= 156
	CHR_YELLOW	= 158
	CHR_CYAN	= 159
	CHR_DOWN	= 17
	CHR_UP		= 145
	CHR_LEFT 	= 157
	CHR_RIGHT	= 29
	CHR_HOME	= 19
	CHR_CLR_HOME	= 147
	CHR_HEART	= 64
	CHR_HALF_HEART	= 65
	CHR_DAMAGE	= 66
	CHR_WALL	= 67
	CHR_FLOOR	= 68
	CHR_DOOR	= 69
	CHR_STAIRS	= 70
	CHR_PLAYER	= 71
	CHR_POTION	= 72
	CHR_GEM		= 73
	CHR_SCROLL	= 74
	CHR_SKULL	= 75
	CHR_GOLD	= 76
	CHR_BAT		= 77
	CHR_RAT		= 78
	CHR_SNAKE	= 79
	CHR_ORC		= 80
	CHR_UNDEAD	= 81
	CHR_STALKER	= 82
	CHR_SLIME	= 83
	CHR_WIZARD	= 84
	CHR_DEMON	= 85

	; screen codes
	SCR_HEART	= 0
	SCR_HALF_HEART	= 1
	SCR_DAMAGE	= 2
	SCR_WALL	= 3
	SCR_FLOOR	= 4
	SCR_DOOR	= 5
	SCR_STAIRS	= 6
	SCR_PLAYER	= 7
	SCR_POTION	= 8
	SCR_GEM		= 9
	SCR_SCROLL	= 10
	SCR_SKULL	= 11
	SCR_GOLD	= 12
	SCR_BAT		= 13
	SCR_RAT		= 14
	SCR_SNAKE	= 15
	SCR_ORC		= 16
	SCR_UNDEAD	= 17
	SCR_STALKER	= 18
	SCR_SLIME	= 19
	SCR_WIZARD	= 20
	SCR_DEMON	= 21

	; color codes
	COLOR_BLACK	= 0
	COLOR_WHITE	= 1
	COLOR_RED	= 2
	COLOR_CYAN	= 3
	COLOR_PURPLE	= 4
	COLOR_GREEN	= 5
	COLOR_BLUE	= 6
	COLOR_YELLOW	= 7
	COLOR_UNSEEN	= COLOR_BLACK
	COLOR_EXPLORED	= COLOR_CYAN

	; zero page variables
	TMP_MX		= $6		; temp monster pos for enemy routines
	TMP_MY		= $7
	TMP_PRINT	= $8		; $8-$9 = temp pointer for print_msg
	PX		= $10
	PY		= $11
	RNDLOC_TMP	= $12
	COLOR_PTR	= $13		; $13-$14 = pointer to current line in color ram
	CUR_NAME	= $15		; current monster/item index for print
	DUNGEON_LEVEL	= $16
	GOLD		= $1b
	HP		= $1c
	TURN		= $1d
	MSG_TIME	= $1e		; last time print message was called

	; misc data
	ENEMY_X		= $0340		; tape buffer $033c-$03ff
	ENEMY_Y		= $0350
	POTIONS		= SCREEN+492	; item counts are stored in screen ram
	GEMS		= POTIONS+3
	SCROLLS		= GEMS+3
	SKULLS		= SCROLLS+3

	; VIC registers
	VIC_SCR_COLORS	= $900F

	.byt $01,$10			; PRG file header (starting address of the program)

	.org $1001			; start of basic program

	;*****************************************************************
	; basic stub
	;*****************************************************************

	; stub basic program
	.word bend 			; next line link
	.word 666        		; line number
	.byte $9e,52,49,48,57		; sys 4109
	.byte 0           		; end of line
bend:	.word 0           		; end of program

	;*****************************************************************
	; main program
	;*****************************************************************

start:	ldx #$ff			; empty stack (we never get back to basic)
	txs
	lda #8
	sta VIC_SCR_COLORS
	lda #$80			; turn on key repeat for all keys
	sta $028a
	lda #$ff			; set character base to $1c00
	sta $9005

	; init charset
	; TODO: this can be removed if charset is placed directly into data segment starting at $1c00
	ldx #0
@copy:  lda charset,x
	sta $1c00,x
	inx
	cpx #charset_end-charset
	bne @copy

	lda #CHR_CLR_HOME		; clear screen
	jsr CHROUT

	; init status bar
	lda #SCR_POTION
	sta POTIONS-1
	lda #SCR_GEM
	sta GEMS-1
	lda #SCR_SCROLL
	sta SCROLLS-1
	lda #SCR_SKULL
	sta SKULLS-1
	lda #COLOR_RED
	sta POTIONS-SCREEN+COLOR_RAM-1
	lda #COLOR_GREEN
	sta GEMS-SCREEN+COLOR_RAM-1
	lda #COLOR_PURPLE
	sta SCROLLS-SCREEN+COLOR_RAM-1
	lda #COLOR_YELLOW
	sta SKULLS-SCREEN+COLOR_RAM-1

	lda #'0'+$80			; init vars
	sta POTIONS
	sta GEMS
	sta SCROLLS
	sta SKULLS
	sta GOLD

	lda #1
	sta DUNGEON_LEVEL
	lda #INITIAL_HP
	sta HP
	lda #0
	sta TURN

	.if MUSIC
	jsr init_music
	.endif
	jsr random_level

	; reveal first area
	ldy PX
	ldx PY
	jsr reveal_area

	; draw welcome message
	ldx #<welcome
	ldy #>welcome
	jsr print_msg

	jsr update_hp

	; dump charset
	.if 0
	ldx #0
@loop:  txa
	sta SCREEN,x
	inx
	cpx #20
	bne @loop
	.endif

mainloop:
	jsr waitkey
	jsr update_player

	ldy PX
	ldx PY
	jsr reveal_area

	jsr update_enemies

	; test check walls
	.if 0
	ldy PX
	ldx PY
	jsr move
	jsr check_walls
	ldy #0
	ldx #1
	jsr move
	jsr print_hex
	.endif

	inc TURN
	jmp mainloop

	;*****************************************************************
	; include other source files
	;*****************************************************************

	.include "player.asm"
	.include "enemy.asm"
	.include "item.asm"
	.if MUSIC
	.include "music.asm"
	.endif

	;*****************************************************************
	; random level generator
	;*****************************************************************

random_level:
	jsr clearscreen

	lda #COLOR_UNSEEN
	sta CUR_COLOR

	; init walker
	; X,Y = x,y
	; $4,$5 = dx,dy
	; $6 = counter
	ldx #10		; x = 10
	ldy #11		; y = 11
	lda #1
	sta $4		; dx = 1
	lda #0
	sta $5		; dy = 0
	; size of level can be adjusted by changing counter's initial value
	sta $6		; counter = 0
	
	; random initial turn
	jsr rand8
	cmp #128
	bcc @turn

	; plot
@loop:	lda #CHR_FLOOR
	jsr plot

	;jsr delay

	; move walker
	txa
	clc
	adc $4		; x = x + dx
	tax
	tya
	clc
	adc $5		; y = y + dy
	tay
	inc $6		; counter++
	beq @done	; done when counter ovewflows

	; turn at edge
	cpx #2
	beq @turn
	cpy #1
	beq @turn
	cpx #20
	beq @turn
	cpy #20
	beq @turn

	; check random turn
	jsr rand8
	cmp #77
	bcs @loop

	; turn (dx,dy = dy,-dx)
@turn:	lda $5
	pha		; dy to stack
	lda #0
	sec
	sbc $4
	sta $5		; dy' = -dx
	pla
	sta $4		; dx' = dy

	jmp @loop

@done:	jsr init_doors
	jsr init_player
	jsr init_stairs
	jsr init_enemies
	jsr init_items
	rts

	;*****************************************************************
	; initialize stairs
	;*****************************************************************

init_stairs:
	jsr randomloc
	lda #CHR_STAIRS
	jsr plot
	rts

	;*****************************************************************
	; initialize doors
	;*****************************************************************

init_doors:
	; traverse the level and check walls at each floor cell
	ldx #20 		; X = row
@yloop:	ldy #20 		; Y = column
@xloop:	jsr move		; move cursor
	tya			; save Y
	pha
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	bne @skip
	jsr check_walls
	; check if bits match with a possible door location
	ldy #0
@chk:	cmp @doorbits,y
	beq @door
	iny
	cpy #@doorbits_end-@doorbits
	bne @chk
	beq @skip		; same as 'jmp @skip' but saves 1 byte
@door:	lda #CHR_DOOR
	jsr CHROUT
@skip:  pla			; restore Y
	tay	
	dey
	bne @xloop
	dex
	bne @yloop
	rts

@doorbits: .byte $d8,$8d,$63,$36,$8c,$c8,$23,$32,$22,$66,$27,$76
@doorbits_end: 

	;*****************************************************************
	; returns a bitmask encoding the walls of eight adjacent cells at cursor pos
	; bit on = wall, bit off = floor
	; in: (cursor pos)   out: A=bitmask    trashes: X,Y
	;*****************************************************************

check_walls:
	lda #0
	sta $0		; $0 = result bitmask
	tay		; Y = 0
@loop:	; move cursor
	lda @dirs,y
	beq @done
	iny
	jsr CHROUT
	asl $0		; shift left bitmask
	; read screen code under cursor
	tya		; save y
	pha
	ldy CURSOR_X
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	beq @floor
	; obstacle found, set bit
	inc $0
@floor: pla		; restore y
	tay
	jmp @loop
@done:	; restore cursor
	lda #CHR_RIGHT
	jsr CHROUT
	lda #CHR_DOWN
	jsr CHROUT
	lda $0		; result to A
	rts

@dirs:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_DOWN,CHR_LEFT,CHR_LEFT,CHR_UP,CHR_UP,0

	;*****************************************************************
	; reveal area, in: X,Y = row,col
	;*****************************************************************

reveal_area:
	jsr move

	; limit recursion depth (avoids stack overflow and also limits visibility somewhat)
	tsx
	cpx #$c0
	bcc @done
	ldx CURSOR_Y

	; fetch cell color, stop recursion if cell already revealed
	lda (COLOR_PTR),y
	and #7			; color ram is 4-bit wide, high nibble contains garbage
	cmp #COLOR_UNSEEN
	bne @done

	; reveal cell
	lda (LINE_PTR),y
	tax			; X = screen code to be revealed
	lda colors-SCR_WALL,x
	sta (COLOR_PTR),y
	ldx CURSOR_Y		; restore X

	; stop recursion at wall or door cell
	lda (LINE_PTR),y
	cmp #SCR_WALL
	beq @done
	cmp #SCR_DOOR
	beq @done

	txa			; save X,Y
	pha
	tya
	pha

	; recurse into neighbor cells
	dex			; up
	jsr reveal_area
	iny			; right
	jsr reveal_area
	inx			; down
	jsr reveal_area
	inx			; down
	jsr reveal_area
	dey			; left
	jsr reveal_area
	dey			; left
	jsr reveal_area
	dex			; up
	jsr reveal_area
	dex			; up
	jsr reveal_area

	pla			; restore X,Y
	tay
	pla
	tax

@done:	rts

	;*****************************************************************
	; moves cursor to row X, column Y
	;*****************************************************************

move:	pha		; store A,X,Y
	txa
	pha
	tya
	pha
	clc
	jsr PLOT	; trashes A,X,Y
	lda LINE_PTR	; update color pointer
	sta COLOR_PTR
	lda LINE_PTR+1
	clc
	adc #$96-$1e
	sta COLOR_PTR+1
	; update screen ptr (line ptr + cursx)
	; clc
	; lda LINE_PTR
	; adc CURSOR_X
	; sta SCREEN_PTR
	; lda LINE_PTR+1
	; adc #0
	; sta SCREEN_PTR+1
	;
	pla		; restore A,X,Y
	tay
	pla
	tax
	pla
	rts

	;*****************************************************************
	; plots a character in A at row X, column Y
	;*****************************************************************

plot:	jsr move
	jsr CHROUT
	rts

	;*****************************************************************
	; prints text at cursor using kernal
	; X,Y = address of text
	;*****************************************************************

print:	stx $0
	sty $1
	ldy #0
@loop:	lda ($0),y
	beq @done
	jsr CHROUT
	iny
	bne @loop	; same as 'jmp @loop' but saves 1 byte
@done:	rts

	;*****************************************************************
	; prints 8-bit hex number at cursor, in: A
	;*****************************************************************

	.if DEBUG
print_hex:
	tax
	lsr
	lsr
	lsr
	lsr
	tay
	lda @digits,y
	jsr CHROUT
	txa
	and #$f
	tay
	lda @digits,y
	jsr CHROUT
	rts

@digits: .byte "0123456789ABCDEF"
	.endif

	;*****************************************************************
	; prints message at the top of the screen
	; this assumes that color codes of 1st line have been set to white!
	; X,Y = address of text
	;*****************************************************************

print_msg:
	; prevent flooding messages on same turn
	lda MSG_TIME
	cmp TURN
	bne @skip
	jsr delay
@skip:	lda TURN
	sta MSG_TIME
	;
	stx TMP_PRINT
	sty TMP_PRINT+1
	ldx #0		; X = screen pos
	ldy #0		; Y = text pos 
@loop1: lda (TMP_PRINT),y
	beq @chk
	iny
	cmp #'%'
	beq @print_name
	and #$ff-64	; char to screen code
	ora #$80	; rebase screen codes to start from 128
	sta SCREEN,x
	inx
	bne @loop1
	; clear rest of the line
@loop2:	lda #32
	sta SCREEN,x
	inx
@chk:	cpx #22
	bne @loop2
@done:	rts

	; prints monster/item name
@print_name:
	tya		; save Y
	pha
	lda CUR_NAME
	asl
	asl
	asl
	tay
@mloop:	lda names-SCR_POTION*8,y
	beq @mdone
	iny
	and #$ff-64	; char to screen code
	ora #$80	; rebase screen codes to start from 128
	sta SCREEN,x
	inx
	bne @mloop
@mdone:	pla		; restore y
	tay		
	bne @loop1

	;*****************************************************************
	; damage flash at cursor
	;*****************************************************************

damage_flash:
	ldy CURSOR_X
	lda (LINE_PTR),y
	pha			; save char
	lda (COLOR_PTR),y
	pha			; save color
	lda #SCR_DAMAGE
	sta (LINE_PTR),y
	lda #COLOR_YELLOW
	sta (COLOR_PTR),y
	jsr delay
	pla			; restore color
	sta (COLOR_PTR),y	
	pla			; restore char
	sta (LINE_PTR),y	
	lda #0			; reset flood counter
	sta MSG_TIME
	rts

	;*****************************************************************
	; update hp
	;*****************************************************************

update_hp:
	; clear old hearts
	ldx #7
@loop1: lda #32+$80
	sta SCREEN+22*22-1,x
	lda #COLOR_RED
	sta COLOR_RAM+22*22-1,x
	dex
	bne @loop1
	; draw hearts
	lda HP
	lsr		; lowest bit of hp goes to carry
	tax		; does not affect carry
	bcc @skip 	; carry clear -> dont draw half heart
	lda #SCR_HALF_HEART
	sta SCREEN+22*22,x
@skip:	cpx #0
	beq @nohp
@loop2:	lda #SCR_HEART
	sta SCREEN+22*22-1,x
	dex
	bne @loop2
@nohp:	rts

	;*****************************************************************
	; clears the screen
	;*****************************************************************

clearscreen:
	; screen is 22*23 = 506 bytes long
	; to save bytes we clear two full pages (512 bytes)
	ldx #0
@loop:	lda #SCR_WALL
	sta SCREEN+22,x		; dont clear first line
	sta SCREEN+228,x	; dont clear last line
	lda #COLOR_UNSEEN
	sta COLOR_RAM+22,x
	sta COLOR_RAM+228,x
	inx
	bne @loop
	rts

	;*****************************************************************
	; short delay in busy loop
	;*****************************************************************

delay:	txa
	pha
	tya
	pha
	ldy #$ff
@delay1:ldx #$ff
@delay2:nop
	nop
	dex
	bne @delay2
	dey
	bne @delay1
	pla
	tay
	pla
	tax
	rts

	;*****************************************************************
	; simple 8-bit random number generator by White Flame (aka David Holz)
	; source: http://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
	;*****************************************************************

rand8:	lda seed
	beq do_eor
	asl
	beq no_eor 	; if the input was $80, skip the EOR
	bcc no_eor
do_eor:	eor #$1d	; TODO: randomize eor value (see codebase64.org for suitable values)
no_eor:	sta seed
	rts

seed:	.byte 0		; TODO: initialize seed from raster pos or timer value!

	;*****************************************************************
	; picks a random unoccupied location, returns: X=row, Y=column
	;*****************************************************************

randomloc:
	; pick random row
	jsr rand8
	and #31
	tax
	inx
	inx
	cpx #20
	bpl randomloc
	; pick random column
	lda #0
	sta RNDLOC_TMP		; max 256 tries on this row
@rndcol:jsr rand8
	and #31
	tay
	iny
	cmp #20
	bpl @rndcol
	; check that it is free
	jsr move
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	beq @done
	dec RNDLOC_TMP
	bne @rndcol
	beq randomloc  		; same as 'jmp randomloc' but saves 1 byte
@done:	rts

	;*****************************************************************
	; waits for a key press
	;*****************************************************************

waitkey:jsr GETIN
	cmp #0
	beq waitkey
	rts

	;*****************************************************************
	; data
	;*****************************************************************

welcome:.byte "DEMONS OF DEX",0
descend:.byte "DESCENDING...",0
youhit:	.byte "YOU HIT THE %!",0
youmiss:.byte "YOU MISS.",0
youdie: .byte "YOU DIE!",0
monhit: .byte "% HITS YOU!",0
monmiss:.byte "% MISSES!",0
mondie:	.byte "THE % DIES!",0
opened:	.byte "OPENED.",0
block:	.byte "BLOCKED.",0
found:	.byte "FOUND %.",0

	; monster and item names (the unused bytes could be used to store variables)
names:  .byte "POTION",0,0
	.byte "GEM",0,0,0,0,0
	.byte "SCROLL",0,0
	.byte "SKULL",0,0,0
	.byte "GOLD",0,0,0,0
	.byte "BAT",0,0,0,0,0
	.byte "RAT",0,0,0,0,0
	.byte "SNAKE",0,0,0
	.byte "ORC", 0,0,0,0,0
	.byte "UNDEAD",0,0
	.byte "STALKER",0
	.byte "SLIME",0,0,0
	.byte "WIZARD",0,0
	.byte "DEMON",0,0,0

	; user defined chars
charset:.byte $36,$7f,$7f,$7f,$3e,$1c,$08,$00	; (heart)
	.byte $30,$78,$78,$78,$38,$18,$08,$00	; (half heart)
	.byte $08,$2a,$1c,$3e,$1c,$2a,$08,$00	; * damage
	.byte $aa,$55,$aa,$55,$aa,$55,$aa,$55	; # wall
	.byte $00,$00,$00,$00,$00,$18,$18,$00	; . floor
	.byte $ff,$f7,$f7,$c1,$f7,$f7,$ff,$ff	; + door
	.byte $70,$18,$0c,$06,$0c,$18,$70,$00	; > stairs
	.byte $1c,$22,$4a,$56,$4c,$20,$1e,$00	; @ player
	.byte $08,$08,$08,$08,$00,$00,$08,$00	; ! potion
	.byte $08,$1c,$3e,$7f,$3e,$1c,$08,$00	; (gem)
	.byte $3c,$42,$02,$0c,$10,$00,$10,$00	; ? scroll
	.byte $30,$48,$48,$30,$4a,$44,$3a,$00	; & skull
	.byte $08,$1e,$28,$1c,$0a,$3c,$08,$00	; $ gold
	.byte $40,$40,$5c,$62,$42,$62,$5c,$00	; b bat
	.byte $00,$00,$5c,$62,$40,$40,$40,$00	; r rat
	.byte $00,$00,$3e,$40,$3c,$02,$7c,$00	; s snake
	.byte $00,$00,$3c,$42,$42,$42,$3c,$00	; o orc
	.byte $00,$00,$7e,$04,$18,$20,$7e,$00	; z undead
	.byte $00,$00,$00,$00,$00,$00,$00,$00	;   stalker
	.byte $3c,$42,$40,$3c,$02,$42,$3c,$00	; S slime
	.byte $1c,$22,$4a,$56,$4c,$20,$1e,$00	; @ wizard
	.byte $78,$24,$22,$22,$22,$24,$78,$00	; D demon
charset_end:

colors:	;.byte COLOR_RED			; (heart)
	;.byte COLOR_RED			; (half heart)
	;.byte COLOR_RED			; * damage
	.byte COLOR_CYAN			; # wall
	.byte COLOR_CYAN			; . floor
	.byte COLOR_CYAN			; + door
	.byte COLOR_WHITE			; > stairs
	.byte COLOR_WHITE			; @ player
	.byte COLOR_RED				; ! potion
	.byte COLOR_GREEN			; (gem)
	.byte COLOR_PURPLE			; ? scroll
	.byte COLOR_YELLOW			; & skull
	.byte COLOR_YELLOW			; $ gold
	.byte COLOR_RED				; b bat
	.byte COLOR_RED				; r rat
	.byte COLOR_GREEN			; s snake
	.byte COLOR_GREEN			; o orc
	.byte COLOR_WHITE			; z undead
	.byte COLOR_BLACK			;   stalker
	.byte COLOR_GREEN			; S slime
	.byte COLOR_PURPLE			; @ wizard
	.byte COLOR_YELLOW			; D demon
