;*****************************************************************
; Demons of Dex
; A roguelike for the unexpanded VIC-20
; (C) 2015 Petri Hakkinen. All rights reserved.
;*****************************************************************

SCREEN 		= $1e00
COLOR_RAM	= $9600

; constants
INITIAL_HP	= 6
PLAYER_ACCURACY	= 200
ENEMY_ACCURACY	= 80
LOOT_DROP	= 50
INVISIBLE_TIME	= 45
DEMON_HP	= 3
SCORE_MONSTER	= 1
SCORE_GOLD	= 10
SCORE_DEMON	= 100
DEFAULT_DELAY	= 25		; default delay value for delay routine in 1/60 seconds
WIZARD_TRIGGER	= 3		; wizard trigger happiness, higher the value the more often wizards shoot
SECRET_DOOR	= 7		; secret door probability after stalker level
DEBUG		= 0		; set to 0 for strip debug code
MUSIC		= 1

; levels
START_LEVEL	= 0
DEMON_LEVEL1	= 4
STALKER_LEVEL	= 9
DEMON_LEVEL2	= 9
FINAL_LEVEL	= 14

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

; screen codes
SCR_HALF_HEART	= 0 + 42
SCR_WALL	= 1 + 42
SCR_FLOOR	= 2 + 42
SCR_DOOR	= 3 + 42
SCR_SECRET_DOOR	= 4 + 42
SCR_STAIRS	= 5 + 42
SCR_PLAYER	= 6 + 42
SCR_POTION	= 7 + 42
SCR_GEM		= 8 + 42
SCR_SCROLL	= 9 + 42
SCR_ANKH	= 10 + 42
SCR_GOLD	= 11 + 42
SCR_BAT		= 12 + 42
SCR_RAT		= 13 + 42
SCR_WORM	= 14 + 42
SCR_SNAKE	= 15 + 42
SCR_ORC		= 16 + 42
SCR_UNDEAD	= 17 + 42
SCR_STALKER	= 18 + 42
SCR_WIZARD	= 19 + 42
SCR_SLIME	= 20 + 42
SCR_DEMON	= 21 + 42
SCR_SPACE 	= 32 + $80
SCR_0	 	= 48 + $80
SCR_DAMAGE	= 42 + $80
SCR_MISS_X	= 45 + $80
SCR_MISS_Y	= 93 + $80
SCR_HEART	= 83 + $80
SCR_PROJ_X	= 45 + $80
SCR_PROJ_Y	= 93 + $80

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

; zero page variables
;		= $2
;		= $3
walker_dx	= $4		; level generator
walker_dy	= $5
px		= $6		; player
py		= $7
hp		= $8
max_hp		= $9
player_level	= $a
player_xp	= $b
invisibility	= $c
dungeon_level	= $d
gold		= $e
turn		= $f
score		= $10		; $10-$11 = 16-bit score
demons_killed	= $12
demon_hp	= $13
rndloc_tmp	= $14
color_ptr	= $15		; $15-$16 = pointer to current line in color ram
cur_name	= $17		; current monster/item index for print
msg_time	= $18		; last time print message was called
mon_x		= $19		; current monster position
mon_y		= $1a
mon_color	= $1b
random_seed	= $1c		; TODO: initialize seed from raster pos or jiffy clock
delay_length	= $1d
delay_tmp	= $1e		; temp for delay routine
reveal_x	= $1f		; reveal area vars
reveal_y 	= $20
reveal_dx	= $21
reveal_dy 	= $22
reveal_tmp	= $23
damage_char	= $24		; temp for damage flash
tempo_counter	= $25
pattern_row	= $26		; current row 0-31
pattern_row2	= $27		; pattern row/2
song_pos	= $28
note_mask	= $29		; temp for music routine
mute_music	= $2a
text_color	= $2b		; text color for print
min_spawn	= $2c		; init enemies
max_spawn	= $2d
shoot_dir	= $2e
shoot_char	= $2f
shoot_counter	= $30
line_ptr	= $d1		; $d1-$d2 pointer to current line (updated by Kernal)
cursor_x	= $d3
cursor_y	= $d6

; other variables
cassette_buffer = $033c		; $033c-$03ff
charset		= $1d50		; address of first char in the user defined charset (vic base address is $1c00)
blocked_cells	= $0100		; 22 byte temp array in stack page for enemy update routine
cur_color	= $0286		; color for CHROUT
potions		= SCREEN+492	; item counts are stored in screen ram
gems		= potions+3
scrolls		= gems+3
skulls		= scrolls+3

