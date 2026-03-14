@echo off
:: new-ralph-loop.bat — wrapper so you can call "new-ralph-loop" from any directory
:: without dealing with PowerShell execution policy.
::
:: Install: copy both this file AND new-ralph-loop.ps1 to the same folder on your PATH.
::   e.g. C:\Users\<you>\AppData\Local\Microsoft\WindowsApps\
::
pwsh -ExecutionPolicy Bypass -File "%~dp0new-ralph-loop.ps1" %*
