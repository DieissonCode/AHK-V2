/*
	File_Version=0.2.0
	Save_To_Sql=1
	Keep_Versions=3
	Development=0
	Software_Name=MDKah
*/

;@Ahk2Exe-SetMainIcon C:\AHK\icones\_gray\2motion.ico
/*
	[MotionDetection]
*/

;	Includes
	#Include C:\AutoHotkey\class\array.ahk
	#Include C:\AutoHotkey\class\auth.ahk
	#Include C:\AutoHotkey\class\dguard.ahk
	#Include C:\AutoHotkey\class\date.ahk
	#Include C:\AutoHotkey\class\functions.ahk
	#Include C:\AutoHotkey\class\gui.ahk
	#Include C:\AutoHotkey\class\mail.ahk
	#Include C:\AutoHotkey\class\timer.ahk

;	Configuração
		#Persistent
		#SingleInstance, Force
		If	A_IsCompiled
			auto_update(,1)
		Menu, Tray, Icon, C:\Seventh\Backup\ico\2motion.ico
		version := sql_version()
			Menu, Tray, Tip ,% "Detecção de Movimento v" version[1] "`nCompilação: " version[2]

;	Variáveis e Timer
	Global	file_path
		,	Token

	settings_dir	:= "C:\Users\" A_UserName "\AppData\Local\KahCool\Motion Detection"
		IfNotExist,% settings_dir
			FileCreateDir,%	settings_dir

	folder_ftp	= \\srvftp\monitoramento\FTP\

	inibidas := []

	ip := StrSplit( A_IPAddress1, "." )
		If	ip[4] not in ( "100", "102", "106", "109", "114", "118", "123" )
			ExitApp

	ip_cam = 999.999.999.999		;	Não pode ser vazio

	Gui.ScreenSizes()

	Loop {	;	espera o dguard estar rodando a pelo menos 60 segundos

		Sleep, 1000
		If	process_exist( "dguard", 60 )
			Break

	}

	Gosub	dguard_auto_open_layouts	;	prepara lista de câmeras para buscar imagens

	Switch	A_IPAddress1	{
	
		Case "192.9.100.100", A_UserName = "dsantos":
			oper := "0000"

		Case "192.9.100.102":
			oper := "0001"
			Menu, Tray, Nostandard

		Case "192.9.100.106":
			oper := "0002"
			Menu, Tray, Nostandard

		Case "192.9.100.109":
			oper := "0003"
			Menu, Tray, Nostandard

		Case "192.9.100.114":
			oper := "0004"
			Menu, Tray, Nostandard

		Case "192.9.100.118":
			oper := "0005"
			Menu, Tray, Nostandard

		Case "192.9.100.123":
			oper := "0006"
			Menu, Tray, Nostandard
	}

	folder_operador := "\\srvftp\monitoramento\FTP\" oper "\*.jpg"
	FileDelete,% settings_dir "\inibidas.ini"
	SetTimer, verifica_imagens,	1000

return

