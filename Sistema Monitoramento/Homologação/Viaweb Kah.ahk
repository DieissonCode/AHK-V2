OutputDebug(A_AhkVersion)
;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.1.0.0
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Viaweb Client
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\pc.ico

#Requires AutoHotkey v2.0
#Warn All, off
; Viaweb AES-256-CBC client (AHK v2 puro, compatível com 2.1-alpha.14)
; - Usa "catch Error as e" conforme solicitado
; - Não usa GuiCreate / akh_H
; - Escuta respostas assíncronas com SetTimer e grava em arquivo de log + TrayTip
; - Hotkeys:
;     F1 -> Armar partição 1
;     F2 -> Desarmar partição 1
;     F3 -> Consultar status partições
;     F4 -> Consultar status zonas
;
; Ajuste os valores abaixo antes de executar.
Persistent
; ----------------- CONFIGURAÇÃO -----------------
IP := "10.0.20.43"
PORTA := 2700
CHAVE := "94EF1C592113E8D27F5BB4C5D278BF3764292CEA895772198BA9435C8E9B97FD"
IV := "70FC01AA8FCA3900E384EA28A5B7BCEF"

ISEP_DEFAULT := "090A"
SENHA_DEFAULT := "1234"

LOG_FILE := A_ScriptDir . "\viaweb_log.txt"
POLL_INTERVAL_MS := 200  ; intervalo do timer de polling
; -------------------------------------------------

class ViawebClient {
	socket := 0
	crypto := 0
	connected := false
	recvBuffer := Buffer(65536)
	commandId := 0

	__New(ip,port,hexKey,hexIV) {
		this.ip := ip
		this.port := port
		this.crypto := ViawebCrypto(hexKey,hexIV)
	}

	Connect() {
		wsaData := Buffer(408)
		if DllCall("ws2_32\WSAStartup","UShort",0x0202,"Ptr",wsaData)
			throw Error("WSAStartup falhou")

		this.socket := DllCall("ws2_32\socket","Int",2,"Int",1,"Int",6,"Ptr")
		if (this.socket == -1)
			throw Error("Falha ao criar socket")

		hostent := DllCall("ws2_32\gethostbyname","AStr",this.ip,"Ptr")
		if (!hostent)
			throw Error("Falha ao resolver hostname")

		addrList := NumGet(hostent + (A_PtrSize == 8 ? 24 : 12),"Ptr")
		addr := NumGet(addrList,"Ptr")
		ipAddr := NumGet(addr,"UInt")

		sockAddr := Buffer(16,0)
		NumPut("Short",2,sockAddr,0)
		NumPut("UShort",DllCall("ws2_32\htons","UShort",this.port,"UShort"),sockAddr,2)
		NumPut("UInt",ipAddr,sockAddr,4)

		result := DllCall("ws2_32\connect","Ptr",this.socket,"Ptr",sockAddr,"Int",16,"Int")
		if (result == -1)
			throw Error("Falha ao conectar: " . DllCall("ws2_32\WSAGetLastError","Int"))

		this.connected := true
		return true
	}

	Disconnect() {
		if (this.socket) {
			DllCall("ws2_32\closesocket","Ptr",this.socket)
			DllCall("ws2_32\WSACleanup")
			this.socket := 0
			this.connected := false
		}
	}

	Send(jsonStr) {
		if (!this.connected)
			throw Error("Não conectado")

		encrypted := this.crypto.Encrypt(jsonStr)
		result := DllCall("ws2_32\send","Ptr",this.socket,"Ptr",encrypted,"Int",encrypted.Size,"Int",0,"Int")
		if (result == -1)
			throw Error("Falha ao enviar: " . DllCall("ws2_32\WSAGetLastError","Int"))
		return result
	}

