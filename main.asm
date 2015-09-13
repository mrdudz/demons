;*****************************************************************
; Demons of Dex
; A roguelike for the unexpanded VIC-20
; (C) 2015 Petri Hakkinen. All rights reserved.
;*****************************************************************

SCREEN 		= $1e00
COLOR_RAM	= $9600

; constants
INITIAL_HP	= 6
PLAYER_ACCURACY	= 140
ENEMY_ACCURACY	= 80
LOOT_DROP	= 30
INVISIBLE_TIME	= 45
DEMON_HP	= 3
SCORE_MONSTER	= 1
SCORE_GOLD	= 10
SCORE_DEMON	= 100
MSG_DELAY	= 25		; message delay length in 1/60 seconds
DEBUG		= 0		; set to 0 for strip debug code
MUSIC		= 0

; special levels
STALKER_LEVEL	= 6
FINAL_LEVEL	= 18

; kernal routines
PRINT_INT	= $ddcd		; print 16-bit integer in X/A (undocumented basic routine)
CHROUT		= $ffd2
GETIN		= $ffe4
PLOT		= $fff0

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
CHR_F1		= 133
CHR_F3		= 134
CHR_F5		= 135
CHR_F7		= 136
CHR_HALF_HEART	= 64
CHR_ANKH	= 65
CHR_WALL	= 66
CHR_FLOOR	= 67
CHR_DOOR	= 68
CHR_SECRET_DOOR	= 69
CHR_STAIRS	= 70
CHR_PLAYER	= 71
CHR_POTION	= 72
CHR_GEM		= 73
CHR_SCROLL	= 74
CHR_SKULL	= 75
CHR_GOLD	= 76
CHR_BAT		= 77
CHR_RAT		= 78
CHR_WORM	= 79
CHR_SNAKE	= 80
CHR_ORC		= 81
CHR_UNDEAD	= 82
CHR_STALKER	= 83
CHR_SLIME	= 84
CHR_WIZARD	= 85
CHR_DEMON	= 86

; screen codes
SCR_HALF_HEART	= 0
SCR_ANKH	= 1
SCR_WALL	= 2
SCR_FLOOR	= 3
SCR_DOOR	= 4
SCR_SECRET_DOOR	= 5
SCR_STAIRS	= 6
SCR_PLAYER	= 7
SCR_POTION	= 8
SCR_GEM		= 9
SCR_SCROLL	= 10
SCR_SKULL	= 11
SCR_GOLD	= 12
SCR_BAT		= 13
SCR_RAT		= 14
SCR_WORM	= 15
SCR_SNAKE	= 16
SCR_ORC		= 17
SCR_UNDEAD	= 18
SCR_STALKER	= 19
SCR_SLIME	= 20
SCR_WIZARD	= 21
SCR_DEMON	= 22
SCR_SPACE 	= 32 + $80
SCR_0	 	= 48 + $80
SCR_DAMAGE	= 42 + $80
SCR_MISS_H	= 45 + $80
SCR_MISS_V	= 93 + $80
SCR_HEART	= 83 + $80

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
print_tmp	= $2		; $2-$3 = temp pointer for print_msg
walker_dx	= $4		; level generator
walker_dy	= $5
px		= $6		; player
py		= $7
hp		= $8
max_hp		= $9
invisibility	= $a
dungeon_level	= $b
gold		= $c
turn		= $d
score		= $e		; $e-$f = 16-bit score
demons_killed	= $10
demon_hp	= $11
rndloc_tmp	= $12
color_ptr	= $13		; $13-$14 = pointer to current line in color ram
cur_name	= $15		; current monster/item index for print
msg_time	= $1f		; last time print message was called
mon_x		= $20		; current monster position
mon_y		= $21
mon_color	= $23
random_seed	= $24		; TODO: initialize seed from raster pos or jiffy clock
delay_length	= $25
delay_tmp	= $26		; temp for delay routine
reveal_x	= $27		; reveal area vars
reveal_y 	= $28
reveal_dx	= $29
reveal_dy 	= $30
reveal_tmp	= $31
damage_char	= $32		; temp for damage flash
tempo_counter	= $33
pattern_row	= $34		; current row 0-31
pattern_row2	= $35		; pattern row/2
song_pos	= $36
note_mask	= $37		; temp for music routine
line_ptr	= $d1		; $d1-$d2 pointer to current line (updated by Kernal)
cursor_x	= $d3
cursor_y	= $d6

