/*
	File_Version=0.1.0
	Save_To_Sql=1
	Keep_Versions=3
	Development=0
	Software_Name=Responsáveis e Informações
*/
#Requires AutoHotkey v2.0
#Warn All, Off
;	Debug options
	; function_debug := 1
;	Includes
	#Include libs\functions.ahk2
;

; If	A_IsCompiled
	; auto_update(,1)
	; sql_version(1, ,"Responsáveis e Informações")
;

;	Settings
	#SingleInstance Force
	CoordMode 'Tooltip', 'Screen'
	WinGetPos ,,,&h, 'ahk_class Shell_TrayWnd'
	Lime				:=	"c9DFF80"
	Gray				:=	"cA3A3A3"
	campos_listview		:=	['ID','Local','Safra','Meio','Abre','Fecha','Meio','Abre','Fecha','Unidade','entreposto','estabelecimento']
	largura				:=	A_ScreenWidth - 286
	altura				:=	A_ScreenHeight - h
	grupo_ativo			:=	1
	altura_da_lisview	:=	A_ScreenHeight-160-( A_ScreenDPI = 96 ? 50 : 60 )
	Switch	SubStr( SysGetIPAddresses()['1'], -3 )	{
	
		Case 101, 102, 103, 104:
			operador_atual := 1

		Case 105, 106, 107, 108:
			operador_atual := 2

		Case 109, 110, 111, 112:
			operador_atual := 3

		Case 113, 114, 115, 116:
			operador_atual := 4

		Case 117, 118, 119, 120:
			operador_atual := 5

		Case 121, 122, 123, 124:
			operador_atual := 6

		Case 100:
			operador_atual	:= 5

	}
	OutputDebug	A_LineNumber '`tConfigurações`n`tOperador ' operador_atual

;	Diretórios e ícones
	DirCreate	'C:\Users\' A_UserName '\AppData\Local\KahCool\Motion Detection'
	DirCreate	'C:\Users\' A_UserName '\AppData\Local\KahCool\Sistema Monitoramento'
	DirCreate	'C:\Users\' A_UserName '\AppData\Local\KahCool\Colaboradores'
	DirCreate	pasta_do_aplicativo := 'C:\Users\' A_UserName '\AppData\Local\KahCool'
	FileInstall	'C:\Seventh\Backup\ico\bman.png',	icone_homem	:= pasta_do_aplicativo	'\man.png',		1
	FileInstall	'C:\Seventh\Backup\ico\bwoman.png',	icone_mulher:= pasta_do_aplicativo	'\woman.png',	1
	OutputDebug A_LineNumber '`tDiretórios e ícones`n`t' pasta_do_aplicativo

;	Gui Seleção
	A:=Gui('-DPIScale -Border', 'Unidades Cotrijal'																								)
	A.Add('Radio',			'ym		w130	h30						voperador			Checked	Section'	A.SetFont('s10 ' Lime),	'Operador'	).OnEvent('Click',		FiltraOperador)
	A.Add('Radio',			'ys		wp		h30						vtodos_operadores			Section',								'Todas'	).OnEvent('Click',		FiltraOperador)
	A.Add('CheckBox',	'xm			w260	h30						vportão'							,			'Exibir horários do portão'	).OnEvent('Click',		OrganizaColunas)
	A.Add('Edit',		'xm			wp		h30						vfiltro_unidade'						A.SetFont('cBlack')				).OnEvent('Change',	   FiltraUnidades)
	A.Add('ListView',	'xm			wp		h' altura_da_lisview '	vlistview			Grid			',						campos_listview	).OnEvent('ItemSelect',	ExibeInformações)
	A.Add('Button',		'xm			wp											 '						carregar_dados(), 			'Fechar'	).OnEvent('Click',		Close)
	A.Show('x' largura '	y0		w280	h' altura	A.color(a, 374658))
	A['filtro_unidade'].Focus()

	B:=Gui('-DPIScale +Owner -Border', 'Responsáveis')
	CriaGui2()
	; B.Minimize()
Esc::close('1','1')

CriaGui2()	{
	A.GetClientPos(&wX, &wY, &wW, &wH)
	s1:=B.Add('Text','	x10	y0	w515	R2		vUnidade	Section	0x1001' B.SetFont('S10 Bold ' Lime),'' )
	B.Add('Button','	xs		w252 			vMapa',													'Mapa com Sensores de Alarme')
	B.Add('Button','		yp	w252			vSenha',												'Senha de Uso Único')

	B.Add('GroupBox','	xs		w515	h210	vS1	Center'	,											'Informações da unidade')
	B.Add('GroupBox','			w515	h210	vS2',													'Informações')
	B.Add('GroupBox','			w515	h230	vS3',													'Autorizados → Responsáveis')

	B['S1'].GetPos(&X, &Y, &W, &H)
	B.Add('Text', 'x' x+10 ' y' y+15,																	'Endereço')
	B.Add('Edit', 'xp	w' w-20 '		R2		vEndereço'			B.SetFont('cBlack S9') ' ReadOnly')
	B.Add('Text', ''												B.SetFont( Lime ' S10'),			'Emergência')
	B.Add('Listview','w' w-20 '			R3	 	vEmergência Grid	-HDR'	B.SetFont('cBlack S9'),		['Emergência','Telefone','Observação']).OnEvent("ItemSelect", (o, r, s) => B['Obs_Emergência'].Value := o.GetText( r, 3 ))
	B.Add('Edit', 'w' w-20 '			R2		vObs_Emergência')

	B['S2'].GetPos(&X, &Y, &W, &H)
	B.Add('Edit', 'x' x+10 ' y' y+20 ' w' w-20 ' h' h-30 ' vInformações')

	B['S3'].GetPos(&X, &Y, &W, &H), B['S3'].Move(,,,wH-y)
	B.Add('Edit', 'x' x+10 '	y' y+20 ' w' w-20 '	R1')
	B.Add('Listview','	xs+10	yp+25	w' w-20 '	vAutorizados	Grid	R10 -HDR',					['Nome','observação','Matrícula','telefone1','telefone2','sex','cpf','cargo']) ;.OnEvent("ItemSelect", (o, r, s) => B['Obs_Emergência'].Value := o.GetText( r, 3 ))
	B.Add('Edit','		xp				w' w-20	'	vObs_Autorizados')
	B['obs_autorizados'].GetPos(&X, &Y, &W, &H), B['obs_autorizados'].Move(,,,wh-y-15)
	B.Show('x' wX-542 ' y0 h' wH B.color(B, 374658))

}

