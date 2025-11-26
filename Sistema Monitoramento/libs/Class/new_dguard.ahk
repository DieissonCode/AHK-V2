
#Requires AutoHotkey v2.0
if (IsSet(__isInCluded))
	return

#Include ..\class\Json.ahk
#Include ..\class\Email.ahk
#Include ..\functions.ahk

Global subOutputDebug := false
Global mainOutputDebug := true
Global reqOutputDebug := false

Class Dguard extends Indexable {
	static __isInCluded := A_ScriptName
	static server_tokens := Map()  ; Armazena tokens por servidor
	static workstation := Map()  ; Armazena informações da estação de trabalho e monitores

	static Init(mapObject) {
				if subOutputDebug
			OutputDebug('---Dguard.Init called')
			return this.CreateIndex(mapObject)
	}

	static _createIndex(mapObject) {
				if subOutputDebug
			OutputDebug('---Dguard._createIndex called')
		return this.CreateIndex(mapObject)
	}

	static _isDguardRunning() {
		if subOutputDebug
			OutputDebug('--Dguard._isDguardRunning called')
		return ProcessExist('Dguard.exe') != 0
	}

	static _validateParams(params) {
				if subOutputDebug
			OutputDebug('--Dguard._validateParams called')
		return IsObject(params) && (params.__Class = 'Map' || params.__Class = '__Enumerator')
	}

	static _validateToken(params) {
				if subOutputDebug
			OutputDebug('--Dguard._validateToken called')
		if !params.Has('token') || params['token'] = '' {
			;tokenResult := this.getToken(Map('server', server, 'user', 'GeraErro'))
			tokenResult := this.getToken(Map('server', params['server']))
			if  tokenResult.error
				return tokenResult
			return tokenResult.HasProp('data') ? tokenResult.data : tokenResult.token
		}
		return params['token']
	}

	static _validateCredentials(params) {
		if subOutputDebug
			OutputDebug('--Dguard._validateCredentials called')
		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos")
		
		if (!params.Has('user') || params['user'] = '') && (!params.HasProp('user') || params.user = '')
			return this._createError("Usuário não fornecido")

		if (!params.Has('pass') || params['pass'] = '') && (!params.HasProp('pass') || params.pass = '')
			return this._createError("Senha não fornecida")
		
		if StrLen(params.Has('pass') ? params['pass'] : params.pass) < 4
			return this._createError("Senha deve conter pelo menos 4 caracteres")

		if StrLen(params.Has('user') ? params['user'] : params.user) < 2
			return this._createError("Usuário deve conter pelo menos 2 caracteres")

		return Map('valid', true, 'message', 'Credenciais válidas')
	}

	static _getDefaultPassword(params) {
				if subOutputDebug
			OutputDebug('--Dguard._getDefaultPassword called')
		if !this._validateParams(params)
			return ''
		
		if params.HasProp('pass') && params.pass != ''
			return params.pass
		
		if params.user = 'conceitto'
			return 'cjal2021'
		
		server := params.HasProp('server') ? params.server : 'localhost'
		ip := this._resolveServerIP(server)
		ipParts := StrSplit(ip, '.')
		
		if ipParts.Length >= 4 {
			lastOctet := ipParts[4]
			
			if (lastOctet >= 101 && lastOctet <= 124)
				return '@dm1n'
			
			if (lastOctet = 100)
				return '@Dm1n'
		}
		
		return 'admin'
	}

	static _getWorkstationInfo(params) {
		if subOutputDebug
			OutputDebug('--Dguard._getWorkstationInfo called')

		if !this._validateParams(params)
			return ''
		
		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.url := 'http://' server ':8081/api/virtual-matrix/workstations'
		reqParams.token := this._validateToken(params)
		reqParams.async := false

		response := this.request(reqParams)

		; Verificar erro
		if	response.error
			return response

		; Fazer parse do JSON
		try {
			parsed := JSON.parse(response.response)
			workstationsReturn := parsed['workstations'][1]

			workstations := Map()
			workstations.CaseSense := false
			workstations := workstationsReturn['guid']

			monitorsReturn := workstationsReturn['monitors']
			monitor := Map()

			Loop monitorsReturn.Length {
				monitor[A_Index] := monitorsReturn[A_Index]['guid']
			}
			this.workstation := Map('guid', workstations, 'monitor', monitor)

			return this._createSuccess(this.workstation)
		} catch as e {
			return this._createError("Erro ao fazer parse do JSON: " e.message, params)
		}

	}

	static _resolveServerIP(server) {
				if subOutputDebug
			OutputDebug('--Dguard._resolveServerIP called')
		dnsMap := Map(
			'vdm01', '192.9.100.181',
			'vdm02', '192.9.100.182',
			'vdm03', '192.9.100.183',
			'vdm04', '192.9.100.184',
			'vdm05', '192.9.100.185',
			'vdm06', '192.9.100.186'
		)
		
		if dnsMap.Has(server)
			return dnsMap[server]
		
		return server
	}

	static _createError(message, params?) {
				if subOutputDebug
			OutputDebug('--Dguard._createError called')
		errorMap := Map()
		errorMap.success := false
		errorMap.error := true
		errorMap.message := message
		errorMap.timestamp := A_Now

		if	IsSet(params)
		if IsObject(params) 	{
			errorMap.params := params
		}

		return errorMap
	}

	static _createSuccess(data := "", message?) {
				if subOutputDebug
			OutputDebug('--Dguard._createSuccess called')
		successMap := Map()
		successMap.success := true
		successMap.error := false
		if IsSet(message)
			successMap.message := message

		if data != ""
			successMap.data := data

		successMap.timestamp := A_Now

		return successMap
	}

	static request(params) {
		if reqOutputDebug
			OutputDebug('-Dguard.request called')
		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução")
		
		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto")

		if !params.url || params.url = ''
			return this._createError("URL é obrigatória")
		
		; Configurar padrões
		method := params.HasProp('method') ? params.method : 'GET'
		isAsync := params.HasProp('async') ? params.async : 'false'
		data := params.HasProp('data') ? params.data : ''
		static req := ComObject('WinHttp.WinHttpRequest.5.1')

		try {
			req.open(method, params.url, isAsync)
		} catch as e {
			return this._createError("Erro ao abrir requisição: " e.message "`nURL: " params.url "`nMétodo: " method "`nAsync: " isAsync "`nData: " data )
		}
		
		; Configurar headers
		if method != 'GET'
			req.SetRequestHeader('Content-Type', 'application/json')

		if params.HasProp('token') && params.token != ''
			req.SetRequestHeader('Authorization', 'Bearer ' params.token)

		; Enviar requisição
		try {
			req.Send(data)
		} catch as e {
			return this._createError("Erro ao abrir requisição: " e.message "`nURL: " params.url "`nMétodo: " method "`nAsync: " isAsync "`nData: " data )
		}
		;OutputDebug(req.statusText)
		result := this._createSuccess()
		if !isAsync
			result.response := req.responseText

		if params.Has('stream') && params['stream']
			result.stream := req.ResponseStream

		return result
	}

	static getToken(params := "") {
		if subOutputDebug
			OutputDebug('--Dguard.getToken called')
		if params = ''
			params := Map()
		
		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto")
		
		if !this._isDguardRunning()
			return this._createError("ERRO - Dguard não está em execução na máquina", params)
		
		; Resolver servidor
		if !params.Has('server') || params['server'] = '' || params['server'] = 'localhost'
			params.server := SysGetIPAddresses()[1]
		else
			params.server := params['server']
		
		; Verificar se token já existe em cache
		if this.server_tokens.Has(params.server)	{

			return this._createSuccess(this.server_tokens[params.server])
		}
		
		; Resolver IP do servidor
		server := this._resolveServerIP(params.server)
		
		; Configurar usuário padrão
		params.user := params.Has('user') && params['user'] != '' ? params['user'] : 'admin'
		
		; Obter senha padrão
		params.pass := this._getDefaultPassword(params)
		
		; Validar credenciais
		validationResult := this._validateCredentials(params)
		if validationResult.Has('error') && validationResult.error
			return validationResult
		
		; Preparar dados de login
		loginData := '{ "username" : "' params.user '", "password" : "' params.pass '" }'
		
		; Preparar parâmetros da requisição
		reqParams := Map()
		reqParams.url := 'http://' server ':8081/api/login'
		reqParams.method := 'POST'
		reqParams.data := loginData
		reqParams.async := false
		
		; Realizar requisição
		response := this.request(reqParams)
		
		; Verificar se houve erro
		if	response.error
			return response
		
		; Extrair token da resposta
		localToken := ''
		
		if RegExMatch(response.response, '(?<="userToken":")(.*)(?=","serverDate)', &match) {
			localToken := match[1]
		}
		
		; Validar se token foi extraído
		if localToken = ''
			return this._createError("Falha ao extrair token da resposta", params)
		
		; Armazenar token em cache
		this.server_tokens[params.server] := localToken
		
		result := this._createSuccess()
		result.token := localToken
		
		return result
	}

}

