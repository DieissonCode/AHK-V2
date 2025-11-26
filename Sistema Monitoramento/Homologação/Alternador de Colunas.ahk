;Save_To_Sql=1
;Keep_Versions=5
;@Ahk2Exe-Let U_FileVersion = 0.0.2.4
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Alternador de Colunas
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\switch_collumn.ico

#Requires AutoHotkey v2.0
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\new_dguard.ahk

#SingleInstance Force
Persistent

_for_delete := {
	Coluna_1_Layout_1: 1, Coluna_2_Layout_1: 1, Coluna_3_Layout_1: 1, Coluna_4_Layout_1: 1,
	Coluna_1_Layout_2: 1, Coluna_2_Layout_2: 1, Coluna_3_Layout_2: 1, Coluna_4_Layout_2: 1,
	Coluna_1_Layout_3: 1, Coluna_2_Layout_3: 1, Coluna_3_Layout_3: 1, Coluna_4_Layout_3: 1,
	Coluna_1_Layout_4: 1, Coluna_2_Layout_4: 1, Coluna_3_Layout_4: 1, Coluna_4_Layout_4: 1,
	Coluna_1_NLayout_1: 1, Coluna_2_NLayout_1: 1, Coluna_3_NLayout_1: 1, Coluna_4_NLayout_1: 1,
	Coluna_1_NLayout_2: 1, Coluna_2_NLayout_2: 1, Coluna_3_NLayout_2: 1, Coluna_4_NLayout_2: 1,
	Coluna_1_NLayout_3: 1, Coluna_2_NLayout_3: 1, Coluna_3_NLayout_3: 1, Coluna_4_NLayout_3: 1,
	Coluna_1_NLayout_4: 1, Coluna_2_NLayout_4: 1, Coluna_3_NLayout_4: 1, Coluna_4_NLayout_4: 1
}

MyGui := Gui('-DPIScale', "KAH - Alternador de Colunas")
MyGui.BackColor := "0x121212"

; ===== CORES =====
	cor_bg := "0x121212"
	cor_painel := "0x1E1E1E"
	cor_titulo := "0x00BCD4"
	cor_texto := "0x9e9050"
	cor_selecionado := "0x4CAF50"
	cor_bloqueado := "0xFF5252"
	cor_botao := "0x42A5F5"

; ===== SEÇÃO: COLUNAS (ORIGEM E DESTINO) =====
; Painel de fundo ORIGEM
	MyGui.Add("Text", "w170 h140 x10 y10 Background" cor_painel)

; ORIGEM - Título
	MyGui.SetFont("s12 Bold c" cor_titulo)
	ctl := MyGui.Add("Text", "w140 h30 x20 y15 Center", "📤 ORIGEM")
	ctl.Opt("+BackgroundTrans")
	MyGui.SetFont("s10 c" cor_texto)

; ORIGEM - Radios (SEM Background)
	loop 4 {
		y := 50 + (A_Index - 1) * 22
		ctl := MyGui.Add("Radio", "w130 h20 x30 y" y (A_Index = 1 ? " Group" : "" ) " v_from" A_Index " c" cor_texto, "⦿ Coluna " A_Index)
		ctl.OnEvent("Click", (*) => CheckColumns())
	}
	Loop 4 {
		y := 50 + (A_Index - 1) * 22
		MyGui.SetFont("s10 c" cor_bloqueado " Bold")
		ctl := MyGui.Add("Text", "w130 h20 x30 y" y " v_from" A_Index "_blocked Hidden c" cor_bloqueado, "✗ Bloqueado")
		MyGui.SetFont("s10 c" cor_texto)
	}
; Painel de fundo DESTINO
	MyGui.Add("Text", "w170 h140 x190 y10 Background" cor_painel)

; DESTINO - Título
	MyGui.SetFont("s12 Bold c" cor_titulo)
	ctl := MyGui.Add("Text", "w140 h30 x200 y15 Center", "📥 DESTINO")
	ctl.Opt("+BackgroundTrans")
	MyGui.SetFont("s10 c" cor_texto)

