#Requires AutoHotkey v2.0
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\Socket.ahk
class Viaweb extends winsock	{

	static Blocking := False

	Connect(Address)								{

		Winsock.Connect.Call(this, Address)

	}
	
	SendText(Text, Encoding:="UTF-8", hide:="")				{
		OutputDebug "SendText " text
		what := This.StrBuf(text)
		This.Send(what)
	
	}

	AjustarHora(IdIsep)								{
		Text := '{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"data", "hora":"%A_Hour%:%A_Min%:%A_Sec%"}]}]}'
		return Text
	}

	Armar(IdIsep, Partitions, Pass, Disable* )		{

		; If	Disable.Count()	{

		; 	Loop % Disable.Count()
		; 		Disabled .=  Disable[A_Index] ( A_Index = Disable.Count() ? "" : ",")
		; 	Disabled := """inibir"": [" Disabled "],"

		; }
		; Text	=
		; 	(
		; 		{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"armar","password":%Pass%,%Disabled%"particoes":[%Partitions%]}]}]}
		; 	)
		; return Text

	}

	Desarmar(IdIsep, Partitions:='', Pass:='1548' )	{

		; if	Partitions
		; 	partitions := ",""particoes"":[" Partitions "]"

		; Text	=
		; 	(
		; 		{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"desarmar","password":%Pass%%partitions%}]}]}
		; 	)
		; Return	Text

	}

	Disparo(IdIsep, Partitions, Zone  )				{

		; if	Partitions
		; 	Partitions := ",""disparar"":[" Partitions "]"

		; Text	=
		; 	(
		; 		{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"evento","codigoEvento":"E130", "zonaUsuario":%zone% %partitions%}]}]}
		; 	)
		/*
			{	"oper":
				[
					{
						"acao":"executar",
						"idISEP":"0002",
						"comando":
							[
								{
									"cmd":"evento",
									"codigoEvento":"E130",
									"zonaUsuario":99,"disparar":[1]}
							]
					}
				]
			}
		*/

		; Return	Text

	}

	Fontes(IdIsep)									{

		; Text	=
		; 	(
		; 		{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"fontes"}]}]}
		; 	)
		; Return	Text
		
	}

	Info(IdIsep)									{
		; id := Ltrim(IdIsep, 0)
		; Text	=
		; 	(
		; 		{"oper":[{"id":"%id%","acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"perif"}]}]}
		; 	)

		; Return	Text

	}

	LerFuncao(obj, Functions* )						{

		; if(Functions.Count() > 1)	{

		; 	Function	:=	"["
		; 	For i, v in Functions
		; 		Function .= v ","
		; 	Function	:=	SubStr(Function, 1, StrLen(Function)-1 ) "]"

		; }
		; Else
		; 	Function := Functions[1]
		; if	!IsObject(obj)
		; 	Text	=
		; 		(
		; 			{"oper":[{"acao":"executar","idISEP":"%obj%","comando":[{"cmd":"ler","end":1,"funcao":%function%}]}]}
		; 		)
		; Else	{
		; 	_temp := []
		; 	Loop, % obj.Count()	
		; 		_temp.Push("{""acao"":""executar"",""idISEP"":""" obj[A_Index] """,""comando"":[{""cmd"":""ler"",""end"":1,""funcao"":" function "}]}")

		; 	_Text := Text := ""
		; 	Loop, % _temp.Count()
		; 		if(A_Index = _temp.Count())
		; 			_Text .= _temp[A_Index]
		; 		Else
		; 			_Text .= _temp[A_Index] ",`n"
		; 	Text := "{""oper"":[" _Text "]}"
		; }

		; Return	Text

	}

	ListarClientes()								{
		; Random, id, 0, 9999999
		; text =
		; 	(
		; 		{"oper":[{	"id":"%id%"
		; 				,	"acao":"listarClientes"
		; 				,	"porta":1733
		; 				,	"nome":"viaweb"	}]}
		; 	)
		; 	Return text
	}

	PGMs(IdIsep)									{

		; Text	=
		; 	(
		; 		{"oper":[{"acao":"executar","idISEP":"%IdIsep%","comando":[{"cmd":"pgms","pos": 1,"max": 2}]}]}
		; 	)
		; Return	Text
		
	}

	StrBuf(str)	{
		; Calculate required size and allocate a buffer.
		buf := Buffer(StrPut(str, "cp0"))
		; Copy or convert the string.
		StrPut(str, buf, "cp0")
		return buf
	}

	OnRecv()										{
		; Line	:= this.RecvText(,,"CP0")
		OutputDebug "OnRecv " A_LineNumber " Viaweb Class"

		If	IsSet(Line)	{
			MsgBox	line
			; Switch	{
				; Case	_Events, _x.oper.Count() = 1:
					; OutputDebug	% "`t1 Event " A_LineNumber " Viaweb Class`n`t" line
					; z	:= []
					; x	:=_x.oper[1]
					; z.Push(x)
					; Append(this.hLog, z )
				; Case	_x.oper.Count() > 1:
					; OutputDebug	% "`tMany Events " A_LineNumber " Viaweb Class`n`t" line
					; Loop % _x.oper.Count()	{
						; z	:= []
						; x	:=_x.oper[A_Index]
						; z.Push(x)
						; Append(this.hLog, z )
					; }
				; Case	_x.resp.Count() = 1:
					; Append(this.hLog, Line )
				; Default:
					; Append(this.hLog, Line )
					; OutputDebug	% "`tDEFAULT " A_LineNumber " Viaweb Class`n`t" line
					; Catch
						; Try EditAppend(this.hLog, datetime(1) "`t<--`r`n`t" Line )
			; }

		}

	}

	NewEvent(ID)									{

		OutputDebug "NewEvent " ID  " " A_LineNumber " Viaweb Class"
		resp := '{ "resp": [ { "id":"%id%" } ] }'
		This.SendText(resp)

	}

}