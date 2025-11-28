#Warn		All,	Off
#Requires	AutoHotkey v2.0
#Include	..\libs\class\socket.ahk
comando := ""
z_functions	:= 0
#Include	..\libs\functions.ahk
#Include	..\libs\Class\Json.ahk
;	Configurações
	w	:=	405
; start_server()
;	Operador
	Switch	SysGetIPAddresses()[1] {
		Case	"192.9.100.102":
			operador := 1
		Case	"192.9.100.106":
			operador := 2
		Case	"192.9.100.109":
			operador := 3
		Case	"192.9.100.114":
			operador := 4
		Case	"192.9.100.118":
			operador := 5
		Case	"192.9.100.123":
			operador := 6
		Default:
			operador := 0
	}

;	Interface Principal
	a := Gui('AlwaysOnTop -DPIScale -Border','KAH')
	;a.Color(a,)
	a.Add('Text', '0x1001	w'  w '		h20		vstatus'												, ''							).OnEvent('Click',	start_socket)
	a.Add('Text', '0x1001	w'  w '		h20'									a.SetFont('Bold cWhite'), 'Selecione o local'		   )
	a.Add('Edit', '			w'  w '				vFiltro			Section'		a.SetFont('cBlack')								   ).OnEvent('Change', filtrar)
	a.Add('Listview','		w'  w '		r20		vUnidade	Grid		-HDR'							,	['Unidade','ID','Operador']	).OnEvent('Click',	verificar_partições)
	a.Add('Button','	xm	w' (w-5)/2	'		vbt_armar		Section			'						,	'Armar'						).OnEvent("Click",	armar)
	a.Add('Button','	yp	w' (w-5)/2	' 		vbt_desarmar					'						,	'Desarmar'					).OnEvent("Click",	desarmar)
	a.Add('Button','	xm	w'  w-5		' 										'						,	'Fechar'					).OnEvent("Click",	sair)
	a.Add('Button','xs		w100 			vbt_pgm_armar		Disabled','Armar PGM').OnEvent("Click", pgm_armar)
	a.Add('Button','	yp	w100 			vbt_pgm_desarmar	Disabled','Desarmar PGM').OnEvent("Click", pgm_desarmar)
	a.Show('x0 y0')

;	Interface da Central	
	WinGetPos &aX, &aY, &aW, &aH, 'KAH'
	b := Gui('+Owner')
	;b.Color(b,)

	
	b.Add('Text', ' vparticao_text Hidden 0x1001 h30 w585' b.SetFont('S12 Bold cWhite'), 'Partições da Central de Alarme' )

	b.SetFont('S10 Bold cWhite')
	Loop	8	;	partições
		b.Add('CheckBox', ' vparticao' A_index ' Hidden ' ( A_index = 5 ? 'ys' : '') ' ' (A_index = 1 ? 'Section' : '') , '00 Movimento' )	;	nome apenas para definir a medida

	b.Add('Text', ' vzonas_text Hidden 0x1001 h30 w585 xs' b.SetFont('S12 Bold cWhite') , 'Zonas da Central de Alarme' )

	b.SetFont('S10 Bold cWhite')
	Loop	32	;	máximo de zonas
		if(A_Index = 1)
			b.Add('CheckBox', ' vsensor' A_index ' Hidden xs Section' 													, Format('{:02}', A_index) ' Movimento' )	;	nome apenas para definir a medida
		Else
			b.Add('CheckBox', ' vsensor' A_index ' Hidden ' ( A_index = 11 || A_index = 21 || A_index = 31 ? 'ys' : '') , Format('{:02}', A_index) ' Movimento' )	;	nome apenas para definir a medida
	b.Show('x' aX+aW-15 ' y0	h' aH-38 '	w605 Hide' )

;	Inicia processos e carrega os dados
	start_socket(1,1)
	centrais(operador)
	start_server()
	OnExit(sair)
;

sair(ctrl,info)	{
	OutputDebug A_LineNumber '`tsair'
	Sock.Close()
	ExitApp 0
}

filtrar(ctrl,info)	{
	Loop
		if ( A_TimeIdleKeyboard > 750 )
			break
	filtro := a["filtro"].Text ? a["filtro"].Text : " "
	OutputDebug "-" filtro "-"
	a["unidade"].Delete()
	Loop	dados_unidades.Length-1
		If	InStr(dados_unidades[A_Index+1][2], filtro,'Locale')
			a["unidade"].Add(,dados_unidades[A_Index+1][2],dados_unidades[A_Index+1][1],dados_unidades[A_Index+1][3])

	a["unidade"].ModifyCol()
	a["unidade"].ModifyCol(2,0)
	a["unidade"].ModifyCol(3,0)

}

verificar_partições(ctrl,info)	{
	esconde_partições()
	esconde_zonas()
	Global	id		:= a["unidade"].GetText(info, 2)
		,	linha	:= info

	a["bt_desarmar"].enabled:= 1
	a["bt_armar"].enabled	:= 1
	OutputDebug	"Verifica partições ID: " id

	z := id '|particoes&'
	EnviarComando( z )
	verificar_zonas(ctrl,info)
}