verifica_imagens:
	If( A_IsCompiled && ip[4] = "100" )
		Return

	exibe_cameras	:= ""
	hora_agora		:= SubStr( A_Now, 9 )
	;	Recarrega o sistema
		If(	hora_agora > "200000" && hora_agora < "200005" )
			Reload

	;	Verifica se está em pause
		if	paused
			Return

	;	Verifica se é horário de detecção e se está compilado
		OutputDebug % "Verifica se é horário de detecção"
		If( hora_agora < "203000"		;	Fora da faixa de horário de execução
		&&	hora_agora > "060000" )	{

			ico			:= "2motionp"
			2_operadores:= 0

		}
		Else
			ico			:= "2motion"
		Menu,	Tray,	Icon,%	"C:\Seventh\Backup\ico\" ico ".ico"
		Menu	Tray,	Tip,%	"Detecção de Movimento v" version[1] "`nCompilação: " version[2]

	;	Impede de abrir duas detecções simultaneamente
		OutputDebug % "Impede de abrir duas detecções simultaneamente"
		IfWinActive, Detecção de Movimento
			WinWaitClose, Detecção de Movimento

	;	Loop imagens
		OutputDebug, % "Imagens"
		Loop, Files,%	folder_operador
			{

				If(	A_LoopFileFullPath = fullfile )						;	Se for o mesmo arquivo
				||(	(hora_agora > "060000" && hora_agora < "203000" )	;	Não for horário de detecção
					&&	A_IPAddress1	!= "192.9.100.100"	){			;		e não for o computador do facilitador

					FileDelete,%	A_LoopFileFullPath
					Continue

				}

				arquivo			:=	StrSplit( A_LoopFileName, "_" )
				data_e_hora		:=	StrRep( arquivo[1],, "-" )
				ip_cam			:=	arquivo[2]
				nome_da_camera	:=	StrReplace( arquivo[3], "-", "|", , 1 )
				op_sinistro		:=	StrReplace( arquivo[4], ".jpg" )

				;	INIBIDAS
					OutputDebug, % "inibidas"
					IniRead, seconds_today,%	settings_dir "\inibidas.ini",% ip_cam,% A_YDay
					IniRead, delete_today,%		settings_dir "\inibidas.ini",% ip_cam,  deletando
					IniRead, seconds_tomorrow,%	settings_dir "\inibidas.ini",% ip_cam,% A_YDay+1
					
					if( seconds_tomorrow != "ERROR" ) {	;	INIBIDO até o próximo dia
						If( delete_today = "ERROR" ) {

						delete_inhibited = 
							(
								#NoTrayIcon`n
								Loop, Files,%folder_operador%`n
									If	InStr( A_LoopFileFullPath, "%ip_cam%" )
										FileDelete,`% A_LoopFileFullPath
								ExitApp
							)
							new_instance( delete_inhibited )

						}
						Continue

					}
					Else If(seconds_today != "ERROR"	;	Inibida até HOJE e
					&&		real_day_time_in_seconds() < seconds_today ) { ;	 ainda NÃO expirou o tempo de inibição

						If( delete_today = "ERROR" ) {
							delete_inhibited = 
								(
									#NoTrayIcon`n
									Loop, Files,%folder_operador%`n
										If	InStr( A_LoopFileFullPath, "%ip_cam%" )
											FileDelete,`% A_LoopFileFullPath
									ExitApp
								)

							new_instance( delete_inhibited )

						}
						Continue

					}
					Else If( seconds_today != "ERROR"	;	Inibida até HOJE e
					&&	real_day_time_in_seconds() > seconds_today ) ;			horário de inibição EXPIRADO
						IniDelete,%	settings_dir "\inibidas.ini",% ip_cam,% A_YDay

				displayed	:=	datetime(1)
				fullfile	:=	A_LoopFileFullPath
				h			:=	A_Hour
				m			:=	A_Min
				s			:=	A_Sec
				Goto	Interface

			}

return

