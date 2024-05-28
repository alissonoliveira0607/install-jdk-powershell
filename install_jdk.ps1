# Configura a codificação padrão para UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# verifica se o script está sendo executado como administrador
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Se não for administrador solicita elevação de privilegios
if (-not (Test-IsAdmin)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

# Define a URL para o instalador MSI
$url = "https://download.oracle.com/java/22/latest/jdk-22_windows-x64_bin.msi"

# Define o caminho local onde o MSI será salvo
$output = "$env:TEMP\jdk-22_windows-x64_bin.msi"

# Define o caminho onde o JDK será instalado
$jdkDir = "C:\Program Files\Java\jdk-22"

# Verifica a versão do Java instalada
function Get-JavaVersion {
    try {
        $javaVersionOutput = & java -version 2>&1
        if ($javaVersionOutput -match '\"(\d+\.\d+).*\"') {
            return $matches[1]
        }
    } catch {
        return $null
    }
    return $null
}

$installedJavaVersion = Get-JavaVersion
$desiredJavaVersion = "22"

if ($installedJavaVersion -eq $desiredJavaVersion) {
    Write-Host "O JDK $desiredJavaVersion já está instalado."
} elseif (Test-Path "$jdkDir\bin\java.exe") {
    Write-Host "O JDK $desiredJavaVersion já está instalado no diretório padrão."
} else {
    Write-Host "Baixando o arquivo MSI de $url..."
    Invoke-WebRequest -Uri $url -OutFile $output

    # Verifica se o download foi bem-sucedido
    if (-not (Test-Path $output)) {
        Write-Host "Erro: Download do arquivo MSI falhou."
        return
    }

    Write-Host "Download concluído com sucesso."
    Write-Host "Instalando o JDK..."
    Start-Process msiexec.exe -ArgumentList "/i $output /quiet /norestart" -Wait

    # Verifica se a instalação foi bem-sucedida
    if (-not (Test-Path "$jdkDir\bin\java.exe")) {
        Write-Host "Erro durante a instalação. Não foi possível encontrar java.exe."
        return
    }

    Write-Host "Instalação concluída com sucesso."

    # Remove o arquivo MSI após a instalação
    Write-Host "Removendo o arquivo MSI temporário..."
    Remove-Item -Path $output -Force
    Write-Host "Arquivo MSI removido."
}

# Configura a variável de ambiente JAVA_HOME
$currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if ($currentJavaHome -ne $jdkDir) {
    Write-Host "Configurando JAVA_HOME..."
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkDir, "Machine")
    Write-Host "JAVA_HOME configurado para $jdkDir."
} else {
    Write-Host "JAVA_HOME já está configurado corretamente."
}

# Verifica se %JAVA_HOME%\bin está no PATH
$javaHomeBin = Join-Path $jdkDir "bin"
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($path -notlike "*$javaHomeBin*") {
    Write-Host "Adicionando $javaHomeBin ao PATH..."
    [Environment]::SetEnvironmentVariable("PATH", "$path;$javaHomeBin", "Machine")
    Write-Host "$javaHomeBin adicionado ao PATH."
} else {
    Write-Host "$javaHomeBin já está no PATH."
}

# Mantém a janela do PowerShell aberta após a execucao
Write-Host "Pressione qualquer tecla para sair..."
[System.Console]::ReadKey() | Out-Null
