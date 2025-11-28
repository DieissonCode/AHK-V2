#Requires AutoHotkey v2.0

class ViawebClient {
	socket := 0
	crypto := 0
	connected := false
	recvBuffer := Buffer(65536)
	commandId := 0

	__New(ip, port, hexKey, hexIV)	{
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
			throw Error("Falha ao conectar: " . DllCall("ws2_32\WSAGetLastError", "Int"))
		
		this.connected := true
		return true
	}

	Send(jsonStr) {
		if (!this.connected)
			throw Error("Não conectado")
		
		encrypted := this.crypto.Encrypt(jsonStr)
		
		result := DllCall("ws2_32\send", "Ptr", this.socket, "Ptr", encrypted, "Int", encrypted.Size, "Int", 0, "Int")
		
		if (result == -1)
			throw Error("Falha ao enviar: " .  DllCall("ws2_32\WSAGetLastError", "Int"))
		
		return result
	}
	
	Receive(timeout := 5000) {
		if (!this.connected)
			throw Error("Não conectado")
		
		tv := Buffer(8)
		NumPut("UInt", timeout // 1000, tv, 0)
		NumPut("UInt", Mod(timeout, 1000) * 1000, tv, 4)
		DllCall("ws2_32\setsockopt", "Ptr", this.socket, "Int", 0xFFFF, "Int", 0x1006, "Ptr", tv, "Int", 8)
		
		recvBuf := Buffer(4096)
		received := DllCall("ws2_32\recv", "Ptr", this.socket, "Ptr", recvBuf, "Int", 4096, "Int", 0, "Int")
		
		if (received <= 0)
			return ""
		
		encrypted := Buffer(received)
		Loop received
			NumPut("UChar", NumGet(recvBuf, A_Index - 1, "UChar"), encrypted, A_Index - 1)
		
		return this.crypto.Decrypt(encrypted)
	}
	
	Disconnect() {
		if (this.socket) {
			DllCall("ws2_32\closesocket", "Ptr", this.socket)
			DllCall("ws2_32\WSACleanup")
			this.socket := 0
			this.connected := false
		}
	}
	
	__Delete() {
		this.Disconnect()
	}
	
	; Gera um ID único para comandos
	GetCommandId() {
		this.commandId++
		return this.commandId
	}
	
	; ============================================
	; FUNÇÕES DE COMANDO
	; ============================================
	
	; Identificar o software no VIAWEB Receiver
	Identificar(nome := "AHK Monitor") {
		identJson := '{"a":' . Random(1, 999999) .  ',"oper":[{"acao":"ident","nome":"' . nome . '"},{"acao":"salvarVIAWEB","operacao":2,"monitoramento":1}]}'
		this.Send(identJson)
		return this.Receive(10000)
	}
	
	; Armar partições
	; idISEP: código ISEP do cliente (ex: "090A")
	; senha: senha do usuário (ex: "1234" ou 1234)
	; particoes: array de partições para armar (ex: [1,2] ou [1])
	; forcado: 1 para armar forçado, 0 para normal
	; zonasInibir: array de zonas para inibir antes de armar (opcional)
	Armar(idISEP, senha, particoes, forcado := 0, zonasInibir := "") {
		cmdId := this.GetCommandId()
		
		; Construir array de partições
		if (Type(particoes) != "Array")
			particoes := [particoes]
		
		particoesStr := "["
		for i, p in particoes {
			if (i > 1)
				particoesStr .= ","
			particoesStr .= p
		}
		particoesStr .= "]"
		
		; Construir comando base
		cmdJson := '{"oper":[{"id":' . cmdId .  ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"armar","password":"' . senha . '","forcado":' . forcado . ',"particoes":' . particoesStr
		
		; Adicionar zonas para inibir se especificado
		if (zonasInibir != "" && Type(zonasInibir) == "Array" && zonasInibir.Length > 0) {
			inibirStr := "["
			for i, z in zonasInibir {
				if (i > 1)
					inibirStr .= ","
				inibirStr .= z
			}
			inibirStr .= "]"
			cmdJson .= ',"inibir":' .  inibirStr
		}
		
		cmdJson .= '}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	; Desarmar partições
	; idISEP: código ISEP do cliente (ex: "090A")
	; senha: senha do usuário (ex: "1234" ou 1234)
	; particoes: array de partições para desarmar (ex: [1,2] ou [1])
	Desarmar(idISEP, senha, particoes) {
		cmdId := this.GetCommandId()
		
		; Construir array de partições
		if (Type(particoes) != "Array")
			particoes := [particoes]
		
		particoesStr := "["
		for i, p in particoes {
			if (i > 1)
				particoesStr .= ","
			particoesStr .= p
		}
		particoesStr .= "]"
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"desarmar","password":"' . senha . '","particoes":' .  particoesStr .  '}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	/* Obter status das partições
	; idISEP: código ISEP do cliente (ex: "090A")
	 Retorna informações de armado/desarmado e disparado para cada partição */
	StatusParticoes(idISEP) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"particoes"}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	/* Obter status das zonas/sensores
	; idISEP: código ISEP do cliente (ex: "090A")
	; Retorna informações de aberta/fechada, disparada, inibida, etc. */
	StatusZonas(idISEP) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"zonas"}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	/* Obter status das PGMs
	; idISEP: código ISEP do cliente (ex: "090A")
	; posInicial: posição inicial (default 1)
	; quantidade: quantidade máxima para ler (default 10, máximo 32) */
	StatusPGMs(idISEP, posInicial := 1, quantidade := 10) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' .  cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"pgms","pos":' . posInicial . ',"max":' . quantidade .  '}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	/* Acionar PGM
	; idISEP: código ISEP do cliente (ex: "090A")
	; pgm: número da PGM (1-255)
	; tempo: tempo em segundos (0 = indefinido) */
	AcionarPGM(idISEP, pgm, tempo := 0) {
		cmdId := this.GetCommandId()
		cmdJson := '{"oper":[{"id":' . cmdId .  ',"acao":"executar","idISEP":"' .  idISEP .  '","comando":[{"cmd":"acionar","pgm":' . pgm .  ',"tempo":' . tempo . '}]}]}'
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	/* Desacionar PGM
	; idISEP: código ISEP do cliente (ex: "090A")
	; pgm: número da PGM (1-255) */
	DesacionarPGM(idISEP, pgm) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"desacionar","pgm":' . pgm . '}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	; Inverter estado da PGM
	; idISEP: código ISEP do cliente (ex: "090A")
	; pgm: número da PGM (1-255)
	; tempo: tempo em segundos para voltar ao estado original (0 = permanente)
	InverterPGM(idISEP, pgm, tempo := 0) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"inverter","pgm":' .  pgm . ',"tempo":' . tempo . '}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	; Obter recursos do sistema (quantidade de zonas, partições, etc.)
	; idISEP: código ISEP do cliente (ex: "090A")
	Recursos(idISEP) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId .  ',"acao":"executar","idISEP":"' .  idISEP .  '","comando":[{"cmd":"recursos"}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	; Obter hora do sistema
	; idISEP: código ISEP do cliente (ex: "090A")
	Relogio(idISEP) {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' .  cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"relogio"}]}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
	}
	
	; Listar clientes conectados
	ListarClientes() {
		cmdId := this.GetCommandId()
		
		cmdJson := '{"oper":[{"id":' . cmdId . ',"acao":"listarClientes"}]}'
		
		this.Send(cmdJson)
		return this.Receive(10000)
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
			NumPut("UChar", NumGet(iv, A_Index - 1, "UChar"), this.ivSend, A_Index - 1)
			NumPut("UChar", NumGet(iv, A_Index - 1, "UChar"), this.ivRecv, A_Index - 1)
		}
		
		result := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &hAlg := 0, "WStr", "AES", "Ptr", 0, "UInt", 0, "UInt")
		
		if (result != 0)
			throw Error("BCryptOpenAlgorithmProvider falhou: " . Format("0x{:08X}", result))
		
		this.hAlg := hAlg
		
		chainMode := Buffer(StrPut("ChainingModeCBC", "UTF-16") * 2)
		StrPut("ChainingModeCBC", chainMode, "UTF-16")
		
		result := DllCall("bcrypt\BCryptSetProperty", "Ptr", this.hAlg, "WStr", "ChainingMode", "Ptr", chainMode, "UInt", chainMode.Size, "UInt", 0, "UInt")
		
		if (result != 0)
			throw Error("BCryptSetProperty falhou: " . Format("0x{:08X}", result))
		
		result := DllCall("bcrypt\BCryptGenerateSymmetricKey", "Ptr", this.hAlg, "Ptr*", &hKey := 0, "Ptr", 0, "UInt", 0, "Ptr", key, "UInt", key.Size, "UInt", 0, "UInt")
		
		if (result != 0)
			throw Error("BCryptGenerateSymmetricKey falhou: " . Format("0x{:08X}", result))
		
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
			NumPut("UChar", NumGet(plainBytes, A_Index - 1, "UChar"), paddedData, A_Index - 1)
		
		encrypted := Buffer(paddedSize)
		
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(this.ivSend, A_Index - 1, "UChar"), ivCopy, A_Index - 1)
		
		result := DllCall("bcrypt\BCryptEncrypt", "Ptr", this.hKey, "Ptr", paddedData, "UInt", paddedSize, "Ptr", 0, "Ptr", ivCopy, "UInt", 16, "Ptr", encrypted, "UInt", paddedSize, "UInt*", &bytesWritten := 0, "UInt", 0, "UInt")
		
		if (result != 0)
			throw Error("BCryptEncrypt falhou: " . Format("0x{:08X}", result))
		
		Loop 16
			NumPut("UChar", NumGet(encrypted, paddedSize - 16 + A_Index - 1, "UChar"), this.ivSend, A_Index - 1)
		
		return encrypted
	}
	
	Decrypt(encryptedBuffer) {
		dataSize := encryptedBuffer.Size
		
		if (Mod(dataSize, 16) != 0)
			throw Error("Dados criptografados devem ter tamanho múltiplo de 16")
		
		lastBlock := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(encryptedBuffer, dataSize - 16 + A_Index - 1, "UChar"), lastBlock, A_Index - 1)
		
		decrypted := Buffer(dataSize)
		
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar", NumGet(this.ivRecv, A_Index - 1, "UChar"), ivCopy, A_Index - 1)
		
		result := DllCall("bcrypt\BCryptDecrypt", "Ptr", this.hKey, "Ptr", encryptedBuffer, "UInt", dataSize, "Ptr", 0, "Ptr", ivCopy, "UInt", 16, "Ptr", decrypted, "UInt", dataSize, "UInt*", &bytesWritten := 0, "UInt", 0, "UInt")
		
		if (result != 0)
			throw Error("BCryptDecrypt falhou: " . Format("0x{:08X}", result))
		
		Loop 16
			NumPut("UChar", NumGet(lastBlock, A_Index - 1, "UChar"), this.ivRecv, A_Index - 1)
		
		return this.BytesToString(decrypted)
	}
	
	HexToBytes(hexStr) {
		hexStr := StrReplace(hexStr, " ", "")
		len := StrLen(hexStr) // 2
		buf := Buffer(len)
		
		Loop len {
			byte := "0x" . SubStr(hexStr, (A_Index - 1) * 2 + 1, 2)
			NumPut("UChar", Integer(byte), buf, A_Index - 1)
		}
		
		return buf
	}
	
	BytesToHex(buf) {
		hex := ""
		Loop buf.Size
			hex .= Format("{:02X}", NumGet(buf, A_Index - 1, "UChar"))
		return hex
	}
	
	StringToBytes(str) {
		len := StrPut(str, "UTF-8") - 1
		buf := Buffer(len)
		StrPut(str, buf, "UTF-8")
		return buf
	}
	
	BytesToString(buf) {
		endPos := buf.Size
		Loop buf.Size {
			idx := buf.Size - A_Index
			byte := NumGet(buf, idx, "UChar")
			if (byte == 0x7D || byte == 0x5D) {
				endPos := idx + 1
				break
			}
			if (byte != 0)
				break
		}
		
		return StrGet(buf, endPos, "UTF-8")
	}
}

