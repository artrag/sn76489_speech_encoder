;
;	compact version (less bytes but sliglty slower)
;

VOCPLAY:
_vocplay:
; get sample pointer
	ld	hl,(_vocadr)
	ld	a,h
	or	l
	ret	z			; if zero do nothing
	
	ld	bc,0x0380

nextchannel:
	ld	e,(hl)				; PPPP PPPP
	inc	hl
	ld	d,(hl)				; XXVV VVPP
	inc	hl

	ld	a,e
	and	a, 0x0F
	or	a,c					; chX period Low 4 bits
	out	(_SOUND),a			; Channel period low nibble
	
	ex 	de,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ex 	de,hl	
	
	ld	a,d					; chX period High 6 bits
	and	a,0x3F
	out	(_SOUND),a
	
	ld	a,(hl)
	rra
	rra
	and	a,0x0F				; (d>>2)&0x0f = attenuation
	inc	c
	or  a,c					; attenuation chX
	out	(_SOUND),a
	
	ld	a,0x20-1
	add a,c
	ld	c,a
	djnz	nextchannel

	ld	a,(hl)				; deal with noise Channel
	inc	hl		
	or	0xE0				; noise control, periodic sound, select the divider
	out	(_SOUND),a			
	out	(_SOUND),a			
	
	ld  a,(hl)
	rra
	rra
	and	0x0F				; attenuation				
	or  0xF0
	out	(_SOUND),a			; noise attenuation
	inc	hl
	
	ld	(_vocadr),hl		; update the pointer and return
	ret
