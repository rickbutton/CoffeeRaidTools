@echo off
setlocal

REM Define Git Bash path
set "GIT_BASH=%ProgramFiles%\Git\bin\sh.exe"

REM Check if Git Bash exists
if exist "%GIT_BASH%" (
    REM Execute package.sh with Git Bash, passing all arguments
    "%GIT_BASH%" "%~dp0package.sh" %*
) else (
    echo Error: Git Bash not found at "%GIT_BASH%"
    echo Please install Git for Windows or verify the installation path.
    exit /b 1
)
