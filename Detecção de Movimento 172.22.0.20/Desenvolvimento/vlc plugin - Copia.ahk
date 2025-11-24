

; Msgbox	%	cam_list.Count()
; ExitApp, 0
; F2::
InputBox, id, ID, Insira o ID da câmera 
vlcx.playlist.stop()	
options=""
Gui, live:Destroy
Goto show
Return

show:
	Gui,	live:Add, Text,%	"x320	y0								vaovivo				cGreen"	,%  nome_da_camera
	Gui,	live:Add, ActiveX,%	"x10	y45	w" A_ScreenWidth " h" A_ScreenHeight "	vVlcx"			,	VideoLAN.VLCPlugin
	Gui,	live:Show,%			"x0		y0	w" A_ScreenWidth " h" A_ScreenHeight-45					,	Live
	vlcx.playlist.add( "http://admin:@dm1n@localhost/mjpegstream.cgi?camera=" id, "", options )
	vlcx.playlist.play()
Return

liveGuiClose:
ExitApp, 0

HttpGet( URL )	{
	responseText=
	static	req	:=	ComObjCreate( "Msxml2.XMLHTTP.6.0" )
	req.open( "GET", URL, false, "admin", "@dm1n" )
	req.SetRequestHeader( "If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT" )
	req.send()
	While	!req.readyState = 4	;	testar
		Return
		; OutputDebug, % req.status  ;	https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ms767625(v=vs.85)
		Return	req.responseText
}