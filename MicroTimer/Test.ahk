#SingleInstance force
#NoEnv

OutputDebug DBGVIEWCLEAR

#include CLR.ahk
/*
Test script for MicroTimer

Attempts to work out how accurate the timer is.
*/

#SingleInstance force

dllfile := "MicroTimer.dll"

if (!FileExist(dllfile)){
	MsgBox DLL Not found
	ExitApp
}
asm := CLR_LoadLibrary(dllfile)
; Use CLR to instantiate a class from within the DLL
mt := asm.CreateInstance("MicroTimer")
t1 := mt.Create(Func("Test"), 1)

; Initialize the test function
Test(1)
; Start the timer
t1.SetState(1)
; Let it gather some data
Sleep 1000
; Stop the timer
t1.SetState(0)
; Retreive data
result := Test(2)
clipboard := result
ToolTip % result
return

Test(init := 0){
	global t1
	static str := "", c:= 0, avg := 0
	elapsed := QPC() * 1000
	QPC(true)
	
	if (init){
		if (init == 1){
			str := ""
			c := 0
		} else {
			avg /= c
			str .= "`nAverage: " avg
			return str
		}
	} else {
		if (c != 0){
			; ignore first tick as we have no previous time to compare against
			avg += elapsed
			str .= elapsed ", "
		}
		c++
	}
}

^esc::
	ExitApp

QPC( R := 0 ) {    ; By SKAN,  http://goo.gl/nf7O4G,  CD:01/Sep/2014 | MD:01/Sep/2014
  Static P := 0,  F := 0,     Q := DllCall( "QueryPerformanceFrequency", "Int64P",F )
Return ! DllCall( "QueryPerformanceCounter","Int64P",Q ) + ( R ? (P:=Q)/F : (Q-P)/F ) 
}