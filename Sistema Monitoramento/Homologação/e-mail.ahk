#Requires AutoHotkey v2.0
html:=	1
#Warn All, Off
;	Bibliotecas
	z_functions	:= 0
	#Include ..\libs\functions.ahk
;	Variáveis
	;	html
		html_default:=	"	;	9BACC0
			(
				<!DOCTYPE html><html><head>
				<STYLE TYPE="text/css" MEDIA=screen>
				<!--
				html { background-color:#9BACC0;}
				-->
				</STYLE></head>
			)"
		modo_html	:=	0

	activex		:=	"xs		w610	h319"						(modo_html ? "" : " Hidden")
	b_add		:=	"xs		w300	h30	Section"
	b_clear		:=	"ys		w300	h30"
	b_reload	:=	"xs		w600	h30"
	c_days		:=	"xs		w200	h25	Section"
	c_comp		:=	"ys		w200	h25			Disabled"
	c_html		:=	"ys		w180	h25"
	date_time	:=	"xs		w200	h30	Section"
	ddl			:=	"ys		w500	R25			Sort"
	e_content 	:=	"xp	yp	w610	h319		+WantTab"		(modo_html ? " Hidden" : "")
	e_show		:=	"xs		w600	h200"

	l_hist		:=	"ym		w600	R11	Section	Grid"
	title		:=	"x10	w610	h30	Section			0x1201"
	t_unidade	:=	"xs		w100	h24	Section	Center	0x1200"

;	Opções da Interface
			a	:=	Gui(,"Adicionar E-Mail")
			a.SetFont( "cFFFFFF bold S10")
			a.BackColor	:=	"c374658"

;	Preparação da Interface
			a.Add(					"Text",		title,		"ADICIONAR E-MAIL"						)
			a.Add(					"DateTime",	date_time,	"dd/MM/yyyy HH:mm:ss"					).OnEvent("Change", change_date)
			html		:=	a.Add(	"Checkbox",	c_html,		"Cópia em modo HTML"					)
			comp		:=	a.Add(	"Checkbox",	c_comp,		"Adicionar mais html"					)
			a.Add(					"Checkbox",	c_days,		"Mais de um dia"						)
			a.Add(					"Text",		t_unidade,	"Unidade:"								)
			unid		:=	a.Add(	"Ddl",		ddl													)
			email_obj	:=	a.Add(	"Activex",	activex,	"HTMLFile"								)
			a.SetFont(), a.SetFont( "S10")
			email_novo	:=	a.Add(	"Edit",		e_content											)
			a.Add(					"Button",	b_add,		"Adicionar"								).OnEvent("Click", adicionar)
			a.Add(					"Button",	b_clear,	"Limpar"								).OnEvent("Click", limpar)
			hist		:=	a.Add(	"ListView",	l_hist,		["Unidade","Assunto","Inserido","ID"]	)			
			email_texto	:=	a.Add(	"Edit",		e_show												)
			a.Add(					"Button",	b_reload,	"Recarregar Avisos"						).OnEvent("Click", recarregar)

;	Carrega os dados
			carrega_emails()
			carrega_unidades()

;	Exibe a interface
			a.Show()

;	Chamadas dos botões
			hist.OnEvent("Click", email_selecionado)
			html.OnEvent("Click", alterna_html)
			email_com	:=	email_obj.value
			email_com.Write(html_default)


;	Checkbox
	alterna_html(ctrl, info)	{

		Global	modo_html := !modo_html
			,	html_default

		Switch	modo_html	{
			Case	1:
				comp.opt("-Disabled")
				email_novo.opt("+Hidden")
				email_obj.opt("-Hidden")
				email_com.Write(html_default)

			Default:
				comp.opt("+Disabled")
				comp.value := 0
				email_novo.opt("-Hidden")
				email_obj.opt("+Hidden")
				email_novo.Value := A_Clipboard
		}

		OnClipboardChange(ClipboardChanged)

	}

	ClipboardChanged(*)	{
		ClipboardAll()
		html	:= Clipboard_to_html()
		texto	:= A_Clipboard
		Switch	{	;	Conseguiu pegar o HTML
		
			Case	html:
				Switch	{	;	é complemento html
				
					Case	comp.value:
						html_antigo := email_com.GetSelection().ToString()
						html := html_antigo "<hr>" html

					Default:
						email_com.Close()

					}
				email_com.Write(html)

			Default:
				email_novo.opt("-Hidden")
				email_obj.opt("+Hidden")
				email_novo.Value := texto

		}
		TipoDeMensagem(texto)
	}

;	Edit
	_email_novo(ctrl, info)	{

		email_texto.value	:=	ctrl.GetText(info,2)

	}

	email_selecionado(ctrl, info)	{

		email_texto.value	:=	ctrl.GetText(info,2)

	}

;	Listview
	carrega_emails()	{

		hist.Delete()
		s	:= "
			(
				SELECT TOP 100
						p.[Mensagem]
					,	c.[Nome]
					,	p.[Inserido]
					,	p.[pkid]
					,	p.[Id_Cliente]
				FROM
					[IrisSQL].[dbo].[Clientes]	c
				LEFT JOIN
					[ASM].[ASM].[dbo].[_Agenda]	p
				ON
					p.[Id_Cliente] = c.[IdUnico]
				WHERE p.[inserido] IS NOT NULL
				ORDER BY
					3 DESC
			)"
		dados_lv := sql( s )

		Loop	dados_lv.Length-1
			hist.Add(
					,	dados_lv[A_Index+1][2] = "Ocomon"
												? "Chamado"
												: dados_lv[A_Index+1][2]
					,	inStr(dados_lv[A_Index+1][1], "<html>")
						?	StrRep( RegexReplace(dados_lv[A_Index+1][1], "<.*?>"),,"`r","`n`n:`n")
						:	dados_lv[A_Index+1][1]
					,	dados_lv[A_Index+1][3]
					,	dados_lv[A_Index+1][4]	)
		hist.ModifyCol( 1 , 140 )
		hist.ModifyCol( 2 , 250 )
		hist.ModifyCol( 3 , 140 )
		hist.ModifyCol( 4 , 40 )

	}

;	DropDownList
	carrega_unidades()	{

		s	:= "
			(
				SELECT
						[Nome]
					,	[IdUnico]
					,	[Classe]
					,	[ContaMaster]
				FROM
					[IrisSQL].[dbo].[Clientes]
				WHERE
					[Cliente] = '10001'	AND
					[Particao] > '001'
				ORDER BY
					1
				ASC
			)"
		u := sql( s )
		
		unidades	:=	[]
		Loop	u.Length-1	{

			unidade		:=	u[A_Index+1][1] = "Ocomon" ? "Chamado" : u[A_Index+1][1]
			If	InStr( unidade, "-" )
				unidade	:=	StrReplace( unidade, "-", " " )
			unidadeid	:=	u[A_Index+1][2] "-" u[A_Index+1][3] "-" u[A_Index+1][4]
			unidades.Push( Format("{:T}", unidade ) )
			; unidades	:=	unidades "`n" Format("{:T}", mensagem.remove_accents( unidade ) )
			; forid		:=	Format("{:T}", mensagem.remove_accents( unidade ) ) "-" unidadeid "`n" forid
			; forid		:=	Format("{:T}", unidade ) "-" unidadeid "`n"

		}

		unid.Add(unidades)

	}

;	Botões
	adicionar(Button, info)	{
		msgbox("wtf 1")
		
	}

	limpar(Button, info)	{
		email_novo.Value	:=	""
		email_com.Close()
		email_com.location.reload()
		email_com.Write("")
		
	}

	recarregar(Button, info)	{
		msgbox("wtf 3")
		
	}

;	Funções
	TipoDeMensagem(texto)	{
		solicitação := facilitador := inicio_do_texto := 0
		; search_delay()
		line	:= "`n____________________________________`n"
		xx		:= ""
		mensagem	:= StrSplit( texto, "`n" )
		Switch	{	;	Auto select da unidade no drop down list
			Case InStr(texto, "Solicitante/Funcionário"):					;	Engeman
				atendimento	:= ""
				texto		:= RegexReplace( texto, "(\r\n|\r|\n)(\s*(\r\n|\r|\n))+", "`n")
				mensagem	:= StrSplit( texto , "`n" )
				engeman 	:= []

				Loop	mensagem.Length {
					Switch	{
					
						Case	InStr(mensagem[A_Index], "Código"):
							engeman.Push("Código Engeman - " mensagem[A_Index+1])
							Continue

						Case	InStr(mensagem[A_Index], "Data Solicitação"):

							data1		:= SubStr(mensagem[A_Index+1], 1, 5)
							data2		:= SubStr(mensagem[A_Index+1], 12, 5)
							engeman.Push(data1 " " data2)
							Continue

						Case	InStr(mensagem[A_Index], "Solicitante"):

							solicitante := StrSplit(mensagem[A_Index+1], " - ")
							solicitante := StrSplit(solicitante[2], " ")
							engeman.Push(Format( "{:T}", Solicitante[1]))
							Continue

					}

					If( mensagem[A_Index] = "Solicitação" )
						solicitação := A_index

					If( A_Index > Solicitação && Solicitação )
						atendimento .= mensagem[A_Index] "`n"

					if( A_Index = mensagem.Length )
						email_novo.value :=	engeman[1] line
										.	"`n" engeman[2]
										.	"`n" Format( "{:U}", SubStr(atendimento, 1, 1) ) Format( "{:L}", SubStr(atendimento, 2, -1) ) line engeman[3]

				}

				unid.Text	:=	"Chamado"
				; Gosub inserir_email

			Case InStr(texto, "A coprel informa a seguinte" ):				;	Energia - Desligamento programado
				coprel(texto, line)

			Case InStr(texto, "Área Responsável" ), InStr(texto, "ATD-"):	;	Chamado
				Switch	{
				
					Case InStr(texto, "ATD-"):
						inmsg := StrSplit( StrRep( texto, "`r" ), "`n" )
						Loop	inmsg.Length
							Switch	{
							
								Case	A_Index = 1:
									atd		:=	inmsg[A_index] "`n"

								Case	A_Index = 2:
									assunto	:=	inmsg[A_index]

								Case	InStr( inmsg[A_Index], "Mais antigo" ):
									facilitador :=	line  SubStr( inmsg[a_index+1], 1, InStr( inmsg[A_index+1], " " )-1 )
												.	"`n`tAdicionado:`n`t" SubStr(inmsg[a_index+2], -12)
									If	!inicio_do_texto
										inicio_do_texto	:=	A_index+3

								Case	inicio_do_texto:
									If( A_Index >= inicio_do_texto )
										texto_	.= inmsg[A_Index] "`n"

							}

				}

				texto_			:=	regexreplace(texto_, "^\s+")
				email_novo.Value:=	atd assunto line "`n" texto_ facilitador
				unid.Text		:=	"Chamado"
				; Gosub	inserir_email

			Default:
				Loop	mensagem.Length
					Switch	{
						Case InStr( mensagem[A_Index], "Unidade - ") && !InStr( mensagem[A_Index], " Unidade - "):
							unid.Text	:=	unidade_ := StrRep( mensagem[ A_Index ], "Unidade - ", "`r" )
							Break

						Case	InStr( mensagem[A_Index], "Expodireto - Coordenadora Administrativa")
							,	InStr( mensagem[A_Index], "Expodireto Cotrijal"):
							unid.Text	:=	unidade_ := "Sede   Expodireto"
							Break
					
						Case	InStr( mensagem[A_Index], "/RS"):
							unid.Text	:=	unidade_ := SubStr( mensagem[A_Index], 1, InStr(mensagem[A_Index], "/")-1 )
							Break

						Default:
							unidade := 0

					}

				Switch	unidade_	{	;	BLOCO NÃO VALIDADO
					Case 0:
						Switch	{
			
							Case InStr(internal_text, "Gerente Produção de Sementes"):
								unid.Text	:=	"UBS"
			
						}
			
					Case "Novos Negócios E Produção Animal":
						Switch	{
			
							Case InStr(internal_text, "TRR - "):
								unid.Text	:=	"TRR"
			
							Case InStr(internal_text, "Fábrica de Rações - "):
								unid.Text	:=	"Sede   Fabrica De Racao"
			
						}
			
					Case "Varejo":
						Switch	{
			
							Case InStr(internal_text, "Supermercado Sede - "):
								unid.Text	:=	"Sede   Supermercado"
			
							Case InStr(internal_text, "CD Loja PF - ") && InStr(internal_text, "Loja PF Centro - "):
								unid.Text	:=	"Passo Fundo"
			
							Case InStr(internal_text, "CD Lojas - ") && InStr( internal_text, "Não-Me-Toque/RS" ):
								unid.Text	:=	"Sede   Loja CD"
			
							Case InStr(internal_text, "Lojas - ") && InStr( internal_text, "Não-Me-Toque/RS" ):
								unid.Text	:=	"Sede   Loja"
			
							Case InStr(internal_text, "Loja - Coordenador De Loja") && InStr( internal_text, "Não-Me-Toque/RS" ):
								unid.Text	:=	"Sede   Loja"
			
							Case InStr(internal_text, "Supermercados -") && InStr( internal_text, "Não-Me-Toque/RS" ):
								unid.Text	:=	"Sede   Supermercado Centro"
			
							Case InStr(internal_text, "CD Supermercados - ") && InStr( internal_text, "Não-Me-Toque/RS" ):
								unid.Text	:=	"Sede   Supermercado Centro"
			
							Case InStr(internal_text, "Supermercado Fontoura Xavier - ") && InStr( internal_text, "Fontoura Xavier/RS"):
								unid.Text	:=	"Fontoura Xavier"
			
							; Case InStr(internal_text, ""):
								; Return	""
			
						}
			
					Case "Não-Me-Toque":
						Switch	{
			
							Case InStr(internal_text, "CD - Defensivos - "):
								unid.Text	:=	"Sede   Defensivos"
			
							; Case InStr(internal_text, ""):
							; 	Return	""
			
						}
			
					Case "Produção Vegetal":
						Switch	{
			
							Case InStr(internal_text, "Unidade Beneficiamento Sementes" ):
								unid.Text	:= "UBS"
			
						}
						
					Case "Expodireto Cotrijal":
						unid.Text	:=	"Sede   Expodireto"
			
					Case "Esmeralda":
						Switch	{
			
							Case InStr(internal_text, "Juvêncio" ):
								unid.Text	:= "Esmeralda Juvencio"
			
						}
			
					Case "Vila Maria Anita Garibaldi":
						unid.Text	:= "Vila Maria Garibaldi"
			
			
					Case "Carazinho Glória":
						unid.Text	:= "Carazinho   Gloria"
			
				}
				OutputDebug unidade_
				unid.Text	:=	StrRep(unidade_,"/RS","\RS")
		
		}

		; hora_agenda	:=	RegExReplace( Format_Time(texto), "\D")
		; data_agenda	:=	RegExReplace( Format_Date(texto), "\D")

		; if	!data_agenda && InStr(texto, "amanhã")
		; 	data_agenda	:=	A_YYYY A_MM A_DD + 1

		; if(	SubStr( data_agenda , 5 , 2 ) > A_MM || SubStr( data_agenda , 7 , 2 ) > A_DD )	;	Altera se a data for posterior a atual
		; 	GuiControl,, _date,%	data_agenda ( hora_agenda ? hora_agenda : "073000" )

		; else if( hora_agenda > A_Hour A_Min )
		; 	GuiControl,, _date,%	A_YYYY A_MM A_DD hora_agenda


	}

	Coprel(email, line)	{

		atendimento	:= ""
		email		:= RegexReplace( email, "(\r\n|\r|\n)(\s*(\r\n|\r|\n))+", "`n")
		inmsg		:= StrSplit( email , "`n" )
		desligamento:= []
		Loop	inmsg.Length	{

			OutputDebug	inmsg[A_Index]
			Switch	{
			
				Case InStr(inmsg[A_Index], "As interrupções são feitas para garantir energia de qualidade na vida dos cooperantes."):
					desligamento.Push(atendimento)

				Case InStr(inmsg[A_Index], "DESLIGAMENTOS PROGRAMADOS"):
					desligamento.Push(inmsg[A_Index])

				Case InStr(inmsg[A_Index], "Dia: "):
					data_agenda	:=	StrRep( inmsg[A_Index],"|","Dia: " )
					RegExReplace( RegExReplace( data_agenda, "\D" ), "(..)(..)(..)", "20$3-$2-$1")
					msgbox

				Default:
					If desligamento.Capacity = 0
						Continue
					atendimento	.=	StrRep( inmsg[A_Index]
										,	"|"
										,	"Dia:|`nDia:"
										,	"Horário(s):|`nHorário(s):"
										,	"Motivo:|`nMotivo:") "`n"

			}

		}
		unid.Text		:=	"Avisos Monitoramento"
		email_novo.Value:=	 desligamento[1] line "`n" desligamento[2]

	}