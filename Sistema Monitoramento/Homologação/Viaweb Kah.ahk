;Save_To_Sql=1
;Keep_Versions=5
;@Ahk2Exe-Let U_FileVersion = 0.0.4.4
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Viaweb
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\switch_collumn.ico

/**
 * VIAWEB KAH - Monitor de Segurança
 * 
 * Sistema de monitoramento e controle de centrais de alarme via protocolo VIAWEB.
 * Permite visualização de status de partições e sensores, além de comandos de armar/desarmar.
 * 
 * @version 0.0.4.4
 * @requires AutoHotkey v2.0
 */

#Requires AutoHotkey v2.0
#Warn All, off
#SingleInstance Force
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Json.ahk
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\ComboBoxFilter.ahk
Persistent

; ===================== CONFIGURAÇÃO =====================
	; Conexão com servidor VIAWEB
	IP := "10.0.20.43"
	PORTA := 2700
	CHAVE := "94EF1C592113E8D27F5BB4C5D278BF3764292CEA895772198BA9435C8E9B97FD"
	IV := "70FC01AA8FCA3900E384EA28A5B7BCEF"

	; Configurações padrão de operação
	ISEP_DEFAULT := "0001 - Sede"
	SENHA_DEFAULT := "8790"

	; Intervalos de polling e atualização (em milissegundos)
	POLL_INTERVAL_MS := 500
	GUI_UPDATE_MS := 1000
	
	; Limites e constantes
	MAX_HISTORICO := 50
	MAX_PARTICOES := 8
	MAX_SENSORES := 32
	BLOCK_SIZE := 16  ; Tamanho do bloco AES
	RECV_BUFFER_SIZE := 65536

; ===================== CONSTANTES DE CORES =====================
	CORES := {
		ARMADA:				"00AA00",
		DESARMADA:			"FFAA00",
		DISPARADA:			"FF0000",
		CONECTADO:			"00FF00",
		DESCONECTADO:		"FF0000",
		INFO:				"0099FF",
		SUCESSO:			"00AA00",
		ERRO:				"FF0000",
		TEXTO_GRUPO:		"001f4e",
		TEXTO_ESCURO:		"000000",
		TEXTO_CLARO:		"FFFFFF",
		FUNDO_NEUTRAL:		"6e6d6d",
		FUNDO_INTERFACE:	"b1b1b1",
		BORDER_INFO:		"000000",
		; Cores dos sensores
		SENSOR_DISPARADO:	"FF0000",
		SENSOR_ABERTO:		"FFAA00",
		SENSOR_TAMPER:		"9932CC",
		SENSOR_TEMPORIZADO:	"FF8C00",
		SENSOR_INIBIDO:		"87CEEB",
		SENSOR_BATLOW:		"FF69B4",
		SENSOR_OK:			"00AA00"
	}

; ===================== VARIÁVEIS GLOBAIS =====================
	global client := 0
	global particionesStatus := Map()
	global zonasStatus := Map()
	global historicoMensagens := []
	global ultimaAtualizacao := ""
	global statusConexao := "Desconectado"
	global colorConexao := CORES.DESCONECTADO
	global guiHwnd := 0
	global gunidades := [
        {id: "0001", label: "Sede"}
      , {id: "0002", label: "Acerto"}
      , {id: "0003", label: "Filial Norte"}
    ]

	; Controles de GUI
	global guiCtrlISEP := 0
	global guiCtrlStatusConexao := 0
	global guiCtrlTimestamp := 0
	global guiCtrlParticoes := []
	global guiCtrlParticoesText := 0
	global guiCtrlSensores := []
	global guiCtrlHistorico := 0

	; Buffers para recepção
	global recvEncryptedAccum := Buffer(0)   ; acumula ciphertext entre recvs
	global recvPlainBuffer    := ""          ; acumula plaintext (JSON não processado)