verificar_zonas(ctrl,info)	{
	Global	id		:= a["unidade"].GetText(info, 2)
		,	linha	:= info

	a["bt_desarmar"].enabled:= 1
	a["bt_armar"].enabled	:= 1
	OutputDebug	"Verifica zonas ID: " id

	z := id '|zonas&'
	; Sleep 1000
	EnviarComando( z )
}

esconde_partições(partição?)	{
	if	!IsSet(partição)
		partição := 'x'
	OutputDebug 'sensor' (partição != 'x' ? partição : A_index)
	b['particao_text'].visible		:=	0
	loop	(partição = 'x' ? 8 : partição)
		b['particao' (partição != 'x' ? partição : A_index)].visible := 0
}

esconde_zonas(zona?)	{
	if	!IsSet(zona)
		zona := 'x'
	OutputDebug 'sensor' (zona != 'x' ? zona : A_index)
	b['zonas_text'].visible		:=	0
	loop	(zona = 'x' ? 32 : zona)
		b['sensor' (zona != 'x' ? zona : A_index)].visible := 0
}

armar(ctrl,info)	{
	a["bt_desarmar"].enabled:= 1
	a["bt_armar"].enabled	:= 0
	OutputDebug "Armar Id: " id

	z := id '|armar'
	z := '{"oper":[{"acao":"executar","idISEP":"' id '", "comando":[{"cmd":"armar", "password":8790, "particoes":[1]}]}]}'

	comando := EnviarComando( z )
	verificar_partições(ctrl,linha)

}

desarmar(ctrl,info)	{
	a["bt_desarmar"].enabled:= 1
	a["bt_armar"].enabled	:= 0
	OutputDebug "Desarmar Id: " id
	
	z := id '|desarmar'
	comando := EnviarComando( z )
	verificar_partições(ctrl,linha)

}

pgm_armar(ctrl,info)	{

	z := id '|armar_pgm'	
	comando := EnviarComando( z )

}

pgm_desarmar(ctrl,info)	{

	z := id '|desarmar_pgm'	
	comando := EnviarComando( z )
}

centrais(operator) {
	a["unidade"].ModifyCol(1,385)
	a["unidade"].ModifyCol(2,0)
	a["unidade"].ModifyCol(3,0)
	if(operator = 0)
		where := ""
	else
		where := " AND firebird.OPERADORA = " operator
	s	:=	"SELECT firebird.SEGUNDOCODIGO, firebird.NOME, firebird.OPERADORA FROM CLIENTES firebird WHERE firebird.CODIGO > 0"	where " ORDER BY 2"

	Global	dados_unidades	:=	sql(s)

	OutputDebug	"Carregando unidades do operador`n`tUnidades: " dados_unidades.Length-1
	Loop	dados_unidades.Length-1
		a["unidade"].Add(,dados_unidades[A_Index+1][2],dados_unidades[A_Index+1][1],dados_unidades[A_Index+1][3])

}

start_socket(ctrl,info)	{
	Global	sock
	port :=	12345
	sock :=	winsock("client", cb, "IPV4")
	sock.Connect("10.0.20.43", port, true)
	Global	socket_error := sock.errnum ? 1 : 0
	OutputDebug  "Iniciando cliente.`n`tCódigo de erro: " sock.errnum
	Switch	sock.errnum	{
		Case 10061:
			a['status'].SetFont('cRed s10 bold')
			a['status'].Text := 'Tentando reconectar na porta... ' port ' ' A_Now
			start_socket(ctrl,info)

		Default:
			a['status'].SetFont('cGreen s10 bold')
			a['status'].Text := 'Conectado'
	}

}

start_server()	{
	sock := winsock("server", cb, "IPV4")
	; sock.Bind("0.0.0.0",1)
	sock.Bind("0.0.0.0", 12345)
	sock.Listen()
	OutputDebug "Iniciando servidor.`n`tCódigo de erro: " sock.errnum

}

