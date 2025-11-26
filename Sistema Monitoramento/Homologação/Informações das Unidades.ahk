#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================================
; SISTEMA DE GERENCIAMENTO DE UNIDADES - AutoHotkey v2.0 OFICIAL
; Responsiva - Ajusta ao tamanho da tela automaticamente SEM FICAR ATRÁS DA BARRA
; ============================================================================

global config := {
    theme: {
        bgColor: "F0F0F0",
        primaryColor: "2E5C8A",
        accentColor: "E74C3C",
        textColor: "2C3E50",
        lightBg: "FFFFFF",
        borderColor: "BDC3C7"
    }
}

; ============================================================================
; DADOS MOCK
; ============================================================================

global operadores := [
    {
        id: 1,
        nome: "Operador 1",
        unidades: [
            {id: 1, nome: "Unidade Centro", endereco: "Av. Paulista, 1000", entreposto: "SP-001", responsaveis: [{nome: "Maria", matricula: "M001", cargo: "Gerente"}], autorizados: [{nome: "Pedro", matricula: "A001", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}},
            {id: 2, nome: "Unidade Sul", endereco: "Rua das Flores, 500", entreposto: "SP-002", responsaveis: [{nome: "Carlos", matricula: "M002", cargo: "Coordenador"}], autorizados: [{nome: "Ana", matricula: "A002", cargo: "Operador"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    },
    {
        id: 2,
        nome: "Operador 2",
        unidades: [
            {id: 3, nome: "Unidade Norte", endereco: "Av. Brasil, 2000", entreposto: "SP-003", responsaveis: [{nome: "Lucas", matricula: "M003", cargo: "Gerente"}], autorizados: [{nome: "Fernanda", matricula: "A003", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}},
            {id: 4, nome: "Unidade Leste", endereco: "Rua do Comércio, 750", entreposto: "SP-004", responsaveis: [{nome: "Roberto", matricula: "M004", cargo: "Coordenador"}], autorizados: [{nome: "Juliana", matricula: "A004", cargo: "Operador"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    },
    {
        id: 3,
        nome: "Operador 3",
        unidades: [
            {id: 5, nome: "Unidade Oeste", endereco: "Av. Faria Lima, 1500", entreposto: "SP-005", responsaveis: [{nome: "Patricia", matricula: "M005", cargo: "Gerente"}], autorizados: [{nome: "Diego", matricula: "A005", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    },
    {
        id: 4,
        nome: "Operador 4",
        unidades: [
            {id: 6, nome: "Unidade Industrial", endereco: "Polo Industrial, 3000", entreposto: "SP-006", responsaveis: [{nome: "Ricardo", matricula: "M006", cargo: "Gerente"}], autorizados: [{nome: "Beatriz", matricula: "A006", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}},
            {id: 7, nome: "Unidade Logística", endereco: "Via de Acesso, 4000", entreposto: "SP-007", responsaveis: [{nome: "Marcelo", matricula: "M007", cargo: "Coordenador"}], autorizados: [{nome: "Vanessa", matricula: "A007", cargo: "Operador"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    },
    {
        id: 5,
        nome: "Operador 5",
        unidades: [
            {id: 8, nome: "Unidade Administrativa", endereco: "Centro Corporativo, 2500", entreposto: "SP-008", responsaveis: [{nome: "Amanda", matricula: "M008", cargo: "Gerente"}], autorizados: [{nome: "Felipe", matricula: "A008", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    },
    {
        id: 6,
        nome: "Operador 6",
        unidades: [
            {id: 9, nome: "Unidade de Pesquisa", endereco: "Tecnopolo, 5000", entreposto: "SP-009", responsaveis: [{nome: "Gustavo", matricula: "M009", cargo: "Gerente"}], autorizados: [{nome: "Cristina", matricula: "A009", cargo: "Supervisor"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}},
            {id: 10, nome: "Unidade de Desenvolvimento", endereco: "Campus Tech, 6000", entreposto: "SP-010", responsaveis: [{nome: "Rafael", matricula: "M010", cargo: "Coordenador"}], autorizados: [{nome: "Sophia", matricula: "A010", cargo: "Operador"}], emergencia: {policia: "190", bombeiros: "193", brigada: "192"}}
        ]
    }
]

global emails := [
    {de: "admin@unidade.com", para: "operador@empresa.com", assunto: "Relatório de Segurança", data: "2025-11-14 10:30", status: "enviado"},
    {de: "operador@empresa.com", para: "admin@unidade.com", assunto: "Solicitação de Acesso", data: "2025-11-14 09:15", status: "recebido"},
    {de: "admin@unidade.com", para: "operador@empresa.com", assunto: "Atualização de Sistema", data: "2025-11-13 16:45", status: "enviado"},
    {de: "operador@empresa.com", para: "admin@unidade.com", assunto: "Confirmação de Agendamento", data: "2025-11-13 14:20", status: "recebido"},
    {de: "admin@unidade.com", para: "operador@empresa.com", assunto: "Alerta de Segurança", data: "2025-11-13 11:00", status: "enviado"},
    {de: "operador@empresa.com", para: "admin@unidade.com", assunto: "Feedback de Monitoramento", data: "2025-11-12 15:30", status: "recebido"},
    {de: "admin@unidade.com", para: "operador@empresa.com", assunto: "Manutenção Preventiva", data: "2025-11-12 10:45", status: "enviado"},
    {de: "operador@empresa.com", para: "admin@unidade.com", assunto: "Teste de Sistema", data: "2025-11-11 13:20", status: "recebido"},
    {de: "admin@unidade.com", para: "operador@empresa.com", assunto: "Relatório Mensal", data: "2025-11-11 09:00", status: "enviado"},
    {de: "operador@empresa.com", para: "admin@unidade.com", assunto: "Requisição de Credenciais", data: "2025-11-10 16:15", status: "recebido"}
]

global horarioPortoes := [
    {id: 1, nome: "Segunda", abertura: "06:00", fechamento: "18:00"},
    {id: 2, nome: "Terça", abertura: "06:00", fechamento: "18:00"},
    {id: 3, nome: "Quarta", abertura: "06:00", fechamento: "18:00"},
    {id: 4, nome: "Quinta", abertura: "06:00", fechamento: "18:00"},
    {id: 5, nome: "Sexta", abertura: "06:00", fechamento: "18:00"},
    {id: 6, nome: "Sábado", abertura: "08:00", fechamento: "14:00"}
]

global gUIPrincipal := 0
global tvUnidades := 0
global lvEmails := 0
global lvHorarios := 0
global unidadeSelecionada := {}

; Controles de Texto
global ctrlTextID := 0
global ctrlTextNome := 0
global ctrlTextEndereco := 0
global ctrlTextEntreposto := 0
global ctrlTextOperador := 0
global ctrlTextResponsaveis := 0
global ctrlTextAutorizados := 0
global ctrlTextPolicia := 0
global ctrlTextBombeiros := 0
global ctrlTextBrigada := 0

; Mapa de IDs da TreeView
global mapTreeViewUnidades := Map()

; ============================================================================
; CLASS PARA EVENTOS
; ============================================================================

class EventosPrincipal {
    Close(GuiObj) {
        ExitApp()
    }
}

; ============================================================================
; FUNÇÃO PARA OBTER DIMENSÕES DISPONÍVEIS (SEM BARRA DE TAREFAS)
; ============================================================================

ObterDimensoesTelaUtil() {
    ; Obter tamanho total da tela
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    
    ; Obter a área de trabalho disponível
    MonitorGetWorkArea(, &workLeft, &workTop, &workRight, &workBottom)
    
    ; Altura e largura da área útil
    usableWidth := workRight - workLeft
    usableHeight := workBottom - workTop
    
    ; Altura da barra de título do Windows (geralmente 32px em Windows 11, 29px em Windows 10)
    ; Varia conforme escala DPI
    titleBarHeight := A_ScreenDPI = 96 ? 32 : Round(32 * A_ScreenDPI / 96)
    
    ; Altura final = área útil - barra de título
    finalHeight := usableHeight - titleBarHeight
    
    OutputDebug("Screen: " screenWidth "x" screenHeight " | WorkArea: " usableWidth "x" usableHeight " | TitleBar: " titleBarHeight " | Final: " finalHeight " | Y Start: " workTop)
    
    return {
        width: usableWidth,
        height: finalHeight,
        startX: workLeft,
        startY: workTop + titleBarHeight
    }
}

; ============================================================================
; GUI PRINCIPAL - RESPONSIVA
; ============================================================================

MontarGUIPrincipal() {
    global operadores, config, gUIPrincipal, tvUnidades
    global ctrlTextID, ctrlTextNome, ctrlTextEndereco, ctrlTextEntreposto, ctrlTextOperador
    global ctrlTextResponsaveis, ctrlTextAutorizados, ctrlTextPolicia, ctrlTextBombeiros, ctrlTextBrigada
    global lvEmails, lvHorarios, mapTreeViewUnidades
    
    gUIPrincipal := Gui(, "Sistema de Gerenciamento de Unidades - v2.0")
    gUIPrincipal.OnEvent("Close", EventosPrincipal)
    gUIPrincipal.BackColor := config.theme.bgColor
    
    ; Obter dimensões disponíveis
    dims := ObterDimensoesTelaUtil()
    screenWidth := A_ScreenWidth
    screenHeight := dims.height
    
    ; Define proporções responsivas
    margin := Round(screenWidth * 0.01)
    leftPanelWidth := Round(screenWidth * 0.65)
    rightPanelWidth := screenWidth - leftPanelWidth - (margin * 3)
    tabHeight := screenHeight - (margin * 2) - 40
    
    ; PAINEL DIREITO - TREEVIEW
    tvx := leftPanelWidth + (margin * 2)
    tvy := margin + 40
    tvw := rightPanelWidth - margin
    tvh := tabHeight
    
    gUIPrincipal.Add("GroupBox", "x" margin " y" margin " w" leftPanelWidth " h" 30, " Detalhes da Unidade ")
    gUIPrincipal.Add("GroupBox", "x" tvx " y" margin " w" tvw " h" (tabHeight + 40), " Operadores e Unidades ")
    
    tvUnidades := gUIPrincipal.Add("TreeView", "x" (tvx + 10) " y" tvy " w" (tvw - 20) " h" tvh " v_TreeUnidades")
    tvUnidades.OnEvent("ItemSelect", Evento_SelecionarUnidade)
    
    PopularTreeView()
    
    ; PAINEL ESQUERDO - ABAS COM CONTEÚDO
    MyTab := gUIPrincipal.Add("Tab3", "x" margin " y" (margin + 40) " w" leftPanelWidth " h" tabHeight, 
                              ["Informações", "Setores", "Contatos", "Emails", "Horários"])
    
    ; Margens internas das abas
    tabMargin := Round(margin * 0.5)
    
    ; ========== ABA 1: INFORMAÇÕES ==========
    MyTab.UseTab(1)
    
    ; Grupo 1: Informações Básicas
    infoBoxW := Round(leftPanelWidth * 0.45)
    infoBoxX := margin + tabMargin
    infoBoxY := margin + 60
    
    gUIPrincipal.Add("GroupBox", "x" infoBoxX " y" infoBoxY " w" infoBoxW " h" Round(tabHeight * 0.3), " Informações Básicas ")
    
    ; Campos com proporções dinâmicas
    labelX := infoBoxX + 10
    valueX := labelX + Round(infoBoxW * 0.35)
    valueW := infoBoxW - Round(infoBoxW * 0.35) - 20
    rowY := infoBoxY + 20
    rowSpacing := Round((tabHeight * 0.3 - 40) / 5)
    
    gUIPrincipal.Add("Text", "x" labelX " y" rowY, "ID:")
    ctrlTextID := gUIPrincipal.Add("Text", "x" valueX " y" rowY " w" valueW, "---")
    
    rowY += rowSpacing
    gUIPrincipal.Add("Text", "x" labelX " y" rowY, "Nome:")
    ctrlTextNome := gUIPrincipal.Add("Text", "x" valueX " y" rowY " w" valueW, "---")
    
    rowY += rowSpacing
    gUIPrincipal.Add("Text", "x" labelX " y" rowY, "Endereço:")
    ctrlTextEndereco := gUIPrincipal.Add("Text", "x" valueX " y" rowY " w" valueW, "---")
    
    rowY += rowSpacing
    gUIPrincipal.Add("Text", "x" labelX " y" rowY, "Entreposto:")
    ctrlTextEntreposto := gUIPrincipal.Add("Text", "x" valueX " y" rowY " w" valueW, "---")
    
    rowY += rowSpacing
    gUIPrincipal.Add("Text", "x" labelX " y" rowY, "Operador:")
    ctrlTextOperador := gUIPrincipal.Add("Text", "x" valueX " y" rowY " w" valueW, "---")
    
    ; Grupo 2: Responsáveis
    respBoxY := infoBoxY + Round(tabHeight * 0.32)
    respBoxH := Round(tabHeight * 0.3)
    gUIPrincipal.Add("GroupBox", "x" infoBoxX " y" respBoxY " w" infoBoxW " h" respBoxH, " Responsáveis ")
    ctrlTextResponsaveis := gUIPrincipal.Add("Text", "x" (infoBoxX + 10) " y" (respBoxY + 15) " w" (infoBoxW - 20) " h" (respBoxH - 25), "---")
    
    ; Grupo 3: Autorizados
    authBoxX := infoBoxX + infoBoxW + tabMargin
    authBoxY := infoBoxY
    authBoxW := infoBoxW
    authBoxH := respBoxH + Round(tabHeight * 0.32)
    gUIPrincipal.Add("GroupBox", "x" authBoxX " y" authBoxY " w" authBoxW " h" authBoxH, " Autorizados ")
    ctrlTextAutorizados := gUIPrincipal.Add("Text", "x" (authBoxX + 10) " y" (authBoxY + 15) " w" (authBoxW - 20) " h" (authBoxH - 25), "---")
    
    ; ========== ABA 2: SETORES ==========
    MyTab.UseTab(2)
    
    sectorX := margin + tabMargin
    sectorY := margin + 60
    sectorW := leftPanelWidth - (tabMargin * 2)
    
    gUIPrincipal.Add("GroupBox", "x" sectorX " y" sectorY " w" sectorW " h" Round(tabHeight * 0.15), " Selecione o Setor ")
    gUIPrincipal.Add("DDL", "x" (sectorX + 10) " y" (sectorY + 20) " w" Round(sectorW * 0.6) " v_Setor", 
                     ["Entrada Principal", "Área de Armazenamento", "Almoxarifado", "Recepção", "Escritórios", "Câmaras Frias"])
    gUIPrincipal.Add("Button", "x" (sectorX + Round(sectorW * 0.65)) " y" (sectorY + 20) " w" Round(sectorW * 0.3) " h" 25).OnEvent("Click", Evento_VisualizarMapa)
    
    mapBoxY := sectorY + Round(tabHeight * 0.17)
    mapBoxH := tabHeight - Round(tabHeight * 0.17) - 20
    gUIPrincipal.Add("GroupBox", "x" sectorX " y" mapBoxY " w" sectorW " h" mapBoxH, " Visualização do Setor ")
    gUIPrincipal.Add("Text", "x" (sectorX + 10) " y" (mapBoxY + 15) " w" (sectorW - 20) " h" (mapBoxH - 25) " Border cAAAAAA", "[Mapa do setor seria exibido aqui]")
    
    ; ========== ABA 3: CONTATOS ==========
    MyTab.UseTab(3)
    
    contactX := margin + tabMargin
    contactY := margin + 60
    contactW := leftPanelWidth - (tabMargin * 2)
    
    ; Emergência
    gUIPrincipal.Add("GroupBox", "x" contactX " y" contactY " w" contactW " h" Round(tabHeight * 0.18), " Números de Emergência ")
    emgY := contactY + 20
    ctrlTextPolicia := gUIPrincipal.Add("Text", "x" (contactX + 10) " y" emgY, "🚔 Polícia: ---")
    ctrlTextBombeiros := gUIPrincipal.Add("Text", "x" (contactX + 10) " y" (emgY + 20), "🚒 Bombeiros: ---")
    ctrlTextBrigada := gUIPrincipal.Add("Text", "x" (contactX + 10) " y" (emgY + 40), "👮 Brigada: ---")
    
    ; Controles Operacionais
    ctrlBoxY := contactY + Round(tabHeight * 0.2)
    ctrlBoxH := tabHeight - Round(tabHeight * 0.2) - 20
    gUIPrincipal.Add("GroupBox", "x" contactX " y" ctrlBoxY " w" contactW " h" ctrlBoxH, " Controles Operacionais ")
    
    btn1W := Round(contactW * 0.47)
    btn1X := contactX + 10
    btn2X := btn1X + btn1W + 10
    btnH := Round(ctrlBoxH * 0.22)
    btnY := ctrlBoxY + 15
    
    gUIPrincipal.Add("Button", "x" btn1X " y" btnY " w" btn1W " h" btnH, "🔐 Gerar Senha Única").OnEvent("Click", Evento_GerarSenhaUnica)
    gUIPrincipal.Add("Button", "x" btn2X " y" btnY " w" btn1W " h" btnH, "📞 Chamar Interfone").OnEvent("Click", Evento_ChamarInterfone)
    
    btnY += btnH + 10
    gUIPrincipal.Add("Button", "x" btn1X " y" btnY " w" btn1W " h" btnH, "🔔 Acionar Corneta").OnEvent("Click", Evento_AcionarCorneta)
    gUIPrincipal.Add("Button", "x" btn2X " y" btnY " w" btn1W " h" btnH, "📋 Gerar Relatório").OnEvent("Click", Evento_GerarRelatorio)
    
    ; ========== ABA 4: EMAILS ==========
    MyTab.UseTab(4)
    
    emailX := margin + tabMargin
    emailY := margin + 60
    emailW := leftPanelWidth - (tabMargin * 2)
    emailH := tabHeight - 20
    
    gUIPrincipal.Add("GroupBox", "x" emailX " y" emailY " w" emailW " h" emailH, " Últimos 10 Emails ")
    
    lvEmails := gUIPrincipal.Add("ListView", "x" (emailX + 10) " y" (emailY + 20) " w" (emailW - 20) " h" (emailH - 30) " -Multi", 
                                 ["Direção", "Email", "Assunto", "Data", "Status"])
    col1 := Round((emailW - 20) * 0.08)
    col2 := Round((emailW - 20) * 0.22)
    col3 := Round((emailW - 20) * 0.30)
    col4 := Round((emailW - 20) * 0.20)
    
    lvEmails.ModifyCol(1, col1)
    lvEmails.ModifyCol(2, col2)
    lvEmails.ModifyCol(3, col3)
    lvEmails.ModifyCol(4, col4)
    lvEmails.ModifyCol(5, -1)
    
    ; ========== ABA 5: HORÁRIOS ==========
    MyTab.UseTab(5)
    
    scheduleX := margin + tabMargin
    scheduleY := margin + 60
    scheduleW := leftPanelWidth - (tabMargin * 2)
    
    gUIPrincipal.Add("GroupBox", "x" scheduleX " y" scheduleY " w" scheduleW " h" Round(tabHeight * 0.65), " Horários de Abertura e Fechamento ")
    
    lvHorarios := gUIPrincipal.Add("ListView", "x" (scheduleX + 10) " y" (scheduleY + 20) " w" (scheduleW - 20) " h" Round(tabHeight * 0.45) " -Multi", 
                                   ["Dia", "Abertura", "Fechamento"])
    colW := Round((scheduleW - 20) / 3)
    lvHorarios.ModifyCol(1, colW)
    lvHorarios.ModifyCol(2, colW)
    lvHorarios.ModifyCol(3, -1)
    
    btnAddY := scheduleY + Round(tabHeight * 0.5)
    btnAddW := Round(scheduleW * 0.47)
    gUIPrincipal.Add("Button", "x" (scheduleX + 10) " y" btnAddY " w" btnAddW " h" 30, "+ Adicionar Horário").OnEvent("Click", Evento_AdicionarHorario)
    gUIPrincipal.Add("Button", "x" (scheduleX + btnAddW + 20) " y" btnAddY " w" btnAddW " h" 30, "💾 Salvar").OnEvent("Click", Evento_SalvarHorarios)
    
    ; Mostra a janela SEM Maximize (usa as dimensões calculadas)
    gUIPrincipal.Show("w" screenWidth " h" screenHeight " x0 y0")
    
    ExibirMensagemInicial()
}

; ============================================================================
; FUNÇÕES
; ============================================================================

PopularTreeView() {
    global operadores, tvUnidades, mapTreeViewUnidades
    
    mapTreeViewUnidades := Map()
    
    Loop operadores.Length {
        operador := operadores[A_Index]
        itemPai := tvUnidades.Add("📋 " operador.nome)
        
        for unidade in operador.unidades {
            itemFilho := tvUnidades.Add("🏢 " unidade.nome, itemPai)
            mapTreeViewUnidades[itemFilho] := unidade.id
        }
    }
}

ExibirMensagemInicial() {
    global ctrlTextID, ctrlTextNome, ctrlTextEndereco, ctrlTextEntreposto, ctrlTextOperador
    global ctrlTextResponsaveis, ctrlTextAutorizados, ctrlTextPolicia, ctrlTextBombeiros, ctrlTextBrigada
    
    ctrlTextID.Value := "---"
    ctrlTextNome.Value := "Selecione uma unidade"
    ctrlTextEndereco.Value := "---"
    ctrlTextEntreposto.Value := "---"
    ctrlTextOperador.Value := "---"
    ctrlTextResponsaveis.Value := "---"
    ctrlTextAutorizados.Value := "---"
    ctrlTextPolicia.Value := "🚔 Polícia: ---"
    ctrlTextBombeiros.Value := "🚒 Bombeiros: ---"
    ctrlTextBrigada.Value := "👮 Brigada: ---"
}

Evento_SelecionarUnidade(GuiObj, Info) {
    global operadores, mapTreeViewUnidades, unidadeSelecionada, lvEmails, lvHorarios, emails, horarioPortoes
    global ctrlTextID, ctrlTextNome, ctrlTextEndereco, ctrlTextEntreposto, ctrlTextOperador
    global ctrlTextResponsaveis, ctrlTextAutorizados, ctrlTextPolicia, ctrlTextBombeiros, ctrlTextBrigada
    
    itemID := Info
    
    if (!mapTreeViewUnidades.Has(itemID)) {
        ExibirMensagemInicial()
        return
    }
    
    unidadeID := mapTreeViewUnidades[itemID]
    
    unidadeEncontrada := ""
    operadorEncontrado := ""
    
    for operadorObj in operadores {
        for unidade in operadorObj.unidades {
            if (unidade.id = unidadeID) {
                unidadeEncontrada := unidade
                operadorEncontrado := operadorObj
                break
            }
        }
        if (unidadeEncontrada != "")
            break
    }
    
    if (unidadeEncontrada = "")
        return
    
    unidadeSelecionada := unidadeEncontrada
    
    ctrlTextID.Value := unidadeEncontrada.id
    ctrlTextNome.Value := unidadeEncontrada.nome
    ctrlTextEndereco.Value := unidadeEncontrada.endereco
    ctrlTextEntreposto.Value := unidadeEncontrada.entreposto
    ctrlTextOperador.Value := operadorEncontrado.nome
    
    textResp := ""
    for resp in unidadeEncontrada.responsaveis {
        textResp .= resp.nome " (Mat: " resp.matricula ")`n" resp.cargo "`n`n"
    }
    ctrlTextResponsaveis.Value := textResp
    
    textAuth := ""
    for auth in unidadeEncontrada.autorizados {
        textAuth .= auth.nome " (Mat: " auth.matricula ")`n" auth.cargo "`n`n"
    }
    ctrlTextAutorizados.Value := textAuth
    
    ctrlTextPolicia.Value := "🚔 Polícia: " unidadeEncontrada.emergencia.policia
    ctrlTextBombeiros.Value := "🚒 Bombeiros: " unidadeEncontrada.emergencia.bombeiros
    ctrlTextBrigada.Value := "👮 Brigada: " unidadeEncontrada.emergencia.brigada
    
    if (IsObject(lvEmails)) {
        lvEmails.Delete()
        for email in emails {
            direcao := (email.de = "admin@unidade.com") ? "📤" : "📥"
            lvEmails.Add(, direcao, email.de, email.assunto, email.data, email.status)
        }
    }
    
    if (IsObject(lvHorarios)) {
        lvHorarios.Delete()
        for horario in horarioPortoes {
            lvHorarios.Add(, horario.nome, horario.abertura, horario.fechamento)
        }
    }
}

; ============================================================================
; EVENTOS
; ============================================================================

Evento_VisualizarMapa(GuiObj, Info) {
    MsgBox("Mapa de Alarme", "Visualizando mapa do setor...",64)
}

Evento_GerarSenhaUnica(GuiObj, Info) {
    global unidadeSelecionada
    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }
    
    senha := Format("{:06d}", Random(1, 999999))
    MsgBox("Senha de Uso Único", "Unidade: " unidadeSelecionada.nome "`n`nSenha: " senha "`n`nVálida por: 24 horas",64)
}

Evento_ChamarInterfone(GuiObj, Info) {
    global unidadeSelecionada

    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }

    MsgBox("Interfone", "Chamada iniciada para: " unidadeSelecionada.nome, 64)
}

Evento_AcionarCorneta(GuiObj, Info) {
    global unidadeSelecionada

    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }

    MsgBox("Corneta", "Corneta acionada em: " unidadeSelecionada.nome, 64)
}

Evento_GerarRelatorio(GuiObj, Info) {
    global unidadeSelecionada

    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }

    MsgBox("Relatório", "Gerando relatório de: " unidadeSelecionada.nome, 64)
}

Evento_AdicionarHorario(GuiObj, Info) {
    global unidadeSelecionada
    
    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }
    
    inputBox := Gui()
    inputBox.Add("Text", , "Dia: ")
    inputBox.Add("Edit", "w200 v_dia")
    inputBox.Add("Text", , "Abertura: ")
    inputBox.Add("Edit", "w200 v_abert")
    inputBox.Add("Text", , "Fechamento: ")
    inputBox.Add("Edit", "w200 v_fech")
    inputBox.Add("Button", "Default w200", "Adicionar").OnEvent("Click", Evento_SalvarNovoHorario)
    inputBox.Show()
}

Evento_SalvarNovoHorario(GuiObj, Info) {
    dia := GuiObj.Gui.Value("v_dia")
    abert := GuiObj.Gui.Value("v_abert")
    fech := GuiObj.Gui.Value("v_fech")
    
    if (dia = "" || abert = "" || fech = "") {
        MsgBox 48, "Erro", "Preencha todos os campos!"
        return
    }
    
    MsgBox 64, "Sucesso", "Horário " dia " adicionado!"
    GuiObj.Gui.Destroy()
}

Evento_SalvarHorarios(GuiObj, Info) {
    global unidadeSelecionada
    
    if !Unidade_Selecionada() {
        MsgBox("Selecione uma unidade primeiro!", "Aviso", 48)
        return
    }

    MsgBox("Horários", "Horários de: " unidadeSelecionada.nome " salvos com sucesso!", 64)
}

Unidade_Selecionada() {
    global unidadeSelecionada
    if (unidadeSelecionada = "" || !IsObject(unidadeSelecionada) || !unidadeSelecionada.HasProp("nome"))
        return false
    return true
}

; ============================================================================
; INICIALIZAÇÃO
; ============================================================================

MontarGUIPrincipal()