;	Botões
	b_all:

		exibe_cameras := !exibe_cameras
		Switch	{

			Case exibe_cameras:
				GuiControl,, _all, Exibir layout padrão
				n := StrSplit( nome_da_camera, "]" )
				Switch	{

					Case SubStr( n[1], 1, 3) = "NMT", SubStr( n[1], 1, 3) = "LVD":
						Switch	{

							Case SubStr( nome_da_camera, 1, 13 ) = "NMT [ SUP ] S":
								layout_guid	:=	__layouts[ SubStr( nome_da_camera, 1, 16 ) ]

							Case SubStr( nome_da_camera, 1, 13 ) = "NMT [ SUP ] C":
								layout_guid	:=	__layouts[ SubStr( nome_da_camera, 1, 18 ) ]

							Case SubStr( nome_da_camera, 1, 3 ) = "LVD [ DEF ]":
								layout_guid	:=	__layouts[ SubStr( nome_da_camera, 1, 11 ) ]

							Default:
								layout_guid	:=	__layouts[ SubStr( n[1], 1, 3) ]

						}

					Default:
						layout_guid	:=	__layouts[ SubStr( n[1], 1, 3) ]

				}

			Default:
				GuiControl,	,	_all, Exibir câmeras da unidade
				layout_guid	:=	__layouts[ "_Layout4" ]

		}

		Dguard.layout_show( "", layout_guid, monitor_guid, workstation_guid )

	Return

	confirmar:
		Gui, Submit, NoHide
		If( StrLen( motivo ) < 10
		||	StrLen( motivo ) > 150 )	{
			if( is_live = 0 )
				WinSet,	AlwaysOnTop,	Off,	Detecção de Movimento
			else
				WinSet,	AlwaysOnTop,	Off,	Live
			MsgBox O encerramento do evento precisa ter pelo menos 10 carateres e no máximo 150 caracteres.
			If( is_live = 0 )
				WinSet,	AlwaysOnTop,	On,	Detecção de Movimento
			Else
				WinSet,	AlwaysOnTop,	On,	Live
			return
		}
		Else	{
			If( inibidor = 1 )	{
				t_ini	:=	Floor( StrReplace( inibe, " Minutos" ) / 60 )
				i_a		:=	A_Hour + t_ini
				if( t_ini = "0" )	{					;	Se foi 30
					if( ( A_Min + 30 ) >= "60" )	{	;	se passa de 1 hora
						i_a	:=	A_Hour+1
						m	:=	( A_min + 30 ) - 60
					}
					else
						m	:=	A_min+StrReplace( inibe, " Minutos" )
				}
				if( i_a > 24 )	{						;	se passou da meia noite
					i_a			:=	Round( i_a - 24 )
					next_day	=	1
				}
				if( i_a = 24 )	{						;	Se for meia noite
					i_a			:=	"00"
					next_day	=	1
				}
				else
					i_a			:=	Round( i_a )
				if( StrLen( m ) = "1" )
					m	:=	"0" m
				FileMove,% fullfile ,% folder_ftp "Inibidos\" ip_cam " - " oper " - " StrRep( nome_da_camera,, ".jpg", "|:-" ) " - " SubStr( A_Now, 1, 8 ) "_" SubStr( A_Now, 9 ) " - " inibe ".jpg", 1
			}
			if( ocorrencia = 1 ){	
				dia_verificar	:= MOD( A_YDay, 2 ) = 1 ? "Dia 1" : "Dia 2"
				move_path		:=	folder_ftp														;	\\srvftp\monitoramento\FTP\
							.	"Verificados\" dia_verificar "\"
							.	SubStr( data_e_hora, 1, 8 ) "-"	SubStr( data_e_hora, 9 ) "_"	;	YYYYMMDD-HHmmss_
							.	ip_cam "_"														;	10.1.52.118
							.	oper "_"														;	0000
							.	StrRep( nome_da_camera,, ".jpg", "|:-" )						;	SD | M. Sede Caixas 1 a 4
							.	".jpg"															;	extensão
				FileMove,% fullfile ,% move_path, 1
			}
			exibido=
			Gosub	sql
		}
		Gui,	Destroy
		Gui,	live:Destroy
	return

	b_pause:
		Gui,	Destroy
		paused := 1
		SetTimer, Pause_counter, -60000
	return

	b_inibir:

		inibidor	:=	!inibidor
		if(	inibidor	=	1)	{
			GuiControl,	Show,	bText
			GuiControl,	Show,	inibe
			GuiControl,	Show,	conf
			GuiControl,	Show,	canc
			GuiControl,	Show,	motivo
			GuiControl,	Hide,	nada
			GuiControl,	Hide,	Sini
			GuiControl,	Hide,	Pause
			GuiControl,	Hide,	mov
			GuiControl,		,	ini,	Voltar
			GuiControl,	Focus,	motivo
		}	else	{
			GuiControl,	Hide,	bText
			GuiControl,	Hide,	inibe
			GuiControl,	Hide,	conf
			GuiControl,	Hide,	canc
			GuiControl,	Hide,	motivo
			GuiControl,	Show,	Sini
			GuiControl,	Show,	Pause
			GuiControl,	Show,	nada
			GuiControl,	Show,	mov
			GuiControl,		,	ini,	Inibir eventos
		}

	return

	b_movimento:
		ocorrencia	:=	!ocorrencia
		if(	ocorrencia = 1	)	{
			GuiControl,	Hide,	bText
			GuiControl,	Hide,	inibe
			GuiControl,	Show,	moti
			GuiControl,	Show,	bMot
			GuiControl,	Show,	conf
			GuiControl,	Show,	canc
			GuiControl,	Hide,	motivo
			GuiControl,	Hide,	nada
			GuiControl,	Hide,	Sini
			GuiControl,	Hide,	Pause
			GuiControl,	Hide,	ini
			GuiControl,		,	mov,	Voltar
			GuiControl,	Show,	motivo
			GuiControl,	Focus,	motivo
		}	else	{
			GuiControl,	Hide,	bText
			GuiControl,	Hide,	inibe
			GuiControl,	Hide,	moti
			GuiControl,	Hide,	bMot
			GuiControl,	Hide,	conf
			GuiControl,	Hide,	canc
			GuiControl,	Hide,	motivo
			GuiControl,	Show,	nada
			GuiControl,	Show,	Sini
			GuiControl,	Show,	Pause
			GuiControl,	Show,	ini
			GuiControl,		,	mov,	Evento devido a...
			GuiControl,	Hide,	motivo
		}
	return

	sem_motivo:
		nada	=	1
		Gui,	Destroy
		Gui,	live:Destroy
		dia_verificar	:= MOD( A_YDay, 2 ) = 1 ? "Dia 1" : "Dia 2"
		; MsgBox % Clipboard := folder_ftp							;	\\srvftp\monitoramento\FTP\
				; .	"Verificados\" dia_verificar "\"	
				; .	SubStr( data_e_hora, 1, 8 ) "-"				;	YYYYMMDD-
				; .	SubStr( data_e_hora, 9 ) "_"				;	HHmmss_
				; .	ip_cam "_"									;	10.1.52.118
				; .	oper "_"									;	0000
				; .	StrRep( nome_da_camera,, ".jpg" )			;	SD - M. Sede Caixas 1 a 4
				; .	".jpg"	
		move_path	:=	folder_ftp									;	\\srvftp\monitoramento\FTP\
				.	"Verificados\" dia_verificar "\"	
				.	SubStr( data_e_hora, 1, 8 ) "-"				;	YYYYMMDD-
				.	SubStr( data_e_hora, 9 ) "_"				;	HHmmss_
				.	ip_cam "_"									;	10.1.52.118
				.	oper "_"									;	0000
				.	StrRep( nome_da_camera,, ".jpg", "|:-" )	;	SD - M. Sede Caixas 1 a 4
				.	".jpg"										;	extensão
		FileMove,% fullfile ,% move_path, 1
		Gosub SQL
	return

	b_sinistro:
		WinSet,	AlwaysOnTop,	Off,	Detecção de Movimento
		MsgBox,	52,	Sinistro Em Andamento, Somente utilizar essa opção em caso de SINISTRO`, as imagens geradas durante 15 minutos serão direcionadas ao(s) operador(es) ao(s) lado(s).
		IfMsgBox,	Yes
		{
			2_operadores = 1
			u	=	;	user logado
			(
				SELECT	TOP(1)	[LOG~USUARIO],[LOG~ORDEM]
				FROM	[BdIrisLog].[dbo].[SYS~Log]
				WHERE	[LOG~DADOS]		=	'Login no Painel de Monitoramento.'
				AND		[LOG~ESTACAO]	=	'%A_ComputerName%'
				ORDER	BY	2	DESC
			)
			u	:=	sql(u)
			user_iris	:=	u[2,1]
				If(	StrLen(	u[ 2, 1 ]	) < 3 )
					user_iris	:=	A_IPAddress1

			;	Data e horário de inicio e para Encerrar
				iniciou		:=	Date.toSeconds()
				finalizar	:=	Date.toSeconds( A_Now + 1500 )	;	15 minutos - Padrão
			;

			operador_	=	;	MUDAR PARA TABELA SINISTRO
				(
					INSERT INTO
						[MotionDetection].[dbo].[operadores]
							( [ip]				, [patrimonio]		, [operador]	, [inicio]		, [fim] )
						VALUES
							( '%A_IPAddress1%'	, '%A_ComputerName%', '%user_iris%'	, '%iniciou%'	, '%finalizar%' )
				)
			operador_	:=	sql( operador_, 3 )

			Gui,	Destroy
			Gui,	live:Destroy
			Loop,	\\srvftp\monitoramento\FTP\%oper%\*.jpg
			{
				arquivo			:=	StrSplit(A_LoopFileName, "_" )
				data_e_hora		:=	StrRep( arquivo[1],, "-" )
				ip_cam			:=	arquivo[2]
				nome_da_camera	:=	arquivo[3]
				op_sinistro		:=	StrRep( arquivo[4],, ".jpg" )
				FileMove,%	A_LoopFileFullPath,	\\srvftp\monitoramento\FTP\%op_sinistro%\%A_LoopFileName%
			}
			Menu,	Tray,	Icon,	C:\Seventh\Backup\ico\2motion.ico
			SetTimer,	sinistro_counter,	1000
			Menu,	Tray,	Add,	Finalizar sinistro, Restauro
		}
		else
			WinSet,	AlwaysOnTop,	On,	Detecção de Movimento
	return
;

dguard_auto_open_layouts:

	if	!Token
		token	:=	Dguard._token("", "", "")

	OutputDebug, % Dguard.virtual_matrix("", token)
	m	:=	Dguard.workstation("", token, "", "", "")
	monitor_guid	:=	m.workstations[1].monitors[	m.workstations[1].monitors.Count() ].guid
	workstation_guid:=	m.workstations[1].guid

	__layouts	:=	{}
		__var	:=	dguard.layouts( "", token, "", "GET" )
		OutputDebug, % "Layouts locais = " __var.Count()
		For value, in __var
		__layouts[ value ] :=	__var[value].guid

	_cam_list := {}
		cam_return	:= StrSplit( HttpGet( "http://localhost/camerasnomes.cgi" ), "&")
		OutputDebug, % "Câmeras locais = " cam_return.Count()
		Loop,%	cam_return.Count()	{
			dados			:=	StrSplit( cam_return[A_Index], "=" )
			nome			:=	StrSplit( dados[2] , ".")
			z_cam_list		:=	nome[1]
			z	:=	{	camera	:	nome[1]
					,	cam_id	:	dados[1]	}
			_cam_list[z_cam_list]	:=	z
			VarSetCapacity(z_cam_list,0)

		}

Return

ao_vivo:
	;	Prepara variáveis
		WinSet,	AlwaysOnTop,	Off,	Detecção de Movimento
		is_live	:=	1
		Erro	:=	""
		ID		:=	_cam_list[nome_da_camera].cam_id
		if	!ID	{

			FileAppend,%	oper " - " nome_da_camera " - " A_IPAddress1 " `t " datetime() "`n", \\srvftp\Monitoramento\FTP\Log\Falha nos ID.txt
			MsgBox,,Câmera Indisponível para visualização, Câmera indisponível no momento para visualização.`nEm caso de emergência visualizar no Ctrl+3 - Layout TODAS
			WinSet,	AlwaysOnTop,	On,	Detecção de Movimento
			Goto	liveClose

		}

	vlcx.playlist.stop()	
	Gui, live:Destroy
	options	=	""

	If	A_IsCompiled
		Gui,	live: -Border +AlwaysOnTop	+ToolWindow
	Gui,	live:Font, S15 Bold
	Gui,	live:Add, Button,	 x10		y0									gliveClose			,	Fechar visualização ao Vivo
	Gui,	live:Add, Text,%	"x320	y0								vaovivo				cGreen"	,%  nome_da_camera
	Gui,	live:Add, ActiveX,%	"x10	y45	w" monitor_w " h" work_h "	vVlcx"						,	VideoLAN.VLCPlugin.2
	Gui,	live:Color, 000000,	FFFFFF
	Gui,	live:Show,%			"x0		y0	w" monitor_w " h" work_h								,	Live
	Gui,	live:Font
	vlcx.playlist.add( "http://admin:%40dm1n@localhost/mjpegstream.cgi?camera=" id, "", options )
	vlcx.playlist.play()

