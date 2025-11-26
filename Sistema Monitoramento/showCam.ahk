;Save_To_Sql=1
;Keep_Versions=5
;@Ahk2Exe-Let U_FileVersion = 0.0.1.1
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Exibidor de Câmeras em Disparos
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\showcam.ico

#Requires AutoHotkey v2.0
#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Class\new_dguard.ahk


showCams(A_Args[1])

ExitApp(0)
showCams(alarmPlace)	{
		Layouts := DguardLayouts.get(Map('server', SysGetIPAddresses()[1]))
		Cameras := DguardCameras.get(Map('server', SysGetIPAddresses()[1], 'createMap', true))

		Dguard.CreateIndex(Layouts)	;	NECESSÁRIO para iniciar o índice
		Dguard.CreateIndex(Cameras)	;	NECESSÁRIO para iniciar o índice

		guid := DguardLayouts.create(Map('server', SysGetIPAddresses()[1], 'name', alarmPlace, 'layouts', layouts))	;	todos os servidores

		guidsForLayout := DguardCameras._abrevMap[alarmPlace]

		DguardAlarm.setAlarmLayout(Map('layoutGuid', guid, 'cameras', guidsForLayout, 'server', SysGetIPAddresses()[1]))
}