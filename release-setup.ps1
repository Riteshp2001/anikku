param(
    [switch]$GenerateKeystore,
    [switch]$EncodeKeystore,
    [string]$KeystorePath = "anikku-release-key.jks"
)

# Requires PowerShell 7+
$ErrorActionPreference = "Stop"

function Show-Menu {
    Write-Output @"

========================================
  ANIKKU RELEASE SETUP TOOL
========================================
1. Generate a new keystore
2. Encode existing keystore to Base64 (for GitHub secret)
3. Show setup instructions
4. Exit
"@
    $choice = Read-Host "Select option (1-4)"
    switch ($choice) {
        "1" { Generate-Keystore }
        "2" { Encode-KeystoreToBase64 }
        "3" { Show-Instructions }
        "4" { Write-Output "Exiting."; return }
        default { Write-Output "Invalid option"; Show-Menu }
    }
}

function Generate-Keystore {
    Write-Output "`n=== Generating Keystore ==="
    $storePass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    $alias = "anikku-key"
    $outputFile = "anikku-release-key.jks"

    if (Test-Path $outputFile) {
        $overwrite = Read-Host "$outputFile already exists. Overwrite? (y/N)"
        if ($overwrite -ne "y") { Write-Output "Cancelled."; return }
    }

    keytool -genkey -v -keystore $outputFile -alias $alias -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $storePass -keypass $storePass `
        -dname "CN=Anikku, OU=Mobile, O=Anikku, L=Unknown, ST=Unknown, C=US" 2>&1

    if ($?) {
        Write-Output "`n✓ Keystore generated: $outputFile"
        Write-Output "✓ Alias: $alias"
        Write-Output "✓ Password: $storePass"

        # Save credentials
        @"
Keystore: $outputFile
Alias:    $alias
Password: $storePass
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@ | Out-File -FilePath "release-credentials.txt" -Encoding utf8

        Write-Output "✓ Credentials saved to release-credentials.txt (DO NOT COMMIT)"

        Encode-KeystoreToBase64 -path $outputFile
    } else {
        Write-Error "Keystore generation failed. Is Java JDK installed?"
    }
}

function Encode-KeystoreToBase64 {
    param([string]$path = $KeystorePath)
    if (-not (Test-Path $path)) {
        Write-Error "Keystore not found: $path"
        return
    }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $path))
    $base64 = [Convert]::ToBase64String($bytes)
    Write-Output "`n=== BASE64 ENCODED KEYSTORE (for SIGNING_KEY secret) ==="
    Write-Output $base64
    Write-Output "=== END BASE64 ==="
}

function Show-Instructions {
    Write-Output @"

========================================
  GITHUB RELEASE SETUP INSTRUCTIONS
========================================

1. CREATE A GITHUB REPOSITORY
   - Create a new repo on GitHub (e.g., your-username/anikku)
   - Push this code to the repo

2. CONFIGURE GITHUB SECRETS
   Go to Settings → Secrets and variables → Actions → New repository secret

   Required Secrets:
   ┌──────────────────────┬──────────────────────────────────────────┐
   │ Secret Name          │ Value                                    │
   ├──────────────────────┼──────────────────────────────────────────┤
   │ SIGNING_KEY          │ Base64-encoded keystore (run this script │
   │                      │ and select option 2)                     │
   ├──────────────────────┼──────────────────────────────────────────┤
   │ ALIAS                │ anikku-key                               │
   ├──────────────────────┼──────────────────────────────────────────┤
   │ KEY_STORE_PASSWORD   │ Your keystore password (from              │
   │                      │ release-credentials.txt)                 │
   ├──────────────────────┼──────────────────────────────────────────┤
   │ KEY_PASSWORD         │ Same as KEY_STORE_PASSWORD               │
   └──────────────────────┴──────────────────────────────────────────┘

   Optional (for Firebase/Google Drive features):
   ┌──────────────────────┬──────────────────────────────────────────┐
   │ GOOGLE_SERVICES_JSON │ Your Firebase google-services.json       │
   │ GOOGLE_CLIENT_SECRETS_JSON │ Your Google API client_secrets.json  │
   └──────────────────────┴──────────────────────────────────────────┘

3. UPDATE WORKFLOW URLs (if using a different repo)
   Edit .github/workflows/build_release.yml and update any
   'komikku-app/anikku' references to your repo's name.

4. TRIGGER A RELEASE
      git tag -a v0.1.6 -m "Release version 0.1.6"
      git push origin v0.1.6

   This triggers build_release.yml which:
   - Assembles the release APK
   - Signs it with your keystore
   - Creates a GitHub Release (as draft)
   - Attaches APKs for all architectures

5. PUBLISH THE RELEASE
   - Go to GitHub → Releases
   - Find the draft release
   - Review, add notes, and publish

========================================
"@
}

# Main
if ($GenerateKeystore) {
    Generate-Keystore
} elseif ($EncodeKeystore) {
    Encode-KeystoreToBase64
} else {
    Show-Menu
}
