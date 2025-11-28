#Requires AutoHotkey v2.0
#Warn All, off

OutputDebug(A_AhkVersion)
Persistent

; ===================== CONFIGURAÇÃO =====================
IP := "10.0.20.43"
PORTA := 2700
CHAVE := "94EF1C592113E8D27F5BB4C5D278BF3764292CEA895772198BA9435C8E9B97FD"
IV := "70FC01AA8FCA3900E384EA28A5B7BCEF"

ISEP_DEFAULT := "0002"
SENHA_DEFAULT := "8790"

POLL_INTERVAL_MS := 200
GUI_UPDATE_MS := 500

; ===================== VARIÁVEIS GLOBAIS =====================
global client := 0
global particionesStatus := Map()
global zonasStatus := Map()
global historicoMensagens := []
global ultimaAtualizacao := ""
global statusConexao := "Desconectado"
global colorConexao := "0xFF0000"
global guiHwnd := 0
global guiCtrlStatusConexao := 0
global guiCtrlTimestamp := 0
global guiCtrlParticoes := 0
global guiCtrlHistorico := 0

; ===================== CLASSES =====================

class ViawebClient {
	socket := 0
	crypto := 0
	connected := false
	recvBuffer := Buffer(65536)
	commandId := 0

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
		if (this.socket == -1)
			throw Error("Falha ao criar socket")

		hostent := DllCall("ws2_32\gethostbyname", "AStr", this.ip, "Ptr")
		if (! hostent)
			throw Error("Falha ao resolver hostname")

		addrList := NumGet(hostent + (A_PtrSize == 8 ? 24 : 12), "Ptr")
		addr := NumGet(addrList, "Ptr")
		ipAddr := NumGet(addr, "UInt")

		sockAddr := Buffer(16, 0)
		NumPut("Short", 2, sockAddr, 0)
		NumPut("UShort", DllCall("ws2_32\htons", "UShort", this.port, "UShort"), sockAddr, 2)
		NumPut("UInt", ipAddr, sockAddr, 4)

		result := DllCall("ws2_32\connect", "Ptr", this.socket, "Ptr", sockAddr, "Int", 16, "Int")
		if (result == -1)
			throw Error("Falha ao conectar: " DllCall("ws2_32\WSAGetLastError", "Int"))