	; Poll não-bloqueante: usa select para verificar se há dados e faz recv
	Poll() {
		if (!this.connected)
			return

		fdsetSize := 4 + (64 * A_PtrSize)
		fdset := Buffer(fdsetSize,0)
		NumPut("UInt",1,fdset,0)
		if (A_PtrSize = 8)
			NumPut("UInt64",this.socket,fdset,4)
		else
			NumPut("UInt",this.socket,fdset,4)

		tv := Buffer(8,0)
		NumPut("UInt",0,tv,0)
		NumPut("UInt",0,tv,4)

		sel := DllCall("ws2_32\select","Int",0,"Ptr",fdset,"Ptr",0,"Ptr",0,"Ptr",tv,"Int")
		if (sel > 0) {
			recvBuf := Buffer(8192)
			received := DllCall("ws2_32\recv","Ptr",this.socket,"Ptr",recvBuf,"Int",recvBuf.Size,"Int",0,"Int")
			if (received = 0) {
				AppendLog("Conexão fechada pelo servidor.")
				this.Disconnect()
				return
			}
			if (received < 0) {
				err := DllCall("ws2_32\WSAGetLastError","Int")
				AppendLog("Erro recv: " . err)
				return
			}

			encrypted := Buffer(received)
			Loop received
				NumPut("UChar",NumGet(recvBuf,A_Index-1,"UChar"),encrypted,A_Index-1)

			try {
				msg := this.crypto.Decrypt(encrypted)
			} catch Error as e {
				AppendLog("Erro descriptografando: " . e.Message)
				return
			}

			AppendLog("RECEBIDO: " . msg)
		}
	}

	GetCommandId() {
		this.commandId++
		return this.commandId
	}

	Identificar(nome := "AHK Monitor") {
		identJson := '{"a":' . Random(1,999999) . ',"oper":[{"acao":"ident","nome":"' . nome . '"},{"acao":"salvarVIAWEB","operacao":2,"monitoramento":1}]}'
		this.Send(identJson)
	}

	Armar(idISEP,senha,particoes,forcado := 0,zonasInibir := []) {
		cmdId := this.GetCommandId()
		if (Type(particoes) != "Array")
			particoes := [particoes]
		particoesStr := "[" . this.JoinArray(particoes,",") . "]"
		cmdObj := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"armar","password":"' . senha . '","forcado":' . forcado . ',"particoes":' . particoesStr
		if (Type(zonasInibir) = "Array" && zonasInibir.Length()) {
			inibirStr := "[" . this.JoinArray(zonasInibir,",") . "]"
			cmdObj .= ',"inibir":' . inibirStr
		}
		cmdObj .= '}]}]}'
		this.Send(cmdObj)
		AppendLog("Comando enviado: Armar id=" . cmdId)
	}

	Desarmar(idISEP,senha,particoes) {
		cmdId := this.GetCommandId()
		if (Type(particoes) != "Array")
			particoes := [particoes]
		particoesStr := "[" . this.JoinArray(particoes,",") . "]"
		cmdObj := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"desarmar","password":"' . senha . '","particoes":' . particoesStr . '}]}]}'
		this.Send(cmdObj)
		AppendLog("Comando enviado: Desarmar id=" . cmdId)
	}

	StatusParticoes(idISEP) {
		cmdId := this.GetCommandId()
		cmdObj := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"particoes"}]}]}'
		this.Send(cmdObj)
		AppendLog("Comando enviado: Particoes id=" . cmdId)
	}

	StatusZonas(idISEP) {
		cmdId := this.GetCommandId()
		cmdObj := '{"oper":[{"id":' . cmdId . ',"acao":"executar","idISEP":"' . idISEP . '","comando":[{"cmd":"zonas"}]}]}'
		this.Send(cmdObj)
		AppendLog("Comando enviado: Zonas id=" . cmdId)
	}

	JoinArray(arr,sep := ",") {
		out := ""
		for i,v in arr {
			if (i > 1)
				out .= sep
			out .= v
		}
		return out
	}
}

class ViawebCrypto {
	hAlg := 0
	hKey := 0
	ivSend := Buffer(16)
	ivRecv := Buffer(16)
	blockSize := 16

