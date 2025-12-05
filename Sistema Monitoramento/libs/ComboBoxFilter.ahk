#Requires AutoHotkey v2.0

class ComboBoxFilter {
    ; cbCtrl  : objeto ComboBox já criado
    ; items   : Array de strings (lista completa)
    ; keepOpen: se true, mantém dropdown aberto ao digitar
    __New(cbCtrl, items, keepOpen := true) {
        this.cb      := cbCtrl
        this.items   := items
        this.keepOpen:= keepOpen
        this.editHwnd:= this.GetComboEditHwnd(cbCtrl.Hwnd)

        ; vincula evento Change
        cbCtrl.OnEvent("Change", ObjBindMethod(this, "FilterList"))

        ; carrega lista inicial
        this.ReloadList("")
    }

    GetComboEditHwnd(hCombo) {
        static GW_CHILD := 5
        return DllCall("GetWindow", "ptr", hCombo, "uint", GW_CHILD, "ptr")
    }

    ReloadList(term) {
        term := StrLower(term)
        this.cb.Delete()
        filtered := []
        for item in this.items {
            if (term = "" || InStr(StrLower(item), term))
                filtered.Push(item)
        }
        if (filtered.Length)
            this.cb.Add(filtered)
    }

    FilterList(ctrl, *) {
        typed := ctrl.Text
        this.ReloadList(typed)

        if (this.keepOpen)
            SendMessage(0x14F, true, 0, ctrl.Hwnd) ; CB_SHOWDROPDOWN

        ctrl.Text := typed

        ; move o cursor para o fim enviando {End} ao Edit interno
        ControlSend("{End}", this.editHwnd)
    }
}
/* Exemplo de uso:
    #Requires AutoHotkey v2.0

    items := ["marau 1","marau 2","marau 3","marau 4","marau 5","marau 6","atacado","não me toque","rio pardo","almirante"]

    _gui := Gui("+AlwaysOnTop", "Demo")
    _gui.AddText("x10 y10", "Cidade:")
    cb := _gui.AddComboBox("x70 y7 w200 vCidade")
    filter := ComboBoxFilter(cb, items, true)  ; keepOpen = true
    _gui.Show()
*/