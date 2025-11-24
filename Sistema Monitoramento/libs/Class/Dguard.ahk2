If	IsSet(z_inc_Dguard)
	Return

Global	z_inc_Dguard := 1,
		server_token :=	Map()

Dguard.cameras('localhost')

#Include ..\class\Json.ahk2
#Include ..\class\Email.ahk2
#Include ..\functions.ahk2

Class	Dguard	{

	static request(o) {
		static	req := ComObject('WinHttp.WinHttpRequest.5.1')
		o['async'] := o.Has('async') ? o['async'] : false
		req.open( o['method'] ? o['method'] : o['method'] := 'GET', o['url'], o['async'])
		if( o['method'] != 'GET' )
			req.SetRequestHeader('Content-Type', 'application/json')
		if o.Has('token')
			req.SetRequestHeader( 'Authorization', 'bearer ' o['token'] )

		Switch	{
			Case o.Has('data'):
				try
					req.Send(o['data'])
				Catch	as e {
					OutputDebug	e.message "`n`n" e.line "`n`n" o['data'] "`n`n" o['url']
					Return
				}

			Default:
				Try req.Send()
				Catch as e {
					Return
				}
				Loop	{
					if(req.statusText = 'Ok') || A_Index > 20
						Break
				Sleep 100
			}

		}

		If	o.Has('stream')
			return	[req.responseText, req.ResponseStream]
		Else
			return	req.responseText

	}

	static getToken(o?) {
		Global server_token
		if !IsSet(o)
			o := Map()
		if( !o.Has('server') || o['server'] = 'localhost')
			o['server'] := SysGetIPAddresses()[1]

		if	server_token.Has(o['server'])
			Return	server_token[o['server']] := 1

		switch o['server'] {	;	if is dns
			case 'vdm01':
				ip:=	'192.9.100.181'
			case 'vdm02':
				ip:=	'192.9.100.182'
			case 'vdm03':
				ip:=	'192.9.100.183'
			case 'vdm04':
				ip:=	'192.9.100.184'
			case 'vdm05':
				ip:=	'192.9.100.185'
			case 'vdm06':
				ip:=	'192.9.100.186'
			Default:
				ip:=	o['server']
		}

		o['user']	:=	!o.Has('user') ? 'admin' : o['user']
		ip		:=	StrSplit(ip , '.')
		o['pass']	:=	o['user'] = 'conceitto' ? 'cjal2021'
					:	ip[4] >= 101 && ip[4] <= 124 && !o.Has('pass') ? '@dm1n' : ip[4] = 100 && !o.Has('pass') ? '@Dm1n'
					:	'admin'
		o['url']		:=	'http://' o['server'] ':8081/api/login'
		o['data']	:=	'{ "username" : "' o['user'] '", "password" : "' o['pass'] '" }'
		if(ProcessExist('Dguard.exe') = 0)
			return 'ERRO - Dguard não está em execução na máquina ' o['server']
		RegExMatch(	__ := this.request(Map( 'url', o['url'], 'data', o['data'], 'method', 'POST'))
			,	'(?<="userToken":")(.*)(?=","serverDate)'
			,	&localToken)
		if(isObject(localToken)){
			Global	token		:= localToken[1]
			server_token[o['server']]:= localToken[1]
			Return localToken[1]
		}
		Else
			Return
	}

	static camera( server, camGuid, tokenDguard ) {	;	informação da câmera
		/*	var['server']['propriedade']
			INDEX = INT
			Propriedade:
				name: AGS [ BAL ] Portão,
				guid: {1DEB2C30-D51C-4ACE-B8C5-EE71D95C84D4},
				parentGuid: null,
				hasChildren: false,
				active: true,
				connected: true,
				vendorGuid: {CA014F07-32AE-46B9-83A2-8A9B836E8120},
				modelGuid: {5BA4689B-6DD0-2C27-C0F8-C6B514DC5533},
				address: 10.2.57.220,
				port: 80,
				username: admin,
				connectionType: 0,
				timeoutEnabled: true,
				timeout: 60,
				bandwidthOptimization: true,
				camerasEnabled: 16,
				vendorModelName: Dahua Technology Co., LTD DH-IPC-HDBW2320RN-ZS,
				firmwareModel: 2.600.0005.0.R,build:2016-12-19,
				firmwareDevice: ,
				type: 0,
				contactIdCode: 0572,
				recording: true,
				offlineSince: -,
				groupGuid: null,
				notes: 56,
				advancedSettings: ,
				url: http://10.2.57.220:80,
				hasCamerasOutOfSpecifications: false,
				hasCamerasWithSignalLost: false
		*/
		Return	JSON.parse(this.request( { url : "http://" server ":8081/api/servers/" camGuid , token : tokenDguard} ))

	}

	static cameras( server, tokenDguard? ) {	;	lista de câmeras
		/*	var['servers'][INDEX][Propriedade]
			INDEX = INT
			Propriedade:
				name
				guid
				active
				connected
		*/
		Return	JSON.parse( this.request(Map( 'url' , "http://" server ":8081/api/servers" , 'token' , this.getToken(Map('server', server)) )) )

	}
/*
	static camerasImage( server, tokenDguard, guid ) {
		__:=this.request( 'http://' server ':8081/api/servers/%7B' (RegExReplace(guid, '[{}]')) '%7D/cameras/0/image.jpg' , tokenDguard, "" )
		MsgBox
		Return	__
	}

	static cameraPTZ(server, guid, token, temp) {
		guid:= RegExReplace(guid, "[{}]")
		__	:= JSON.parse(_ := this.request( "http://" server ":8081/api/servers/%7B" guid "%7D", token, "" ))
		Switch	{
		
			Case InStr(_,"NOT FOUND"):
				Return "Câmera não existe nesse servidor"

			Case InStr(__['server']['vendorModelName'], 'SD'):
				Return 1

			Default:
				;@Ahk2Exe-IgnoreBegin
				OutputDebug	__['server']['vendorModelName']
				;@Ahk2Exe-IgnoreEnd
				return '0'
				; if	!InStr(_, 'error')
						; Return	json.parse(_)['ptz']
				; Else
					; Return	
		
		}

	}

	static cameraPreset(server, guid, id, tokenDguard, go?) {
		OutputDebug	IsSet(go)
		guid:=	RegExReplace(guid, "[{}]")
		url	:=	'http://' server ':8081/api/servers/%7B' guid '%7D/cameras/0/ptz/presets/' id ( !IsSet(go) ? '/define' : '/goto')
		data:=	'{}'
		__	:= Map()
		_:= this.request( url, tokenDguard, data, "PUT" )
		if InStr(_, 'Error')
			Return
		__ := JSON.parse(_)

		Switch	{

			Case InStr(_,"NOT FOUND"):
				Return

			Default:
				Return	__['preset']['name']

		}

	}

	static cameraResolution(server, tokenDguard, guid)	{
		url	:= 'http://' server ':8081/api/servers/%7B' RegExReplace(guid, '[{}]') '%7D/cameras/0/streams/0/statistics'
		RegExMatch(	__ := this.request(url, tokenDguard,'', 'GET'),	'(?<="resolution":")(.*)(?="}})', &var)
		OutputDebug	__
		Return	var ? var[1] : ''

	}

	;static  contact_id( server, tokenDguard, guid, put* )	{

	; 	Switch	put.Count()	{
		
	; 		Case 0:
	; 			return	json( this.request( "http://" server ":8081/api/servers/`%7B" StrRep( guid ,, "{", "}" ) "`%7D/contact-id" , tokenDguard, "" ) )

	; 		Default:
	; 			_data :=  "{ "
	; 			Loop,% put.Count()
	; 				_data .=  put[A_Index] ","

	; 			data	:= SubStr(_data, 1, -1) " }"
	; 			return	this.request(	"http://" server ":8081/api/servers/`%7B" StrRep( guid ,, "{", "}" ) "`%7D/contact-id"
	; 								,	tokenDguard
	; 								,	data
	; 								,	"PUT" )

	; 	}

	; }

	; has_preset(ip, guid, token)	{
	; 	If !guid
	; 		Return "false"
	; 	url	:=	"http://" ip ":8081/api/servers/%7B" RegexReplace(guid,"[{}]") "%7D/cameras/0/ptz"
	; 	Return json( this.request( url,token , "", "GET" ) )["ptz"].haspresets
	
	; }

	static _layouts( server, tokenDguard, name, method:="GET" ) {

		Switch	{
				Case name && method="GET", name && method="POST":
				method	:=	"POST"
				data	:= '{ "name":"' name '"}'

			Case name && method="DELETE":
				delete	:=	1
				method	:=	"GET"

		}

		if	!server
			server	:= "localhost"

		If	!tokenDguard {
			tokenDguard := this.getToken(server)
			if	!tokenDguard {

				Msgbox("ERRO AO REQUISITAR O TOKEN PARA O SERVIDOR " server "`n`tClass Dguard.layout " A_LineNumber)
				Return

			}

		}

		URL	:=	"http://" server ":8081/api/layouts"
		__	:=	Json.Parse( this.request( url, tokenDguard, data, method ) )
		MsgBox
		_layouts	:= {}
		If( method = "GET" ) {	;	Pega layouts
			Loop	__.layouts.Length	{

				If(	InStr( __.layouts[A_Index].name, "__" ) )
					Continue

				z_oeto	:=	 __.layouts[A_Index].name
				z			:=	{ guid	:	__.layouts[A_Index].guid
								, count	:	__.layouts[A_Index].camerascount }
				_layouts[z_oeto]	:=	z
				z_oeto := ''

			}

			Return	_layouts

		}
		; If	delete {				;	Exclui layout

		; 	Loop,%	__.layouts.count()
		; 		If	InStr( __.layouts[A_Index].name, name ) {

		; 			url		:= url "/" __.layouts[A_Index].guid
		; 			method	:= "DELETE"
		; 			; instanced :='
		; 			; 	(
		; 			; 		#NoTray
		; 			; 		request( "%url%", "%tokenDguard%", "", "%method%" )
		; 			; 		Exitapp, 0
		; 			; 		request( url, tokenDguard, data, method="GET" )	{
		; 			; 			static req := ComoCreate( "WinHttp.WinHttpRequest.5.1" )
		; 			; 			req.open( "%method%", "%url%", False )
		; 			; 			if(	"%method%" != "GET" )
		; 			; 				req.SetRequestHeader("Content-Type", "application/json")
		; 			; 			If	tokenDguard
		; 			; 				req.SetRequestHeader( "Authorization", "tokenDguard 'tokenDguard%" )
		; 			; 			if	data
		; 			; 				req.send( "%data%" )
		; 			; 			Else
		; 			; 				req.send()
		; 			; 			response	:=	req.responseText
		; 			; 		}
		; 			; 	)'
		; 			; new_instance( instanced )

		; 		}
			delete := 0
			Msgbox
			Return
		; }
		; Else	{					;	Cria layout

		; 	If	__.error	{	;	Já existe
		; 		___ := Json( this.request( url, tokenDguard,""), url )

		; 		Loop,%	___.layouts.Count()
		; 			If( ___.layouts[A_Index].name = name ) {

		; 				z_oeto			:=	name
		; 				z					:=	{ guid	:	___.layouts[A_Index].guid }
		; 				_layouts[z_oeto]	:=	z
		; 				VarSetCapacity(z_oeto,0)

		; 			}
	
		; 	}
		; 	Else	{	;	criado novo layout

		; 		z_oeto			:=	name
		; 		z					:=	{ guid	:	__.layout.guid }
		; 		_layouts[z_oeto]	:=	z
		; 		VarSetCapacity(z_oeto,0)

		; 	}
		; 	Return	_layouts

		; }

	}

	; layout_cameras( server, tokenDguard, camera_guid, layout_guid, method="GET", aspect=1 )	{	;	 incompleto

	; 	if	!server
	; 		server	:= "localhost"

	; 	If	!tokenDguard {
	
	; 		tokenDguard := this._token( server, "", "" )
	; 		if	!tokenDguard {

	; 			Msgbox	%	"ERRO AO REQUISITAR O TOKEN PARA O SERVIDOR " server "`n`tClass Dguard.layout_add " A_LineNumber
	; 			Return
	
	; 		}

	; 	}

	; 	If	camera_guid && layout_guid	;	POST
	; 		method		:=	"POST"

	; 	Switch	method	{

	; 		Case	"GET":
	; 			URL	:=	"http://" server ":8081/api/layouts/" layout_guid "/cameras"
	; 			data =
	; 			return Json( this.request( url, tokenDguard, data, method ) )

	; 		Case	"POST":
	; 			URL	:=	"http://" server ":8081/api/layouts/" layout_guid "/servers"
	; 			data =	{ ""serverGuid"":""%camera_guid%"" }
	; 			instanced	 =
	; 				(	
	; 					#NoTrayIcon
	; 					request( "%url%", "%tokenDguard%", "%data%", "%method%" )
	; 					Exitapp, 0
	; 					request( url, tokenDguard, data, method="GET" )	{
	; 						static req := ComoCreate( "WinHttp.WinHttpRequest.5.1" )
	; 						req.open( "%method%", "%url%", False )
	; 						if(	"%method%" != "GET" )
	; 							req.SetRequestHeader("Content-Type", "application/json")
	; 						If	tokenDguard
	; 							req.SetRequestHeader( "Authorization", "tokenDguard %tokenDguard%" )
	; 						if	data
	; 							req.send( data )
	; 						Else
	; 							req.send()
	; 						response	:=	req.responseText
	; 					}
	; 				)
	; 			new_instance( instanced )
	; 			Return

	; 	}

	; }

	; licenses( server, tokenDguard )	{
	; 	;	.licenses[A_Index]

	; 	if	!server
	; 		server	:= "localhost"

	; 	If	!tokenDguard {
	
	; 		tokenDguard := this._token( server, "", "" )
	; 		if	!tokenDguard {

	; 			Msgbox	%	"ERRO AO REQUISITAR O TOKEN PARA O SERVIDOR " server "`n`tClass Dguard.layout_add " A_LineNumber
	; 			Return
	
	; 		}

	; 	}

	; 	data	:=	""
	; 	return Json( this.request( "http://" server ":8081/api/licenses/projects", tokenDguard, data, "GET" ) )

	; }

	; license_delete( server, tokenDguard, id )	{

	; 	if	!server
	; 		server	:= "localhost"

	; 	If	!tokenDguard {
	
	; 		tokenDguard := this._token( server, "", "" )
	; 		if	!tokenDguard {

	; 			Msgbox	%	"ERRO AO REQUISITAR O TOKEN PARA O SERVIDOR " server "`n`tClass Dguard.layout_add " A_LineNumber
	; 			Return
	
	; 		}

	; 	}

	; 	data	:=	""
	; 	return Json( this.request( "http://" server ":8081/api/licenses/projects/" id, tokenDguard, data, "DELETE" ) )

	; }

	; license_renew( server, tokenDguard, license )	{

	; 	if	!server
	; 		server	:= "localhost"

	; 	If	!tokenDguard {
	
	; 		tokenDguard := this._token( server, "", "" )
	; 		if	!tokenDguard {

	; 			Msgbox	%	"ERRO AO REQUISITAR O TOKEN PARA O SERVIDOR " server "`n`tClass Dguard.layout_add " A_LineNumber
	; 			Return
	
	; 		}

	; 	}

	; 	data	:=	"{ ""text"": """ license """ }"
	; 	return Json( this.request( "http://" server ":8081/api/licenses/projects/renewal", tokenDguard, data, "POST" ) )

	; }

	; layout_show( tokenDguard, layout_guid, monitor_guid, workstation_guid )	{	; NÃO FINALIZADO

	; 	if	!tokenDguard
	; 		tokenDguard := this._token()

	; 	c	:=	"http://localhost:8081/api/virtual-matrix/workstations/%7B" StrRep( workstation_guid,, "{", "}" )
	; 		.	"%7D/monitors/%7B" StrRep( monitor_guid,, "{", "}" )
	; 		.	"%7D/layout"""

	; 	data :=	"{ ""layoutGuid"": """ layout_guid """}"
	; 	Msgbox	%	data "`n" c
	; 	return this.request( c, tokenDguard, data, "PUT" )

	; }

	Static preset(num) {  ; exclusive - Migrar para outra classe
		clist := WinGetControls("Gerenciador")
		Loop clist.Length {
			if (InStr(clist[A_Index], "combobox")) {
				ctext := ControlGetText(clist[A_Index], "Gerenciador")
				if (InStr(ctext, "Preset") || InStr(ctext, "Default")) {
					control := clist[A_Index]
					break
				}
			}
		}
		ControlSend( "{RAW}" (num = 0 ? 10 : num), control, "Gerenciador")  ; Using {Raw} mode
	}

	static layouts(tokenDguard?) {
		If	!IsSet(tokenDguard)
			tokenDguard := this.getToken()
		url	:=	"http://localhost:8081/api/layouts"
		var := JSON.Parse( This.request( url, tokenDguard,"" ) )
		Return	var['layouts']
	}

	static recording(server, tokenDguard, guid, method:="GET")	{
		url	:= 'http://' server ':8081/api/servers/%7B' RegExReplace(guid, '[{}]') '%7D/cameras/0/recording'
		data:= '{ "enabled": true, "streamId": 0, "type": 0, "daysHoursLimitEnabled": true, "daysLimit": 33, "hoursLimit": 0, "emergencyRecording": false, "recordInAnyDrive": true }'
		__ := this.request(url, tokenDguard, data, method)
		OutputDebug	'`t' __
		; if	!InStr(__,'"recording":{"enabled":true')
		; 	MsgBox	__

	}

	static virtualMatrix(token?) {
		If	!IsSet(token)
			token := this.getToken()
		url	:=	'http://localhost:8081/api/virtual-matrix'
		data:=	'{ "machineName": "' A_ComputerName '", "enabled":true, "activationMode":1 }'
		RegExMatch(	this.request( url,token , data )
				,	'(?<=machineName":")(.*)(?=","enabled)'
				,	&var)
		Return	var[1]
		;"{"virtualMatrix":{"machineName":"CPC038830","enabled":true,"activationMode":1}}
	}

	static workspaces(token?) {
		If	!IsSet(token)
			token := this.getToken()
		url	:=	"http://localhost:8081/api/virtual-matrix/workstations"
		; data:=	'{}'
		Return	JSON.Parse(	__ := this.request( url,token,"" ) )
	}
*/
}

save_temp(){
	runCmd( "REG COPY HKCU\SOFTWARE\Seventh\DguardCenter HKCU\SOFTWARE\Seventh\_temp /s /f")
}