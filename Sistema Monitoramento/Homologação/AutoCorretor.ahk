;Save_To_Sql=1
;Keep_Versions=3
;@Ahk2Exe-Let U_FileVersion = 0.3.0.0
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Auto Corretor Ortográfico
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\autocorretor.ico

#Requires AutoHotkey v2.0
#Warn All, off

;{	Configurações de envio - melhora confiabilidade no Windows 11
	SendMode("Input")
	SetKeyDelay(-1, -1)
	A_HotkeyInterval := 2000
	A_MaxHotkeysPerInterval := 200
;}

if	!A_IsCompiled
	TraySetIcon("C:\AHK\icones\autocorretor.ico")
;{	Includes
	#Include ..\libs\functions.ahk
;}

;{	Configurações
	GroupAdd('work_windows', 'ahk_class ThunderRT6FormDC')
	GroupAdd('work_windows', 'ahk_class WordPadClass')
	GroupAdd('work_windows', 'ahk_class Notepad++')
	GroupAdd('work_windows', 'ahk_class Notepad')
	GroupAdd('work_windows', 'ahk_class SALFRAME')
	GroupAdd('work_windows', 'ahk_class TJanelaOcorrencia')
	;GroupAdd('work_windows', 'ahk_exe chrome.exe')
	GroupAdd('work_windows', 'ahk_exe Moni.exe')
	
	#SingleInstance Force
	A_TrayMenu.Delete()
;}

;{	Startup
	LoadHotstrings()
	SetTimer(self_load, -300000)
;}

self_load() {
	Hotstring('Reset')  ; Limpa todas as hotstrings
	LoadHotstrings()
	SetTimer(self_load, -300000)
}

LoadHotstrings() {
	; CRÍTICO: Define o contexto ANTES de criar as hotstrings
	HotIfWinActive('ahk_group work_windows')
	
	totalLoaded := 0
	
	;{	Palavras adicionadas
		h := '
			(
				SELECT
					[misspelled_word],
					[corrected_word]
				FROM
					[ASM].[dbo].[_corretor]
			)'
		h := sql(h)
		
		Loop h.Length - 1 {
			Switch {
				Case SubStr(h[A_Index+1][1], 1, 1) = "," || SubStr(h[A_Index+1][1], 1, 1) = ".":
					Hotstring(':?*:' h[A_Index+1][1], h[A_Index+1][2])
					
				Case InStr(h[A_Index+1][2], "|"):
					parts := StrSplit(h[A_Index+1][2], "|")
					Hotstring(':' parts[2] ':' h[A_Index+1][1], parts[1])
					
				Default:
					Hotstring('::' h[A_Index+1][1], h[A_Index+1][2])
			}
			totalLoaded++
		}
	;}
	
	;{	Câmeras
		h := '
			(
				SELECT	s.[current_value], d.[device_name]
				FROM		[Dguard].[dbo].[camera_devices]		d
				LEFT JOIN	[Dguard].[dbo].[camera_settings]	s
				ON			d.[device_id] = s.[device_id]
				WHERE		s.[setting_name] = 'address'
			)'
		h := sql(h)
		
		Loop h.Length - 1 {
			Hotstring(':Z:' h[A_Index+1][1], h[A_Index+1][2] ' ( ' h[A_Index+1][1] ' )')
			totalLoaded++
		}
	;}
	
	;{	Matrículas
		h := '
			(
				SELECT
					TRIM([EmployeeId]),
					[FullName],
					[JobTitle]
				FROM
					[Cotrijal].[dbo].[Employees]
			)'
		h := sql(h)
		
		Loop h.Length - 1 {
			matricula := h[A_Index+1][1]
			nome := Format('{:T}', h[A_Index+1][2])
			cargo := Format('{:T}', h[A_Index+1][3])
			
			textoCompleto := nome ' (' cargo ', Matrícula ' matricula ')'
			Hotstring(':T:#' matricula, SendTextSafe.Bind(textoCompleto))
			totalLoaded++
		}
	;}
	
	; Volta ao contexto global (opcional)
	HotIf()
	TrayTip('✓ ' totalLoaded ' correções carregadas!', 'AutoCorretor', 49)
}

SendTextSafe(texto, *) {
	oldDelay := A_KeyDelay
	SetKeyDelay(0, 10)
	SendText(texto)
	SetKeyDelay(oldDelay)
}

