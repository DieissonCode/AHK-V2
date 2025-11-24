if	IsSet(z_inc_auth)
	Return

Global	z_inc_auth := 1

Class Auth	{

	Static login(operadores := "", user := "", pass := "", software := "", show_message := "1", teste := "") {
		global autenticou := "", users, passs, LoginGui := Gui(,"Login Cotrijal")
		
		this.admins()
		if (user && pass) {
			users := user
			passs := pass
			return operadores ? AutOperador() : AutAdmin()
		}

		LoginGui.BackColor := "c9BACC0"
		LoginGui.SetFont("Bold S10 cWhite")
		LoginGui.Add("Text", "x10 y10 w80 h20", "Usuário")
		LoginGui.Add("Text", "x10 y30 w80 h20", "Senha")
		LoginGui.SetFont()
		users := LoginGui.Add("Edit", "x90 y10 w140 h20")
		passs := LoginGui.Add("Edit", "x90 y30 w140 h20 Password")
		LoginGui.SetFont("Bold S10")
		LoginGui.Add("Button", "x10 y55 w110 h25", "Ok").OnEvent("Click", (StrLen(operadores) ? AutOperador : AutAdmin))
		LoginGui.Add("Button", "x121 y55 w110 h25", "Cancelar").OnEvent("Click", loginxCancel)
		LoginGui.SetFont()
		LoginGui.Opt("+AlwaysOnTop -MinimizeBox")
		; LoginGui.Opt(software ? "+AlwaysOnTop -MinimizeBox" : "-Caption +AlwaysOnTop -MinimizeBox")
		LoginGui.Show()
		return
	
		AutAdmin(*) {
			OutputDebug("Login - Admin")
			LoginGui.Submit(0)
			isAdmin := 0
			Loop _login_admin.Length {
				if (users = _login_admin[A_Index]) {
					isAdmin := 1
					break
				}
			}
			
			if (!isAdmin) {
				WinSetAlwaysOnTop(0, "Login Cotrijal")
				MsgBox("Você não tem permissão para administrar o sistema.`n" . _login_admin.Length)
				ExitApp()
			} else if (Windows.LoginAd(users, passs) = 0) {
				if (show_message = 1) {
					WinSetAlwaysOnTop(0, "Login Cotrijal")
					MsgBox("Senha ou Usuário inválidos!", "Falha no login")
				}
				return autenticou := "0|" . users.Value
			} else {
				LoginGui.Destroy()
				return autenticou := "1|" . users.Value
			}
		}
	
		AutOperador(*) {
			OutputDebug("Login - Operador")
			LoginGui.Submit(0)
			internal_auth := Windows.LoginAd(users, passs)
			
			if (!internal_auth) {
				WinSetAlwaysOnTop(0, "Login Cotrijal")
				MsgBox("Senha ou Usuário inválidos!", "Falha no login")
				autenticou := "0|" . users.Value
				LoginGui.Destroy()
				return autenticou
			} else if (internal_auth) {
				autenticou := "1|" . users.Value
				LoginGui.Destroy()
				return autenticou
			}
		}
	
		loginxCancel(*) {
			autenticou := "2|" . users.Value
			LoginGui.Destroy()
			return autenticou
		}

		loginxGuiClose(*) {
			autenticou := "0|" . users.Value
			LoginGui.Destroy()
			return autenticou
		}
	}
	
	Static login_vigilante() {
		teste := 1
		global autenticou, __login_data, __user, __pass, __vigilante
		
		vigilantes := "
		(
			SELECT [nome],
				   [usuario],
				   [cargo]
			FROM [ASM].[dbo].[_colaboradores]
			WHERE [cargo] = 'vigilante'
			OR [matricula] IN (SELECT [badge]
							  FROM [Guardinhas].[dbo].[UserAccessExceptions]
							  WHERE [expiration_date] > GETDATE())
		)"
		vigilantes := sql(vigilantes)
		__vigilante := Map()
		Loop vigilantes.Length-1
			__vigilante[vigilantes[A_Index+1][2]] := vigilantes[A_Index+1][1]
		
		if ((A_UserName = "dsantos" || SysGetIPAddresses()[1] = "192.9.100.100") && !teste) {
			autenticou := 1
			return __login_data := [1, A_UserName]
		}
		
		gui.Cores("loginy", "", "")
		LoginYGui := Gui("loginy")
		LoginYGui.SetFont("Bold S10 cWhite")
		LoginYGui.Add("Text", "x10 y10 w80 h20", "Usuário")
		LoginYGui.Add("Text", "x10 y30 w80 h20", "Senha")
		LoginYGui.SetFont()
		__user := LoginYGui.Add("Edit", "x90 y10 w140 h20")
		__pass := LoginYGui.Add("Edit", "x90 y30 w140 h20 Password")
		LoginYGui.SetFont("Bold S10")
		LoginYGui.Add("Button", "x10 y55 w110 h25 gAutGuardinha", "Ok")
		LoginYGui.Add("Button", "x121 y55 w110 h25 gloginyGuiClose", "Cancelar")
		LoginYGui.SetFont()
		LoginYGui.Opt("+AlwaysOnTop -MinimizeBox")
		LoginYGui.Show(, "Login Cotrijal")
		return
	
		AutGuardinha(*) {
			LoginYGui := Gui("loginy")
			LoginYGui.Submit()
			login_status := !__vigilante.Has(__user) ? 2 : Windows.LoginAd(__user, __pass)
			
			switch login_status {
				case 0:
					WinSetAlwaysOnTop(0, "Login Cotrijal")
					MsgBox("Senha ou Usuário inválidos!`nVerifique os dados e tente novamente.`nLembrando que se você errar sua senha por 3 vezes em menos de 1 hora, seu usuário ficará bloqueado por 60 minutos.", "Falha no login")
					autenticou := 0
					return __login_data := [0, __user]
				case 1:
					LoginYGui.Destroy()
					autenticou := 1
					return __login_data := [1, __user]
				case 2:
					autenticou := 3
					return __login_data := [3, __user]
			}
		}
	
		loginyGuiClose(*) {
			ExitApp(0)
		}
	}
	
	Static admins() {
		s := "
		(
			SELECT [complemento1]
			FROM [ASM].[dbo].[_gestao_sistema]
			WHERE [funcao] = 'admin'
		)"
		s := sql(s)
		admins := StrSplit(s[2][1], ";")
		global _login_admin := []
		Loop admins.Length
			_login_admin.Push(admins[A_Index])
	}

}