#Requires AutoHotkey v2.0

;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.0.2.0
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Agendamentos
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\ico\agenda.ico

#Include ..\Sistema Monitoramento\libs\Functions.ahk2

;	Configurações
	#SingleInstance Force
	; If	A_IsCompiled	{
		; auto_update(, 1)
		; #NoTrayIcon
	; }
	Switch SubStr( SysGetIPAddresses()[1], -2 ) {
		Case 102:
			maquina	:=	1

		Case 106:
			maquina	:=	2

		Case 109:
			maquina	:=	3

		Case 114:
			maquina	:=	4

		Case 118:
			maquina	:=	5

		Case 123:
			maquina	:=	6

		Default:
			; Return
			maquina :=	1

	}

	SetTimer(agendados, -1000)
	return

agendados()	{

	reload_time := RegExReplace( A_Now, '(....)(..)(..)(..)(..)(..)', '$4$5' )	;	hora e minuto
	if( reload_time = 1900 || reload_time = 0700 )
		Reload
	OutputDebug	A_Now
	tabela_antiga := ;	eventos agendados de hoje
		(
			"SELECT`n"
			"	[id_aviso],`n"
			"	[data_alerta],`n"
			"	[quem_avisar],`n"
			"	[pkid]`n"
			"FROM`n"
			"	[ASM].[dbo].[_agenda_alertas]`n"
			"WHERE`n"
			"	[visualizado] IS NULL`n"
			"AND`n"
			"	(	DATEPART( yy, [data_alerta] ) = " A_Year "	AND`n"
			"		DATEPART( mm, [data_alerta] ) = " A_MM "	AND`n"
			"		DATEPART( dd, [data_alerta] ) = " A_DD "	)`n"
			"AND`n"
			"	[quem_avisar] = '" maquina "'`n"
			"	ORDER BY`n"
			"		[data_alerta]`n"
			"	DESC`n"
		)

		agenda	:=	sql( tabela_antiga )

	Loop	agenda.Length-1	{

		id_aviso:=	agenda[A_Index+1][1]
		operador:=	agenda[A_Index+1][3]
		pkid	:=	agenda[A_Index+1][4]
		data	:=	RegExReplace( RegExReplace( agenda[A_Index+1][2]	;	yyyymmddhhmm
				,	'\D' )
				,	'(..)(..)(....)(..)(..)(..)', '$3$2$1$4$5' )
		ano		:=	SubStr( data, 1,	4 )
		mes		:=	SubStr( data, 5,	2 )
		dia		:=	SubStr( data, 7,	2 )
		hora	:=	SubStr( data, 9,	2 )
		mn		:=	SubStr( data, 11,	2 )
		inicio	:=	A_Hour A_Min
		fim		:=	Format('{:02}',(A_Min >= 50 ? A_Hour+1 : A_Hour)) Format('{:02}',(A_Min >= 50 ? A_Min-50 : A_Min+10))
		OutputDebug	inicio '`t' hora mn '`t' fim
		if(	hora mn >= inicio && hora mn <= fim )	{

			if(	operador && operador != maquina )
					return
			op	:=	(
					"SELECT"
					"`n	agenda.[operador],		--	1"
					"`n	agenda.[mensagem],		--	2"
					"`n	agenda.[inserido],		--	3"
					"`n	alerta.[data_alerta],	--	4"
					"`n	b.[Nome],				--	5"
					"`n	agenda.[pkid],			--	6"
					"`n	agenda.[id_unidade],	--	7"
					"`n	agenda.[mensagem_html],	--	8"
					"`n	alerta.[pkid]			--	9"
					"`nFROM"
					"`n	[ASM].[dbo].[_Agenda] agenda"
					"`nLEFT JOIN"
					"`n	[iris].[IrisSQL].[dbo].[Clientes] b ON agenda.[Id_Cliente]=b.[IdUnico]"
					"`nLEFT JOIN"
					"`n	[ASM].[dbo].[_agenda_alertas] alerta ON agenda.[pkid] = alerta.[id_aviso]"
					"`nWHERE"
					"`n	agenda.[pkid] = '%id_aviso%'"
					"`nAND(	DATEPART(yy, alerta.[data_alerta])	= " ano
					"`nAND	DATEPART(mm, alerta.[data_alerta])	= " mes
					"`nAND	DATEPART(dd, alerta.[data_alerta])	= " dia
					"`nAND	DATEPART(hh, alerta.[data_alerta])	= " hora
					"`nAND	DATEPART(mi, alerta.[data_alerta])	= " mn " )"
				)

			op		:= sql( op )
			
			Global	_texto	:= op[2,2]
				,	qnd		:= op[2,3]
				,	qnda	:= op[2,4]
				,	cliente	:= op[2,5]
				,	id_aviso:= op[2,6]
				,	event	:= op[2,7]
				,	html	:= op[2,8]
				,	pkid	:= op[2,9]
				,	A:=Gui('+AlwaysOnTop')
			easteregg := Random(1, 100)	;	easteregg
				Switch 	{

					Case easteregg >	99:
						som	:=	"fart"

					Case easteregg <= 3:
						som	:=	"yoda"

					Default:
						som	:=	"car"

				}

			SoundPlay("\\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\" som ".wav")
			
			A.Add('GroupBox',		'x10		y50		w855 	h65	Center'	A.Font( "s10", "bold", "cWhite" )	, cliente)
			A.Add('Text',			'x20		yp+20'				 		A.Font( "cWhite" )					, 'Adicionado em:')
			A.Add('Text',			'xp+' 520 '	yp'																 , 'Lembrar Evento em:')
			A.Add('Text',			'x20		yp+20'															 , qnd)
			A.Add('Text',			'xp+520		yp'																 , qnda)
			_html:=	A.Add('Activex','x12		y125	w853	h500'											 , 'HTMLFile')
			A.Add('Button',			'x10		y10		w855	h30	vas'	A.Font()	" gfinaliza_agendamento" , 'Confirmar visualização')
			 
			_html.Close()
			_html.Write(	html
						?	html
						:	StrRep( _texto,, '`n:<br>' ) )
			A.Cores()
			visto := datetime(1)
			A.Show(,,'Evento Agendado')
			WinWaitClose('Evento Agendado')

		}
		else
			Continue

	}
	OutputDebug	'waiting 30 seconds...'
	SetTimer(agendados, -30000)

}

GuiClose:
	finaliza_agendamento:
	usuario	:= SysGetIPAddresses()[1]

	define_visualizado :=
		(
			"UPDATE"
			"`n	[ASM].[dbo].[_agenda_alertas]"
			"`nSET"
			"`n	[visualizado]		= '1',"
			"`n	[data_visualizado]	= GetDate(),"
			"`n	[visto_por]			= '" usuario "'"
			"`nWHERE"
			"`n	[id_aviso] = '" id_aviso "'"
			"`nAND	[pkid] = '" pkid "'"
		)
		sql( define_visualizado )

	limpa_passados :=
		(
			"UPDATE"
			"`n	[ASM].[dbo].[_agenda_alertas]"
			"`nSET"
			"`n	[visualizado] = '1'"
			"`n	,[data_visualizado] = GetDate()"
			"`nWHERE"
			"`n	[data_alerta] < GetDate()"
			"`n	AND [visualizado] IS NULL"
		)
		sql( limpa_passados )

	zabbix_read_date :=
		(
			"UPDATE	[zabbix].[dbo].[device_event]"
			"`nSET		[read_date]	= GetDate()"
			"`nWHERE	[event]		= '" event "'"
		)
	If( StrLen(event) > 4 )
		sql( zabbix_read_date)
	A.Destroy()
	agendados()
Return