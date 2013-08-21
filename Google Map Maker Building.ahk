#include fileio.ahk
#include gdip_routines.ahk

degrees(deg)
{
	return deg*0.0174532925
}

StrSplit(ByRef text, delimiter := "", omitChars := "")
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

Gui, 2: Add, Text,, Numele fisierului
Gui, 2: Add, Edit, w150 vFile
Gui, 2: Add, Text,, Lista coordonate (x1,y1 x2,y2 ... xn,yn)
Gui, 2: Add, Edit, w400 h200 vCoords
Gui, 2: Add, Button, w100 x310, Trimite

Gui, 3: Add, DropDownList, vFirstShapePoint w100
Gui, 3: Add, DropDownList, vSecondShapePoint w100 xp+110
Gui, 3: Add, Button, xp+110 w30, OK
Gui, 3: Add, Text, xm, Primul bloc
Gui, 3: Add, Text, xp+110 yp, Al doilea bloc

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
mutareBloc := 5		;in pixeli
rotireBloc := 0.5 	;in grade

SetWorkingDir %A_ScriptDir%
Load_All(shapes, files)

numar_blocuri := shapes.MaxIndex()

IfExist, session.ini
{
	IniRead, currentX, session.ini, CurrentSession, currentX
	IniRead, currentY, session.ini, CurrentSession, currentY
	IniRead, unghi_total, session.ini, CurrentSession, unghiTotal
	IniRead, numar_bloc_curent, session.ini, CurrentSession, shapeID
} Else {
	IniWrite, %startX%, session.ini, CurrentSession, currentX
	IniWrite, %startY%, session.ini, CurrentSession, currentY
	IniWrite, 0, session.ini, CurrentSession, unghiTotal
	IniWrite, 1, session.ini, CurrentSession, shapeID
	
	currentX := startX
	currentY := startY
	numar_bloc_curent := 1
	unghi_total := 0
}

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
	
	IniWrite, %unghi_total%, session.ini, CurrentSession, unghiTotal
	
	return
}

selectareBloc(numar_bloc)
{
	Global

	numar_puncte := shapes[numar_bloc].MaxIndex()
	bloc := shapes[numar_bloc].clone()
	
	IfWinExist, Lipire blocuri
	{
		List3 := "|"
		Loop, %numar_puncte%
		{
			bloc[a_index] := shapes[numar_bloc][a_index].clone()
			List3 .= a_index . "|"
		}
		
		GuiControl, 3:, SecondShapePoint, %List3%
		GuiControl, 3: Choose, SecondShapePoint, 1
	}
		
	Loop, %numar_puncte%
	{
		bloc[a_index][1] := bloc[a_index][1] + currentX
		bloc[a_index][2] := bloc[a_index][2] + currentY
	}

	calculareCentru()
	rotireBloc(unghi_total)
	redesenare(bloc)
	
	IniWrite, %numar_bloc%, session.ini, CurrentSession, shapeID
	
	ToolTip, % files[numar_bloc], currentX+50, currentY+50
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

A::
{
	Gui, 99:Hide

	2ButtonTrimite:
	KeyWait,a
	IfWinExist, Adauga forma bloc
	{
		Gui, 2:Hide
		Gui, 2:Submit
		
		If !ErrorLevel AND File AND Coords
		{
			shapes[numar_blocuri+1] := Array()	
			Loop, parse, Coords, `|
			{
				shapes[numar_blocuri+1][a_index] := StrSplit(A_LoopField, ",").clone()
			}
			numar_blocuri += 1
			
			files[numar_blocuri] := File
			Save_Shape(shapes[numar_blocuri], "shapes\" . files[numar_blocuri] . ".txt")
			
			selectareBloc(numar_blocuri)
			
			GuiControl,,Coords,
			GuiControl,,File,
			Gui, 99:Show
		} Else {
			MsgBox, Toate campurile sunt obligatorii
			Gui, 2:Show
		}	
	}
	Else
	{
		Gui, 2: Show, Center, Adauga forma bloc
	}

	Return
}

Q::
{
	if (beforeShape != "")
	{		
		List1 := "|"
		List2 := "|"
 		numar_puncte_before := beforeShape.MaxIndex()
		Loop, %numar_puncte_before%
			List1 .= A_Index . "|" 
		
		Loop, %numar_puncte%
			List2 .= A_Index . "|" 
		
		GuiControl, 3:, FirstShapePoint, %List1%
		GuiControl, 3:, SecondShapePoint, %List2%
		GuiControl, 3: Choose, FirstShapePoint, 1 
		GuiControl, 3: Choose, SecondShapePoint, 1 
		Gui, 3: Show, Center, Lipire blocuri
		Return
	} else {
		MsgBox, Mai intai trebuie sa desenati un bloc
	}
	
	3ButtonOK:
	{
		Gui, 3:Submit
		
		If !ErrorLevel AND FirstShapePoint AND SecondShapePoint
		{
			moveX := currentX - beforeShape[FirstShapePoint][1] - bloc[SecondShapePoint][1]
			moveY := currentY - beforeShape[FirstShapePoint][2] - bloc[SecondShapePoint][2]
			
			MouseMove, currentX, currentY
			MouseClickDrag, L, currentX, currentY, moveX, moveY, 50
			Sleep, 500
			;msgbox, % moveX . " x " . moveY
		}		
		Return
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

	IniWrite, %currentX%, session.ini, CurrentSession, currentX
	IniWrite, %currentY%, session.ini, CurrentSession, currentY
	
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
	
	IniWrite, %startX%, session.ini, CurrentSession, currentX
	IniWrite, %startY%, session.ini, CurrentSession, currentY
	IniWrite, 0, session.ini, CurrentSession, unghiTotal
	IniWrite, 1, session.ini, CurrentSession, shapeID
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
	
	beforeShape := bloc.clone()
	Loop, %numar_puncte%
	{
		beforeShape[a_index] := bloc[a_index].clone()
	}

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