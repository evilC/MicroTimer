/*
Demo Script for MicroTimer

Converts Arrow Keys to mouse cursor, with 1ms move time for the mouse
*/

#SingleInstance force

asm := CLR_LoadLibrary("MicroTimer\MicroTimer.dll")
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

; =================================================================================================================
; ==========================================================
;                  .NET Framework Interop
;      http://www.autohotkey.com/forum/topic26191.html
; ==========================================================
;
;   Author:     Lexikos
;   Version:    1.2
;   Requires:	AutoHotkey_L v1.0.96+
;
; Modified by evilC for compatibility with AHK_H as well as AHK_L
; "null" is a reserved word in AHK_H, so did search & Replace from "null" to "_null"
CLR_LoadLibrary(AssemblyName, AppDomain=0)
{
	if !AppDomain
		AppDomain := CLR_GetDefaultDomain()
	e := ComObjError(0)
	Loop 1 {
		if assembly := AppDomain.Load_2(AssemblyName)
			break
		static _null := ComObject(13,0)
		args := ComObjArray(0xC, 1),  args[0] := AssemblyName
		typeofAssembly := AppDomain.GetType().Assembly.GetType()
		if assembly := typeofAssembly.InvokeMember_3("LoadWithPartialName", 0x158, _null, _null, args)
			break
		if assembly := typeofAssembly.InvokeMember_3("LoadFrom", 0x158, _null, _null, args)
			break
	}
	ComObjError(e)
	return assembly
}

CLR_CreateObject(Assembly, TypeName, Args*)
{
	if !(argCount := Args.MaxIndex())
		return Assembly.CreateInstance_2(TypeName, true)
	
	vargs := ComObjArray(0xC, argCount)
	Loop % argCount
		vargs[A_Index-1] := Args[A_Index]
	
	static Array_Empty := ComObjArray(0xC,0), _null := ComObject(13,0)
	
	return Assembly.CreateInstance_3(TypeName, true, 0, _null, vargs, _null, Array_Empty)
}

CLR_CompileC#(Code, References="", AppDomain=0, FileName="", CompilerOptions="")
{
	return CLR_CompileAssembly(Code, References, "System", "Microsoft.CSharp.CSharpCodeProvider", AppDomain, FileName, CompilerOptions)
}

CLR_CompileVB(Code, References="", AppDomain=0, FileName="", CompilerOptions="")
{
	return CLR_CompileAssembly(Code, References, "System", "Microsoft.VisualBasic.VBCodeProvider", AppDomain, FileName, CompilerOptions)
}

CLR_StartDomain(ByRef AppDomain, BaseDirectory="")
{
	static _null := ComObject(13,0)
	args := ComObjArray(0xC, 5), args[0] := "", args[2] := BaseDirectory, args[4] := ComObject(0xB,false)
	AppDomain := CLR_GetDefaultDomain().GetType().InvokeMember_3("CreateDomain", 0x158, _null, _null, args)
	return A_LastError >= 0
}

CLR_StopDomain(ByRef AppDomain)
{	; ICorRuntimeHost::UnloadDomain
	DllCall("SetLastError", "uint", hr := DllCall(NumGet(NumGet(0+RtHst:=CLR_Start())+20*A_PtrSize), "ptr", RtHst, "ptr", ComObjValue(AppDomain))), AppDomain := ""
	return hr >= 0
}

; NOTE: IT IS NOT NECESSARY TO CALL THIS FUNCTION unless you need to load a specific version.
CLR_Start(Version="") ; returns ICorRuntimeHost*
{
	static RtHst := 0
	; The simple method gives no control over versioning, and seems to load .NET v2 even when v4 is present:
	; return RtHst ? RtHst : (RtHst:=COM_CreateObject("CLRMetaData.CorRuntimeHost","{CB2F6722-AB3A-11D2-9C40-00C04FA30A3E}"), DllCall(NumGet(NumGet(RtHst+0)+40),"uint",RtHst))
	if RtHst
		return RtHst
	EnvGet SystemRoot, SystemRoot
	if Version =
		Loop % SystemRoot "\Microsoft.NET\Framework" (A_PtrSize=8?"64":"") "\*", 2
			if (FileExist(A_LoopFileFullPath "\mscorlib.dll") && A_LoopFileName > Version)
				Version := A_LoopFileName
	if DllCall("mscoree\CorBindToRuntimeEx", "wstr", Version, "ptr", 0, "uint", 0
	, "ptr", CLR_GUID(CLSID_CorRuntimeHost, "{CB2F6723-AB3A-11D2-9C40-00C04FA30A3E}")
	, "ptr", CLR_GUID(IID_ICorRuntimeHost,  "{CB2F6722-AB3A-11D2-9C40-00C04FA30A3E}")
	, "ptr*", RtHst) >= 0
		DllCall(NumGet(NumGet(RtHst+0)+10*A_PtrSize), "ptr", RtHst) ; Start
	return RtHst
}

;
; INTERNAL FUNCTIONS
;

CLR_GetDefaultDomain()
{
	static defaultDomain := 0
	if !defaultDomain
	{	; ICorRuntimeHost::GetDefaultDomain
		if DllCall(NumGet(NumGet(0+RtHst:=CLR_Start())+13*A_PtrSize), "ptr", RtHst, "ptr*", p:=0) >= 0
			defaultDomain := ComObject(p), ObjRelease(p)
	}
	return defaultDomain
}

CLR_CompileAssembly(Code, References, ProviderAssembly, ProviderType, AppDomain=0, FileName="", CompilerOptions="")
{
	if !AppDomain
		AppDomain := CLR_GetDefaultDomain()
	
	if !(asmProvider := CLR_LoadLibrary(ProviderAssembly, AppDomain))
	|| !(codeProvider := asmProvider.CreateInstance(ProviderType))
	|| !(codeCompiler := codeProvider.CreateCompiler())
		return 0

	if !(asmSystem := (ProviderAssembly="System") ? asmProvider : CLR_LoadLibrary("System", AppDomain))
		return 0
	
	; Convert | delimited list of references into an array.
	StringSplit, Refs, References, |, %A_Space%%A_Tab%
	aRefs := ComObjArray(8, Refs0)
	Loop % Refs0
		aRefs[A_Index-1] := Refs%A_Index%
	
	; Set parameters for compiler.
	prms := CLR_CreateObject(asmSystem, "System.CodeDom.Compiler.CompilerParameters", aRefs)
	, prms.OutputAssembly          := FileName
	, prms.GenerateInMemory        := FileName=""
	, prms.GenerateExecutable      := SubStr(FileName,-3)=".exe"
	, prms.CompilerOptions         := CompilerOptions
	, prms.IncludeDebugInformation := true
	
	; Compile!
	compilerRes := codeCompiler.CompileAssemblyFromSource(prms, Code)
	
	if error_count := (errors := compilerRes.Errors).Count
	{
		error_text := ""
		Loop % error_count
			error_text .= ((e := errors.Item[A_Index-1]).IsWarning ? "Warning " : "Error ") . e.ErrorNumber " on line " e.Line ": " e.ErrorText "`n`n"
		MsgBox, 16, Compilation Failed, %error_text%
		return 0
	}
	; Success. Return Assembly object or path.
	return compilerRes[FileName="" ? "CompiledAssembly" : "PathToAssembly"]
}

CLR_GUID(ByRef GUID, sGUID)
{
	VarSetCapacity(GUID, 16, 0)
	return DllCall("ole32\CLSIDFromString", "wstr", sGUID, "ptr", &GUID) >= 0 ? &GUID : ""
}