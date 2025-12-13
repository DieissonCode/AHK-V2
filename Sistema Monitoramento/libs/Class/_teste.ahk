;Save_To_Sql=1
;Keep_Versions=5
;@Ahk2Exe-Let U_FileVersion = 0.0.5.1
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Viaweb
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\switch_collumn.ico

#Requires AutoHotkey v2.0
#Warn All, off
#SingleInstance Force

#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Functions.ahk
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\ComboBoxFilter.ahk
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Json.ahk
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Unicode.ahk

Persistent

; ===================== CONFIGURAÇÃO =====================
	IP := "10.0.20.43"
	PORTA := 2700
	CHAVE := "94EF1C592113E8D27F5BB4C5D278BF3764292CEA895772198BA9435C8E9B97FD"
	IV := "70FC01AA8FCA3900E384EA28A5B7BCEF"

	SENHA_DEFAULT := "8790"

	POLL_INTERVAL_MS := 500
	GUI_UPDATE_MS := 1000

; ===================== CONSTANTES DE CORES =====================
	CORES := {
		ARMADA: 				"00AA00",
		DESARMADA:			"FFAA00",
		DISPARADA:			"FF0000",
		CONECTADO:			"00FF00",
		DESCONECTADO: 		"FF0000",
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
		SENSOR_TEMPORIZADO: 	"FF8C00",
		SENSOR_INIBIDO:		"87CEEB",
		SENSOR_BATLOW:		"FF69B4",
		SENSOR_OK:			"00AA00"
	}

; ===================== VARIÁVEIS GLOBAIS =====================
	; Variáveis principais
		global client := 0
		global particionesStatus := Map()
		global zonasStatus := Map()
		global historicoMensagens := []
		global ultimaAtualizacao := ""
		global statusConexao := "Desconectado"
		global colorConexao := CORES.DESCONECTADO
		global guiHwnd := 0
		global gunidades := CarregarUnidadesDb()
		global lastZonasUpdateTick := 0
		global clientesMap := Map()

	; Controles de GUI
		global guiCtrlISEP := 0
		global guiCtrlStatusConexao := 0
		global guiCtrlTimestamp := 0
		global guiCtrlParticoes := []
		global guiCtrlParticoesText := 0
		global guiCtrlSensores := []
		global guiCtrlHistorico := 0
		global guiCtrlClienteSelecionado := 0

	; Variáveis para ListView
		global historicoMaxLinhas := 100  ; Máximo de linhas a manter
		global historicoContador := 0	 ; Contador para ID das linhas

	; Buffers para recepção
		global recvEncryptedAccum := Buffer(0)   ; acumula ciphertext entre recvs
		global recvPlainBuffer	:= ""		  ; acumula plaintext (JSON não processado)

