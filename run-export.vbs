Set fso=CreateObject("Scripting.FileSystemObject") : Set sh=CreateObject("WScript.Shell")
d=fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & d & "\todo-export.ps1""", 0, False