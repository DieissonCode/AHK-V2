#Requires AutoHotkey v2.0

; Configurações iniciais
serverGuid := "{A1D60A4F-93F9-467A-878F-F5962A33F4E8}"  ; Valor simbólico
cameraId := 0           ; Valor simbólico
streamId := 0           ; Valor simbólico
baseUrl := "http://localhost"  ; Substitua pelo endereço real do servidor D-Guard
endpoint := baseUrl "/servers/" serverGuid "/cameras/" cameraId "/streams/" streamId "/native-video"

; Criar objeto para requisição HTTP
http := ComObject("WinHttp.WinHttpRequest.5.1")
http.Open("GET", endpoint, true)  ; true para requisição assíncrona
http.SetRequestHeader("Content-Type", "multipart/x-mixed-replace")  ; Ajuste conforme necessário
http.Send()

; Aguardar resposta inicial
http.WaitForResponse()

; Diretório temporário para salvar frames
tempDir := A_Temp "\DGuardFrames"
DirCreate(tempDir)
Run(tempDir)
; Contador para nomear os arquivos de frame
frameCount := 0

; Função para processar o stream
ProcessStream() {
    global http, tempDir, frameCount
    boundary := "--boundary"  ; Ajuste o boundary conforme especificado no cabeçalho Content-Type da resposta
    
    ; Ler o stream em partes
    while (http.ResponseStream) {
        ; Ler o próximo frame do stream
        frameData := http.ResponseBody  ; Obtém os dados binários do frame
        
        ; Verificar se há dados
        if (frameData.Length > 0) {
            frameCount++
            frameFile := tempDir "\frame_" frameCount ".bin"  ; Arquivo temporário
            
            ; Salvar o frame em um arquivo
            FileOpen(frameFile, "w").RawWrite(frameData, frameData.Length)
            
            ; Aqui você pode adicionar lógica para exibir o frame, por exemplo, usando um player externo
            ; Exemplo: Run("vlc.exe " frameFile)  ; Requer VLC instalado
			
			MsgBox
        }
        
        ; Pequena pausa para evitar sobrecarga
        Sleep(100)
    }
}

; Iniciar o processamento do stream
ProcessStream()

; Limpeza (opcional)
CleanUp() {
    global tempDir
    DirDelete(tempDir, 1)  ; Remove o diretório temporário e os arquivos
}