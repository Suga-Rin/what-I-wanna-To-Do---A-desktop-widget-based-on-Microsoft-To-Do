Set fso=CreateObject("Scripting.FileSystemObject") : Set sh=CreateObject("WScript.Shell")
d=fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run """C:\Program Files\Rainmeter\Rainmeter.exe"" !ActivateConfig ToDo ToDo.ini", 0, False