OPTION EXPLICIT ON

DIM #SoundPointer

#SoundPointer = VARPTR SFX0(0)

MODE 0
ON FRAME GOSUB Player

PRINT AT 0,"Press any key in 0-9"

WHILE 1
	WAIT	

	if (#SoundPointer = 0) then 
		select case (CONT.KEY) 
			case 0:	#SoundPointer = VARPTR SFX0(0)
			case 1:	#SoundPointer = VARPTR SFX1(0)
			case 2:	#SoundPointer = VARPTR SFX2(0)
			case 3:	#SoundPointer = VARPTR SFX3(0)
			case 4:	#SoundPointer = VARPTR SFX4(0)
			case 5:	#SoundPointer = VARPTR SFX5(0)
			case 6:	#SoundPointer = VARPTR SFX6(0)
			case 7:	#SoundPointer = VARPTR SFX7(0)
			case 8:	#SoundPointer = VARPTR SFX8(0)
			case 9:	#SoundPointer = VARPTR SFX9(0)
		end select
	end if
	
WEND
	
Player: procedure
	CALL VOCPLAY
end	
	
' VOCPLAY is equivalent to this routine in Basic
	
'Player: procedure	
'	if (#SoundPointer=0) then 
'		return
'	end if
'	
'	if (peek(#SoundPointer+1) = 255) then 
'		#SoundPointer = 0
'		SOUND 0,,0
'		SOUND 1,,0
'		SOUND 2,,0
'		SOUND 3,,0
'		return
'	end if
'
'	SOUND 0,peek(#SoundPointer)+256*(peek(#SoundPointer+1) and 3), 15-((peek(#SoundPointer+1)/4) and 15) : #SoundPointer = #SoundPointer + 2
'	SOUND 1,peek(#SoundPointer)+256*(peek(#SoundPointer+1) and 3), 15-((peek(#SoundPointer+1)/4) and 15) : #SoundPointer = #SoundPointer + 2
'	SOUND 2,peek(#SoundPointer)+256*(peek(#SoundPointer+1) and 3), 15-((peek(#SoundPointer+1)/4) and 15) : #SoundPointer = #SoundPointer + 2
'	
'	SOUND 3,peek(#SoundPointer), 15-peek(#SoundPointer+1)/4 
'	#SoundPointer = #SoundPointer + 2
'
'end	

ASM INCLUDE "src\artvoice.asm"
	
INCLUDE "sfx_sn76489.bas"


