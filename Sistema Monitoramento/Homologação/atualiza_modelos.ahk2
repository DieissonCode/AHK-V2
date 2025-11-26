;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.0.2.1
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Atualização de Informações das Câmeras
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\model.ico
#Requires AutoHotkey v2.0
;	Includes
	#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Functions.ahk
	#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Http.ahk
	sql_version(1)
s := '
	(
		SELECT	[ip], [vendorModel]
		FROM	[dguard].[dbo].[cameras]
		WHERE	[vendormodel] LIKE 'Dahu%'
		OR		[vendormodel] LIKE 'Intel%'
		OR		[vendormodel] LIKE 'Sams%'
		OR		[vendormodel] LIKE 'Fosc%'
		ORDER BY
			[cam_model] DESC
	)'
	s := sql( s )

Loop s.Length-1	{
	if	!ping( ip := s[A_index+1][1] )
		continue

	modelo := ""
	switch {
		case InStr( s[A_index+1][2], "Dahua" ), InStr( s[A_index+1][2], "Intel" ):
			r := StrSplit( http.request( "http://admin:tq8hSKWzy5A@" ip "/cgi-bin/magicBox.cgi?action=getSystemInfo" ), "`n" )
			modelo := 'dahua'

		case InStr( s[A_index+1][2], "Samsung"):
			r := StrSplit( http.request( "http://admin:tq8hSKWzy5A@" ip "/cgi-bin/about.cgi?msubmenu=about&action=view2" ), "`n" )
			modelo := 'samsung'

		case InStr( s[A_index+1][2], "foscam" ):
			r := StrSplit( http.request( "http://" ip ":88/cgi-bin/CGIProxy.fcgi?cmd=getDevInfo&usr=admin&pwd=tq8hSKWzy5A" ), "`n" )
			modelo := 'foscam'

		default:
			MsgBox "modelo desconhecido"	
	}

	serial := cam_model := ""

	Loop r.Length {
		switch modelo {
			case 'dahua':
				if	InStr( r[A_Index], "deviceType=" ) {
					RegExMatch( r[A_Index],"(?<=deviceType=)(.*)", &cam_model )
					cam_model := cam_model[1] 
				}
				if	InStr( r[A_Index], "serialNumber=" ) {
					RegExMatch( r[A_Index],"(?<=serialNumber=)(.*)", &serial )
					serial := serial[1] 

				}
			case 'samsung':
				if	InStr( r[A_Index], "model:" ) {
					RegExMatch( r[A_Index],"(?<=model:)(.*)", &cam_model )
					cam_model := cam_model[1] 
				}
				if	InStr( r[A_Index], "serial:" ) {
					RegExMatch( r[A_Index],"(?<=serial:)(.*)", &serial )
					serial := serial[1] 

				}
				; if	InStr( r[A_Index], "version:" ) {
					; RegExMatch( r[A_Index],"(?<=version:)(.*)", &firmware )
					; firmware := firmware[1] 

				; }

			case 'foscam':
				if	InStr( r[A_Index], "<productName>" ) {
					RegExMatch( r[A_Index],"(?<=<productName>)(.*)(?=</productName>)", &cam_model )
					cam_model := cam_model[1] 
				}
				if	InStr( r[A_Index], "<mac>" ) {
					RegExMatch( r[A_Index],"(?<=<mac>)(.*)(?=</mac>)", &serial )
					serial := serial[1] 

				}

		}

		if	cam_model && ip && serial {
			OutputDebug(ip "`t" cam_model "`t" serial )
			u := 
			(
				"UPDATE [Dguard].[dbo].[cameras_configuration]`n"
				"SET`n"
				"	[model]	= '" cam_model "',`n"
				"	[serial]	= '" serial "',`n"
				"	[update_date]	= GetDate()`n"
				"WHERE	[ip]	= '" ip "'"
			)
			sql( u )
			break

		}
	}


}

ExitApp(0)