		this.connected := true
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
		if (result == -1)
			throw Error("Falha ao enviar: "  DllCall("ws2_32\WSAGetLastError", "Int"))
		return result
	}

	Poll() {
		if (!this.connected)
			return

		fdsetSize := 4 + (64 * A_PtrSize)
		fdset := Buffer(fdsetSize, 0)
		NumPut("UInt", 1, fdset, 0)
		if (A_PtrSize = 8)
			NumPut("UInt64", this.socket, fdset, 4)
		else
			NumPut("UInt", this.socket, fdset, 4)

		tv := Buffer(8, 0)
		NumPut("UInt", 0, tv, 0)
		NumPut("UInt", 0, tv, 4)

		sel := DllCall("ws2_32\select", "Int", 0, "Ptr", fdset, "Ptr", 0, "Ptr", 0, "Ptr", tv, "Int")
		if (sel > 0) {
			recvBuf := Buffer(8192)
			received := DllCall("ws2_32\recv", "Ptr", this.socket, "Ptr", recvBuf, "Int", recvBuf.Size, "Int", 0, "Int")
			if (received = 0) {
				AddHistorico("⚠️ Conexão fechada pelo servidor.", "FF0000")
				this.Disconnect()
				return
			}
			if (received < 0) {
				err := DllCall("ws2_32\WSAGetLastError", "Int")
				AddHistorico("❌ Erro recv: " err, "FF0000")
				return
			}

			encrypted := Buffer(received)
			Loop received
				NumPut("UChar", NumGet(recvBuf, A_Index-1, "UChar"), encrypted, A_Index-1)

			try {
				msg := this.crypto.Decrypt(encrypted)
				ProcessarResposta(msg)
			} catch Error as e {
				AddHistorico("❌ Erro descriptografando: " e.Message, "FF0000")
				return
			}
		}
	}

	GetCommandId() {
		this.commandId++
		return this.commandId
	}

	Identificar(nome := "AHK Monitor") {
		identJson := '{"a":' Random(1, 999999) ',"oper":[{"acao":"ident","nome":"' nome '"},{"acao":"salvarVIAWEB","operacao":2,"monitoramento":1}]}'
		this.Send(identJson)
	}

	Armar(idISEP, senha, particoes, forcado := 0) {
		cmdId := this.GetCommandId()
		if (Type(particoes) != "Array")
			particoes := [particoes]
		particoesStr := "[" JoinArray(particoes, ",")  "]"
		cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idISEP '","comando":[{"cmd":"armar","password":"' senha '","forcado":' forcado ',"particoes":' particoesStr '}]}]}'
		this.Send(cmdObj)
		AddHistorico("🔒 Comando: Armar partições " JoinArray(particoes, ","), "00AA00")
	}

	Desarmar(idISEP, senha, particoes) {
		cmdId := this.GetCommandId()
		if (Type(particoes) != "Array")
			particoes := [particoes]
		particoesStr := "[" JoinArray(particoes, ",") "]"
		cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idISEP  '","comando":[{"cmd":"desarmar","password":"' senha  '","particoes":' particoesStr '}]}]}'
		this.Send(cmdObj)
		AddHistorico("🔓 Comando: Desarmar partições " JoinArray(particoes, ","), "FFAA00")
	}

	StatusParticoes(idISEP) {
		cmdId := this.GetCommandId()
		cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idISEP '","comando":[{"cmd":"particoes"}]}]}'
		this.Send(cmdObj)
		AddHistorico("📋 Consultando status de partições..  .", "0099FF")
	}

	StatusZonas(idISEP) {
		cmdId := this.GetCommandId()
		cmdObj := '{"oper":[{"id":' cmdId ',"acao":"executar","idISEP":"' idISEP '","comando":[{"cmd":"zonas"}]}]}'
		this.Send(cmdObj)
		AddHistorico("📋 Consultando status de zonas.. .", "0099FF")
	}
}

class ViawebCrypto {
	hAlg := 0
	hKey := 0
	ivSend := Buffer(16)
	ivRecv := Buffer(16)
	blockSize := 16

	__New(hexKey, hexIV) {
		key := this.HexToBytes(hexKey)
		iv := this.HexToBytes(hexIV)
		Loop 16 {
			NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivSend, A_Index-1)
			NumPut("UChar", NumGet(iv, A_Index-1, "UChar"), this.ivRecv, A_Index-1)
		}

