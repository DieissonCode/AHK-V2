#Requires AutoHotkey v2.0

#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Functions.ahk
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Http.ahk
call := Http()
auth := 'http://admin:tq8hSKWzy5A@'
get := '/cgi-bin/configManager.cgi?action=getConfig&name=StorageGroup'
set := '/cgi-bin/configManager.cgi?action=setConfig&StorageGroup'
select := '
(
	SELECT	[ip]
	FROM	[Dguard].[dbo].[cameras]
	WHERE	[vendormodel]	LIKE '%DAHUA%'
	OR		[vendormodel]	LIKE '%INTELBRAS%'
	ORDER BY 1
)'

cam := sql(select)

storage0 := Map()
storage1 := Map()
storage2 := Map()
storage3 := Map()

Loop cam.Length-1	{
	look4path := 0
	data := StrSplit( __ := call.request(auth (ip := cam[A_Index+1][1]) get), "`n")

	Loop data.Length	{
		st_nm := SubStr(data[A_Index], InStr(data[A_Index], "]" )-1, 1)
		OutputDebug	ip "`t" st_nm
		switch {
			case InStr(data[A_Index], 'PicturePathRule' ):
				storage%st_nm%[ip '_path'] := SubStr(data[A_Index], InStr(data[A_Index], "=")+1)

			case InStr(data[A_Index], 'Name' ):
				storage%st_nm%[ip '_type'] := SubStr(data[A_Index], InStr(data[A_Index], "=")+1)

		}
		; if InStr(data[A_Index], 'FTP' )	{
			; look4path := 1
		; }
		; if InStr(data[A_Index], 'PicturePathRule' )	&& look4path {
			; RegExMatch(data[A_Index], "(?<=PicturePathRule=)(.*)",&found )
			; if found[1] = 'none'	{
				; MsgBox	call.request( auth ip set '[' RegExReplace(data[st_nm], "\D") '].PicturePathRule=' ip '_%y%M%d-%h%m%s.jpg' )
			; }
			; OutputDebug( ip "`n`t" found[1] )
			; look4path := 0
		; }
	}

}
MsgBox