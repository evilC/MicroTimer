#SingleInstance force
#NoEnv

#include CLR.ahk
/*
Demo Script for MicroTimer

Converts Arrow Keys to mouse cursor, with 1ms move time for the mouse
*/

#SingleInstance force

dllfile := "MicroTimer\MicroTimer.dll"

if (!FileExist(dllfile)){
	MsgBox DLL Not found
	ExitApp
}
asm := CLR_LoadLibrary(dllfile)
; Use CLR to instantiate a class from within the DLL
mt := asm.CreateInstance("MicroTimer")

XState := 0
YState := 0
XTimer := mt.Create(Func("MoveX"), 1)
YTimer := mt.Create(Func("MoveY"), 1)
return

MoveX(){
	global XState
	DllCall("user32.dll\mouse_event", "UInt", 0x0001, "UInt", XState, "UInt", 0, "UInt", 0, "UPtr", 0)
}

MoveY(){
	global YState
	DllCall("user32.dll\mouse_event", "UInt", 0x0001, "UInt", 0, "UInt", YState, "UInt", 0, "UPtr", 0)
}

XEvent(evt){
	global XState, XTimer
	XState := evt
	XTimer.SetState(abs(XState))
}

YEvent(evt){
	global YState, YTimer
	YState := evt
	YTimer.SetState(abs(YState))
}

~Left::
	XEvent(-1)
	return
	
~Right::
	XEvent(1)
	return

~Left up::
~Right up::
	XEvent(0)
	return
	
~Up::
	YEvent(-1)
	return

~Down::
	YEvent(1)
	return

up up::
down up::
	YEvent(0)
	return

^Esc::
	ExitApp