; other variables
; NOTE: unused memory in tape buffer $033c-$03ff
blocked_cells	= $0100		; 22 byte temp array in stack page for enemy update routine
cur_color	= $0286		; color for CHROUT
potions		= SCREEN+492	; item counts are stored in screen ram
gems		= potions+3
scrolls		= gems+3
skulls		= scrolls+3

; VIC registers
vic_scr_center	= $9000
vic_colors	= $900f

	.byt $01,$10			; PRG file header (starting address of the program)

	.org $1001			; start of basic program

	;*****************************************************************
	; basic stub
	;*****************************************************************

	; stub basic program
	.word bend 			; next line link
	.word 2015        		; line number
	.byte $9e,52,49,48,57		; sys 4109
	.byte 0           		; end of line
bend:	.word 0           		; end of program

	;*****************************************************************
	; main program
	;*****************************************************************

start:	ldx #$ff			; empty stack (we never get back to basic)
	txs
	lda #8
	sta vic_colors
	lda #$80			; turn on key repeat for all keys
	sta $028a
	lda #$ff			; set character base to $1c00
	sta $9005

	; init charset
	ldx #0
@copy:  lda charset,x
	sta $1c00,x
	inx
	cpx #charset_end-charset
	bne @copy

	lda #CHR_CLR_HOME		; clear screen
	jsr CHROUT

	; init zero page vars to zero
	ldx #$50
	lda #0
@zp:	sta $0,x
	dex
	bpl @zp

	; init status bar
	ldx #21
@stat:	lda statscr,x
	sta SCREEN+22*22+7,x
	lda statcol,x
	sta COLOR_RAM+22*22,x
	dex
	bpl @stat

	; init game vars
	inc dungeon_level
	lda #INITIAL_HP
	sta hp
	sta max_hp
	lda #MSG_DELAY
	sta delay_length

	jsr update_hp
	.if MUSIC
	jsr init_music
	.endif
	jsr random_level

	; draw welcome message
	ldx #<welcome
	ldy #>welcome
	jsr print_msg

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
	jsr reveal
	jsr update_enemies

	; test check walls
	.if 0
	ldy px
	ldx py
	jsr move
	jsr check_walls
	ldy #0
	ldx #1
	jsr move
	jsr print_hex
	.endif

	; update invisibility
	dec invisibility
	bne @skip
	lda #COLOR_WHITE
	sta plcolor
@skip:

	inc turn
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
	sta cur_color

	; init walker
	ldx #10			; x = 10
	ldy #11			; y = 11
	lda #1
	sta walker_dx		; dx = 1
	lda #0
	sta walker_dy		; dy = 0
	; size of level can be adjusted by changing counter's initial value
	sta $0			; counter = 0
	
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
	adc walker_dx		; x = x + dx
	tax
	tya
	clc
	adc walker_dy		; y = y + dy
	tay
	inc $0			; counter++
	beq @done		; done when counter ovewflows

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
@turn:	lda walker_dy
	pha			; dy to stack
	lda #0
	sec
	sbc walker_dx
	sta walker_dy		; dy' = -dx
	pla
	sta walker_dx		; dx' = dy

	jmp @loop

@done:	jsr init_doors
	jsr init_player
	jsr init_stairs
	jsr init_enemies
	jsr init_items

	; test level for reveal routine
	.if 0
	ldx #1
	lda #SCR_FLOOR
@floop: sta $1e00+22*2,x
	sta $1e00+22*3,x
	sta $1e00+22*4,x
	sta $1e00+22*5,x
	sta $1e00+22*6,x
	sta $1e00+22*7,x
	sta $1e00+22*8,x
	sta $1e00+22*9,x
	sta $1e00+22*10,x
	sta $1e00+22*11,x
	sta $1e00+22*12,x
	sta $1e00+22*13,x
	sta $1e00+22*14,x
	sta $1e00+22*15,x
	sta $1e00+22*16,x
	sta $1e00+22*17,x
	inx
	cpx #21
	bne @floop
	jsr init_player
	.endif

	lda #DEMON_HP	; init demon hp
	sta demon_hp

	jmp reveal	; jsr reveal + rts

	;*****************************************************************
	; initialize stairs
	;*****************************************************************

init_stairs:
	jsr randomloc
	; replace stairs with demon on special levels
	lda dungeon_level
	cmp #6
	beq @demon
	cmp #12
	beq @demon
	cmp #18
	beq @demon
	lda #CHR_STAIRS
	bne @plot		; always branches
@demon:	lda #CHR_DEMON
@plot:	jmp plot		; jmp + rts

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
	lda (line_ptr),y
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
	beq @skip		; always branches