Class DguardCameras extends Dguard {

	static _abrevMap := Map()

	static get(params) {
		if mainOutputDebug
			OutputDebug('DguardCameras.get called')

		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto")

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para listar câmeras", params)

		params['server'] := params.Has('server') ? params['server'] : 'LocalHost'

		; Se o servidor for "servidor", buscar de todos os IPs
		if (params['server'] = 'servidor' || params['server'] = 'Servidor')
			return this._getCamerasFromAllServers(params)
		
		; Caso contrário, buscar de um servidor específico
		return this._getCamerasFromSingleServer(params)
	}

	; MÉTODO PRIVADO: Buscar câmeras de um servidor específico
	static _getCamerasFromSingleServer(params) {
		if mainOutputDebug
			OutputDebug('DguardCameras._getCamerasFromSingleServer called')

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.url := 'http://' server ':8081/api/servers'
		reqParams.token := this._validateToken(params)
		reqParams.async := false

		response := this.request(reqParams)

		; Verificar erro
		if response.error
			return response

		; Fazer parse do JSON
		cameras := Map()
		cameras.CaseSense := false

		try {
			parsed := JSON.parse(response.response)
			result := this._createSuccess()
			result.cameras := parsed['servers']
			For index, camera in result.cameras {
				if	InStr(camera['name'], 'vdm') || InStr(camera['name'], 'servidor')
					continue
				camera.server := server
				camera.token := reqParams.token
				camera.active := camera['active']
				camera.connected := camera['connected']
				camera.guid := camera['guid']
				camera.name := camera['name']

				camera.delete('active')
				camera.delete('connected')
				camera.delete('guid')
				camera.delete('name')
				camera.delete('hasChildren')
				camera.delete('parentGuid')

				cameras[camera.name] := camera

				if params.Has('createMap')
					this._createMap(camera)
			}

			return cameras
		} catch as e {
			return this._createError("Erro ao fazer parse do JSON: " e.message, params)
		}
	}

	; MÉTODO PRIVADO: Buscar câmeras de todos os servidores
	static _getCamerasFromAllServers(params) {
		if mainOutputDebug
			OutputDebug('DguardCameras._getCamerasFromAllServers called')
		; Lista de servidores
		servers := [
			'192.9.100.181',
			'192.9.100.182',
			'192.9.100.183',
			'192.9.100.184',
			'192.9.100.185',
			'192.9.100.186'
		]

		; Map para armazenar todas as câmeras
		Cameras := Map()

		; Map para armazenar erros
		errors := Map()

		; Iterar sobre cada servidor
		Loop servers.Length {
			currentServer := servers[A_Index]

			; Obter token do servidor
			tokenResult := this.getToken(Map('server', currentServer))

			if tokenResult.error {
				errors[currentServer] := tokenResult.message
				continue
			}

			token := tokenResult.token

			; Realizar requisição para obter câmeras
			reqParams := Map()
			reqParams.url := 'http://' currentServer ':8081/api/servers'
			reqParams.token := token

			response := this.request(reqParams)

			; Se houver erro, adicionar ao mapa de erros
			if response.error {
				errors[currentServer] := response.message
				continue
			}

			; Fazer parse do JSON
			try {
				parsed := JSON.parse(response.response)
				result := parsed['servers']

				; Adicionar propriedades server e token a cada câmera
				Loop result.Length {
					if	InStr(result[A_Index]['name'], 'vdm')
						continue
					camera := result[A_Index]
					camera.server := currentServer
					camera.token := token
					camera.active := camera['active']
					camera.connected := camera['connected']
					camera.guid := camera['guid']
					camera.name := camera['name']

					camera.delete('guid')
					camera.delete('connected')
					camera.delete('active')
					camera.delete('name')
					camera.delete('hasChildren')
					camera.delete('parentGuid')
					camera.delete('Count')

					; Adicionar câmera à lista geral
					Cameras[camera.name] := camera

					if params.Has('createMap')
						this._createMap(camera)
				}

			} catch as e {
				errors[currentServer] := "Erro ao fazer parse do JSON: " e.message
				continue
			}
		}

		; Adicionar informações de erros se houver
		if errors.Count > 0 {
			Cameras['servers_with_errors'] := errors
			Cameras['servers_successfully_fetched'] := servers.Length - errors.Count
		} else {
			Cameras['servers_successfully_fetched'] := servers.Length
		}

		return Cameras
	}

	static _createMap(params)	{
		if subOutputDebug
			OutputDebug('--DguardCameras._createMap called')
		prefix := RegExReplace(params.name, "^([^\]]+\]).*", "$1")
		if !this._abrevMap.Count	{
			this._abrevMap.CaseSense := false
			this._abrevMap.Default := 'Not Found'
		}

		if !this._abrevMap.Has(prefix)
			this._abrevMap[prefix] := Map(1, params.guid)
		else
			this._abrevMap[prefix][this._abrevMap[prefix].Count + 1] := params.guid

		return
	}
}