;	Funções

	EnviarComando( string ) {
		string := StrReplace(string, "id_da_central", id)
		strbuf := Buffer(StrLen(string)) ; for UTF-8, take strLen() + 1 as the buffer size
		StrPut(string, strbuf, "UTF-8")
		OutputDebug "Enviando comando`n`tComando:`n`t`t" StrReplace(string,"`t")
		if	sock.Send(strbuf) = 0	{
			OutputDebug	'Reiniciando conexão'
			start_socket(1,1)
			sleep 1000
			sock.Send(strbuf)
		}
		Return 1
	}

	cb(sock, event, err) {
		Global	informação_do_cliente
			,	comando
			MsgBox
		Switch	{
			Case	sock.name = "client":
				Switch	event	{
					Case	"Close":
						informação_do_cliente := ""
						sock.close()
	
					Case	"Connect":	; Conexão completa, se err = 0 então foi completo
						OutputDebug "Conectando à...`n`tEndereço:`t" sock.addr "`n`tPorta:`t" sock.port "`n"
	
					Case	"Write":	; Cliente pronto para envio ou leitura
						get_req	:= comando
						strbuf	:= Buffer(StrPut(get_req,"UTF-8"),0)
						StrPut(get_req,strbuf,"UTF-8")
						sock.Send(strbuf)
						Outputdebug "Enviado:`n`t" Trim(get_req,"`r`n") "`n"
	
					Case	"Read":		; Não vai haver informação para leitura
						buf := sock.Recv()
						informação_do_cliente .= StrGet(buf,"UTF-8")
	
				}

			Case	sock.name = "server", instr(sock.name,"serving-"):
				Switch	event	{
					Case	"Accept":
						sock.Accept(&addr,&newsock) ; pass &addr param to extract addr of connected machine
						OutputDebug "Server Accept`n`t" newsock.addr
	
					Case	"Close":
						OutputDebug "Server Close " A_LineNumber
						sock.close()
						Sleep	1000
						start_socket(1,1)
					Case	"Read":
						Sleep	100
						If !(buf := sock.Recv()).size ; Recebe o buffer, verifica o tamanho e retorna em buffer de tamanho zero
							return
						Sleep	100
						retorno := StrGet(buf,"UTF-8")
						Switch	{
						
							Case	InStr(retorno, '"cmd":"particoes"'):
								OutputDebug	"Tem partições"
								trata_Dados(retorno)
								b.Show()
								; a["bt_desarmar"].enabled:= inStr(retorno,'"armado":1')	? 1 : 0
								; a["bt_armar"].enabled	:= !inStr(retorno,'"armado":1')	? 1 : 0

							Case	InStr(retorno, '"cmd":"zonas"'):
								OutputDebug	"Tem zonas"
								trata_Dados(retorno)
								b.Show()

						}
						
						Outputdebug "Server Read:`n`t" StrReplace(retorno,"},{","},`n{")

				}

			Case	sock.name = "client-err":
				OutputDebug "Server Error"
				if(event = "connect") && err
					msgbox sock.name ": " event ": err: " err 

			Default:
				OutputDebug "Server Default"
				msgbox	sock.name
	
		}

	}

	trata_Dados(text)	{
		Switch	{
			Case	inStr(text, '"zonas"'):
				__ := json.Parse(text)
				__ := __['resp'][1]['resposta']
				b['zonas_text'].visible		:=	1
				Loop __.length	{
					status						:=	__[A_index]['aberta']		= 1 ? Format('{:02}', A_index) ' Movimento'
												:	__[A_index]['disparada']	= 1 ? Format('{:02}', A_index) ' Disparado'
												:	__[A_index]['tamper']		= 1 ? Format('{:02}', A_index) ' Tamper Violado'
												:	__[A_index]['inibida']		= 1 ? Format('{:02}', A_index) ' Inibido'
												:	__[A_index]['batlow']		= 1 ? Format('{:02}', A_index) ' Carga baixa'
												:	__[A_index]['temporizando']	= 1 ? Format('{:02}', A_index) ' Temporizando'
												:	Format('{:02}', A_index) ' Ok'
					b['sensor' A_Index].visible :=	1
					b['sensor' A_Index].Text	:=	status
					Switch	{
						Case	__[A_index]['aberta']:
							b['sensor' A_Index].Opt('cRed')
						Case	__[A_index]['disparada']:
							b['sensor' A_Index].Opt('cOrange')
						Case	__[A_index]['tamper']:
							b['sensor' A_Index].Opt('cPurple')
						Case	__[A_index]['inibida']:
							b['sensor' A_Index].Opt('cAqua')
						Case	__[A_index]['batlow']:
							b['sensor' A_Index].Opt('cWhite')
						Case	__[A_index]['temporizando']:
							b['sensor' A_Index].Opt('cOlive')
						Default:
							b['sensor' A_Index].Opt('cLime')
					}
				}

			Case	inStr(text, '"particoes"'):
				__ := json.Parse(text)
				__ := __['resp'][1]['resposta']
				b['particao_text'].visible		:=	1
				Loop __.length	{
					status						:=	__[A_index]['disparado']= 1 ? Format('{:02}', A_index) ' Disparada'
												:	__[A_index]['armado']	= 1 ? Format('{:02}', A_index) ' Armada'
												:	Format('{:02}', A_index) ' Desarmada'
					b['particao' A_Index].visible	:=	1
					b['particao' A_Index].Text		:=	status
					Switch	{
						Case	__[A_index]['disparado']:
							b['particao' A_Index].Opt('cRed')
						Case	__[A_index]['armado']:
							b['particao' A_Index].Opt('cLime')
						Default:
							b['particao' A_Index].Opt('cGray')
					}
				}

			; Default:
			; 	result	:=	RegexReplace(text,'},{','},`r`n`t{')
			; 	result	:=	RegexReplace(result,'\[{','[`r`n`t{')
			; 	result	:=	RegexReplace(result,'}\]','}`r`n`t]')
			; 	result	:=	RegexReplace(result,',"',',`t"')
			; 	result	:=	RegexReplace(result,':',' : ')

		}

	}