return

dois_operadores:
	ToolTip, Desabilitado...
	Sleep, 5000
	Tooltip
	Return
	2_operadores	:=	!2_operadores
	If( 2_operadores= 1 )	{
		Gui,	Destroy
		paused = 1
		autenticou	:=	Auth.login( "operadores", , ,"mdkah" )
		Loop
			If( StrLen( autenticou ) > 0 )	{
				if( SubStr( autenticou, 1, 1 ) = 1 )
					Goto autenticou
				if( SubStr( autenticou, 1, 1 ) = 0 )	{
					WinSet,	AlwaysOnTop,	Off,	Login Cotrijal
					MsgBox,,Autenticação Falhou,	Verifique seu usuário e senha.
					paused = 0
					Return
				}
			}
		autenticou:
		; logs.habilitou( SubStr( autenticou, 3 ), "Modo 2 operadores" )
		Menu, Tray, Tip,%	"Detecção de Movimento - Modo 2 Operadores v" version[1] "`nCompilação: " version[2]
		Menu, Tray, Delete, Trabalho com 2 operadores
		Menu, Tray, Add, Desabilitar Modo 2 operadores, dois_operadores
	}
	else	{
		paused = 0
		Menu, Tray, Tip,%	"Detecção de Movimento v" version[1] "`nCompilação: " version[2]
		Menu, Tray, Add,	Trabalho com 2 operadores, dois_operadores
		Menu, Tray, Delete, Desabilitar Modo 2 operadores
	}