; DESTINO - Radios (SEM Background)
	loop 4 {
		y := 50 + (A_Index - 1) * 22
		ctl := MyGui.Add("Radio", "w130 h20 x210 y" y (A_Index = 1 ? " Group" : "" ) " v_to" A_Index " c" cor_texto, "⦿ Coluna " A_Index)
		ctl.OnEvent("Click", (*) => CheckColumns())
	}
	Loop 4 {
		y := 50 + (A_Index - 1) * 22
		MyGui.SetFont("s10 c" cor_bloqueado " Bold")
		ctl := MyGui.Add("Text", "w130 h20 x210 y" y " v_to" A_Index "_blocked Hidden c" cor_bloqueado, "✗ Bloqueado")
		MyGui.SetFont("s10 c" cor_texto)
	}
; ===== LINHA SEPARADORA =====
	MyGui.Add("Text", "w350 h2 x10 y160 Background" cor_bloqueado)

; ===== SEÇÃO: PERÍODO =====
; Painel de fundo PERÍODO
	MyGui.Add("Text", "w350 h80 x10 y170 Background" cor_painel)

; PERÍODO - Título
	MyGui.SetFont("s12 Bold c" cor_titulo)
	ctl := MyGui.Add("Text", "w200 h30 x20 y175 Center", "⏰ PERÍODO")
	ctl.Opt("+BackgroundTrans")
	MyGui.SetFont("s10 c" cor_texto)

; PERÍODO - Radios (SEM Background)
	ctl := MyGui.Add("Radio", "w150 h20 x30 y210 Checked Group v_day c" cor_texto " Center", "☀️ Dia")
	MyGui["_day"].SetFont("c" cor_selecionado " Bold")
	ctl.OnEvent("Click", (*) => CheckColumns())

	ctl := MyGui.Add("Radio", "w150 h20 x200 y210 v_night c" cor_texto " Center", "🌙 Noite")
	ctl.OnEvent("Click", (*) => CheckColumns())

; ===== LINHA SEPARADORA =====
	MyGui.Add("Text", "w350 h2 x10 y260 Background" cor_bloqueado)

; ===== SEÇÃO: BOTÕES =====
; Painel de fundo BOTÕES
	MyGui.Add("Text", "w350 h60 x10 y260 Background" cor_painel)

	MyGui.SetFont("s11 Bold cWhite")
	ctl := MyGui.Add("Button", "w110 h30 x10 y280 v_ok Background" cor_selecionado,		"✓ EXECUTAR")
	ctl.OnEvent("Click", (*) => Execute())

	ctl := MyGui.Add("Button", "w110 h30 x130 y280 v_cancel Background" cor_botao,		"⟲ CANCELAR")
	ctl.OnEvent("Click", (*) => OnCancel())

	ctl := MyGui.Add("Button", "w110 h30 x250 y280 v_exit Background" cor_bloqueado,	"✕ SAIR")
	ctl.OnEvent("Click", (*) => OnExit())

; Rodapé com informações
	MyGui.SetFont("s8 c" cor_texto " Bold")
	ctl := MyGui.Add("Text", "w350 h20 x10 y330 Background" cor_painel " Center", "Alternador de Colunas")
	ctl.Opt("+BackgroundTrans")

	MyGui.OnEvent("Close", (*) => ExitApp())
	MyGui.Show("w370 h365")
; ===== FUNÇÕES =====