Class DguardLayouts extends Dguard {

	static get(params) {
		if mainOutputDebug
			OutputDebug('DguardLayouts.get called')
		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map()")

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para listar layouts", params)

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.url := 'http://' server ':8081/api/layouts'
		reqParams.token := this._validateToken(params)
		reqParams.async := false

		response := this.request(reqParams)

		; Verificar erro
		if	response.error
			return response

		; Fazer parse do JSON
		try {
			parsed := JSON.parse(response.response)
			layoutsReturn := parsed['layouts']
			layouts := Map()
			layouts.CaseSense := false
			For index, value in layoutsReturn {
				layout := Map()
				layout.name := value['name']
				if InStr('Todas as Câmeras Nenhum', layout.name)
					continue
				layout.camerasCount :=	value['camerasCount']
				layout.firstCameraId :=	value['firstCameraId']
				layout.guid :=			value['guid']
				layout.mosaicGuid :=	value['mosaicGuid']
				layout.readOnly :=		value['readOnly']
				layout.status :=		value['status']

				layout.delete('camerasCount')
				layout.delete('firstCameraId')
				layout.delete('guid')
				layout.delete('mosaicGuid')
				layout.delete('readOnly')
				layout.delete('status')

				layouts[layout.name] := layout
			}
			return layouts
		} catch as e {
			return this._createError("Erro ao fazer parse do JSON: " e.message, params)
		}
	}

	static getCameras(params) {
		if mainOutputDebug
			OutputDebug('DguardLayouts.getCameras called')
		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map()")

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para listar layouts", params)

		if !params.Has('layoutGuid') || params['layoutGuid'] = ''
			return this._createError("layoutGuid é obrigatório para listar layouts", params)

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.url := 'http://' server ':8081/api/layouts/' params['layoutGuid'] '/cameras'
		reqParams.token := this._validateToken(params)
		reqParams.async := false

		response := this.request(reqParams)

		; Verificar erro
		if	response.error
			;response = {"error":{"guid":"{42CFAFE7-8BE7-46D5-B712-B552507CE136}","message":"Entity not found","description":"Layout not found"}}
			return response

		; Fazer parse do JSON
		try {
			parsed := JSON.parse(response.response)
			camerasReturn := parsed['cameras']
			cameras := Map()
			cameras.CaseSense := false

			Loop camerasReturn.Length {
				camera := Map()
				camera.name := camerasReturn[A_Index]['cameraName']
				camera.guid := camerasReturn[A_Index]['serverGuid']
				camera.sequence := camerasReturn[A_Index]['sequence']
				cameras[A_Index] := camera

			}
			return cameras
		}
		catch as e {
			return this._createError("Erro ao fazer parse do JSON: " e.message, params)
		}
	}

	; create( server, name, token )
	static create(params) {
		if mainOutputDebug
			OutputDebug('DguardLayouts.create called')

		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto", params)

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para listar layouts", params)

		if !params.Has('name') || params['name'] = ''
			return this._createError("name é obrigatório para criar layout", params)

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.layoutGuid := this.exists(params)
		if  reqParams.layoutGuid && params.Has('delete') && params['delete']
			this.delete(params)

		reqParams.url := 'http://' server ':8081/api/layouts'
		reqParams.token := this._validateToken(params)
		reqParams.method := 'POST'
		reqParams.data := '{ "name": "' params['name'] '", "status": 0 }'
		reqParams.async := false

		responseObj := this.request(reqParams)

		;	Trata Layout existente
		if responseObj.success = true	{
			response := JSON.parse( responseObj.response )
			if response.Has('error')	{
				erro := Map()
				erro.guid := this._indexed[params['name']]
				responseObj.response := erro
			}
		}

		; Verificar erro
		if responseObj.HasProp('error') && responseObj.error = true
			return responseObj.response.error.message

		; Verificar sucesso - se já existe, retorna o guid existente
		if responseObj.HasProp('response') && responseObj.error = false && !response.Has('layout')	{
			return responseObj.response.guid
		}

		if response.Has('layout')	{
			return response['layout']['guid']
		}
		else
			return responseObj
	}

	; delete( server, guid/name )
	static delete(params){
		if mainOutputDebug
			OutputDebug('DguardLayouts.delete called')

		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto", params)

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para listar layouts", params)

		if (!params.Has('guid') || params['guid'] = '') && (!params.Has('name') || params['name'] = '')
			return this._createError("GUID ou name são obrigatórios para deletar layout", params)

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.layoutGuid := this.exists(params)
		if	!reqParams.layoutGuid
			return this._createError("Layout não encontrado para exclusão", params)
		if !InStr(reqParams.layoutGuid, '{')
			reqParams.layoutGuid := params['guid']
		if reqParams.layoutGuid	{
			reqParams.url := 'http://' server ':8081/api/layouts/%7B' . RegExReplace( reqParams.layoutGuid,"[{}]" ) . '%7D'
			reqParams.token := this._validateToken(params)
			reqParams.method := 'DELETE'
			response := this.request(reqParams)
		}
		else	{
			return this._createError("Layout não encontrado para exclusão", params)
		}
		; Verificar erro
		if	response.HasProp('error') && response.error = true
			return this._createError("Erro ao excluir layout: " . response.message, params)
		; Verificar sucesso
		If response.HasProp('success') && response.success = true
			return this._createSuccess(true, "Layout excluído com sucesso")
		else
			return this._createError("Falha ao excluir layout", params)
	}

	static exists(params) {
		if subOutputDebug
			OutputDebug('--DguardLayouts.exists called')

		if params.Has('layouts')
			layouts := params['layouts']
		else
			layouts := this.get(params)

		if !layouts.Has('index')
			layouts := this.CreateIndex(layouts)

		if	params.Has('name')
			return this.IndexOr(params['name'], false)

		if params.Has('guid')
			return this.IndexOr(params['guid'], false)

		if	params.Has('LayoutName')
			return this.IndexOr(params['LayoutName'], false)

		if params.Has('LayoutGuid')
			return this.IndexOr(params['LayoutGuid'], false)
	}

	static addCam(params){
		if mainOutputDebug
			OutputDebug('DguardLayouts.addCam called')
		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto", params)

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para inserir câmeras no layout", params)

		server	:=	params['server']

		; Realizar requisição
		reqParams := Map()
		if !params.Has('camera') || params['camera'] = ''
			return this._createError("Câmera é obrigatória para inserir no layout", params)

		if !params.Has('alarm')
			reqParams.layoutGuid := this.exists(params)
		else
			reqParams.layoutGuid := params['guid']
		if	!reqParams.layoutGuid
			return this._createError("Layout não encontrado para inserir câmeras", params )

		if !InStr(reqParams.layoutGuid, '{')
			reqParams.layoutGuid := params['guid']

		if reqParams.HasProp('layoutGuid')	{
			data := '{ "serverGuid": "' params['camera'] '", "cameraId": 0, "aspectRatio": 1, "AllowDuplicates" : false }'
			reqParams.url := 'http://' server ':8081/api/layouts/%7B' . RegExReplace( reqParams.layoutGuid,"[{}]" ) . '%7D/cameras'
			reqParams.token := this._validateToken(params)
			reqParams.method := 'POST'
			reqParams.data := data
			reqParams.async := true
			return this.request(reqParams)
		}
		else	{
			return this._createError("Layout não encontrado para exclusão", params )
		}
	}

	static show(params) {
		if mainOutputDebug
			OutputDebug('DguardLayouts.show called')

		if !this._isDguardRunning()
			return this._createError("Dguard não está em execução", params)

		if !this._validateParams(params)
			return this._createError("Parâmetros inválidos - esperado Map/Objeto", params)

		if !params.Has('server') || params['server'] = ''
			return this._createError("Servidor é obrigatório para inserir câmeras no layout", params)

		if !params.Has('layoutGuid') || params['layoutGuid'] = ''
			return this._createError("LayoutGuid é obrigatório para inserir câmeras", params)

		server := params['server']

		; Realizar requisição
		reqParams := Map()
		reqParams.layoutGuid := params['layoutGuid']

		if !reqParams.layoutGuid
			return this._createError("Layout não encontrado para inserir câmeras", params )

		if !InStr(reqParams.layoutGuid, '{')
			reqParams.layoutGuid := params['guid']

		if reqParams.layoutGuid	{
			data := '{ "layoutGuid": "'  reqParams.layoutGuid '", "cameraId": 0 }'
			monitor := params['monitorGuid'] ? params['monitorGuid'] : this.workstation['monitor'][1]
			reqParams.url := 'http://' server ':8081/api/virtual-matrix/workstations/%7B' RegexReplace(this.workstation['guid'], "[{}]", "") '%7D/monitors/%7B' RegexReplace(monitor, "[{}]", "") '%7D/layout'
			reqParams.token := this._validateToken(params)
			reqParams.method := 'PUT'
			reqParams.data := data

			response := this.request(reqParams)

			return response.success
		}
		else	{
			return this._createError("Layout não encontrado para exclusão", params )
		}
	}
}

