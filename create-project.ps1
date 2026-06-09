<#
.SYNOPSIS
    Skrip otomatisasi untuk membuat proyek Laravel 12 dengan Inertia.js 3.0, React 19, TailwindCSS v4, dan Filament v5 (opsional).
.PARAMETER ProjectName
    Nama folder/direktori proyek baru.
.PARAMETER WithFilament
    Menentukan apakah Filament PHP & Livewire akan diinstal.
#>
param(
    [Parameter(Position=0)]
    [string]$ProjectName,

    [Parameter(Position=1)]
    [string]$WithFilamentOpt,

    [Parameter(Position=2)]
    [string]$WithSSROpt
)

$ErrorActionPreference = "Stop"

# Tentukan fungsi helper untuk logging berwarna
function Write-Header ($message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

function Write-Success ($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Info ($message) {
    Write-Host "[INFO] $message" -ForegroundColor Gray
}

# 1. Validasi Parameter Nama Proyek
if ([string]::IsNullOrEmpty($ProjectName)) {
    $ProjectName = Read-Host "Masukkan nama folder proyek baru (misal: my-new-project)"
    if ([string]::IsNullOrEmpty($ProjectName)) {
        Write-Error "Nama proyek tidak boleh kosong!"
        exit 1
    }
}

# 2. Validasi Parameter Filament (jika tidak dilewatkan)
$WithFilament = $null
if (-not [string]::IsNullOrEmpty($WithFilamentOpt)) {
    $WithFilamentOptLower = $WithFilamentOpt.ToLower().Trim()
    if ($WithFilamentOptLower -eq '$true' -or $WithFilamentOptLower -eq 'true' -or $WithFilamentOptLower -eq '1' -or $WithFilamentOptLower -eq 'yes' -or $WithFilamentOptLower -eq 'y') {
        $WithFilament = $true
    } elseif ($WithFilamentOptLower -eq '$false' -or $WithFilamentOptLower -eq 'false' -or $WithFilamentOptLower -eq '0' -or $WithFilamentOptLower -eq 'no' -or $WithFilamentOptLower -eq 'n') {
        $WithFilament = $false
    }
}

if ($null -eq $WithFilament) {
    $choice = Read-Host "Apakah Anda ingin memasang Filament PHP & Livewire v4? (Y/N) [Y]"
    if ($choice -match "^[Nn]") {
        $WithFilament = $false
    } else {
        $WithFilament = $true
    }
}

# 2.5. Validasi Parameter SSR (jika tidak dilewatkan)
$WithSSR = $null
if (-not [string]::IsNullOrEmpty($WithSSROpt)) {
    $WithSSROptLower = $WithSSROpt.ToLower().Trim()
    if ($WithSSROptLower -eq '$true' -or $WithSSROptLower -eq 'true' -or $WithSSROptLower -eq '1' -or $WithSSROptLower -eq 'yes' -or $WithSSROptLower -eq 'y') {
        $WithSSR = $true
    } elseif ($WithSSROptLower -eq '$false' -or $WithSSROptLower -eq 'false' -or $WithSSROptLower -eq '0' -or $WithSSROptLower -eq 'no' -or $WithSSROptLower -eq 'n') {
        $WithSSR = $false
    }
}

if ($null -eq $WithSSR) {
    $choice = Read-Host "Apakah Anda ingin menggunakan Inertia SSR (Server-Side Rendering)? (Y/N) [Y]"
    if ($choice -match "^[Nn]") {
        $WithSSR = $false
    } else {
        $WithSSR = $true
    }
}

$startTime = Get-Date

Write-Header "React Laravel Installer by Badroel07"
Write-Info "Memulai Pembuatan Proyek: $ProjectName"
Write-Info "Filament & Livewire     : $(if ($WithFilament) { 'YA' } else { 'TIDAK' })"
Write-Info "Inertia SSR             : $(if ($WithSSR) { 'YA' } else { 'TIDAK' })"

# 3. Buat Proyek Laravel Baru
Write-Header "Mengunduh & Membuat Proyek Laravel 12 Baru..."
composer create-project laravel/laravel:^12.0 $ProjectName
if (-not (Test-Path $ProjectName)) {
    Write-Error "Gagal menginisialisasi proyek Laravel di folder $ProjectName."
    exit 1
}

# Masuk ke folder proyek
$projectPath = (Resolve-Path $ProjectName).Path
Set-Location $projectPath
Write-Success "Berhasil masuk ke direktori proyek: $projectPath"

# 4. Install Dependensi Composer
Write-Header "Menginstal Dependensi Composer Utama..."
Write-Info "Menginstal Inertia.js (inertia-laravel)..."
composer require inertiajs/inertia-laravel

if ($WithFilament) {
    Write-Header "Menginstal Filament & Livewire..."
    composer require filament/filament livewire/livewire
}

# 5. Inisialisasi Middleware Inertia
Write-Header "Membuat Middleware Inertia..."
php artisan inertia:middleware

# Daftarkan middleware ke bootstrap/app.php
$bootstrapFile = Join-Path $projectPath "bootstrap/app.php"
if (Test-Path $bootstrapFile) {
    Write-Info "Mendaftarkan HandleInertiaRequests ke bootstrap/app.php..."
    $bootstrapContent = Get-Content $bootstrapFile -Raw
    
    # Ganti bagian ->withMiddleware(function (Middleware $middleware) { ... })
    $pattern = '->withMiddleware\(function\s*\(Middleware\s+\$middleware\)\s*\{[\s#\/\*]*\}'
    $replacement = "->withMiddleware(function (Middleware `$middleware) {`n        `$middleware->web(append: [`n            \App\Http\Middleware\HandleInertiaRequests::class,`n        ]);`n    }"
    
    $newBootstrapContent = $bootstrapContent -replace $pattern, $replacement
    
    # Jika penggantian regex pertama gagal karena format bawaan berbeda, lakukan fallback
    if ($newBootstrapContent -eq $bootstrapContent) {
        $newBootstrapContent = $bootstrapContent -replace '(?s)withMiddleware\(function\s*\(Middleware\s+\$middleware\)\s*\{(.*?)\}', "withMiddleware(function (Middleware `$middleware) {`n        `$middleware->web(append: [`n            \App\Http\Middleware\HandleInertiaRequests::class,`n        ]);`n    `1}"
    }

    Set-Content $bootstrapFile $newBootstrapContent
    Write-Success "bootstrap/app.php berhasil dikonfigurasi."
} else {
    Write-Warning "File bootstrap/app.php tidak ditemukan!"
}

# 6. Konfigurasi resources/views/app.blade.php
$appBladePath = Join-Path $projectPath "resources/views/app.blade.php"
Write-Header "Membuat root template app.blade.php..."
$appBladeContent = @"
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title inertia>{{ config('app.name', 'Laravel') }}</title>
    @viteReactRefresh
    @vite(['resources/js/app.jsx', 'resources/css/app.css'])
    @inertiaHead
</head>
<body class="font-sans antialiased bg-gray-900 text-white">
    @inertia
</body>
</html>
"@
Set-Content $appBladePath $appBladeContent
Write-Success "app.blade.php berhasil dibuat."

# Hapus welcome.blade.php jika ada
$welcomeBlade = Join-Path $projectPath "resources/views/welcome.blade.php"
if (Test-Path $welcomeBlade) {
    Remove-Item $welcomeBlade -Force
}

# 7. Konfigurasi Routes web.php
$webRouteFile = Join-Path $projectPath "routes/web.php"
if (Test-Path $webRouteFile) {
    Write-Info "Mengonfigurasi routes/web.php untuk menggunakan Inertia..."
    $webRouteContent = @"
<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Welcome');
});
"@
    Set-Content $webRouteFile $webRouteContent
    Write-Success "routes/web.php berhasil dikonfigurasi."
}

