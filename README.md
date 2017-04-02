# MicroTimer
A DLL Wrapper for [Ken Loveday's MicroLibrary](https://www.codeproject.com/Articles/98346/Microsecond-and-Millisecond-NET-Timer), with AutoHotkey interop demo

## Usage in AHK
Instantiate the MicroTimer class from the DLL  
```
asm := CLR_LoadLibrary("MicroTimer\MicroTimer.dll")
; Use CLR to instantiate a class from within the DLL
mt := asm.CreateInstance("MicroTimer")
```

Instantiate a timer class instance using `Create(<callback>, <time in ms>, [<fireImmediately>])`  
`callback` is a Func Object (Or BoundFunc)  
`time in ms` can be negative to have the callback only fire once (like AHK's `SetTimer`)  
Optional `fireImmediately` can be set to true to fire a callback straight away.  

```
MyTimer := mt.Create(Func("MyFunc"), 1)
```  

Start / Stop the timer with `Start`, `Stop` or `SetState` (Pass SetState 0 or 1)
```
MyTimer.Start()
MyTimer.Stop()
MyTimer.SetState()
```

That's it!  
See the demo script for an example.  
