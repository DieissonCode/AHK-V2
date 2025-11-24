#Requires AutoHotkey v2.0

keys := []
Loop Reg, 'HKEY_CURRENT_USER\Control Panel\NotifyIconSettings\', 'RKV'
	{
		if A_LoopRegType = "key"
			value := ""
		else
			If(A_LoopRegName = 'ExecutablePath')
				keys.push(A_LoopRegKey)
	}
Loop	keys.Length-1
	RegWrite('1', 'REG_DWORD', keys[A_Index], 'IsPromoted')

ExitApp 0