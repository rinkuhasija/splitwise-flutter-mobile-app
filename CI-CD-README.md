# CI/CD Pipeline - Quick Start

This project has automatic Android APK builds set up with GitHub Actions.

## 🚀 Quick Setup (First Time Only)

### 1. Generate Keystore

Run the keystore generation script:

**Windows**: Double-click `generate-keystore.bat`  
**Linux/Mac**: Run `./generate-keystore.sh`

Save the passwords it generates!

### 2. Add GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add these 5 secrets (values from the script output):
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `KEYSTORE_BASE64`
- `GOOGLE_SERVICES_JSON`

### 3. Push to GitHub

```bash
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

## 📦 How to Get APKs

### Download from GitHub Actions
1. Go to **Actions** tab
2. Click any completed workflow
3. Download APK from **Artifacts** section

### Create a Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

APK will be automatically attached to the release!

## 🔄 What Happens Automatically

- **Push to `main`** → Signed release APK
- **Pull Request** → Debug APK
- **Push tag `v*`** → GitHub Release with APK

## 📖 Full Documentation

See [walkthrough.md](file:///C:/Users/rhasi/.gemini/antigravity/brain/61747a5e-0cda-4151-819b-bf424c9fc301/walkthrough.md) for complete setup guide and troubleshooting.

## ⚠️ Security

- Never commit `*.jks` or `key.properties` files
- Keep your keystore passwords secure
- GitHub Secrets are encrypted and safe
