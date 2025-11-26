#Requires AutoHotkey v2.0
If	IsSet(z_inc_reg)
	Return
Global	z_inc_reg := 1
reg := Register()

Class Register {

	regDelete(key_name) {
		RegDeleteKey(key_name)
		Return A_LastError = 1 ? "Fail" : "Ok"
	}

	regExist( key_path, key ) {
		exist := 0
		Loop Reg, key_path
			{
				if(	key && a_LoopRegName = key ) {
					exist := 1
					Break
				}
				; else    {
					; RegRead, whatever
					; if	!ErrorLevel {
						; exist++
						; break
					; }
				; }
			}
		Return exist
	}

	regRead( key_name, key:="" )	{
		Return	RegRead(key_name, key) ? RegRead(key_name, key) : RegRead(key_name)
	}

	regWrite( value_type , key_name, value_name:='', value:=''  ) {
		types_of_value		:= 'REG_SZ,REG_EXPAND_SZ,REG_MULTI_SZ,REG_DWORD,REG_BINARY'
		types_of_key_name	:= 'HKEY_LOCAL_MACHINE,HKEY_USERS,HKEY_CURRENT_USER,HKEY_CLASSES_ROOT,HKEY_CURRENT_CONFIG,HKLM,HKU,HKCU,HKCR,HKCC,'

		if (InStr( types_of_value , value_type ) = 0 )	{
			MsgBox("Tipo de valor informado inválido. (primeiro parâmetro)")
			Return
		}
		key_name_	:= StrSplit( key_name , "\" )
		if (InStr( types_of_key_name , key_name_[1] ) = 0 )	{
			MsgBox("Tipo de nome de chave informado inválido. (segundo parâmetro)")
			Return
		}
		RegWrite(value, value_type , key_name, value_name)
		Return	A_LastError	= 1
							? "Erro ao escrever o registro`nRegWrite," value_type "," key_name "," value_name "," value
							: "Registrado com sucesso!"
	}

}