		result := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &hAlg := 0, "WStr", "AES", "Ptr", 0, "UInt", 0, "UInt")
		if (result != 0)
			throw Error("BCryptOpenAlgorithmProvider falhou: " Format("0x{:08X}", result))
		this.hAlg := hAlg

		chainMode := Buffer(StrPut("ChainingModeCBC", "UTF-16") * 2)
		StrPut("ChainingModeCBC", chainMode, "UTF-16")

		result := DllCall("bcrypt\BCryptSetProperty", "Ptr", this.hAlg, "WStr", "ChainingMode", "Ptr", chainMode, "UInt", chainMode.Size, "UInt", 0, "UInt")
		if (result != 0)
			throw Error("BCryptSetProperty falhou: " Format("0x{:08X}", result))

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
		if (paddedSize == 0)
			paddedSize := 16

		paddedData := Buffer(paddedSize, 0)
		Loop plainBytes.Size
			NumPut("UChar", NumGet(plainBytes, A_Index-1, "UChar"), paddedData, A_Index-1)

		encrypted := Buffer(paddedSize)
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(this.ivSend, A_Index-1, "UChar"), ivCopy, A_Index-1)

		result := DllCall("bcrypt\BCryptEncrypt", "Ptr", this.hKey, "Ptr", paddedData, "UInt", paddedSize, "Ptr", 0, "Ptr", ivCopy, "UInt", 16, "Ptr", encrypted, "UInt", paddedSize, "UInt*", &bytesWritten := 0, "UInt", 0, "UInt")
		if (result != 0)
			throw Error("BCryptEncrypt falhou: " Format("0x{:08X}", result))

		Loop 16
			NumPut("UChar", NumGet(encrypted, paddedSize-16 + A_Index-1, "UChar"), this.ivSend, A_Index-1)

		return encrypted
	}

	Decrypt(encryptedBuffer) {
		dataSize := encryptedBuffer.Size
		if (Mod(dataSize, 16) != 0)
			throw Error("Dados criptografados devem ter tamanho múltiplo de 16")

		lastBlock := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(encryptedBuffer, dataSize-16 + A_Index-1, "UChar"), lastBlock, A_Index-1)

		decrypted := Buffer(dataSize)
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(this.ivRecv, A_Index-1, "UChar"), ivCopy, A_Index-1)

		result := DllCall("bcrypt\BCryptDecrypt", "Ptr", this.hKey, "Ptr", encryptedBuffer, "UInt", dataSize, "Ptr", 0, "Ptr", ivCopy, "UInt", 16, "Ptr", decrypted, "UInt", dataSize, "UInt*", &bytesWritten := 0, "UInt", 0, "UInt")
		if (result != 0)
			throw Error("BCryptDecrypt falhou: "  Format("0x{:08X}", result))

		Loop 16
			NumPut("UChar", NumGet(lastBlock, A_Index-1, "UChar"), this.ivRecv, A_Index-1)

		endPos := decrypted.Size
		Loop decrypted.Size {
			idx := decrypted.Size - A_Index
			b := NumGet(decrypted, idx, "UChar")
			if (b == 0x7D || b == 0x5D) {
				endPos := idx + 1
				break
			}
			if (b != 0)
				break
		}
		return StrGet(decrypted, endPos, "UTF-8")
	}

	HexToBytes(hexStr) {
		hexStr := StrReplace(hexStr, " ", "")
		len := StrLen(hexStr) // 2
		buf := Buffer(len)
		Loop len {
			byte := "0x"  SubStr(hexStr, (A_Index - 1) * 2 + 1, 2)
			NumPut("UChar", Integer(byte), buf, A_Index-1)
		}
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
	for i, v in arr {
		if (i > 1)
			out .= sep
		out .= v
	}
	return out
}

