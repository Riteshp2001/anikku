# Anikku Release Setup

## Prerequisites

- Java JDK 17+ (for `keytool` and building)
- Android SDK (compileSdk 35, buildTools 35.0.1, NDK 27.1.12297006)
- GitHub repository for the code

## Files Created

| File | Purpose |
|------|---------|
| `anikku-release-key.jks` | Keystore for APK signing. **DO NOT COMMIT** (already in .gitignore) |
| `release-credentials.txt` | Keystore passwords and alias. **DO NOT COMMIT** |
| `release-setup.ps1` | Helper script for keystore management |

## GitHub Secrets Required

Configure these in your repo: Settings → Secrets and variables → Actions

| Secret | Description |
|--------|-------------|
| `SIGNING_KEY` | Base64-encoded keystore. Run `release-setup.ps1` → option 2 |
| `ALIAS` | Key alias (default: `anikku-key`) |
| `KEY_STORE_PASSWORD` | Keystore password (in `release-credentials.txt`) |
| `KEY_PASSWORD` | Same as KEY_STORE_PASSWORD |
| `GOOGLE_SERVICES_JSON` | (Optional) Firebase google-services.json for telemetry |
| `GOOGLE_CLIENT_SECRETS_JSON` | (Optional) Google API client_secrets.json for Drive sync |

## Triggering a Release

```bash
git tag -a v0.1.6 -m "Release version 0.1.6"
git push origin v0.1.6
```

The `build_release.yml` workflow will:
1. Build release APKs (universal, arm64-v8a, armeabi-v7a, x86, x86_64)
2. Sign them with the keystore
3. Create a draft GitHub Release with SHA-256 checksums

After the workflow completes, go to GitHub → Releases, review the draft, and publish it.

## Preview Releases

```bash
git tag -a v0.1.6-preview.1 -m "Preview 1"
git push origin v0.1.6-preview.1
```

Or trigger manually via the `build_preview.yml` workflow dispatch in GitHub Actions.

## Build Variants

| Variant | Command | Output |
|---------|---------|--------|
| Release | `./gradlew assembleRelease` | `app/build/outputs/apk/release/` |
| Preview | `./gradlew assemblePreview` | `app/build/outputs/apk/preview/` |
| Debug | `./gradlew assembleDebug` | `app/build/outputs/apk/debug/` |
| FOSS | `./gradlew assembleFoss` | `app/build/outputs/apk/foss/` |
| Benchmark | `./gradlew assembleBenchmark` | `app/build/outputs/apk/benchmark/` |

## Versioning

Update version in `app/build.gradle.kts`:
```kotlin
versionCode = 5       // increment for each release
versionName = "0.1.6" // semantic version
```

## Workflow Summary

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `build_release.yml` | Tag `v*` | Build + sign + create draft release |
| `build_preview.yml` | Manual dispatch | Build + sign + create draft prerelease |
| `build_push.yml` | Push to master | Build + sign + upload artifact |
| `build_pull_request.yml` | PR opened | Build check + unit tests |
