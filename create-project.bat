@echo off
:: Skrip Batch untuk menjalankan create-project.ps1
:: Penggunaan: create-project.bat [NamaProyek] [DenganFilament]
:: Contoh: create-project.bat my-project $true
::         create-project.bat my-project $false

echo ===========================================
echo    React Laravel Installer by Badroel07
echo ===========================================
echo.

set "ARGS=%*"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-project.ps1" %ARGS%

if %errorlevel% neq 0 (
    echo.
    echo [BAT-ERROR] Terjadi kesalahan saat menjalankan skrip pembuatan proyek.
    pause
    exit /b %errorlevel%
)

echo.
echo ===========================================
echo [SUKSES] Proyek baru telah berhasil dibuat!
echo ===========================================
pause
