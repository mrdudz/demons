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
	ENEMY_COUNT	= 3
	DEBUG		= 0		; set to 0 for strip debug code

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
	CHR_WALL	= 64
	CHR_FLOOR	= 65
	CHR_POTION	= 66
	CHR_GOLD	= 67
	CHR_STAR	= 68
	CHR_DOOR	= 69
	CHR_STAIRS	= 70
	CHR_PLAYER	= 71
	CHR_BAT		= 72
	CHR_RAT		= 73
	CHR_SNAKE	= 74
	CHR_ORC		= 75
	CHR_UNDEAD	= 76
	CHR_SLIME	= 77
	CHR_WIZARD	= 78
	CHR_DEMON	= 79
	CHR_DRAGON	= 80

	; screen codes
	SCR_WALL	= 0
	SCR_FLOOR	= 1
	SCR_POTION	= 2
	SCR_GOLD	= 3
	SCR_STAR	= 4
	SCR_DOOR	= 5
	SCR_STAIRS	= 6
	SCR_PLAYER	= 7
	SCR_BAT		= 8
	SCR_RAT		= 9
	SCR_SNAKE	= 10
	SCR_ORC		= 11
	SCR_UNDEAD	= 12
	SCR_SLIME	= 13
	SCR_WIZARD	= 14
	SCR_DEMON	= 15
	SCR_DRAGON	= 16

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
	PX		= $10
	PY		= $11
	RNDLOC_TMP	= $12
	COLOR_PTR	= $13		; $13-$14 = pointer to current line in color ram

	; VIC registers
	VIC_SCR_COLORS	= $900F

	.byt $01,$10			; PRG file header (starting address of the program)

	.org    $1001			; start of basic program

	;*****************************************************************
	; basic stub
	;*****************************************************************

	; stub basic program
	.word bend 			; next Line link
	.word 2015        		; line number
	.byte $9e,52,49,48,57		; sys 4109
	.byte 0           		; end of line
bend:	.word 0           		; end of program

	;*****************************************************************
	; main program
	;*****************************************************************

start:	lda #8
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

	jsr random_level

	; reveal first area
	ldy PX
	ldx PY
	jsr reveal_area

	; draw welcome message
        ldx #<welcome
        ldy #>welcome
        jsr print_msg

mainloop:
	jsr waitkey
	jsr update_player

	ldy PX
	ldx PY
	jsr reveal_area

	; test extract bits
	.if 0
	ldy PX
	ldx PY
	jsr move
	jsr extract_bits
	ldy #0
	ldx #1
	jsr move
	jsr print_hex
	.endif

	jmp mainloop

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
	rts

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
	cmp #SCR_STAIRS
	beq @enter_stairs	; allow moving into stairs
	cmp #SCR_WALL
	beq @blocked
	cmp #SCR_DOOR
	beq @open_door
	cmp #SCR_FLOOR
	bne player_attack

	; move player to X,Y
	sty PX			; store new pos
	stx PY
	lda #COLOR_UNSEEN ;;WHITE
	sta CUR_COLOR
	lda #CHR_PLAYER
	jsr plot		; draw player at new pos
	ldx $0			; restore old pos
	ldy $1
	lda #CHR_FLOOR
	jsr plot		; erase old player
	rts

@blocked:
        ldx #<blocked
        ldy #>blocked
        jsr print_msg
	rts

@open_door:
	lda #COLOR_UNSEEN
	sta CUR_COLOR
	lda #CHR_FLOOR
	jsr plot
	jsr reveal_area
        ldx #<opened
        ldy #>opened
        jsr print_msg
	rts

@enter_stairs:
        ldx #<descend
        ldy #>descend
        jsr print_msg
	jsr random_level
	rts

	;*****************************************************************
	; player attack, in: X,Y = target coordinates
	;*****************************************************************

player_attack:
	jsr rand8
	cmp #128
	bcc @hit
	ldx #<youmiss
        ldy #>youmiss
        jsr print_msg
        rts
@hit:	txa				; store X,Y
	pha
	tya
	pha
	ldx #<youhit
	ldy #>youhit
	jsr print_msg	
	jsr waitkey
	pla				; restore X,Y
	tay
	pla
	tax
	lda #COLOR_EXPLORED
	sta CUR_COLOR
	lda #CHR_FLOOR			; remove monster
	jsr plot
	ldx #<mondie
	ldy #>mondie
	jsr print_msg
	rts

	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	lda #ENEMY_COUNT
	sta $0
