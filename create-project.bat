@echo off
:: Skrip Batch untuk menjalankan create-project.ps1
::
:: Penggunaan:
::   create-project.bat [NamaProyek] [Stack] [DenganFilament] [DenganSSR]
::
:: Argumen:
::   NamaProyek    - Nama folder proyek (wajib, akan ditanya jika kosong)
::   Stack         - "react"  => React 19 + Inertia.js + TailwindCSS v4
::                   "blade"  => Laravel Blade + TailwindCSS v4 (tanpa React/Inertia)
::                   (akan ditanya interaktif jika kosong)
::   DenganFilament - $true / $false  (akan ditanya jika kosong)
::   DenganSSR      - $true / $false  (hanya relevan untuk stack react)
::
:: Contoh:
::   create-project.bat my-project react $true $false
::   create-project.bat my-project blade $true
::   create-project.bat my-project blade $false

echo ===========================================
echo    Laravel 12 Installer by Badroel07
echo ===========================================
echo.
echo  Stack tersedia:
echo    [1] React 19 + Inertia.js + TailwindCSS v4  (Full SPA)
echo    [2] Blade   + TailwindCSS v4                 (No React/Inertia)
echo.
echo  Filament tersedia untuk semua stack.
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
