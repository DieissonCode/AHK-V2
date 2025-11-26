#Requires AutoHotkey v2.0

/**
 * @class WindowManager
 * @description Gerenciador avançado de janelas do sistema com suporte a filtros, busca e controle
 * @author DieissonCode
 * @date 2025-11-06 12:58:01 UTC
 * @version 1.0.0
 * 
 * @example
 * wm := WindowManager()
 * wm.ShowInfo()
 */
class WindowManager {
    ; Propriedades privadas
    __windows := []
    __filter := ''
    
    /**
     * @method __New
     * @description Constructor da classe WindowManager - Inicializa com filtro opcional
     * @param {String} [filter=''] - Filtro opcional para títulos de janelas
     * @returns {WindowManager} - Instância do WindowManager
     * @example
     * wm := WindowManager()
     * wm2 := WindowManager('monitor')
     */
    __New(filter := '') {
        this.__filter := filter
        this.Refresh()
    }
    
    /**
     * @property filter
     * @description Getter/Setter do filtro de janelas
     * @type {String}
     * @example
     * currentFilter := wm.filter
     * wm.filter := 'new filter'
     */
    filter {
        get => this.__filter
        set => (this.__filter := value, this.Refresh())
    }
    
    /**
     * @property windows
     * @description Getter das janelas (somente leitura)
     * @type {Array<Object>}
     * @readonly
     * @example
     * allWindows := wm.windows
     */
    windows {
        get => this.__windows
    }
    
    /**
     * @method Refresh
     * @description Atualiza a lista de janelas do sistema
     * @returns {void}
     * @throws {Error} - Se houver erro ao acessar janelas
     * @example
     * wm.Refresh()
     */
    Refresh() {
        this.__windows := []
        this._FetchWindows()
    }
    
    /**
     * @method _FetchWindows
     * @description (Privado) Busca todas as janelas do sistema com filtro
     * @returns {void}
     * @private
     * @example
     * this._FetchWindows()
     */
    _FetchWindows() {
        winList := WinGetList()
        
        for hwnd in winList {
            try {
                title := WinGetTitle(hwnd)
                if (title = '')
                    continue
                    
                if (this.__filter && !InStr(title, this.__filter))
                    continue
                
                this.__windows.Push({
                    hwnd: hwnd,
                    title: title,
                    processName: WinGetProcessName(hwnd),
                    processID: WinGetPID(hwnd)
                })
            } catch as err {
                continue
            }
        }
    }

    /**
     * @method GetAll
     * @description Retorna todas as janelas atualmente gerenciadas
     * @returns {Array<Object>} - Array contendo objetos de janelas com propriedades (hwnd, title, processName, processID)
     * @example
     * windows := wm.GetAll()
     * for index, win in windows {
     *     MsgBox(win.title)
     * }
     */
    GetAll() {
        return this.__windows
    }
    
    /**
     * @method Count
     * @description Retorna a quantidade total de janelas gerenciadas
     * @returns {Integer} - Número de janelas
     * @example
     * total := wm.Count()
     * MsgBox("Total: " . total)
     */
    Count() {
        return this.__windows.Length
    }
    
    /**
     * @method GetByTitle
     * @description Busca uma janela por título exato (case-sensitive)
     * @param {String} title - Título exato da janela a buscar
     * @returns {Object} - Objeto da janela encontrada ou {} se não encontrar
     * @example
     * win := wm.GetByTitle("Untitled - Notepad")
     * if (win.hwnd) {
     *     MsgBox("Janela encontrada!")
     * }
     */
    GetByTitle(title) {
        for win in this.__windows {
            if (win.title = title)
                return win
        }
        return {}
    }
    
    /**
     * @method GetByTitleContains
     * @description Busca todas as janelas que contenham o texto especificado no título
     * @param {String} searchText - Texto a procurar no título (case-insensitive)
     * @returns {Array<Object>} - Array de janelas que contêm o texto
     * @example
     * results := wm.GetByTitleContains("Visual Studio")
     * for win in results {
     *     OutputDebug(win.title)
     * }
     */
    GetByTitleContains(searchText) {
        results := []
        for win in this.__windows {
            if (InStr(win.title, searchText))
                results.Push(win)
        }
        return results
    }
    
    /**
     * @method GetByProcessName
     * @description Busca todas as janelas de um processo específico
     * @param {String} processName - Nome do processo (ex: 'explorer.exe', 'notepad.exe')
     * @returns {Array<Object>} - Array de janelas do processo
     * @example
     * notepadWindows := wm.GetByProcessName('notepad.exe')
     * for win in notepadWindows {
     *     MsgBox(win.title)
     * }
     */
    GetByProcessName(processName) {
        results := []
        for win in this.__windows {
            if (InStr(win.processName, processName, false))
                results.Push(win)
        }
        return results
    }
    
    /**
     * @method GetByPID
     * @description Busca uma janela pelo Process ID (PID)
     * @param {Integer} pid - ID do processo
     * @returns {Object} - Objeto da janela encontrada ou {} se não encontrar
     * @example
     * win := wm.GetByPID(1234)
     * if (win.hwnd) {
     *     MsgBox("Janela do processo encontrada!")
     * }
     */
    GetByPID(pid) {
        for win in this.__windows {
            if (win.processID = pid)
                return win
        }
        return {}
    }
    
    /**
     * @method GetByHWND
     * @description Busca uma janela pelo Handle (HWND)
     * @param {Integer} hwnd - Handle único da janela
     * @returns {Object} - Objeto da janela encontrada ou {} se não encontrar
     * @example
     * win := wm.GetByHWND(0x000A0A62)
     * if (win.hwnd) {
     *     MsgBox("Janela encontrada: " . win.title)
     * }
     */
    GetByHWND(hwnd) {
        for win in this.__windows {
            if (win.hwnd = hwnd)
                return win
        }
        return {}
    }
    
