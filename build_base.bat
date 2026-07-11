@echo off
setlocal

if "%~1"=="" (
    echo Usage: %~nx0 ^<git-commit^>
    exit /b 1
)

set "COMMIT=%~1"
set "ROOT=%~dp0."
set "WORKTREE=%ROOT%\build\base_worktree_%RANDOM%%RANDOM%"
set "OUT=%ROOT%\build\base.sfc"
set "SYM=%ROOT%\build\base.sym"
set "ERR=0"

if not exist "%ROOT%\build" mkdir "%ROOT%\build"

git -C "%ROOT%" rev-parse --verify "%COMMIT%" >nul 2>nul
if errorlevel 1 (
    echo Invalid commit: %COMMIT%
    exit /b 1
)

git -C "%ROOT%" worktree add --detach "%WORKTREE%" "%COMMIT%"
if errorlevel 1 exit /b %ERRORLEVEL%

for %%F in (sm.sfc zelda3.sfc metroid.nes zelda1prg0.nes) do (
    if not exist "%ROOT%\resources\%%F" (
        echo Missing resources\%%F
        set "ERR=1"
        goto cleanup
    )
    copy /y "%ROOT%\resources\%%F" "%WORKTREE%\resources\%%F" >nul
    if errorlevel 1 (
        set "ERR=1"
        goto cleanup
    )
)

del "%OUT%" >nul 2>nul
del "%SYM%" >nul 2>nul

pushd "%WORKTREE%\resources"
if errorlevel 1 (
    set "ERR=1"
    goto cleanup
)

"%ROOT%\resources\asar.exe" --fix-checksum=off --symbols=wla --symbols-path="%SYM%" "%WORKTREE%\src\main.asm" "%OUT%"
set "ERR=%ERRORLEVEL%"
popd

:cleanup
git -C "%ROOT%" worktree remove --force "%WORKTREE%" >nul 2>nul
exit /b %ERR%