CheckColumns() {
	MyGui.Submit(0)

	; Resetar todas cores para branco, habilitar e esconder bloqueios
	loop 4 {
		MyGui["_from" A_Index].SetFont("c" cor_texto)
		MyGui["_from" A_Index].Enabled := true
		MyGui["_from" A_Index "_blocked"].Visible := false

		MyGui["_to" A_Index].SetFont("c" cor_texto)
		MyGui["_to" A_Index].Enabled := true
		MyGui["_to" A_Index "_blocked"].Visible := false
	}

	; Resetar cores do período
	MyGui["_day"].SetFont("c" cor_texto)
	MyGui["_night"].SetFont("c" cor_texto)

	; Encontrar qual foi selecionado em origem
	selectedFrom := 0
	loop 4 {
		if MyGui["_from" A_Index].Value {
			selectedFrom := A_Index
			MyGui["_from" A_Index].SetFont("c" cor_selecionado " Bold")
			break
		}
	}

	; Encontrar qual foi selecionado em destino
	selectedTo := 0
	loop 4 {
		if MyGui["_to" A_Index].Value {
			selectedTo := A_Index
			MyGui["_to" A_Index].SetFont("c" cor_selecionado " Bold")
			break
		}
	}

	; Colorir dia ou noite selecionado
	if MyGui["_day"].Value {
		MyGui["_day"].SetFont("c" cor_selecionado " Bold")
	}

	if MyGui["_night"].Value {
		MyGui["_night"].SetFont("c" cor_selecionado " Bold")
	}

	; Bloquear a mesma coluna no outro lado com texto vermelho sobreposto
	if selectedFrom > 0 {
		MyGui["_to" selectedFrom].Enabled := false
		MyGui["_to" selectedFrom "_blocked"].Visible := true
	}

	if selectedTo > 0 {
		MyGui["_from" selectedTo].Enabled := false
		MyGui["_from" selectedTo "_blocked"].Visible := true
	}

}

Execute() {
	;Global
	try {
		MyGui.Submit(0)

		if !CheckOrigemDestino()
			return

		DisableButtons()

		ipAddress := GetIPAddress()
		colunasMap := GetColunasMap(ipAddress)

		if !colunasMap {
			MsgBox("IP não reconhecido: " ipAddress)
			EnableButtons()
			return
		}

		_from := GetColumnSelected("from", colunasMap)
		_to := GetColumnSelected("to", colunasMap)

		_from_layouts := DguardLayouts.Get(Map('server', _from))
		_to_layouts := DguardLayouts.Get(Map('server', _to))

		Global _for_delete
		for name in _to_layouts {
			if _for_delete.HasProp(name)
				dguardLayouts.delete(Map('server', _to, 'guid', _to_layouts[name].guid))
		}

		ProcessLayouts(_from, _to, _from_layouts, colunasMap)
		
		ResetRadios()
		EnableButtons()
		CheckColumns()

		MsgBox("✓ Layouts copiados com sucesso!")
	}
	catch as err {
		MsgBox( "Execute()`n`n" "❌ Erro: " err.What "`nExtra: " err.Extra)
		EnableButtons()
	}
}

OnCancel() {
	try {
		DisableButtons()

		; TODO: Implementar lógica de undo

		EnableButtons()
		ResetRadios()
		CheckColumns()

		;MsgBox("✓ Layouts resetados com sucesso!")
	}
	catch as err {
		MsgBox("❌ Erro: " err.What)
		EnableButtons()
	}
}

OnExit() {
	ExitApp()
}

; ===== FUNÇÕES AUXILIARES =====

CheckOrigemDestino() {
	if !MyGui["_from1"].Value && !MyGui["_from2"].Value 
	   && !MyGui["_from3"].Value && !MyGui["_from4"].Value {
		MsgBox("⚠️ Você precisa selecionar a coluna de ORIGEM para prosseguir.")
		return false
	}

	if !MyGui["_to1"].Value && !MyGui["_to2"].Value 
	   && !MyGui["_to3"].Value && !MyGui["_to4"].Value {
		MsgBox("⚠️ Você precisa selecionar a coluna de DESTINO para prosseguir.")
		return false
	}

	return true
}

DisableButtons() {
	MyGui["_ok"].Enabled := false
	MyGui["_exit"].Enabled := false
	MyGui["_cancel"].Enabled := false
}

