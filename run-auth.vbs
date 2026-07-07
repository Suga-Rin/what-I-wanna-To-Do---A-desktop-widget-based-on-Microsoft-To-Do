Set fso=CreateObject("Scripting.FileSystemObject") : Set sh=CreateObject("WScript.Shell")
d=fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -Command ""& '" & d & "\todo-auth.ps1'; & '" & d & "\todo-export.ps1'; Read-Host 'Done - press Enter to close'""", 1, False