Class DguardAlarm extends Dguard {

		static setAlarmLayout(params) {
			if mainOutputDebug
				OutputDebug('DguardAlarm.process called')

			if !this._isDguardRunning()
				return this._createError("Dguard não está em execução", params)

			if !this._validateParams(params)
				return this._createError("Parâmetros inválidos - esperado Map/Objeto", params)

			if !params.Has('server') || params['server'] = ''
				return this._createError("Servidor é obrigatório para inserir câmeras no layout", params)

			if !params.Has('layoutGuid') || params['layoutGuid'] = ''
				return this._createError("LayoutGuid é obrigatório para inserir câmeras", params)

			Dguard._getWorkstationInfo(Map('server', params['server']))

			if !params.Has('cameras') || params['cameras'] = 'Not Found'
				return this._createError("Não localizado mapa de câmeras", params)

			DguardLayouts.show(Map('server', params['server'], 'layoutGuid', params['layoutGuid']))
			Loop params['cameras'].Count {
				DguardLayouts.addCam( Map(
					'guid', params['layoutGuid'],
					'server', params['server'],
					'alarm', true,
					'camera', params['cameras'][A_Index] ) )
			}

			DguardLayouts.show(Map('server', params['server'], 'layoutGuid', params['layoutGuid']))
		}

		static setNormalLayout(unitName) {
			return "ALARM_" . unitName
		}
}


