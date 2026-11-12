@echo off
rem Orca runs recipe commands through cmd.exe, which cannot execute a .sh file.
rem This wrapper locates Git Bash and hands suspend over to it, passing stdin,
rem stdout and the exit code straight through. On macOS or Linux desktops point
rem the recipe at docker-suspend.sh instead.
setlocal
set "ORCA_VM_BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "ORCA_VM_BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined ORCA_VM_BASH if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "ORCA_VM_BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined ORCA_VM_BASH if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "ORCA_VM_BASH=%LocalAppData%\Programs\Git\bin\bash.exe"
if not defined ORCA_VM_BASH (
  echo Git Bash was not found. Install Git for Windows, or run docker-suspend.sh directly. 1>&2
  exit /b 1
)
"%ORCA_VM_BASH%" "%~dp0docker-suspend.sh" %*
exit /b %ERRORLEVEL%
