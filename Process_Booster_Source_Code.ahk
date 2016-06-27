#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#InstallKeybdHook
#SingleInstance Force

;----------------------------------------------------------------------------------------------------
; Read Config File
;----------------------------------------------------------------------------------------------------

FileRead, Hotkey_Variable, Process_Booster_Config.txt
Hotkey_Variable := StrReplace(Hotkey_Variable, "Hotkey=")
Gui, Add, Text,, Press
Gui, Add, Hotkey, x+10 y2 vNew_Hotkey_Variable
GuiControl,, New_Hotkey_Variable,  %Hotkey_Variable%
Gui, Add, Text, x12, to open the Process_Booster window.
Gui, Add, Button, gApply_Settings, Okay
Gui, Show
return

;----------------------------------------------------------------------------------------------------
; Create Interface Window
;----------------------------------------------------------------------------------------------------

Show_Window:
{
	IfWinExist, ahk_exe Process_Booster.exe
	{
		WinActivate, ahk_exe Process_Booster.exe
	}
	else
	{
		WinGetTitle, This_Window, A
		WinGet, This_Process, ProcessName, A
		Gui, Add, Text,, Process "%This_Process%" detected.
		Gui, Add, Text,, Toggle Bordeless Fullscreen
		Gui, Add, Button, gBorderless_Full_Screen, Toggle Borderless Fullscreen
		Gui, Add, Text,, Process Priority
		Gui, Add, DropDownList, vThis_Process_Priority, Realtime|High|AboveNormal|Normal|BelowNormal|Low
		Current_Priority := GetPriority(This_Process)
		if Current_Priority = Realtime
		{
			GuiControl, Choose, This_Process_Priority, 1
		}
		if Current_Priority = High
		{
			GuiControl, Choose, This_Process_Priority, 2
		}
		if Current_Priority = AboveNormal
		{
			GuiControl, Choose, This_Process_Priority, 3
		}
		if Current_Priority = Normal
		{
			GuiControl, Choose, This_Process_Priority, 4
		}
		if Current_Priority = BelowNormal
		{
			GuiControl, Choose, This_Process_Priority, 5
		}
		if Current_Priority = Low
		{
			GuiControl, Choose, This_Process_Priority, 6
		}
		Gui, Add, Text,, Process Affinity
		Gui, Add, Button, gEnable_All_Cores, Check All Cores
		Gui, Add, Button, x+10 gDisable_All_Cores, Uncheck All Cores
		EnvGet, Processor_Count, NUMBER_OF_PROCESSORS
		This_Core := 0
		loop, %Processor_Count%
		{
			Gui, Add, Checkbox, x12 vEnable_Core%This_Core%, Core #%This_Core%
			This_Core += 1
		}
		Affinity_Decimal := Get_Affinity(This_Process)
		This_Core := Processor_Count-1
		loop, %Processor_Count%
		{
			if (Affinity_Decimal >= 2**This_Core)
			{
				GuiControl, ,Enable_Core%This_Core%, 1
				Affinity_Decimal := (Affinity_Decimal-2**This_Core)
			}
			This_Core -= 1
		}
		Gui, Add, Button, gApply, Apply
		Gui, Add, Button, x+10 gCancel, Cancel
		Gui, Add, Button, x+10 gSettings, Settings
		Gui, Show
	}
}
return

;----------------------------------------------------------------------------------------------------
; Exit Code
;----------------------------------------------------------------------------------------------------

GuiClose:
{
	Hotkey, %Hotkey_Variable%, Show_Window, UseErrorLevel
	if ErrorLevel
	{
		;Do Nothing
	}
	else
	{
		Hotkey, %Hotkey_Variable%, Show_Window, On
	}
	Gui, Destroy
}
return

;----------------------------------------------------------------------------------------------------
; Toggle Window Borderless Fullscreen
;----------------------------------------------------------------------------------------------------

Borderless_Full_Screen:
{
	WinGet, window_style, Style, %This_Window%
	If (window_style & 0xC00000)
		{
		WinSet, Style, -0xC00000, %This_Window%
		WinSet, Style, -0x40000, %This_Window%
		WinMove, %This_Window%, , 0, 0, %A_ScreenWidth%, %A_ScreenHeight% ;-2, -2, 1924, 1084
		WinSet, Style, -0xC00000, %This_Window%
		WinSet, Style, -0x40000, %This_Window%
		}
	else
		{
		WinSet, Style, +0xC00000, %This_Window%
		WinSet, Style, +0x40000, %This_Window%
		}
}
return

;----------------------------------------------------------------------------------------------------
; Get Process Priority
; Function made by SKAN: https://autohotkey.com/board/topic/7984-ahk-functions-incache-cache-list-of-recent-items/://autohotkey.com/board/topic/7984-ahk-functions-incache-cache-list-of-recent-items/page-3?&#entry75675
;----------------------------------------------------------------------------------------------------

