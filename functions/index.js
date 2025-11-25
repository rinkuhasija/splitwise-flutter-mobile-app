const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineString } = require('firebase-functions/params');
const nodemailer = require('nodemailer');

// Define environment parameters with fallback to process.env for local development
const emailUser = defineString('EMAIL_USER', { default: process.env.EMAIL_USER || '' });
const emailPassword = defineString('EMAIL_PASSWORD', { default: process.env.EMAIL_PASSWORD || '' });

exports.sendInviteEmail = onCall(async (request) => {
    const { recipientEmail, recipientName, senderName, appDownloadLink } = request.data;

    // Validate input
    if (!recipientEmail || !recipientName || !senderName) {
        throw new HttpsError(
            'invalid-argument',
            'Missing required parameters'
        );
    }

    // Create transporter inside the function
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: emailUser.value(),
            pass: emailPassword.value(),
        },
    });

    // Email template
    const mailOptions = {
        from: `Splitwise Clone <${emailUser.value()}>`,
        to: recipientEmail,
        subject: `${senderName} invited you to Splitwise Clone!`,
        html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background: linear-gradient(135deg, #00D09C 0%, #00A67E 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
          }
          .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 10px 10px;
          }
          .button {
            display: inline-block;
            background: #00D09C;
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
          }
          .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
            font-size: 12px;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>🎉 You're Invited!</h1>
        </div>
        <div class="content">
          <p>Hi ${recipientName},</p>
          
          <p><strong>${senderName}</strong> has invited you to join <strong>Splitwise Clone</strong> - the easiest way to split bills and track shared expenses with friends!</p>
          
          <p>With Splitwise Clone, you can:</p>
          <ul>
            <li>✅ Split bills with friends and family</li>
            <li>✅ Track who owes what</li>
            <li>✅ Settle up easily</li>
            <li>✅ Keep your finances organized</li>
          </ul>
          
          <div style="text-align: center;">
            <a href="${appDownloadLink || 'https://play.google.com/store'}" class="button">
              Download the App
            </a>
          </div>
          
          <p>Start splitting expenses with ${senderName} today!</p>
          
          <p>Best regards,<br>The Splitwise Clone Team</p>
        </div>
        <div class="footer">
          <p>This email was sent because ${senderName} added you as a friend on Splitwise Clone.</p>
        </div>
      </body>
      </html>
    `,
    };

    try {
        await transporter.sendMail(mailOptions);
        return { success: true, message: 'Email sent successfully' };
    } catch (error) {
        console.error('Error sending email:', error);
        throw new HttpsError('internal', 'Failed to send email');
    }
});
