#Requires AutoHotkey v2.0
;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.0.3.4
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Sistema Monitoramento
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\ico\sistema monitoramento.ico
#SingleInstance	Force
Persistent
SetTitleMatchMode(2)
FileEncoding('UTF-8')
;	Include
	#Include ..\libs\functions.ahk
	#Include ..\libs\Class\Auth.ahk
	#Include ..\libs\Class\Dguard.ahk
	#Include ..\libs\Class\Email.ahk
	#Include ..\libs\Class\Http.ahk
	#Include ..\libs\Class\Json.ahk
	#Include ..\libs\Class\Notify.ahk
	#Include ..\libs\Class\Register.ahk
	#Include ..\libs\Class\Telegram.ahk
	#Include ..\libs\Class\Windows.ahk
;	Variáveis
	Global	tooltip_mode 	:=	0
		,	disable_hahaha	:=	0

	myMenu			:=	isMenu := subMenu := Admin := A_TrayMenu
	monitor			:=	SysGet(80)
	smk				:=	'\\fs\Departamentos\monitoramento\Monitoramento\Dieisson\SMK\'
	software		:=	'ASM'
	server			:=	'localhost'
	;'Monokai', 'tc=0xF8F8F2 mc=0xA6E22E bc=0x272822 bdr=0xE8F7C8 tf=Lucida Console mf=Tahoma',
	tray_bg_color	:=	'0x6d6d6d'
	_manha			:=	'070000'
	_tarde			:=	'190000'
	set_restore := '0'

	versão_sql	:= '
		(
			SELECT TOP(1) [version]
			FROM [ASM].[dbo].[Softwares]
			WHERE [name] = 'Sistema Monitoramento'
			ORDER BY [pkid] DESC
		)'
	versão_sql	:=	sql(versão_sql)[2][1]

	colunas := '
		(
			SELECT
				[descricao]
			FROM
				[ASM].[dbo].[_gestao_sistema]
			WHERE
				[funcao] = 'operador'
			OR
				[funcao] = 'facilitador'
			ORDER BY
				[descricao]
		)'
		colunas	:= sql(colunas)

	Auto_Update()
	principais	:= Map()

	Loop colunas.Length-1
		principais[ colunas[A_Index+1][1] ] := '1'
;	Load Gui - Notify
	mStart := Notify.Show('Sistema Monitoramento  ' versão_sql ' | ' FormatTime( modificado := FileGetTime(A_ScriptFullPath, 'M'), 'yyyy-MM-dd HH:mm:ss')
						, 'Iniciando sistema',,,
						, 'theme=Monokai style=round dur=0 prog=w' A_ScreenWidth ' dgc=0 MAli=Right')
;	Prepara os diretórios e arquivos necessários
	Notify.Update( mStart, 'msg=Preparando Diretórios,prog=10'), DirCreate('C:\Seventh\backup'), DirCreate('C:\Seventh\Backup\ico')
	Notify.Update( mStart, 'msg=Preparando Ícones,prog=20')
	FileInstall(SMK '\Ico\operador.ico',	'C:\Seventh\Backup\ico\operador.ico',	1)
	FileInstall(SMK '\Ico\2contatos.ico',	'C:\Seventh\Backup\ico\2contatos.ico',	1)
	FileInstall(SMK '\Ico\2update.ico',		'C:\Seventh\Backup\ico\2update.ico',	1)
	FileInstall(SMK '\Ico\2mail.ico',		'C:\Seventh\Backup\ico\2mail.ico',		1)
	FileInstall(SMK '\Ico\2lembedit.ico',	'C:\Seventh\Backup\ico\2LembEdit.ico',	1)
	FileInstall(SMK '\Ico\2resp.ico',		'C:\Seventh\Backup\ico\2resp.ico',		1)
	FileInstall(SMK '\Ico\admin.ico',		'C:\Seventh\Backup\ico\2admin.ico',		1)
;	Timers
	Notify.Update(mStart, "msg=Inicializando Timer's,prog=30")

	if( A_UserName != 'Alberto' )	{
		SetTimer((*) => close_messageBox(0), 1000)
		SetTimer((*) => auto_restore(0), 2000)
	}

	if ( A_UserName != "Alberto" ) {
		SetTimer((*) => close_messageBox(0), 1000)										;	Define o tema do dguard ao iniciar, se houver disparo no iris gera o disparo sonoro e fecha janelas desnecessárias do dguard
		SetTimer((*) => talkto(), 30000)
		SetTimer((*) => auto_restore(0), 2000)											;	Verifica se é 07:00 ou 19:00 para efetuar o restauro dos layouts das colunas
		SetTimer(mail_check, principais.Has( SysGetIPAddresses()[1] ) ? 60000 : 'Off')	;	Verifica novos e-mails
	}