/**
 * @class Indexable
 * @description Classe para gerenciar índices incrementais de maps com busca rápida
 * @author DieissonCode
 * @date 2025-11-06 18:47:18 UTC
 * @version 1.1.0
 * 
 * Métodos Disponíveis:
 * - CreateIndex(mapObject, caseSensitive)  - Cria um índice a partir de um Map (INCREMENTAL)
 * - Index(key)                              - Busca simples, retorna string
 * - IndexOr(key, default)                   - Busca com valor padrão
 * - HasIndex(key)                           - Verifica se existe
 * - CountIndex()                            - Conta itens no índice
 * - ListIndex()                             - Lista todas as entradas
 * - IndexMulti(keys*)                       - Busca múltiplas chaves
 * - GetIndex()                              - Retorna o índice completo
 * - GetMapObject()                          - Retorna o mapObject original
 * - ClearIndex()                            - Limpa o índice
 * - ResetIndex()                            - Reset completo (novo índice)
 */
class Indexable {
	static _mapObject := Map()
	static _indexed := Map()
	static _mapHistory := []  ; ⭐ Rastreia todos os maps adicionados
	static _initialized := false  ; ⭐ Flag para primeira inicialização
	
	/**
	 * @method CreateIndex
	 * @description Cria o índice para busca rápida (INCREMENTAL - acumula dados)
	 * @param {Map} mapObject - Map contendo itens para indexar
	 * @param {Boolean} [caseSensitive=false] - Define se a busca é case sensitive
	 * @returns {Map} - O mapObject indexado
	 * 
	 * @example
	 * map1 := Map()
	 * map1[1] := Map('guid', 'g1', 'name', 'Camera 1')
	 * Indexable.CreateIndex(map1)
	 * 
	 * map2 := Map()
	 * map2[1] := Map('guid', 'g2', 'name', 'Camera 2')
	 * Indexable.CreateIndex(map2)  ; ⭐ Acumula com map1
	 * 
	 * Indexable.CountIndex()  ; Retorna 2 (não 1)
	 * @static
	 */
	static CreateIndex(mapObject, caseSensitive := false) {
		; ⭐ Inicializa _indexed se for a primeira vez ou se estiver vazio
		if (!this._initialized || this._indexed.Count = 0) {
			this._indexed := Map()
			this._indexed.CaseSense := caseSensitive
			this._initialized := true
		}
		

		; ⭐ INCREMENTAL - Adiciona ao índice existente
		For index, item in mapObject {
			if (item.__Class != 'Map')
				continue

			; Indexar guid -> name e name -> guid
			if item.HasOwnProp('guid') && item.HasOwnProp('name') {
				this._indexed[item.guid] := item.name
				this._indexed[item.name] := item.guid
			}
		}

		; Adiciona a propriedade ao objeto original
		mapObject.index := this._indexed
		this._mapObject := mapObject
		
		; ⭐ Rastreia o histórico
		this._mapHistory.Push({
			timestamp: A_Now,
			mapObject: mapObject,
			indexCount: this._indexed.Count
		})

		return mapObject
	}
	
