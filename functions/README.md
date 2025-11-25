# Firebase Cloud Functions Setup for Email Invites

This guide explains how to set up and deploy the Firebase Cloud Function for sending email invitations.

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project configured
- Node.js 18 or higher

## Setup Steps

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Create .env File for Local Development

Create a `.env` file in the `functions` directory:

```bash
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

**Important**: Add `.env` to your `.gitignore` to avoid committing credentials!

### 3. Configure Email Credentials for Production

#### Option A: Gmail (For Testing)

1. Create an App Password for your Gmail account:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password

2. Set the environment variables when deploying:
```bash
firebase deploy --only functions --set-env EMAIL_USER="your-email@gmail.com",EMAIL_PASSWORD="your-app-password"
```

Or set them via Firebase Console:
- Go to Firebase Console → Functions
- Click on your function → Configuration
- Add environment variables: `EMAIL_USER` and `EMAIL_PASSWORD`

#### Option B: SendGrid (Recommended for Production)

1. Sign up for SendGrid (free tier: 100 emails/day)
2. Get your API key
3. Modify `functions/index.js` to use SendGrid instead of Gmail
4. Set environment variable: `SENDGRID_API_KEY`

### 4. Deploy the Function

```bash
cd "c:\Users\rhasi\OneDrive\Desktop\SPLITWISE CLONE - RN\splitwise-flutter-app\splitwise_clone"
firebase deploy --only functions
```

If you need to set environment variables during deployment:
```bash
firebase deploy --only functions --set-env EMAIL_USER="your-email@gmail.com",EMAIL_PASSWORD="your-app-password"
```

### 5. Test the Function Locally (Optional)

You can test locally using the Firebase emulator:

```bash
cd functions
npm run serve
```

Then update `email_service.dart` to use the local emulator URL:
```dart
// For local testing
final FirebaseFunctions _functions = FirebaseFunctions.instance;
// Use local emulator (uncomment for local testing)
// _functions.useFunctionsEmulator('localhost', 5001);
```

## Troubleshooting

### "Cannot read properties of undefined" Error
- This means environment variables are not set
- Make sure you've set `EMAIL_USER` and `EMAIL_PASSWORD`
- For local testing, create a `.env` file
- For production, set via `--set-env` flag or Firebase Console

### Function not found error
- Make sure the function is deployed: `firebase deploy --only functions`
- Check the function name matches in both `index.js` and `email_service.dart`
- Verify the function appears in Firebase Console

### Email not sending
- Verify email credentials are correct
- Check Firebase Functions logs: `firebase functions:log`
- For Gmail, ensure you're using an App Password, not your regular password
- Check that "Less secure app access" is enabled (if not using App Password)

### CORS errors
- The function uses `onCall` which handles CORS automatically
- Ensure you're using the latest Firebase SDK

## Cost Considerations

- **Firebase Functions**: Free tier includes 2M invocations/month
- **Gmail**: Free but limited (use for testing only)
- **SendGrid**: Free tier includes 100 emails/day

## Security Notes

- Never commit email credentials to version control
- Always use environment variables or Firebase secrets
- Add `.env` to `.gitignore`
- Consider implementing rate limiting for production
- Validate email addresses on both client and server side

## Environment Variables

The function uses these environment variables:
- `EMAIL_USER`: Your email address (Gmail or other SMTP service)
- `EMAIL_PASSWORD`: Your email password or app-specific password