return

HttpGet( URL )	{

	responseText=
	static	req	:=	ComObjCreate( "Msxml2.XMLHTTP.6.0" )
	; static	req	:=	ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
	req.open( "GET", URL, false )
	req.SetRequestHeader( "If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT" )
	req.SetRequestHeader( "Authorization", "Basic YWRtaW46QGRtMW4=" )
	req.send()
	Return	req.responseText

}

Interface:
	IfWinActive, Detecção de Movimento
		WinWaitClose, Detecção de Movimento
	If A_IsCompiled
		Gui,	-Border	+AlwaysOnTop +ToolWindow
	Else
		Gui,	-Border	+ToolWindow

	Gui, Add,	Pic,%			"x10  	y45 			w" monitor_w "	h" work_h-7	"	vPic"							,%	fullfile
		Gui, Font,	S12
	Gui, Add,	Edit,%			"x10 	y" work_h-125 "	w999	h100					vmotivo				Hidden"
		
	Gui, Add,	Button,%		"x10	y" work_h-25 "	w150	h25		gsem_motivo		vnada	-TabStop"	Gui.Font()	, Sem motivo aparente
	Gui, Add,	Button,%		"xp+151	y" work_h-25 "	w150	h25		gb_movimento	vmov	-TabStop"				, Evento devido a...
	Gui, Add,	Button,%		"xp+151	y" work_h-25 "	w150	h25		gb_inibir		vini	-TabStop"				, Inibir eventos
	Gui, Add,	Button,%		"xp+151	y" work_h-25 "	w150	h25		gb_all			v_all	-TabStop"				, Exibir câmeras da unidade
	; Gui, Add,	Button,%		"xp+151	y" work_h-25 "	w150	h25		gb_sinistro		vSini	-TabStop"				, Sinistro em Andamento
	Gui, Add,	Button,%		"xp+151	y" work_h-25 "	w150	h25		gb_Pause		vPause	-TabStop"				, Pausar por 60 Segundos
	; Gui, Add,	Button,%		"xp+302	y" work_h-25 "	w150	h25		gb_Pause		vPause	-TabStop"				, Pausar por 30 Segundos
	Gui, Add,	Button,%		"xp+400	y" work_h-125 "	w260	h21						vbText	Center		Hidden	"	, % "Inibir " nome_da_camera " por:"
	Gui, Add,	DropDownList,%	"xp		yp+20			w260	h30						vinibe	Choose2	r7	Hidden	"	, 30 Minutos|60 Minutos|120 Minutos|180 Minutos|240 Minutos
	Gui, Add,	Button,			 xp		yp-20			w260	h21						vbMot	Center		Hidden		,  Escolher motivo do movimento no local:
	Gui, Add,	DropDownList,%	"xp		yp+20			w260	h30		gmoti			vmoti	Choose1	r7	Hidden	"	, |Moradores da unidade|Animais no local|Veículos passando na parte externa|Chuva e/ou relâmpagos|Colaboradores trabalhando no local|Insetos ou poeira em frente a câmera|Fonte de luz incidindo sobre a câmera|Vigilante realizando ronda
	Gui, Add,	Button,%		"xp		y" work_h-25 "	w260	h25		gConfirmar		vconf	-TabStop	Hidden	"	, Confirmar
		Gui, Font,	S15 Bold
	Gui, Add,	Text,%			"x200	y0																	cGreen	"	, % StrRep( nome_da_camera,".jpg" ) " | "	datetime( data_e_hora )
	Gui, Add,	Button,%		"x10	y0								gao_vivo		vlive	-TabStop			"	,	Verificar Ao Vivo
		Gui, Font
		Gui, Color,	000000, FFFFFF
	Gui, Show ,%				"x0		y0				 w" monitor_w-7 " h"	work_h								 	, Detecção de Movimento
	Sleep	1000
		WinWaitClose, Detecção de Movimento