	/**
	 * @method Index
	 * @description Busca uma chave no índice
	 * @param {String} key - Chave a ser buscada (guid ou name)
	 * @returns {String} - Valor encontrado ou string vazia
	 * @example
	 * result := Indexable.Index('guid-001')
	 * @static
	 */
	static Index(key) {
		if !this._indexed.Count
			return ''
		
		return this._indexed.Has(key) ? String(this._indexed[key]) : ''
	}
	
	/**
	 * @method IndexOr
	 * @description Busca com valor padrão
	 * @param {String} key - Chave a ser buscada
	 * @param {String} [defaultValue=''] - Valor padrão se não encontrar
	 * @returns {String} - Valor encontrado ou valor padrão
	 * @example
	 * result := Indexable.IndexOr('guid-001', 'Não encontrado')
	 * @static
	 */
	static IndexOr(key, defaultValue := '') {
		if !this._indexed.Count
			return defaultValue
		return this._indexed.Has(key) ? String(this._indexed[key]) : defaultValue
	}
	
	/**
	 * @method HasIndex
	 * @description Verifica se a chave existe no índice
	 * @param {String} key - Chave a verificar
	 * @returns {Boolean} - true se existe, false caso contrário
	 * @example
	 * if (Indexable.HasIndex('guid-001')) {
	 *     MsgBox("Encontrado!")
	 * }
	 * @static
	 */
	static HasIndex(key) {
		return this._indexed.Has(key)
	}

