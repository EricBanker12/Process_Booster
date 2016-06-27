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
Hotkey, %Hotkey_Variable%, Show_Window
return

;----------------------------------------------------------------------------------------------------
; Create Interface Window
;----------------------------------------------------------------------------------------------------

Show_Window:
{
	IfWinExist, ahk_exe Process_Booster.exe
	{
		;Do Nothing
	}
	else
	{
		WinGet, This_Process, ProcessName, A
		Process_Name := StrReplace(This_Process, ".exe")
		Gui, Add, Text,, Process "%This_Process%" detected.
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
		Gui, Add, Button, gEnable_All_Cores, Assign All Cores
		Gui, Add, Button, x+10 gDisable_All_Cores, Assign No Cores
		EnvGet, Processor_Count, NUMBER_OF_PROCESSORS
		This_Core := 0
		loop, %Processor_Count%
		{
			Gui, Add, Checkbox, x12 vEnable_Core%This_Core%, Core #%This_Core%
			This_Core += 1
		}
		Affinity_Decimal := Get_Affinity(Process_Name)
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
; Get Process Priority
; Function made by SKAN https://autohotkey.com/board/topic/7984-ahk-functions-incache-cache-list-of-recent-items/://autohotkey.com/board/topic/7984-ahk-functions-incache-cache-list-of-recent-items/page-3?&#entry75675
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
; Get Process Affinity
;----------------------------------------------------------------------------------------------------

Get_Affinity(Process_Name)
{
RunWait, cmd.exe /c cd %A_ScriptDir% & PowerShell "Get-Process %Process_Name% | Select-Object ProcessorAffinity" > Temp_Affinity.txt, C:\Windows\system32\, Hide
FileRead, Affinity_Decimal, Temp_Affinity.txt
FileDelete, Temp_Affinity.txt
Affinity_Decimal := StrReplace(Affinity_Decimal, "-")
Affinity_Decimal := StrReplace(Affinity_Decimal, "ProcessorAffinity")
Affinity_Decimal := StrReplace(Affinity_Decimal, "`r`n")
Affinity_Decimal := StrReplace(Affinity_Decimal, " ")
return Affinity_Decimal
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
	Run, cmd.exe /c PowerShell "$Process = Get-Process %Process_Name%; $Process.ProcessorAffinity=%Affinity_Decimal%", C:\Windows\system32\, Hide
	Gui, Destroy
}
return

;----------------------------------------------------------------------------------------------------
; Close the Interface Window
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
	Gui, Add, Text, , New Hotkey
	Gui, Add, Hotkey, vNew_Hotkey_Variable
	Gui, Add, Button, gApply_Settings, Apply
	Gui, Add, Button, x+10 gCancel, Cancel
	Gui, Show
}
return

Apply_Settings:
{
	Gui, Submit, NoHide
	FileDelete, Process_Booster_Config.txt
	FileAppend, Hotkey=%New_Hotkey_Variable%, Process_Booster_Config.txt
	FileRead, Hotkey_Variable, Process_Booster_Config.txt
	Hotkey_Variable := StrReplace(Hotkey_Variable, "Hotkey=")
	Hotkey, %Hotkey_Variable%, Show_Window
	Gui, Destroy
	Gui, Destroy
	Run, Process_Booster.exe
}
return