# 8. Install NPM Dependencies
Write-Header "Menginstal Dependensi Javascript (NPM)..."
Write-Info "Menginstal React 19, Inertia.js React, dan TailwindCSS v4..."
npm install react@latest react-dom@latest @inertiajs/react@latest @inertiajs/vite@latest tailwindcss@latest @tailwindcss/vite@latest --legacy-peer-deps
npm install @vitejs/plugin-react@latest laravel-vite-plugin@latest vite@latest --save-dev --legacy-peer-deps

# 9. Konfigurasi vite.config.js
$viteConfigPath = Join-Path $projectPath "vite.config.js"
Write-Header "Mengonfigurasi vite.config.js..."
if ($WithSSR) {
    $viteConfigContent = @"
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import inertia from '@inertiajs/vite';

export default defineConfig(({ isSsrBuild }) => {
    return {
        plugins: [
            tailwindcss(),
            react(),
            inertia(),
            laravel({
                input: ['resources/css/app.css', 'resources/js/app.jsx'],
                ssr: 'resources/js/ssr.jsx',
                refresh: true,
            }),
        ],
    };
});
"@
} else {
    $viteConfigContent = @"
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import inertia from '@inertiajs/vite';

export default defineConfig(() => {
    return {
        plugins: [
            tailwindcss(),
            react(),
            inertia(),
            laravel({
                input: ['resources/css/app.css', 'resources/js/app.jsx'],
                refresh: true,
            }),
        ],
    };
});
"@
}
Set-Content $viteConfigPath $viteConfigContent
Write-Success "vite.config.js berhasil dikonfigurasi."

