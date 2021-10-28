@ECHO OFF
SETLOCAL
SET EL=0

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %~f0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IF /I "%msvs_version%"=="" ECHO msvs_version unset, defaulting to 2019 && SET msvs_version=2019

SET PATH=%CD%;%PATH%
IF NOT "%NODE_RUNTIME%"=="" SET "TOOLSET_ARGS=%TOOLSET_ARGS% --runtime=%NODE_RUNTIME%"
IF NOT "%NODE_RUNTIME_VERSION%"=="" SET "TOOLSET_ARGS=%TOOLSET_ARGS% --target=%NODE_RUNTIME_VERSION%"

ECHO nodejs_version^: %nodejs_version%
ECHO platform^: %platform%
ECHO msvs_version^: %msvs_version%
ECHO TOOLSET_ARGS^: %TOOLSET_ARGS%

ECHO activating VS command prompt
:: NOTE this call makes the x64 -> X64
IF /I "%platform%"=="x64" ECHO x64 && CALL "C:\Program Files (x86)\Microsoft Visual Studio\%msvs_version%\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" amd64
IF /I "%platform%"=="x86" ECHO x86 && CALL "C:\Program Files (x86)\Microsoft Visual Studio\%msvs_version%\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" x86
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO using compiler^: && CALL cl
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO using MSBuild^: && CALL msbuild /version && ECHO.
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO node^: && call node -v
call node -e "console.log('  - arch:',process.arch,'\n  - argv:',process.argv,'\n  - execPath:',process.execPath)"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO npm^: && CALL npm -v
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO ===== where npm puts stuff START ============
ECHO npm root && CALL npm root
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO npm root -g && CALL npm root -g
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO npm bin && CALL npm bin
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO npm bin -g && CALL npm bin -g
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL npm install --build-from-source --msvs_version=%msvs_version% %TOOLSET_ARGS% --loglevel=http
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

FOR /F "tokens=*" %%i in ('"CALL node_modules\.bin\node-pre-gyp reveal module %TOOLSET_ARGS% --silent"') DO SET MODULE=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
FOR /F "tokens=*" %%i in ('node -e "console.log(process.execPath)"') DO SET NODE_EXE=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

dumpbin /DEPENDENTS "%NODE_EXE%"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
dumpbin /DEPENDENTS "%MODULE%"
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

ECHO calling npm test
CALL npm test
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

CALL node_modules\.bin\node-pre-gyp rebuild --msvs_version=%msvs_version% %TOOLSET_ARGS%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
ECHO packaging for node-gyp
CALL node_modules\.bin\node-pre-gyp package %TOOLSET_ARGS%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

GOTO DONE



:ERROR
ECHO ~~~~~~~~~~~~~~~~~~~~~~ ERROR %~f0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO ERRORLEVEL^: %ERRORLEVEL%
SET EL=%ERRORLEVEL%

:DONE
ECHO ~~~~~~~~~~~~~~~~~~~~~~ DONE %~f0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EXIT /b %EL%