/*  EXEMPLO DE USO  */
	IP		:= "10.0.20.43"
	PORTA	:= 2700
	CHAVE	:= "94EF1C592113E8D27F5BB4C5D278BF3764292CEA895772198BA9435C8E9B97FD"
	IV		:= "70FC01AA8FCA3900E384EA28A5B7BCEF"

/* Código ISEP do cliente que você quer controlar */
ISEP := "0251"
SENHA := "8790"

client := ViawebClient(IP, PORTA, CHAVE, IV)

try {
	client.Connect()
	MsgBox("Conectado ao VIAWEB Receiver!")
	
	; Identificar
	response := client.Identificar("AHK Monitor")
	MsgBox("Identificação: " . response)
	
	; Listar clientes conectados
	response := client.ListarClientes()
	MsgBox("Clientes: " . response)
	
	; Ver status das partições
	response := client.StatusParticoes(ISEP)
	MsgBox("Status Partições: " .  response)
	
	; Ver status das zonas/sensores
	response := client.StatusZonas(ISEP)
	MsgBox("Status Zonas: " .  response)
	
	; Ver recursos do sistema
	response := client.Recursos(ISEP)
	MsgBox("Recursos: " . response)
	
	/* Exemplo: Armar partição 1
	; response := client. Armar(ISEP, SENHA, [1])
	; MsgBox("Armar: " . response)
	
	; Exemplo: Armar partições 1 e 2 no modo forçado
	; response := client. Armar(ISEP, SENHA, [1, 2], 1)
	; MsgBox("Armar Forçado: " .  response)
	
	; Exemplo: Armar partição 1 inibindo zonas 5 e 6
	; response := client.Armar(ISEP, SENHA, [1], 0, [5, 6])
	; MsgBox("Armar com Inibição: " . response)
	
	; Exemplo: Desarmar partição 1
	; response := client.Desarmar(ISEP, SENHA, [1])
	; MsgBox("Desarmar: " . response)
	
	; Exemplo: Ver status das PGMs
	; response := client.StatusPGMs(ISEP)
	; MsgBox("Status PGMs: " . response)
	
	; Exemplo: Acionar PGM 1 por 5 segundos
	; response := client. AcionarPGM(ISEP, 1, 5)
	; MsgBox("Acionar PGM: " . response) */
	
} catch as e {
	MsgBox("Erro: " . e.Message)
} finally {
	client.Disconnect()
}