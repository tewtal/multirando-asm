; Patch Zelda 3 SRAM Accesses

org $0087eb
	sta $007ffe
	lda $0063e1

org $0087fb
	sta $0063e1
	lda $0068e1
	
org $00880b
	sta $0068e1
	lda $006de1

org $00881b
	sta $006de1

org $0cccdd
	adc $006000,x

org $0cccf5
	adc $006f00,x

org $0ccd5f
	sta $006f00,x
	sta $006000,x
	sta $007000,x
	sta $006100,x
	sta $007100,x
	sta $006200,x
	sta $007200,x
	sta $006300,x
	sta $007300,x
	sta $006400,x

org $0ccd0a
	sta $006f00,x
	sta $006000,x
	sta $007000,x
	sta $006100,x
	sta $007100,x
	sta $006200,x
	sta $007200,x
	sta $006300,x
	sta $007300,x
	sta $006400,x

org $0ccdfa
	lda $0063e1,x

	
org $1befa0
	lda $006354
org $1befa6
	lda $00635b
org $1befb0
	lda $006359
org $1befba
	lda $00635a
org $1befc4
	lda $006854
org $1befca
	lda $00685b
org $1befd4
	lda $006859
org $1befde
	lda $00685a
org $1befe8
	lda $006d54
org $1befee
	lda $006d5b
org $1beff8
	lda $006d59
org $1bf002
	lda $006d5a

org $0cd79b
	sta $006000,x
	sta $006100,x
	sta $006200,x
	sta $006300,x
	sta $006400,x
	
org $0cd7be
	sta $0063d9,x
	sta $0063db,x	
	sta $0063dd,x	
	sta $0063df,x
	
org $0cdb11
	sta $0063d9,x

org $0cdca9
	lda $0063d9,x

org $0cdb25
	lda $0063d9,x
	
org $0cdb4c
	sta $007ffe

org $0cdb5b
	sta $0063e1,x
org $0cdb62
	sta $00620c,x
org $0cdb66
	sta $00620e,x
org $0cdb6d
	sta $006401,x

org $0cdb8a
	lda $0063d9

org $0cdb96
	sta $006212,x
org $0cdb9d
	sta $0063c5,x
org $0cdba4
	sta $0063c7,x

org $0cdbae
	sta $006340,x

org $0cdbc1
	adc $006000,x

org $0cdbd7
	sta $0064fe,x
	
org $0cd5d9
	lda $006359,x

org $0cd626
	lda $00635a,x

org $0cd6c4
	lda $006401,x
	
org $0cd52c
	lda $0063d9,x

org $0cd54c
	lda $00636c,x
 
org $0cce85
	sta $007ffe
	
org $0cced8
	lda $006000,x

org $0ccedf
	lda $006100,x

org $0ccee6
	lda $006200,x

org $0cceed
	lda $006300,x

org $0ccef4
	lda $006400,x

org $0eefeb
	lda $007ffe

org $0eeff5
	lda $0063d9,x
	
org $0ef011
	lda $0063db,x

org $0ef02d
	lda $0063dd,x
	
org $0ef049
	lda $0063df,x
	
org $00894b
	lda #$00
	
org $008951
	ldx $7ffe
	
org $008961
	sta $6000,y
	sta $6f00,y
	
org $00896b
	sta $6100,y
	sta $7000,y

org $008975
	sta $6200,y
	sta $7100,y

org $00897f
	sta $6300,y
	sta $7200,y
	
org $008989
	sta $6400,y
	sta $7300,y
	
org $0089b6
	sta $0064fe,x
	sta $0073fe,x

org $0cd4d3
	sta.l $006000,x
	sta.l $006100,x
	sta.l $006200,x
	sta.l $006300,x
	sta.l $006400,x
	sta.l $006f00,x
	sta.l $007000,x
	sta.l $007100,x
	sta.l $007200,x
	sta.l $007300,x

org $0cd2d1
	lda.b #$00

org $0cd2dc
	lda $6000,x
	sta $6000,y
	lda $6100,x
	sta $6100,y
	lda $6200,x
	sta $6200,y
	lda $6300,x
	sta $6300,y
	lda $6400,x
	sta $6400,y