; ===================== CLASSES =====================

	; Classe base com os comandos do protocolo VIAWEB
	class Viaweb {

		static Version := "0.0.2"
		commandId := 0
		static GetVersion() {
			return this.Version
		}

		Send(jsonStr) {
			throw Error("Send must be implemented by subclass - ViawebClient")
		}

		GetCommandId() {
			this.commandId++
			return SubStr(SysGetIPAddresses()[1], -3) this.commandId
		}

		Identificar(nome := "AHK Monitor") {
			identJson := '{"a":' Random(1, 999999) ',"oper":[{"acao":"ident","nome":"' nome '"},{"acao":"salvarVIAWEB","operacao": 2,"monitoramento":1}]}'
			OutputDebug('→ ' identJson)
			this.Send(identJson)
		}

		Armar(idISEP, senha, particoes, forcado := 0) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			if (Type(particoes) != "Array")
				particoes := [particoes]
			particoesStr := "[" JoinArray(particoes, ",") "]"
			cmdObj := '{"oper":[{"id": ' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"armar","password":"' senha '","forcado":' forcado ',"particoes":' particoesStr '}]}]}'
			OutputDebug('→ ' cmdObj)
			this.Send(cmdObj)
			AddHistorico("🔒 Armar:  " JoinArray(particoes, ","), CORES.ARMADA)
			this.StatusParticoes(idISEP)
		}

		Desarmar(idISEP, senha, particoes) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			if (Type(particoes) != "Array")
				particoes := [particoes]
			particoesStr := "[" JoinArray(particoes, ",") "]"
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"desarmar","password":"' senha '","particoes":' particoesStr '}]}]}'
			OutputDebug('→ ' cmdObj)
			this.Send(cmdObj)
			AddHistorico("🔓 Desarmar: " JoinArray(particoes, ","), CORES.DESARMADA)
			this.StatusParticoes(idISEP)
		}

		StatusParticoes(idISEP) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"particoes"}]}]}'
			OutputDebug('→ ' cmdObj)
			this.Send(cmdObj)
			AddHistorico("📋 Consultando partições...`r`n`t`tcmdId:  " cmdId "`r`n`t`tIdIsep: " idClean, CORES.INFO)
			this.StatusZonas(idISEP)
		}

		StatusZonas(idISEP) {
			idClean := RegExReplace(idISEP, "\D")
			if (idClean = "")
				idClean := idISEP
			cmdId := this.GetCommandId()
			cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idClean '","comando":[{"cmd":"zonas"}]}]}'
			OutputDebug('→ ' cmdObj)
			this.Send(cmdObj)
			AddHistorico("📋 Consultando zonas...`r`n`t`tcmdId: " cmdId "`r`n`t`tIdIsep: " idClean, CORES.INFO)
		}

		ListarClientes(portas := "", nomes := "", idISEPs := "") {
			cmdId := this.GetCommandId()

			oper := Map()
			oper["id"]   := cmdId
			oper["acao"] := "listarClientes"

			if (portas != "") {
				if (Type(portas) != "Array")
					portas := [portas]
				oper["porta"] := portas
			}

			if (nomes != "") {
				if (Type(nomes) != "Array")
					nomes := [nomes]
				oper["nome"] := nomes
			}

			if (idISEPs != "") {
				if (Type(idISEPs) != "Array")
					idISEPs := [idISEPs]
				oper["idISEP"] := idISEPs
			}

			payload := Map("oper", [oper])
			jsonStr := (StrReplace(JSON.stringify(payload, , ""), '`n', ' '))

			OutputDebug('→ ' jsonStr)
			this.Send(jsonStr)

			AddHistorico("📋 Listar clientes enviado.`r`n`t`tcmdId: " cmdId, CORES.INFO)

		}
	}

	; Cliente:  gerencia socket/cripto e herda os comandos do protocolo
	class ViawebClient extends Viaweb {
		socket := 0
		crypto := 0
		connected := false
		recvBuffer := Buffer(65536)
		commandId := 0
		hwnd := 0

		static Version := "0.1.1"

		static GetVersion() {
			return this.Version
		}

		__New(ip, port, hexKey, hexIV) {
			this.ip := ip
			this.port := port
			this.crypto := ViawebCrypto(hexKey, hexIV)
		}

		Connect() {
			wsaData := Buffer(408)
			if DllCall("ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData)
				throw Error("WSAStartup falhou")

			this.socket := DllCall("ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "Ptr")
			if (this.socket = -1)
				throw Error("Falha ao criar socket")

			hostent := DllCall("ws2_32\gethostbyname", "AStr", this.ip, "Ptr")
			if (!  hostent)
				throw Error("Falha ao resolver hostname")

			addrList := NumGet(hostent + (A_PtrSize = 8 ? 24 : 12), "Ptr")
			addr := NumGet(addrList, "Ptr")
			ipAddr := NumGet(addr, "UInt")

			sockAddr := Buffer(16, 0)
			NumPut("Short", 2, sockAddr, 0)
			NumPut("UShort", DllCall("ws2_32\htons", "UShort", this.port, "UShort"), sockAddr, 2)
			NumPut("UInt", ipAddr, sockAddr, 4)

			result := DllCall("ws2_32\connect", "Ptr", this.socket, "Ptr", sockAddr, "Int", 16, "Int")
			if (result = -1)
				throw Error("Falha ao conectar:  " DllCall("ws2_32\WSAGetLastError", "Int"))

			modeBuf := Buffer(4)
			NumPut("UInt", 1, modeBuf, 0) ; 1 = non-blocking
			res := DllCall("ws2_32\ioctlsocket", "Ptr", this.socket, "UInt", 0x8004667E, "Ptr", modeBuf)
			if (res != 0) {
				err := DllCall("ws2_32\WSAGetLastError", "Int")
				DllCall("ws2_32\closesocket", "Ptr", this.socket)
				this.socket := 0
				throw Error("ioctlsocket falhou: " err)
			}

			this.connected := true
			FileAppend("[DEBUG] Socket:  " this.socket " conectado (NON-BLOCKING)`n", A_ScriptDir "\debug.log")
			return true
		}

		Disconnect() {
			if (this.socket) {
				DllCall("ws2_32\closesocket", "Ptr", this.socket)
				DllCall("ws2_32\WSACleanup")
				this.socket := 0
				this.connected := false
			}
		}

		Send(jsonStr) {
			if (!this.connected)
				throw Error("Não conectado")

			encrypted := this.crypto.Encrypt(jsonStr)
			result := DllCall("ws2_32\send", "Ptr", this.socket, "Ptr", encrypted, "Int", encrypted.Size, "Int", 0, "Int")
			if (result = -1)
				throw Error("Falha ao enviar: " DllCall("ws2_32\WSAGetLastError", "Int"))
			return result
		}

		Poll() {
			if (!this.connected)
				return
			ListLines(0)
			Loop {
				recvBuf := Buffer(65536)
				received := DllCall("ws2_32\recv", "Ptr", this.socket, "Ptr", recvBuf, "Int", recvBuf.Size, "Int", 0, "Int")
				if (received < 0) {
					err := DllCall("ws2_32\WSAGetLastError", "Int")
					if (err = 10035)
						break
					FileAppend("[DEBUG] WSA Error: " err "`n", A_ScriptDir "\debug.log")
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

				chunk := Buffer(received)
				Loop received
					NumPut("UChar", NumGet(recvBuf, A_Index-1, "UChar"), chunk, A_Index-1)

				global recvEncryptedAccum
				recvEncryptedAccum := CombineBuffers(recvEncryptedAccum, chunk)
			}
			ListLines(1)

			global recvEncryptedAccum, recvPlainBuffer
			if (! recvEncryptedAccum.Size)
				return

			fullBlocksBytes := Floor(recvEncryptedAccum.Size / 16) * 16
			if (fullBlocksBytes > 0) {
				procBuf := Buffer(fullBlocksBytes)
				ListLines(0)
				Loop fullBlocksBytes
					NumPut("UChar", NumGet(recvEncryptedAccum, A_Index-1, "UChar"), procBuf, A_Index-1)
					ListLines(1)
				leftoverSize := recvEncryptedAccum.Size - fullBlocksBytes
				if (leftoverSize > 0) {
					leftover := Buffer(leftoverSize)
					ListLines(0)
					Loop leftoverSize
						NumPut("UChar", NumGet(recvEncryptedAccum, fullBlocksBytes + A_Index-1, "UChar"), leftover, A_Index-1)
					ListLines(1)
					recvEncryptedAccum := leftover
				} else {
					recvEncryptedAccum := Buffer(0)
				}

				try {
					plaintext := this.crypto.Decrypt(procBuf)
					recvPlainBuffer := recvPlainBuffer . plaintext
				} catch Error as e {
					FileAppend("[DEBUG] Erro decrypt: " e.Message "`t" e.Extra "`t" e.Line "`n", A_ScriptDir "\debug.log")
					MsgBox("Erro ao descriptografar dados recebidos: " e.Message)
					return
				}
				ListLines(0)
				while (true) {
					nextJson := ExtractNextJsonFromBuffer()
					if (!nextJson)
						break
					try {
						ProcessarResposta(UnicodeHelper.Decode(nextJson))
						OutputDebug( '← ' UnicodeHelper.Decode(nextJson))
					} catch Error as e {
						FileAppend("[DEBUG] Erro ProcessarResposta: " e.Message "`nJSON:`n" UnicodeHelper.Decode(nextJson) "`n", A_ScriptDir "\debug.log")
					}
				}
				ListLines(1)
			}
		}
	}

	; Classe de criptografia via Bcrypt (AES CBC)
	class ViawebCrypto {
		hAlg := 0
		hKey := 0
		ivSend := Buffer(16)
		ivRecv := Buffer(16)
		blockSize := 16

		static Version := "0.0.1"

		static GetVersion() {
			return this.Version
		}

		__New(hexKey, hexIV) {
			key := this.HexToBytes(hexKey)
			iv := this.HexToBytes(hexIV)
			Loop 16 {
				NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivSend, A_Index-1)
				NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivRecv, A_Index-1)
			}

			result := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &hAlg := 0, "WStr", "AES", "Ptr", 0, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptOpenAlgorithmProvider falhou:  " Format("0x{:08X}", result))
			this.hAlg := hAlg

			chainMode := Buffer(StrPut("ChainingModeCBC", "UTF-16") * 2)
			StrPut("ChainingModeCBC", chainMode, "UTF-16")

			result := DllCall("bcrypt\BCryptSetProperty", "Ptr", this.hAlg, "WStr", "ChainingMode", "Ptr", chainMode, "UInt", chainMode.Size, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptSetProperty falhou: " Format("0x{: 08X}", result))

			result := DllCall("bcrypt\BCryptGenerateSymmetricKey", "Ptr", this.hAlg, "Ptr*", &hKey := 0, "Ptr", 0, "UInt", 0, "Ptr", key, "UInt", key.Size, "UInt", 0, "UInt")
			if (result != 0)
				throw Error("BCryptGenerateSymmetricKey falhou: " Format("0x{:08X}", result))
			this.hKey := hKey
		}

		__Delete() {
			if (this.hKey)
				DllCall("bcrypt\BCryptDestroyKey", "Ptr", this.hKey)
			if (this.hAlg)
				DllCall("bcrypt\BCryptCloseAlgorithmProvider", "Ptr", this.hAlg, "UInt", 0)
		}

		Encrypt(plainText) {
			plainBytes := this.StringToBytes(plainText)
			paddedSize := Ceil(plainBytes.Size / 16) * 16
			if (paddedSize = 0)
				paddedSize := 16

			paddedData := Buffer(paddedSize, 0)
			ListLines(0)
			Loop plainBytes.Size
				NumPut("UChar", NumGet(plainBytes, A_Index-1, "UChar"), paddedData, A_Index-1)
			ListLines(1)
			encrypted := Buffer(paddedSize)
			ivCopy := Buffer(16)
			ListLines(0)
			Loop 16
				NumPut("UChar", NumGet(this.ivSend, A_Index-1, "UChar"), ivCopy, A_Index-1)
			ListLines(1)
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
				throw Error("BCryptEncrypt falhou:  " Format("0x{:08X}", result))
			ListLines(0)
			Loop 16
				NumPut("UChar", NumGet(encrypted, paddedSize-16 + A_Index-1, "UChar"), this.ivSend, A_Index-1)
			ListLines(1)
			return encrypted
		}

		Decrypt(encryptedBuffer) {
			dataSize := encryptedBuffer.Size
			if (Mod(dataSize, 16) != 0)
				throw Error("Dados criptografados devem ter tamanho múltiplo de 16")

			lastBlock := Buffer(16)
			ListLines(0)
			Loop 16
				NumPut("UChar", NumGet(encryptedBuffer, dataSize-16 + A_Index-1, "UChar"), lastBlock, A_Index-1)
			ListLines(1)
			decrypted := Buffer(dataSize)
			ivCopy := Buffer(16)
			ListLines(0)
			Loop 16
				NumPut("UChar", NumGet(this.ivRecv, A_Index-1, "UChar"), ivCopy, A_Index-1)
			ListLines(1)
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
				throw Error("BCryptDecrypt falhou:  " Format("0x{:08X}", result))
			ListLines(0)
			Loop 16
				NumPut("UChar", NumGet(lastBlock, A_Index-1, "UChar"), this.ivRecv, A_Index-1)
			ListLines(1)

			endPos := bytesWritten
			while (endPos > 0 && NumGet(decrypted, endPos-1, "UChar") = 0)
				endPos--

			return StrGet(decrypted, endPos, "UTF-8")
		}

		HexToBytes(hexStr) {
			hexStr := StrReplace(hexStr, " ", "")
			len := StrLen(hexStr) // 2
			buf := Buffer(len)
			ListLines(0)
			Loop len {
				byte := "0x" SubStr(hexStr, (A_Index - 1) * 2 + 1, 2)
				NumPut("UChar", Integer(byte), buf, A_Index-1)
			}
			ListLines(1)
			return buf
		}

		StringToBytes(str) {
			len := StrPut(str, "UTF-8") - 1
			buf := Buffer(len)
			StrPut(str, buf, "UTF-8")
			return buf
		}
	}

; ===================== FUNÇÕES AUXILIARES =====================

	JoinArray(arr, sep := ",") {
		out := ""
		i := 1
		ListLines(0)
		Loop arr.Length {
			if (i > 1)
				out := out sep
			out := out arr[i]
			i++
		}
		ListLines(1)
		return out
	}

	CombineBuffers(b1, b2) {
		newSize := b1.Size + b2.Size
		newBuf := Buffer(newSize)
		idx := 0
		if (b1.Size) {
			ListLines(0)
			Loop b1.Size
				NumPut("UChar", NumGet(b1, A_Index-1, "UChar"), newBuf, idx++)
			ListLines(1)
		}
		if (b2.Size) {
			ListLines(0)
			Loop b2.Size
				NumPut("UChar", NumGet(b2, A_Index-1, "UChar"), newBuf, idx++)
			ListLines(1)
		}
		return newBuf
	}

	; ===================== FUNÇÃO PARA EXTRAIR TIPO DE MENSAGEM =====================
	ExtrairTipoMensagem(message) {
		if (InStr(message, "✅"))
			return "✅ Sucesso"
		else if (InStr(message, "❌"))
			return "❌ Erro"
		else if (InStr(message, "⚠️"))
			return "⚠️ Aviso"
		else if (InStr(message, "ℹ️"))
			return "ℹ️ Info"
		else if (InStr(message, "📋"))
			return "📋 Consulta"
		else if (InStr(message, "🔒"))
			return "🔒 Armar"
		else if (InStr(message, "🔓"))
			return "🔓 Desarmar"
		else if (InStr(message, "🔐"))
			return "🔐 Seg."
		else if (InStr(message, "🔄"))
			return "🔄 Refresh"
		else if (InStr(message, "📡"))
			return "📡 Rede"
		else
			return "ℹ️ Outro"
	}

	; ===================== FUNÇÃO PARA ATUALIZAR LISTVIEW =====================
	AtualizarListViewHistorico() {
		global guiCtrlHistorico, historicoMensagens
		if (!guiCtrlHistorico)
			return

		WM_SETREDRAW := 0x0B
		SendMessage(WM_SETREDRAW, 0, 0, guiCtrlHistorico.Hwnd)  ; pausa redraw

		guiCtrlHistorico.Delete()
		Loop historicoMensagens.Length {
			item := historicoMensagens[A_Index]
			msg := item.message
			if (StrLen(msg) > 100)
				msg := SubStr(msg, 1, 97) "..."
			msg := StrReplace(msg, "`r`n", " | ")
			msg := StrReplace(msg, "`n", " | ")
			guiCtrlHistorico.Add(, item.timestamp, item.tipo, msg)
		}

		SendMessage(WM_SETREDRAW, 1, 0, guiCtrlHistorico.Hwnd)  ; retoma redraw
		DllCall("user32\RedrawWindow", "ptr", guiCtrlHistorico.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x105) ; RDW_INVALIDATE|RDW_UPDATENOW

		if (guiCtrlHistorico.GetCount() > 0)
			guiCtrlHistorico.Modify(1, "Vis")
	}

	AddHistorico(message, color := "FFFFFF") {
		global historicoMensagens, guiHwnd, guiCtrlHistorico, client, historicoMaxLinhas
		
		timestamp := Format("{: 02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
		
		; Extrai tipo de mensagem baseado em emojis/padrões
		tipo := ExtrairTipoMensagem(message)
		
		; Armazena no array global
		historicoMensagens.InsertAt(1, {
			message: message, 
			color: color, 
			timestamp: timestamp,
			tipo: tipo
		})
		
		; Mantém apenas as últimas N mensagens na memória
		if (historicoMensagens.Length > historicoMaxLinhas)
			historicoMensagens.Pop()
		
		; Atualiza a ListView se GUI está ativa
		if (guiHwnd && guiCtrlHistorico && client && IsObject(client))
			AtualizarListViewHistorico()
	}

	; ===================== EVENTO:  DUPLO CLIQUE NA LISTVIEW =====================
	HistoricoDoubleClick(GuiCtrlObj, Item) {
		global historicoMensagens
		
		if (Item = 0)
			return
		
		; Item começa em 1, array também
		if (Item <= historicoMensagens.Length) {
			msgCompleta := historicoMensagens[Item].message
			MsgBox(msgCompleta, "Mensagem Completa", "")
		}
	}

	; ===================== EVENTO: BOTÃO DIREITO NA LISTVIEW =====================
	HistoricoContextMenu(GuiCtrlObj, Item, IsRightClick := False, X := 0, Y := 0) {
		global historicoMensagens
		
		if (Item = 0)
			return
		
		; Cria menu de contexto
		MyContextMenu := Menu()
		MyContextMenu.Add("Copiar", MenuAcaoHistorico)
		MyContextMenu.Add("Limpar Histórico", MenuAcaoHistorico)
		MyContextMenu.Show()
	}

	; ===================== CALLBACK DO MENU DE CONTEXTO =====================
	MenuAcaoHistorico(ItemName, ItemID, MenuName) {
		global historicoMensagens, guiCtrlHistorico
		
		if (ItemName = "Copiar") {
			; Copia o texto selecionado
			linha := guiCtrlHistorico.GetNext()
			if (linha > 0 && linha <= historicoMensagens.Length) {
				item := historicoMensagens[linha]
				A_Clipboard := item.timestamp " | " item.tipo " | " item.message
				MsgBox("Copiado para área de transferência!", "Sucesso", "")
			}
		}
		else if (ItemName = "Limpar Histórico") {
			if (MsgBox("Deseja limpar todo o histórico?", "Confirmar", "YesNo") = "Yes") {
				global historicoMensagens
				historicoMensagens := []
				AtualizarListViewHistorico()
				MsgBox("Histórico limpo!", "Sucesso", "")
			}
		}
	}

	ProcessaParticoes(resposta) {
		Global particionesStatus
		armado := resposta['armado']
		disparado := resposta['disparado']
		particao := resposta['pos']
		particionesStatus[particao] := Map('armado', armado, 'disparado', disparado)
		AddHistorico("✅ Status da partição " particao " atualizado", CORES.SUCESSO)
	}

	ProcessaZonas(resposta) {
		Global zonasStatus, CORES, lastZonasUpdateTick
		aberta		:= resposta['aberta']
		batlow		:= resposta['batlow']
		disparada	:= resposta['disparada']
		inibida		:= resposta['inibida']
		pos			:= resposta['pos']
		tamper		:= resposta['tamper']
		temporizando:= resposta['temporizando']
		zonasStatus[pos] := Map('aberta', aberta, 'batlow', batlow, 'disparada', disparada, 'inibida', inibida, 'tamper', tamper, 'temporizando', temporizando)
		lastZonasUpdateTick := A_TickCount
		AddHistorico("✅ Status do sensor " pos " atualizado`r`n`tAberto:`t`t" aberta "`r`n`tDisparado:`t" disparada "`r`n`tInibida:`t`t" inibida "`r`n`tTamper:`t`t" tamper "`r`n`tTemporizando:`t" temporizando, CORES.SUCESSO)
	}

	EnsureZonas(currIsep, tries := 3) {
		global client, ISEP_DEFAULT, lastZonasUpdateTick
		if (!client || !IsObject(client) || !client.connected)
			return
		if (ISEP_DEFAULT != currIsep)
			return
		if (tries <= 0)
			return  ; parou de tentar

		; se não atualizou há >1s, reenvia e agenda nova tentativa
		if ((A_TickCount - lastZonasUpdateTick) > 1000) {
			try client.StatusZonas(currIsep)
			SetTimer(() => EnsureZonas(currIsep, tries - 1), -1000)
		}
		; se já atualizou há <=1s, não faz nada (já está “fresco”)
	}

	ResponderEvento(id) {
		global client
		respJson := '{"resp":[{"id":"' id '"}]}'
		client.Send(respJson)
	}

	ProcessarResposta(jsonStr) {
		response := json.parse(jsonStr)
		if	IsSet(response) && isObject(response) {
			if(response.Has("a")) {
				AddHistorico("ℹ️ Autenticado.`r`n`t`tEventos pendentes:  " (response.Has("eventosPendentes") ? response["eventosPendentes"] : "0"), CORES.INFO)
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

	ProcessaListarClientes(respItem) {
		global clientesMap
		clientesMap.Clear()
		if (!respItem.Has("viaweb"))
			return

		for vw in respItem["viaweb"] {
			servidorNome  := vw.Has("nome")  ? vw["nome"]  : ""
			servidorPorta := vw.Has("porta") ? vw["porta"] : ""

			if (vw.Has("cliente")) {
				for cli in vw["cliente"] {
					try {
						id := cli.Has("idISEP") ? cli["idISEP"] : ""
						if (id = "")
							continue

						; senhas:  até 3 na ordem recebida
						pwd1 := "", pwd2 := "", pwd3 := ""
						pwd1Gen := "", pwd2Gen := "", pwd3Gen := ""
						if (cli.Has("senhas") && Type(cli["senhas"]) = "Array") {
							idx := 1
							for s in cli["senhas"] {
								if (idx = 1) {
									pwd1	:= s.Has("senha")   ? s["senha"]   : ""
									pwd1Gen := s.Has("geracao") ? s["geracao"] : ""
								} else if (idx = 2) {
									pwd2	:= s.Has("senha")   ? s["senha"]   : ""
									pwd2Gen := s.Has("geracao") ? s["geracao"] : ""
								} else if (idx = 3) {
									pwd3	:= s.Has("senha")   ? s["senha"]   : ""
									pwd3Gen := s.Has("geracao") ? s["geracao"] : ""
								} else {
									break
								}
								idx++
							}
						}

						; meio:  pega o primeiro, se existir
						offlineTypical := "", authorization := "", onlineTs := "", offlineTs := ""
						protection := "", delay := "", ping := "", ip := ""
						if (cli.Has("meio") && Type(cli["meio"]) = "Array" && cli["meio"].Length >= 1) {
							m := cli["meio"][1]
							offlineTypical := m.Has("offlineTipico") ? m["offlineTipico"] : ""
							authorization  := m.Has("autorizacao")   ? m["autorizacao"]   : ""
							onlineTs	   := m.Has("online")		? m["online"]		: ""
							offlineTs	  := m.Has("offline")	   ? m["offline"]	   : ""
							protection	 := m.Has("protecao")	  ? m["protecao"]	  : ""
							delay		  := m.Has("atraso")		? m["atraso"]		: ""
							ping		   := m.Has("ping")		  ? m["ping"]		  : ""
							ip			 := m.Has("ip")			? m["ip"]			: ""
						}

						onlineFlag := cli.Has("online") ? cli["online"] : ""

						clientesMap[id] := Map()
						clientesMap[id].password1 := pwd1
						clientesMap[id].password2 := pwd2
						clientesMap[id].password3 := pwd3
						clientesMap[id].password1Generated := StrReplace(pwd1Gen, '\', '')
						clientesMap[id].password2Generated := StrReplace(pwd2Gen, '\', '')
						clientesMap[id].password3Generated := StrReplace(pwd3Gen, '\', '')
						clientesMap[id].offlineTypical := offlineTypical
						clientesMap[id].authorization := authorization
						clientesMap[id].onlineTimestamp  := (onlineTs  = "" ? "" : UnixToDateTime(onlineTs))
						clientesMap[id].offlineTimestamp := (offlineTs = "" ? "" : UnixToDateTime(offlineTs))
						clientesMap[id].protection := protection
						clientesMap[id].delay := delay
						clientesMap[id].ping := ping
						clientesMap[id].ip := ip
						clientesMap[id].online := onlineFlag

					} catch Error as e {
						AddHistorico("❌ Erro ao processar cliente: " (cli.Has("idISEP") ? cli["idISEP"] : "? ") "`r`n`t" e.Message "`r`n`tLine: " e.Line, CORES.ERRO)
						continue
					}
				}
			}
			total := vw.Has("cliente") ? vw["cliente"].Length : 0
			AddHistorico("📋 Clientes armazenados: " total, CORES.INFO)
		}
	}

	TratarResp(respObj) {
		global client
		for index, item in respObj {
			if(!  item.HasProp('Capacity'))
				continue
			if(item.Capacity = 0)
				continue

			; Tratamento de erros retornados em "resp"
			if(item.Has("erro")) {
				errCode := item["erro"]
				desc	:= item.Has("descricao") ? item["descricao"] : "Erro"
				idStr   := item.Has("id") ? item["id"] : ""
				p1	  := item.Has("param1") ? item["param1"] : ""
				p2	  := item.Has("param2") ? item["param2"] : ""

				message := "❌ Erro (id: " idStr "): [" errCode "] " desc
				if (p1 != "")
					message .= "`r`n`tparam1: " p1
				if (p2 != "")
					message .= "`r`n`tparam2: " p2
				AddHistorico(message, CORES.ERRO)
				continue
			}

			; Tratamento de listarClientes (viaweb -> cliente)
			if(item.Has("viaweb")) {
				ProcessaListarClientes(item)
				continue
			}

			if(respObj.Has("oper")) {
				if(InStr(respObj['oper'][1]['acao'], 'evento') && InStr(respObj['oper'][1]['id'], '-evento')) {
					ResponderEvento(respObj['oper'][1]['id'])
					continue
				}
				ListLines(0)
				Loop respObj['oper'].Capacity
					for operIndex, operItem in respObj['oper'][A_Index] {
						OutputDebug(A_Now "`tOper " A_Index ":  " operIndex " = " respObj['oper'][A_Index][operIndex])
					}
				ListLines(1)
			}

			if(item.Has("resposta")) {
				resposta := item['resposta']
				if(resposta.HasProp('Capacity'))	{
					ListLines(0)
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
					ListLines(1)
				}
				ResponderEvento(item['id'])
			}
		}
	}

	ExtractNextJsonFromBuffer() {
		global recvPlainBuffer
		s := recvPlainBuffer
		if (! s)
			return ""

		start := 0
		len := StrLen(s)
		ListLines(0)
		Loop len {
			ch := SubStr(s, A_Index, 1)
			if (ch = "{" || ch = "[") {
				start := A_Index
				break
			}
		}
		ListLines(1)
		if (! start) {
			recvPlainBuffer := ""
			return ""
		}
		s := SubStr(s, start)
		len := StrLen(s)
		depth := 0
		inStr := false
		i := 0
		ListLines(0)
		while (i < len) {
			i++
			ch := SubStr(s, i, 1)

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
		ListLines(1)
		return ""
	}

	PollTimer() {
		global client
		if (client && IsObject(client) && client.connected) {
			client.Poll()
		}
	}

	ObterStatusSensor(numSensor) {
		global zonasStatus, CORES
		
		if (!  zonasStatus.Has(numSensor)) {
			return {
				texto:  "Aguardando...",
				cor:  CORES.FUNDO_NEUTRAL
			}
		}

		dados := zonasStatus[numSensor]
		
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

	ObterStatusParticao(numParticao) {
		global particionesStatus
		
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

	AtualizarGUI() {
		global guiHwnd, particionesStatus, historicoMensagens, ultimaAtualizacao, statusConexao, colorConexao, client
		global guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlHistorico, guiCtrlSensores
		
		if (!guiHwnd)
			return

		if (! client || !IsObject(client)) {
			statusConexao := "🔴 DESCONECTADO"
			colorConexao := CORES.DESCONECTADO
			try guiCtrlStatusConexao.Text := statusConexao
			return
		}

		statusConexao := client.connected ? "🟢 CONECTADO" : "🔴 DESCONECTADO"
		colorConexao := client.connected ? CORES.CONECTADO :  CORES.DESCONECTADO
		try guiCtrlStatusConexao.Text := statusConexao

		ultimaAtualizacao := Format("{:02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
		try guiCtrlTimestamp.Text := "Última atualização:`t" ultimaAtualizacao
		
		ListLines(0)
		Loop 8 {
			status := ObterStatusParticao(A_Index)
			guiCtrlParticoes[A_Index].Opt("-Redraw")
			guiCtrlParticoes[A_Index].Text := "Partição " A_Index ": " status.texto
			guiCtrlParticoes[A_Index].Opt("+Background" status.cor)
		}

		Loop 32 {
			status := ObterStatusSensor(A_Index)
			guiCtrlSensores[A_Index].Opt("-Redraw")
			guiCtrlSensores[A_Index].Text := A_Index ": " status.texto
			guiCtrlSensores[A_Index].Opt("+Background" status.cor)
		}

		Loop 32 {
			if(A_Index < 9)
				guiCtrlParticoes[A_Index].Opt("+Redraw")
			guiCtrlSensores[A_Index].Opt("+Redraw")
		}
		ListLines(1)
	}

	UnixToDateTime(ts) {
		; ts:  segundos desde 1970-01-01 00:00:00 UTC
		base := 19700101000000  ; YYYYMMDDhhmmss

		return DateAdd(base, ts, "s")  ; retorna YYYYMMDDhhmmss
	}

; ===================== INTERFACE GRÁFICA =====================

	CarregarUnidadesDb() {
		global gunidades, CORES
		unidades := []

		query := "SELECT [NOME],[NUMERO] FROM [Programação].[dbo].[INSTALACAO] ORDER BY 1"
		;query := "select * from [ASM].[dbo].[_unidades]"

		try {
			rs := sql(query)
			Loop rs.Length-1 {
				nome := rs[A_Index+1][1]
				num  := Format("{:04}",rs[A_Index+1][2])
				unidades.Push({ id :  num, label : nome })
			}
		} catch Error as e {
			msgbox("❌ Erro SQL: " e.Message "`r`n`tLine: " e.Line, CORES.ERRO)
		}
		
		global ISEP_DEFAULT := rs[2][2] ' - ' rs[2][1]

		; Se nada voltou ou deu erro, mantém as unidades atuais
		if (unidades.Length = 0)
			return gunidades
		return unidades
	}

	CriarGUI() {
		global guiHwnd, guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlSensores, guiCtrlHistorico, CORES
			, gunidades, guiCtrlISEP, guiCtrlClienteSelecionado
		MyGui := Gui()
		guiHwnd := MyGui.Hwnd

		MyGui.BackColor := CORES.FUNDO_INTERFACE
		MyGui.SetFont("S12")
		MyGui.Add("Text", "x15 Center w410 h20 cFFFFFF Background" CORES.INFO " Section", "🛡️ VIAWEB MONITOR")
		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		guiCtrlStatusConexao := MyGui.Add("Text", "Center w410 h20 c" CORES.CONECTADO " Background" CORES.FUNDO_NEUTRAL, "🔴 DESCONECTADO")
		MyGui.SetFont("S9")

		MyGui.Add("Text", "x15 w410", "Endereço:`t`t" IP ":" PORTA)

		MyGui.Add("Text", "x15 w60 y+5", "ISEP:")
		guiCtrlISEP := MyGui.Add("ComboBox", "x80 yp-3 w200", gunidades)
		filter := ComboBoxFilter(guiCtrlISEP, gunidades, true, true)
			global comboFilter := filter
		OnMessage(0x0100, ComboKeyNavBlock)	; WM_KEYDOWN
		OnMessage(0x0111, HandleComboCommand)  ; WM_COMMAND
		guiCtrlISEP.Text := ISEP_DEFAULT

		guiCtrlClienteSelecionado := MyGui.Add("Text", "x15 y+5 w410 c" CORES.TEXTO_GRUPO, "Cliente selecionado:  (nenhum)")
		ConfirmarISEP()

		guiCtrlTimestamp := MyGui.Add("Text", "x15 w410 y+0", "Última atualização:`t00:00:00")
		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		btnCtrlGroup := MyGui.Add("GroupBox", "x15 w410 h60 Section c" CORES.TEXTO_GRUPO, "🎮 Controles de Central")
		MyGui.Add("Button", "x025 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.ARMADA, "🔒 Armar").OnEvent("Click", ArmarBtn)
		MyGui.Add("Button", "x125 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.DESARMADA, "🔓 Desarmar").OnEvent("Click", DesarmarBtn)
		MyGui.Add("Button", "x225 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.INFO, "📋 Status").OnEvent("Click", StatusBtn)
		MyGui.Add("Button", "x325 ys+20 w90 h30 c" CORES.TEXTO_CLARO " Background" CORES.INFO, "🔄 Zonas").OnEvent("Click", ZonasBtn)

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		MyGui.Add("GroupBox", "x15 y+10 w410 h165 Section c" CORES.TEXTO_GRUPO, "📊 Status das Partições ")
		Loop 8 {
			guiCtrlParticoes.Push("")
			status := ObterStatusParticao(A_Index)
			guiCtrlParticoes[A_Index] := MyGui.Add("Text", "x20 ys+" (A_Index * 16) " w390 h16 c" CORES.TEXTO_CLARO " 0x1500 Background" status.cor, "Partição " A_Index ": " status.texto)
		}

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		MyGui.Add("GroupBox", "x15 y+10 w410 h180 Section c" CORES.TEXTO_GRUPO, "📡 Status dos Sensores")
		yBaseSensores := 555
		Loop 32 {
			coluna := Mod(A_Index - 1, 4)
			linha := (A_Index - 1) // 4
			xPos := 20 + (coluna * 100)
			status := ObterStatusSensor(A_Index)
			guiCtrlSensores.Push(MyGui.Add("Text", "x" xPos " ys+" ((linha+1) * 20) " w95 h18 c" CORES.TEXTO_CLARO " 0x1500 Background" status.cor, A_Index ": " status.texto))
		}

		MyGui.Add("Text", "x15 w410 h2 Background" CORES.BORDER_INFO, "")

		; ===================== LISTVIEW PARA HISTÓRICO =====================
		MyGui.Add("GroupBox", "x15 w410 h250 c" CORES.TEXTO_GRUPO " Section", "📜 Histórico de Ações (ListView)")
		
		; Cria a ListView com 3 colunas
		guiCtrlHistorico := MyGui.Add("ListView", 
			"ys+20 xs+10 w390 R07"					; Posição e tamanho
			" -Multi"								; Sem seleção múltipla
			" Grid"									; Mostra grid
			" AltSubmit"							; Valores alternados no submit
			" Background" CORES.FUNDO_NEUTRAL		; Cor de fundo
			" c" CORES.TEXTO_ESCURO,				; Cor do texto
			["Hora", "Tipo", "Mensagem"]			; Colunas
		)
		; depois de criar guiCtrlHistorico
			LVM_SETEXTENDEDLISTVIEWSTYLE := 0x1036
			LVS_EX_DOUBLEBUFFER		  := 0x00010000
			SendMessage(LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_DOUBLEBUFFER, LVS_EX_DOUBLEBUFFER, guiCtrlHistorico.Hwnd)
		; Configura as colunas
			guiCtrlHistorico.ModifyCol(1, 60)   ; Coluna 1: Hora (60 pixels)
			guiCtrlHistorico.ModifyCol(2, 90)   ; Coluna 2: Tipo (90 pixels)
			guiCtrlHistorico.ModifyCol(3, 235)  ; Coluna 3: Mensagem (240 pixels, expansível)
		
		; Evento:  clique duplo na linha
			guiCtrlHistorico.OnEvent("DoubleClick", HistoricoDoubleClick)

		; Evento: botão direito do mouse
			guiCtrlHistorico.OnEvent("ContextMenu", HistoricoContextMenu)

		guiCtrlStatusConexao.Value := "🔴 DESCONECTADO"
		guiCtrlTimestamp.Value := "Última atualização:`t00:00:00"

		MyGui.Show("x0 y0")
		MyGui.OnEvent("Close", GuiClose)
		MyGui.Title := "🛡️ VIAWEB Monitor - Dashboard de Monitoramento"
	}

	GetComboDropHwnd(cbHwnd) {
		cbInfo := Buffer(40, 0) ; COMBOBOXINFO tem 40 bytes em 64-bit/32-bit também
		NumPut("UInt", cbInfo.Size, cbInfo, 0) ; cbSize
		if DllCall("user32\GetComboBoxInfo", "ptr", cbHwnd, "ptr", cbInfo) {
			offset := (A_PtrSize = 8) ? 24 : 16 ; hwndList offset
			return NumGet(cbInfo, offset, "ptr")
		}
		return 0
	}

	ComboKeyNavBlock(wParam, lParam, message, hwnd) {
		global guiCtrlISEP, comboFilter
		static VK_RETURN := 0x0D, VK_NUMPAD_RETURN := 0x0D
		static VK_DOWN := 0x28, VK_UP := 0x26
		static CB_GETDROPPEDSTATE := 0x157
		static CB_GETCURSEL := 0x147, CB_GETCOUNT := 0x146
		static CB_SETCURSEL := 0x14E, CB_FINDSTRINGEXACT := 0x158

		focusHwnd := DllCall("GetFocus", "ptr")
		dropHwnd  := GetComboDropHwnd(guiCtrlISEP.Hwnd)

		; só processa se o foco está no combo, no edit ou na listbox
		if (focusHwnd != guiCtrlISEP.Hwnd && focusHwnd != comboFilter.editHwnd && focusHwnd != dropHwnd)
			return

		dropped := DllCall("user32\SendMessageW", "ptr", guiCtrlISEP.Hwnd, "uint", CB_GETDROPPEDSTATE, "ptr", 0, "ptr", 0)

		; Enter / NumPadEnter com lista FECHADA confirma seleção
		if (wParam = VK_RETURN || wParam = VK_NUMPAD_RETURN) {
			if (dropped)
				return  ; lista aberta:  CBN_SELENDOK cuidará
			ConfirmarISEP()
			return 0
		}

		; Corrige a "primeira seta" com lista fechada sem mexer no texto do edit
		if (! dropped && (wParam = VK_DOWN || wParam = VK_UP)) {
			idx   := DllCall("user32\SendMessageW", "ptr", guiCtrlISEP.Hwnd, "uint", CB_GETCURSEL, "ptr", 0, "ptr", 0, "int")
			count := DllCall("user32\SendMessageW", "ptr", guiCtrlISEP.Hwnd, "uint", CB_GETCOUNT, "ptr", 0, "ptr", 0, "int")
			if (count > 0) {
				; se nada selecionado, tenta achar pelo texto atual
				if (idx = -1) {
					txt := guiCtrlISEP.Text
					found := DllCall("user32\SendMessageW", "ptr", guiCtrlISEP.Hwnd, "uint", CB_FINDSTRINGEXACT, "ptr", -1, "ptr", StrPtr(txt), "int")
					if (found >= 0)
						idx := found
				}
				if (idx = -1)
					idx := 0
				else if (wParam = VK_DOWN)
					idx := Min(idx + 1, count - 1)
				else if (wParam = VK_UP)
					idx := Max(idx - 1, 0)

				; aplica seleção sem alterar guiCtrlISEP.Text
				DllCall("user32\SendMessageW", "ptr", guiCtrlISEP.Hwnd, "uint", CB_SETCURSEL, "ptr", idx, "ptr", 0)
				ConfirmarISEP()
				return 0
			}
		}

		; demais teclas seguem o padrão (digitação/filtragem)
	}

	ConfirmarISEP() {
		global guiCtrlISEP, ISEP_DEFAULT, CORES, guiCtrlClienteSelecionado, client
		static lastISEP := ""  ; evita reprocessar o mesmo ISEP consecutivo

		if (! IsObject(guiCtrlISEP))
			return

		hwnd := guiCtrlISEP.Hwnd
		idx := DllCall("user32\SendMessageW", "ptr", hwnd, "uint", 0x147, "ptr", 0, "ptr", 0, "int") ; CB_GETCURSEL
		selText := ""

		if (idx != -1) {
			len := DllCall("user32\SendMessageW", "ptr", hwnd, "uint", 0x149, "ptr", idx, "ptr", 0, "int") ; CB_GETLBTEXTLEN
			buf := Buffer((len + 1) * 2, 0)
			DllCall("user32\SendMessageW", "ptr", hwnd, "uint", 0x148, "ptr", idx, "ptr", buf) ; CB_GETLBTEXT
			selText := StrGet(buf, "UTF-16")
		} else {
			selText := guiCtrlISEP.Text
		}

		idClean := RegExReplace(selText, "\D")
		if (idClean = "")
			return

		candidate := Format('{: 04}', idClean)
		if (candidate = lastISEP)
			return  ; bloqueia repetição do mesmo ISEP

		ISEP_DEFAULT := candidate
		lastISEP := candidate

		AddHistorico("📝 ISEP selecionado: " ISEP_DEFAULT, CORES.INFO)
		if (IsObject(guiCtrlClienteSelecionado))
			guiCtrlClienteSelecionado.Text := "Cliente selecionado: " selText

		; ao selecionar cliente por qualquer caminho, chama Status
		if (client && IsObject(client) && client.connected) {
			try StatusBtn(0, 0)
		}
	}

	HandleComboCommand(wParam, lParam, msg, hwnd) {
		global guiCtrlISEP
		if (!IsObject(guiCtrlISEP))
			return

		static CBN_SELCHANGE := 1, CBN_SELENDOK := 9
		notify := (wParam >> 16) & 0xFFFF

		; Dispara somente quando a seleção é confirmada (clique ou Enter com lista)
		if (lParam = guiCtrlISEP.Hwnd && (notify = CBN_SELCHANGE || notify = CBN_SELENDOK)) {
			ConfirmarISEP()
			return 0
		}
	}

	GuiClose(GuiObj) {
		global guiHwnd
		SetTimer(PollTimer, 0)
		SetTimer(AtualizarGUI, 0)
		guiHwnd := 0
		ExitApp()
	}

	ArmarBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT, SENHA_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.Armar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
		} catch Error as e {
			AddHistorico("❌ Erro:  " e.Message "`r`n`t" e.Extra "`r`n`tLine - " e.Line, CORES.ERRO)
		}
	}

	DesarmarBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT, SENHA_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.Desarmar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message "`r`n`t" e.Extra "`r`n`tLine - " e.Line, CORES.ERRO)
		}
	}

	StatusBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT, CORES, lastZonasUpdateTick
		static lastCallTick := 0

		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}

		; throttle opcional de 1s para evitar spam
		if (A_TickCount - lastCallTick < 1000)
			return
		lastCallTick := A_TickCount

		curr := ISEP_DEFAULT
		try {
			client.StatusParticoes(RegExReplace(curr, "\D"))
			SetTimer(() => EnsureZonas(curr), -1000) ; se quiser 1s no fallback
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message "`r`n`t" e.Extra "`r`n`tLine - " e.Line, CORES.ERRO)
		}
	}

	ZonasBtn(GuiCtrlObj, Info) {
		global client, ISEP_DEFAULT
		if (!client || !IsObject(client) || !client.connected) {
			AddHistorico("❌ Não conectado", CORES.ERRO)
			return
		}
		try {
			client.StatusZonas(ISEP_DEFAULT)
		} catch Error as e {
			AddHistorico("❌ Erro: " e.Message "`r`n`t" e.Extra "`r`n`tLine - " e.Line, CORES.ERRO)
		}
	}

	ISEPChanged(GuiCtrlObj, Info) {
		global ISEP_DEFAULT
		idClean := RegExReplace(GuiCtrlObj.Text, "\D")
		ISEP_DEFAULT := Format('{:04}', idClean)
		AddHistorico("📝 ISEP alterado para: " ISEP_DEFAULT, CORES.INFO)
	}

; ===================== INICIALIZAÇÃO ======================

	try {

		CriarGUI()

		client := ViawebClient(IP, PORTA, CHAVE, IV)
		client.Connect()

		AddHistorico("✅ Conectado em " IP ":" PORTA, CORES.SUCESSO)

		client.Identificar("AHK Monitor GUI")
		AddHistorico("🔐 Identificação enviada", CORES.INFO)

		SetTimer(PollTimer, POLL_INTERVAL_MS)
		SetTimer(AtualizarGUI, GUI_UPDATE_MS)

		client.ListarClientes()

	} catch Error as e {
		AddHistorico("❌ Erro na inicialização: " e.Message "`r`n`t" e.Extra "`r`n`tLine - " e.Line, CORES.ERRO)
		MsgBox("Erro:  " e.Message "`n`t" e.Extra "`nLinha - " e.Line, "VIAWEB Monitor", "Icon!")
	}

; ===================== HOTKEYS =====================

	F3::  {
		StatusBtn(0, 0)
	}

	F4:: {
		Global client
		client.ListarClientes()
	}

	F1:: {
		ArmarBtn(0, 0)
	}

	F2:: {
		DesarmarBtn(0, 0)
	}

; ===================== EXIT ======================

	Shutdown(ExitReason, ExitCode := 0) {
		global client
		SetTimer(PollTimer, 0)
		SetTimer(AtualizarGUI, 0)
		if (IsSet(client) && IsObject(client) && client.connected)
			client.Disconnect()
	}

	OnExit(Shutdown)