# React Laravel Installer by Badroel07

An automated Windows CLI installer script to instantly bootstrap a modern web application using Laravel 12, Inertia.js, React, TailwindCSS v4, and Filament PHP v5.

## 🚀 Features

- **Laravel 12 & React 19 SPA** out of the box using Inertia.js.
- **Inertia SSR / CSR Selection**: Choose whether you want Server-Side Rendering enabled or stick to Client-Side Rendering.
- **TailwindCSS v4 Integration**: Fully configured using the new `@tailwindcss/vite` plugin.
- **Optional Filament PHP v5**: Easily choose whether to install Filament PHP Admin Panel & Livewire.
- **Automatic MySQL Setup**: Automatically configures the `.env` file, creates the MySQL database matching your project name, and runs migrations automatically (powered by PHP PDO, no `mysql` CLI required in PATH).
- **Latest Library Versions**: Always pulls the absolute latest stable releases of Vite, Tailwind, React, Inertia, and Filament.

## 📦 Prerequisites

Ensure you have the following installed on your Windows machine:
- PHP (>= 8.2)
- Composer
- Node.js & NPM
- MySQL Server (e.g., Laragon, XAMPP, or native MySQL)

## 🛠️ Usage

Clone this script into your web root directory (e.g., `C:\laragon\www` or `C:\xampp\htdocs`):

### 1. Via Command Prompt (CMD)
```cmd
create-project.bat your-project-name