; VIC registers
vic_scr_center	= $9000
vic_bass	= $900a
vic_alto	= $900b
vic_soprano	= $900c
vic_noise	= $900d
vic_volume	= $900e
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

coldstart:
	; copy chars segment to cassette buffer
	ldx #0
@copy:	lda charset+8,x			
	sta cassette_buffer,x
	inx
	bne @copy

	; init charset
	lda #<(charset+8)			; $2-$3 = dest pointer in chars segments
	sta $2
	lda #>(charset+8)
	sta $3
	ldx #0
@cloop: lda charadr,x			; $0-$1 = src pointer in char ROM
	sta $0
	lda charadr+1,x
	sta $1
	ldy #7				; copy char data
@chars: lda ($0),y			
	sta ($2),y
	dey
	bpl @chars
	inx				; next char
	inx
	lda $2
	adc #8				; carry is always zero here
	sta $2
@skip:	cpx #charadr_end-charadr
	bne @cloop
	lda #$5d			; secret door char
	sta charset+4*8+3

start:	ldx #$ff			; empty stack (we never get back to basic)
	txs
	lda #8
	sta vic_colors
	lda #$80			; turn on key repeat for all keys
	sta $028a
	lda #$ff			; set character base to $1c00
	sta $9005

	; init zero page vars to zero
	ldx #$50
	lda #0
@zp:	sta $0,x
	dex
	bpl @zp

	; clear screen
	lda #CHR_CLR_HOME		; clear screen
	jsr CHROUT
	ldx #0
@clear:	lda #SCR_SPACE
	sta SCREEN,x
	sta SCREEN+256,x
	inx
	bne @clear

	.if MUSIC
	lda #15				; set music volume
	sta vic_volume
	sei
	lda #<irq
	sta $0314
	lda #>irq
	sta $0315
	cli
	.endif

	; title screen
titles:	jsr rand8			; random text color
	and #1
	tax
	lda titlec,x
	sta text_color
	ldy #0
	ldx #6
	jsr move
	ldx #0
	ldy #3				; x offset
	jsr print_title
	; code
	lda #COLOR_YELLOW
	sta text_color
	inx
	ldy #1+22*5			; x offset
	jsr print_title
	; music
	inx
	ldy #1+22*7			; x offset
	jsr print_title
	lda #6
	jsr delay2
	jsr GETIN
	cmp #0
	beq titles

	; init game vars
	inc player_level
	.if START_LEVEL
	lda #START_LEVEL
	sta dungeon_level
	.endif
	lda #INITIAL_HP
	sta hp
	sta max_hp

	jsr random_level
	jsr update_hp

	; init status bar
	ldx #21
@stat:	lda statscr,x
	sta SCREEN+22*22+7,x
	lda statcol,x
	sta COLOR_RAM+22*22,x
	dex
	bpl @stat

	; dump charset
	.if 0
	ldx #0
@loop:  txa
	sta SCREEN,x
	lda #COLOR_WHITE
	sta COLOR_RAM,x
	inx
	bne @loop
@e:	jmp @e
	.endif

mainloop:
	jsr waitkey
	jsr update_player

	; update invisibility
	dec invisibility
	bne @skip
	lda #COLOR_WHITE
	sta plcolor
	ldx py
	ldy px
	jsr move
	sta (color_ptr),y
@skip:

	jsr reveal
	;
	;
update_enemies:
	lda plcolor
	cmp #COLOR_BLUE
	beq @done		; player is invisible
	; clear blocked cells array
	ldx #21
	lda #0
@clear:	sta blocked_cells,x
	dex
	bpl @clear
	ldx #2			; X = row
@yloop:	ldy #1			; Y = column
@xloop: jsr move
	lda (line_ptr),y
	cmp #SCR_BAT
	bmi @skip		; skip non-enemy cells
	sta cur_name		; store monster
	stx mon_y
	sty mon_x
	lda (color_ptr),y
	and #7
	sta mon_color
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN	; skip unseen cells
	.endif
	beq @skip
	lda blocked_cells,y
	beq @skipb		; skip monsters in 'blocked' cells
	; monster is in a blocked cell (downward movement) -> unblock cell and skip update
	lda #0
	sta blocked_cells,y
	beq @skip		; always branches
