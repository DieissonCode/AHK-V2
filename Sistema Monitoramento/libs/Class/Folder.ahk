#Requires AutoHotkey v2.0
Try	if	IsSet(z_inc_folder)
	Return

; Email.send("dieisson13@gmail.com","E-Mail de Teste","Teste de corpo de e-mail")
Global	z_inc_folder := 1
Class	Folder	{
	
	Static Clear( dir )	{
		Loop Files, dir '\*.*', 'FDR'
		{
			Try FileDelete(dir "\DVRWorkDirectory")
			Try FileDelete(A_LoopFileFullPath "\DVRWorkDirectory")
			This.Clear( A_LoopFileFullPath )
		}
		Try DirDelete(A_LoopFileFullPath, 1)
	}

}