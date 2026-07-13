const nodemailer = require('nodemailer');
require('dotenv').config();

// Create transporter
const transporter = nodemailer.createTransport({
  pool: true,
  host: process.env.SMTP_HOST || 'smtp-relay.brevo.com',
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: parseInt(process.env.SMTP_PORT || '587', 10) === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  connectionTimeout: 10000,
  greetingTimeout: 10000,
  socketTimeout: 10000,
  tls: {
    rejectUnauthorized: false
  }
});

/**
 * Send password reset confirmation email
 * @param {string} toEmail 
 * @param {string} name 
 * @param {string} newPassword 
 */
async function sendPasswordResetEmail(toEmail, name, newPassword) {
  const fromEmail = process.env.FROM_EMAIL || 'eazziogroup@gmail.com';
  
  const mailOptions = {
    from: `"Eazzio Reminder" <${fromEmail}>`,
    to: toEmail,
    subject: 'Your Password Has Been Reset Successfully',
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border: 1px solid #e8e7f3; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 12px rgba(124, 58, 237, 0.05);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #7C3AED; margin: 0; font-size: 24px; font-weight: bold;">Password Reset Success</h2>
          <p style="color: #6E6893; font-size: 14px; margin-top: 6px;">Eazzio Reminder Account Services</p>
        </div>
        <p style="color: #1E1B4B; font-size: 15px; line-height: 1.5;">Dear <strong>${name}</strong>,</p>
        <p style="color: #4A457E; font-size: 14px; line-height: 1.5;">Your password for the Eazzio Reminder account has been successfully reset. Please use your new credentials to sign in.</p>
        
        <div style="background-color: #F9F8FD; border: 1px solid #E5E3F5; border-radius: 12px; padding: 20px; margin: 24px 0;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 6px 0; font-size: 14px; color: #757095; font-weight: 600; width: 120px;">Username / Email:</td>
              <td style="padding: 6px 0; font-size: 14px; color: #1E1B4B; font-weight: 700;">${toEmail}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; font-size: 14px; color: #757095; font-weight: 600;">New Password:</td>
              <td style="padding: 6px 0; font-size: 14px; color: #7C3AED; font-weight: 700; font-family: monospace;">${newPassword}</td>
            </tr>
          </table>
        </div>
        
        <div style="background-color: #FFF5F5; border: 1px solid #FEE2E2; border-radius: 12px; padding: 14px; margin-bottom: 24px;">
          <p style="color: #EF4444; font-size: 13px; margin: 0; line-height: 1.4; font-weight: 500;">
            <strong>Security Warning:</strong> If you did not initiate this password reset request, please secure your account or contact support immediately.
          </p>
        </div>
        
        <hr style="border: 0; border-top: 1px solid #E5E3F5; margin: 24px 0;" />
        <p style="font-size: 11px; color: #9CA3AF; text-align: center; margin: 0;">This is an automated security notification from Eazzio Reminder. Please do not reply to this email.</p>
      </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[SMTP] Password reset email sent to ${toEmail}: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`[SMTP] Error sending password reset email to ${toEmail}:`, error);
    throw error;
  }
}

/**
 * Send OTP password reset email
 * @param {string} toEmail 
 * @param {string} name 
 * @param {string} otp 
 */
async function sendOtpEmail(toEmail, name, otp) {
  const fromEmail = process.env.FROM_EMAIL || process.env.SMTP_USER || 'aed402001@smtp-brevo.com';
  
  const mailOptions = {
    from: `"Eazzio Reminder" <${fromEmail}>`,
    to: toEmail,
    subject: 'Your Password Reset OTP - Eazzio Reminder',
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border: 1px solid #e8e7f3; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 12px rgba(124, 58, 237, 0.05);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #7C3AED; margin: 0; font-size: 24px; font-weight: bold;">Security Verification Code</h2>
          <p style="color: #6E6893; font-size: 14px; margin-top: 6px;">Eazzio Reminder Security Services</p>
        </div>
        <p style="color: #1E1B4B; font-size: 15px; line-height: 1.5;">Dear <strong>${name}</strong>,</p>
        <p style="color: #4A457E; font-size: 14px; line-height: 1.5;">We received a request to reset your password. Use the following 6-digit verification code (OTP) to complete the process. This code will expire in 5 minutes.</p>
        
        <div style="text-align: center; margin: 32px 0;">
          <div style="background-color: #F9F8FD; border: 1.5px dashed #7C3AED; color: #7C3AED; font-size: 32px; font-weight: 800; letter-spacing: 6px; padding: 18px; border-radius: 12px; display: inline-block; min-width: 200px; font-family: monospace; text-align: center;">${otp}</div>
        </div>
        
        <div style="background-color: #F9F8FD; border: 1px solid #E5E3F5; border-radius: 12px; padding: 14px; margin-top: 24px;">
          <p style="color: #757095; font-size: 12px; margin: 0; line-height: 1.4;">
            If you did not request a password reset, you can safely ignore this email. Do not share this OTP code with anyone.
          </p>
        </div>
        
        <hr style="border: 0; border-top: 1px solid #E5E3F5; margin: 24px 0;" />
        <p style="font-size: 11px; color: #9CA3AF; text-align: center; margin: 0;">This is an automated security notification from Eazzio Reminder. Please do not reply to this email.</p>
      </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[SMTP] OTP email sent to ${toEmail}: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`[SMTP] Error sending OTP email to ${toEmail}:`, error);
    throw error;
  }
}

module.exports = {
  sendPasswordResetEmail,
  sendOtpEmail,
};