carregar_dados()	{	;	chamado apenas uma vez
	OutputDebug	A_LineNumber '`tcarregar_dados()' 

	;	Unidades
		select	:=	'
				(	;	id iris | nome unidade | operador
				SELECT	a.[id],					--	1
						a.[local],				--	2
						b.[operador],			--	3
						b.[safra],				--	4
						b.[meio_manha],			--	5
						b.[abertura_manha],		--	6
						b.[fechamento_manha],	--	7
						b.[meio_tarde],			--	8
						b.[abertura_tarde],		--	9
						b.[fechamento_tarde],	--	10
						b.[entreposto],			--	11
						b.[estabelecimento]		--	12
				FROM
					[Sistema_Monitoramento].[dbo].[id locais] a
				LEFT JOIN
					[Cotrijal].[dbo].[unidades] b
				ON
					a.[entreposto] = b.[estabelecimento]
				ORDER BY
					2 ASC
			)'
		unidades:=	sql( select )
		Global	dados_unidade	:=	Map()

		OutputDebug	A_LineNumber '`tcarregar_dados()`n`tAdicionando dados á listview'

		Loop	unidades.Length-1	{
			nome								:=	RegexReplace(unidades[A_index+1][2], ' ', '_')
			dados_unidade[nome]					:=	Map()
			dados_unidade[nome].Default			:=	''

			dados_unidade[nome].id				:=	unidades[A_index+1][1]
			dados_unidade[nome].nome			:=	unidades[A_index+1][2]
			dados_unidade[nome].operador		:=	(unidades[A_index+1][2]	= "Sede Defensivos" ? 2 : unidades[A_index+1][3])
			dados_unidade[nome].safra			:=	(unidades[A_index+1][4]	= "" || unidades[A_index+1][4] = 0 ? "" : "Sim")
			dados_unidade[nome].meio_manha		:=	unidades[A_index+1][5]
			dados_unidade[nome].abre_manha		:=	unidades[A_index+1][6]
			dados_unidade[nome].fecha_manha		:=	unidades[A_index+1][7]
			dados_unidade[nome].meio_tarde		:=	unidades[A_index+1][8]
			dados_unidade[nome].abre_tarde		:=	unidades[A_index+1][9]
			dados_unidade[nome].fecha_tarde		:=	unidades[A_index+1][10]
			dados_unidade[nome].unidade			:=	dados_unidade[nome].nome = "UBS" ? 10
												:	dados_unidade[nome].nome = "Lagoa Vermelha CD Defensivos" ? 60
												:	SubStr( dados_unidade[nome].id, 1, Strlen(dados_unidade[nome].id) > 1 ? Strlen(dados_unidade[nome].id)-1 : Strlen(dados_unidade[nome].id) )
			dados_unidade[nome].entreposto		:=	unidades[A_index+1][11]
			dados_unidade[nome].estabelecimento	:=	unidades[A_index+1][12]
			dados_unidade.Capacity			:=	A_Index
			AdicionaUnidade(nome,operador_atual)

		}
		A['listview'].ModifyCol()
		OrganizaColunas()
	;	Informações
		select		:=	'
			(	;	nome | endereco | informação | lembrete | entreposto
				SELECT
					a.[nome],		--	1
					a.[endereco],	--	2
					a.[informacao],	--	3
					a.[lembrete],	--	4
					b.[entreposto],	--	5
					a.[unidade]		--	6
				FROM
					[Sistema_Monitoramento].[dbo].[informação_unidade] a
				LEFT JOIN
					[Sistema_Monitoramento].[dbo].[id locais] b
				ON
					a.[unidade] = b.[id]
				WHERE
					a.[ordem] = 'm'
				ORDER BY
					a.[ordem],
					a.[nome]
			)'
		informações	:=	sql( select )
		Global	informações_unidade	:=	Map()
		Loop	informações.Length-1	{
			unidade									:=	Format( '{:04}' ,informações[A_index+1][6])
			informações_unidade[unidade]			:=	Map()
			informações_unidade[unidade].Default	:=	''
			; informações_unidade.Default				:=	''

			informações_unidade[unidade].nome		:=	informações[A_index+1][1]
			informações_unidade[unidade].endereço	:=	informações[A_index+1][2]
			informações_unidade[unidade].informação	:=	informações[A_index+1][3]
			informações_unidade[unidade].informações:=	informações[A_index+1][4]
			informações_unidade[unidade].entreposto	:=	informações[A_index+1][5]
			informações_unidade[unidade].unidade	:=	unidade

			informações_unidade.Capacity			:=	A_Index
			; msgbox
		}
	;	Responsáveis
		select			:=	'
			(	;	nome | endereco | informação | lembrete | entreposto
				SELECT	[id_gerente]			--	1
						[id_administrativo],	--	2
						[id_operacional],		--	3
						[id_unidade],			--	4
						[id_local],				--	5
						[id_estabelecimento]	--	6
				FROM	[Cotrijal].[dbo].[responsaveis]
				WHERE	[id_local] IS NOT NULL
				ORDER BY	4
			)'
		responsaveis	:=	sql( select )
		Global	responsaveis_unidade	:=	Map()
		Loop	responsaveis.Length-1	{
			unidade									:=	Format( '{:04}' ,responsaveis[A_index+1][4] )
			responsaveis_unidade[unidade]			:=	Map()
			responsaveis_unidade[unidade].Default	:=	''
			responsaveis_unidade.Default			:=	''

			responsaveis_unidade[unidade].gerente		:=	responsaveis[A_index+1][1]
			responsaveis_unidade[unidade].administrativo:=	responsaveis[A_index+1][2]
			responsaveis_unidade[unidade].operacional	:=	responsaveis[A_index+1][3]
			responsaveis_unidade[unidade].unidade		:=	responsaveis[A_index+1][4]
			responsaveis_unidade[unidade].local			:=	responsaveis[A_index+1][5]
			responsaveis_unidade[unidade].entreposto	:=	unidade

			responsaveis_unidade.Capacity			:=	A_Index

		}
	;	Emergência
		select		:=	'
			(	;	nome | endereco | informação | lembrete | entreposto
				SELECT	DISTINCT
						[descricao],
						[telefone],
						[observacao],
						[unidade],
						[entreposto]
				FROM	[Sistema_Monitoramento].[dbo].[emergencia]
				ORDER BY 4
			)'
		emergência	:=	sql( select )
		Global	emergência_unidade	:=	Map()
		Loop	emergência.Length-1	{
			unidade											:=	Format('{:04}', emergência[A_index+1][4])
			Try
				IsObject(emergência_unidade[unidade])
			Catch	{
				emergência_unidade[unidade]					:=	Map()
				index										:=	0
			}
			index++
			emergência_unidade[unidade][Index]				:=	Map()
			emergência_unidade[unidade][Index].Default		:=	''
			emergência_unidade[unidade][index].descrição	:=	emergência[A_index+1][1]
			emergência_unidade[unidade][index].telefone		:=	emergência[A_index+1][2]
			emergência_unidade[unidade][index].observação	:=	emergência[A_index+1][3]
			emergência_unidade[unidade][index].unidade		:=	emergência[A_index+1][4]
			emergência_unidade[unidade][index].entreposto	:=	emergência[A_index+1][5]

		}
		
	;	Autorizados
		; select	:=	'
		; 	(
		; 		SELECT	b.[nome],
		; 				a.[observacao],
		; 				a.[matricula],
		; 				b.[telefone1],
		; 				b.[telefone2],
		; 				b.[sexo],
		; 				b.[cpf],
		; 				b.[cargo],
		; 				b.[cd_entreposto],
		; 				b.[cd_estab]
		; 		FROM		[Sistema_monitoramento].[dbo].[autorizados] a
		; 		LEFT JOIN	[ASM].[dbo].[_colaboradores] b
		; 		ON	a.[matricula] = b.[matricula]
		; 		WHERE	b.[nome] IS NOT NULL
		; 	)'
		; autorizado	:=	sql( select )
		; msgbox	autorizado.Length-1
	;	Colaboradores
		select		:=	'
			(	;	nome | endereco | informação | lembrete | entreposto
				SELECT
					[nome],
					[matricula],
					[usuario],
					[cargo],
					[email],
					[telefone1],
					[telefone2],
					[ramal],
					[cpf],
					[sexo],
					[c_custo],
					[setor],
					[local],
					[situacao],
					[cd_estab],
					[cd_entreposto],
					[cd_unidade]
				FROM	[ASM].[dbo].[_Colaboradores]
				ORDER BY 1

			)'
			Colaboradores	:=	sql( select )

		Global	Colaborador	:=	Map()
		Loop	Colaboradores.Length-1	{
			matricula						:=	Colaboradores[A_index+1][2]
			Colaborador[matricula]			:=	Map()
			Colaborador[matricula].Default	:=	''
			; Colaborador.Default				:=	''

			Colaborador[matricula].nome			:=	Colaboradores[A_index+1][1]
			Colaborador[matricula].matricula	:=	Colaboradores[A_index+1][2]
			Colaborador[matricula].usuario		:=	Colaboradores[A_index+1][3]
			Colaborador[matricula].cargo		:=	Colaboradores[A_index+1][4]
			Colaborador[matricula].email		:=	Colaboradores[A_index+1][5]
			Colaborador[matricula].telefone1	:=	Colaboradores[A_index+1][6]
			Colaborador[matricula].telefone2	:=	Colaboradores[A_index+1][7]
			Colaborador[matricula].ramal		:=	Colaboradores[A_index+1][8]
			Colaborador[matricula].cpf			:=	Colaboradores[A_index+1][9]
			Colaborador[matricula].sexo			:=	Colaboradores[A_index+1][10]
			Colaborador[matricula].c_custo		:=	Colaboradores[A_index+1][11]
			Colaborador[matricula].setor		:=	Colaboradores[A_index+1][12]
			Colaborador[matricula].local		:=	Colaboradores[A_index+1][13]
			Colaborador[matricula].situacao		:=	Colaboradores[A_index+1][14]
			Colaborador[matricula].cd_estab		:=	Colaboradores[A_index+1][15]
			Colaborador[matricula].cd_entrepos	:=	Colaboradores[A_index+1][16]
			Colaborador[matricula].cd_unidade	:=	Colaboradores[A_index+1][17]

			Colaborador.Capacity				:=	A_Index

		}

}