	/**
	 * @method GetIndex
	 * @description Retorna o objeto completo do índice
	 * @returns {Map} - Map com todo o índice
	 * @example
	 * allIndex := Indexable.GetIndex()
	 * @static
	 */
	static GetIndex() {
		return this._indexed
	}
	
	/**
	 * @method GetMapObject
	 * @description Retorna o mapObject original
	 * @returns {Map} - Map original com os dados
	 * @example
	 * original := Indexable.GetMapObject()
	 * @static
	 */
	static GetMapObject() {
		return this._mapObject
	}
	
	/**
	 * @method CountIndex
	 * @description Conta quantos itens (únicos) existem no índice
	 * @returns {Integer} - Número de itens (guid/name são contados como 1)
	 * @example
	 * total := Indexable.CountIndex()
	 * @static
	 */
	static CountIndex() {
		return Round(Floor(this._indexed.Count/2))
	}
	
	/**
	 * @method ClearIndex
	 * @description Limpa o índice mantendo histórico
	 * @returns {void}
	 * @example
	 * Indexable.ClearIndex()
	 * @static
	 */
	static ClearIndex() {
		this._indexed.Clear()
		if this._mapObject.HasOwnProp('index')
			this._mapObject.index.Clear()
		if (mainOutputDebug)
			OutputDebug("✅ Índice limpo")
	}
	