; ===================== CLASSES =====================

	/**
	 * Classe base com os comandos do protocolo VIAWEB
	 * Implementa comandos de identificação, armar, desarmar e consulta de status
	 */
	class Viaweb {
		/**
		 * Gera um ID único para comandos baseado no IP e contador
		 * @returns {String} ID único do comando
		 */
		GetCommandId() {
			this.commandId++
			return SubStr(SysGetIPAddresses()[1], -3) this.commandId
		}

		/**
		 * Envia comando de identificação ao servidor VIAWEB
		 * @param {String} nome - Nome do cliente a identificar
		 */
		Identificar(nome := "AHK Monitor") {
			identJson := '{"a":' Random(1, 999999) ',"oper":[{"acao":"ident","nome":"' nome '"},{"acao":"salvarVIAWEB","operacao":2,"monitoramento":1}]}'
			this.Send(identJson)
		}

		/**
		 * Arma partições da central
		 * @param {String} idISEP - ID da unidade ISEP
		 * @param {String} senha - Senha de autenticação
		 * @param {Array|Number} particoes - Partição ou array de partições a armar
		 * @param {Number} forcado - 1 para armar forçado, 0 para armar normal
		 */
		Armar(idISEP, senha, particoes, forcado := 0) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			if (Type(particoes) != "Array")
				particoes := [particoes]
			particoesStr := "[" JoinArray(particoes, ",") "]"
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"armar","password":"' senha '","forcado":' forcado ',"particoes":' particoesStr '}]}]}'
			this.Send(cmdObj)
			AddHistorico("🔒 Armar: " JoinArray(particoes, ","), CORES.ARMADA)
			this.StatusParticoes(idISEP)
			this.StatusZonas(idISEP)
		}

		/**
		 * Desarma partições da central
		 * @param {String} idISEP - ID da unidade ISEP
		 * @param {String} senha - Senha de autenticação
		 * @param {Array|Number} particoes - Partição ou array de partições a desarmar
		 */
		Desarmar(idISEP, senha, particoes) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			if (Type(particoes) != "Array")
				particoes := [particoes]
			particoesStr := "[" JoinArray(particoes, ",") "]"
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"desarmar","password":"' senha '","particoes":' particoesStr '}]}]}'
			this.Send(cmdObj)
			AddHistorico("🔓 Desarmar: " JoinArray(particoes, ","), CORES.DESARMADA)
			this.StatusParticoes(idISEP)
			this.StatusZonas(idISEP)
		}

		/**
		 * Solicita status das partições
		 * @param {String} idISEP - ID da unidade ISEP
		 */
		StatusParticoes(idISEP) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"particoes"}]}]}'
			this.Send(cmdObj)
			AddHistorico("📋 Consultando partições...`tcmdId: " cmdId "`tIdIsep: " idClean, CORES.INFO)
		}

		/**
		 * Solicita status das zonas/sensores
		 * @param {String} idISEP - ID da unidade ISEP
		 */
		StatusZonas(idISEP) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"zonas"}]}]}'
			this.Send(cmdObj)
			AddHistorico("📋 Consultando zonas...`tcmdId: " cmdId "`tIdIsep: " idClean, CORES.INFO)
		}
	}

	/**
	 * Cliente VIAWEB - Gerencia socket, criptografia e herda comandos do protocolo
	 * Implementa conexão TCP com criptografia AES-CBC
	 */
	class ViawebClient extends Viaweb {
		socket := 0
		crypto := 0
		connected := false
		recvBuffer := Buffer(65536)
		commandId := 0
		hwnd := 0

		__New(ip, port, hexKey, hexIV) {
			this.ip := ip
			this.port := port
			this.crypto := ViawebCrypto(hexKey, hexIV)
		}

		/**
		 * Estabelece conexão TCP com o servidor VIAWEB
		 * @returns {Boolean} true se conectado com sucesso
		 * @throws {Error} Se falhar em alguma etapa da conexão
		 */
		Connect() {
			; Inicializa Winsock
			wsaData := Buffer(408)
			if DllCall("ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData)
				throw Error("WSAStartup falhou")

			; Cria socket TCP
			this.socket := DllCall("ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "Ptr")
			if (this.socket = -1)
				throw Error("Falha ao criar socket")

			; Resolve hostname
			hostent := DllCall("ws2_32\gethostbyname", "AStr", this.ip, "Ptr")
			if (! hostent)
				throw Error("Falha ao resolver hostname")

			; Extrai endereço IP
			addrList := NumGet(hostent + (A_PtrSize = 8 ? 24 : 12), "Ptr")
			addr := NumGet(addrList, "Ptr")
			ipAddr := NumGet(addr, "UInt")

			; Prepara estrutura sockaddr
			sockAddr := Buffer(16, 0)
			NumPut("Short", 2, sockAddr, 0)
			NumPut("UShort", DllCall("ws2_32\htons", "UShort", this.port, "UShort"), sockAddr, 2)
			NumPut("UInt", ipAddr, sockAddr, 4)

			; Conecta ao servidor
			result := DllCall("ws2_32\connect", "Ptr", this.socket, "Ptr", sockAddr, "Int", 16, "Int")
			if (result = -1)
				throw Error("Falha ao conectar: " DllCall("ws2_32\WSAGetLastError", "Int"))

			; Configura socket como non-blocking
			modeBuf := Buffer(4)
			NumPut("UInt", 1, modeBuf, 0)
			res := DllCall("ws2_32\ioctlsocket", "Ptr", this.socket, "UInt", 0x8004667E, "Ptr", modeBuf)
			if (res != 0) {
				err := DllCall("ws2_32\WSAGetLastError", "Int")
				DllCall("ws2_32\closesocket", "Ptr", this.socket)
				this.socket := 0
				throw Error("ioctlsocket falhou: " err)
			}

			this.connected := true
			FileAppend("[DEBUG] Socket: " this.socket " conectado (NON-BLOCKING)`n", A_ScriptDir "\debug.log")
			return true
		}

		/**
		 * Fecha conexão e limpa recursos
		 */
		Disconnect() {
			if (this.socket) {
				DllCall("ws2_32\closesocket", "Ptr", this.socket)
				DllCall("ws2_32\WSACleanup")
				this.socket := 0
				this.connected := false
			}
		}

		/**
		 * Envia dados criptografados ao servidor
		 * @param {String} jsonStr - String JSON a enviar
		 * @returns {Number} Número de bytes enviados
		 * @throws {Error} Se não conectado ou falha no envio
		 */
		Send(jsonStr) {
			if (!this.connected)
				throw Error("Não conectado")

			encrypted := this.crypto.Encrypt(jsonStr)
			result := DllCall("ws2_32\send", "Ptr", this.socket, "Ptr", encrypted, "Int", encrypted.Size, "Int", 0, "Int")
			if (result = -1)
				throw Error("Falha ao enviar: " DllCall("ws2_32\WSAGetLastError", "Int"))
			return result
		}

		/**
		 * Verifica e processa dados recebidos do servidor
		 * Acumula dados criptografados, descriptografa blocos completos e processa JSON
		 */
		Poll() {
			if (!this.connected)
				return

			; Recebe dados disponíveis
			Loop {
				recvBuf := Buffer(RECV_BUFFER_SIZE)
				received := DllCall("ws2_32\recv", "Ptr", this.socket, "Ptr", recvBuf, "Int", recvBuf.Size, "Int", 0, "Int")
				if (received < 0) {
					err := DllCall("ws2_32\WSAGetLastError", "Int")
					; WSAEWOULDBLOCK (10035) é esperado em non-blocking
					if (err = 10035)
						break
					FileAppend("[DEBUG] WSA Error: " err "`n", A_ScriptDir "\debug.log")
					; WSAECONNRESET (10054) significa conexão fechada
					if (err = 10054) {
						AddHistorico("⚠️ Conexão fechada.", CORES.ERRO)
						this.Disconnect()
						return
					}
					break
				}
				if (received = 0) {
					AddHistorico("⚠️ Conexão fechada pelo servidor.", CORES.ERRO)
					this.Disconnect()
					return
				}

				; Copia dados recebidos para novo buffer
				chunk := Buffer(received)
				Loop received
					NumPut("UChar", NumGet(recvBuf, A_Index-1, "UChar"), chunk, A_Index-1)

				global recvEncryptedAccum
				recvEncryptedAccum := CombineBuffers(recvEncryptedAccum, chunk)
			}

			; Processa blocos completos de criptografia (múltiplos de 16 bytes)
			global recvEncryptedAccum, recvPlainBuffer
			if (!recvEncryptedAccum.Size)
				return

			fullBlocksBytes := Floor(recvEncryptedAccum.Size / BLOCK_SIZE) * BLOCK_SIZE
			if (fullBlocksBytes > 0) {
				; Extrai blocos completos para processamento
				procBuf := Buffer(fullBlocksBytes)
				Loop fullBlocksBytes
					NumPut("UChar", NumGet(recvEncryptedAccum, A_Index-1, "UChar"), procBuf, A_Index-1)

				; Mantém bytes restantes no acumulador
				leftoverSize := recvEncryptedAccum.Size - fullBlocksBytes
				if (leftoverSize > 0) {
					leftover := Buffer(leftoverSize)
					Loop leftoverSize
						NumPut("UChar", NumGet(recvEncryptedAccum, fullBlocksBytes + A_Index-1, "UChar"), leftover, A_Index-1)
					recvEncryptedAccum := leftover
				} else {
					recvEncryptedAccum := Buffer(0)
				}

				; Descriptografa blocos
				try {
					plaintext := this.crypto.Decrypt(procBuf)
					recvPlainBuffer := recvPlainBuffer . plaintext
				} catch Error as e {
					FileAppend("[DEBUG] Erro decrypt: " e.Message "`n", A_ScriptDir "\debug.log")
					return
				}

				; Extrai e processa JSONs completos do buffer
				while (true) {
					nextJson := ExtractNextJsonFromBuffer()
					if (!nextJson)
						break
					try {
						ProcessarResposta(nextJson)
					} catch Error as e {
						FileAppend("[DEBUG] Erro ProcessarResposta: " e.Message "`nJSON:`n" nextJson "`n", A_ScriptDir "\debug.log")
					}
				}
			}
		}
	}

	/**
	 * Classe de criptografia VIAWEB
	 * Implementa AES-256-CBC usando BCrypt API do Windows
	 */
	class ViawebCrypto {
		hAlg := 0
		hKey := 0
		ivSend := Buffer(16)
		ivRecv := Buffer(16)
		blockSize := 16

		/**
		 * Inicializa algoritmo de criptografia AES-CBC
		 * @param {String} hexKey - Chave em formato hexadecimal
		 * @param {String} hexIV - IV em formato hexadecimal
		 */
		__New(hexKey, hexIV) {
			key := this.HexToBytes(hexKey)
			iv := this.HexToBytes(hexIV)
			
			; Copia IV para buffers de envio e recepção
			Loop 16 {
				NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivSend, A_Index-1)
				NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivRecv, A_Index-1)
			}

			; Abre provedor de algoritmo AES
			result := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &hAlg := 0, "WStr", "AES", "Ptr", 0, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptOpenAlgorithmProvider falhou: " Format("0x{:08X}", result))
			this.hAlg := hAlg

			; Configura modo de encadeamento CBC
			chainMode := Buffer(StrPut("ChainingModeCBC", "UTF-16") * 2)
			StrPut("ChainingModeCBC", chainMode, "UTF-16")

			result := DllCall("bcrypt\BCryptSetProperty", "Ptr", this.hAlg, "WStr", "ChainingMode", "Ptr", chainMode, "UInt", chainMode.Size, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptSetProperty falhou: " Format("0x{:08X}", result))

			; Gera chave simétrica
			result := DllCall("bcrypt\BCryptGenerateSymmetricKey", "Ptr", this.hAlg, "Ptr*", &hKey := 0, "Ptr", 0, "UInt", 0, "Ptr", key, "UInt", key.Size, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptGenerateSymmetricKey falhou: " Format("0x{:08X}", result))
			this.hKey := hKey
		}

		/**
		 * Limpa recursos de criptografia
		 */
		__Delete() {
			if (this.hKey)
				DllCall("bcrypt\BCryptDestroyKey", "Ptr", this.hKey)
			if (this.hAlg)
				DllCall("bcrypt\BCryptCloseAlgorithmProvider", "Ptr", this.hAlg, "UInt", 0)
		}

		/**
		 * Criptografa texto usando AES-CBC
		 * @param {String} plainText - Texto a criptografar
		 * @returns {Buffer} Buffer com dados criptografados
		 */
		Encrypt(plainText) {
			plainBytes := this.StringToBytes(plainText)
			paddedSize := Ceil(plainBytes.Size / 16) * 16
			if (paddedSize = 0)
				paddedSize := 16

			; Aplica padding com zeros
			paddedData := Buffer(paddedSize, 0)
			Loop plainBytes.Size
				NumPut("UChar", NumGet(plainBytes, A_Index-1, "UChar"), paddedData, A_Index-1)

			encrypted := Buffer(paddedSize)
			ivCopy := Buffer(16)
			Loop 16
				NumPut("UChar", NumGet(this.ivSend, A_Index-1, "UChar"), ivCopy, A_Index-1)

			bytesWritten := 0
			result := DllCall("bcrypt\BCryptEncrypt"
				, "Ptr", this.hKey
				, "Ptr", paddedData, "UInt", paddedSize
				, "Ptr", 0
				, "Ptr", ivCopy, "UInt", 16
				, "Ptr", encrypted, "UInt", encrypted.Size
				, "UInt*", &bytesWritten
				, "UInt", 0)
			if (result != 0)
				throw Error("BCryptEncrypt falhou: " Format("0x{:08X}", result))

			; Atualiza IV com último bloco cifrado (CBC mode)
			Loop 16
				NumPut("UChar", NumGet(encrypted, paddedSize-16 + A_Index-1, "UChar"), this.ivSend, A_Index-1)

			return encrypted
		}

		/**
		 * Descriptografa dados usando AES-CBC
		 * @param {Buffer} encryptedBuffer - Buffer com dados criptografados
		 * @returns {String} Texto descriptografado
		 */
		Decrypt(encryptedBuffer) {
			dataSize := encryptedBuffer.Size
			if (Mod(dataSize, 16) != 0)
				throw Error("Dados criptografados devem ter tamanho múltiplo de 16")

			; Salva último bloco para atualizar IV
			lastBlock := Buffer(16)
			Loop 16
				NumPut("UChar", NumGet(encryptedBuffer, dataSize-16 + A_Index-1, "UChar"), lastBlock, A_Index-1)

			decrypted := Buffer(dataSize)
			ivCopy := Buffer(16)
			Loop 16
				NumPut("UChar", NumGet(this.ivRecv, A_Index-1, "UChar"), ivCopy, A_Index-1)

			bytesWritten := 0
			result := DllCall("bcrypt\BCryptDecrypt"
				, "Ptr", this.hKey
				, "Ptr", encryptedBuffer, "UInt", dataSize
				, "Ptr", 0
				, "Ptr", ivCopy, "UInt", 16
				, "Ptr", decrypted, "UInt", decrypted.Size
				, "UInt*", &bytesWritten
				, "UInt", 0)
			if (result != 0)
				throw Error("BCryptDecrypt falhou: " Format("0x{:08X}", result))

			; Atualiza IV com último bloco cifrado (CBC mode)
			Loop 16
				NumPut("UChar", NumGet(lastBlock, A_Index-1, "UChar"), this.ivRecv, A_Index-1)

			; Remove padding de zeros
			endPos := bytesWritten
			while (endPos > 0 && NumGet(decrypted, endPos-1, "UChar") = 0)
				endPos--

			return StrGet(decrypted, endPos, "UTF-8")
		}

		/**
		 * Converte string hexadecimal para bytes
		 * @param {String} hexStr - String em formato hexadecimal
		 * @returns {Buffer} Buffer com bytes
		 */
		HexToBytes(hexStr) {
			hexStr := StrReplace(hexStr, " ", "")
			len := StrLen(hexStr) // 2
			buf := Buffer(len)
			Loop len {
				byte := "0x" SubStr(hexStr, (A_Index - 1) * 2 + 1, 2)
				NumPut("UChar", Integer(byte), buf, A_Index-1)
			}
			return buf
		}

		/**
		 * Converte string para bytes UTF-8
		 * @param {String} str - String a converter
		 * @returns {Buffer} Buffer com bytes UTF-8
		 */
		StringToBytes(str) {
			len := StrPut(str, "UTF-8") - 1
			buf := Buffer(len)
			StrPut(str, buf, "UTF-8")
			return buf
		}
	}

; ===================== FUNÇÕES AUXILIARES =====================

	/**
	 * Junta elementos de array em string separada
	 * @param {Array} arr - Array a processar
	 * @param {String} sep - Separador entre elementos
	 * @returns {String} String com elementos unidos
	 */
	JoinArray(arr, sep := ",") {
		out := ""
		i := 1
		Loop arr.Length {
			if (i > 1)
				out := out sep
			out := out arr[i]
			i++
		}
		return out
	}

	/**
	 * Combina dois buffers em um novo buffer
	 * @param {Buffer} b1 - Primeiro buffer
	 * @param {Buffer} b2 - Segundo buffer
	 * @returns {Buffer} Novo buffer combinado
	 */
	CombineBuffers(b1, b2) {
		newSize := b1.Size + b2.Size
		newBuf := Buffer(newSize)
		idx := 0
		if (b1.Size) {
			Loop b1.Size
				NumPut("UChar", NumGet(b1, A_Index-1, "UChar"), newBuf, idx++)
		}
		if (b2.Size) {
			Loop b2.Size
				NumPut("UChar", NumGet(b2, A_Index-1, "UChar"), newBuf, idx++)
		}
		return newBuf
	}

	/**
	 * Adiciona mensagem ao histórico com timestamp e cor
	 * @param {String} message - Mensagem a adicionar
	 * @param {String} color - Código de cor hexadecimal
	 */
	AddHistorico(message, color := "FFFFFF") {
		global historicoMensagens, guiHwnd, client
		timestamp := Format("{:02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
		historicoMensagens.InsertAt(1, {message: message, color: color, timestamp: timestamp})

		if (historicoMensagens.Length > MAX_HISTORICO)
			historicoMensagens.Pop()
		
		if (guiHwnd && client && IsObject(client))
			AtualizarGUI()
	}

	/**
	 * Processa resposta de status de partições
	 * @param {Object} resposta - Objeto JSON com dados da partição
	 */
	ProcessaParticoes(resposta) {
		Global particionesStatus
		armado := resposta['armado']
		disparado := resposta['disparado']
		particao := resposta['pos']
		particionesStatus[particao] := Map('armado', armado, 'disparado', disparado)
		AddHistorico("✅ Status da partição " particao " atualizado", CORES.SUCESSO)
	}

	/**
	 * Processa resposta de status de zonas/sensores
	 * @param {Object} resposta - Objeto JSON com dados do sensor
	 */
	ProcessaZonas(resposta) {
		Global zonasStatus
		aberta		:= resposta['aberta']
		batlow		:= resposta['batlow']
		disparada	:= resposta['disparada']
		inibida		:= resposta['inibida']
		pos			:= resposta['pos']
		tamper		:= resposta['tamper']
		temporizando:= resposta['temporizando']
		zonasStatus[pos] := Map('aberta', aberta, 'batlow', batlow, 'disparada', disparada, 'inibida', inibida, 'tamper', tamper, 'temporizando', temporizando)
		AddHistorico("✅ Status do sensor " pos " atualizado`r`n`tAberto: " aberta " | Disparado: " disparada " | Inibida: " inibida " | Tamper: " tamper " | Temporizando: " temporizando, CORES.SUCESSO)
	}

	/**
	 * Envia resposta de confirmação de evento
	 * @param {String} id - ID do evento a confirmar
	 */
	ResponderEvento(id) {
		global client
		respJson := '{"resp":[{"id":"' id '"}]}'
		client.Send(respJson)
	}

	/**
	 * Processa resposta JSON do servidor
	 * @param {String} jsonStr - String JSON a processar
	 */
	ProcessarResposta(jsonStr) {
		response := json.parse(jsonStr)
		if	IsSet(response) && isObject(response) {
			; Resposta de autenticação
			if(response.Has("a")) {
				AddHistorico("ℹ️ Autenticado.`tEventos pendentes: " (response.Has("eventosPendentes") ? response["eventosPendentes"] : "0"), CORES.INFO)
				return
			}

			Try resp := response['resp']
			Switch {
				Case IsSet(resp):
					TratarResp(resp)
				Default:
					TratarResp(response)
			}
		}
	}

	/**
	 * Trata respostas do servidor VIAWEB
	 * @param {Object} respObj - Objeto de resposta
	 */
	TratarResp(respObj) {
		global client
		for index, item in respObj {
			if(! item.HasProp('Capacity'))
				continue
			if(item.Capacity = 0)
				continue
			
			; Processa eventos que requerem confirmação
			if(respObj.Has("oper")) {
				if(InStr(respObj['oper'][1]['acao'], 'evento') && InStr(respObj['oper'][1]['id'], '-evento')) {
					ResponderEvento(respObj['oper'][1]['id'])
					continue
				}
				Loop respObj['oper'].Capacity
					for operIndex, operItem in respObj['oper'][A_Index] {
						OutputDebug(A_Now "`tOper " A_Index ": " operIndex " = " respObj['oper'][A_Index][operIndex])
					}
			}

			; Processa respostas de comandos
			if(item.Has("resposta")) {
				resposta := item['resposta']
				if(resposta.HasProp('Capacity'))
					Loop resposta.Length {
						if(resposta[A_Index].Has("cmd")) {
							cmd := resposta[A_Index]['cmd']
							if		(cmd = 'particoes') {
								ProcessaParticoes(resposta[A_Index])
							}
							else if	(cmd = 'zonas') {
								ProcessaZonas(resposta[A_Index])
							}
						}
					}
				ResponderEvento(item['id'])
			}
		}
	}

	/**
	 * Extrai próximo JSON completo do buffer de texto
	 * @returns {String} JSON completo ou string vazia se não houver
	 */
	ExtractNextJsonFromBuffer() {
		global recvPlainBuffer
		s := recvPlainBuffer
		if (!s)
			return ""

		; Encontra início do JSON
		start := 0
		len := StrLen(s)
		Loop len {
			ch := SubStr(s, A_Index, 1)
			if (ch = "{" || ch = "[") {
				start := A_Index
				break
			}
		}
		if (!start) {
			recvPlainBuffer := ""
			return ""
		}
		
		; Processa JSON verificando balanceamento de chaves/colchetes
		s := SubStr(s, start)
		len := StrLen(s)
		depth := 0
		inStr := false
		i := 0

		while (i < len) {
			i++
			ch := SubStr(s, i, 1)

			; Trata strings entre aspas
			if (ch = '"') {
				bs := 0, j := i-1
				while (j >= 1 && SubStr(s, j, 1) = "\") {
					bs++, j--
				}
				if (Mod(bs, 2) = 0)
					inStr := !inStr
				continue
			}
			if (inStr)
				continue

			; Conta profundidade de chaves/colchetes
			if (ch = "{" || ch = "[")
				depth++
			else if (ch = "}" || ch = "]") {
				depth--
				if (depth = 0) {
					candidate := SubStr(s, 1, i)
					try {
						_ := json.parse(candidate)
						recvPlainBuffer := SubStr(recvPlainBuffer, start + i)
						return candidate
					} catch Error as e {
						continue
					}
				}
			}
		}
		return ""
	}

	/**
	 * Timer de polling - verifica dados recebidos
	 */
	PollTimer() {
		global client
		if (client && IsObject(client) && client.connected) {
			try {
				client.Poll()
			} catch Error as e {
				FileAppend("[ERROR] PollTimer: " e.Message "`n", A_ScriptDir "\debug.log")
			}
		}
	}

	/**
	 * Obtém status formatado de um sensor
	 * @param {Number} numSensor - Número do sensor (1-32)
	 * @returns {Object} Objeto com texto e cor do status
	 */
	ObterStatusSensor(numSensor) {
		global zonasStatus, CORES
		
		if (! zonasStatus.Has(numSensor)) {
			return {
				texto: "Aguardando...",
				cor: CORES.FUNDO_NEUTRAL
			}
		}

		dados := zonasStatus[numSensor]
		
		; Prioridade de estados (do mais crítico ao menos crítico)
		if (dados["disparada"] = "1") {
			return {texto: "Disparado", cor: CORES.SENSOR_DISPARADO}
		} else if (dados["aberta"] = "1") {
			return {texto: "Aberto", cor: CORES.SENSOR_ABERTO}
		} else if (dados["tamper"] = "1") {
			return {texto: "Tamper", cor: CORES.SENSOR_TAMPER}
		} else if (dados["temporizando"] = "1") {
			return {texto: "Temporizado", cor: CORES.SENSOR_TEMPORIZADO}
		} else if (dados["inibida"] = "1") {
			return {texto: "Inibido", cor: CORES.SENSOR_INIBIDO}
		} else if (dados["batlow"] = "1") {
			return {texto: "Bateria Baixa", cor: CORES.SENSOR_BATLOW}
		} else {
			return {texto: "OK", cor: CORES.SENSOR_OK}
		}
	}

	/**
	 * Obtém status formatado de uma partição
	 * @param {Number} numParticao - Número da partição (1-8)
	 * @returns {Object} Objeto com dados de status da partição
	 */
	ObterStatusParticao(numParticao) {
		global particionesStatus, CORES
		
		if (! particionesStatus.Has(numParticao)) {
			return {
				armado: "0",
				disparado: "0",
				texto: "Aguardando...",
				emoji: "⏳",
				cor: CORES.INFO
			}
		}

		dados := particionesStatus[numParticao]
		armado := dados["armado"]
		disparado := dados["disparado"]

		; Prioridade: Disparada > Armada > Desarmada
		if (disparado = "1") {
			return {
				armado: armado,
				disparado: disparado,
				texto: "⚠️ DISPARADA",
				emoji: "🚨",
				cor: CORES.DISPARADA
			}
		} else if (armado = "1") {
			return {
				armado: armado,
				disparado: disparado,
				texto: "🔒 ARMADA",
				emoji: "🔐",
				cor: CORES.ARMADA
			}
		} else {
			return {
				armado: armado,
				disparado: disparado,
				texto: "🔓 DESARMADA",
				emoji: "🔓",
				cor: CORES.DESARMADA
			}
		}
	}

	/**
	 * Atualiza interface gráfica com status atual
	 * Otimizado para minimizar redesenhos desnecessários
	 */
	AtualizarGUI() {
		global guiHwnd, particionesStatus, historicoMensagens, ultimaAtualizacao, statusConexao, colorConexao, client
		global guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlHistorico, guiCtrlSensores

		if (!guiHwnd)
			return

		; Atualiza status de conexão
		if (!client || !IsObject(client)) {
			statusConexao := "🔴 DESCONECTADO"
			colorConexao := CORES.DESCONECTADO
			try guiCtrlStatusConexao.Text := statusConexao
			return
		}

		statusConexao := client.connected ? "🟢 CONECTADO" : "🔴 DESCONECTADO"
		colorConexao := client.connected ? CORES.CONECTADO : CORES.DESCONECTADO
		try guiCtrlStatusConexao.Text := statusConexao

		; Atualiza timestamp
		ultimaAtualizacao := Format("{:02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
		try guiCtrlTimestamp.Text := "Última atualização:`t" ultimaAtualizacao

		; Atualiza partições (desativa redraw para performance)
		Loop MAX_PARTICOES {
			status := ObterStatusParticao(A_Index)
			guiCtrlParticoes[A_Index].Opt("-Redraw")
			guiCtrlParticoes[A_Index].Text := "Partição " A_Index ": " status.texto
			guiCtrlParticoes[A_Index].Opt("+Background" status.cor)
		}

		; Atualiza sensores (desativa redraw para performance)
		Loop MAX_SENSORES {
			status := ObterStatusSensor(A_Index)
			guiCtrlSensores[A_Index].Opt("-Redraw")
			guiCtrlSensores[A_Index].Text := A_Index ": " status.texto
			guiCtrlSensores[A_Index].Opt("+Background" status.cor)
		}

		; Reativa redraw em batch
		Loop MAX_SENSORES {
			if(A_Index < 9)
				guiCtrlParticoes[A_Index].Opt("+Redraw")
			guiCtrlSensores[A_Index].Opt("+Redraw")
		}
	}

; ===================== INTERFACE GRÁFICA =====================

	/**
	 * Cria e configura a interface gráfica do monitor
	 */
	CriarGUI() {
		global guiHwnd, guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlSensores, guiCtrlHistorico, CORES
			, gunidades
		MyGui := Gui()
		guiHwnd := MyGui.Hwnd

		MyGui.BackColor := CORES.FUNDO_INTERFACE
		MyGui.SetFont("S12")
		
		; Cabeçalho
		MyGui.Add("Text", "x15 Center w410 h20 cFFFFFF Background" CORES.INFO " Section", "🛡️ VIAWEB MONITOR")
		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")
		
		; Status de conexão
		guiCtrlStatusConexao := MyGui.Add("Text", "Center w410 h20 c" CORES.CONECTADO " Background" CORES.FUNDO_NEUTRAL, "🔴 DESCONECTADO")
		MyGui.SetFont("S9")

		; Informações de conexão
		MyGui.Add("Text", "x15 w410", "Endereço:`t`t" IP ":" PORTA)

		; Seletor de unidade ISEP
		MyGui.Add("Text", "x15 w60 y+5", "ISEP:")
		guiCtrlISEP := MyGui.Add("ComboBox", "x80 yp-3 w100", gunidades)
		filter := ComboBoxFilter(guiCtrlISEP, gunidades, true, true)
		guiCtrlISEP.Text := ISEP_DEFAULT
		guiCtrlISEP.OnEvent("Change", ISEPChanged)

		; Timestamp da última atualização
		guiCtrlTimestamp := MyGui.Add("Text", "x15 w410 y+0", "Última atualização:`t00:00:00")
		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		; Grupo de controles
		btnCtrlGroup := MyGui.Add("GroupBox", "x15 w410 h60 Section c" CORES.TEXTO_GRUPO, "🎮 Controles de Central")
		MyGui.Add("Button", "x025 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.ARMADA, "🔒 Armar").OnEvent("Click", ArmarBtn)
		MyGui.Add("Button", "x125 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.DESARMADA, "🔓 Desarmar").OnEvent("Click", DesarmarBtn)
		MyGui.Add("Button", "x225 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.INFO, "📋 Status").OnEvent("Click", StatusBtn)
		MyGui.Add("Button", "x325 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.INFO, "🔄 Zonas").OnEvent("Click", ZonasBtn)

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		; Painel de partições
		MyGui.Add("GroupBox", "x15 y+10 w410 h165 Section c" CORES.TEXTO_GRUPO, "📊 Status das Partições ")
		Loop MAX_PARTICOES {
			guiCtrlParticoes.Push("")
			status := ObterStatusParticao(A_Index)
			guiCtrlParticoes[A_Index] := MyGui.Add("Text", "x20 ys+" (A_Index * 16) " w390 h16 c" CORES.TEXTO_CLARO " 0x1500 Background" status.cor, "Partição " A_Index ": " status.texto)
		}

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		; Painel de sensores
		MyGui.Add("GroupBox", "x15 y+10 w410 h180 Section c" CORES.TEXTO_GRUPO, "📡 Status dos Sensores")
		yBaseSensores := 555
		Loop MAX_SENSORES {
			coluna := Mod(A_Index - 1, 4)
			linha := (A_Index - 1) // 4
			xPos := 20 + (coluna * 100)
			status := ObterStatusSensor(A_Index)
			guiCtrlSensores.Push(MyGui.Add("Text", "x" xPos " ys+" ((linha+1) * 20) " w95 h18 c" CORES.TEXTO_CLARO " 0x1500 Background" status.cor, A_Index ": " status.texto))
		}

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		; Histórico de ações
		MyGui.Add("GroupBox", "x15 w410 h120 c" CORES.TEXTO_GRUPO " Section", "📜 Histórico de Ações:")
		guiCtrlHistorico := MyGui.Add("Edit", "ys+20 xs+10 w390 h90 ReadOnly Multi Background" CORES.FUNDO_NEUTRAL " c" CORES.TEXTO_ESCURO)

		; Valores iniciais
		guiCtrlStatusConexao.Value := "🔴 DESCONECTADO"
		guiCtrlTimestamp.Value := "Última atualização:`t00:00:00"
		guiCtrlHistorico.Value := "Sistema iniciado`nAguardando conexão..."

		MyGui.Show("x0 y0")
		MyGui.OnEvent("Close", GuiClose)
		MyGui.Title := "🛡️ VIAWEB Monitor - Dashboard de Monitoramento"
	}

	/**
	 * Handler de fechamento da GUI
	 */
	GuiClose(GuiObj) {
		global guiHwnd
		SetTimer(PollTimer, 0)
		SetTimer(AtualizarGUI, 0)
		guiHwnd := 0
		ExitApp()
	}

	/**
	 * Handler do botão Armar
	 */
	ArmarBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT, SENHA_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.Armar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message, CORES.ERRO)
		}
	}

	/**
	 * Handler do botão Desarmar
	 */
	DesarmarBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT, SENHA_DEFAULT
		if (!client || ! IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.Desarmar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message, CORES.ERRO)
		}
	}

	/**
	 * Handler do botão Status (consulta partições)
	 */
	StatusBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.StatusParticoes(RegExReplace(ISEP_DEFAULT, "\D"))
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message, CORES.ERRO)
		}
	}

	/**
	 * Handler do botão Zonas (consulta sensores)
	 */
	ZonasBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.StatusZonas(ISEP_DEFAULT)
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message, CORES.ERRO)
		}
	}

	/**
	 * Handler de mudança de unidade ISEP
	 */
	ISEPChanged(GuiCtrlObj, Info) {
		global ISEP_DEFAULT
		idClean := RegExReplace(GuiCtrlObj.Text, "\D")
		ISEP_DEFAULT := Format('{:04}', idClean)
		AddHistorico("📝 ISEP alterado para: " ISEP_DEFAULT, CORES.INFO)
	}
