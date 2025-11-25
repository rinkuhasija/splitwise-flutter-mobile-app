@echo off
REM Script to generate Android keystore for signing release builds
REM This script will create a keystore file and display the information needed for GitHub Secrets

echo =========================================
echo Android Keystore Generation Script
echo =========================================
echo.

REM Prompt for keystore details
set /p KEYSTORE_PASSWORD="Enter keystore password (min 6 characters): "
set /p KEY_ALIAS="Enter key alias (e.g., upload): "
set /p KEY_PASSWORD="Enter key password (min 6 characters): "
set /p DNAME_CN="Enter your name: "
set /p DNAME_O="Enter your organization (optional): "
set /p DNAME_L="Enter your city: "
set /p DNAME_ST="Enter your state/province: "
set /p DNAME_C="Enter your country code (e.g., US, IN): "

echo.
echo Generating keystore...
echo.

REM Generate the keystore
keytool -genkey -v ^
  -keystore android\app\upload-keystore.jks ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias %KEY_ALIAS% ^
  -storepass %KEYSTORE_PASSWORD% ^
  -keypass %KEY_PASSWORD% ^
  -dname "CN=%DNAME_CN%, O=%DNAME_O%, L=%DNAME_L%, ST=%DNAME_ST%, C=%DNAME_C%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Keystore generated successfully!
    echo.
    echo =========================================
    echo GitHub Secrets Configuration
    echo =========================================
    echo.
    echo Add these secrets to your GitHub repository:
    echo ^(Settings → Secrets and variables → Actions → New repository secret^)
    echo.
    echo 1. KEYSTORE_PASSWORD
    echo    Value: %KEYSTORE_PASSWORD%
    echo.
    echo 2. KEY_ALIAS
    echo    Value: %KEY_ALIAS%
    echo.
    echo 3. KEY_PASSWORD
    echo    Value: %KEY_PASSWORD%
    echo.
    echo 4. KEYSTORE_BASE64
    echo    Run this command to get the value:
    echo    certutil -encode android\app\upload-keystore.jks keystore.txt ^&^& findstr /v CERTIFICATE keystore.txt ^> keystore-base64.txt
    echo    Then copy the contents of keystore-base64.txt
    echo.
    echo 5. GOOGLE_SERVICES_JSON
    echo    Run this command to get the value:
    echo    type android\app\google-services.json
    echo.
    echo =========================================
    echo ⚠️  IMPORTANT: Keep these values secure!
    echo =========================================
    echo.
    
    REM Generate base64 for convenience
    echo Generating base64 encoded keystore...
    certutil -encode android\app\upload-keystore.jks keystore.txt >nul 2>&1
    findstr /v CERTIFICATE keystore.txt > keystore-base64.txt
    echo.
    echo KEYSTORE_BASE64 value saved to keystore-base64.txt
    echo Copy the contents of this file to GitHub Secrets
    echo.
) else (
    echo.
    echo ❌ Failed to generate keystore
    echo Make sure you have keytool installed ^(comes with Java JDK^)
    pause
    exit /b 1
)

pause
