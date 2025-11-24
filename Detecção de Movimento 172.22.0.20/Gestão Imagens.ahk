/*
	File_Version=0.2.0
	Save_To_Sql=1
	Keep_Versions=2
	Development=0
	Software_Name=Gestão Imagens
*/
;	Includes
	#Include C:\AutoHotkey\class\functions.ahk
	#Include C:\AutoHotkey\class\gui.ahk
	#Include C:\AutoHotkey\class\sql.ahk

;@Ahk2Exe-SetMainIcon C:\AHK\icones\kah.ico
;	Configurações
	#SingleInstance, Force
	#Persistent
	#IfWinActive,	Gestão

	show_tooltip	:=	A_Args[1]
		if ( A_UserName = "dsantos" )
			show_tooltip = 1
		CoordMode, ToolTip, Screen

	if A_IsCompiled
		ext	=	exe
	Else
		ext = ahk
	deletado=0


;	GUI
	Gui.Cores()
	Gui,	Add,	Text,%	gui.Font( "S10", "Bold", "cWhite" )	"ym		xm		w"	Floor(Round((A_ScreenWidth/10)*2))	" 	vtotal		h30					0x1000	Center"
	Gui,	Add,	button,%																								"	gfl		h30"											,	Abrir Pasta de Inibidos
	Gui,	Add,	button,%									"yp		xp+180													gfs		h30"											,	Imagens Salvas
	Gui,	Add,	ListView,%	Gui.Font()						"yp+30	xp-180	w"	Floor(Round((A_ScreenWidth/10)*2))	" R53	gL1	vL1			AltSubmit" 								,	Câmera|ip|Eventos	;|Soma
	Gui,	Add,	ListView,%									"ym				w"	Floor(Round((A_ScreenWidth/10)*1))	" R57	gL2	vL2			AltSubmit"								,	Horário|FullPath
	Gui,	Add,	Picture,%									"ym				w"	Floor(Round((A_ScreenWidth/10)*7))	"	vpic		h"	Floor(Round((A_ScreenWidth/10)*6)/16*9)
	Gosub	fill_l1
	Gui,	Show,	,	Gestão
	Menu,	mcm,	Add,	Configurar,		_configurar
	Menu,	mcm,	Add,	Deletar todas,	_limpar
	Menu,	mcm,	Add
	Menu,	mcm,	Add,	Salvar todas,	save_all
	Menu,	mcm2,	Add,	Salvar todas,	save_all
	return


fill_l1:
	OutputDebug % "fill_l1 " A_LineNumber
	Gui,	ListView,	L1
	LV_ModifyCol(	3, "Integer" )
	dia_verificar	:= MOD( A_YDay, 2 ) = 1 ? "Dia 1" : "Dia 2"
	_names			:= []
	_ips_count		:= {}
	Loop,	Files,	\\srvftp\Monitoramento\FTP\Verificados\%dia_verificar%\*.jpg
	{
		total_imagens++
		data	:=	StrSplit( A_LoopFileName, "_")
		If	_ips_count[data[2]].count {
			has := _ips_count[data[2]].count + 1
			z_ip		:=	data[2]
			z			:=	{	count	:	has
							,	name	:	StrReplace( data[4], ".jpg" )	}
			_ips_count[z_ip]	:=	z
			VarSetCapacity(z_ip,0)
		}
		Else {
			z_ip		:=	data[2]
			z			:=	{	count	:	1
							,	name	:	data[4]	}
			_ips_count[z_ip]	:=	z
			VarSetCapacity(z_ip,0)
		}
		temp_name	:=	 StrReplace( data[2], ".", "_" )
		if	!%temp_name%.Count() {
			%temp_name%	:=	[]
			_names.Push( data[2] )
		}
		%temp_name%.Push( A_LoopFileFullPath )

	}
	GuiControl, , total, % "Total de imagens " total_imagens

	Loop,% _names.Count()
		LV_Add(, _ips_count[ _names[A_Index] ].name, _names[A_Index], _ips_count[ _names[A_Index] ].count )

	LV_ModifyCol( 3, "SortDesc" )
	LV_ModifyCol(				)
	LV_ModifyCol( 2, 0 			)
	LV_ModifyCol( 3, 75 		)
	GuiControl, Focus, L1
	LV_GetText( ip1, 1, 2 )
	Goto, fill_l2
	return