return

liveClose:

	vlcx.playlist.stop()
	If A_IsCompiled
		WinSet,	AlwaysOnTop,	On,	Detecção de Movimento

	is_live	:=	0
	Gui,	live:Destroy

return

moti:	;motivo

	Gui,	Submit,	NoHide
	GuiControl,	,	motivo,	%moti%

return

Pause_Counter:

	paused := 0

return

Restauro:	;	restaura o Sinistro

	2_operadores=	0
	Menu,		Tray,	Icon,	C:\Seventh\Backup\ico\2motion.ico
	SetTimer,	sinistro_counter,	Off
	Menu, 		Tray, Tip, %	"Detecção de Movimento v" version[1] "`nCompilação: " version[2]
	FormatTime,	agora,	A_Now,	yyy/MM/dd HH:m:ss

	up_sini	=
		(
			UPDATE
				[MotionDetection].[dbo].[operadores]
			SET
				[Finalizado] = GetDate()
			WHERE
				[ip] = '%A_IPAddress1%'
			AND
				[Finalizado] is NULL
		)
		sql( up_sini, 3 )

return

sinistro_counter:	;	traytip apenas

	agora_	:=	Date.toSeconds( A_Now )
	If( agora_ > finalizar && agora_ < finalizar + 5 )
		goto	Restauro

	minutos		:=	Floor( ( finalizar - agora_ ) /60 )
	segundos	:=	( finalizar - agora_ ) - ( minutos * 60 )
	if( StrLen( segundos ) < 2 )
		segundos	:=	"0"	segundos

	resta	:=	"Tempo até expirar o sinistr: "	minutos ":"	segundos
	Menu,	Tray,	Tip,	%resta%

return

