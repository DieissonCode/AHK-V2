QPX(T?, N?, M?, D?) ; v0.12 by SKAN for ah2 on CT91/D79D @ autohotkey.com/r?t=133066
{
    Static  F,  Q := DllCall("Kernel32\QueryPerformanceFrequency", "int64p",&F := 0)
    Return (  DllCall("Kernel32\QueryPerformanceCounter", "int64p",&Q)
           ,  Round( ((Q/F) - (T??0)) / (D??1) * (1000 ** (M??0)), N??7)  )
}

;*ScriptEnd*QPX.ah2*

#Requires AutoHotkey v2.0
#SingleInstance
ProcessSetPriority("High")

QPX() ; initialize static var (frequency)

; Basic example

t1 := t0 := QPX()
Sleep(-1)
t1 := QPX(t1)

t2 := QPX()
Sleep(1)
t2 := QPX(t2, 3)

t3 := QPX()
Sleep(50)
t3 := QPX(t3, 3)

t0 := QPX(t0, 3)

MsgBox( t1 "`n" t2 "`n" t3, "Overall: " t0 )


; Better examples

tt := QPX()
Sleep( Random(1000,2000) )
tt := QPX(tt, 2, 0)
MsgBox( tt "s", "Elapsed seconds" )

tt := QPX()
Sleep( Random(24,96) )
tt := QPX(tt, 1, 1)
MsgBox( tt "ms", "Elapsed milliseconds" )

tt := QPX()
, Sleep(-1)
, tt := QPX(tt, 0, 2)
MsgBox( tt "µs", "Elapsed microseconds" )


; Performance of QPX() tested wih QPX()

tt := QPX()
iter := 1000000

Loop ( iter )
       QPX()

tt := QPX(tt, 1, 2, iter)
MsgBox( "QPX() " tt "µs", "Average microsecond" )