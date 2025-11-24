#Requires AutoHotkey v2
;#include <UIA> ; Uncomment if you have moved UIA.ahk to your main Lib folder
#include ..\Lib\UIA.ahk
;#include <UIA_Browser> ; Uncomment if you have moved UIA_Browser.ahk to your main Lib folder
#include ..\Lib\UIA_Browser.ahk

/**
 * This example demonstrates automating a login page.
 * 
 * CAUTION: DO NOT use this with Google or other big companies login pages. UIAutomation may be
 * detected as botting and your browser will get banned from logging in. Gmail detects this 
 * kind of automation for example.
 */

Run "chrome.exe https://www.w3schools.com/howto/howto_css_login_form.asp -incognito" 
WinWaitActive "ahk_exe chrome.exe"
Sleep 3000 ; Give enough time to load the page
cUIA := UIA_Browser()

try {
    ; Might ask for permission to store cookies
    cUIA.FindElement({Name:"Accept all & visit the site"}).Click()
    OutputDebug	a_now ' elemento'
    ; Sleep 500
}

; Click the Login button
cUIA.FindElement({Name:"Login", Type:"Button"}).Click()
OutputDebug	a_now ' login selecionado'
; Enter username and password
cUIA.WaitElement({Name:"Enter Username", Type:"Edit"}).Value := "MyUsername"
OutputDebug	a_now ' username'
passwordEdit := cUIA.FindElement({Name:"Enter Password", Type:"Edit"})
passwordEdit.Value := "MyPassword"
OutputDebug	a_now ' senha'
; Uncheck the "Remember me" option
cUIA.FindElement({Name:"Remember me", Type:"Checkbox"}).Toggle()
OutputDebug	a_now ' desmarcado'
; Find the first Login button, starting the search from the passwordEdit element.
; If we did the search without the startingElement argument, then instead the first login button would be pressed.
; (Try removing the startingElement part: ", startingElement:passwordEdit") 
cUIA.FindElement({Name:"Login", Type:"Button", startingElement:passwordEdit}).Highlight().Click()
OutputDebug	a_now ' feito'
ExitApp