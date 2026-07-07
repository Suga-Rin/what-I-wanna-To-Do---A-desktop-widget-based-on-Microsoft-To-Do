Set fso=CreateObject("Scripting.FileSystemObject") : Set sh=CreateObject("WScript.Shell")
d=fso.GetParentFolderName(WScript.ScriptFullName)
a=""
For i=0 To WScript.Arguments.Count-1
  a=a & " """ & WScript.Arguments(i) & """"
Next
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & d & "\todo-action.ps1""" & a, 0, False