AdicionaUnidade(unidade, operador?)	{
	filtro	:=	A['filtro_unidade'].Value
	Switch	{
		Case	(operador && dados_unidade[unidade].operador != operador) || (filtro && !InStr(accent_off(dados_unidade[unidade].nome), accent_off(filtro) )):
			Return

		Default:
			A['ListView'].Add(
				,	dados_unidade[unidade].id
				,	dados_unidade[unidade].nome
				,	dados_unidade[unidade].safra
				,	dados_unidade[unidade].meio_manha
				,	dados_unidade[unidade].abre_manha
				,	dados_unidade[unidade].fecha_manha
				,	dados_unidade[unidade].meio_tarde
				,	dados_unidade[unidade].abre_tarde
				,	dados_unidade[unidade].fecha_tarde
				,	dados_unidade[unidade].unidade
				,	dados_unidade[unidade].entreposto
				,	dados_unidade[unidade].estabelecimento	)
	}

}

AdicionaAutorizados(id, estabelecimento)	{

	B['Autorizados'].Delete()
	select := '
		(
			SELECT	b.[nome],
					a.[observacao],
					a.[matricula],
					b.[telefone1],
					b.[telefone2],
					b.[sexo],
					b.[cpf],
					b.[cargo]
			FROM		[Sistema_monitoramento].[dbo].[autorizados] a
			LEFT JOIN	[ASM].[dbo].[_colaboradores] b
			ON	a.[matricula] = b.[matricula]
			WHERE	a.[unidade]			=	'
			)' id '
			(
				'
			AND		a.[estabelecimento]	=	'
			)' estabelecimento '
			(
				' AND b.[nome] IS NOT NULL
			)'

	autorizados := sql(select)
	Try	Loop	autorizados.Length-1
		B['Autorizados'].Add(
				,	autorizados[A_index+1][1]
				,	autorizados[A_index+1][2]
				,	autorizados[A_index+1][3]
				,	autorizados[A_index+1][4]
				,	autorizados[A_index+1][5]
				,	autorizados[A_index+1][6]
				,	autorizados[A_index+1][7]
				,	autorizados[A_index+1][8] )

	B['Autorizados'].ModifyCol(3)
	B['Autorizados'].ModifyCol(1,400)
	B['Autorizados'].ModifyCol(2,0)
	B['Autorizados'].ModifyCol(4,0)
	B['Autorizados'].ModifyCol(5,0)
	B['Autorizados'].ModifyCol(6,0)
	B['Autorizados'].ModifyCol(7,0)
	B['Autorizados'].ModifyCol(8,0)

}