@loop:	jsr randomloc
	lda #CHR_RAT
	jsr plot
	dec $0
	bne @loop
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
	; traverse the level and extract bits for each floor cell
	; place door if bits match with one in the door bit list
	ldx #20 		; X = row
@yloop:	ldy #20 		; Y = column
@xloop:	jsr move		; move cursor
	tya			; save Y
	pha
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	bne @skip
	jsr extract_bits
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

extract_bits:
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
	lda colors,x
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
	jmp @loop
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
	; X,Y = address of text
	;*****************************************************************

print_msg:
	lda #CHR_HOME
	jsr CHROUT
	lda #COLOR_WHITE
	sta CUR_COLOR
        jsr print
        ; clear rest of the line
        lda #32
        ldx CURSOR_X
@cloop: sta SCREEN,x
	inx
	cpx #22
        bne @cloop
        ; rebase screen codes to start from 128
     	ldx #SCREEN_WIDTH-1
@reloc: lda SCREEN,x
	ora #$80
	sta SCREEN,x
	dex
	bpl @reloc
	rts

	;*****************************************************************
	; clears the screen
	;*****************************************************************

clearscreen:
	; screen is 22*23 = 506 bytes long
	; to save bytes we clear two full pages (512 bytes)
	ldx #0
@loop:	lda #SCR_WALL
	sta SCREEN+22,x		; dont clear first line
	sta SCREEN+$100,x
	lda #COLOR_UNSEEN
	sta COLOR_RAM+22,x	; dont clear first line
	sta COLOR_RAM+$100,x
	inx
	bne @loop
	rts

	;*****************************************************************
	; short delay in busy loop
	;*****************************************************************

	.if DEBUG
delay:	txa
	pha
	tya
	pha
	ldy #$40
@delay1:ldx #$ff
@delay2:dex
	bne @delay2
	dey
	bne @delay1
	pla
	tay
	pla
	tax
	rts
	.endif

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
	beq randomloc  ;same as 'jmp randomloc' but saves 1 byte
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

welcome:.byte	"DEMONS OF DEX",0
descend:.byte	"DESCENDING...",0
youhit:	.byte	"YOU HIT THE XXX!",0
youmiss:.byte	"YOU MISS.",0
mondie:	.byte	"THE XXX IS DEAD!",0
opened:	.byte	"OPENED.",0
blocked:.byte	"BLOCKED.",0

	; user defined chars
charset:.byte $aa,$55,$aa,$55,$aa,$55,$aa,$55	; wall
	.byte $00,$00,$00,$00,$00,$18,$18,$00	; .
	.byte $18,$18,$18,$18,$00,$00,$18,$00	; !
	.byte $18,$3e,$60,$3c,$06,$7c,$18,$00	; $
	.byte $00,$66,$3c,$ff,$3c,$66,$00,$00	; *
	.byte $ff-$00,$ff-$18,$ff-$18,$ff-$7e,$ff-$18,$ff-$18,$ff-$00,$ff-$00	; + reversed
	.byte $70,$18,$0c,$06,$0c,$18,$70,$00	; >
	.byte $3c,$66,$6e,$6e,$60,$62,$3c,$00	; @ (player)
	.byte $00,$60,$60,$7c,$66,$66,$7c,$00	; b
	.byte $00,$00,$7c,$66,$60,$60,$60,$00	; r
	.byte $00,$00,$3e,$60,$3c,$06,$7c,$00	; s
	.byte $00,$00,$3c,$66,$66,$66,$3c,$00	; o
	.byte $00,$00,$7e,$0c,$18,$30,$7e,$00	; z
	.byte $3c,$66,$60,$3c,$06,$66,$3c,$00	; S
	.byte $3c,$66,$6e,$6e,$60,$62,$3c,$00	; @ (wizard)
	.byte $66,$66,$3c,$18,$3c,$66,$66,$00	; X
	.byte $78,$6c,$66,$66,$66,$6c,$78,$00	; D
charset_end:

colors:	.byte COLOR_CYAN			; wall
	.byte COLOR_CYAN			; .
	.byte COLOR_PURPLE			; !
	.byte COLOR_YELLOW			; $
	.byte COLOR_RED				; *
	.byte COLOR_CYAN			; +
	.byte COLOR_CYAN			; >
	.byte COLOR_WHITE			; @ (player)
	.byte COLOR_RED				; b
	.byte COLOR_RED				; r
	.byte COLOR_GREEN			; s
	.byte COLOR_GREEN			; o
	.byte COLOR_WHITE			; z
	.byte COLOR_GREEN			; S
	.byte COLOR_PURPLE			; @ (wizard)
	.byte COLOR_YELLOW			; X
	.byte COLOR_RED				; D