;	TrayMenu
	Notify.Update(mStart, "msg=Preparando Menu's,prog=40")
	Switch	{	;	tray menu standard
		Case	A_UserName != 'dsantos':
			myMenu.Delete()
	}
	myMenu.SetColor(tray_bg_color,1)
	NoAction := (*) => {} ; //	TEMP Usado apenas para não gerar erros no menu, remover quando estiver tudo OK
	; Menu	ADMIN
		Notify.Update(mStart, "msg=Preparando Menu de Admin,prog=50")
		sub_admin	:=	Menu(), sub_admin.SetColor(tray_bg_color, 1)
		admin.Add('Administração', NoActioN), admin.Add('Administração', sub_admin)
		sub_admin.Add('Editar Dados das Unidades', dadosUnidades)
		sub_admin.Add('Reiniciar Camera', ShowIPRebootGui)

		admin.SetIcon('Administração', 'C:\Seventh\Backup\ico\2admin.ico')
		sub_admin.SetIcon('Editar Dados das Unidades', 'C:\Seventh\Backup\ico\2LembEdit.ico')
		sub_admin.SetIcon('Reiniciar Camera', 'C:\Seventh\Backup\ico\2update.ico')

	; Menu	PADRÃO
		Notify.Update(mStart, "msg=Preparando Menu de Operador,prog=60")
		myMenu.Add()
		myMenu.Add('Colaboradores da Cotrijal', Colaboradores)
		myMenu.Add('E-mails  - Chamados - Registros', Emails)
		myMenu.Add('Relatórios e Eventos', Eventos)
		myMenu.Add('Informações das Unidades', Unidades)

		myMenu.SetIcon('Colaboradores da Cotrijal', 'C:\Seventh\Backup\ico\2contatos.ico')
		myMenu.SetIcon('E-mails  - Chamados - Registros', 'C:\Seventh\Backup\ico\2mail.ico')
		myMenu.SetIcon('Relatórios e Eventos', 'C:\Seventh\Backup\ico\2LembEdit.ico')
		myMenu.SetIcon('Informações das Unidades', 'C:\Seventh\Backup\ico\2resp.ico')

	; Executa programas e define operador, coluna e facilitador
	Notify.Update(mStart, "msg=Inicializando programas padrões e definindo elevação do sistema,prog=70")
	if	principais.Has( SysGetIpAddresses()[1] )	{
		if !ProcessExist("AutoCorretor.exe")
			executar( "AutoCorretor" )
		if !ProcessExist("MDKah.exe")
			executar( "MDKah" )
		if !ProcessExist("Agendamentos.exe")
			executar( "Agendamentos" )
		eh_operador := 1
	}
	if( SysGetIpAddresses()[1] = "192.9.100.100" )
		eh_facilitador := 1
;	Pre-load de dados

	preload()
	Notify.Update(mStart, "msg=Limpando registro temporário,prog=95")
	TRY	Reg.regDelete( "HKCU\SOFTWARE\Seventh\_temp" )
	Notify.Update(mStart, 'msg=Inicialização completada com sucesso,prog=100'), Sleep(1500), Notify.Destroy(mStart['hwnd'])
	Return