AddHistorico(msg, color := "FFFFFF") {
	global historicoMensagens, guiHwnd, client
	timestamp := Format("{:02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
	historicoMensagens.InsertAt(1, {msg: msg, color: color, timestamp: timestamp})
	
	if (historicoMensagens.Length > 50)
		historicoMensagens.Pop()
	
	if (guiHwnd && client && IsObject(client)) {
		AtualizarGUI()
	}
}

ProcessarResposta(jsonStr) {
	try {
		if (InStr(jsonStr, "particoes")) {
			pos := 1
			while (pos := InStr(jsonStr, '"pos":', pos)) {
				pos += 6
				posNum := SubStr(jsonStr, pos, 2)
				posNum := Integer(posNum)
				
				armPos := InStr(jsonStr, '"armado":', pos)
				if (armPos) {
					armado := SubStr(jsonStr, armPos + 9, 1)
					disparado := "0"
					disparadoPos := InStr(jsonStr, '"disparado":', pos)
					if (disparadoPos)
						disparado := SubStr(jsonStr, disparadoPos + 12, 1)
					
					particionesStatus[posNum] := {armado: armado, disparado: disparado}
				}
			}
			AddHistorico("✅ Partições atualizadas", "00FF00")
		}
		else if (InStr(jsonStr, "zonas")) {
			AddHistorico("✅ Zonas recebidas", "00FF00")
		}
		else if (InStr(jsonStr, "resultado")) {
			if (InStr(jsonStr, '"resultado":0'))
				AddHistorico("✅ Comando executado com sucesso!", "00FF00")
			else
				AddHistorico("❌ Erro ao executar comando", "FF0000")
		}
		else {
			AddHistorico("📥 Resposta recebida", "0099FF")
		}
	} catch Error as e {
		AddHistorico("⚠️ Erro ao processar: " e.Message, "FFAA00")
	}
}

PollTimer() {
	global client
	if (client && IsObject(client) && client.connected)
		client.Poll()
}

AtualizarGUI() {
	global guiHwnd, particionesStatus, historicoMensagens, ultimaAtualizacao, statusConexao, colorConexao, client
	global guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlHistorico
	
	if (! guiHwnd)
		return
	
	if (! client || !IsObject(client)) {
		statusConexao := "🔴 DESCONECTADO"
		colorConexao := "FF0000"
		try {
			guiCtrlStatusConexao.Value := statusConexao
		}
		return
	}
	
	statusConexao := client.connected ? "🟢 CONECTADO" : "🔴 DESCONECTADO"
	colorConexao := client.connected ? "00FF00" : "FF0000"
	
	guiCtrlStatusConexao.Value := statusConexao
	
	ultimaAtualizacao := Format("{:02d}:{:02d}:{:02d}", A_Hour, A_Min, A_Sec)
	guiCtrlTimestamp.Value := "Última atualização: " ultimaAtualizacao
	
	particoesText := ""
	Loop 8 {
		if (particionesStatus.Has(A_Index)) {
			dados := particionesStatus[A_Index]
			armado := dados["armado"] = "1" ?  "🔒 ARMADA" : "🔓 DESARMADA"
			disparado := dados["disparado"] = "1" ? " ⚠️ DISPARADA" : ""
			particoesText .= "Partição " A_Index ": " armado disparado "`n"
		} else {
			particoesText .= "Partição "  A_Index ": (aguardando...  )`n"
		}
	}
	guiCtrlParticoes.Value := particoesText
	
	historicoText := ""
	for idx, item in historicoMensagens {
		historicoText .= item.timestamp " - " item.msg "`n"
	}
	guiCtrlHistorico.Value := historicoText
}

; ===================== INTERFACE GRÁFICA =====================

CriarGUI() {
	global guiHwnd, guiCtrlStatusConexao, guiCtrlTimestamp, guiCtrlParticoes, guiCtrlHistorico
	
	MyGui := Gui()
	guiHwnd := MyGui.Hwnd
	
	MyGui.Opt("+AlwaysOnTop")
	MyGui.Title := "🛡️ VIAWEB Monitor - Dashboard de Monitoramento"
	
	MyGui.Add("Text",, "╔════════════════════════════════════════════╗")
	MyGui.Add("Text", "Center w400 h25 cFFFFFF", "🛡️ VIAWEB RECEIVER MONITOR")
	
	MyGui.Add("Text", "w400 h1 cAAAAFF", "")
	MyGui.Add("Text", "w400", "Status da Conexão:")
	guiCtrlStatusConexao := MyGui.Add("Text", "Center w400 h30 c00FF00 BackgroundTrans", "🔴 DESCONECTADO")
	MyGui.Add("Text", "x10 w400", "Endereço: " IP ":"  PORTA)
	MyGui.Add("Text", "x10 w400", "ISEP: " ISEP_DEFAULT)
	guiCtrlTimestamp := MyGui.Add("Text", "x10 w400", "Última atualização: 00:00:00")
	
	MyGui.Add("Text", "w400 h1 cAAAAFF", "")
	
	MyGui.Add("Text", "w400", "Controle Rápido:")
	btnCtrlGroup := MyGui.Add("GroupBox", "w400 h80", "Ações")
	
	MyGui.Add("Button", "x20 y+5 w90 h30 cFFFFFF", "🔒 Armar").OnEvent("Click", ArmarBtn)
	MyGui.Add("Button", "x120 y236 w90 h30 cFFFFFF", "🔓 Desarmar").OnEvent("Click", DesarmarBtn)
	MyGui.Add("Button", "x220 y236 w90 h30 cFFFFFF", "📋 Status").OnEvent("Click", StatusBtn)
	MyGui.Add("Button", "x320 y236 w90 h30 cFFFFFF", "🔄 Zonas").OnEvent("Click", ZonasBtn)
	
	MyGui.Add("Text", "w400 h1 cAAAAFF", "")
	
	MyGui.Add("Text", "w400", "Status das Partições:")
	guiCtrlParticoes := MyGui.Add("Edit", "x10 w400 h150 ReadOnly Multi")
	
	MyGui.Add("Text", "w400 h1 cAAAAFF", "")
	
	MyGui.Add("Text", "w400", "Histórico de Ações (últimas 20):")
	guiCtrlHistorico := MyGui.Add("Edit", "x10 w400 h200 ReadOnly Multi")
	
	guiCtrlStatusConexao.Value := "🔴 DESCONECTADO"
	guiCtrlTimestamp.Value := "Última atualização: 00:00:00"
	guiCtrlParticoes.Value := "Aguardando dados...  `n`n(Pressione F3 para consultar status)"
	guiCtrlHistorico.Value := "Sistema iniciado`nAguardando conexão..."
	
	MyGui.Show("w420")
}

ArmarBtn(GuiCtrlObj, Info) {
	global client, ISEP_DEFAULT, SENHA_DEFAULT
	if (!client || !IsObject(client) || !client.connected) {
		AddHistorico("❌ Não conectado", "FF0000")
		return
	}
	try {
		client.Armar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
	} catch Error as e {
		AddHistorico("❌ Erro: " e.Message, "FF0000")
	}
}

DesarmarBtn(GuiCtrlObj, Info) {
	global client, ISEP_DEFAULT, SENHA_DEFAULT
	if (!client || !IsObject(client) || !client.connected) {
		AddHistorico("❌ Não conectado", "FF0000")
		return
	}
	try {
		client.Desarmar(ISEP_DEFAULT, SENHA_DEFAULT, [1])
	} catch Error as e {
		AddHistorico("❌ Erro: " e.Message, "FF0000")
	}
}

StatusBtn(GuiCtrlObj, Info) {
	global client, ISEP_DEFAULT
	if (!client || !IsObject(client) || !client.connected) {
		AddHistorico("❌ Não conectado", "FF0000")
		return
	}
	try {
		client.StatusParticoes(ISEP_DEFAULT)
	} catch Error as e {
		AddHistorico("❌ Erro: " e.Message, "FF0000")
	}
}

ZonasBtn(GuiCtrlObj, Info) {
	global client, ISEP_DEFAULT
	if (!client || !IsObject(client) || !client.connected) {
		AddHistorico("❌ Não conectado", "FF0000")
		return
	}
	try {
		client.StatusZonas(ISEP_DEFAULT)
	} catch Error as e {
		AddHistorico("❌ Erro: " e.Message, "FF0000")
	}
}

; ===================== INICIALIZAÇÃO ======================

try {
	CriarGUI()
	
	client := ViawebClient(IP, PORTA, CHAVE, IV)
	client.Connect()
	
	AddHistorico("✅ Conectado em " IP ":" PORTA, "00FF00")
	
	client.Identificar("AHK Monitor GUI")
	AddHistorico("🔐 Identificação enviada", "0099FF")
	
	SetTimer(PollTimer, POLL_INTERVAL_MS)
	SetTimer(AtualizarGUI, GUI_UPDATE_MS)
	
;} catch Error as e {
;	AddHistorico("❌ Erro na inicialização: " e.Message, "FF0000")
;	MsgBox("Erro: " e.Message, "VIAWEB Monitor", "Icon!")
}

; ===================== HOTKEYS ======================

F3:: {
	StatusBtn(0, 0)
}

F4:: {
	ZonasBtn(0, 0)
}

F1:: {
	ArmarBtn(0, 0)
}

F2:: {
	DesarmarBtn(0, 0)
}

; ===================== EXIT ======================

Shutdown(ExitReason, ExitCode) {
	global client
	SetTimer(PollTimer, 0)
	SetTimer(AtualizarGUI, 0)
	if (client && IsObject(client) && client.connected)
		client.Disconnect()
}

OnExit(Shutdown)