#z:: {
	; Verifica IP
	if (SysGetIPAddresses()[1] != "192.9.100.100")
		return
	
	; Salva clipboard atual
	ClipboardOld := A_Clipboard
	A_Clipboard := ""
	Send('^c')
	
	; Aguarda conteúdo
	if !ClipWait(1) {
		ToolTip('Erro ao capturar conteúdo, finalizando...')
		Sleep(1000)
		ToolTip()
		return
	}
	
	Sleep(100)
	ClipContent := StrReplace(StrReplace(A_Clipboard, "`n", ""), "`r", "")
	ClipContent := StrReplace(ClipContent, "|", "")
	
	; Verifica se há conteúdo
	if !ClipContent {
		ToolTip('Você precisa SELECIONAR a palavra que deseja sugerir uma auto correção!')
		Sleep(1000)
		ToolTip()
		A_Clipboard := ClipboardOld
		return
	}
	
	; Cria GUI
	G := Gui()
	G.Opt("+AlwaysOnTop")
	G.BackColor := "0x2b2b2b"
	G.SetFont("cWhite s10", "Segoe UI")
	
	G.Add('Text', 'x20 y20 w460', 
		'Digite o texto que deve substituir a palavra:')
	G.Add('Text', 'x20 y45 w460 c0xFFD700', 
		'"' ClipContent '"')
	
	G.SetFont("s8")
	G.Add('Text', 'x20 y70 w460 c0xAAAAAA', 
		'Ficará registrado que ' A_UserName ' inseriu a correção.')
	
	G.SetFont("s10")
	editCtrl := G.Add('Edit', 'x20 y100 w460 h25 vnew_word c0x004e11')
	
	G.SetFont("cWhite s10")  ; Volta fonte branca para botões
	
	btnInserir := G.Add('Button', 'x20 y140 w225 h30', 'Inserir')
	btnCancelar := G.Add('Button', 'x250 y140 w230 h30', 'Cancelar')
	
	; Eventos dos botões
	btnInserir.OnEvent('Click', (*) => ProcessarInsercao(G, ClipContent, ClipboardOld))
	btnCancelar.OnEvent('Click', (*) => FecharGui(G, ClipboardOld))
	G.OnEvent('Close', (*) => FecharGui(G, ClipboardOld))
	G.OnEvent('Escape', (*) => FecharGui(G, ClipboardOld))
	
	G.Title := 'Auto Corretor'
	G.Show('w500 h190')
}

ProcessarInsercao(GuiObj, ClipContent, ClipboardOld) {
	try {
		; Captura valor digitado
		new_word := Trim(GuiObj['new_word'].Value)
		
		if !new_word {
			MsgBox('Por favor, digite uma correção!', 'Aviso', 'Icon!')
			return
		}
		
		; Trata espaços
		if InStr(new_word, A_Space)
			new_word := RegExReplace(new_word, "\s+", " {Space} ")
		
		; Cria hotstring
		hotstringLabel := '::' ClipContent
		Hotstring(hotstringLabel, new_word)
		
		; Escapa aspas simples para SQL
		ClipContent_SQL := StrReplace(ClipContent, "'", "''")
		new_word_SQL := StrReplace(new_word, "'", "''")
		username_SQL := StrReplace(A_UserName, "'", "''")
		ip_SQL := SysGetIPAddresses()[1]  ; Pega o primeiro IP disponível
		
		; Monta query SQL usando Format
		sqlQuery := Format("
		(
			IF NOT EXISTS (SELECT * FROM [ASM].[dbo].[_corretor] WHERE [misspelled_word] = '{}')
				INSERT INTO [ASM].[dbo].[_corretor]
					([misspelled_word], [corrected_word], [ip], [submitted_by])
				VALUES
					('{}', '{}', '{}', '{}')
			ELSE
				UPDATE [ASM].[dbo].[_corretor]
				SET 
					[corrected_word] = '{}',
					[submitted_by] = '{}',
					[ip] = '{}'
				WHERE [misspelled_word] = '{}'
		)", ClipContent_SQL, ClipContent_SQL, new_word_SQL, ip_SQL, username_SQL, new_word_SQL, username_SQL, ip_SQL, ClipContent_SQL)

		; Executa SQL
		resultado := sql(sqlQuery, 3)
		
		; Verifica se houve erro
		global Sql_le
		if IsSet(Sql_le) && Sql_le {
			MsgBox('Erro ao salvar no banco:`n' Sql_le, 'Erro', 'Icon!')
			return
		}
		
		; Sucesso
		A_Clipboard := ClipboardOld
		GuiObj.Destroy()
		
		ToolTip('✓ Adicionado com sucesso!', 10, 10)
		SetTimer(() => ToolTip(), -2000)
		
	} catch as err {
		MsgBox('Erro ao processar:`n' err.Message, 'Erro', 'Icon!')
	}
}

FecharGui(GuiObj, ClipboardOld) {
	A_Clipboard := ClipboardOld
	GuiObj.Destroy()
}