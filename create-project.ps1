<#
.SYNOPSIS
    Skrip otomatisasi pembuatan proyek Laravel 12.
    Stack A: React 19 + Inertia.js + TailwindCSS v4  (+ opsional Filament)
    Stack B: Laravel Blade + TailwindCSS v4           (+ opsional Filament)
#>
param(
    [Parameter(Position=0)] [string]$ProjectName,
    [Parameter(Position=1)] [string]$StackChoiceOpt,
    [Parameter(Position=2)] [string]$WithFilamentOpt,
    [Parameter(Position=3)] [string]$WithSSROpt
)

$ErrorActionPreference = "Stop"

function Write-Header  ($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan  }
function Write-Success ($msg) { Write-Host "[SUCCESS] $msg"  -ForegroundColor Green }
function Write-Info    ($msg) { Write-Host "[INFO] $msg"     -ForegroundColor Gray  }
function Write-TextFile ($path, $content) {
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
}

# ─────────────────────────────────────────────────────────
# TEMPLATE KONTEN (didefinisikan di luar blok if/elseif
# agar penutup here-string ada di kolom 0)
# ─────────────────────────────────────────────────────────

# --- Inertia root template ---
$TMPL_BLADE_INERTIA = @'
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
'@

# --- routes/web.php (React/Inertia) ---
$TMPL_ROUTES_REACT = @'
<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Welcome');
});
'@

# --- vite.config.js (React, tanpa SSR) ---
$TMPL_VITE_REACT = @'
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
'@

# --- vite.config.js (React, dengan SSR) ---
$TMPL_VITE_REACT_SSR = @'
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
'@

# --- Pages/Welcome.jsx ---
$TMPL_WELCOME_JSX = @'
import React from 'react';

