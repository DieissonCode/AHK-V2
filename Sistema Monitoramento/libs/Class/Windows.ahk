#Requires AutoHotkey v2.0
if	IsSet(z_inc_windows)
	Return
Global	z_inc_windows := 1

Class	Windows	{
	
	; Static ActiveObj( Object, CLSID, Flags:=0 ) {
	; 	;	https://www.autohotkey.com/boards/viewtopic.php?f=6&t=6148
	; 	static cookieJar := {}
	; 	if( !CLSID ) {
	; 		if( cookie := cookieJar.Remove( Object ) ) != ""
	; 			DllCall( "oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0 )
	; 		return
	; 	}
	; 	; if cookieJar[ Object ]
	; 	; 	throw Exception( "Object is already registered", -1 )
	; 	VarSetCapacity( _clsid, 16, 0 )
	; 	if( hr := DllCall( "ole32\CLSIDFromString", "wstr", CLSID, "ptr", &_clsid ) ) < 0
	; 		throw Exception( "Invalid CLSID", -1, CLSID )
	; 	hr := DllCall( "oleaut32\RegisterActiveObject"
	; 		, "ptr", &Object, "ptr", &_clsid, "uint", Flags, "uint*", cookie
	; 		, "uint" )
	; 	if( hr < 0 )
	; 		throw Exception( format( "Error 0x{:x}", hr ), -1 )
	; 	cookieJar[ Object ] := cookie
	; }

	; Static clsid( name ) {

	; 	hex		:= this.str2hex( Format( "{:L}", name ) )
	; 	chars	:= []
	; 	len		:= strlen(hex) > 32 ? 32 : strlen(hex)

	; 	Loop,	32
	; 		c	.= "A"

	; 	hex		:= SubStr( c, 1, 32-len ) hex

	; 	Loop,	32
	; 		if	Mod( A_Index, 2 ) {

	; 			; OutputDebug, % SubStr( hex, A_Index,2 )
	; 			chars.Push( SubStr( hex, A_Index,2 ) )

	; 		}

	; 	Loop,	16 {

	; 			if( A_Index = 5
	; 			||	A_Index = 7
	; 			||	A_Index = 9
	; 			||	A_Index = 11) {
	; 				clsid .= "-" chars[A_Index]
	; 				; OutputDebug, % clsid

	; 			}
	; 			Else {

	; 				clsid .= chars[A_Index]
	; 				; OutputDebug, % clsid

	; 			}

	; 	}

	; 	Return "{" clsid "}"

	; }

	; Static fileVersion( filepath ) {	;	https://www.autohotkey.com/boards/viewtopic.php?t=77#p396
	; 	filepath := StrReplace( filepath, "\", "\\" )
	; 	For objFile in ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\"	A_ComputerName	"\root\cimv2") .ExecQuery( "SELECT Version FROM CIM_Datafile WHERE Name = '" filepath "'" )
	; 		Return	objFile.Version
	; }

	static LoginAd(usuario, senha) {
		usuario := (Type(usuario) = "Gui.Edit") ? usuario.Value : usuario
		senha := (Type(senha) = "Gui.Edit") ? senha.Value : senha
		
		nSize := 0  ; Initialize the variable
		if DllCall("advapi32\LogonUser", "Str", usuario, "Str", "Cotrijal", "Str", senha, "Ptr", 3, "Ptr", 3, "UIntP", &nSize)
			return 1
		else
			return 0
	}

	; Static ProcessExist( processName )	{
	; 	Process, Exist,% processName
	; 	return Errorlevel
	; }

	; Static ProcessStartTime( process* ) {
	; 	/*
	; 		retorno := windows.ProcessStartTime( "dguard", "ddguard player" )
	; 		Msgbox	%	retorno[1] "`n" retorno[2]
	; 	*/
	; 	times	:=	[]
	; 	if( process.Count() > 1 ) {
	; 		for i, v in process
	; 			processos .= InStr( v, " " )	> 0
	; 											? "'" v "'" ", "
	; 											: v ", "
	; 		processos := SubStr( processos, 1, -2)
	; 	}
	; 	Else
	; 		processos := InStr( process[1], " " )	> 0
	; 												? "'" process[1] "'"
	; 												: process[1]
	; 	started	:= RegexReplace( RunPS( "powershell Get-Process -Name " processos " |Format-List StartTime" ), "\D")
	; 	Loop,%	Round( StrLen( started )/14 ) {
	; 		base	:= A_Index = 1 ? 1 : (A_Index-1) * 14 + 1
	; 		time	:=	SubStr( started, base+4, 4 )
	; 				.	SubStr( started, base+2, 2 )
	; 				.	SubStr( started, base, 2 )
	; 				.	SubStr( started, base+8, 6 )
	; 		times.Push( time )
	; 	}
	; 	Return times
	; }

	; Static Run( software )	{
	; 	path = C:\Dguard Advanced\
	; 	copy = \\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\
	; 	try
	; 		Run,%   path software ".exe"
	; 		catch	{
	; 			FileCopy,%  copy software ".exe"
	; 				,%  path software ".exe",   1
	; 			Sleep,	500
	; 			if ( errorlevel = 0 )
	; 				try
	; 					Run,%   path software ".exe"
	; 		}
	; }

	Static Speak( text, volume:="100", speed:="1" )	{
		speak := ComObject("SAPI.SpVoice")
		speak.Volume := volume
		speak.Rate := speed
		speak.Speak('<pitch absmiddle="-10"/>', 0x28) ; SVSFPersistXML := 0x20 ;SVSFIsXML := 0x8 ;SVSFlagsAsync := 0x1
		speak.Speak( 'Atenção' )
		speak.Pause
		Sleep(250)
		speak.Resume
		speak.Speak( text )

	}

	; Static Status( where )	{
	; 	; OutputDebug % where
	; 	if !where
	; 		Return
	; 	obj := ComObjGet( "winmgmts:{impersonationLevel=impersonate}!\\" . A_ComputerName . "\root\cimv2" )
	; 	query_results := obj.ExecQuery( "SELECT Lockout, Status FROM Win32_UserAccount WHERE Name = '" where "'" )._NewEnum
	; 	While query_results[ property ]
	; 		Return property[ "Lockout" ] = "-1" ? "Usuário bloqueado ou senha expirada" : "Usuário ou senha inválidos.`nVerifique sua senha, se a tecla CAPSLOCK não está ativada.`nE se atecla NUMLOCK está ativada!"
	; }

	; Static str2hex(string)	{

	; 	VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1

	; 	if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x4, "ptr", 0, "uint*", size))
	; 		throw Exception("CryptBinaryToString Fail", -1)

	; 	VarSetCapacity(buf, size << 1, 0)

	; 	if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x4, "ptr", &buf, "uint*", size))
	; 		throw Exception("CryptBinaryToString Fail", -1)

	; 	return StrReplace(StrReplace( StrReplace( StrGet(&buf), " " ), "`n" ), "`r" )

	; }

	; Static Users( where )	{
	; 	if !where
	; 		Return
	; 	obj := ComObjGet( "winmgmts:{impersonationLevel=impersonate}!\\" . A_ComputerName . "\root\cimv2" )
	; 	query_results := obj.ExecQuery( "SELECT FullName FROM Win32_UserAccount WHERE Name = '" where "'" )._NewEnum
	; 	While query_results[ property ]
	; 		Return property[ "FullName" ]
	; }

	; Static writeEvent( content, remote_pc_name="", type="" )	{
	; 	;	https://www.autohotkey.com/boards/viewtopic.php?f=6&t=77&start=20
	; 	;	https://docs.microsoft.com/en-us/previous-versions/tn-archive/ee156617(v=technet.10)?redirectedfrom=MSDN
	; 	If	!content
	; 		Return "Evento em branco, não gerado evento!"
	; 	If	!type
	; 	||	type not in ( 0, 1, 2, 4, 8, 16 )
	; 		type	 =	8
	; 		/*	Event types
	; 			Value			Event Type
	; 			0				SUCCESS
	; 			1				ERROR
	; 			2				WARNING
	; 			4				INFORMATION
	; 			8				AUDIT_SUCCESS
	; 			16				AUDIT_FAILURE
	; 		*/
	; 	objShell	:=	ComObjCreate( "WScript.Shell" )

	; 	If	remote_pc_name
	; 		Try
	; 			objShell.LogEvent( type, content, remote_pc_name )
	; 	Else
	; 		Try
	; 			objShell.LogEvent( type, content )

	; }
}