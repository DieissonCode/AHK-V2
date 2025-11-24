go := 1
if go
	FileSelectFile,	file_ahk
Else
	; File_ahk = C:\AutoHotkey\Core - Atualizações\Core - Moni\Ferramentas\teste versão.ahk
	File_ahk = C:\AutoHotkey\Core - Atualizações\Core - Moni\Ferramentas\Configurador de Presets.ahk
if	!file_ahk
	ExitApp
;	Includes
	#Include C:\AutoHotkey\class\base64.ahk
	#Include C:\AutoHotkey\class\functions.ahk
	#Include C:\AutoHotkey\class\sql.ahk

;	Configurações
	#SingleInstance, Force
	FileDelete, C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis\Compile_AHK.log
	FileRead, a,% File_ahk
	if InStr(a, "#Requires AutoHotkey v2.0")	{
		base	:=	"/base ""C:\Program Files\AutoHotkey\v2\Autohotkey64.exe"""
		is_v2	:=	1
	}
	ahk2exe	:=	"""C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"""
	in		:=	"/in """ file_ahk """"
	File_ahk:=	StrReplace(File_ahk, "ahk2", "ahk")
	out		:=	"/out ""C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis"	(file_name := StrReplace(SubStr( File_ahk, InStr( File_ahk, "\",,-1 ) ), ".ahk", ".exe") ) """"
	silent	:=	" /silent"
	log		:=	" >> ""C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis\Compile_AHK.log"""	;	se quiser gerar arquivo de log

;	Code
	RunWait, %comspec% /c "%ahk2exe% %in% %out% %base% %log% %silent%" , , UseErrorLevel Hide
	Run, C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis
	Run, C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis\Compile_AHK.log
	Sleep, 2000
	file_exe := "C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis" file_name
	FileGetTime, time,%	file_exe
	FileGetVersion, new_version_output, %	file_exe
	OutputDebug, % Datetime(,time) "`n" file_name "`t" new_version_output

	If(	A_Now - time < 300	)	{
		FileGetVersion, v,% file_exe := "C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis" file_name
		file_v		:= StrSplit(v, ".")
		file_name	:= SubStr(file_name,2,-4)
		sql_v		:= version(file_name)
		if	checkVersion(file_v, sql_v)	{	;	nova versão
			Switch	{
				Case InStr(a, "Save_to_Sql=1"):
					keep	:=	SubStr(a, InStr(a, "keep_versions=")+14,1)
					if	Keep	{
						d	=
							(
								DELETE FROM	[ASM].[dbo].[Softwares]
								WHERE	[name] = '%file_name%'
								AND		[PKID] NOT IN (
									SELECT TOP(%keep%) [pkid] FROM [ASM].[dbo].[Softwares] WHERE [name] = '%file_name%' ORDER BY PKID DESC)
							)
						sql(d)
					}
					file_b64	:=	base64.FileEnc( file_exe )
					_new_version:=	file_v[1] "." file_v[2] "." file_v[3] "." file_v[4]
					i	=
						(
							IF NOT EXISTS (SELECT [version] FROM [ASM].[dbo].[softwares] WHERE [version] = '%_new_version%' AND [name] = '%file_name%')
								BEGIN
									INSERT INTO
										[ASM].[dbo].[softwares]
										([name]
										,[bin]
										,[version]
										,[date]
										,[Obs])
									VALUES
										('%file_name%'
										,'%file_b64%'
										,'%_new_version%'
										,GetDate()
										,'%file_name%')
								END
						)
								; Clipboard := i
					sql(i)
					OutputDebug, % "Inserido no banco de dados"
			}

		}
	}

ExitApp	