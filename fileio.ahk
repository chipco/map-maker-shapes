Save_Shape(data, path) {
	FileDelete, % Path
	output := "", bloc

	Loop, % data.MaxIndex() {
		output .= data[A_index][1] . " " . data[A_index][2] . ", "
	}

	FileAppend, % output, % Path
	If (ErrorLevel)
		Return -1
	Return 0
}

Load_Shape(path) {
	If (!FileExist(path))
		Return -1

	FileRead, string, % path

	RegExNeedle := "([0-9]+) ([0-9]+),"

	p0 := 1
	shape :=  Array()

	while p1 := RegExMatch(string, RegExNeedle, output, p0) {
		shape[A_Index] :=  Array()
		shape[A_Index][1] :=  output1
		shape[A_Index][2] :=  output2
		p0 := p1 + StrLen(output1) + 2 + StrLen(output2)
	}

	Return shape
}

Load_All(ByRef shapes, ByRef files) {
	shapes :=  Array()
	files := Array()

	FileList =
	Loop, shapes\*.txt
		FileList = %FileList%%A_LoopFileName%`n
	Sort, FileList

	Loop, parse, FileList, `n
	{
		if A_LoopField =
			continue
		file := "shapes\" . A_LoopField
		shapes[A_Index] := Load_Shape(file)
		files[A_Index] := A_LoopField
	}
}