# 10. Update package.json scripts & overrides
$packageJsonPath = Join-Path $projectPath "package.json"
if (Test-Path $packageJsonPath) {
    Write-Info "Mengonfigurasi build scripts dan overrides di package.json..."
    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    
    # Tambahkan command build & dev
    if ($WithSSR) {
        $packageJson.scripts.build = "vite build && vite build --ssr"
    } else {
        $packageJson.scripts.build = "vite build"
    }
    $packageJson.scripts.dev = "vite"
    
    # Tambahkan overrides untuk keamanan shell-quote
    $packageJson | Add-Member -MemberType NoteProperty -Name "overrides" -Value ([PSCustomObject]@{"shell-quote" = "^1.8.4"}) -Force
    
    $packageJsonString = $packageJson | ConvertTo-Json -Depth 10
    $packageJsonString = $packageJsonString -replace '\\u0026', '&'
    Set-Content $packageJsonPath $packageJsonString
    Write-Success "package.json berhasil diperbarui."
}

# 11. Buat folder dan file JS/CSS Frontend
Write-Header "Membuat file aset frontend..."

# Buat folder Pages
$pagesDir = Join-Path $projectPath "resources/js/Pages"
if (-not (Test-Path $pagesDir)) {
    New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null
}

# Buat Welcome.jsx
$welcomeJsxPath = Join-Path $pagesDir "Welcome.jsx"
$welcomeJsxContent = @"
import React from 'react';

export default function Welcome() {
    return (
        <div className="flex min-h-screen items-center justify-center bg-gray-950 text-white font-sans">
            <div className="text-center p-8 bg-gray-900 border border-gray-800 rounded-lg shadow-2xl max-w-md">
                <h1 className="text-3xl font-extrabold text-blue-500 mb-2">Instalasi Sukses!</h1>
                <p className="text-gray-400 mb-6 text-sm">
                    Proyek Laravel 12 + Inertia React + TailwindCSS v4 telah berhasil diinisialisasi.
                </p>
                <div className="text-left text-xs bg-gray-950 p-4 rounded border border-gray-800 font-mono text-gray-300">
                    <p className="text-green-400"># Untuk memulai development:</p>
                    <p>npm run dev</p>
                    <p>php artisan serve</p>
                </div>
            </div>
        </div>
    );
}
"@
Set-Content $welcomeJsxPath $welcomeJsxContent

# Buat app.jsx
$appJsxPath = Join-Path $projectPath "resources/js/app.jsx"
$appJsxContent = @'
import './bootstrap';
import { createInertiaApp } from '@inertiajs/react';
import { createRoot, hydrateRoot } from 'react-dom/client';

createInertiaApp({
    progress: {
        delay: 250,
        color: '#3b82f6',
    },
    resolve: name => {
        const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true });
        return pages[`./Pages/${name}.jsx`];
    },
    setup({ el, App, props }) {
        if (import.meta.env.SSR) {
            hydrateRoot(el, <App {...props} />);
        } else {
            createRoot(el).render(<App {...props} />);
        }
    },
});
'@
Set-Content $appJsxPath $appJsxContent

