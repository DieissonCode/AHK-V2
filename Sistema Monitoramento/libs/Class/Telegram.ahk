#Requires AutoHotkey v2.0
if  IsSet(z_inc_telegram)
	Return

Global	z_inc_telegram	:=	1
	,	bot_token		:=	'https://api.telegram.org/bot1510356494:AAFkppxELD9JISyZglP0r0c-Q3STc4tKTpo'
	,	chat_id_test	:=	'-1001729068003'	;	canal de teste
	,	chat_id			:=	'-1001160086708'	;	canal de notificações de câmeras

/*
	header := '<a href=''http://10.1.1.1''>AGS [ BAL ] PTZ</a>[n]'
	ip = 10.1.1.1
	operador = 2
	sinistro = 3
	server = 01
	receiver = 10001
	id = 57
	text:=	header
		.	'Câmera Nova! [n]'
		.	'├─ <b>IP</b>................➝ <code>' 		IP		'</code>[n]'
		.	'├─ <b>Operador</b>➝ <code>'	operador			'</code>[n]'	
		.	'├─ <b>Sinistro</b>.....➝ <code>'	sinistro		'</code>[n]'
		.	'├─ <b>Servidor</b>...➝ <code>'		server			'</code>[n]'
		.	'├─ <b>Receptora</b>➝ <code>'	receiver			'</code>[n]'
		.	'└─ <b>ID</b>>..............➝ <code>'			ID	'</code>'
	telegram.sendmessage( text , 'parse_mode=html', 'chat_id=' chat_id_test )
	ExitApp, 0
*/

Class	Telegram {

	Static Request( url )					{
		req := ComObject( 'WinHttp.WinHttpRequest.5.1' )
		req.open( 'GET' , url , false )
		req.SetRequestHeader( 'If-Modified-Since', 'Sat, 1 Jan 2000 00:00:00 GMT' )
		req.send()
		if(	strLen( req.responseText ) = 0 ){
			req := ComObject('Msxml2.XMLHTTP')
			req.open( 'GET' , url , false )
			req.SetRequestHeader( 'If-Modified-Since', 'Sat, 1 Jan 2000 00:00:00 GMT' )
			req.send()
			return	req.responseText
		}
		return	req.responseText
	}

	Static SendMessage( texto, params* )	{
		;	exemplo de uso
			;	telegram.SendMessage( 'exemplo[n]```_texto_[n]*bold*```', 'parse_mode=markdownv2' , 'chat_id=-1001729068003' )
		if ( params.Length > 0 )
			Loop    params.Length	{									;	Altera chat_id da conversa destino se enviado
				if ( InStr( params[A_Index], 'chat_id' ) > 0 )	{
					chat_id	:=	SubStr( params[A_Index], InStr( params[A_Index] , '=' )+1 )
					Continue
				}
				parametros .= '&' params[A_Index]
			}
		; chat_id = 1597053632	;	Meu telegram
		url	:=	bot_token											        	;	URL e TOKEN do bot
			.	'/sendmessage?chat_id=' chat_id							            ;	Chat_id da conversa que deverá receber a msg
			.	'&text=' StrReplace(StrReplace( texto, '[n]:%0A'), '[t]:%09%09' )	;	Insere as novas linhas e tabulações no formato URI
			.	parametros												            ;	Adiciona parâmetros adicionas a mensagem
		; MsgBox % clipboard:=url
		; MsgBox % clipboard:=url '`n`n' StrRep( texto , , '[n]:%0A', '[t]:%09%09' )
		return	Telegram.Request( url )
	}

}