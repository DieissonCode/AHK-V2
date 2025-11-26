#Requires AutoHotkey v2.0
Try	if	IsSet(z_inc_email)
	Return

; Email.send("dieisson13@gmail.com","E-Mail de Teste","Teste de corpo de e-mail")
Global	z_inc_email := 1

Class	Email	{
	Static Send( to, subj, body, custom_name:="", cc*) {
		static mail
		has_cc := cc.Length
		Switch	{
			Case has_cc = 1:
				Switch	cc[1] {
					Case "monitoramento":
						copy := "monitoramento@cotrijal.com.br"
					Case "facilitador":
						mail := 'dsantos@cotrijal.com.br,egraff@cotrijal.com.br,ddiel@cotrijal.com.br'
						Loop	mail.Count()
							copy .=	mail[A_Index] (A_Index = mail.Count() ? "" : ",")
					Default:
						copy := cc

				}

			Case has_cc > 1:
				Loop	cc.Length
					copy .= cc[A_Index] ( A_Index = has_cc ? "" : "," )

			Default:
				copy := ""

		}

		pmsg		:= ComObject( "CDO.Message" )
		Switch	{
			Case InStr(body, "<html>"):
				pmsg.HtmlBody := body
			Default:
				pmsg.TextBody := body

		}

		pmsg.From	:= custom_name
			?	'"' custom_name '" <do-not-reply@cotrijal.com.br>"'
			:	'"Sistema Monitoramento" <do-not-reply@cotrijal.com.br>'
		pmsg.To		:= to
		pmsg.Subject:= subj
		pmsg.CC		:= copy

		fields						:= Object()
		fields.smtpserver			:= "mail.cotrijal.com.br"
		fields.smtpserverport		:= 25
		fields.smtpusessl			:= false
		fields.sendusing			:= 2
		fields.smtpauthenticate		:= 1
		fields.sendusername			:= fields.sendpassword := ""
		fields.smtpconnectiontimeout:= 15

		schema := "http://schemas.microsoft.com/cdo/configuration/", pfld := pmsg.Configuration.Fields
		for field, value in fields.OwnProps()
			pfld.Item[schema . field] := value
		pfld.Update()
		pmsg.Send()

	}

}