@door:	; choose door type
	ldy #CHR_DOOR		; place normal door by default
	lda dungeon_level
	cmp #STALKER_LEVEL
	beq @sdoor		; all doors are secret on stalker level
	bmi @pr			; no secret door before stalker level
	jsr rand8		; small chance of placing secret doors after stalker level
	cmp #0
	bne @pr
@sdoor:	ldy #CHR_SECRET_DOOR	; place secret door
@pr:	tya
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
	ldy cursor_x
	lda (line_ptr),y
	cmp #SCR_FLOOR
	beq @floor
	; obstacle found, set bit
	inc $0
@floor: pla		; restore y
	tay
	bne @loop	; always branches
@done:	; restore cursor
	lda #CHR_RIGHT
	jsr CHROUT
	lda #CHR_DOWN
	jsr CHROUT
	lda $0		; result to A
	rts

@dirs:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_DOWN,CHR_LEFT,CHR_LEFT,CHR_UP,CHR_UP,0

	;*****************************************************************
	; reveal area
	; inspired by Aleksi Eeben's Whack
	;*****************************************************************

reveal:	lda #1			; top-right segment
	sta reveal_dx
	lda #$ff
	sta reveal_dy
	jsr @doseg

	lda #1			; bottom-right segment
	sta reveal_dy
	jsr @doseg

	lda #$ff		; bottom-left segment
	sta reveal_dx
	jsr @doseg

	lda #$ff		; top-left segment
	sta reveal_dy
	;jsr @doseg
	;rts

@doseg:	; horiz pass
	ldy px			; start at player
	ldx py
@hloop:	jsr move
	jsr @reveal_cell
	beq @vert		; done if blocked
	ldy reveal_x		; restore X,Y
	ldx reveal_y
	tya			; step x
	clc
	adc reveal_dx
	tay
	bpl @hloop		; always branches

	; vert pass
@vert:	ldy px			; start at player
	ldx py
@vloop:	jsr move
	jsr @reveal_cell
	beq @block		; done if blocked
	ldy reveal_x		; restore X,Y
	ldx reveal_y
	txa			; step y
	clc
	adc reveal_dy
	tax
	bne @vloop		; always branches
@block:	rts

@reveal_cell:
	sty reveal_x
	stx reveal_y
	; reveal cell
	jsr @mark_cell_visible
	; stop at wall or door cell
	cpx #SCR_WALL
	beq @end
	cpx #SCR_DOOR
	beq @end
	cpx #SCR_SECRET_DOOR
	beq @end
	; --- spawn diagonal ray ---
	ldy reveal_x
	ldx reveal_y
@diag:	jsr move
	; reveal cell
	stx reveal_tmp		; save X
	jsr @mark_cell_visible	; trashes X
	; stop at wall or door cell
	cpx #SCR_WALL
	beq @end2
	cpx #SCR_DOOR
	beq @end2
	cpx #SCR_SECRET_DOOR
	beq @end2
	ldx reveal_tmp		; restore X
	; step diagonally
	tya
	clc
	adc reveal_dx
	tay
	txa
	clc
	adc reveal_dy
	tax
	;jsr delay
	bpl @diag		; always branch
@end2:	lda #1			; clear Z
@end:	; Z set if blocked
	rts

@mark_cell_visible:
	lda (line_ptr),y
	tax			; X = screen code to be revealed
	lda (color_ptr),y
	and #7
	cmp #COLOR_UNSEEN	; don't touch already seen blocks (preserves monster colors)
	bne @skip
	lda colors,x
	sta (color_ptr),y
@skip:	rts

	;*****************************************************************
	; reveal area, in: X,Y = row,col
	;*****************************************************************

	.if 0
reveal_area:
	jsr move

	; limit recursion depth (avoids stack overflow and also limits visibility somewhat)
	tsx
	cpx #$c0
	bcc @done
	ldx cursor_y

	; fetch cell color, stop recursion if cell already revealed
	lda (color_ptr),y
	and #7			; color ram is 4-bit wide, high nibble contains garbage
	cmp #COLOR_UNSEEN
	bne @done

	; reveal cell
	lda (line_ptr),y
	tax			; X = screen code to be revealed
	lda colors,x
	sta (color_ptr),y
	ldx cursor_y		; restore X

	; stop recursion at wall or door cell
	lda (line_ptr),y
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
	.endif

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
	lda line_ptr
	sta color_ptr
	lda line_ptr+1
	clc
	adc #$96-$1e
	sta color_ptr+1
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
	;sta (line_ptr),y
	;lda cur_color
	;sta (color_ptr),y
	rts

	;*****************************************************************
	; prints text at cursor using kernal
	; X,Y = address of text
	;*****************************************************************

	.if 0