	__New(hexKey,hexIV) {
		key := this.HexToBytes(hexKey)
		iv := this.HexToBytes(hexIV)
		Loop 16 {
			NumPut("UChar",NumGet(iv,A_Index-1,"UChar"),this.ivSend,A_Index-1)
			NumPut("UChar",NumGet(iv,A_Index-1,"UChar"),this.ivRecv,A_Index-1)
		}

		result := DllCall("bcrypt\BCryptOpenAlgorithmProvider","Ptr*",&hAlg := 0,"WStr","AES","Ptr",0,"UInt",0,"UInt")
		if (result != 0)
			throw Error("BCryptOpenAlgorithmProvider falhou: " . Format("0x{:08X}",result))
		this.hAlg := hAlg

		chainMode := Buffer(StrPut("ChainingModeCBC","UTF-16") * 2)
		StrPut("ChainingModeCBC",chainMode,"UTF-16")

		result := DllCall("bcrypt\BCryptSetProperty","Ptr",this.hAlg,"WStr","ChainingMode","Ptr",chainMode,"UInt",chainMode.Size,"UInt",0,"UInt")
		if (result != 0)
			throw Error("BCryptSetProperty falhou: " . Format("0x{:08X}",result))

		result := DllCall("bcrypt\BCryptGenerateSymmetricKey","Ptr",this.hAlg,"Ptr*",&hKey := 0,"Ptr",0,"UInt",0,"Ptr",key,"UInt",key.Size,"UInt",0,"UInt")
		if (result != 0)
			throw Error("BCryptGenerateSymmetricKey falhou: " . Format("0x{:08X}",result))
		this.hKey := hKey
	}

	__Delete() {
		if (this.hKey)
			DllCall("bcrypt\BCryptDestroyKey","Ptr",this.hKey)
		if (this.hAlg)
			DllCall("bcrypt\BCryptCloseAlgorithmProvider","Ptr",this.hAlg,"UInt",0)
	}

	Encrypt(plainText) {
		plainBytes := this.StringToBytes(plainText)
		paddedSize := Ceil(plainBytes.Size / 16) * 16
		if (paddedSize == 0)
			paddedSize := 16

		paddedData := Buffer(paddedSize,0)
		Loop plainBytes.Size
			NumPut("UChar",NumGet(plainBytes,A_Index-1,"UChar"),paddedData,A_Index-1)

		encrypted := Buffer(paddedSize)
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar",NumGet(this.ivSend,A_Index-1,"UChar"),ivCopy,A_Index-1)

		result := DllCall("bcrypt\BCryptEncrypt","Ptr",this.hKey,"Ptr",paddedData,"UInt",paddedSize,"Ptr",0,"Ptr",ivCopy,"UInt",16,"Ptr",encrypted,"UInt",paddedSize,"UInt*",&bytesWritten := 0,"UInt",0,"UInt")
		if (result != 0)
			throw Error("BCryptEncrypt falhou: " . Format("0x{:08X}",result))

		Loop 16
			NumPut("UChar",NumGet(encrypted,paddedSize-16 + A_Index-1,"UChar"),this.ivSend,A_Index-1)

		return encrypted
	}

