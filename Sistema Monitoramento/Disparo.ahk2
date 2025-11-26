;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.0.4.6
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Moni Disparo Sonoro
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\timer.ico

#Requires AutoHotkey v2.0
#Warn All, Off
#SingleInstance Force
#NoTrayIcon

#Include libs\functions.ahk
#Include libs\Class\Notify.ahk
#Include libs\Class\WindowManager.ahk

If !FileExist('C:\Seventh\Backup\sirene.wav') {
	Try {
		FileInstall('\\192.9.100.187\Moni\Sons\sirene.wav', 'C:\Seventh\Backup\sirene.wav', 1)
	}
}

show_tray	:= 0
operador	:= Nr_Operador()
OnMessage 0x004A, readCommand
if(operador = '0') && A_IsCompiled
	ExitApp(0)

global g_lastNotifyGUI := ""
global g_lastNotifyID := ""
global soundFile := 'C:\Seventh\Backup\sirene.wav'
global defaultLayout := defaultLayoutRetrieval()

verificaEventos()

verificaEventos()	{
	global soundFile

	filter := ''
	if(operador!= 0)
		filter := ' OPERADORA = ' operador '`nAND'

	select := 
		(
			"SELECT`n"
			"	c.NOME,`n"
			"	s.DESCRICAO,`n"
			"	s.SETOR`n"
			"FROM CLIENTES c`n"
			"RIGHT join eventospendentes e`n"
			"	ON c.CODIGO = e.CODIGOCLIENTE`n"
			"LEFT join clientessetores s`n"
			"	ON e.CODIGOCLIENTE = s.CLIENTE`n"
			"WHERE" filter " s.SETOR = e.CODIGOSETOR`n"
			"	AND e.IDENTOCOR = 'E'`n"
			"	AND (e.CODIGOOCORRENCIA = 130 OR e.CODIGOOCORRENCIA = 992)`n"
			"	AND e.PRIORIDADE = 2`n"
			"	AND e.TIPODISPARO = 0`n"
			"	AND e.ATENDIMENTO IS NULL"
		)

	alarm := sql(select)

	if(show_tray)	{
		tray := A_TrayMenu
		tray.Delete()
		A_IconHidden := 0
	}
	Else
		A_IconHidden := 1
	opt :=	'BC=Red '
		.	'MON=Primary '
		.	'SHOW=Fade@500 '
		.	'HIDE=Fade@500 '
		.	'DG=1 '
		.	'DUR=5 '
		.	'TS=14 '
		.	'MS=11 '
		.	'MFO=bold '
		.	'BDR=black,5 '
		.	'theme=Rust'
	If IsObject(alarm)
		if(alarm.Length-1 > 0)	{
			if FileExist(soundFile) {
				try {
					SoundSetMute(0)
					SoundSetVolume(20)
					SoundPlay(soundFile)
				}
				;catch as err {
				;	MsgBox("Erro ao tocar som: " err.What, "Erro", 0x1010)
				;}
			}
			;else {
			;	MsgBox("Arquivo não encontrado: " soundFile, "Aviso", 0x1030)
			;}
			
			; Armazenar dados globais ANTES de criar a notificação
			global g_lastNotifyID, g_lastNotifyGUI
			g_lastNotifyID := SubStr(alarm[2][1], 1, 3) ' ' SubStr(alarm[2][2], 1, 7)

			g_lastNotifyGUI := Notify.Show( 
				alarm[2][1] '`n`tDisparo de Alarme!'
				, alarm[2][3] ' - ' SubStr(alarm[2][1], 1, 3) ' ' alarm[2][2]
				, 'icon!'
				, ''
				, showcamNotify
				, opt)
		}
	A_IconTip := 'Operador ' operador '`nÚltima Verificação: ' datetime()
	SetTimer verificaEventos, -6000
}

; Função callback global que será chamada ao clicar
showcamNotify(GuiCtrlObj, Info) {
	global g_lastNotifyGUI, g_lastNotifyID

	if FileExist('Showcam.ahk')
		Run('AutoHotkey.exe "Showcam.ahk" "' g_lastNotifyID '"')

	if FileExist('ShowCam.exe')
		Run('ShowCam.exe "' g_lastNotifyID '"')

	if (IsObject(g_lastNotifyGUI) && g_lastNotifyGUI.HasOwnProp('hwnd'))
		Notify.Destroy(g_lastNotifyGUI['hwnd'])
}

defaultLayoutRetrieval()	{
	wm := WindowManager()
	wm.filter := SysGetIPAddresses()[1] = '192.9.100.100' ? 'Monitor' : 'Monitor 1'
	for index, win in wm.GetAll() {
		layoutDefault := RegExReplace(win.title, SysGetIPAddresses()[1] = '192.9.100.100' ? 'Monitor:\s*' : "Monitor \d+:\s*", "")
	}
	return layoutDefault
}