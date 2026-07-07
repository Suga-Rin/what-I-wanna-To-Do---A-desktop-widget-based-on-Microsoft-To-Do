Set fso=CreateObject("Scripting.FileSystemObject") : Set sh=CreateObject("WScript.Shell")
d=fso.GetParentFolderName(WScript.ScriptFullName)
y=0 : m=0
If WScript.Arguments.Count>=2 Then
  y=WScript.Arguments(0) : m=WScript.Arguments(1)
End If
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & d & "\todo-cal.ps1"" " & y & " " & m, 0, False