export default function Welcome() {
    return (
        <div className="flex min-h-screen items-center justify-center bg-gray-950 text-white font-sans">
            <div className="text-center p-8 bg-gray-900 border border-gray-800 rounded-lg shadow-2xl max-w-md w-full mx-4">
                <h1 className="text-3xl font-extrabold text-blue-500 mb-2">Instalasi Sukses!</h1>
                <p className="text-gray-400 mb-6 text-sm">
                    Laravel 12 + Inertia.js + React 19 + TailwindCSS v4 siap digunakan.
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
'@

# --- resources/js/app.jsx ---
$TMPL_APP_JSX = @'
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

# --- resources/js/ssr.jsx ---
$TMPL_SSR_JSX = @'
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

# --- vite.config.js (Blade) ---
$TMPL_VITE_BLADE = @'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        tailwindcss(),
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
'@

# --- layouts/app.blade.php ---
$TMPL_LAYOUT_BLADE = @'
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', config('app.name', 'Laravel'))</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @stack('styles')
</head>
<body class="font-sans antialiased bg-gray-50 text-gray-900">
    @yield('content')
    @stack('scripts')
</body>
</html>
'@

# --- welcome.blade.php ---
$TMPL_WELCOME_BLADE = @'
@extends('layouts.app')

@section('title', 'Selamat Datang')

@section('content')
<div class="flex min-h-screen items-center justify-center bg-gray-950 text-white">
    <div class="text-center p-8 bg-gray-900 border border-gray-800 rounded-2xl shadow-2xl max-w-md w-full mx-4">
        <h1 class="text-3xl font-extrabold text-blue-500 mb-2">Instalasi Sukses!</h1>
        <p class="text-gray-400 mb-6 text-sm">
            Laravel 12 + Blade + TailwindCSS v4 siap digunakan.
        </p>
        <div class="text-left text-xs bg-gray-950 p-4 rounded border border-gray-800 font-mono text-gray-300">
            <p class="text-green-400"># Untuk memulai development:</p>
            <p>npm run dev</p>
            <p>php artisan serve</p>
        </div>
    </div>
</div>
@endsection
'@

# --- routes/web.php (Blade) ---
$TMPL_ROUTES_BLADE = @'
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
'@

# ─────────────────────────────────────────────
# 1. Nama Proyek
# ─────────────────────────────────────────────
if ([string]::IsNullOrEmpty($ProjectName)) {
    $ProjectName = Read-Host "Masukkan nama folder proyek baru (misal: my-new-project)"
    if ([string]::IsNullOrEmpty($ProjectName)) { Write-Error "Nama proyek tidak boleh kosong!"; exit 1 }
}

# ─────────────────────────────────────────────
# 2. Pilih Stack
# ─────────────────────────────────────────────
$StackChoice = $null
if (-not [string]::IsNullOrEmpty($StackChoiceOpt)) {
    $s = $StackChoiceOpt.ToLower().Trim()
    if ($s -eq "react" -or $s -eq "1") { $StackChoice = "react" }
    elseif ($s -eq "blade" -or $s -eq "2") { $StackChoice = "blade" }
}

if ($null -eq $StackChoice) {
    Write-Host ""
    Write-Host "Pilih Stack Frontend:" -ForegroundColor Yellow
    Write-Host "  [1] React 19 + Inertia.js 3.0 + TailwindCSS v4  (Full SPA)"
    Write-Host "  [2] Laravel Blade + TailwindCSS v4               (Tanpa React / Inertia)"
    Write-Host ""
    $sc = Read-Host "Pilihan Anda (1/2) [1]"
    $StackChoice = if ($sc -eq "2" -or $sc.ToLower() -eq "blade") { "blade" } else { "react" }
}

# ─────────────────────────────────────────────
# 3. Opsi SSR (hanya React)
# ─────────────────────────────────────────────
$WithSSR = $false
if ($StackChoice -eq "react") {
    $WithSSR = $null
    if (-not [string]::IsNullOrEmpty($WithSSROpt)) {
        $wsr = $WithSSROpt.ToLower().Trim()
        if ($wsr -in @('$true','true','1','yes','y'))   { $WithSSR = $true  }
        elseif ($wsr -in @('$false','false','0','no','n')) { $WithSSR = $false }
    }
    if ($null -eq $WithSSR) {
        $c = Read-Host "Apakah Anda ingin menggunakan Inertia SSR? (Y/N) [N]"
        $WithSSR = ($c -match "^[Yy]")
    }
}

# ─────────────────────────────────────────────
# 4. Opsi Filament (semua stack)
# ─────────────────────────────────────────────
$WithFilament = $null
if (-not [string]::IsNullOrEmpty($WithFilamentOpt)) {
    $wf = $WithFilamentOpt.ToLower().Trim()
    if ($wf -in @('$true','true','1','yes','y'))   { $WithFilament = $true  }
    elseif ($wf -in @('$false','false','0','no','n')) { $WithFilament = $false }
}
if ($null -eq $WithFilament) {
    $c = Read-Host "Apakah Anda ingin memasang Filament PHP dan Livewire? (Y/N) [Y]"
    $WithFilament = -not ($c -match "^[Nn]")
}

# ─────────────────────────────────────────────
# Ringkasan konfigurasi
# ─────────────────────────────────────────────
$startTime  = Get-Date
$stackLabel = if ($StackChoice -eq "react") { "React 19 + Inertia.js + TailwindCSS v4" } else { "Blade + TailwindCSS v4 (No React/Inertia)" }

Write-Header "Laravel 12 Installer by Badroel07"
Write-Info "Nama Proyek  : $ProjectName"
Write-Info "Stack        : $stackLabel"
if ($StackChoice -eq "react") { Write-Info "Inertia SSR  : $(if ($WithSSR) { 'YA' } else { 'TIDAK' })" }
Write-Info "Filament     : $(if ($WithFilament) { 'YA' } else { 'TIDAK' })"

# ─────────────────────────────────────────────
# 5. Buat Proyek Laravel 12
# ─────────────────────────────────────────────
Write-Header "Mengunduh dan Membuat Proyek Laravel 12 Baru..."
composer create-project laravel/laravel:^12.0 $ProjectName
if (-not (Test-Path $ProjectName)) { Write-Error "Gagal membuat proyek Laravel di '$ProjectName'."; exit 1 }

$projectPath = (Resolve-Path $ProjectName).Path
Set-Location $projectPath
Write-Success "Berhasil masuk ke direktori proyek: $projectPath"

# ══════════════════════════════════════════════
#  STACK A — React 19 + Inertia.js + TailwindCSS
# ══════════════════════════════════════════════
if ($StackChoice -eq "react") {

    Write-Header "Menginstal Dependensi Composer (Inertia)..."
    composer require inertiajs/inertia-laravel

    if ($WithFilament) {
        Write-Header "Menginstal Filament dan Livewire..."
        composer require filament/filament livewire/livewire
    }

    # Middleware Inertia
    Write-Header "Membuat Middleware Inertia..."
    php artisan inertia:middleware

    $bootstrapFile = Join-Path $projectPath "bootstrap/app.php"
    if (Test-Path $bootstrapFile) {
        Write-Info "Mendaftarkan HandleInertiaRequests ke bootstrap/app.php..."
        $bc  = Get-Content $bootstrapFile -Raw
        $pat = '->withMiddleware\(function\s*\(Middleware\s+\$middleware\)\s*\{[\s#\/\*]*\}'
        $rep = "->withMiddleware(function (Middleware `$middleware) {`n        `$middleware->web(append: [`n            \App\Http\Middleware\HandleInertiaRequests::class,`n        ]);`n    }"
        $bc2 = $bc -replace $pat, $rep
        if ($bc2 -eq $bc) {
            $bc2 = $bc -replace '(?s)withMiddleware\(function\s*\(Middleware\s+\$middleware\)\s*\{(.*?)\}', "withMiddleware(function (Middleware `$middleware) {`n        `$middleware->web(append: [`n            \App\Http\Middleware\HandleInertiaRequests::class,`n        ]);`n    `1}"
        }
        Set-Content $bootstrapFile $bc2
        Write-Success "bootstrap/app.php berhasil dikonfigurasi."
    }

    # app.blade.php
    Write-Header "Membuat root template app.blade.php (Inertia)..."
    Write-TextFile (Join-Path $projectPath "resources/views/app.blade.php") $TMPL_BLADE_INERTIA
    Write-Success "app.blade.php berhasil dibuat."

    $wb = Join-Path $projectPath "resources/views/welcome.blade.php"
    if (Test-Path $wb) { Remove-Item $wb -Force }

    # routes/web.php
    Write-TextFile (Join-Path $projectPath "routes/web.php") $TMPL_ROUTES_REACT
    Write-Success "routes/web.php berhasil dikonfigurasi."

    # NPM
    Write-Header "Menginstal Dependensi JavaScript (NPM)..."
    npm install react@latest react-dom@latest @inertiajs/react@latest @inertiajs/vite@latest tailwindcss@latest @tailwindcss/vite@latest --legacy-peer-deps
    npm install @vitejs/plugin-react@latest laravel-vite-plugin@latest vite@latest --save-dev --legacy-peer-deps

    # vite.config.js
    Write-Header "Mengonfigurasi vite.config.js (React)..."
    $viteContent = if ($WithSSR) { $TMPL_VITE_REACT_SSR } else { $TMPL_VITE_REACT }
    Write-TextFile (Join-Path $projectPath "vite.config.js") $viteContent
    Write-Success "vite.config.js berhasil dikonfigurasi."

    # package.json
    $pkgPath = Join-Path $projectPath "package.json"
    if (Test-Path $pkgPath) {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        $pkg.scripts.build = if ($WithSSR) { "vite build && vite build --ssr" } else { "vite build" }
        $pkg.scripts.dev   = "vite"
        $pkg | Add-Member -MemberType NoteProperty -Name "overrides" -Value ([PSCustomObject]@{"shell-quote" = "^1.8.4"}) -Force
        $pkgStr = ($pkg | ConvertTo-Json -Depth 10) -replace '\\u0026', '&'
        Set-Content $pkgPath $pkgStr
        Write-Success "package.json berhasil diperbarui."
    }

    # Pages & JS files
    Write-Header "Membuat file aset frontend (React/Inertia)..."
    $pagesDir = Join-Path $projectPath "resources/js/Pages"
    if (-not (Test-Path $pagesDir)) { New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null }

    Write-TextFile (Join-Path $pagesDir "Welcome.jsx") $TMPL_WELCOME_JSX
    Write-TextFile (Join-Path $projectPath "resources/js/app.jsx") $TMPL_APP_JSX
    if ($WithSSR) { Write-TextFile (Join-Path $projectPath "resources/js/ssr.jsx") $TMPL_SSR_JSX }

    Write-TextFile (Join-Path $projectPath "resources/css/app.css") '@import "tailwindcss";'
    Write-Success "File aset frontend React/Inertia berhasil disiapkan."
}

# ══════════════════════════════════════════════
#  STACK B — Laravel Blade + TailwindCSS v4
# ══════════════════════════════════════════════
elseif ($StackChoice -eq "blade") {

    if ($WithFilament) {
        Write-Header "Menginstal Filament dan Livewire..."
        composer require filament/filament livewire/livewire
    }

    # NPM — TailwindCSS saja
    Write-Header "Menginstal Dependensi JavaScript (NPM) - TailwindCSS only..."
    npm install tailwindcss@latest @tailwindcss/vite@latest --legacy-peer-deps
    npm install laravel-vite-plugin@latest vite@latest --save-dev --legacy-peer-deps

    # vite.config.js
    Write-Header "Mengonfigurasi vite.config.js (Blade)..."
    Write-TextFile (Join-Path $projectPath "vite.config.js") $TMPL_VITE_BLADE
    Write-Success "vite.config.js berhasil dikonfigurasi."

    # package.json
    $pkgPath = Join-Path $projectPath "package.json"
    if (Test-Path $pkgPath) {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        $pkg.scripts.build = "vite build"
        $pkg.scripts.dev   = "vite"
        $pkg | Add-Member -MemberType NoteProperty -Name "overrides" -Value ([PSCustomObject]@{"shell-quote" = "^1.8.4"}) -Force
        $pkgStr = ($pkg | ConvertTo-Json -Depth 10) -replace '\\u0026', '&'
        Set-Content $pkgPath $pkgStr
        Write-Success "package.json berhasil diperbarui."
    }

    # CSS, JS entry, Layout, Welcome
    Write-TextFile (Join-Path $projectPath "resources/css/app.css") '@import "tailwindcss";'
    Write-TextFile (Join-Path $projectPath "resources/js/app.js")   '// Laravel Blade app entry point'

    Write-Header "Membuat layout dan halaman Blade..."
    $layoutsDir = Join-Path $projectPath "resources/views/layouts"
    if (-not (Test-Path $layoutsDir)) { New-Item -ItemType Directory -Path $layoutsDir -Force | Out-Null }

    Write-TextFile (Join-Path $layoutsDir "app.blade.php") $TMPL_LAYOUT_BLADE
    Write-TextFile (Join-Path $projectPath "resources/views/welcome.blade.php") $TMPL_WELCOME_BLADE

    # routes/web.php
    Write-TextFile (Join-Path $projectPath "routes/web.php") $TMPL_ROUTES_BLADE
    Write-Success "routes/web.php berhasil dikonfigurasi."

    Write-Success "File aset frontend Blade berhasil disiapkan."
}

# ─────────────────────────────────────────────
# 6. Konfigurasi Database MySQL + Auto Migrate
#    (berlaku untuk SEMUA stack)
# ─────────────────────────────────────────────
Write-Header "Mengonfigurasi Database MySQL..."
$dbName = $ProjectName
Write-Info "Nama database: $dbName"

$envFile = Join-Path $projectPath ".env"
if (Test-Path $envFile) {
    Write-Info "Memperbarui konfigurasi database di .env..."
    $envContent = Get-Content $envFile -Raw
    $envContent = $envContent -replace 'DB_CONNECTION=sqlite', 'DB_CONNECTION=mysql'
    $envContent = $envContent -replace 'DB_CONNECTION=\w*',    'DB_CONNECTION=mysql'
    $envContent = $envContent -replace 'DB_DATABASE=.*',       "DB_DATABASE=$dbName"
    $envContent = $envContent -replace 'DB_USERNAME=\w*',      'DB_USERNAME=root'
    $envContent = $envContent -replace 'DB_PASSWORD=.*',       'DB_PASSWORD='
    if ($envContent -notmatch 'DB_HOST') { $envContent += "`nDB_HOST=127.0.0.1`nDB_PORT=3306" }
    Set-Content $envFile $envContent
    Write-Success ".env berhasil dikonfigurasi untuk MySQL."
}

try {
    Write-Info "Mencoba membuat database '$dbName' via PHP PDO..."
    $phpCode = "try { `$pdo = new PDO('mysql:host=127.0.0.1;port=3306', 'root', ''); `$pdo->exec('CREATE DATABASE IF NOT EXISTS ' . chr(96) . '$dbName' . chr(96)); } catch (Exception `$e) { echo `$e->getMessage(); exit(1); }"
    php -r $phpCode
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database '$dbName' berhasil dibuat/sudah ada."
        Write-Info "Menjalankan php artisan migrate..."
        php artisan migrate --force
        Write-Success "Migrasi database berhasil dijalankan."
    } else { throw "exit code bukan 0" }
} catch {
    Write-Warning "Gagal membuat database/migrasi secara otomatis."
    Write-Warning "Pastikan MySQL (Laragon) aktif, lalu jalankan 'php artisan migrate' secara manual."
}

# ─────────────────────────────────────────────
# 7. Setup Filament (berlaku untuk semua stack)
# ─────────────────────────────────────────────
if ($WithFilament) {
    Write-Header "Mengonfigurasi Filament Panel..."
    php artisan filament:install --panels --quiet
    Write-Success "Filament panel berhasil dipasang."
}

# ─────────────────────────────────────────────
# 8. Update + Audit Fix
# ─────────────────────────────────────────────
Write-Header "Melakukan Pembaruan dan Audit Keamanan..."
composer update
npm update --legacy-peer-deps
npm audit fix --legacy-peer-deps
Write-Success "Pembaruan dan audit selesai."

# ─────────────────────────────────────────────
# 9. Selesai
# ─────────────────────────────────────────────
$endTime  = Get-Date
$duration = ($endTime - $startTime).ToString("mm\:ss")

Write-Header "PROSES SELESAI!"
Write-Host "Proyek '$ProjectName' berhasil dibuat dalam waktu $duration!" -ForegroundColor Green
Write-Host ""
Write-Host "Stack       : $stackLabel" -ForegroundColor Cyan
Write-Host ""
Write-Host "Langkah selanjutnya:" -ForegroundColor Cyan
Write-Host "  1. Pastikan database '$dbName' ada dan .env sudah benar"
Write-Host "  2. php artisan serve"
Write-Host "  3. npm run dev"
if ($WithFilament) { Write-Host "  4. php artisan make:filament-user" }
Write-Host ""
