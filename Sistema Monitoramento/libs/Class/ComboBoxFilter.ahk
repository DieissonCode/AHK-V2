
ListLines(0)
#Requires AutoHotkey v2.0

class ComboBoxFilter {
    /*
        cbCtrl   : objeto ComboBox já criado
        items    : array de {id: "...", label: "..."} ou strings (usa o próprio texto como id/label)
        keepOpen : true para manter dropdown aberto enquanto digita
        idLabel  : true para mostrar "id - label", false para mostrar só label
    */
    __New(cbCtrl, items, keepOpen := true, idLabel := false) {
        this.cb       := cbCtrl
        this.items    := items
        this.keepOpen := keepOpen
        this.idLabel  := idLabel
        this.editHwnd := this.GetComboEditHwnd(cbCtrl.Hwnd)
        this.guiHwnd  := cbCtrl.Gui.Hwnd
        this.displayMap := Map()  ; texto exibido -> {id, label}

        cbCtrl.OnEvent("Change", ObjBindMethod(this, "FilterList"))
        this.SetupCloseHotkeys()
        this.ReloadList("")
    }

    SetupCloseHotkeys() {
        HotIfWinActive("ahk_id " this.guiHwnd)
        Hotkey("Enter", ObjBindMethod(this, "CloseDropdown"), "On")
        Hotkey("NumpadEnter", ObjBindMethod(this, "CloseDropdown"), "On")
        HotIfWinActive()
    }

    CloseDropdown(*) {
        SendMessage(0x14F, false, 0, this.cb.Hwnd) ; fecha dropdown
    }

    GetComboEditHwnd(hCombo) {
        static GW_CHILD := 5
        return DllCall("GetWindow", "ptr", hCombo, "uint", GW_CHILD, "ptr")
    }

    BuildDisplayText(item) {
        id    := item.HasOwnProp("id")    ? item.id    : item
        label := item.HasOwnProp("label") ? item.label : item
        return this.idLabel ? id " - " label : label
    }

    ReloadList(term) {
        term := StrLower(term)
        this.cb.Delete()
        this.displayMap.Clear()

        filtered := []
        for item in this.items {
            display := this.BuildDisplayText(item)
            if (term = "" || InStr(StrLower(display), term)) {
                filtered.Push(display)
                id    := item.HasOwnProp("id")    ? item.id    : display
                label := item.HasOwnProp("label") ? item.label : display
                this.displayMap[display] := {id: id, label: label}
            }
        }
        if (filtered.Length)
            this.cb.Add(filtered)
    }

    FilterList(ctrl, *) {
        typed := ctrl.Text
        this.ReloadList(typed)
        if (this.keepOpen)
            SendMessage(0x14F, true, 0, ctrl.Hwnd) ; mantém aberto
        ctrl.Text := typed
        ControlSend("{End}", this.editHwnd)        ; caret no fim
    }

    GetSelected() {
        txt := this.cb.Text
        return this.displayMap.Has(txt) ? this.displayMap[txt] : ""
    }
    GetSelectedId() {
        sel := this.GetSelected()
        return sel ? sel.id : ""
    }
    GetSelectedLabel() {
        sel := this.GetSelected()
        return sel ? sel.label : ""
    }
}

/*
    #Requires AutoHotkey v2.0

    items := [
        {id: "0001", label: "Sede"}
      , {id: "0002", label: "Acerto"}
      , {id: "0003", label: "Filial Norte"}
    ]

    _gui := Gui("+AlwaysOnTop", "Demo")
    _gui.AddText("x10 y10", "Destino:")
    cb := _gui.AddComboBox("x70 y7 w220")

    ; idLabel: true -> mostra "id - label"; false -> só label
    filter := ComboBoxFilter(cb, items, true, true)

    btn := _gui.AddButton("x70 y40 w220", "Mostrar seleção")
    btn.OnEvent("Click", (*) => (
        sel := filter.GetSelected(),
        MsgBox("ID: " sel.id "`nLabel: " sel.label)
    ))

    _gui.Show()
*/
ListLines(1)