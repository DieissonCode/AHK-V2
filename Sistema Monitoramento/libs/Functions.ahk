#Warn All, Off
#Requires AutoHotkey v2.0
Try if	z_functions
	Return

z_functions	:= 1
Global copyData := Map()
copyData.Default := 'EMPTY'

#Include ..\libs\Class\base64.ahk
#Include ..\libs\Class\Email.ahk

Accent_Off(text) {
	text	:= RegExReplace(text, '[áàâäã]','a')
	text	:= RegExReplace(text, '[éèêë]',	'e')
	text	:= RegExReplace(text, '[íìîï]',	'i')
	text	:= RegExReplace(text, '[óòôöõ]','o')
	text	:= RegExReplace(text, '[úùûü]',	'u')
	text	:= RegExReplace(text, '[ç]',	'c')
	return text

}

Auto_Update( software:="", auto_restart:="0" ) {
	; FileVersion	:= '0.0.0.1' ;	for debug only
	If	!software
		SplitPath(A_ScriptName,,,&ext,&software)

	s :=	(
			"SELECT	TOP(1)`n"
			"	 [name]`n"
			"	,[bin]`n"
			"	,[version]`n"
			"	--,[obs]`n"
			"FROM`n"
			"	[ASM].[dbo].[Softwares]`n"
			"WHERE`n"
			"	[name] = '" software "' AND`n"
			"	LEN([bin]) > 10 AND`n"
			"	[ahk_version] = 2`n"
			"ORDER BY`n"
			"	[PKID]`n"
			"DESC"
		)

	sql_return	:=	sql( s )

	if( sql_return.Length-1 = 0 )
		Return "Sem atualização disponível."

	if(ext = 'exe')
		Version_File := FileGetVersion(A_ScriptFullPath)
	Else
		return '0.0.0.1'
	If(	Version_File  = "1.1.33.2")
		Version_File := "0.0.0.1"

	version_sql	:= StrSplit( sql_return[2][3], "." )
	ref_bin		:= sql_return[2][2]
	Version_File:= StrSplit( SubStr( Version_File, InStr( Version_File, "." )+1 ), "." )
	if(version_sql.Length = 3)
		version_sql.InsertAt(1, "0")
	if(Version_File.Length = 3)
		Version_File.InsertAt(1, "0")

	If	!A_IsCompiled
		OutputDebug			version_sql.Length "`n`t"
				.			version_sql[1] "`n`t"
				.			version_sql[2] "`n`t"
				.			version_sql[3] "`n`t"
				.			version_sql[4] "`n"
				.		Version_File.Length "`n`t"
				.			Version_File[1] "`n`t"
				.			Version_File[2] "`n`t"
				.			Version_File[3] "`n`t"
				.			Version_File[4]
	
	Loop	4
		if( version_sql[A_Index] > Version_File[A_Index] )
			Goto autoupdate
	Return Version_File

	autoupdate:
		Base64.FileDec( &ref_bin, A_ScriptDir "\" software "_new.exe" )
		fail := 0
		Loop	{
			Sleep(500)
			If	FileExist( A_ScriptDir "\" software "_new.exe" )	;	se criou o novo executável, sai do loop para atualizar
				Break
			Else If( A_Index > 20 ) {	;	se não criou o executável após 25 segundos, retorna falha e interrompe a atualização
				fail := 1
				Email.Send(	"dsantos@cotrijal.com.br"
						,	"Falha ao atualizar o software " software
						,	"Falha ao atualizar o software " software " na máquina " SysGetIPAddresses()[1] ", usuário logado " A_UserName " em " datetime() ", para a versão " sql_return[2][3] "`n`nNão criou o arquivo novo." )
				Break
			}
		}
		if	Fail	;	se não criou executável, retorna mensagem de falha 
			Return "Falha"

		update_software	:=	'ToolTip("Atualizando ' software ' da versão ' Version_File[1] '.' Version_File[2] '.' Version_File[3] '.' Version_File[4]
						.	' para versão ' sql_return[2][3] '", 0,' A_ScreenHeight-45 ')'
						.	'`nauto_restart := ' auto_restart
						.	'`nScript:= "' software '"'
						.	'`nFileDelete("' A_ScriptFullPath '")'
						.	'`nsleep 1000'
						.	'`nFileCopy("' software '_new.exe","' A_ScriptFullPath '", 1)'
						.	'`nSleep(1000)'
						.	'`nLoop	{'
						.	'`n Sleep(500)'
						.	'`n	If FileExist( "'	A_ScriptDir '\' software '_new.exe" ){'
						.	'`n		FileDelete("'	A_ScriptDir '\' software '_new.exe")'
						.	'`n		Break'
						.	'`n	}'
						.	'`n	Else If( A_Index > 20 )'
						.	'`n		Exitapp(0)'
						.	'`n}'
						.	'`nIf	Auto_restart'
						.	'`n		Run("'	A_ScriptDir '\' software '.exe")'
						.	'`nExitapp(0)'	;	sai do script de update
		new_instance( update_software )	;	executa a atualização assíncrona
	ExitApp(0)

}

change_date(ctrl, info) {
	;	usage = .OnEvent('Change', change_date)
	DTM_GETMONTHCAL := 0x1008
	If !DllCall( 'User32.dll\SendMessage','Ptr', ctrl.hwnd, 'UInt', DTM_GETMONTHCAL, 'Ptr', 0 , 'Ptr')
		Send('{Right}')
}

checkVersion(file, sql)	{	;	sql < exe
	if		file[1] > sql[1]
		Return "1"
	Else if	file[2] > sql[2]
		Return "1"
	Else if	file[3] > sql[3]
		Return "1"
	Else if	file[4] > sql[4]
		Return "1"
	Else if	file[4] = sql[4] &&	file[3] = sql[3] &&	file[2] = sql[2] &&	file[1] = sql[1]
		Return "2"
	Else
		Return "0"

}

clipboard_to_html() {

	static CF_HTML := DllCall('RegisterClipboardFormat', 'Str', 'HTML Format')
	DllCall('OpenClipboard', 'Ptr', A_ScriptHwnd)
	format := 0
	Loop
		format := DllCall('EnumClipboardFormats', 'UInt', format)
	until (format = CF_HTML || !format )

	if(format != CF_HTML) {
		DllCall('CloseClipboard')
		return
	}

	hData	:= DllCall('GetClipboardData', 'UInt', CF_HTML, 'Ptr')
	pData	:= DllCall('GlobalLock', 'Ptr', hData, 'Ptr')
	html	:= StrGet(pData, 'UTF-8')
	DllCall('GlobalUnlock', 'Ptr', hData)
	DllCall('CloseClipboard')

	html := SubStr( html, a := InStr(html, '<html>'), InStr(html, '</html>')- a + 7 )
	if	InStr(html, 'Retrieving data')
		Return 'Cópia falhou. Tente reiniciar o módulo!'
	html	:=	StrReplace( html, '<!--StartFragment-->' )
	html	:=	StrReplace( html,'<!--EndFragment-->' )

	return	html

}

datetime( sql:=0, date:="" ) {
	sql	:= RegExReplace( sql, "[^\d]+" )
	date:= RegExReplace( date, "[^\d]+" )

	if Strlen( sql ) = 14	;	 se a data foi passada no campo de sql, ajusta as variáveis
		is_date:=sql, sql:=0, date:=is_date
	If(	sql = 2 && !StrLen( date ) )
		Return
	If( sql = 1 && !date)
		Return		SubStr( A_Now, 1, 4 ) "-"  SubStr( A_Now, 5, 2 ) "-"  SubStr( A_Now, 7, 2 )
			.	" " SubStr( A_Now, 9, 2 ) ":"  SubStr( A_Now, 11, 2) ":"  SubStr( A_Now, 13, 2 ) ".000"
	else If( sql = 1 && date)
		Return		SubStr( date, 1, 4 ) "-"  SubStr( date, 5, 2 ) "-"  SubStr( date, 7, 2 )
			.	" " SubStr( date, 9, 2 ) ":"  SubStr( date, 11, 2) ":"  SubStr( date, 13, 2 ) ".000"
	else If ( sql = 2 )
		Return		SubStr( date, 5, 4 ) "-"  SubStr( date, 3, 2 ) "-"  SubStr( date, 1, 2 )
			.	" " SubStr( date, 9, 2 ) ":"  SubStr( date, 11, 2) ":"  SubStr( date, 13, 2 )
	else If(	sql	=	3
	&&			date!=	"" )	;	valor passado junto
		Return		SubStr( date, 1, 4 ) "-"  SubStr( date, 5, 2 ) "-"  SubStr( date, 7, 2 )
			.	" " SubStr( date, 9, 2 ) ":"  SubStr( date, 11, 2) ":"  SubStr( date, 13, 2 )
	Else If(	sql	=	0
	&&			date!=  "")
		return		SubStr( date, 7, 2 ) "/"  SubStr( date, 5, 2 ) "/"  SubStr( date, 1, 4 )
			.	" " SubStr( date, 9, 2 ) ":"  SubStr( date, 11, 2) ":"  SubStr( date, 13, 2 )
	Else
		Return		SubStr( A_Now, 7, 2 ) "/"  SubStr( A_Now, 5, 2 ) "/"  SubStr( A_Now, 1, 4 )
			.	" " SubStr( A_Now, 9, 2 ) ":"  SubStr( A_Now, 11, 2) ":"  SubStr( A_Now, 13, 2 )
}

;=====================; DNSQuery
	#DllLoad "dnsapi.dll"
	#DllLoad "ntdll.dll"

	DNSQuery(Name, Type:="A", Options := 0) {
		static STATUS_SUCCESS     := 0
		static DnsFreeRecordList  := 1
		static RECORD_DATA        := (A_PtrSize * 2) + 16
		static DNS_TYPE := Map("A", 0x0001, "NS", 0x0002, "CNAME", 0x0005, "SOA", 0x0006, "PTR", 0x000c, "MX", 0x000f, "TEXT", 0x0010, "AAAA", 0x001c)

		; if !(DNS_TYPE.Has(Type))
			; throw Error()

		DNS_STATUS := DllCall("dnsapi\DnsQuery_W", "Str", Name, "Short", DNS_TYPE[Type], "UInt", Options, "Ptr", 0, "Ptr*", &DNS_RECORD := 0, "Ptr", 0)

		if (DNS_STATUS = STATUS_SUCCESS) {
			Addr := DNS_RECORD
			DNS_RECORD_LIST := Map()
			while (Addr) {
				LIST := Map()
				RECORD_TYPE  := NumGet(Addr, A_PtrSize * 2, "UShort")
				switch RECORD_TYPE {
					case DNS_TYPE["A"]:
						LIST["IpAddress"] := RtlIpv4AddressToStringW(NumGet(Addr, RECORD_DATA, "UInt"))
					case DNS_TYPE["NS"], DNS_TYPE["CNAME"], DNS_TYPE["PTR"]:
						LIST["NameHost"]			:= StrGet(NumGet(Addr, RECORD_DATA, "Ptr"))
					case DNS_TYPE["SOA"]:
						LIST["NamePrimaryServer"]	:= StrGet(NumGet(Addr, RECORD_DATA, "Ptr"))
						LIST["NameAdministrator"]	:= StrGet(NumGet(Addr + 8, RECORD_DATA, "Ptr"))
						LIST["SerialNo"]			:= NumGet(Addr + 16, RECORD_DATA, "UInt")
						LIST["Refresh"]				:= NumGet(Addr + 20, RECORD_DATA, "UInt")
						LIST["Retry"]				:= NumGet(Addr + 24, RECORD_DATA, "UInt")
						LIST["Expire"]				:= NumGet(Addr + 28, RECORD_DATA, "UInt")
						LIST["DefaultTtl"]			:= NumGet(Addr + 32, RECORD_DATA, "UInt")
					case DNS_TYPE["MX"]:
						LIST["NameExchange"]		:= StrGet(NumGet(Addr, RECORD_DATA, "Ptr"))
						LIST["Preference"]			:= NumGet(Addr + 8, RECORD_DATA, "UChar")
					case DNS_TYPE["TEXT"]:
						LIST["StringArray"]			:= StrGet(NumGet(Addr + 8, RECORD_DATA, "Ptr"))
					case DNS_TYPE["AAAA"]:
						LIST["Ip6Address"]			:= RtlIpv6AddressToStringW(NumGet(Addr, RECORD_DATA, "UInt"))
				}
				DNS_RECORD_LIST[A_Index] := LIST
				Try Addr := NumGet(Addr, "Ptr")
			}
			DllCall("dnsapi\DnsRecordListFree", "Ptr", DNS_RECORD, "Int", DnsFreeRecordList)
			return DNS_RECORD_LIST[1]['IpAddress']
		}

		Return 0
	}

	RtlIpv4AddressToStringW(IN_ADDR) {
		Size := VarSetStrCapacity(&StringAddr, 32)
		if (DllCall("ntdll\RtlIpv4AddressToStringW", "Ptr*", IN_ADDR, "Str", StringAddr))
			return StringAddr
		return False
	}

	RtlIpv6AddressToStringW(IN6_ADDR) {
		Size := VarSetStrCapacity(&StringAddr, 92)
		if (DllCall("ntdll\RtlIpv6AddressToStringW", "Ptr*", IN6_ADDR, "Str", StringAddr))
			return StringAddr
		return False
	}
;========================;

email_notificador( choosen_sound:="" ) {
	ListLines(0)
	s :=	'
		(
			SELECT TOP(1)
				p.[Mensagem],
				c.[Nome],
				p.[pkid]
			FROM
				[ASM].[dbo].[_Agenda] p
			LEFT JOIN
				[Iris].[IrisSQL].[dbo].[Clientes] c
			ON
				p.[id_cliente] = c.[IdUnico]
			ORDER BY
				3
			DESC
		)'
	email := sql( s )

	If(	!IsSet(last_id )	;	se não há novos e-mails
	||	last_id	 = email[2][3] ) {
		last_id := email[2][3]
		ListLines(1)
		return	last_id
	}
	Else if( last_id < email[2][3] ) {	;	se houver novos e-mails
		last_id		:= email[2][3]
		easter_egg	:= Random(1, 100)
		if	!choosen_sound
			Switch	easter_egg {

				Case easter_egg > 94:
					choosen_sound	:=	"yoda"

				Case easter_egg < 6:
					choosen_sound	:=	"toasty"
					toasty()

				Default:
					choosen_sound	:=	"outlook"
			}
			SoundPlay('\\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\' choosen_sound '.wav')

			TrayTip(email[2][2] "`nNOVO E-MAIL - " FormatTime(A_now, 'yyyy/MM/dd HH:mm:ss'), email[2][1])

	}
	last_id := email[2][3]
	ListLines(1)
	return	last_id

}

executar( software, software_path*) {
	if	software_path.Length && SubStr(software_path[1], -0) != "\"
		software_path := software_path[1] "\"
	Else
		software_path	:= "C:\Dguard Advanced\"

	if	pid := ProcessExist( software )
		ProcessClose( pid )
	Try	Run(software '.exe', software_path)

}

getADUser(name)	{
	objRootDSE					:= ComObjGet("LDAP://rootDSE")
	strADPath					:= "LDAP://DC=cotrijal,DC=local"
	objDomain					:= ComObjGet(strADPath)
	objConnection				:= ComObject("ADODB.Connection"), objConnection.Open("Provider=ADsDSOObject")
	objCommand					:= ComObject("ADODB.Command")
	objCommand.ActiveConnection	:= objConnection
	CommandText := "<" strADPath ">;"
				.	"(&"
				.	"(objectClass=*)"
				.	"(CN=" name "*)"
				.	")"
				.	";distinguishedName,sAMAccountName;subtree"
	objCommand.CommandText		:= CommandText
	objRecordSet				:= objCommand.Execute
	objRecordCount				:= objRecordSet.RecordCount
	z							:= 0

	Switch	objRecordCount {
	
		Case 0:
			OutputDebug "Sem retornos"
			Return ["ERRO", "Não encontrado nenhum resultado."]

		Case 1:
			obj := Map()
			z	:=	1
			objRecordSet.MoveFirst
			user	:= objRecordSet.Fields.Item("sAMAccountName").value
			zz		:= [name, user]
			obj[z]	:= zz
			Return obj

		Default:
			objRecordSet.MoveFirst
			obj := Map()
			While !objRecordSet.EOF	{
				z	:=	z+1
				nome:=	RegexMatch(objRecordSet.Fields.Item("distinguishedName").value, "CN=([^,]+)")
				user:= objRecordSet.Fields.Item("sAMAccountName").value
				zz := [nome[1], user]
				obj[z] := zz
				objRecordSet.MoveNext
			}
			Return obj

	}

}

new_instance( Script )	{
	shell	:= ComObject("WScript.Shell")
	exec	:= shell.Exec( A_AhkPath " /ErrorStdOut *")
	; MsgBox	script
	exec.StdIn.Write( script )
	exec.StdIn.Close()

}

Nr_Operador()	{
	last := SubStr(SysGetIPAddresses()[1], -3)
	Switch	last	{
		Case	100:
			Return	0

		Case	102:
			Return	1

		Case	106:
			Return	2

		Case	109:
			Return	3

		Case	114:
			Return	4

		Case	118:
			Return	5

		Case	123:
			Return	6

		Default:
			Return SysGetIPAddresses()[1] " não pertence ao range de ip's de operadores do monitoramento."

	}

}

; Debug(line, method, Class:="") {	;	REFAZER AQUI

	; line	:=	Format('{:06}', line '|	')
	; method	:=	Format('{:-20}', Format('{:20}', method ) ) '|'
	; class	:=	Format("{:.20}", Format("{:.20}", "	" Class "   Class"))
	; OutputDebug line method	class

; }

pidListFromName( name ) {
	static wmi := ComObjGet("winmgmts:\\.\root\cimv2")
	if(name == '')
		return
	PIDs := []
	for Process in wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" name "'")
		PIDs.Push( Process.processId )
	return PIDs 
}

ping( address, retries:="0" )	{
	rVal := []
	; Static	done := 0
	; done++
	colPings := ComObjGet( "winmgmts:" ).ExecQuery( "Select * From Win32_PingStatus where Address = '" address "'")._NewEnum()
	While colPings(&objStatus)	{
		; OutputDebug	objStatus.StatusCode
		rVal.Push( [ ( ( objStatus.StatusCode = "" || objStatus.StatusCode != 0 ) ? "0" : "1" ) , objStatus.Address ] )
	}

	if ( InStr( Address , A_Space ) > 0 )	{ ;	Multi Addresses or not
		MsgBox	'MULTI ENDEREÇOS AINDA NÃO VALIDADO!'
		Return rVal
	}
	Else	{
		if(	status := rVal[1][1] = 1)
			Return status
		Else	{
			if	retries
				Loop retries	{
					rVal := []
					colPings := ComObjGet( "winmgmts:" ).ExecQuery( "Select * From Win32_PingStatus where Address = '" address )._NewEnum()
					While colPings(&objStatus)
						rVal.Push( [ ( ( oS := ( objStatus.StatusCode = "" or objStatus.StatusCode != 0 ) ) ? "0" : "1" ) , objStatus.Address ] )	
					if(status := rVal[1][1] = 1)
						Return status
				}
			Return 0
		}
	}
}

runCmd( command )	{
	DetectHiddenWindows(1)
	Run( A_ComSpec,, 'Hide', &pid)
		WinWait('ahk_pid ' pid)

	DllCall( "AttachConsole" , "UInt" , pid )

	Shell	:= ComObject( "WScript.Shell" )
	Exec	:= Shell.Exec( A_ComSpec " /C " command )
	DllCall( "FreeConsole" )
	Return	Exec.StdOut.ReadAll()
}

Search_Delay( delay := '500', done := '0' )	{
	/*
		Inserir antes do Submit;
		Não precisa de 'if's', apenas a chamada ex: search_delay( '750' )
	*/
	if	!done
		Loop	{
			if ( A_TimeIdleKeyboard > delay )
				Return	done := 0
		}
	Else
		Return	done := 0

}

StrRep( haystack, needles* )	{
	/*
		texto :=	'Nome da câmera alterado dê:[n]'a'[n][t]para:[n]'b'[n]'
		MsgBox %  StrRep( texto , , '[n]:%0A', '[t]:%09' ) parametros
	*/

	separator	:=	Needles.Has(1) ? Needles[1] : ':'
	If	IsSet(function_debug)
		OutputDebug "Functions`n`tStrRep()`n`t`tSeparador = '" separator	"'"

	Loop needles.Length	{
		Switch	{
			Case InStr( (needles[A_Index] ? needles[A_Index] :  "Undefined"), separator ):
				SearchText	:= SubStr( needles[A_Index], 1, InStr( needles[A_Index], separator )-1 )	
				ReplaceText	:= SubStr( needles[A_Index], InStr( needles[A_Index], separator )+1 )
				haystack	:= StrReplace( haystack, SearchText, ReplaceText )
			Default:
				SearchText	:=	(needles[A_Index] ? needles[A_Index] :  "Undefined")
				ReplaceText	:=	''
				haystack	:= StrReplace( haystack, SearchText, ReplaceText )
		}
	}

	Return haystack

}

sql( query, update_in_query:=0 )	{
	initial_error	:=	A_LastError
	query := Trim(query, '`t')
	query := Trim(query, '`r')
	query := Trim(query, '`n')
	query := Trim(query, A_Space)
	q	:=	StrSplit( RegexReplace( query, '[\t\r\n]', A_Space ), A_Space)
	v	:=	Map('select'	, 1
			,	'update'	, 1
			,	'insert'	, 1
			,	'if'		, 1
			,	'delete'	, 1
			,	'declare'	, 1
			,	'MERGE'		, 1
			,	'WITH'		, 1
			,	'EXECUTE'	, 1
			,	'backup'	, 1 )
	If	!v.Has( Format('{:L}',q[1]))
		Return	'ERROR - Tipo de query não definida!'

	start_query	:=	query
	SQL_LE_COUNT:=	1

	redo:
		If( A_IsCompiled )
			ListLines False

	sql_le	:=	''
	;	Update sem 'WHERE' - Necessita confirmação do usuário
		if( InStr( query, 'UPDATE' ) > 0 && InStr( query, 'WHERE' ) = 0 && update_in_query != 1 )	{
			If	!A_IsCompiled
				clipboard := query

			If MsgBox(	'Você está tentando executar um UPDATE sem definir WHERE, deseja realmente continuar?`nIsso alterará TODOS os dados da tabela`n.' SubStr( query, InStr(query, 'update')-10, instr(query, 'update')+20 )
				,	'CUIDADO!'
				,	4	) = 'No'
				return
			Else
				if( !A_IsCompiled )
					clipboard := query

			}

	;

	Switch	{	;	Auto select tipo

		Case	InStr( query, '[IrisSQL].' ) && !InStr( query, '[Iris].'):
			str	:=	'
				(
					Driver={SQL Server};
					Server=srvvdm-bd\iris10db;
					Uid=ahk;
					Pwd=139565Sa
				)'
			tipo := 'mssql'

		Case	InStr( query, 'oracle.' ):
			str	:=	'
				(
					Driver={Oracle in ora_moni};
					dbq=(	DESCRIPTION=(	ADDRESS=(	PROTOCOL=TCP	)(	HOST=oraprod.cotrijal.local	)(	PORT=1521	)	)(	CONNECT_DATA=(	SERVICE_NAME=prodpdb	)	)	);
					Uid=asm;
					Pwd=cot2020asm
				)'
			tipo := 'oracle'

		Case	InStr( query, '[IrisSQL].' ) && InStr( query, '[Iris].')
				,	InStr( query, '[ASM].' )
				,	InStr( query, '[Cotrijal].' )
				,	InStr( query, '[Dguard].' )
				,	InStr( query, '[Guardinhas].' )
				,	InStr( query, '[Logs].' )
				,	InStr( query, '[MotionDetection].' )
				,	InStr( query, '[Sistema_Monitoramento].' )
				,	InStr( query, '[Telegram].' )
				,	InStr( query, '[Viaweb_Facilitador].' )
				,	InStr( query, '[vw_operador01].' )
				,	InStr( query, '[vw_programação].' )
				,	InStr( query, '[vw_operador02].' )
				,	InStr( query, '[vw_operador03].' )
				,	InStr( query, '[vw_operador04].' )
				,	InStr( query, '[vw_operador05].' )
				,	InStr( query, '[vw_operador06].' )
				,	InStr( query, '[Zabbix].' ):
			str	:=	'
				(
					Driver={SQL Server};
					Server=srvvdm-bd\ASM;
					Uid=ahk;
					Pwd=139565Sa
				)'
				tipo := 'mssql'

		Default:	;	firebird
			str	:=	'
				(
					Driver={Firebird/InterBase(r) driver};DBNAME=\\192.9.100.187\c:\Moni\Dados\MONI.FDB;Port=3050;Uid=SYSDBA;Pwd=mn1200qldd;Client=\\192.9.100.187\Moni\FireBird\fbclient.dll;Server Type=0
				)'
			tipo := 'firebird'

	}
	
	coer := '', txtout := 0, rd := '`n', cd := 'CSV'

	If	!( oCon := ComObject( 'ADODB.Connection' ) )	{	;	se não houver driver odbc

		; ComObjError('1')
		ErrorLevel	:= 'Error'
		sql_le		:= 'Fatal Error: Driver ODBC não encontrado.'
		Msgbox(sql_le)
		Return

	}

	oCon.ConnectionTimeout	:= 5
	oCon.CursorLocation		:= 3
	oCon.CommandTimeout		:= 30
	Try	oCon.Open( str )
	Catch As e
		Return

	If	!( coer := initial_error && initial_error != A_LastError )	{	;	Se não haver erro, executa a chamada

		LTRIM( query, '	' )
		sql_lq	:= query
		Try oRec	:= oCon.execute( query )	;	https://www.w3schools.com/asp/ado_ref_recordset.asp	| ANTIGO
		Catch as e
			OutputDebug	e.Message
		if	A_LastError && !A_IsCompiled
			Msgbox	'erro sql`n' clipboard := sql_lq

		}
	Else
		Return
	If	!( coer := A_LastError && initial_error != A_LastError )	{	;	se não deu erro na execução, prepara o objeto para retornar
		Retorno := []

		While IsObject( oRec )	{

			; __ := orec.Find('b.[operador]=1')
			; MsgBox
			Switch	{

				Case !oRec.State:
					Switch	{

						Case tipo = 'firebird':
							Try	
								oRec := oRec.NextRecordset()
							Catch
								oRec := 0

						Default:
							oRec := oRec.NextRecordset()

					}

				Default:
					oFld	:=	oRec.Fields
					cols	:=	oFld.Count
					Retorno.Push( oTbl := [] )
					oTbl.Push( oRow := [] )
					Loop	cols	;	preparamos o nome das colunas
						oRow.Push( oFld.Item( A_Index-1 ).Name )

					While	!oRec.EOF	{			;	Enquanto o ponteiro não chegar no final do recordset

						oTbl.Push( oRow := [] )	;	cria o objeto para os resultados da query
						Loop	cols					;	busca o resultado de cada coluna, da linha atual e insere no objeto
							oRow.Push( oFld.Item( A_Index - 1 ).Value )

						oRec.MoveNext()				;	próxima linha

					}
					; MsgBox
			}

			Switch	{

				Case tipo = 'firebird':
					Try
						oRec := oRec.NextRecordset()
					Catch
						oRec := 0

				Default:
					if IsObject(oRec)	;	2024/11/13
						oRec := oRec.NextRecordset()

			}

		}

		}
	Else	{							;	tratamento de erros

		oErr	:=	oCon.Errors
		Loop	oErr.Count	{

			oFld	:=	oErr.Item( A_Index - 1 )
			str		:=	oFld.Description
			query	.=	'`n`n'	SubStr( str, 1 + InStr( str, ']', 0, 2 + InStr( str, '][', 0, 0 ) ) )
					.	'`n		Number: '		oFld.Number
					.	'`n		NativeError: '	oFld.NativeError
					.	'`n		Source: '		oFld.Source
					.	'`n		SQLState: '		oFld.SQLState
					.	'`n		Message: '		oFld.Message

		}
		sql_le	:= query
		query	:= ''
		txtout	:= 1

	}
	oCon.Close()

	; ComObjError()
	ErrorLevel := coer
	if	sql_le	{

		SQL_LE_COUNT++
		if( SQL_LE_COUNT < 5 ) {

			if	InStr( sql_le, 'comando de texto não foi definido para o objeto de comando.' )
			&&	start_query {

				query	:=	start_query
				OutputDebug	'SQL ERROR Tentativa ' SQL_LE_COUNT '`n`t' sql_le
				Goto('redo')

			}

		}
		Else	{
			MsgBox
			; mail.new( 'dsantos@cotrijal.com.br'
					; , 'Erro de SQL - ' A_ScriptName
					; , A_IPAddress1 '`n`nErro:`n`t' sql_le '`n`nQuery:`n`t' start_query )
			if	!A_IsCompiled
				OutputDebug	'Erro de sql:`n`t' sql_le '`n'
							. 'Query`n`t' clipboard := start_query

			Return

		}

	}

	ListLines(1)

	Return	Retorno.Length = 1
			?	Retorno[1]
			:	Retorno


}

sql_version( show_tray_tip:="0", custom_name:="", show_name:="" )	{
	if	!A_IsCompiled
		Return

	script_name := !custom_name ? StrRep( A_ScriptName,, A_IsCompiled ? ".exe" : ".ahk2" ) : custom_name
	s := (
		"	SELECT TOP (1)"
		"		[version],"
		"		[date],"
		"		[pkid]"
		"	FROM"
		"		[ASM].[dbo].[Softwares]"
		"	WHERE"
  		"		[name] = '" script_name "'"
  		"	ORDER BY"
		"		3"
		"	DESC"
		)
	o := sql( s )
	file_version:= FileGetVersion(A_ScriptFullPath)
	file_version:= SubStr(file_version, InStr(file_version, ".")+1 )
	compilation	:= FileGetTime( A_ScriptFullPath )

	if	show_tray_tip {
		TrayTip(	show_name
				?	show_name
					.	"`nVersão SQL: " o[2][1]
					.	"`nVersão EXE: " file_version
					.	"`nCompilação: " datetime( ,compilation )
				:	script_name
					.	"`nVersão SQL: " o[2][1]
					.	"`nVersão EXE: " file_version
					.	"`nCompilação: " datetime( ,compilation )
				, ,'0x20' )
		Return
	}
	Else
		Return	[o[2][1], o[2][2]]

}

toasty() {
	x := A_ScreenWidth
	WinGetPos(,,,&taskbar, 'ahk_class Shell_TrayWnd')
	Toasty 			:= Gui('+LastFound +AlwaysOnTop +ToolWindow -Caption')
	Toasty.BackColor:= 'EEAA99'
	Toasty.Add('Picture', 'BackgroundTrans vPic', '\\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\toasty.png')	
	ControlGetPos(,,&w,&h,toasty['pic'])
	WinSetTransColor('EEAA99')
	Toasty.Show("x" A_ScreenWidth " y" (A_ScreenHeight - taskbar ) - h)
	SoundPlay('\\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\toasty.wav')
	Loop	5	{
		x -= 52
		WinMove(x, (A_ScreenHeight-taskbar )-h)
	}
	Toasty.Destroy()

}

readCommand(wParam, lParam, message, hwnd)	{
	/* https://www.autohotkey.com/docs/v2/lib/OnMessage.htm */
	;	OnMessage 0x004A, readCommand	;	Inserir no script principal para rodar
	StringAddress := NumGet(lParam, 2*A_PtrSize, "Ptr")
	Global	show_tooltip
		,	show_tray
		OutputDebug	StrGet(StringAddress)
	Try If copyData.Has( StrGet(StringAddress) )	{
		OutputDebug	copyData[StrGet(StringAddress)]
		new_instance(copyData[StrGet(StringAddress)] )

	}
	switch	StrGet(StringAddress), 0 {
		case 'ShowTooltip':
			show_tooltip := 1
		case 'ShowTray':
			show_tray := 1

		default:
			show_tooltip:= 0
			show_tray	:= 0
	}
	return true
}

sendCommand(StringToSend, TargetScriptTitle)	{
	CopyDataStruct			:= Buffer(3*A_PtrSize)
	SizeInBytes				:= (StrLen(StringToSend) + 1) * 2
	NumPut(	"Ptr", SizeInBytes, "Ptr", StrPtr(StringToSend), CopyDataStruct, A_PtrSize )
	Prev_DetectHiddenWindows:= A_DetectHiddenWindows
	Prev_TitleMatchMode		:= A_TitleMatchMode
	DetectHiddenWindows		True
	SetTitleMatchMode		2
	TimeOutTime				:= 4000	;	default é 5
	RetValue				:= SendMessage(0x004A, 0, CopyDataStruct,, TargetScriptTitle,,,, TimeOutTime)
	DetectHiddenWindows Prev_DetectHiddenWindows
	SetTitleMatchMode Prev_TitleMatchMode
	return RetValue
}

watchdog()	{
	if	!A_IsCompiled
		Return
	settings_dir := 'C:\Users\' A_UserName '\AppData\Roaming\KahSystems'
	If	!FileExist(settings_dir)
		DirCreate('C:\Users\' A_UserName '\AppData\Roaming\KahSystems')
	if	FileExist(ini := settings_dir '\watchdog.ini')	{
		txt := IniRead(ini, 'Keep Running')
		For each, line in StrSplit(txt, '`n') {
			part	:= StrSplit(line, '=')
			software:= part[1]
			path	:= part[2]
			if	!ProcessExist(software) && !InStr(software, "watchdog") && FileExist(path)
				run(path)
		}
		ExitApp(0)
	}

}

watchdog_register()	{
	if	!A_IsCompiled
		Return
	settings_dir := 'C:\Users\' A_UserName '\AppData\Roaming\KahSystems'
	If	!FileExist(settings_dir)
		DirCreate('C:\Users\' A_UserName '\AppData\Roaming\KahSystems')
	ini := settings_dir '\watchdog.ini'
	IniWrite(A_ScriptFullPath, ini, 'Keep Running' ,A_ScriptName )

}

;	PropDef
	;	Map
		Map.Prototype.DefineProp('Filter', {Call: Search})
		Search( map, filter, map_back )	{	;	para presets
			if !filter
				Return
			many := 1
			Loop map.Count
				if	InStr(map[A_Index].name, filter)
					map_back[many++] := {guid : map[A_Index].guid, server : map[A_Index].server, name : map[A_Index].name}

			return map_back

		}

	;	Array
		Array.Prototype.DefineProp('Sort', {Call: Order})
		Order( string, obj, opt:='' )	{
			ret := []
			Loop obj.Length
				tempList .= obj[A_Index] (A_Index = obj.Length ? '' : '`n')
			tempList :=  StrSplit(Sort(tempList, opt), '`n')
			Loop tempList.Length
				ret.Push(tempList[A_Index])
			Return	ret
		}