EnableButtons() {
	MyGui["_ok"].Enabled := true
	MyGui["_exit"].Enabled := true
	MyGui["_cancel"].Enabled := true
}

ResetRadios() {
	loop 4 {
		MyGui["_from" A_Index].Value := 0
		MyGui["_to" A_Index].Value := 0
	}
	MyGui["_day"].Value := 1
	MyGui["_night"].Value := 0
}

GetColunasMap(ip) {
	switch ip {
		case "192.9.100.102":
			return {1: "192.9.100.101", 2: "192.9.100.102", 3: "192.9.100.103", 4: "192.9.100.104", count: 4}
		case "192.9.100.100", "192.9.100.106":
			return {1: "192.9.100.105", 2: "192.9.100.106", 3: "192.9.100.107", 4: "192.9.100.108", count: 4}
		case "192.9.100.109":
			return {1: "192.9.100.109", 2: "192.9.100.110", 3: "192.9.100.111", 4: "192.9.100.112", count: 4}
		case "192.9.100.114":
			return {1: "192.9.100.113", 2: "192.9.100.114", 3: "192.9.100.115", 4: "192.9.100.116", count: 4}
		case "192.9.100.118":
			return {1: "192.9.100.117", 2: "192.9.100.118", 3: "192.9.100.119", 4: "192.9.100.120", count: 4}
		case "192.9.100.123":
			return {1: "192.9.100.121", 2: "192.9.100.122", 3: "192.9.100.123", 4: "192.9.100.124", count: 4}
	}
	return ""
}

GetColumnSelected(type, map) {
	loop 4 {
		if MyGui["_" type A_Index].Value
			return map.%A_Index%
	}
	return map[1]
}

GetIPAddress() {
	return SysGetIPAddresses()[1]
}

InsertCam(server, cam_from, layout_guid) {
	loop cam_from.Count	{
		_ := dguardLayouts.addCam(Map(	'server', server
									,	'camera', cam_from[A_Index].guid
									,	'guid'	, layout_guid))
	}
}

OrderCam(layout_cam) {
	done := Map()
	loop layout_cam.Count {
		z_objeto := layout_cam[A_Index].sequence + 1
		z := {guid: layout_cam[A_Index].guid}
		done[z_objeto] := z
	}
	return done
}

ProcessLayouts(_from, _to, _from_layouts, colunasMap) {
	Global MyGui
	_new_layout_day_guids := []
	_new_layout_night_guids := []
	_monitores_from := dguard._getWorkstationInfo(Map('server', _from)).data["monitor"]
	_monitores := dguard._getWorkstationInfo(Map('server', _to)).data["monitor"]
	
	;	Criar novos layouts no servidor de destino e pegar informações das câmeras
	loop _from_layouts.Count {
		layoutPeriod := MyGui['_day'].Value ? "_Layout" : "_NLayout"
		_new_layout := dguardLayouts.Create(Map('server', _to, 'name',  'Coluna_' GetColunaFromIp(_from, colunasMap) layoutPeriod '_' A_Index))
		_new_layout_day_guids.Push(_new_layout)
		_layout_cam := dguardLayouts.getCameras(Map('server', _from, 'layoutGuid', _from_layouts[layoutPeriod A_Index].guid))
		InsertCam(_to, OrderCam(_layout_cam), _new_layout)
	}

	;	Exibir layouts nas estações de trabalho
	loop _from_layouts.Count {
				DguardLayouts.show(Map(	'server', _to
									,	'monitorGuid', _monitores[A_Index]
									,	'layoutGuid', A_Hour >= 7 && A_Hour <= 19
										? _new_layout_day_guids[A_Index]
										: _new_layout_night_guids[A_Index]))
	}

}

GetColunaFromIp(ip, colunas) {
	Loop colunas.Count {
		if colunas.%A_Index% = ip
			return A_Index
	}
}