# ============================================================
# e-Office — Cau hinh IIS Reverse Proxy
# Chay sau khi deploy-windows.ps1 thanh cong
# PowerShell (Administrator): .\setup-iis.ps1
# ============================================================

$ErrorActionPreference = "Stop"

function Log($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }

# Cai IIS + URL Rewrite + ARR
Log "Cai dat IIS..."
Install-WindowsFeature -Name Web-Server, Web-WebSockets -IncludeManagementTools | Out-Null
Log "IIS da cai"

# Tai URL Rewrite Module
$urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$urlRewriteFile = "C:\qlvb\_installers\urlrewrite.msi"
if (-not (Test-Path "C:\Program Files\IIS\URL Rewrite Module 2\rewrite.dll" -ErrorAction SilentlyContinue)) {
    Log "Tai URL Rewrite Module..."
    Invoke-WebRequest -Uri $urlRewriteUrl -OutFile $urlRewriteFile -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$urlRewriteFile`" /quiet /norestart" -Wait
    Log "URL Rewrite da cai"
}

# Tai ARR (Application Request Routing)
$arrUrl = "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi"
$arrFile = "C:\qlvb\_installers\arr.msi"
if (-not (Test-Path $arrFile)) {
    Log "Tai Application Request Routing..."
    Invoke-WebRequest -Uri $arrUrl -OutFile $arrFile -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$arrFile`" /quiet /norestart" -Wait
    Log "ARR da cai"
}

# Enable proxy trong ARR
Log "Bat ARR Proxy..."
& "$env:windir\system32\inetsrv\appcmd.exe" set config -section:system.webServer/proxy -enabled:true -commit:apphost 2>$null

# Tao web.config cho reverse proxy
$webConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <!-- Backend API -->
        <rule name="API Proxy" stopProcessing="true">
          <match url="^api/(.*)" />
          <action type="Rewrite" url="http://127.0.0.1:4000/api/{R:1}" />
        </rule>
        <!-- Frontend Next.js -->
        <rule name="Frontend Proxy" stopProcessing="true">
          <match url="(.*)" />
          <action type="Rewrite" url="http://127.0.0.1:3000/{R:1}" />
        </rule>
      </rules>
    </rewrite>
    <security>
      <requestFiltering>
        <requestLimits maxAllowedContentLength="52428800" />
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
"@

$iisRoot = "C:\inetpub\wwwroot"
$webConfig | Out-File -FilePath "$iisRoot\web.config" -Encoding utf8
Log "web.config da tao"

# Restart IIS
iisreset /restart | Out-Null
Log "IIS da restart"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  IIS Reverse Proxy da cau hinh!" -ForegroundColor Green
Write-Host ""
Write-Host "  Truy cap: http://103.97.134.87"
Write-Host "    /       -> Next.js (:3000)"
Write-Host "    /api/*  -> Express (:4000)"
Write-Host "============================================" -ForegroundColor Green
