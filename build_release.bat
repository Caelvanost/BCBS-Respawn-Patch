@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "BUILD_DIR=%ROOT%\build"
set "PACKAGE_DIR=%ROOT%\package"
set "DIST_DIR=%ROOT%\dist"

rem Allow an override, otherwise use the local Skyrim path used for development.
if not defined SKYRIM_DIR set "SKYRIM_DIR=C:\Games\Steam\steamapps\common\Skyrim Special Edition"

if not defined PAPYRUS_COMPILER set "PAPYRUS_COMPILER=%SKYRIM_DIR%\Papyrus Compiler\PapyrusCompiler.exe"
if not defined PAPYRUS_FLAGS set "PAPYRUS_FLAGS=%SKYRIM_DIR%\TESV_Papyrus_Flags.flg"
set "PAPYRUS_IMPORTS=%SKYRIM_DIR%\Data\Source\Scripts;%ROOT%\Source\Scripts"

for /f "tokens=2" %%V in ('findstr /r /c:"^[ ]*VERSION [0-9]" "%ROOT%\CMakeLists.txt"') do set "VERSION=%%V"
if not defined VERSION (
    echo [ERROR] Could not read VERSION from CMakeLists.txt.
    exit /b 1
)

set "ZIP_NAME=BCBS-Respawn-Patch-v%VERSION%.zip"
set "ZIP_PATH=%DIST_DIR%\%ZIP_NAME%"

call :require_file "%SKYRIM_DIR%\Data\BCBSRespawnPatch.esp" "BCBSRespawnPatch.esp"
if errorlevel 1 exit /b 1
call :require_file "%PAPYRUS_COMPILER%" "PapyrusCompiler.exe"
if errorlevel 1 exit /b 1
call :require_file "%PAPYRUS_FLAGS%" "TESV_Papyrus_Flags.flg"
if errorlevel 1 exit /b 1
call :require_file "%SKYRIM_DIR%\Data\Source\Scripts\SKI_ConfigBase.psc" "SKI_ConfigBase.psc"
if errorlevel 1 exit /b 1
call :require_file "%SKYRIM_DIR%\Data\Source\Scripts\SKI_ConfigManager.psc" "SKI_ConfigManager.psc"
if errorlevel 1 exit /b 1
call :require_file "%SKYRIM_DIR%\Data\Source\Scripts\SKI_QuestBase.psc" "SKI_QuestBase.psc"
if errorlevel 1 exit /b 1

where cmake >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cmake was not found in PATH.
    exit /b 1
)

if not defined VCPKG_ROOT (
    echo [ERROR] VCPKG_ROOT is not defined.
    echo Set it to your vcpkg installation before running this script.
    exit /b 1
)

call :require_file "%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" "vcpkg.cmake"
if errorlevel 1 exit /b 1

if exist "%PACKAGE_DIR%" rmdir /s /q "%PACKAGE_DIR%"
mkdir "%PACKAGE_DIR%\Scripts" || exit /b 1
mkdir "%PACKAGE_DIR%\SKSE\Plugins" || exit /b 1
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%" || exit /b 1

if exist "%ZIP_PATH%" del /q "%ZIP_PATH%"

echo.
echo ============================================================
echo  BCBS Respawn Patch v%VERSION% - Release Build
echo ============================================================
echo.

echo [1/5] Configuring native plugin...
cmake -S "%ROOT%" -B "%BUILD_DIR%" -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake"
if errorlevel 1 goto :fail

echo.
echo [2/5] Building native plugin (Release)...
cmake --build "%BUILD_DIR%" --config Release
if errorlevel 1 goto :fail

set "DLL_PATH=%BUILD_DIR%\Release\BCBSRespawnPatch.dll"
if not exist "%DLL_PATH%" set "DLL_PATH=%BUILD_DIR%\BCBSRespawnPatch.dll"
if not exist "%DLL_PATH%" (
    for /r "%BUILD_DIR%" %%F in (BCBSRespawnPatch.dll) do set "DLL_PATH=%%~fF"
)
if not exist "!DLL_PATH!" (
    echo [ERROR] BCBSRespawnPatch.dll was not found after the build.
    goto :fail
)

echo.
echo [3/5] Compiling Papyrus scripts...
"%PAPYRUS_COMPILER%" "%ROOT%\Source\Scripts\BCBSRespawnCheckpointAlias.psc" -f="%PAPYRUS_FLAGS%" -i="%PAPYRUS_IMPORTS%" -o="%PACKAGE_DIR%\Scripts"
if errorlevel 1 goto :fail

"%PAPYRUS_COMPILER%" "%ROOT%\Source\Scripts\BCBSRespawnMCM.psc" -f="%PAPYRUS_FLAGS%" -i="%PAPYRUS_IMPORTS%" -o="%PACKAGE_DIR%\Scripts"
if errorlevel 1 goto :fail

call :require_file "%PACKAGE_DIR%\Scripts\BCBSRespawnCheckpointAlias.pex" "BCBSRespawnCheckpointAlias.pex"
if errorlevel 1 goto :fail
call :require_file "%PACKAGE_DIR%\Scripts\BCBSRespawnMCM.pex" "BCBSRespawnMCM.pex"
if errorlevel 1 goto :fail

echo.
echo [4/5] Staging release package...
copy /y "%SKYRIM_DIR%\Data\BCBSRespawnPatch.esp" "%PACKAGE_DIR%\BCBSRespawnPatch.esp" >nul || goto :fail
copy /y "!DLL_PATH!" "%PACKAGE_DIR%\SKSE\Plugins\BCBSRespawnPatch.dll" >nul || goto :fail

echo.
echo [5/5] Creating archive...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%PACKAGE_DIR%\*' -DestinationPath '%ZIP_PATH%' -Force"
if errorlevel 1 goto :fail

call :require_file "%ZIP_PATH%" "%ZIP_NAME%"
if errorlevel 1 goto :fail

echo.
echo ============================================================
echo  SUCCESS

echo  Package: %PACKAGE_DIR%
echo  Archive: %ZIP_PATH%
echo ============================================================
exit /b 0

:require_file
if not exist "%~1" (
    echo [ERROR] Missing %~2
    echo         Expected: %~1
    exit /b 1
)
exit /b 0

:fail
echo.
echo ============================================================
echo  BUILD FAILED

echo  Review the error above. No release archive was produced.
echo ============================================================
exit /b 1
