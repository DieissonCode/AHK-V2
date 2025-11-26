if	IsSet(z_inc_base64)
	Return

Global	z_inc_base64 := 1

Class Base64 {

	Static Enc(&Src)				{	;  By SKAN for ah2 on D672/D672 @ autohotkey.com/r?p=534720
		OutputDebug	'Enc'
		Local  Bytes  :=  Src.Size
			,  RqdCap :=  1 + (( Ceil(Bytes*4/3) + 3 ) & ~0x03)
			,  Trg    :=  ""

		VarSetStrCapacity(&Trg, RqdCap - 1)
		DllCall("Crypt32\CryptBinaryToString", "ptr",Src, "int",Bytes, "int",0x40000001, "str",Trg, "intp",&RqdCap)

		Return Trg
	}

	Static Dec(&Src)				{	;  By SKAN for ah2 on D672/D672 @ autohotkey.com/r?p=534720
		OutputDebug	'Dec'
		Local  EqTo    :=  (SubStr(Src,-2,1) = "=") + (SubStr(Src,-1) = "=")   ;  = count
			,  nBytes  :=  (StrLen(Src) - EqTo) * 3 // 4                       ;  Target bytes
			,  Trg     :=  Buffer(nBytes)

		DllCall("Crypt32\CryptStringToBinary", "str",Src, "int",StrLen(Src), "int",0x1, "ptr",Trg, "intp",&nBytes, "int",0, "int",0 )

		Return Trg
	}

	Static FileEnc(Src)				{	;  By SKAN for ah2 on D672/D672 @ autohotkey.com/r?p=534720
		OutputDebug	'FileEnc'
		Src	:=	FileRead(Src, "RAW")
		Static mCode
		If  Not IsSet(mCode)
		{
			mCode := Buffer(352 + 64, 0)

			If  ( A_PtrSize =  8 )  ;  x64 size:349
				NumPut("int64",0x4156415441575653, "int64",0x548b445824448b57, "int64",0xc08545db31456024, "int64",0xdb3100000098860f
					, "int64",0xdf893234b60fde89, "int64",0xdc8941013a7cb60f, "int64",0x8941022264b60f46, "int64",0xf6894502eec141f6
					, "int64",0x47df894531348a46, "int64",0x8341f68941393488, "int64",0x894104e6c14103e6, "int64",0xfe094504efc141ff
					, "int64",0x4531348a46f68945, "int64",0x410239748847df89, "int64",0xc1410fe68341fe89, "int64",0xefc141e7894502e6
					, "int64",0x46f68945fe094506, "int64",0x8847df894531348a, "int64",0x8341e48945043974, "int64",0x894521248a463fe4
					, "int64",0x83410631648847de, "int64",0xc3394403c38308c3, "int64",0xc085ffffff6a820f, "int64",0xb60f42c089415974
					, "int64",0x027cb60fc0890234, "int64",0x048a02e8c1f08901, "int64",0x01048843d8894501, "int64",0x04e0c103e083f089
					, "int64",0x4404e8c141f88941, "int64",0x4501048ac089c009, "int64",0x830201448843d889, "int64",0x8af88902e7c10fe7
					, "int64",0x448843d889450104, "int64",0x44c641d889440401, "int64",0x3b74d285453d0601, "int64",0x890234b60fd08944
					, "int64",0x4401048a02e8c1f0, "int64",0xe68311048841da89, "int64",0x048af08904e6c103, "int64",0x11448841da894401
					, "int64",0x0144c641d8894402, "int64",0x44c641d889443d04, "int64",0x415e415f413d0601, "int64",0xc35b5e5f5c
					,  mCode)
									;  x86 size:288
			Else  NumPut("int64",0x56530cec83e58955, "int64",0x3114558b08458b57, "int64",0x31767600107d83c9, "int64",0x373cb60f0c7d8bf6
					, "int64",0xb60f0c7d8bf47d89, "int64",0x7d8bfc7d8901377c, "int64",0x7d8902377cb60f0c, "int64",0x8a02efc1f47d8bf8
					, "int64",0xf47d8b0a1c88381c, "int64",0x5d8b04e7c103e783, "int64",0x1c8adf0904ebc1fc, "int64",0xfc7d8b020a5c8838
					, "int64",0x5d8b02e7c10fe783, "int64",0x1c8adf0906ebc1f8, "int64",0xf87d8b040a5c8838, "int64",0x5c88381c8a3fe783
					, "int64",0x03c68308c183060a, "int64",0x187d838c7210753b, "int64",0x7d8b0c758b507400, "int64",0xf475893e34b60f18
					, "int64",0xb60f1875030c758b, "int64",0xf4758bfc75890176, "int64",0x1c88301c8a02eec1, "int64",0xc103e683f4758b0a
					, "int64",0x04efc1fc7d8b04e6, "int64",0x0a5c88301c8afe09, "int64",0x8a0fe683fc758b02, "int64",0x44c6040a5c88b01c
					, "int64",0x74001c7d833d060a, "int64",0x0f1c7d8b0c758b30, "int64",0xeec1f475893e34b6, "int64",0x8b0a1c88301c8a02
					, "int64",0x04e6c103e683f475, "int64",0xc6020a448830048a, "int64",0x060a44c63d040a44, "int64",0xc35dec895b5e5f3d
					,  mCode)

			DllCall("Kernel32\VirtualProtect", "ptr",mCode, "ptr",352, "uint",0x40, "uintp",0)
			StrPut("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", mCode.Ptr+352, 64, "cp0") ;  Base64 lookup table
		}

		Local  Tail   :=  Mod(Src.Size, 3)
			,  sBytes :=  Src.Size - Tail
			,  nBytes := ( Ceil(Src.Size*4/3) + 3 ) & ~0x03
			,  Trg

		VarSetStrCapacity(&Trg, nBytes)

		DllCall( mCode, "ptr",   mCode.Ptr + 352               ;  Lookup table
					, "ptr",   Src                           ;  Source string
					, "int",   sBytes                        ;  Source bytes
					, "str",   Trg                           ;  Target string
					, "int",   Tail=2 ? sBytes : 0           ;  Tail 2 bytes
					, "int",   Tail=1 ? sBytes : 0           ;  Tail 1 byte
					, "cdecl" )
		Return Trg
	}

	Static FileDec(&Src, Fullpath)	{	;  By SKAN for ah2 on D672/D672 @ autohotkey.com/r?p=534720
		OutputDebug	'FileDec'
		Static mCode
		If  Not IsSet(mCode)
		{
			mCode := Buffer(256 + 256, 0)

			If  ( A_PtrSize =  8 )  ;  x64 size:251
				NumPut("int64",0x448b485441575653, "int64",0x455024548b4c4824, "int64",0x317376c08545db31, "int64",0x00000000801f0fdb
					, "int64",0x0f3234b60f48de89, "int64",0xdf8912e6c13134b6, "int64",0xb60f023a7cb60f48, "int64",0x89fe090ce7c1393c
					, "int64",0x0f043a7cb60f48df, "int64",0xfe0906e7c1393cb6, "int64",0x063a7cb60f48df89, "int64",0x8944fe09393cb60f
					, "int64",0x08ecc141f48941df, "int64",0xc4c14166e4894566, "int64",0x8944392489456608, "int64",0x83410239748841df
					, "int64",0xc3394408c38303c3, "int64",0x483c760038809672, "int64",0xc11114b60f10b60f, "int64",0x460240b60f4c12e2
					, "int64",0x0ce0c1410104b60f, "int64",0x0440b60f48c20944, "int64",0x0906e0c10104b60f, "int64",0x66d0896608eac1c2
					, "int64",0x4166da894408c0c1, "int64",0x76003a8041110489, "int64",0x04b60f02b60f4924, "int64",0x52b60f4d12e0c101
					, "int64",0xe2c11114b60f4202, "int64",0x894410e8c1d0090c, "int64",0x5f5c4111048841da, "int64",0xc35b5e
					,  mCode)
									;  x86 size:238
			Else  NumPut("int64",0x565304ec83e58955, "int64",0x310c558b08458b57, "int64",0x315d7600107d83c9, "int64",0x3cb60f323cb60ff6
					, "int64",0x325cb60f12e7c138, "int64",0x0ce3c1181cb60f02, "int64",0x0f04325cb60fdf09, "int64",0xdf0906e3c1181cb6
					, "int64",0x1cb60f06325cb60f, "int64",0x7d8bfc7d89df0918, "int64",0x6608ebc1fc5d8b14, "int64",0x8b0f1c896608c3c1
					, "int64",0x0f5c88fc5d8a147d, "int64",0x3b08c68303c18302, "int64",0x8018558ba5721075, "int64",0x0f18558b3b76003a
					, "int64",0xe2c11014b60f12b6, "int64",0x0276b60f18758b12, "int64",0x090ce6c13034b60f, "int64",0x0476b60f18758bf2
					, "int64",0x0906e6c13034b60f, "int64",0x08c2c16608eac1f2, "int64",0x8b0e14896614758b, "int64",0x8b2876003a801c55
					, "int64",0x14b60f12b60f1c55, "int64",0x0f1c758b12e2c110, "int64",0xc13004b60f0276b6, "int64",0x8810eac1c2090ce0
					, "int64",0x5f0a048814558bd0, "int64",0xc35dec895b5e
					,  mCode)

			DllCall("Kernel32\VirtualProtect", "ptr",mCode, "ptr",256, "uint",0x40, "uintp",0)

			NumPut("short",0x3332,  NumPut("int64",0x31302F2E2D2C2B2A, NumPut("int64",0x2928272625242322,         ; Base64 lookup table
			NumPut("int64",0x21201F1E1D1C1B1A,  NumPut("char",0x19,    NumPut("int64",0x1817161514131211,
			NumPut("int64",0x100F0E0D0C0B0A09,  NumPut("int64",0x0807060504030201, NumPut("int",0x3D3C3B,
			NumPut("int64",0x3A3938373635343F,  NumPut("char",0x3E, mCode,256 + 43)+3))+7))))+6))))
		}

		Local  Tail    :=  SubStr(Src, -4)                     ;  Tail 4 bytes
			,  EqTo    :=  4 -  StrLen(RTrim(Tail,"="))        ;  = count
			,  SBytes  :=  StrLen(Src) * 2 - (EqTo ? 8 : 0)    ;  Source bytes
			,  nBytes  :=  (StrLen(Src) - EqTo) * 3 // 4       ;  Target bytes
			,  Trg     :=  Buffer(nBytes)                      ;  Target buffer

		DllCall( mCode, "ptr",   mCode.Ptr + 256               ;  Lookup table
					, "str",   Src                           ;  Source string
					, "int",   sBytes                        ;  Source bytes
					, "ptr",   Trg                           ;  Target buffer
					, "str",   EqTo=1 ? Tail : ""            ;  Tail with =
					, "str",   EqTo=2 ? Tail : ""            ;  Tail with ==
					, "cdecl" )
		Base64.Bin2Exe(&Trg, Fullpath)
		Return Trg
	}

	Static Bin2Exe(&bin, fullpath)	{
		OutputDebug	'bin2exe'
		dir := StrSplit(fullpath,"\")
		dir := StrReplace(fullpath, "\" dir[dir.Length] )
		if	!DirExist(dir)
			try DirCreate(dir)
		; Try	{
			file := FileOpen(fullpath, "w")	;	cria o arquivo
			file.RawWrite(Bin)				;	escreve o binário nele
			file.Close()					;	fecha o arquivo
		; }
	}
}
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; fileInput := "C:\Users\dsantos\OneDrive - Cotrijal Cooperativa Agropecuária e Industrial\Área de Trabalho\Executáveis\gestor de unidades.exe"
; fileOutput := "C:\Autohotkey\AHK V2\teste.exe"
; Try	filedelete(fileOutput)
; Txt :=  base64.FileEnc(fileInput)
; Base64.FileDec(&Txt,fileOutput)
; Run(fileOutput)
; ExitApp 0