; ===================== INICIALIZAÇÃO ======================

	/**
	 * Inicialização do sistema
	 * Cria GUI, conecta ao servidor e inicia timers
	 */
	try {
		; Cria interface gráfica
		CriarGUI()
		
		; Inicializa cliente VIAWEB
		client := ViawebClient(IP, PORTA, CHAVE, IV)
		client.Connect()
		
		AddHistorico("✅ Conectado em " IP ":" PORTA, CORES.SUCESSO)
		
		; Envia identificação ao servidor
		client.Identificar("AHK Monitor GUI")
		AddHistorico("🔐 Identificação enviada", CORES.INFO)
		
		; Inicia timers de polling e atualização de GUI
		SetTimer(PollTimer, POLL_INTERVAL_MS)
		SetTimer(AtualizarGUI, GUI_UPDATE_MS)
		
	} catch Error as e {
		AddHistorico("❌ Erro na inicialização: " e.Message, CORES.ERRO)
		MsgBox("Erro: " e.Message, "VIAWEB Monitor", "Icon!")
	}

; ===================== HOTKEYS =====================

	/**
	 * F3 - Consulta status das partições
	 */
	F3:: {
		StatusBtn(0, 0)
	}

	/**
	 * F4 - Consulta status das zonas/sensores
	 */
	F4:: {
		ZonasBtn(0, 0)
	}

	/**
	 * F1 - Arma partição 1
	 */
	F1:: {
		ArmarBtn(0, 0)
	}

	/**
	 * F2 - Desarma partição 1
	 */
	F2:: {
		DesarmarBtn(0, 0)
	}

; ===================== EXIT ======================

	/**
	 * Handler de encerramento do script
	 * Limpa recursos e desconecta do servidor
	 */
	Shutdown(ExitReason, ExitCode) {
		global client
		SetTimer(PollTimer, 0)
		SetTimer(AtualizarGUI, 0)
		if (IsSet(client) && IsObject(client) && client.connected)
			client.Disconnect()
	}
	OnExit(Shutdown)