print:	stx $0
	sty $1
	ldy #0
@loop:	lda ($0),y
	beq @done
	jsr CHROUT
	iny
	bne @loop	; always branches
@done:	rts
	.endif

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
	lda msg_time
	cmp turn
	bne print_msg2
	jsr delay
print_msg2:
	lda turn
	sta msg_time
	stx print_tmp
	sty print_tmp+1
	ldx #0		; X = screen pos
	ldy #0		; Y = text pos 
@loop1: lda (print_tmp),y
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
	ldy cur_name	; Y = monster/item index
	lda nameoff,y
	tay		; Y = start of name offset
@mloop:	lda names,y
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
	lda #SCR_DAMAGE
	ldy #COLOR_YELLOW
damage_flash2:
	sta damage_char
	sty cur_color
	ldy cursor_x
	lda (line_ptr),y
	pha			; save char
	lda (color_ptr),y
	pha			; save color
	lda damage_char
	sta (line_ptr),y
	lda cur_color
	sta (color_ptr),y
	jsr delay
	pla			; restore color
	sta (color_ptr),y	
	pla			; restore char
	sta (line_ptr),y	
	lda #0			; reset flood counter
	sta msg_time
	rts

miss_flash:
	lda px
	cmp mon_x
	beq @ver
	lda #SCR_MISS_H
	bne @hor		; always branch
@ver:	lda #SCR_MISS_V
@hor:	ldy #COLOR_WHITE
	jmp damage_flash2	; jsr damage_flash2 + rts

	;*****************************************************************
	; update hp
	;*****************************************************************

update_hp:
	; clear old hearts
	ldx #7
@loop1: lda #SCR_SPACE
	sta SCREEN+22*22-1,x
	dex
	bne @loop1
	; draw hearts
	lda hp
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
	; short delay about half a second, trashes: A
	;*****************************************************************

delay:	lda $a2
	sta delay_tmp
@loop:	sec
	lda $a2
	sbc delay_tmp
	cmp delay_length
	bcc @loop
	rts

	;*****************************************************************
	; simple 8-bit random number generator by White Flame (aka David Holz)
	; source: http://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
	;*****************************************************************

rand8:	lda random_seed
	beq do_eor
	asl
	beq no_eor 	; if the input was $80, skip the EOR
	bcc no_eor
do_eor:	eor #$1d	; TODO: randomize eor value (see codebase64.org for suitable values)
no_eor:	sta random_seed
	rts

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
	sta rndloc_tmp		; max 256 tries on this row
@rndcol:jsr rand8
	and #31
	tay
	iny
	cmp #20
	bpl @rndcol
	; check that it is free
	jsr move
	lda (line_ptr),y
	cmp #SCR_FLOOR
	beq @done
	dec rndloc_tmp
	bne @rndcol
	beq randomloc  		; always branches
@done:	rts

	;*****************************************************************
	; waits for a key press
	;*****************************************************************

waitkey:jsr GETIN
	cmp #0
	beq waitkey
	rts

	;*****************************************************************
	; increase score by A
	;*****************************************************************

add_score:
	clc
	adc score
	sta score
	bcc @skip
	inc score+1
@skip:	rts

	;*****************************************************************
	; data
	;*****************************************************************

welcome:.byte "DEMONS OF DEX",0
descend:.byte "DESCENDING",0
youhit:	.byte "YOU HIT THE %!",0
youmiss:.byte "YOU MISS.",0
youdie: .byte "YOU DIE! SCORE:",0
monhit: .byte "% HITS YOU!",0
monmiss:.byte "% MISSES!",0
mondie:	.byte "THE % IS DEAD!",0
mondies:.byte "% DIES!",0
monwoun:.byte "% IS WOUNDED!",0
opened:	.byte "OPENED.",0
block:	.byte "BLOCKED.",0
found:	.byte "FOUND %.",0
outof:	.byte "NO %S.",0
useitem:.byte "USING %...",0
usepot:	.byte "HEALED!",0
usegem:	.byte "A VISION!",0
usescr:	.byte "TURNED INVISIBLE!",0
useskul:.byte "CHAOS!",0
youwin:	.byte "YOU WIN! SCORE:",0

	; initial contents of status bar area in screen ram and color ram