	/**
	 * @method ResetIndex
	 * @description Reset completo - cria novo índice do zero
	 * @returns {void}
	 * @example
	 * Indexable.ResetIndex()
	 * @static
	 */
	static ResetIndex() {
		this._indexed := Map()
		this._mapObject := Map()
		this._mapHistory := []
		this._initialized := false
		if (mainOutputDebug)
			OutputDebug("✅ Índice resetado completamente")
	}
	
	/**
	 * @method ListIndex
	 * @description Lista todas as entradas do índice
	 * @returns {String} - String formatada com todas as entradas
	 * @example
	 * lista := Indexable.ListIndex()
	 * OutputDebug(lista)
	 * @static
	 */
	static ListIndex() {
		if !this._indexed.Count
			return 'Índice vazio'
		
		texto := ''
		for key, value in this._indexed {
			texto .= key . ' => ' . value . '`n'
		}
		return RTrim(texto, '`n')
	}
	
	/**
	 * @method IndexMulti
	 * @description Busca múltiplas chaves (retorna resultado de cada uma)
	 * @param {String} keys* - Várias chaves para buscar
	 * @returns {String} - Resultado de cada busca em nova linha
	 * @example
	 * resultado := Indexable.IndexMulti('guid-001', 'Camera 1', 'guid-999')
	 * @static
	 */
	static IndexMulti(keys*) {
		result := ''
		for key in keys {
			result .= this.IndexOr(key, key ' não encontrado') "`n"
		}
		return result ? RTrim(result, '`n') : ''
	}
	
	/**
	 * @method GetHistory
	 * @description Retorna histórico de criações de índice
	 * @returns {Array} - Array com histórico de operações
	 * @example
	 * hist := Indexable.GetHistory()
	 * @static
	 */
	static GetHistory() {
		return this._mapHistory
	}
	
	/**
	 * @method PrintStatus
	 * @description Exibe status completo do índice
	 * @returns {void}
	 * @example
	 * Indexable.PrintStatus()
	 * @static
	 */
	static PrintStatus() {
		if (mainOutputDebug) {
			OutputDebug("╔════════════════════════════════════════╗")
			OutputDebug("║     STATUS DO ÍNDICE INCREMENTAL      ║")
			OutputDebug("╚════════════════════════════════════════╝")
			OutputDebug("Total de itens: " . this.CountIndex())
			OutputDebug("Total de entradas: " . this._indexed.Count())
			OutputDebug("Operações de índice: " . this._mapHistory.Length)
			OutputDebug("")
			OutputDebug("Últimos 5 índices criados:")
			
			start := this._mapHistory.Length > 5 ? this._mapHistory.Length - 4 : 1
			Loop this._mapHistory.Length - start + 1 {
				idx := start + A_Index - 1
				info := this._mapHistory[idx]
				OutputDebug("  [" . idx . "] - " . info.timestamp . " (Total: " . info.indexCount . ")")
			}
		}
	}
}

;if (mainOutputDebug)
;	OutputDebug("✅ Indexable carregado com sucesso")