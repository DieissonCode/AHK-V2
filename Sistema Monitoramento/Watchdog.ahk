
;Save_To_Sql=1
;Keep_Versions=3
#Requires AutoHotkey v2.0
#SingleInstance force
;@Ahk2Exe-Let U_FileVersion = 0.0.1.2
;@Ahk2Exe-SetFileVersion %U_FileVersion%
;@Ahk2Exe-Let U_C = KAH - Watchdog
;@Ahk2Exe-SetDescription %U_C%
;@Ahk2Exe-SetMainIcon C:\AHK\icones\watchdog.ico

#Include C:\AutoHotkey\AHK V2\Sistema Monitoramento\libs\Functions.ahk2
#NoTrayIcon
watchdog()
ExitApp(0)	;	redundante