#Requires Autohotkey v2
;AutoGUI creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;EasyAutoGUI-AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

if A_LineFile = A_ScriptFullPath && !A_IsCompiled
{
	myGui := Constructor()
	myGui.Show("")
}

.::	{
	OutputDebug('1')
	Send('{Tab}')
}
NumpadDel::
NumpadDot::	{
	OutputDebug('2')
	Send('{Tab}')
}

Constructor()
{
	myGui := Gui()
	myGui.Add("Text", "x10 y10 h20", "Ip da câmera")
	Edit1 := myGui.Add("Edit", "y30		w35 h20 Number xp")
	ControlGetPos(&x,,,,Edit1)
	Edit2 := myGui.Add("Edit", "yp		w35 h20 Number")
	Edit3 := myGui.Add("Edit", "yp		w35 h20 Number")
	Edit4 := myGui.Add("Edit", "yp		w35 h20 Number")
	button1 := myGui.Add("Button","x" x-2 "	w78 h20 ", "Ok")
	button2 := myGui.Add("Button","yp	wp h20 ", "Cancelar")
	Edit1.OnEvent("Change", OnEventHandler)
	Edit2.OnEvent("Change", OnEventHandler)
	Edit3.OnEvent("Change", OnEventHandler)
	Edit4.OnEvent("Change", OnEventHandler)
	button1.OnEvent("Click", Ok)
	button2.OnEvent("Click", Cancel)
	myGui.OnEvent('Close', (*) => ExitApp())
	myGui.Title := "Window"

	ok(*)
	{
		ip := edit1.value "." edit2.value "." edit3.value "." edit4.value
		OutputDebug(request("http://admin:tq8hSKWzy5A@" ip "/cgi-bin/magicBox.cgi?action=reboot"))
		ExitApp
	}

	cancel(*)
	{
		ExitApp
	}

	OnEventHandler(*)
	{
		 focus := ControlGetFocus('A')
		 size := StrLen(ControlGetText(focus))
		if( size >= 3)
			Send('{Tab}')
		; SetTimer () => ToolTip(), -3000 ; tooltip timer
	}

	request(url)
	{	;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		Local r	:= ComObject( "Msxml2.XMLHTTP" )
		r.Open( "POST", url, false )
		r.SetRequestHeader( "Content-Type", "application/json" )
		r.SetRequestHeader( "If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT" )
		Try r.Send()
		Try Return r.responseText
	}
	
	return myGui
}