GetPriority(process="")
{
	Process, Exist, %process%
	PID := ErrorLevel
	IfLessOrEqual, PID, 0, Return, "Error!"
	hProcess := DllCall("OpenProcess", Int,1024, Int,0, Int,PID)
	Priority := DllCall("GetPriorityClass", Int,hProcess)
	DllCall("CloseHandle", Int,hProcess)
	IfEqual, Priority, 64   , Return, "Low"
	IfEqual, Priority, 16384, Return, "BelowNormal"
	IfEqual, Priority, 32   , Return, "Normal"
	IfEqual, Priority, 32768, Return, "AboveNormal"
	IfEqual, Priority, 128  , Return, "High"
	IfEqual, Priority, 256  , Return, "Realtime"
	Return "" 
}

;----------------------------------------------------------------------------------------------------
; Set Process Affinity
;----------------------------------------------------------------------------------------------------

Set_Affinity(process="", Affinity_Decimal=0)
{
	Process, Exist, %process%
	PID := ErrorLevel
	IfLessOrEqual, PID, 0, Return, "Error!"
	IfLessOrEqual, Affinity_Decimal, 0, Return, "Error!"
	hProcess := DllCall("OpenProcess", Int,1536, Int,0, Int,PID)
	DllCall("SetProcessAffinityMask", Int,hProcess, Int,Affinity_Decimal)
	DllCall("CloseHandle", Int,hProcess)
	return
}

;----------------------------------------------------------------------------------------------------
; Get Process Affinity
;----------------------------------------------------------------------------------------------------

Get_Affinity(process="")
{
	Process, Exist, %process%
	PID := ErrorLevel
	IfLessOrEqual, PID, 0, Return, "Error!"
	hProcess := DllCall("OpenProcess", Int,1536, Int,0, Int,PID)
	DllCall("GetProcessAffinityMask", Int,hProcess, IntP,PAM, IntP,SAM)
	DllCall("CloseHandle", Int,hProcess)
	return PAM
}

;----------------------------------------------------------------------------------------------------
; Assign All Cores
;----------------------------------------------------------------------------------------------------

Enable_All_Cores:
{
	This_Core := 0
	loop, %Processor_Count%
	{
		GuiControl, ,Enable_Core%This_Core%, 1
		This_Core += 1
	}
}
return

;----------------------------------------------------------------------------------------------------
; Assign No Cores
;----------------------------------------------------------------------------------------------------

Disable_All_Cores:
{
	This_Core := 0
	loop, %Processor_Count%
	{
		GuiControl, ,Enable_Core%This_Core%, 0
		This_Core += 1
	}
}
return

;----------------------------------------------------------------------------------------------------
; Apply Changes and Close the Interface Window
;----------------------------------------------------------------------------------------------------

Apply:
{
	Gui, Submit, NoHide
	Process, Priority, %This_Process%, %This_Process_Priority%
	Affinity_Decimal := 0
	This_Core := Processor_Count-1
	Loop, %Processor_Count%
	{
		if Enable_Core%This_Core% = 1
		{
			Affinity_Decimal := Affinity_Decimal*2+1
		}
		if Enable_Core%This_Core% = 0
		{
			Affinity_Decimal := Affinity_Decimal*2
		}
		This_Core -= 1
	}
	Test := Set_Affinity(This_Process, Affinity_Decimal)
	Gui, Destroy
}
return

;----------------------------------------------------------------------------------------------------
; Close the Active Interface Window
;----------------------------------------------------------------------------------------------------

Cancel:
{
	Gui, Destroy
}
return

;----------------------------------------------------------------------------------------------------
; Create Settings Interface Window
;----------------------------------------------------------------------------------------------------

Settings:
{
	Gui, New
	Gui, Add, Text, , Set a new Hotkey?
	Gui, Add, Hotkey, vNew_Hotkey_Variable
	GuiControl,, New_Hotkey_Variable,  %Hotkey_Variable%
	Gui, Add, Button, gApply_Settings, Apply
	Gui, Add, Button, x+10 gCancel, Cancel
	Gui, Show
}
return

;----------------------------------------------------------------------------------------------------
; Apply Changes and Close the Settings Interface Window
;----------------------------------------------------------------------------------------------------

Apply_Settings:
{
	Hotkey, %Hotkey_Variable%, Show_Window, UseErrorLevel
	if ErrorLevel
	{
		;Do Nothing
	}
	else
	{
		Hotkey, %Hotkey_Variable%,, Off
	}
	Gui, Submit
	FileDelete, Process_Booster_Config.txt
	FileAppend, Hotkey=%New_Hotkey_Variable%, Process_Booster_Config.txt
	FileRead, Hotkey_Variable, Process_Booster_Config.txt
	Hotkey_Variable := StrReplace(Hotkey_Variable, "Hotkey=")
	Hotkey, %Hotkey_Variable%, Show_Window, On
	Gui, Destroy
}
return