    /**
     * @method ActivateByTitle
     * @description Ativa (traz para frente) uma janela pelo título
     * @param {String} title - Título exato da janela
     * @returns {Boolean} - true se ativada com sucesso, false caso contrário
     * @example
     * if (wm.ActivateByTitle("Untitled - Notepad")) {
     *     MsgBox("Janela ativada!")
     * }
     */
    ActivateByTitle(title) {
        win := this.GetByTitle(title)
        if (win.hwnd) {
            WinActivate(win.hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method ActivateByHWND
     * @description Ativa (traz para frente) uma janela pelo Handle
     * @param {Integer} hwnd - Handle único da janela
     * @returns {Boolean} - true se ativada com sucesso, false caso contrário
     * @example
     * if (wm.ActivateByHWND(0x000A0A62)) {
     *     MsgBox("Janela ativada!")
     * }
     */
    ActivateByHWND(hwnd) {
        if (this.GetByHWND(hwnd).hwnd) {
            WinActivate(hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method CloseByTitle
     * @description Fecha uma janela pelo título
     * @param {String} title - Título exato da janela
     * @returns {Boolean} - true se fechada com sucesso, false caso contrário
     * @warning Esta ação é irreversível
     * @example
     * if (wm.CloseByTitle("Untitled - Notepad")) {
     *     MsgBox("Janela fechada!")
     * }
     */
    CloseByTitle(title) {
        win := this.GetByTitle(title)
        if (win.hwnd) {
            WinClose(win.hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method MaximizeByTitle
     * @description Maximiza uma janela pelo título
     * @param {String} title - Título exato da janela
     * @returns {Boolean} - true se maximizada com sucesso, false caso contrário
     * @example
     * wm.MaximizeByTitle("Untitled - Notepad")
     */
    MaximizeByTitle(title) {
        win := this.GetByTitle(title)
        if (win.hwnd) {
            WinMaximize(win.hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method MinimizeByTitle
     * @description Minimiza uma janela pelo título
     * @param {String} title - Título exato da janela
     * @returns {Boolean} - true se minimizada com sucesso, false caso contrário
     * @example
     * wm.MinimizeByTitle("Untitled - Notepad")
     */
    MinimizeByTitle(title) {
        win := this.GetByTitle(title)
        if (win.hwnd) {
            WinMinimize(win.hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method RestoreByTitle
     * @description Restaura uma janela minimizada ou maximizada pelo título
     * @param {String} title - Título exato da janela
     * @returns {Boolean} - true se restaurada com sucesso, false caso contrário
     * @example
     * wm.RestoreByTitle("Untitled - Notepad")
     */
    RestoreByTitle(title) {
        win := this.GetByTitle(title)
        if (win.hwnd) {
            WinRestore(win.hwnd)
            return true
        }
        return false
    }
    
    /**
     * @method DebugPrint
     * @description Exibe todas as janelas no Debug Output do VS Code
     * @returns {void}
     * @example
     * wm.DebugPrint()
     */
    DebugPrint() {
        OutputDebug("=== TOTAL DE JANELAS: " . this.Count() . " ===")
        for index, win in this.__windows {
            OutputDebug("Janela #" . index)
            OutputDebug("  Título: " . win.title)
            OutputDebug("  HWND: " . win.hwnd)
            OutputDebug("  Processo: " . win.processName)
            OutputDebug("  PID: " . win.processID)
        }
    }
    
    /**
     * @method ShowInfo
     * @description Exibe informações de todas as janelas em uma janela MsgBox
     * @returns {void}
     * @example
     * wm.ShowInfo()
     */
    ShowInfo() {
        output := "=== INFORMAÇÕES DE JANELAS ===" . "`n"
        output .= "Total: " . this.Count() . " janelas`n"
        output .= "Usuário: DieissonCode`n"
        output .= "Data/Hora: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n`n"
        
        for index, win in this.__windows {
            output .= "Janela #" . index . "`n"
            output .= "  Título: " . win.title . "`n"
            output .= "  Processo: " . win.processName . " (PID: " . win.processID . ")`n`n"
        }
        
        MsgBox(output, "Gerenciador de Janelas")
    }
    
    /**
     * @method SetFilter
     * @description Define um novo filtro e atualiza a lista
     * @param {String} filterText - Texto para filtrar títulos
     * @returns {Array<Object>} - Array de janelas filtradas
     * @example
     * results := wm.SetFilter('explorer')
     */
    SetFilter(filterText) {
        this.__filter := filterText
        this.Refresh()
        return this.__windows
    }
    
    /**
     * @method ClearFilter
     * @description Remove o filtro atual e retorna todas as janelas
     * @returns {Array<Object>} - Array de todas as janelas
     * @example
     * allWindows := wm.ClearFilter()
     */
    ClearFilter() {
        this.__filter := ''
        this.Refresh()
        return this.__windows
    }
}

/*
; ============================================
; EXEMPLOS DE USO
; ============================================

; Criar instância
wm := WindowManager()

; Usar a propriedade filter (agora funciona corretamente)
wm.filter := 'Monitor'

; Listar todas as janelas com "Monitor" no título
for index, win in wm.GetAll() {
    OutputDebug(win.title)
}

; Limpar filtro
;wm.ClearFilter()

; Mostrar informações
;wm.ShowInfo()

; Usar Debug
;wm.DebugPrint()
*/