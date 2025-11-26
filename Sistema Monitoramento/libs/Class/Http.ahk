Try	if	IsSet(z_inc_http)
	Return
_inc_http	:= 1

url	:= 'http://localhost:8081/api/login'

; msgbox Http.Call("http://admin:tq8hSKWzy5A@10.1.52.58/cgi-bin/magicBox.cgi?action=reboot")

class Http {

	Static new() {
		MsgBox
	}

	Static Call(url, auth:="", data?, method := "get", assync:= "") {
		return this.request(url, IsSet(auth) ? auth : "", IsSet(data) ? data  : "", IsSet(method) ? method : "get", IsSet(assync) ? assync : "")
	}

	Static delete( url, auth:='', data?  ) {			;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		r:= ComObject( 'Msxml2.XMLHTTP' )
		r.Open( 'DELETE', url, false )
		r.SetRequestHeader( 'Content-Type', 'application/json' )
		Try	if	auth
			r.SetRequestHeader( 'Authorization', 'Bearer ' auth )
		r.SetRequestHeader( 'If-Modified-Since', 'Sat, 1 Jan 2000 00:00:00 GMT' )
		r.Send()
		return	r.responseText

	}

	Static get( url, auth:="", data* ) {						;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		d	:= "{" SubStr( d, 1, -1 ) "}"
		r	:= ComObject( "Msxml2.XMLHTTP" )
		r.Open( "GET", url, false )
		r.SetRequestHeader( "Content-Type", "application/json" )
		Try	If	auth
			r.SetRequestHeader( "Authorization", "Bearer " auth )
		r.SetRequestHeader( "If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT" )
		r.Send( d )
		return	r.responseText

	}

	Static post( url, auth:="", data? ) {							;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		return	this.request(url, auth, data, "post")

	}

	Static put( url, auth:="", data? ) {						;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		this.request(url, auth, data, "PUT", 1)
	}

	Static request( url, auth:="", data?, method:="get", assync:="") {	;	https://www.autohotkey.com/boards/viewtopic.php?style=19&t=86128
		; unique := Random(1,500)
		url := StrReplace(url, "{", "%7B")
		url := StrReplace(url, "}", "%7D")
		Local r	:= ComObject( "Msxml2.XMLHTTP" )
		r.Open( method, url, assync ? true : false )
		r.SetRequestHeader( "Content-Type", "application/json" )
		Try	If	auth
			r.SetRequestHeader( "Authorization", "bearer " auth )
		r.SetRequestHeader( "If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT" )
		Try	IsSet(data) ? r.Send(data) : r.Send()

		If	!assync	{
			_ := r.responseText
			IsSet(_) ? __ := Trim(Trim( _,'`n'),'`r') : ""
			if(InStr(__, "Error") || InStr(__, "404 - Not Found") || InStr(__, "500 - Internal Server Error"))
				Return "Erro de conexão"
			else
				return __ = "ok" ? "Sucesso" : __
		}
		Else	{
			Return "UnSet"
		}

	}

}

; data :='
; 	(
; 	{	"username": "admin",
; 		"password": "@Dm1n"	}
; 	)'
; h := http()
; __ := h.post( url,, data )
; MsgBox __