@skipb:	jsr update_enemy
@skip:	iny
	cpy #21
	bne @xloop
	inx			; next row
	cpx #21
	bne @yloop
@done:	
	
	inc turn
	jmp mainloop

	;*****************************************************************
	; include other source files
	;*****************************************************************

	.include "player.asm"
	.include "enemy.asm"
	.include "item.asm"
	.include "music.asm"

	;*****************************************************************
	; random level generator
	;*****************************************************************

random_level:
	; clear map area
	ldx #0
@clear:	lda #SCR_WALL
	sta SCREEN+22,x
	sta SCREEN+228,x
	lda #COLOR_UNSEEN
	sta COLOR_RAM+22,x
	sta COLOR_RAM+228,x
	inx
	bne @clear

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
@loop:	lda #SCR_FLOOR
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
	beq init_doors		; done when counter ovewflows

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
	;
	;
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

	; compute bitmask encoding the walls of eight adjacent cells at cursor pos (bit on = wall, bit off = floor)
	lda #0
	sta $0			; $0 = result bitmask
	tay			; Y = 0
@loop:	; move cursor
	lda drdirs,y
	beq @done
	iny
	jsr CHROUT
	asl $0			; shift left bitmask
	; read screen code under cursor
	tya			; save y
	pha
	ldy cursor_x
	lda (line_ptr),y
	cmp #SCR_FLOOR
	beq @floor
	; obstacle found, set bit
	inc $0
@floor: pla			; restore y
	tay
	bne @loop		; always branches
@done:	; restore cursor
	lda #CHR_RIGHT
	jsr CHROUT
	lda #CHR_DOWN
	jsr CHROUT
	lda $0			; bitmask to A

	; check if bits match with a possible door location
	ldy #0
@chk:	cmp drbits,y
	beq @door
	iny
	cpy #drbits_end-drbits
	bne @chk
	beq @skip		; always branches
@door:	; choose door type
	ldy #SCR_DOOR		; place normal door by default
	lda dungeon_level
	cmp #STALKER_LEVEL
	beq @sdoor		; all doors are secret on stalker level
	bmi @pr			; no secret door before stalker level
	jsr rand8		; small chance of placing secret doors after stalker level
	cmp #SECRET_DOOR
	bcs @pr
@sdoor:	ldy #SCR_SECRET_DOOR	; place secret door
@pr:	tya
	ldy cursor_x
	jsr plot
@skip:  pla			; restore Y
	tay	
	dey
	bne @xloop
	dex
	bne @yloop
	;
	;
init_player:
	ldx #10
	ldy #11
	stx py
	sty px
	lda #SCR_PLAYER
	jsr plot
	;
	;
init_stairs:
	jsr randomloc
	cpy #8			; check that stairs are not too near
	bmi @ok
	cpy #14
	bmi init_stairs
@ok:	; replace stairs with demon on special levels
	lda dungeon_level
	cmp #DEMON_LEVEL1
	beq @demon
	cmp #DEMON_LEVEL2
	beq @demon
	cmp #FINAL_LEVEL
	beq @demon
	lda #SCR_STAIRS
	bne @plot		; always branches
@demon:	lda #SCR_DEMON
@plot:	jsr plot
	;
	;
init_enemies:
	ldx dungeon_level
	lda mcounts,x
	sta $0			; $0 = spawn count
	lda spawns,x
	tax
	and #$f
	sta max_spawn
	txa
	lsr
	lsr
	lsr
	lsr
	sta min_spawn
@loop:	jsr rand8
	and #15
	cmp min_spawn
	bmi @loop
	cmp max_spawn
	bpl @loop
	clc
	adc #SCR_BAT
	pha
	jsr randomloc
	pla
	jsr plot
	dec $0
	bne @loop
	;
	;
init_items:
	jsr rand8
	and #7
	sec
	sbc #5
	bmi @done
	beq @done
	sta $0			; $0 = count
@loop:	jsr randomloc
	jsr random_loot
	dec $0
	bne @loop
@done:	;
	;

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
	.endif

	lda #DEMON_HP		; init demon hp
	sta demon_hp
	;
	;