fill_l2:
	dia_verificar	:= MOD( A_YDay, 2 ) = 1 ? "Dia 1" : "Dia 2"
	Gui,	ListView,	L2
	LV_ModifyCol( 2, 0 )
	LV_ModifyCol( 1, 185 )
	Sleep, 500
	OutputDebug % "listview " A_DefaultListView "`n`tip " ip1 "`n`tdia - " dia_verificar
	main_ip := StrReplace( ip1, ".", "_" )
	Loop,%	%main_ip%.Count() {
			data	:=	StrSplit( %main_ip%[A_Index], "_")
			LV_Add(, StrRep( SubStr( data[1], InStr(data[1], "\",,-1)+1),, "-"), %main_ip%[A_Index])
	}
	LV_Modify( 0, "-Select" )
	LV_Modify( 1, "Focus Select" )
	GuiControl, Focus, L2
	Send {Right}
	Gui, Submit, NoHide
	row	:=	LV_GetNext()
	LV_GetText( p, row, 2 )
	GuiControl,	,			pic,%	p
	GuiControl,	MoveDraw,	pic,%	"w" Floor(Round((A_ScreenWidth/10)*6.75))	"	h" Floor(Round((A_ScreenWidth/10)*7)/16*9)
	Return

L1:
	if( A_EventInfo = ""
	||	A_EventInfo = "0" )
		return
	if ( A_GuiEvent = "Normal" ) {
		Gui,	ListView,	L1
		LV_GetText( ip1, A_EventInfo, 2 )
		OutputDebug % "listview " A_DefaultListView "`n`tip " ip1 "`n`tevento - " A_EventInfo
		Gui,	ListView,	L2
			LV_Delete()
		OutputDebug % "L1 " ip1
		gosub fill_l2
	}
	return

L2:
	if	( A_GuiEvent = "Normal" )	{
		OutputDebug % "L2 " A_LineNumber
		Gui,	ListView,	L2
		LV_GetText( p, A_EventInfo, 2 )
		GuiControl,	,			pic,%	p
		GuiControl,	MoveDraw,	pic,%	"w" Floor(Round((A_ScreenWidth/10)*6.75))	"	h" Floor(Round((A_ScreenWidth/10)*7)/16*9)
	}
	If( A_GuiEvent = "K" )	{
		OutputDebug % "K L2 " A_LineNumber
		if( A_EventInfo	= 40 )		{
			OutputDebug % "L2 40 " A_LineNumber
			r	:= LV_GetNext()
			Sleep	100
			LV_GetText( p, r, 2 )
			GuiControl,	,			pic,%	p
			GuiControl,	MoveDraw,	pic,%	"w" Floor(Round((A_ScreenWidth/10)*6.75))	" h" Floor(Round((A_ScreenWidth/10)*7)/16*9)
		}
		else if( A_EventInfo = 38 )		{
			OutputDebug % "L2 38 " A_LineNumber
			r	:= LV_GetNext()
			Sleep	100
			LV_GetText( p, r, 2 )
			GuiControl,	,			pic,%	p
			GuiControl,	MoveDraw,	pic,%	"w" Floor(Round((A_ScreenWidth/10)*6.75))	" h" Floor(Round((A_ScreenWidth/10)*7)/16*9)
		}
	}
	return

GuiContextMenu:
	IfWinActive,	Gestão
	if( A_GuiControl != "L1" ) {
		one_file := 1
		Menu, mcm2, Show, %A_GuiX%, %A_GuiY%
	}
	Else {
		one_file := 0
		Menu, mcm, Show, %A_GuiX%, %A_GuiY%
	}
	return

_configurar:
	Gui,	ListView,	L1
	d := LV_GetNext( 0, "F" )
	LV_GetText( d, d, 2 )
	Run,	http://%d%
	return

~Delete::
	_limpar:
		OutputDebug % "Delete " A_LineNumber
		Gui,	ListView,	L2
		LV_Delete()
		Gui,	ListView,	L1
		Gui,	Submit,	NoHide
		row := LV_GetNext(0, "F")
		LV_GetText(ip,row,2)
		LV_GetText(count,row,3)
		GuiControl, , total,% "Total de imagens " total_imagens := total_imagens-count
		OutputDebug % "listview " A_DefaultListView
		LV_Delete(row)
		GuiControl, Focus, L1
		LV_GetText(ip1,1,2)
		OutputDebug % " new ip -" ip1 "-"
		gosub fill_l2
		deleted .= ip "`n"
		code	:=	"#notrayicon"
				.	"`nLoop,	Files,	\\srvftp\Monitoramento\FTP\Verificados\" dia_verificar "\*.jpg"
				.	"`nIf RegexMatch( A_LoopFileName, """ ip """ )"
				.	"`nFileDelete,`%	A_LoopFileFullPath"
				.	"`nExitApp"
		new_instance(code)
	return

save_all:
	OutputDebug % "Salva todas " A_LineNumber
	Gui,	ListView,	L1
	rowl1	:= LV_GetNext(0, "F")
	Gui,	ListView,	L2
	rowl2	:= LV_GetNext(0, "F")
	if	one_file {
		LV_GetText( file_path, rowl2, 2 )
		LV_Delete( rowl2 )
		filepath := SubStr( file_path, InStr( file_path, "\",, -0 )+1 )
		code	:=	"#notrayicon"
				.	"`nFileCreateDir, \\srvftp\Monitoramento\FTP\Verificados\Salvas\`%A_YYYY`%-`%A_MM`%-`%A_DD`%"
				.	"`nFileMove," file_path ", \\srvftp\Monitoramento\FTP\Verificados\Salvas\`%A_YYYY`%-`%A_MM`%-`%A_DD`%\" filepath
				.	"`nExitApp"
		
		GuiControl, , total,% "Total de imagens " total_imagens := total_imagens-1
		If !LV_GetCount( l2 ) {
			Gui,	ListView,	L1
			LV_Delete( rowl1 )
			GuiControl, Focus, L1
			LV_Modify( rowl1-1 != 0 ? rowl1-1 : rowl1+1, "Select" )
		}
		Else {
			Gui,	ListView,	L2
			LV_GetText( p, rowl2-1, 2 )
			GuiControl,	,			pic,%	p
			GuiControl,	MoveDraw,	pic,%	"w" Round((A_ScreenWidth/10)*6)	" h"Round((A_ScreenWidth/10)*6)/16*9
			GuiControl, Focus, L2
			LV_Modify( rowl2-1 != 0 ? rowl2-1 : rowl2+1, "Select" )
		}
		
		new_instance(code)
	}
	Else {
		Gui,	ListView,	L2		
		LV_Delete()
		Gui,	ListView,	L1
		Gui,	Submit,	NoHide
		LV_GetText( ip, rowl1, 2 )
		LV_GetText( count, rowl1, 3 )
		GuiControl, , total,% "Total de imagens " total_imagens := total_imagens-count
		LV_Delete( rowl1 )
		GuiControl, Focus, L1
		LV_GetText( ip1, 1, 2 )
		deleted .= ip "`n"
		code	:=	"#notrayicon"
				.	"`nFileCreateDir, \\srvftp\Monitoramento\FTP\Verificados\Salvas\`%A_YYYY`%-`%A_MM`%-`%A_DD`%"
				.	"`nLoop,	Files,	\\srvftp\Monitoramento\FTP\Verificados\" dia_verificar "\*.jpg"
				.	"`n`tIf RegexMatch( A_LoopFileName, """ ip """ )"
				.	"`n`t`tFileMove,`%	A_LoopFileFullPath, \\srvftp\Monitoramento\FTP\Verificados\Salvas\`%A_YYYY`%-`%A_MM`%-`%A_DD`%\`%A_LoopFileName`%"
				.	"`nExitApp"
				new_instance(code)
				gosub fill_l2
	}
	Return

fl:
	Run, \\srvftp\FTP\Inibidos
	Return

fs:
	Run, \\srvftp\FTP\Verificados\Salvas
	Return

GuiClose:
	ExitApp