statscr:.byte SCR_POTION,SCR_0,SCR_SPACE,SCR_GEM,SCR_0,SCR_SPACE,SCR_SCROLL,SCR_0,SCR_SPACE,SCR_SKULL,SCR_0,SCR_SPACE,SCR_SPACE,SCR_SPACE,SCR_SPACE
statcol:.byte 2,2,2,2,2,2,2,2,1,1,5,1,1,4,1,1,7,1,1,1,1,1

	; monster and item names
names:
_potion:.byte "POTION",0
_gem:	.byte "GEM",0
_scroll:.byte "SCROLL",0
_skull:	.byte "SKULL",0
_gold:	.byte "GOLD",0
_bat:	.byte "BAT",0
_rat:	.byte "RAT",0
_worm:	.byte "WORM",0
_snake:	.byte "SNAKE",0
_orc:	.byte "ORC",0
_undead:.byte "UNDEAD",0
_stalke:.byte "STALKER",0
_slime:	.byte "SLIME",0
_wizard:.byte "WIZARD",0
_demon:	.byte "DEMON",0

	; name offsets
nameoff = _nameof-SCR_POTION
_nameof:.byte _potion-names
	.byte _gem-names
	.byte _scroll-names
	.byte _skull-names
	.byte _gold-names
	.byte _bat-names
	.byte _rat-names
	.byte _worm-names
	.byte _snake-names
	.byte _orc-names
	.byte _undead-names
	.byte _stalke-names
	.byte _slime-names
	.byte _wizard-names
	.byte _demon-names

	; user defined chars
charset:.byte $30,$78,$78,$78,$38,$18,$08,$00	; (half heart)
ankh:	.byte $1c,$22,$22,$14,$08,$3e,$08,$08	; (ankh)
	.byte $aa,$55,$aa,$55,$aa,$55,$aa,$55	; # wall
	.byte $00,$00,$00,$00,$00,$18,$18,$00	; . floor
	.byte $ff,$f7,$f7,$c1,$f7,$f7,$ff,$ff	; + door
	.byte $aa,$55,$aa,$5d,$aa,$55,$aa,$55	; (secret door)
	.byte $70,$18,$0c,$06,$0c,$18,$70,$00	; > stairs
	.byte $1c,$22,$4a,$56,$4c,$20,$1e,$00	; @ player
	.byte $08,$08,$08,$08,$00,$00,$08,$00	; ! potion
	.byte $08,$1c,$3e,$7f,$3e,$1c,$08,$00	; (gem)
	.byte $3c,$42,$02,$0c,$10,$00,$10,$00	; ? scroll
	.byte $30,$48,$48,$30,$4a,$44,$3a,$00	; & skull
	.byte $08,$1e,$28,$1c,$0a,$3c,$08,$00	; $ gold
	.byte $40,$40,$5c,$62,$42,$62,$5c,$00	; b bat
	.byte $00,$00,$5c,$62,$40,$40,$40,$00	; r rat
	.byte $00,$00,$41,$49,$49,$49,$36,$00	; w worm
	.byte $00,$00,$3e,$40,$3c,$02,$7c,$00	; s snake
	.byte $00,$00,$3c,$42,$42,$42,$3c,$00	; o orc
	.byte $00,$00,$7e,$04,$18,$20,$7e,$00	; z undead
	.byte $00,$00,$00,$00,$00,$00,$00,$00	;   stalker
	.byte $3c,$42,$40,$3c,$02,$42,$3c,$00	; S slime
	.byte $1c,$22,$4a,$56,$4c,$20,$1e,$00	; @ wizard
	.byte $78,$24,$22,$22,$22,$24,$78,$00	; D demon
charset_end:

colors = _colors-SCR_WALL
_colors:.byte COLOR_CYAN			; # wall
	.byte COLOR_CYAN			; . floor
	.byte COLOR_CYAN			; + door
	.byte COLOR_CYAN			; (secret door)
	.byte COLOR_WHITE			; > stairs
plcolor:.byte COLOR_WHITE			; @ player
	.byte COLOR_RED				; ! potion
	.byte COLOR_GREEN			; (gem)
	.byte COLOR_PURPLE			; ? scroll
	.byte COLOR_YELLOW			; & skull
	.byte COLOR_YELLOW			; $ gold
	.byte COLOR_RED				; b bat
	.byte COLOR_RED				; r rat
	.byte COLOR_WHITE			; w worm
	.byte COLOR_GREEN			; s snake
	.byte COLOR_GREEN			; o orc
	.byte COLOR_WHITE			; z undead
	.byte COLOR_WHITE			;   stalker
	.byte COLOR_GREEN			; S slime
	.byte COLOR_PURPLE			; @ wizard
	.byte COLOR_PURPLE			; D demon