init_theme:
	ldx dungeon_level	; init level theme
	lda themes,x
	tay
	lsr
	lsr
	lsr
	lsr
	sta wlcolor		; wall color
	sta drcolor		; door color
	sta sdcolor		; secret door color
	tya
	and #7
	sta flcolor

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
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN	; don't touch already seen blocks (preserves monster colors)
	.endif
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
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
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
	; move cursor in direction X (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

movedir:lda @dirs,x
	jsr CHROUT
	ldx cursor_y
	ldy cursor_x
	jmp move	; jsr + rts

@dirs:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_LEFT

	;*****************************************************************
	; plots a character in A at row X, column Y
	;*****************************************************************

plot:	jsr move
plot2:	sta (line_ptr),y
	lda cur_color
	sta (color_ptr),y
rts2:	rts

	;*****************************************************************
	; prints text at cursor
	; X = text offset
	; Y = dest offset
	;*****************************************************************

print_title:
	lda title,x
	beq rts2
	inx
	sta (line_ptr),y
	lda text_color
	sta (color_ptr),y
	iny
	bne print_title		; always branches

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
	; Y = text offset
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
	ldx #0			; X = screen pos
@loop1: lda textbase,y
	beq @chk
	iny
	cmp #'%'
	beq @print_name
	sta SCREEN,x
	lda #COLOR_WHITE
	sta COLOR_RAM,x
	inx
	bne @loop1
	; clear rest of the line
@loop2:	lda #SCR_SPACE
	sta SCREEN,x
	inx
@chk:	cpx #22
	bne @loop2
	clc
	rts

	; prints monster/item name
@print_name:
	tya			; save Y
	pha
	ldy cur_name		; Y = monster/item index
	lda nameoff,y
	tay			; Y = start of name offset
@mloop:	lda names,y
	beq @mdone
	iny
	sta SCREEN,x
	inx
	bne @mloop
@mdone:	pla			; restore y
	tay		
	bne @loop1		; always branch

	;*****************************************************************
	; damage flash at cursor
	;*****************************************************************

damage_flash:
	lda (line_ptr),y
	pha			; save char
	lda (color_ptr),y
	pha			; save color
	lda #SCR_DAMAGE
	sta (line_ptr),y
	lda #COLOR_YELLOW
	sta (color_ptr),y
	; damage sound
	jsr pause_music
	lda #150
	sta vic_noise
	jsr delay
damres:	jsr resume_music
	pla			; restore color
	sta (color_ptr),y	
	pla			; restore char
	sta (line_ptr),y	
	lda #0			; reset flood counter
	sta msg_time		; NOTE: enemy_attack assumes that Z=1 when returning from this routine!
	rts

miss_flash:
	lda (line_ptr),y
	pha			; save char
	lda (color_ptr),y
	pha			; save color
	lda px
	cmp mon_x
	beq @ver
	lda #SCR_MISS_X
	bne @hor		; always branch
@ver:	lda #SCR_MISS_Y
@hor:	sta (line_ptr),y
	lda #COLOR_WHITE
	sta (color_ptr),y
	; old sound effect
	; jsr pause_music
	; lda #225
	; sta vic_soprano
	; lda #5
	; jsr delay2
	; lda #245
	; sta vic_soprano
	; lda #9
	; jsr resume_music
	; play sound
	jsr pause_music
	ldx #224
@sound:	stx vic_alto
	lda #1
	jsr delay2
	inx
	inx
	inx
	cpx #248
	bne @sound
	jsr resume_music
	lda #7
	jsr delay2
	beq damres		; always branch

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
	; short delay about half a second, trashes: A
	; delay uses default delay value
	; delay2 uses default value in A
	;*****************************************************************

delay:	lda #DEFAULT_DELAY
delay2: sta delay_length
	lda $a2
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
	beq rts5
	dec rndloc_tmp
	bne @rndcol
	beq randomloc  		; always branches

	;*****************************************************************
	; waits for a key press
	;*****************************************************************

waitkey:jsr GETIN
	cmp #0
	beq waitkey
rts5:	rts

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

	; title texts
title:	.byte SCR_ANKH,$a0,$84,$85,$8d,$8f,$8e,$93,$a0,$8f,$86,$a0,$84,$85,$98,$a0,SCR_ANKH,$00	; DEMONS OF DEX
creds1: .byte $83,$8f,$84,$85,$ba,$a0,$a0,$90,$85,$94,$92,$89,$a0,$88,$81,$8b,$8b,$89,$8e,$85,$8e,$00
creds2: .byte $8d,$95,$93,$89,$83,$ba,$a0,$8d,$89,$8b,$8b,$8f,$a0,$8b,$81,$8c,$8c,$89,$8e,$85,$8e,$00

	; message texts
textbase:
descend:.byte $84,$85,$93,$83,$85,$8e,$84,$89,$8e,$87,$00				; DESCENDING
youhit: .byte $99,$8f,$95,$a0,$88,$89,$94,$a0,$94,$88,$85,$a0,$25,$a1,$00		; YOU HIT THE %!
youmiss:.byte $99,$8f,$95,$a0,$8d,$89,$93,$93,$ae,$00					; YOU MISS.
youdie: .byte $99,$8f,$95,$a0,$84,$89,$85,$a1,$a0,$93,$83,$8f,$92,$85,$ba,$00		; YOU DIE! SCORE:
monhit: .byte $25,$a0,$88,$89,$94,$93,$a0,$99,$8f,$95,$a1,$00				; % HITS YOU!
monmiss:.byte $25,$a0,$8d,$89,$93,$93,$85,$93,$a1,$00					; % MISSES!
mondies:.byte $25,$a0,$84,$89,$85,$93,$a1,$00						; % DIES!
monwoun:.byte $25,$a0,$89,$93,$a0,$97,$8f,$95,$8e,$84,$85,$84,$a1,$00			; % IS WOUNDED!
opened: .byte $8f,$90,$85,$8e,$85,$84,$ae,$00						; OPENED.
block:  .byte $82,$8c,$8f,$83,$8b,$85,$84,$ae,$00					; BLOCKED.
found:  .byte $86,$8f,$95,$8e,$84,$a0,$25,$ae,$00					; FOUND %.
outof:  .byte $8e,$8f,$a0,$25,$93,$ae,$00						; NO %S.
useitem:.byte $95,$93,$85,$a0,$25,$00							; USE %
usepot: .byte $88,$85,$81,$8c,$85,$84,$a1,$00						; HEALED!
usegem: .byte $81,$a0,$96,$89,$93,$89,$8f,$8e,$a1,$00					; A VISION!
usescr: .byte $94,$95,$92,$8e,$85,$84,$a0,$89,$8e,$96,$89,$93,$89,$82,$8c,$85,$a1,$00	; TURNED INVISIBLE!
useskul:.byte $83,$88,$81,$8f,$93,$a1,$00						; CHAOS!
youwin: .byte $99,$8f,$95,$a0,$97,$89,$8e,$a1,$a0,$93,$83,$8f,$92,$85,$ba,$00		; YOU WIN! SCORE:
levelup:.byte $8c,$85,$96,$85,$8c,$a0,$95,$90,$a1,$00					; LEVEL UP!

	; initial contents of status bar area in screen ram and color ram
statscr:.byte SCR_POTION,SCR_0,SCR_SPACE,SCR_GEM,SCR_0,SCR_SPACE,SCR_SCROLL,SCR_0,SCR_SPACE,SCR_ANKH,SCR_0,SCR_SPACE,SCR_SPACE,SCR_SPACE,SCR_SPACE
statcol:.byte 2,2,2,2,2,2,2,2,1,1,5,1,1,4,1,1,7,1,1,1,1,1

	; dirs for check walls
drdirs:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_DOWN,CHR_LEFT,CHR_LEFT,CHR_UP,CHR_UP,0

	; wall bits for door placement
drbits: .byte $d8,$8d,$63,$36,$8c,$c8,$23,$32,$22,$66,$27,$76
drbits_end: 

rnditem:.byte SCR_POTION,SCR_POTION,SCR_GOLD,SCR_GOLD,SCR_GEM,SCR_SCROLL,SCR_ANKH,SCR_GOLD

	; user defined chars
ankh:	.byte $1c,$22,$22,$14,$08,$3e,$08,$08

	; addresses of chars in memory
	; chars are copied to linear memory area starting at $1d50
charadr:;.word hheart		; half heart
	.word $8000+102*8	; #
	.word $8000+46*8	; .
	.word $8000+(43+128)*8	; +
	.word $8000+102*8	; (secret door)
	.word $8000+62*8	; > stairs
	.word $8000		; @ player
	.word $8000+33*8	; ! potion
	.word $8000+90*8	; (gem)
	.word $8000+63*8	; ? scroll
	.word ankh		; (ankh)
	.word $8000+36*8	; $ gold
	.word $8800+2*8		; b bat
	.word $8800+18*8	; r rat
	.word $8800+23*8	; w worm
	.word $8800+19*8	; s snake
	.word $8800+15*8	; o orc
	.word $8800+26*8	; z undead
	.word $8800+32*8	;   stalker
	.word $8800		; @ wizard
	.word $8800+83*8	; S slime
	.word $8800+68*8	; D demon
charadr_end:

projch:	.byte SCR_PROJ_Y,SCR_PROJ_X,SCR_PROJ_Y,SCR_PROJ_X

mul3:	.byte 0,3,6,9

	.segment "CHARS"

	; this is the first char
hheart:	.byte $30,$78,$78,$78,$38,$18,$08,$00

	; contents of this segment is copied to cassette buffer
	; and this area is filled with user defined char data

	.org cassette_buffer

	; monster and item names
names:
_potion:.byte $90,$8f,$94,$89,$8f,$8e,$00						; POTION
_gem:   .byte $87,$85,$8d,$00								; GEM
_scroll:.byte $93,$83,$92,$8f,$8c,$8c,$00						; SCROLL
_ankh:  .byte $81,$8e,$8b,$88,$00							; ANKH
_gold:  .byte $87,$8f,$8c,$84,$00							; GOLD
_bat:   .byte $82,$81,$94,$00								; BAT
_rat:   .byte $92,$81,$94,$00								; RAT
_worm:  .byte $97,$8f,$92,$8d,$00							; WORM
_snake: .byte $93,$8e,$81,$8b,$85,$00							; SNAKE
_orc:   .byte $8f,$92,$83,$00								; ORC
_undead:.byte $95,$8e,$84,$85,$81,$84,$00						; UNDEAD
_stalke:.byte $93,$94,$81,$8c,$8b,$85,$92,$00						; STALKER
_wizard:.byte $97,$89,$9a,$81,$92,$84,$00						; WIZARD
_slime: .byte $93,$8c,$89,$8d,$85,$00							; SLIME
_demon: .byte $84,$85,$8d,$8f,$8e,$00							; DEMON

	; name offsets
nameoff = _nameof-SCR_POTION
_nameof:.byte _potion-names
	.byte _gem-names
	.byte _scroll-names
	.byte _ankh-names
	.byte _gold-names
	.byte _bat-names
	.byte _rat-names
	.byte _worm-names
	.byte _snake-names
	.byte _orc-names
	.byte _undead-names
	.byte _stalke-names
	.byte _wizard-names
	.byte _slime-names
	.byte _demon-names

colors = _colors-SCR_WALL
_colors:
wlcolor:.byte COLOR_CYAN			; # wall
flcolor:.byte COLOR_CYAN			; . floor
drcolor:.byte COLOR_CYAN			; + door
sdcolor:.byte COLOR_CYAN			; (secret door)
	.byte COLOR_WHITE			; > stairs
plcolor:.byte COLOR_WHITE			; @ player
	.byte COLOR_RED				; ! potion
	.byte COLOR_GREEN			; (gem)
	.byte COLOR_PURPLE			; ? scroll
	.byte COLOR_YELLOW			; (ankh)
	.byte COLOR_YELLOW			; $ gold
	.byte COLOR_RED				; b bat		0
	.byte COLOR_RED				; r rat		1
	.byte COLOR_WHITE			; w worm	2
	.byte COLOR_GREEN			; s snake	3
	.byte COLOR_GREEN			; o orc		4
	.byte COLOR_WHITE			; z undead	5
	.byte COLOR_WHITE			;   stalker	6
	.byte COLOR_PURPLE			; @ wizard	7
	.byte COLOR_YELLOW			; S slime	8
	.byte COLOR_PURPLE			; D demon	9

	;lvl  0   1   2   3   Dz  5   o   7   8   Ds  r   11  12  S  Dw
spawns:	.byte $02,$03,$04,$05,$56,$06,$45,$26,$26,$67,$12,$27,$28,$89,$78	; hi=min monster, lo=max monster+1
mcounts:.byte $03,$04,$05,$05,$05,$06,$06,$07,$07,$07,$0c,$09,$09,$03,$08	; number of monsters
themes:	.byte $33,$33,$33,$33,$61,$33,$52,$33,$33,$61,$22,$33,$33,$57,$41	; hi=wall color, lo=floor color

	; colors: 0=black, 1=white, 2=red, 3=cyan, 4=purple, 5=green, 6=blue, 7=yellow

titlec:	.byte COLOR_RED,COLOR_YELLOW	; title colors
