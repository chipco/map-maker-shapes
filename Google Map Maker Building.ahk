#include fileio.ahk
#include gdip_routines.ahk

degrees(deg) 
{
	return deg*0.0174532925
}

StrSplit(ByRef text, delimiter := "", omitChars := "") ; Using ByRef for performance (you can pass non-variables too)
{
    ret := []
    Loop, Parse, text, % delimiter, % omitChars
        ret.Insert(A_LoopField)
    return ret
}

Gdip_Startup()
 
CoordMode, ToolTip, Screen
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

Gui, 99: +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui, 99: Show

Width := A_ScreenWidth,
Height := A_ScreenHeight,
hwnd1 := WinExist(),
Canvas := 0,
pBitmapDraw_%Canvas% := Gdip_CreateBitmap(Width, Height),
GDrawplus_%Canvas% := Gdip_GraphicsFromImage(pBitmapDraw_%Canvas%),
Gdip_SetSmoothingMode(GDrawplus_%Canvas%, 4),
hbmDraw_%Canvas% := CreateDIBSection(Width, Height),
hdcDraw_%Canvas% := CreateCompatibleDC(),
obmDraw_%Canvas% := SelectObject(hdcDraw_%Canvas%, hbmDraw_%Canvas%),
GDraw_%Canvas% := Gdip_GraphicsFromHDC(hdcDraw_%Canvas%)

bPen := Gdip_CreatePen(0xffff0000, 2)

redesenare(puncte)
{
	Global
	
	Gdip_GraphicsClear(GDraw_%Canvas%)
	
	numar := puncte.MaxIndex()
	
	repetari := numar - 1
	Loop, %repetari%
	{
		Gdip_DrawLine(GDraw_0, bPen, puncte[a_index][1], puncte[a_index][2], puncte[a_index+1][1], puncte[a_index+1][2])
	}
	Gdip_DrawLine(GDraw_0, bPen, puncte[1][1], puncte[1][2], puncte[numar][1], puncte[numar][2])

	UpdateLayeredWindow(hwnd1, hdcDraw_0, 0, 0, Width, Height)
}

startX := (Width / 2) + 100
startY := (Height / 3)
currentX := startX
currentY := startY
mutareBloc := 5		;in pixeli
rotireBloc := 0.5 	;in grade


SetWorkingDir %A_ScriptDir%
shapes =
fiels = 
Load_All(shapes, files)

; Loop % a1.MaxIndex() {
	; bloc := a1[A_Index]
    ; Loop, % bloc.MaxIndex() {
		; pixel1 := bloc[A_Index][1]
		; pixel2 := bloc[A_Index][2]
	; }
	; ListVars
	; Pause
; }

;0,0|271,0|271,445|164,445|164,379|107,379|107,445|0,445

numar_blocuri := shapes.MaxIndex()
numar_bloc_curent := 1
unghi_total := 0

selectareBloc(numar_bloc_curent)

calculareCentru()
{
	Global
	
	minX := maxX := bloc[1][1]
	minY := maxY := bloc[1][2]
	Loop, %numar_puncte%
	{
		if (bloc[a_index][1] < minX)
			minX := bloc[a_index][1]
		if (bloc[a_index][1] > maxX)
			maxX := bloc[a_index][1]
			
		if (bloc[a_index][2] < minY)
			minY := bloc[a_index][2]
		if (bloc[a_index][2] > maxY)
			maxY := bloc[a_index][2]
	}
	cx := minX + ((maxX - minX) / 2)
	cy := minY + ((maxY - minY) / 2)
}

rotireBloc(unghi)
{
	Global
	Loop, %numar_puncte%
	{
		s := sin(unghi)
		c := cos(unghi)
		
		bloc[a_index][1] := bloc[a_index][1] - cx
		bloc[a_index][2] := bloc[a_index][2] - cy

		xnew := bloc[a_index][1] * c - bloc[a_index][2] * s
		ynew := bloc[a_index][1] * s + bloc[a_index][2] * c

		bloc[a_index][1] := xnew + cx
		bloc[a_index][2] := ynew + cy	
	}
	return
}

selectareBloc(numar_bloc)
{
	Global

	numar_puncte := shapes[numar_bloc].MaxIndex()
	bloc := shapes[numar_bloc].clone()
	Loop, %numar_puncte%
	{
		bloc[a_index] := shapes[numar_bloc][a_index].clone()
	}

	Loop, %numar_puncte%
	{
		bloc[a_index][1] := bloc[a_index][1] + currentX
		bloc[a_index][2] := bloc[a_index][2] + currentY
	}
	
	calculareCentru()
	rotireBloc(unghi_total)
	redesenare(bloc)

	ToolTip, % "#" . numar_bloc, currentX+50, currentY+50
	SetTimer, RemoveToolTip, 500
	return
}

repozitionare(x, y)
{
	Global
	
	Loop, %numar_puncte%
	{
		bloc[a_index][1] := bloc[a_index][1] + x
		bloc[a_index][2] := bloc[a_index][2] + y
	}
	
	redesenare(bloc)
	calculareCentru()
}

