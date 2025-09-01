;*******************************************
; 60Hz voice player 
; ColecoVision version
;
; Each frame is 4 words
; The first 3 words are for channels 0,1,2
; Each word is a channel packed in this way 
; XXVV VVPP PPPP PPPP
;
; NB, it's little endian, so we get: PPPP PPPP XXVV VVPP  
; PP in the the second byte are the most significant bits
;
; XX = 00 always, 1X if the frame has ended
; VVVV = volume in the SN76489 format
; PPPPPPPPPP = period of the tone in 1-1023, 
; where 1 = 111860Hz to 1023 = 109Hz
;
; The last word is for the noise channel in periodic mode
; The format is
; XXVV VVPP PPPP PPPP
; XX, VVVV and PPPPPPPPPP are the same as above 
; but the  frequency can only be one of these:
;  3579545/512 = 6990Hz  ->00h NF0 = 0 ; NF1 = 0
; 3579545/1024 = 3495Hz  ->01h NF0 = 0 ; NF1 = 1
; 3579545/2048 = 1740Hz  ->02h NF0 = 1 ; NF1 = 0
;
; The encoder chooses the most relevant, 
; The player uses the two msb's to select the frequency divider
;
; The volume is the same as above
; 
;
; Updated 8/20/2025 by artrag 
;
;*******************************************
;
; To use, simply load the address of your voice at "vocadr"
; and call "vocplay" 60 times per second (ie: during vblank)
; vocadr will be updated automatically, and will be zeroed
; when the voice is over. (Make sure it's zero before the
; first time you call vocplay if there's no sample ;) )
;



; coleco sound port
_SOUND:	equ	0xff
_vocadr: equ	cvb_#SOUNDPOINTER

;	---------------------------------
; Function mute - silence all three channels we use
; mutes the noise channel 
; zeros vocadr
; ---------------------------------

_mute:
	ld	a,0x9F
	out	(_SOUND),a
	ld	a,0xBF
	out	(_SOUND),a
	ld	a,0xDF
	out	(_SOUND),a
	ld	a,0xFF
	out	(_SOUND),a
	ld  a,0xE0				; noise control
	out	(_SOUND),a			; periodic noise, frequency divided by 512 and 15

	ld	hl,0x0000
	ld	(_vocadr),hl
	ret

; ---------------------------------
; Function vocinit 
; Input: HL pointing to the data

_vocinit:
	ld	(_vocadr),hl	
	ret

; ---------------------------------
; Function vocplay - call every 1/60th second
;
; register used:
; hl - sample pointer
; d - MSB of current word
; e - LSB of current word
; ---------------------------------
VOCPLAY:
; get sample pointer
	ld	hl,(_vocadr)
	ld	a,h
	or	l
	ret	z			; if zero do nothing
	
; start processing loop for three voices

; read two bytes (little endian format)

	ld	e,(hl)				; PPPP PPPP
	inc	hl
	ld	d,(hl)				; XXVV VVPP
	bit	7,d					; check for terminate flag
	jp	nz,_mute			; silences speakers and zeros pointer
	inc	hl	
	ld	a, e				; first byte out - tone command (e & 0x0f)|0x80
	and	0x0F
	or	0x80				; ch0 period Low 4 bits
	out	(_SOUND),a			; Channel period low nibble
	rr	d					; de >> 4 - second byte is 4 bits from LSB and 2 from MSB
	rr  e
	rr	d
	rr  e
	rr  e
	rr  e
	ld	a,e					; ch0 period High 6 bits
	and	0x3F
	out	(_SOUND),a
	ld	a,d
	and	0x0F				; (d>>2)&0x0f = attenuation
	or 	0x90				; attenuation ch0
	out	(_SOUND),a
	
	ld	e,(hl)				; PPPP PPPP
	inc	hl
	ld	d,(hl)				; XXVV VVPP
	inc	hl
	ld	a, e				; first byte out - tone command (e & 0x0f)|0xA0
	and	0x0F
	or	0xA0				; ch1 period Low 4 bits
	out	(_SOUND),a			; Channel period low nibble
	rr	d					; de >> 4 - second byte is 4 bits from LSB and 2 from MSB
	rr  e
	rr	d
	rr  e
	rr  e
	rr  e
	ld	a,e					; ch1 period High 6 bits
	and	0x3F
	out	(_SOUND),a
	ld	a,d
	and	0x0F				; (d>>2)&0x0f = attenuation
	or  0xB0				; attenuation ch1
	out	(_SOUND),a

	ld	e,(hl)				; PPPP PPPP
	inc	hl
	ld	d,(hl)				; XXVV VVPP
	inc	hl
	ld	a, e				; first byte out - tone command (e & 0x0f)|0xC0
	and	0x0F
	or	0xC0				; ch2 period Low 4 bits
	out	(_SOUND),a			; Channel period low nibble
	rr	d					; de >> 4 - second byte is 4 bits from LSB and 2 from MSB
	rr  e
	rr	d
	rr  e
	rr  e
	rr  e
	ld	a,e					; ch2 period High 6 bits
	and	0x3F
	out	(_SOUND),a
	ld	a,d
	and	0x0F				; (d>>2)&0x0f = attenuation
	or  0xD0				; attenuation ch2
	out	(_SOUND),a

	ld	a,(hl)				; deal with noise Channel
	inc	hl		
	or	0xE0				; noise control, periodic sound, select the divider
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