FiltraOperador( control, value )	{
	A['filtro_unidade'].Value := ''
	radio := {}
	radio.value := ''
	A['filtro_unidade'].Focus()
	FiltraUnidades(radio)
}

FiltraUnidades( control, operador:='' )	{
	A['Listview'].Delete()
	operador := A['operador'].Value ? operador_atual : 0
	for unidade, v in dados_unidade
		AdicionaUnidade(unidade, operador )
	OrganizaColunas()

}

ExibeInformações( GuiCtrlObj, Item, Selected )	{
	if	!Selected	;	evita mudar os dados ao deselecionar o item anterior, pois o itemselect executa tanto ao selecionar quanto ao deselecionar
		return

	id	:=	Format('{:04}', GuiCtrlObj.GetText( Item , 1))
	mapa:=	FileExist( "C:\Seventh\Backup\map\" (_id := LTrim( id, "0" )) ".jpg" ) ? 1 : 0
		; senha	:=	StrLen( a := Iris.random_pass( unidade, "preload" ) ) ? 1 : 0	;	refazer Classe Iris
	OutputDebug A_LineNumber '`tExibeInformações`n`t' ID "`t" Selected
	B['Unidade'].Value		:= informações_unidade[id].Nome
	B['Endereço'].Value		:= informações_unidade[id].Endereço
	B['Informações'].Value	:= informações_unidade[id].informações
	B['Mapa'].GetPos(&X, &Y, &Width, &Height)
	Switch	{	;	Mapa e Senha

		Case IsSet(senha) && IsSet(mapa):
			B['Mapa'].Move(x,,252)
			B['senha'].Move(,'yp',252)
			B['Mapa'].Visible	:= 1
			B['Senha'].Visible	:= 1

		Case IsSet(senha):
			B['senha'].Move(x,y,510)
			B['Senha'].Visible	:= 1
			B['Mapa'].Visible	:= 0

		Case IsSet(mapa):
			B['Mapa'].Move(x,y,510)
			B['Mapa'].Visible	:= 1
			B['Senha'].Visible	:= 0

	}
	B['Emergência'].Delete()
	Try	Loop	emergência_unidade[id].Count
		B['Emergência'].Add(
				,	emergência_unidade[id][A_index].Descrição
				,	emergência_unidade[id][A_index].Telefone
				,	emergência_unidade[id][A_index].Observação	) 
	B['Emergência'].ModifyCol()
	B['Emergência'].ModifyCol(3,0)
	entreposto		:=	GuiCtrlObj.GetText( Item , 11)
	estabelecimento	:=	GuiCtrlObj.GetText( Item , 12)
	adicionaAutorizados(entreposto,estabelecimento)

}

close( control, value )	{
	ExitApp 0
}

OrganizaColunas(control?,nothing?)	{
	If	IsSet(control)	{
		if	control.Value
			aumenta := 400
		else
			aumenta := 0
	}
	if	!IsSet(control)
		aumenta := 0
	OutputDebug A_LineNumber '`t' aumenta
	Switch	{

		Case aumenta:
			A['listview'].ModifyCol(1,	0	)
			A['listview'].ModifyCol(2,	230	)
			A['listview'].ModifyCol(3,	45	)
			A['listview'].ModifyCol(4,	45	)
			A['listview'].ModifyCol(5,	45	)
			A['listview'].ModifyCol(6,	50	)
			A['listview'].ModifyCol(7,	45	)
			A['listview'].ModifyCol(8,	45	)
			A['listview'].ModifyCol(9,	50	)
			A['listview'].ModifyCol(10,70 " center")
			A['listview'].ModifyCol(11,	0	)
			A['listview'].ModifyCol(12,	0	)
			A.Move(largura-aumenta, 0, 280+aumenta, altura)

		Default:
			A['listview'].ModifyCol(1, 0)
			A['listview'].ModifyCol(2, 230)
			A['listview'].ModifyCol(3, 0)
			A['listview'].ModifyCol(4, 0)
			A['listview'].ModifyCol(5, 0)
			A['listview'].ModifyCol(6, 0)
			A['listview'].ModifyCol(7, 0)
			A['listview'].ModifyCol(8, 0)
			A['listview'].ModifyCol(9, 0)
			A['listview'].ModifyCol(10,0)
			A['listview'].ModifyCol(11,0)
			A['listview'].ModifyCol(12,0)
			A.Move(largura, 0, 280, altura)

	}

	A['ListView'].Move(,,260+aumenta,)
	A['Filtro_unidade'].Move(,,260+aumenta,)

}

; Gui_unidades:

	; OutputDebug, % "Gui_Unidades"
	; id	:=	LTrim( unidade, "0" )
	; Gui.Cores( "2", "", "" )
	; Gui, 2:-DPIScale
	; grupo_ativo:=	1

	; _uniname	:=	funcionarios[2, 1]
	; _endereco	:=	funcionarios[2, 2]
	; _infos		:=	funcionarios[2, 3]
	; _lembrete	:=	funcionarios[2, 4]
	; _entreposto	:=	funcionarios[2, 5]
	; mapa		:=	FileExist( "C:\Seventh\Backup\map\" (_id_unidade := LTrim( unidade, "0" )) ".jpg" ) ? 1 : 0
	; senha	:=	StrLen( a := Iris.random_pass( unidade, "preload" ) ) ? 1 : 0

	; ; Gui, 2: +Hwnd2
	; Gui, 2:Default
	; Gui, 2:Add,	Text,%	"	x10		y2		w510			Section	0x1001"										Gui.Font( "2:", "Bold", Lime, "S10")	,%	_uniname "`nID " LTrim( unidade, "0" ) (_entreposto ? "`tEntreposto " _entreposto : "")
	; 	Switch	{	;	Mapa e Senha

	; 		Case senha && mapa:
	; 			Gui, 2:Add,	Button,	xs				w250		gAbre_Mapa		,	Mapa de Sensores de Alarme
	; 			Gui, 2:Add,	Button,	xp+260	yp		w250		gLogin_Senhas	,	Senhas de Uso Único

	; 		Case senha:
	; 			Gui, 2:Add,	Button,	xs				w510		gLogin_Senhas	,	Senhas de Uso Único

	; 		Case mapa:
	; 			Gui, 2:Add,	Button,	xs				w510		gAbre_Mapa		,	Mapa de Sensores de Alarme

	; 	}
	; Gui, 2:Add,	GroupBox,	xs				w510	h215		Center																					,	Informações da Unidade
	; Gui, 2:Add,	Text,%	"	xp+7	yp+20"																		Gui.Font( "2:", Lime, "Bold" )			,	Endereço
	; Gui, 2:Add,	Edit,%	"	xp		yp+20	w497	h40"														Gui.Font( "2:", "Bold" )				,%	_endereco
	; Gui, 2:Add,	Text,%	"	xp		yp+50"																		Gui.Font( "2:", Lime, "Bold", "S10" )	,	Emergência
	; Gui, 2:Add,	ListView,% "xp		yp+20	w497	R3		Grid	AltSubmit	v_3		-HDR"					Gui.Font( "2:", "Bold" )				,	Emergência|Telefone|Observação
	; Gui, 2:Add,	Edit,		xp		yp+60	w497	h40		v_obs_emerg
	; Gui, 2:Add,	GroupBox,% "xs				w511	h205"														Gui.Font( "2:", "Bold", "S10", Lime )	,	Informações
	; Gui, 2:Add,	Edit,%	"	xp+7	yp+20	w497	h175"														Gui.Font( "2:", "Bold" )				,%	_lembrete

	; Gui, 2:Add,	GroupBox,% "xs				w510	h300			Section					" Gui.Font( "2:" )	Gui.Font( "2:", Lime, "Bold", "S10" )
	; Gui, 2:Add, Text,		xs+10	ys 						vgb1						gtog															,	Autorizados → Responsáveis
	; Gui, 2:Add, Edit,%	"	xp-3	yp+20	w497			v_filtro					gFiltra_autorizado"		Gui.Font( "2:" )
	; Gui, 2:Add, Listview,% "				w497	R6		vfl1	Grid	AltSubmit	gseleciona_autorizado"	Gui.Font( "2:", "Bold" )	" -HDR"		,	Nome|observação|Matrícula|telefone1|telefone2|sex|cpf|cargo
	; Gui, 2:Add, Edit,%	"	v_obs	yp+106	w497	h300	ved1	+readOnly"									Gui.Font( "2:", "cFFFF00", "S10" )
	; 	Gosub	Autorizados

	; Gui, 2:Add,	GroupBox,% "xs		ys		w510	h235					Hidden			" Gui.Font( "2:" )	Gui.Font( "2:", Lime, "Bold", "S10" )
	; Gui, 2:Add, Text,		xs+10	ys 						vgb2			Hidden		gtog															,	Responsáveis → Autorizados
	; Gui, 2:Add, Edit,%	"	xp-3	yp+20	w497			v_filtro4		Hidden		gFiltra_responsavel"	Gui.Font( "2:" )
	; Gui, 2:Add, Listview,% "				w497	R10		vfl2	Grid	Hidden		AltSubmit"				Gui.Font( "2:", "Bold" )	" -HDR"		,	Nome|Matrícula|Observação|telefone1|telefone2|ramal|sexo|cargo|situação
	; 	Gosub	Responsaveis
	; 	Gosub	Emergencia
	; Gui, 2:Show,%	"		x-2		y-1				h" altura																							,	Responsáveis

	; Gui, 1:-Disabled
	; Sleep, 100
	; ControlGetPos,  , _Y, ,,% "Button" __ := (mapa + senha = 2 ? 5 : mapa + senha = 1 ? 4 : 3), Responsáveis
	; ControlGetPos,  , _YY,,, Edit5, Responsáveis
	; OutputDebug, % _Y "`t" altura - (_Y+5)
	; GuiControl, MoveDraw,% "Button" (mapa + senha = 2 ? 5 : mapa + senha = 1 ? 4 : 3),% "h" altura - (_Y+5)
	; GuiControl, MoveDraw, Edit5,% "h" altura - (_YY+15)

; return

; ;	Emergência
; 	emergencia:

	; OutputDebug, % "Emergência"
	; Gui, 2:Default
	; Gui, Listview, _3
	; s	=
	; 	(
			; SELECT	[descricao],
			; 		[telefone],
			; 		[observacao]
			; FROM	[Sistema_Monitoramento].[dbo].[emergencia]
			; WHERE	[unidade]	=	'%id%'
			; AND		[entreposto]=	'%_entreposto%'
	; 	)
	; s	:=	sql( s, 3 )
	; Loop,% S.Count()-1
	; 	LV_Add(
	; 		,	s[A_Index+1,1]
	; 		,	StrLen( s[A_Index+1,2] )	= 3
	; 										? s[A_Index+1,2]	;	190
	; 										: String.Telefone( s[A_Index+1,2] )
	; 		,	s[A_Index+1,3])

	; LV_ModifyCol(1, 100)
	; LV_ModifyCol(2, 170)
	; LV_ModifyCol(3, 200)

; 	Return

; ;

; ;	Autorizados
; 	Autorizados:

	; OutputDebug, % "Autorizados"
	; Gui.Submit()
	; Gui, 2:Listview, fl1
	; LV_Delete()
	; _id_unidade_	:=	StrLen( _id_unidade ) > 1 ? SubStr( _id_unidade, 1, StrLen(_id_unidade)-1) : _id_unidade
	; s =
	; 	(
	; 		WITH PRE_LOAD AS (	SELECT	a.[matricula] as mat,
	; 						a.[observacao] as obs,
	; 						(SELECT TOP(1) [nome]		FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as nom,
	; 						(SELECT TOP(1) [telefone1]	FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as te1,
	; 						(SELECT TOP(1) [telefone2]	FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as te2,
	; 						(SELECT TOP(1) [sexo]		FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as sex,
	; 						(SELECT TOP(1) [cpf]		FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as cpf,
	; 						(SELECT TOP(1) [cargo]		FROM [ASM].[dbo].[_colaboradores] WHERE [matricula] = a.[matricula]) as car
	; 				FROM	[Sistema_monitoramento].[dbo].[autorizados] a
	; 				WHERE	a.[unidade]			=	'%_id_unidade_%'
	; 				AND		a.[estabelecimento]	=	'%_entreposto%'
	; 				%where% )
					
	; 		SELECT
	; 			*
	; 		FROM
	; 			PRE_LOAD
	; 		WHERE
	; 			[nom] LIKE '`%%_filtro%`%'
	; 		OR
	; 			[mat] LIKE '`%%_filtro%`%'
	; 		OR
	; 			[te1] LIKE '`%%_filtro%`%'
	; 		OR
	; 			[car] LIKE '`%%_filtro%`%'
	; 		OR
	; 			[cpf] LIKE '`%%_filtro%`%'

	; 	)

	; s	:=	sql( s, 3 )

	; Loop,% s.count()-1
	; 	Switch	{
		
	; 		Case !s[A_Index+1,3]:
	; 			Continue
	; 			; temp_mat	:=	s[A_Index+1,1]
	; 			; SQL("DELETE FROM [Sistema_monitoramento].[dbo].[autorizados] WHERE [matricula] = '%temp_mat%'")
				
	; 		Default:
	; 			LV_Add(
	; 				,	String.Name(s[A_Index+1,3] )	
	; 				,	s[A_Index+1,1]
	; 				,	s[A_Index+1,2]	;	observação
	; 				,	s[A_Index+1,4]
	; 				,	s[A_Index+1,5]
	; 				,	s[A_Index+1,6]
	; 				,	s[A_Index+1,7]
	; 				,	s[A_Index+1,8]	)

	; 	}


	; LV_ModifyCol(1, 385	)
	; LV_ModifyCol(2, 90	)
	; LV_ModifyCol(3, 0	)
	; LV_ModifyCol(4, 0	)
	; LV_ModifyCol(5, 0	)
	; LV_ModifyCol(6, 0	)
	; LV_ModifyCol(7, 0	)
	; LV_ModifyCol(8, 0	)

	; LV_ModifyCol(2, "Sort Integer")

; 	Return

; 	Filtra_autorizado:

	; OutputDebug, % "Filtra_Autorizados"
	; search_delay()
	; Gui.Submit()
	; Gosub	Autorizados

; 	Return

; 	seleciona_autorizado:

	; Switch	A_GuiEvent {

	; 	Case "Normal", "K", "RightClick":
	; 		OutputDebug, % "Seleciona_autorizado"
	; 		Gui, 2:Listview, fl1
	; 		Gui.Submit()
	; 		LV_GetText(obs, A_GuiEvent = "Normal" ? A_EventInfo : LV_GetNext(), 3)
	; 		GuiControl, 2:, ed1,% obs

	; }

; 	Return
; ;

; ;	Responsável
; 	Responsaveis:
		
	; 	OutputDebug, % "Responsáveis"
	; 	Gui.Submit()
	; 	Gui, 2:Listview, fl2
	; 	LV_Delete()
	; 	_id_unidade_	:=	SubStr( _id_unidade, 1, StrLen( _id_unidade )-1 )

	; 	Loop,	3	{

		; cargo	:=	A_Index = 1
		; 		?	"gerente"
		; 		:	A_index = 2
		; 		?	"administrativo"
		; 		:	"operacional"

		; s =
		; 	(
				; WITH PRE_LOAD AS (	SELECT		a.[id_%cargo%],
				; 								b.[nome],
				; 								b.[telefone1],
				; 								b.[telefone2],
				; 								b.[ramal],
				; 								b.[sexo],
				; 								b.[cargo],
				; 								b.[situacao]
				; 					FROM		[Cotrijal].[dbo].[responsaveis]	a
				; 					LEFT JOIN	[ASM].[dbo].[_Colaboradores]	b
				; 					ON			a.[id_%cargo%]			=	b.[matricula]
				; 					WHERE		a.[id_unidade]			=	'%_id_unidade_%'
				; 					AND			a.[id_estabelecimento]	=	'%_entreposto%'	)

				; SELECT
				; 	*
				; FROM
				; 	PRE_LOAD

		; 	)
		; 	; Msgbox	%	Clipboard := s
		; s	:=	sql( s, 3 )

		; if( (s.count()-1) = 0 )
		; 	Continue

		; Loop,% s.count()-1
		; 	Switch	{
			
		; 		Case	!s[A_Index+1,2]:
		; 			Continue:
					
		; 		Default:
		; 			LV_Add(
		; 				,	String.Name( s[A_Index+1,2] )
		; 				,	s[A_Index+1,1]
		; 				,	s[A_Index+1,3]
		; 				,	s[A_Index+1,4]
		; 				,	s[A_Index+1,5]
		; 				,	s[A_Index+1,6]
		; 				,	string.Cargo( s[A_Index+1,7] )
		; 				,	s[A_Index+1,8]	)

		; 	}



	; 	}

	; 	LV_ModifyCol(1, 170	)
	; 	LV_ModifyCol(2, 90	)
	; 	LV_ModifyCol(3, 0	)
	; 	LV_ModifyCol(4, 0	)
	; 	LV_ModifyCol(5, 0	)
	; 	LV_ModifyCol(6, 0	)
	; 	LV_ModifyCol(7, 150	)
	; 	LV_ModifyCol(8, 0	)

	; 	LV_Modify(1, "Sort")

	; Return

	; Filtra_responsavel:

	; 	OutputDebug, % "Filtra_responsavel"
	; 	search_delay()
	; 	Gui.Submit()
	; 	Gosub	responsaveis

; 	Return
; ;

; tog:
	
	; OutputDebug, % "Tog"
	; Gui.Submit()

	; Switch grupo_ativo	{

	; 	Case 1:
	; 		GuiControl, 2:Hide, gb1
	; 		GuiControl, 2:Hide, _filtro
	; 		GuiControl, 2:Hide, fl1
	; 		GuiControl, 2:Hide, ed1
	; 		GuiControl, 2:Show, gb2
	; 		GuiControl, 2:Show, _filtro4
	; 		GuiControl, 2:Show, fl2

	; 	Default:
	; 		GuiControl, 2:Show, gb1
	; 		GuiControl, 2:Show, _filtro
	; 		GuiControl, 2:Show, fl1
	; 		GuiControl, 2:Show, ed1
	; 		GuiControl, 2:Hide, gb2
	; 		GuiControl, 2:Hide, _filtro4
	; 		GuiControl, 2:Hide, fl2

	; }

	; grupo_ativo := !grupo_ativo

; Return

; Abre_Mapa:

	; OutputDebug, % "Abre_Mapa"
	; unidade :=	LTrim(unidade, "0")
	; Run, C:\Dguard Advanced\MDMapas.exe "%con%" "%ora%" "%unidade%" "%_uniname%"

; return

; 2GuiContextMenu()		{	;	mudar para um campo fixo na gui
	; ; ToolTip % A_GuiControl
	; if	clicado
	; 	Try {

	; 		Menu, ClickToCall, DeleteAll
	; 		Menu, ClickToCall, Delete
	; 		clicado := ""

	; 	}

	; Switch	A_GuiControl {

	; 	Case "fl1":	;	autorizados
	; 		clicado++
	; 		Gui, Listview,% A_GuiControl
	; 		LV_GetText( nome,		A_EventInfo, 1 )
	; 		LV_GetText( matricula,	A_EventInfo, 2 )
	; 		LV_GetText( num1,		A_EventInfo, 4 )
	; 		LV_GetText( num2,		A_EventInfo, 5 )
	; 		LV_GetText( sexo,		A_EventInfo, 6 )
	; 		LV_GetText( cpf,		A_EventInfo, 7 )
	; 		LV_GetText( cargo,		A_EventInfo, 8 )

	; 		numero1	:=	StrRep( string.telefone( num1 ),, "`t:" A_Space )
	; 		numero2	:=	StrRep( string.telefone( num2 ),, "`t:" A_Space )
	; 		photo	:=	image.load_profile_pic( matricula, "1" )

	; 		;	exibição do menu
	; 			Menu, ClickToCall, Add,%	string.name(nome) " - " string.cargo(cargo), call_num1			;	nome
	; 			Menu, ClickToCall
	; 				,	Icon
	; 				,%	string.name(nome) " - " string.cargo(cargo)
	; 				,%	photo ? photo : (sexo = "M" ? icone_homem : icone_mulher)
	; 				,
	; 				,	0
	; 			Menu, ClickToCall, Add
	; 			Menu, ClickToCall, Add,%	numero1, call_num1		;	numero

	; 			if( numero1 != numero2 && numero2) {

	; 				Menu, ClickToCall, Add
	; 				Menu, ClickToCall, Add,%	numero2, call_num2	;	numero

	; 			}

	; 		Menu, ClickToCall, Color,	9BACC0
	; 		Menu, ClickToCall, Show, 515,% A_GuiY

	; 	Case "fl2":	;	responsáveis
	; 		clicado++
	; 		Gui, Listview,% A_GuiControl
	; 		LV_GetText( nome,		A_EventInfo, 1 )
	; 		LV_GetText( matricula,	A_EventInfo, 2 )
	; 		LV_GetText( num1,		A_EventInfo, 3 )
	; 		LV_GetText( num2,		A_EventInfo, 4 )
	; 		LV_GetText( ramal,		A_EventInfo, 5 )
	; 		LV_GetText( sexo,		A_EventInfo, 6 )
	; 		LV_GetText( cargo,		A_EventInfo, 7 )
	; 		LV_GetText( situação,	A_EventInfo, 8 )

	; 		numero1	:=	StrRep( string.telefone( num1 ),, "`t:" A_Space )
	; 		numero2	:=	StrRep( string.telefone( num2 ),, "`t:" A_Space )
	; 		photo	:=	image.load_profile_pic( matricula, "1" )

	; 		;	exibição do menu
	; 			Menu, ClickToCall, Add,%	string.name(nome) " - " string.cargo(cargo), call_num1			;	nome
	; 			Menu, ClickToCall
	; 				,	Icon
	; 				,%	string.name(nome) " - " string.cargo(cargo)
	; 				,%	photo ? photo : (sexo = "M" ? icone_homem : icone_mulher)
	; 				,
	; 				,	0
	; 			Menu, ClickToCall, Add
	; 			Menu, ClickToCall, Add,%	numero1, call_num1		;	numero

	; 			if( numero1 != numero2 && numero2) {

	; 				Menu, ClickToCall, Add
	; 				Menu, ClickToCall, Add,%	numero2, call_num2	;	numero

	; 			}

	; 			if	ramal {

	; 				Menu, ClickToCall, Add
	; 				Menu, ClickToCall, Add,%	ramal, call_ramal	;	numero

	; 			}

	; 		Menu, ClickToCall, Color,	9BACC0
	; 		Menu, ClickToCall, Show, 515,% A_GuiY

	; 	Case "_3":	;	emergencia
	; 		clicado++
	; 		Gui, Listview,% A_GuiControl
	; 		police := "C:\Seventh\Backup\ico\guardinha.ico"
	; 		LV_GetText( nome,	A_EventInfo, 1 )
	; 		LV_GetText( num,	A_EventInfo, 2 )
	; 		numero1	:=	StrRep( num,, "`t:" A_Space )

	; 		;	exibição do menu
	; 			Menu, ClickToCall, Add,%	nome, call_num1		;	nome
	; 			Menu, ClickToCall, Icon,%	nome,% police, , 0	;	icone
	; 			Menu, ClickToCall, Add							;	divisor
	; 			Menu, ClickToCall, Add,%	numero1, call_num1	;	numero

	; 		Menu, ClickToCall, Color,	9BACC0
	; 		Menu, ClickToCall, Show, 515,% A_GuiY

	; }

; 	Return


; 	call_num1:
		; convert.call( RegexReplace( StrLen( numero1 ) = 3 ? "0" numero1 : numero1, "\D" ) )

; 	Return

; 	call_num2:
		; convert.call( RegexReplace(numero2, "\D") )

; 	Return

; 	call_ramal:
		; convert.call( RegexReplace(ramal, "\D") )

; 	Return

; Login_Senhas:

	; autenticou := auth.login(1,,,,1,1)

	; Loop	{

	; 	Sleep, 500
	; 	If	StrLen( autenticou )	{

	; 		if( SubStr( autenticou, 1, 1 ) = 1 )
	; 			Break

	; 		else if( SubStr( autenticou, 1, 1 ) = 0 )	{

	; 			WinSet,	AlwaysOnTop,	Off,	Login Cotrijal
	; 			MsgBox,,Autenticação Falhou,	Verifique seu usuário e senha.
	; 			paused = 0
	; 			Return

	; 		}

	; 	}

	; }
	; Gui.Cores( "login_senhas", "", "" )
	; Gui, login_senhas: -DPIScale
	; Gui.Font( "login_senhas:", "S11 Bold cYellow"  )
	; Gui, login_senhas:Add,	Text, 	x10		y10		w450	h40	+Center				,	A senha de uso único só deve ser gerada em caEmergência de emergência:
	; Gui, login_senhas:Add,	Text, 	x10		y200	w450	h40						,	Seu coordenador será notificado do compartilhamento dessa senha. Justifique abaixo.
	; 	Gui,	login_senhas:Font,	S9 Bold cWhite
	; Gui, login_senhas:Add,	Text, 	x10		y50		w450	h70	0x1000				,	Onde:`n`tNão seja possível fazer o desarme remoto da central.`n`tQue não haja ninguém com senha no local.`n`tQue o desarme seja devidamente autorizado por um dos responsáveis da unidade`, preferencialmente com registro por e-mail.
	; Gui, login_senhas:Add,	Text, 	x10		y130	w450	h60	0x1000				,	Necessitando registro de:`n`tQuem autorizou.`n`tPorque foi gerado.`n`tPara quem foi passado a senha.
	; 	Gui,	login_senhas:Font
	; Gui, login_senhas:Add,	Edit,	x10		y240	w450	h50	vreason
	; Gui, login_senhas:Add,	Button, xm				w220	gSenhas_Unicas			,	Confirmar
	; Gui, login_senhas:Add,	Button, xp+230			w220	glogin_senhasGuiClose	,	Cancelar
	; Gui, login_senhas:Show,,	Justificativa

; return

; login_senhasGuiClose:

	; Gui.Destroy("login_senhas")

; return

; Senhas_Unicas:		;{	03/12/2020

	; Gui.Submit("login_senhas")
	; Gui.Destroy("login_senhas")

	; if	!InStr(autenticou,"1") || !autenticou
	; 	return

	; senha	:=	Iris.random_pass( unidade, SubStr( autenticou, 3 ) "&" reason )

	; r	:=	"INSERT INTO [Logs].[dbo].[Log_ASM] ([data],[software],[user],[descricao],[local],[cmp1]) VALUES"
	; 	.	"('" datetime(1) "',"
	; 	.	"'MDResp',"
	; 	.	"'" SubStr( autenticou, 3 ) "',"
	; 	.	"'Senha de uso único:`n`t"	reason	"',"
	; 	.	"'"	unidade	"',"
	; 	.	"'"	senha	"')"

	; sql( r, 3 )

	; MsgBox, ,Senha de Uso único, %	"Senha:`n`t"	senha
	; 							.	"`n`nDisponibilizada em:`n`t" datetime()
	; 							.	"`n`nPara o usuário:`n`t" SubStr(autenticou,3)
	; 							.	"`n`nDa central de id:`n`t"	unidade
	; 							.	"`n`nDevido a:`n`t" reason
	; senha := reason := autenticou := ""

; return

; 2GuiCLose:

	; Gui.Destroy("2")
	; Gui, 1:Default
	; Process, Close, MDMapas.exe
	; Gui,	login_senhas:Destroy

; return

; Esc::

	; GuiClose:
	; Gui,	login_senhas:Destroy
	; Process, Close, MDMapas.exe

; ExitApp

Get(this, Key, Params) {

	; in this way Return the value of MapObj.Default, if defined:
	try {
		if !Params.Length
			return this[key] ;Or this.Get(Key)
	
		return this[key][Params*]
		
	} catch UnsetItemError
		throw UnsetItemError(Key)
}