Gui, 1: Add, Edit, vMyEdit x10 y30 w400 h200
Gui, 1: Add, Text, x10 y10 w400 h20 , Coordonate poligon:
Gui, 1: Add, Button, x311 y235 w100 h30 , Trimite
Return

A::
{
	Gui, 99:Hide
	
	ButtonTrimite:
	KeyWait,a
	IfWinExist, Adauga poligon
	{
		Gui, 1:Hide
		Gui, 1:Submit
		
		If !ErrorLevel AND MyEdit
		{			
			shapes[numar_blocuri+1] := Array()
			Loop, parse, MyEdit, `|
			{
				shapes[numar_blocuri+1][a_index] := StrSplit(A_LoopField, ",").clone()
			}
			numar_blocuri += 1
			selectareBloc(numar_blocuri)			
		}
		GuiControl,,MyEdit,
		Gui, 99:Show
	}
	Else
	{		
		Gui, 1: Show, Center h275 w420, Adauga poligon
	}

	Return
}

NumpadAdd::
{
	unghi := degrees(rotireBloc)
	unghi_total := unghi_total + unghi
	rotireBloc(unghi)
	redesenare(bloc)
	
	return
}

NumpadSub::
{
	unghi := degrees(rotireBloc)*-1
	unghi_total := unghi_total + unghi
	rotireBloc(unghi)
	redesenare(bloc)
	
	return
}

Up::
Left::
Down::
Right::
{
	If ((GetKeyState("Up", "P") AND GetKeyState("Left", "P")))
	{
		currentX += mutareBloc*-1
		currentY -= mutareBloc
		repozitionare(mutareBloc*-1, mutareBloc*-1)	
	}
	Else If ((GetKeyState("Up", "P") AND GetKeyState("RIGHT", "P")))
	{
		currentX += mutareBloc
		currentY -= mutareBloc
		repozitionare(mutareBloc, mutareBloc*-1)	
	}
	Else If ((GetKeyState("DOWN", "P") AND GetKeyState("LEFT", "P")))
	{
		currentX += mutareBloc*-1
		currentY += mutareBloc
		repozitionare(mutareBloc*-1, mutareBloc)	
	}
	Else If ((GetKeyState("DOWN", "P") AND GetKeyState("RIGHT", "P")))
	{
		currentX += mutareBloc
		currentY += mutareBloc
		repozitionare(mutareBloc, mutareBloc)	
	}
	Else If (GetKeyState("Up", "P"))
    {
		currentY -= mutareBloc
		repozitionare(0, mutareBloc*-1)	
    }
	Else If (GetKeyState("Left", "P"))
    {
		currentX += mutareBloc*-1
		repozitionare(mutareBloc*-1, 0)	
    }
	Else If (GetKeyState("Down", "P"))
    {
		currentY += mutareBloc
		repozitionare(0, mutareBloc)	
    }
	Else If (GetKeyState("Right", "P"))
    {
		currentX += mutareBloc
		repozitionare(mutareBloc, 0)	
    }
	
	
	return
}

NumpadMult::
{
	Loop, %numar_puncte%
	{
		bloc[a_index][1] := maxX - bloc[a_index][1] + currentX
	}
	redesenare(bloc)
	calculareCentru()
	return
}

NumpadDiv::
{
	Loop, %numar_puncte%
	{
		bloc[a_index][2] := maxY - bloc[a_index][2] + currentY
	}
	redesenare(bloc)
	calculareCentru()
	return
}

PgUp::
{	
	if (numar_bloc_curent = numar_blocuri)
	{
		numar_bloc_curent := 1
	} else {
		numar_bloc_curent := numar_bloc_curent + 1
	}
		
	selectareBloc(numar_bloc_curent)
	
	return
}

PgDn::
{	
	if (numar_bloc_curent = 1)
	{
		numar_bloc_curent := numar_blocuri
	} else {
		numar_bloc_curent := numar_bloc_curent - 1
	}
	
	selectareBloc(numar_bloc_curent)	
	return
}

r::
{	
	unghi_total := unghi_total * -1
	rotireBloc(unghi_total)	
	repozitionare(startX-currentX, startY-currentY)
		
	redesenare(bloc)
	
	currentX := startX
	currentY := startY
	unghi_total := 0
	return
}

Enter::
{
	Gui,99: Hide

	Loop, %numar_puncte%
	{
		MouseMove bloc[a_index][1], bloc[a_index][2]
		Click
		Sleep, 300
	}
	MouseMove bloc[1][1], bloc[1][2]
	Click
	Sleep, 100
	Click

	Gui,99: Show
	return
}

v::
{	
	tooltip, Liviu Roman`nGoogle Map Maker Building`nVersiunea 1.00, currentX, currentY
	SetTimer, RemoveToolTip, 5000
	return
}

RemoveToolTip:
	SetTimer, RemoveToolTip, Off
	ToolTip
return

~ESC::ExitApp 