;	Atalhos
	F1::{			;	Eventos
		If	eh_operador
			executar( "Relatórios" )
	}

	^F10::{			;	Adiciona E-mails e chamados
		If !WinActive( "Visual Studio Code" ) && (eh_operador || eh_facilitador )
			executar( "Lançador de E-Mails" )
	}

	F10::{			;	E-Mails, Chamados e registros
		If	eh_operador
			executar( "Agenda Operadores" )
	}

	~F11::{			;	Salva layout temporário - Deleta ao se restaurar
		If	Reg.regExist("HKCU\SOFTWARE\Seventh\_temp", "_BackupAtualizado") {
			Notify.Show('Iniciando procedimento de restauro de layout do Operador'
					,	'Por favor aguarde...',,,
					,	'theme=!Dark dur=0 pos=tc MAli=center')
			ProcessClose('WatchdogServices.exe'), ProcessClose('Watchdog.exe'), ProcessClose('DGuard.exe'), ProcessClose('Player.exe')
			Reg.regDelete( "HKCU\SOFTWARE\Seventh\DguardCenter" )
			runCmd( "REG COPY HKCU\SOFTWARE\Seventh\_temp HKCU\SOFTWARE\Seventh\DguardCenter /s /f" )
			check_registry := 0
			Loop {
				Sleep 1000
				check_registry++
				if	Reg.regExist("HKEY_CURRENT_USER\SOFTWARE\Seventh\DguardCenter\WorkspaceManager", "WorkspaceToRestore")
					Break
				Else if( check_registry > 9 ) {		
					Reg.regDelete( "HKCU\SOFTWARE\Seventh\DguardCenter" )
					runCmd( "REG COPY HKCU\SOFTWARE\Seventh\_temp HKCU\SOFTWARE\Seventh\DguardCenter /s /f" )
					Sleep(3000)
					Break
				}	
			}
			executar( "Dguard","C:\Seventh\DGuardCenter\" )
			Reg.regDelete( "HKCU\SOFTWARE\Seventh\_temp" )
			Notify.Update(mStart, 'tempSave', 'Restauro de Layout concluído')
		}
		Else if !WinActive( "ahk_exe Painel de Monitoramento.exe" ) && !Reg.regExist("HKCU\SOFTWARE\Seventh\_temp", "_BackupAtualizado")	{
			Notify.Show('Iniciando procedimento de salvamento de layout temporário'
					,	'Por favor aguarde...',,,
					,	'theme=!Dark dur=0 pos=tc MAli=center')
			check_registry := 0
			Loop 7	{
				check_registry++
				save_temp()
				Sleep(100)
				If	Reg.regExist( "HKCU\SOFTWARE\Seventh\_temp", "_BackupAtualizado" )
					Break
				Else if( check_registry > 5 )	{
					Notify.Destroy('tempSave')
					Msgbox("Falha ao salvar, tente executar o Sistema Monitoramento como administrador.")
					Return
				}
			}
			Notify.Update(mStart, 'tempSave', 'Salvamento temporário do layout concluído.')
			restore_layout(0)
		}
		Sleep(2000)
		Notify.Destroy('tempSave')
	}

	#Q::{
		Shutdown(6)
	}

	^ins::{
		Global tooltip_mode, disable_hahaha
		SetTitleMatchMode(2)
		If WinActive( "TeamViewer" )
			Return
		pass := ""
		pass := InputBox('Comando Sistema Monitoramento',,'Password* h100')
		Switch	pass.Value	{
			Case "":
				return

			Case "infos":
				if IsSet(aaa)
					A_Clipboard := aaa

			Case "tooltip":
				tooltip_mode := !tooltip_mode
				Switch	tooltip_mode	{
					Case 1:
						Notify.Show( 'Tooltips'
									, 'Tooltips ativados',,,
									, 'theme=Monokai style=round dur=2 dgc=0 MAli=Right TAli=Center pos=ct')
					Default:
						Notify.Show( 'Tooltips'
									, 'Tooltips desativados',,,
									, 'theme=Monokai style=round dur=2 dgc=0 MAli=Right TAli=Center pos=ct')
						ToolTip()
				}

			Case "close", "exit":
				Notify.Show(	'Sistema Monitoramento'
							,	'Encerrando o sistema...',,,
							,	'theme=Monokai style=round dur=2 dgc=0 MAli=Center TAli=Center pos=CT')
							Sleep(2000)
				ExitApp

			Case "toasty":
				toasty()

			Case "synergy":
				Notify.Show(	'Sistema Monitoramento'
							,	'Iniciando Synergy...',,,
							,	'theme=Monokai style=round dur=2 dgc=0 MAli=Center TAli=Center pos=CT')
				Run('C:\Program Files\Synergy\Synergy_.exe')

			Case "hahaha":
				disable_hahaha := !disable_hahaha
				switch disable_hahaha {
					case 1:
						Notify.Show(	'Sistema Monitoramento'
									,	'Desabilitando "hahaha"...',,,
									,	'theme=Monokai style=round dur=2 dgc=0 MAli=Center TAli=Center pos=CT')
						
					default:
						Notify.Show(	'Sistema Monitoramento'
									,	'Habilitado "hahaha"',,,
									,	'theme=Monokai style=round dur=2 dgc=0 MAli=Center TAli=Center pos=CT')
						
				}

			Case "debug":
				ListVars()

			Case "dia":
				auto_restore(1)

			Case "noite":
				auto_restore(2)

			Case "save":
				;	Gera arquivo reg de segurança, para uso manual ou em caso de máquina formatada
				mSave := Notify.Show( 'Salvando Registro'
									, 'Em Processo de salvamento de layouts, aguarde...',,,
									, 'theme=Monokai style=round dur=0 prog=w500 dgc=0 MAli=Right TAli=Center pos=CT' )
				runCmd( "reg export HKCU\Software\Seventh\DGuardCenter " smk "registros\default\" SysGetIpAddresses()[1] "_NEW.reg /y" )
				Notify.Update(mSave, 'prog=25,msg=Registro temporário exportado,dur=1')
				start_export := A_Now
				while !FileExist( smk "registros\Default\" SysGetIpAddresses()[1] "_NEW.reg" )
					if(( A_Now - start_export ) > 4) {
						MsgBox('Falha ao salvar o registro de backup.`nTente executar o Sistema Monitoramento como administrador e salvar o registro novamente.')
						Return
					}
				;	Substituição do arquivo de segurança
				Notify.Update(mSave,'msg=Deletando arquivo de registro antigo,prog=25')
				FileDelete(smk 'registros\Default\' SysGetIpAddresses()[1] '.reg')
				Notify.Update(mSave,'msg=Criando arquivo de registro novo,prog=50')
				FileMove(smk 'registros\Default\' SysGetIpAddresses()[1] '_NEW.reg',smk 'registros\Default\' SysGetIpAddresses()[1] '.reg')
				start_check := A_Now
				while !FileExist( smk "registros\Default\" SysGetIpAddresses()[1] ".reg" )
					if(( A_Now - start_check ) > 4) {
						MsgBox('Falha ao substituir o registro de backup.`nTente executar o Sistema Monitoramento como administrador e salvar o registro novamente.')
						Return
					}
				;	Registro de backup para restauro
				;	Deletando registro antigo
				if( Reg.regDelete( "HKCU\SOFTWARE\Seventh\_save" ) = "Fail" ) && Reg.regExist( "HKCU\SOFTWARE\Seventh\", "_save" ) {
					Notify.Update(mSave,'msg=Falha ao remover registro antigo do regedit.,prog=100,dur=2')
					Notify.Destroy(mSave['hwnd'])
					Msgbox('Falha ao deletar o registro antigo, reinicie o Sistema Monitoramento em modo Administrativo.`nApós fechar essa tela, o sistema monitoramento será encerrado.')
					Return
				}
				;	Salvando registro
				Notify.Update(mSave,'msg=Salvando registro de backup,prog=75')
				runCmd( 'REG COPY HKCU\SOFTWARE\Seventh\DguardCenter HKCU\SOFTWARE\Seventh\_save /s /f' )
				if(A_UserName = 'dsantos')
					runCmd( 'REG COPY HKCU\SOFTWARE\Seventh\DguardCenter HKCU\SOFTWARE\Seventh\' A_UserName ' /s /f' )
				regWrite('REG_SZ' , 'HKCU\SOFTWARE\Seventh\_save', '_BackupAtualizado', datetime())
				restore_period	:=	A_Hour >= 7 && A_Hour <= 19 ? 'dia' : 'noite'
				Notify.Update(mSave,'msg=Registro salvo com sucesso!,prog=100,dur=1.5')
				Notify.Destroy(mSave['hwnd'])
				executar("Dguard", "C:\Seventh\DGuardCenter\")
				;	Remove backups mais antigos
				Loop Reg, 'HKEY_CURRENT_USER\SOFTWARE\Seventh\_Backup\Default', 'K'
					reg_sort .= A_LoopRegName "`n"

				Sort(reg_sort, 'Desc')
				old_regs := StrSplit(reg_sort, "`n")

				Loop	old_regs.Length-1
					if( A_index < 5 )
						Continue
					Else
						Reg.regDelete( 'HKEY_CURRENT_USER\SOFTWARE\Seventh\_Backup\Default\' old_regs[A_Index] '\' )
				;	Backup's
				runCmd( 'REG COPY HKCU\SOFTWARE\Seventh\DguardCenter HKCU\SOFTWARE\Seventh\_Backup\Default\' a_now ' /s /f' )

			Case 'reload':
				Reload

			Default:
				MsgBox('Este comando não existe = "' pass.Value '"', 'Comando Inexistente')
				Return

		}

	}

	^g::	{
		Global	monitor_count
		SetTitleMatchMode(2)
		If WinActive( "TeamViewer" )
			Return
		yger := 0
		if	!WinActive('ahk_group ahk_class TfmGerenciador')	{
			Try WinShow('ahk_class TfmGerenciador')
			if(monitor_count = 5)
				yger := "-1800"
			Try WinMove(5,	yger,,,'ahk_class TfmGerenciador')
			Try WinActivate('ahk_class TfmGerenciador')
			Try WinMove(400, yger,,,'ahk_class TfmAutenticacao')
			Try WinMove(400, yger,,,'ahk_class TfmConfigSistema')
			Try WinMove(400, yger,,,'ahk_class TfmUsuarios')
			Try WinMove(400, yger,,,'ahk_class TfmAvisos')
			Try WinMove(400, yger,,,'ahk_class TfmConfigLegenda')
		}
		else	{
			Try WinHide('ahk_class TfmGerenciador')
			Try WinMove(5, yger,,,'ahk_class TfmGerenciador')
			Try WinMove(400,yger,,,'ahk_class TfmAutenticacao')
			Try WinMove(400,yger,,,'ahk_class TfmConfigSistema')
			Try WinMove(400,yger,,,'ahk_class TfmUsuarios')
			Try WinMove(400,yger,,,'ahk_class TfmAvisos')
			Try WinMove(400,yger,,,'ahk_class TfmConfigLegenda')
		}
		check_dns()
	}

	^u::update()	;	Update:
		update()	{
			mUpdate := Notify.Show('Sistema Monitoramento'
						, 'Iniciando Update dos Módulos e do Sistema',,,
						, 'theme=Monokai style=round dur=0 prog=w' A_ScreenWidth ' dgc=0 MAli=Center TAli=Center')
			SetTitleMatchMode(2)
			If	WinActive( "TeamViewer" )
				Return
			Notify.Update(mUpdate, 'msg=Update em andamento,prog=50')
			SetTimer((*) => close_messageBox(0), 0)
			Notify.Update(mUpdate, 'msg=Update Finalizado,prog=100,dur=1')
			executar('update', 'C:\Seventh\backup\')
			ExitApp()
		}

	^Numpad0::{		;	
		SetTitleMatchMode(2)
		If	WinActive( "TeamViewer" )
			Return
		pid := pidListFromName( "synergyc.exe" )
		if( pid.Length > 1 ) {
			mShare := Notify.Show('Sistema Monitoramento'
								, 'Desativando compartilhamento de coluna',,,
								, 'theme=Monokai style=round dur=0 prog=w' A_ScreenWidth ' dgc=0 MAli=Center TAli=Center')
			Loop	pid.Length
				if	ProcessExist(pid[A_Index])
					processClose(pid[A_Index])
		}
		Else {
			mShare := Notify.Show('Sistema Monitoramento'
								, 'Ativando compartilhamento de coluna',,,
								, 'theme=Monokai style=round dur=0 prog=w' A_ScreenWidth ' dgc=0 MAli=Center TAli=Center')
			try	Run('C:\Program Files\Synergy\synergy_connect.exe')
			Catch {
				if	!fileExist( "C:\Program Files\Synergy\synergy_connect.exe" ) {
					synergyConnect	:= '
						(
							SELECT TOP(1)
								[BIN],
								[NAME]
							FROM
								[ASM].[DBO].[SOFTWARES]
							WHERE
								[NAME] = 'SYNERGY_CONNECT'
							AND
								[AHK_VERSION] = '2'
							ORDER BY
								[DATE]
							DESC
						)'
					s_connect := sql(synergyConnect)
					s_c_ref	:=	s_connect[2][1]
					base64.FileDec( &s_c_ref, "C:\Program Files\Synergy\synergy_connect.exe" )
					Loop	
						if	fileExist( "C:\Program Files\Synergy\synergy_connect.exe" )
							break
				}
				Notify.Update(mShare,'msg=Executando Synergy,prog=99,dur=2')
				try	Run('C:\Program Files\Synergy\synergy_connect.exe')
				Notify.Update(mShare,'msg=Finalizando,prog=100,dur=1')
			}
		}
		Notify.Destroy(mShare['hwnd'])
	}

	; Preset's
	#Hotif WinActive('ahk_class TfmMonitor')
		Numpad0::Dguard.Preset(10)
		Numpad1::Dguard.Preset(1)
		Numpad2::Dguard.Preset(2)
		Numpad3::Dguard.Preset(3)
		Numpad4::Dguard.Preset(4)
		Numpad5::Dguard.Preset(5)
		Numpad6::Dguard.Preset(6)
		Numpad7::Dguard.Preset(7)
		Numpad8::Dguard.Preset(8)
		Numpad9::Dguard.Preset(9)
	#Hotif

	; Atalhos de Layouts
		^b::restore_layout('Padrão')
		^Numpad1::restore_layout('Dia')
		^Numpad2::restore_layout('Noite')
		^Numpad3::restore_layout('Todas')

	check_dns()	{
		dns := Map()
		Loop	5
			dns.%A_Index% := DNSQuery("vdm0" A_Index)
		runCmd("ipconfig /flushdns")
		Loop	5
			if( DNSQuery("vdm0" A_Index) != dns.%A_Index% ) {
				ProcessClose('WatchdogServices.exe')
				ProcessClose('Watchdog.exe')
				ProcessClose('DGuard.exe')
				ProcessClose('Player.exe')
				executar("Dguard", "C:\Seventh\DGuardCenter\")
				Reload
			}
	}

;	Operadores
	; Feedback_rel(*)	=> executar("inbox")
	Unidades(*)		=> executar("Informações das Unidades")
	Emails(*)		=> executar("Agenda Operadores")
	Eventos(*)		=> executar("Relatórios")
	Colaboradores(*)=> executar("Colaboradores")
;	Gerenciamento
	dadosUnidades(*)	=> executar("Gestor de Unidades")
	adicionar_email(*)	=> executar("Agenda")
;	Restauro dos layouts
	auto_restore(set_restore)	{
		Global	disable_hahaha
			,	_manha
			,	_tarde
			,	o
			,	n
			,	SMK
		ListLines(0)
		If(( A_Hour A_Min A_Sec > _manha ) && ( A_Hour A_Min A_Sec < _manha+10 )) || (( A_Hour A_Min A_Sec > _tarde ) && ( A_Hour A_Min A_Sec < _tarde+10 )) || set_restore {
			mSelfRestore := Notify.Show('Sistema Monitoramento'
									,	'Iniciando Auto Restauração do Sistema',,,
									,	'theme=Monokai style=round dur=0 prog=w500 dgc=0 MAli=Center TAli=Center pos=CT')
			restore_period	:=	set_restore = 1	?	"Dia"
							:	set_restore = 2	?	"Noite"
							:	(A_Hour >= 7 && A_Hour < 19 ? "Dia" : "Noite")
			SetTimer((*) => auto_restore(0), 0)
			restore_layout(restore_period)
			ListLines(1)
			Notify.Update(mSelfRestore, 'msg=Iniciand Atualização do Sistema Monitoramento e seus Módulos,prog=100,dur=2.5')
			Sleep(3000)
			update()
			Return

		}

		if	!IsSet(disable_hahaha) {
			TRY n := WinGetTitle('A')
			try if( n != o )	{
				o	:= n
				if	InStr( n , "Web Filter Violation" )
					SoundPlay(SMK '\hahaha.wav')
			}
		}
		ListLines(1)
	}

	restore_layout(periodo)	{
		if(periodo = 'Padrão')
			if( MsgBox('Tem certeza que deseja restaurar os layouts para o padrão?',,4) = 'No')
				Return
		
		SetTitleMatchMode(2)
		if(SysGetIpAddresses()[1] = "192.9.100.100" || (WinActive( "TeamViewer" ) && (SysGetIpAddresses()[1] = "192.9.100.100")))
			If MsgBox('Tem certeza que quer exibir o layout ' periodo ' na máquina do facilitador?',,4) = 'No'
				Return
		mRestore := Notify.Show('Sistema Monitoramento'
							,	'Alterando Layouts - ' periodo,,,
							,	'theme=Monokai style=round dur=0 dgc=0 MAli=Center TAli=Center')
		Global	monitor
			,	workstation
			,	layout
		runCmd("ipconfig /flushdns")
		If	!RegRead( "HKCU\SOFTWARE\Seventh\_save" , "_BackupAtualizado" ) {														;	Se não existir registro
			if	FileExist( smk "\registros\Default\" SysGetIPAddresses()[1] ".reg" ) {
				runCmd(" reg import " smk "\registros\Default\" SysGetIPAddresses()[1] ".reg" )
				Email.Send('dsantos@cotrijal.com.br', 'Sistema Monitoramento ' SysGetIPAddresses()[1], 'Arquivo de registro padrão inexistente.')
				MsgBox	"IMPORTANDO ARQUIVO .REG`nLAYOUT DE EXIBIÇÃO DO PERÍODO PRECISA SER SALVO!!!`n`n"
					.	"O Layout atual será salvo provisoriamente como padrão para o período " periodo "!"
			}
			runCmd( "REG COPY HKCU\SOFTWARE\Seventh\DguardCenter HKCU\SOFTWARE\Seventh\_save /s /f" )								;	ATUALIZA backup pois não existia
			RegWrite(FormatTime(, 'yyyy-MM-dd HH:mm:ss'), 'REG_SZ', 'HKCU\SOFTWARE\Seventh\_save', '_BackupAtualizado')				;	atualiza marca de atualização

		}

		if( periodo = 'Dia' || periodo = 'Noite' || periodo = 'Todas')	{
			Loop	monitor.Length
				Try Notify.Update(mRestore, 'msg=Layouts alterados - ' periodo ',dur=2'),  Http.Put( "http://localhost:8081/api/virtual-matrix/workstations/" workstation "/monitors/" monitor[A_Index] "/layout", token, '{"layoutGuid":"' layout[periodo A_Index] '"}' )
		}
		Else {
			new_instance( "#NoTrayIcon`nFileRemoveDir, C:\Seventh\DGuardCenter\Dados\Servidores,1`nExitapp" )	;	limpa gravações locais
			Notify.Update(mRestore, 'msg=Fechando processos do D-Guard,dur=2'),	ProcessClose('WatchdogServices.exe'), ProcessClose('Watchdog.exe'), ProcessClose('DGuard.exe'), ProcessClose('Player.exe')
			Notify.Update(mRestore, 'msg=Deletando registro atual,dur=2'),		Reg.regDelete( "HKCU\SOFTWARE\Seventh\DguardCenter" ), Sleep(3000)
			Notify.Update(mRestore, 'msg=Definindo registro Padrão,dur=2'),		runCmd( "REG COPY HKCU\SOFTWARE\Seventh\_save HKCU\SOFTWARE\Seventh\DguardCenter /s /f" )
			Notify.Update(mRestore, 'msg=Executando D-Guard,dur=2'),			executar( "Dguard", "C:\Seventh\DGuardCenter" )
			Notify.Update(mRestore, 'msg=Restauro efetuado - ' periodo ',dur=2')
		}
		Send('{LCtrl Up}'), SoundSetVolume(Random(20, 30))
		Notify.Destroy(mRestore['hwnd'])
	}
;	Funções
	close_messageBox(*)	{
		ListLines(0)
		try title := WinGetTitle('A')
		if((	A_UserName != "dsantos"
			&&	A_UserName != "ddiel" 
			&&	A_UserName != "egraff" )
			&&	InStr( title, "nascotrijal01" ) ) {

			WinClose(title)
			Email.Send( "dsantos@cotrijal.com.br", "Tentativa de Acesso ao NAS", "Tentativa de acesso ao NAS em:`n`t" DateTime() "`n`tIp " SysGetIpAddresses()[1] "`nUsuário:`t" A_UserName )

		}
		if	WinExist('Selecione o tema de sua preferência')
			WinClose('Selecione o tema de sua preferência')

		if	WinExist('Sistema Monitoramento.exe')	{
			WinActivate('Sistema Monitoramento.exe')
			couldnot := ControlGetText( 'static1',	'Sistema Monitoramento.exe')
			if	instr(couldnot,"could")	{
				ControlClick('Button2', 'Sistema Monitoramento.exe',, 'Left')
				Send('{tab}{Enter}')
				WinClose('Sistema Monitoramento.exe')
			}
		}
		ListLines(1)

	}

	mail_check() => (email_notificador())

	preload()	{
		Notify.Update(mStart, "msg=Fazendo pré carga das informações do sistema,prog=80")
		workspace		:=	Dguard.workspaces()
		If	!workspace.Count
			Return
		workstation := 0
		Global	monitor_count	:=	MonitorGetCount()
			,	monitor			:=	[]
			,	workstation		:=	workspace['workstations'][1]['guid']
			,	info			:=	Dguard.layouts()
			,	layout			:=	Map()
		BlockInput('Send')
		Notify.Update(mStart, "msg=Carregando dados do D-Guard,prog=85")

		monitor := []  ; Ensure monitor is initialized as an array
		monitor_count := Min(monitor_count = 5 ? 4 : monitor_count, workspace['workstations'][1]['monitors'].Length)
		Loop monitor_count
			monitor.Push(workspace['workstations'][1]['monitors'][A_Index]['guid'])

		Loop	info.Length {
			if(	layout.Count = 12 )
				Break
			Switch info[A_index]['name'] {
				case "_Layout1":
					layout["Dia1"] := info[A_index]['guid']
				case "_Layout2":
					layout["Dia2"] := info[A_index]['guid']
				case "_Layout3":
					layout["Dia3"] := info[A_index]['guid']
				case "_Layout4":
					layout["Dia4"] := info[A_index]['guid']
				case "_NLayout1":
					layout["Noite1"] := info[A_index]['guid']
				case "_NLayout2":
					layout["Noite2"] := info[A_index]['guid']
				case "_NLayout3":
					layout["Noite3"] := info[A_index]['guid']
				case "_NLayout4":
					layout["Noite4"] := info[A_index]['guid']
				case "_Todas1":
					layout["Todas1"] := info[A_index]['guid']
				case "_Todas2":
					layout["Todas2"] := info[A_index]['guid']
				case "_Todas3":
					layout["Todas3"] := info[A_index]['guid']
				case "_Todas4":
					layout["Todas4"] := info[A_index]['guid']
			}
		}
		Notify.Update(mStart, "msg=Dados do D-Guard carregados,prog=90")
		BlockInput('Off')

	}

	talkto()	{
		if( (SubStr(A_Now, 1, 10) > 185900 && SubStr(A_Now, 1, 10) < 190011) || (SubStr(A_Now, 1, 10) > 065900 && SubStr(A_Now, 1, 10) < 070011) )
			Return
		talk_operador :=	SysGetIpAddresses()[1]	= "192.9.100.102" ? "1"
						:	SysGetIpAddresses()[1]	= "192.9.100.106" ? "2"
						:	SysGetIpAddresses()[1]	= "192.9.100.109" ? "3"
						:	SysGetIpAddresses()[1]	= "192.9.100.114" ? "4"
						:	SysGetIpAddresses()[1]	= "192.9.100.118" ? "5"
						:	SysGetIpAddresses()[1]	= "192.9.100.123" ? "6"
						:	SysGetIpAddresses()[1]	= "192.9.100.100" ? "0"
						:	""
		if(talk_operador = "")
			Return

		s	:= 
			(
			"SELECT`n"
			"	[id]`n"
			"	,[command]`n"
			"FROM`n"
			"	[Telegram].[dbo].[command]`n"
			"WHERE`n"
			"	[return] IS NULL `n"
			"AND`n"
			"	[command] LIKE '[[]" talk_operador "]%'`n"
			)
		talk_messages := sql(s)

		Loop	talk_messages.Length-1 {
			id_executado	:=	talk_messages[A_Index+1][1]
			message			:=	StrSplit( talk_messages[A_index+1][2], "][" )
			master_volume	:= SoundGetVolume()
			SoundSetVolume(100)
			Sleep(1000)
			Windows.speak( message[2] )
			SoundSetVolume(master_volume)
			executado_as := datetime()
			Telegram.SendMessage( "Mensagem executada para o operador " RegExReplace(message[1], '[[]') " " executado_as, "reply_to_message_id=" message[3], "chat_id=" message[4] )
			u :=
				(
				"UPDATE [Telegram].[dbo].[command]`n"
				"SET [return] = 'Executado " executado_as "'`n"
				"WHERE [id] = '" id_executado "'`n"
				)
			sql(u,1)

		}
	}

	ShowIPRebootGui(*) {
		global	Octet1, Octet2, Octet3, Octet4
			,	RebootGui := Gui(,"Reiniciar PTZ")
		RebootGui.BackColor := "c9BACC0"
		RebootGui.SetFont("c374658", "Bold")
		RebootGui.Add("Text", "xm y10 cWhite -Wrap", "Insira o IP:")
		RebootGui.Add("Edit", "x+10 y7 w40 Limit3").OnEvent("Change", ValidarIP)
		RebootGui.Add("Text", "x+5 cWhite -Wrap", ".")
		RebootGui.Add("Edit", "x+5 w40 Limit3").OnEvent("Change", ValidarIP)
		RebootGui.Add("Text", "x+5 cWhite -Wrap", ".")
		RebootGui.Add("Edit", "x+5 w40 Limit3").OnEvent("Change", ValidarIP)
		RebootGui.Add("Text", "x+5 cWhite -Wrap", ".")
		RebootGui.Add("Edit", "x+5 w40 Limit3").OnEvent("Change", ValidarIP)
		RebootGui.SetFont("Norm")
		RebootGui.Add("Button", "xm y40 w280 Default", "Reiniciar PTZ").OnEvent("Click", ExecutarComando)
		RebootGui.Show("w300 h80")

	}
	
	ValidarIP(GuiCtrlObj, Info) {
		global	Octet1, Octet2, Octet3, Octet4
		,		RebootGui := GuiCtrlObj.Gui
		RebootGui.Submit(0)
		switch {
			case GuiCtrlObj.ClassNN  = "Edit1":
				Octet1 := GuiCtrlObj.Text
			case GuiCtrlObj.ClassNN  = "Edit2":
				Octet2 := GuiCtrlObj.Text
			case GuiCtrlObj.ClassNN  = "Edit3":
				Octet3 := GuiCtrlObj.Text
			case GuiCtrlObj.ClassNN  = "Edit4":
				Octet4 := GuiCtrlObj.Text
		}

		currentControl := GuiCtrlObj.ClassNN
		if (currentControl != "" && GuiCtrlObj.Text != "") {
			If	IsNumber(GuiCtrlObj.Text) && !InStr(GuiCtrlObj.Text, ".")	{
				if (GuiCtrlObj.Text < 0 || GuiCtrlObj.Text > 255) {
					currentValue := RebootGui[currentControl].Value
					RebootGui[currentControl].Value := SubStr(currentValue, 1, -1)
					Send("{End}")
					MsgBox("O valor de ip deve estar entre 0-255!", "Erro", 16)
					return
				}
			}
			else {
				RebootGui.Submit(0)
				RebootGui := GuiCtrlObj.Gui
				currentControl := GuiCtrlObj.ClassNN
				currentValue := RebootGui[currentControl].Value
				RebootGui[currentControl].Value := RegExReplace(currentValue, "\D")
				Send("{End}")
				if(SubStr(currentValue, -1) = "." && StrLen(currentValue)-1 >= 1)
					RebootGui["Edit" . (SubStr(currentControl, -1) + 1)].Focus()
			}
		}

		if (StrLen(GuiCtrlObj.Text) = 3 && GuiCtrlObj.Text >= 0 && GuiCtrlObj.Text <= 255 && currentControl = "Edit" . SubStr(currentControl, -1))
			RebootGui[SubStr(currentControl, -1) < 4 ? "Edit" . (SubStr(currentControl, -1) + 1) : "Button1"].Focus()
	}	

	ExecutarComando(GuiCtrlObj, Info) {
		global Octet1, Octet2, Octet3, Octet4, autenticou
		RebootGui := GuiCtrlObj.Gui
		RebootGui.Submit()
		RebootGui.Hide()
		auth.login("1")
		Loop 20 {
			if (A_Index >= 20) {
				LoginGui.Destroy()
				RebootGui.Destroy()
				return
			}
			if (StrLen(autenticou) > 0) {
				if (SubStr(autenticou, 1, 1) = 1)
					break
				if (SubStr(autenticou, 1, 1) = 0) {
					WinSetAlwaysOnTop(0, "Login Cotrijal")
					MsgBox("Verifique seu usuário e senha.", "Autenticação Falhou")
					return
				}
			}
			Sleep 1000
			OutputDebug(autenticou)
		}
	
		if (!Octet1 || !Octet2 || !Octet3 || !Octet4) {
			MsgBox("Preencha tudo!", "Erro", 16)
			RebootGui.Show()
			return
		}
		result := Http.request("http://admin:tq8hSKWzy5A@" . Octet1 Octet2 Octet3 Octet4 . "/cgi-bin/magicBox.cgi?action=reboot")
		MsgBox(result = "Sucesso" 
			? "Câmera " . Octet1 Octet2 Octet3 Octet4 . " reiniciada com sucesso!" 
			: "Falha ao reiniciar a câmera " . Octet1 Octet2 Octet3 Octet4, "Comando de Reinício de PTZ", "T5")
	}
	
	RebootEscape:
		RebootClose:
		RebootGui.Destroy()
	return
	
	#HotIf WinActive("Reiniciar PTZ")
		Tab::
		+Tab::	{
			currentControl := ControlGetClassNN(ControlGetFocus())
			content := ControlgetText( currentControl )
			Loop 4 {
				if (currentControl = "Edit" . A_Index)
					RebootGui[A_ThisHotkey = "Tab" ? (A_Index < 4 ? "Edit" . (A_Index + 1) : "Button1") : (A_Index > 1 ? "Edit" . (A_Index - 1) : "")].Focus()
			}
		}

		~Backspace::	{
				currentControl := ControlGetClassNN(ControlGetFocus())
				content := ControlgetText( currentControl )
				if(StrLen(content) = 0 && currentControl != "Edit1") {
					Loop 4 {
						if (currentControl = "Edit" . A_Index) {
							prevField := "Edit" . (A_Index - 1)
							prevContent := RebootGui[prevField].Value
							RebootGui[prevField].Focus()
							RebootGui[prevField].Value := SubStr(prevContent, 1, -1)
							Send("{End}")
							break
						}
					}
				}
		}
	#HotIf