sql:
	u	=	;	Usuário Logado
		(
			SELECT TOP(1)
				[LOG~USUARIO],
				[LOG~ORDEM]
			FROM
				[BdIrisLog].[dbo].[SYS~Log]
			WHERE
				[LOG~DADOS] = 'Login no Painel de Monitoramento.'
			AND
				[LOG~ESTACAO] = '%A_ComputerName%'
			ORDER BY
				2 DESC
		)
		u	:=	sql( u )
		usuarioatual	:=	u[2,1]
	;

	Switch	{
	
		Case inibidor:
			nome		:=	StrRep( nome_da_camera,, ".jpg" )
			data		:=	datetime( 1, data_e_hora )
			data_exibida:=	datetime( 1, displayed )
			agora		:=	datetime( 1, A_Now )

			minutos		:=	StrRep( inibe,, " Minutos" )
			if( next_day = 1 )
				dia	:=	A_YDay+1
			else
				dia	:=	A_YDay
			inibir_ate	:=	( i_a * 60 * 60 ) + ( m * 60 ) + s
			operador_ini:=	oper
			inibidor	:=	0

			If((A_Min = "29" || A_Min = "59"
			&&	inibidas.Count() > 0) ) {
				Loop,%	inibidas.Count() {
					dados_inibidas := StrSplit( inibidas[A_Index], "|" )
					insert_inibidas := "( '" dados_inibidas[1] "','"
									.		 dados_inibidas[2] "','"
									.		 dados_inibidas[3] "','"
									.		 dados_inibidas[4] "','"
									.		 dados_inibidas[5] "','"
									.		 dados_inibidas[6] "','"
									.		 dados_inibidas[7] "','"
									.		 dados_inibidas[8] "','"
									.		 dados_inibidas[9] "' )," 
				}
				insert_inibidas := SubStr( insert_inibidas, 1, -1 )
				finaliza1	=
					(
						INSERT INTO [MotionDetection].[dbo].[Encerrados]
							( [Camera]
							, [Gerado]
							, [Exibido]
							, [Finalizado]
							, [Usuario]
							, [Ocorrido]
							, [Descricao]
							, [IP]
							, [Operador] )
						VALUES
							%insert_inibidas%
					)
					sql( finaliza1, 3 )

				inibidas:=[]
			}
			Else
				inibidas.Push( nome "|" data  "|" data_exibida "|" agora "|" usuarioatual "|Inibido - " minutos " minutos|" motivo "|" ip_cam "|" operador_ini )

			IniWrite,% inibir_ate,%	 settings_dir "\inibidas.ini",% ip_cam,% dia
			next_day =

		Case ocorrencia:
			campo1		:=	StrRep( nome_da_camera,, ".jpg" )
			campo2		:=	datetime( 1, data_e_hora )
			campo3		:=	datetime( 1, displayed )
			campo4		:=	datetime( 1, A_Now )
			campo5		:=	usuarioatual
			campo7		:=	"Ocorrência"
			campo8		:=	motivo
			campo9		:=	ip_cam
			campo10		:=	oper
			ocorrencia	:=	0
			finaliza	=
				(
					INSERT INTO [MotionDetection].[dbo].[Encerrados]
						( [Camera]
						, [Gerado]
						, [Exibido]
						, [Finalizado]
						, [Usuario]
						, [Ocorrido]
						, [Descricao]
						, [IP]
						, [Operador]	)
					VALUES
						( '%campo1%'
						, '%campo2%'
						, '%campo3%'
						, '%campo4%'
						, '%campo5%'
						, '%campo7%'
						, '%campo8%'
						, '%campo9%'
						, '%campo10%'	)
				)
				Log := sql( finaliza, 3 )

		Case Nada:
			campo1	:=	StrRep( nome_da_camera,, ".jpg" )
			campo2	:=	datetime( 1, data_e_hora )
			campo3	:=	datetime( 1, displayed )
			campo4	:=	datetime( 1, A_Now )
			campo5	:=	usuarioatual
			campo7	:=	"Sem Motivo Aparente"
			campo8	:=	""
			campo9	:=	ip_cam
			campo10	:=	oper
			nada	=	0
			finaliza=
				(
					INSERT INTO [MotionDetection].[dbo].[Encerrados]
						( [Camera]
						, [Gerado]
						, [Exibido]
						, [Finalizado]
						, [Usuario]
						, [Ocorrido]
						, [Descricao]
						, [IP]
						, [Operador]	)
					VALUES
						( '%campo1%'
						, '%campo2%'
						, '%campo3%'
						, '%campo4%'
						, '%campo5%'
						, '%campo7%'
						, '%campo8%'
						, '%campo9%'
						, '%campo10%'	)
				)
				Log	:=	sql( finaliza, 3 )

	}
	
	; if( inibidor = 1 )	{
	; 	nome		:=	StrRep( nome_da_camera,, ".jpg" )
	; 	data		:=	datetime( 1, data_e_hora )
	; 	data_exibida:=	datetime( 1, displayed )
	; 	agora		:=	datetime( 1, A_Now )

	; 	minutos		:=	StrRep( inibe,, " Minutos" )
	; 	if( next_day = 1 )
	; 		dia	:=	A_YDay+1
	; 	else
	; 		dia	:=	A_YDay
	; 	inibir_ate	:=	( i_a * 60 * 60 ) + ( m * 60 ) + s
	; 	operador_ini:=	oper
	; 	inibidor	 =	0

	; 	If((A_Min = "29" || A_Min = "59"
	; 	&&	inibidas.Count() > 0) ) {
	; 		Loop,%	inibidas.Count() {
	; 			dados_inibidas := StrSplit( inibidas[A_Index], "|" )
	; 			insert_inibidas := "( '" dados_inibidas[1] "','"
	; 							.		 dados_inibidas[2] "','"
	; 							.		 dados_inibidas[3] "','"
	; 							.		 dados_inibidas[4] "','"
	; 							.		 dados_inibidas[5] "','"
	; 							.		 dados_inibidas[6] "','"
	; 							.		 dados_inibidas[7] "','"
	; 							.		 dados_inibidas[8] "','"
	; 							.		 dados_inibidas[9] "' )," 
	; 		}
	; 		insert_inibidas := SubStr( insert_inibidas, 1, -1 )
	; 		finaliza1	=
	; 			(
	; 				INSERT INTO [MotionDetection].[dbo].[Encerrados]
	; 					( [Camera]
	; 					, [Gerado]
	; 					, [Exibido]
	; 					, [Finalizado]
	; 					, [Usuario]
	; 					, [Ocorrido]
	; 					, [Descricao]
	; 					, [IP]
	; 					, [Operador] )
	; 				VALUES
	; 					%insert_inibidas%
	; 			)
	; 			sql( finaliza1, 3 )

	; 		inibidas:=[]
	; 	}
	; 	Else
	; 		inibidas.Push( nome "|" data  "|" data_exibida "|" agora "|" usuarioatual "|Inibido - " minutos " minutos|" motivo "|" ip_cam "|" operador_ini )

	; 	IniWrite,% inibir_ate,%	 settings_dir "\inibidas.ini",% ip_cam,% dia
	; 	next_day =

	; }
	; else if( ocorrencia = 1 )	{
	; 	campo1		:=	StrRep( nome_da_camera,, ".jpg" )
	; 	campo2		:=	datetime( 1, data_e_hora )
	; 	campo3		:=	datetime( 1, displayed )
	; 	campo4		:=	datetime( 1, A_Now )
	; 	campo5		:=	usuarioatual
	; 	campo7		:=	"Ocorrência"
	; 	campo8		:=	motivo
	; 	campo9		:=	ip_cam
	; 	campo10		:=	oper
	; 	ocorrencia	=	0
	; 	finaliza	=
	; 		(
	; 			INSERT INTO [MotionDetection].[dbo].[Encerrados]
	; 				( [Camera]
	; 				, [Gerado]
	; 				, [Exibido]
	; 				, [Finalizado]
	; 				, [Usuario]
	; 				, [Ocorrido]
	; 				, [Descricao]
	; 				, [IP]
	; 				, [Operador]	)
	; 			VALUES
	; 				( '%campo1%'
	; 				, '%campo2%'
	; 				, '%campo3%'
	; 				, '%campo4%'
	; 				, '%campo5%'
	; 				, '%campo7%'
	; 				, '%campo8%'
	; 				, '%campo9%'
	; 				, '%campo10%'	)
	; 		)
	; 		Log := sql( finaliza, 3 )

	; }
	; else if( nada = 1 )	{
	; 	campo1	:=	StrRep( nome_da_camera,, ".jpg" )
	; 	campo2	:=	datetime( 1, data_e_hora )
	; 	campo3	:=	datetime( 1, displayed )
	; 	campo4	:=	datetime( 1, A_Now )
	; 	campo5	:=	usuarioatual
	; 	campo7	:=	"Sem Motivo Aparente"
	; 	campo8	:=	""
	; 	campo9	:=	ip_cam
	; 	campo10	:=	oper
	; 	nada	=	0
	; 	finaliza=
	; 		(
	; 			INSERT INTO [MotionDetection].[dbo].[Encerrados]
	; 				( [Camera]
	; 				, [Gerado]
	; 				, [Exibido]
	; 				, [Finalizado]
	; 				, [Usuario]
	; 				, [Ocorrido]
	; 				, [Descricao]
	; 				, [IP]
	; 				, [Operador]	)
	; 			VALUES
	; 				( '%campo1%'
	; 				, '%campo2%'
	; 				, '%campo3%'
	; 				, '%campo4%'
	; 				, '%campo5%'
	; 				, '%campo7%'
	; 				, '%campo8%'
	; 				, '%campo9%'
	; 				, '%campo10%'	)
	; 		)
	; 		Log	:=	sql( finaliza, 3 )

	; }
return

^F12::
	if( _cam_list.Count() = 0 ) {

		Msgbox, , AVISO!, Lista de câmeras vazia, gostaria de reiniciar o serviço para tentar recarregar as câmeras?
		ifMsgBox Yes
			Reload
		Return

	}
	InputBox, cam_name, Buscar Identificador Local de Câmera, Digite o nome completo da câmera para verificar se existe ID local gerado para ela!
	if _cam_list.HasKey(cam_name)
		Msgbox,,ID da Câmera "%cam_name%",%	"O ID local asssociado a essa câmera é:`n`t" _cam_list[cam_name].cam_id
	Else
		Msgbox,,ID da Câmera "%cam_name%",% "ID da câmera não encontrado no servidor local ou nome errado."

Return

^END::
	GuiClose:
	ExitApp
;