# Buat ssr.jsx (jika dipilih)
if ($WithSSR) {
    $ssrJsxPath = Join-Path $projectPath "resources/js/ssr.jsx"
    $ssrJsxContent = @'
import { createInertiaApp } from '@inertiajs/react';
import createServer from '@inertiajs/react/server';
import { renderToString } from 'react-dom/server';

createServer((page) =>
    createInertiaApp({
        page,
        render: renderToString,
        resolve: name => {
            const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true });
            return pages[`./Pages/${name}.jsx`];
        },
        setup: ({ App, props }) => <App {...props} />,
    }),
    13715
);
'@
    Set-Content $ssrJsxPath $ssrJsxContent
}

# Buat resources/css/app.css dengan Tailwind import
$cssFile = Join-Path $projectPath "resources/css/app.css"
Set-Content $cssFile '@import "tailwindcss";'
Write-Success "File aset frontend berhasil disiapkan."

# 11.5. Setup Database MySQL & Auto Migrate
Write-Header "Mengonfigurasi Database MySQL..."
$dbName = $ProjectName
Write-Info "Nama database: $dbName"

$envFile = Join-Path $projectPath ".env"
if (Test-Path $envFile) {
    Write-Info "Memperbarui konfigurasi database di .env..."
    $envContent = Get-Content $envFile -Raw
    $envContent = $envContent -replace 'DB_CONNECTION=sqlite', 'DB_CONNECTION=mysql'
    $envContent = $envContent -replace 'DB_CONNECTION=\w*', 'DB_CONNECTION=mysql'
    $envContent = $envContent -replace 'DB_DATABASE=.*', "DB_DATABASE=$dbName"
    $envContent = $envContent -replace 'DB_USERNAME=\w*', 'DB_USERNAME=root'
    $envContent = $envContent -replace 'DB_PASSWORD=.*', 'DB_PASSWORD='
    if ($envContent -notmatch 'DB_HOST') {
        $envContent += "`nDB_HOST=127.0.0.1`nDB_PORT=3306"
    }
    Set-Content $envFile $envContent
    Write-Success ".env berhasil dikonfigurasi untuk MySQL."
}

try {
    Write-Info "Mencoba membuat database MySQL '$dbName' secara otomatis via PHP PDO..."
    $phpCode = "try { `$pdo = new PDO('mysql:host=127.0.0.1;port=3306', 'root', ''); `$pdo->exec('CREATE DATABASE IF NOT EXISTS ' . chr(96) . '$dbName' . chr(96)); } catch (Exception `$e) { echo `$e->getMessage(); exit(1); }"
    php -r $phpCode
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database MySQL '$dbName' berhasil dibuat/sudah ada."
        Write-Info "Menjalankan migrasi database (php artisan migrate)..."
        php artisan migrate --force
        Write-Success "Migrasi database berhasil dijalankan."
    } else {
        throw "Gagal membuat database"
    }
} catch {
    Write-Warning "Gagal membuat database/migrasi secara otomatis."
    Write-Warning "Pastikan server MySQL (seperti Laragon) aktif."
    Write-Warning "Silakan buat database '$dbName' secara manual dan jalankan 'php artisan migrate' di proyek baru Anda."
}

# 12. Setup Filament (jika dipilih)
if ($WithFilament) {
    Write-Header "Mengonfigurasi Filament..."
    php artisan filament:install --panels --quiet
    Write-Success "Filament panel berhasil dipasang."
}

# 13. Update & Audit Fix
Write-Header "Melakukan Pembaruan & Audit Keamanan..."
Write-Info "Menjalankan composer update..."
composer update
Write-Info "Menjalankan npm update..."
npm update --legacy-peer-deps
Write-Info "Menjalankan npm audit fix..."
npm audit fix --legacy-peer-deps
Write-Success "Pembaruan & audit selesai."

# 14. Selesai
$endTime = Get-Date
$duration = ($endTime - $startTime).ToString("mm\:ss")
Write-Header "PROSES SELESAI!"
Write-Host "Proyek '$ProjectName' berhasil dibuat dalam waktu $duration!" -ForegroundColor Green
Write-Host "Langkah selanjutnya:" -ForegroundColor Cyan
Write-Host "1. Jalankan database migration (buat database & atur file .env jika diperlukan)"
Write-Host "2. Jalankan server backend: php artisan serve"
Write-Host "3. Jalankan server frontend: npm run dev"
if ($WithFilament) {
    Write-Host "4. Buat user admin Filament: php artisan make:filament-user"
}
Write-Host ""