	Decrypt(encryptedBuffer) {
		dataSize := encryptedBuffer.Size
		if (Mod(dataSize,16) != 0)
			throw Error("Dados criptografados devem ter tamanho múltiplo de 16")

		lastBlock := Buffer(16)
		Loop 16
			NumPut("UChar",NumGet(encryptedBuffer,dataSize-16 + A_Index-1,"UChar"),lastBlock,A_Index-1)

		decrypted := Buffer(dataSize)
		ivCopy := Buffer(16)
		Loop 16
			NumPut("UChar",NumGet(this.ivRecv,A_Index-1,"UChar"),ivCopy,A_Index-1)

		result := DllCall("bcrypt\BCryptDecrypt","Ptr",this.hKey,"Ptr",encryptedBuffer,"UInt",dataSize,"Ptr",0,"Ptr",ivCopy,"UInt",16,"Ptr",decrypted,"UInt",dataSize,"UInt*",&bytesWritten := 0,"UInt",0,"UInt")
		if (result != 0)
			throw Error("BCryptDecrypt falhou: " . Format("0x{:08X}",result))

		Loop 16
			NumPut("UChar",NumGet(lastBlock,A_Index-1,"UChar"),this.ivRecv,A_Index-1)

		endPos := decrypted.Size
		Loop decrypted.Size {
			idx := decrypted.Size - A_Index
			b := NumGet(decrypted,idx,"UChar")
			if (b == 0x7D || b == 0x5D) {
				endPos := idx + 1
				break
			}
			if (b != 0)
				break
		}
		return StrGet(decrypted,endPos,"UTF-8")
	}

	HexToBytes(hexStr) {
		hexStr := StrReplace(hexStr," ","")
		len := StrLen(hexStr) // 2
		buf := Buffer(len)
		Loop len {
			byte := "0x" . SubStr(hexStr,(A_Index - 1) * 2 + 1,2)
			NumPut("UChar",Integer(byte),buf,A_Index-1)
		}
		return buf
	}

	StringToBytes(str) {
		len := StrPut(str,"UTF-8") - 1
		buf := Buffer(len)
		StrPut(str,buf,"UTF-8")
		return buf
	}
}

; ----------------- LOG E INTERFACE SIMPLES -----------------
AppendLog(msg) {
	global LOG_FILE
	ts := "[" . A_Now . "] "
	if (IsObject(msg))
		msg := msg.ToString()
	FileAppend(ts . msg . "`n", LOG_FILE)
	; exibir notificação curta
	TrayTip("Viaweb", msg, 4)
}

PollTimer() {
	global client
	if client && client.connected
		client.Poll()
}

; hotkeys para ações rápidas usando padrão ISEP e senha
F1:: {
	global client,ISEP_DEFAULT,SENHA_DEFAULT
	if (!client || !client.connected) {
		AppendLog("Não conectado.")
		return
	}
	try {
		client.Armar(ISEP_DEFAULT,SENHA_DEFAULT,[1])
	} catch Error as e {
		AppendLog("Erro ao enviar armar: " . e.Message)
	}
}

F2:: {
	global client,ISEP_DEFAULT,SENHA_DEFAULT
	if (!client || !client.connected) {
		AppendLog("Não conectado.")
		return
	}
	try {
		client.Desarmar(ISEP_DEFAULT,SENHA_DEFAULT,[1])
	} catch Error as e {
		AppendLog("Erro ao enviar desarmar: " . e.Message)
	}
}

F3:: {
	global client,ISEP_DEFAULT
	if (!client || !client.connected) {
		AppendLog("Não conectado.")
		return
	}
	try {
		client.StatusParticoes(ISEP_DEFAULT)
	} catch Error as e {
		AppendLog("Erro ao solicitar status particoes: " . e.Message)
	}
}

F4:: {
	global client,ISEP_DEFAULT
	if (!client || !client.connected) {
		AppendLog("Não conectado.")
		return
	}
	try {
		client.StatusZonas(ISEP_DEFAULT)
	} catch Error as e {
		AppendLog("Erro ao solicitar status zonas: " . e.Message)
	}
}

; ----------------- INICIALIZAÇÃO E START -----------------
try {
	client := ViawebClient(IP,PORTA,CHAVE,IV)
	client.Connect()
	AppendLog("Conectado ao VIAWEB Receiver em " . IP . ":" . PORTA)
	client.Identificar("AHK Monitor")
	SetTimer(PollTimer,POLL_INTERVAL_MS)
} catch Error as e {
	AppendLog("Erro inicial: " . e.Message)
}

OnExit(Exit(Shutdown,0))
Return

Exit(*) {
	global client
	SetTimer(PollTimer, 0)
	if client
		client.Disconnect()
	ExitApp()
}