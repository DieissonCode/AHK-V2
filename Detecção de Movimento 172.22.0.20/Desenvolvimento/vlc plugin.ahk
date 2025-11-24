options =""
	Gui,	live:Add, Text,%	"x320	y0								vaovivo				cGreen"	,%  nome_da_camera
	Gui,	live:Add, ActiveX,%	"x10	y45	w" A_ScreenWidth " h" A_ScreenHeight "	vVlcx"			,	VideoLAN.VLCPlugin
	Gui,	live:Show,%			"x0		y0	w" A_ScreenWidth " h" A_ScreenHeight-45					,	Live
	vlcx.playlist.add( "https://www.youtube.com/watch?v=8ZWfD68h_z0", "", options )
	vlcx.playlist.play()
Return

liveGuiClose:
	ExitApp, 0