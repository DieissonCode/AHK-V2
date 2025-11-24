#Requires AutoHotkey v2
;#include <UIA> ; Uncomment if you have moved UIA.ahk to your main Lib folder
#include ..\Lib\UIA.ahk
;#include <UIA_Browser> ; Uncomment if you have moved UIA_Browser.ahk to your main Lib folder
#include ..\Lib\UIA_Browser.ahk

Run "chrome.exe https://www.google.com/?hl=en -incognito" 
WinWaitActive "ahk_exe chrome.exe"
Sleep 3000 ; Give enough time to load the page
cUIA        := UIA_Browser()
search      := cUIA.FindElement({Name:"Search", Type:"ComboBox"})
search.Value:= "Hello!"
ExitApp