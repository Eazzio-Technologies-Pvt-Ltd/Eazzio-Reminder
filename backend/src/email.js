const nodemailer = require('nodemailer');
require('dotenv').config();

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp-relay.brevo.com',
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
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
 * Send password reset link email
 * @param {string} toEmail 
 * @param {string} name 
 * @param {string} resetLink 
 */
async function sendForgotPasswordEmail(toEmail, name, resetLink) {
  const fromEmail = process.env.FROM_EMAIL || 'eazziogroup@gmail.com';
  
  const mailOptions = {
    from: `"Eazzio Reminder" <${fromEmail}>`,
    to: toEmail,
    subject: 'Password Reset Request - Eazzio Reminder',
    html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border: 1px solid #e8e7f3; border-radius: 16px; background-color: #ffffff; box-shadow: 0 4px 12px rgba(124, 58, 237, 0.05);">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #7C3AED; margin: 0; font-size: 24px; font-weight: bold;">Password Reset Request</h2>
          <p style="color: #6E6893; font-size: 14px; margin-top: 6px;">Eazzio Reminder Security Services</p>
        </div>
        <p style="color: #1E1B4B; font-size: 15px; line-height: 1.5;">Dear <strong>${name}</strong>,</p>
        <p style="color: #4A457E; font-size: 14px; line-height: 1.5;">We received a request to reset your password for your Eazzio Reminder account. Click the button below to set a new password. This link will expire in 15 minutes.</p>
        
        <div style="text-align: center; margin: 32px 0;">
          <a href="${resetLink}" style="background-color: #7C3AED; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: bold; font-size: 15px; display: inline-block; box-shadow: 0 4px 12px rgba(124, 58, 237, 0.25);">Reset Password</a>
        </div>
        
        <p style="color: #757095; font-size: 12px; line-height: 1.5;">If the button above does not work, copy and paste this URL into your browser:</p>
        <p style="font-size: 12px; color: #7C3AED; word-break: break-all; font-family: monospace; background-color: #F9F8FD; border: 1px solid #E5E3F5; padding: 12px; border-radius: 8px;">${resetLink}</p>
        
        <div style="background-color: #F9F8FD; border: 1px solid #E5E3F5; border-radius: 12px; padding: 14px; margin-top: 24px;">
          <p style="color: #757095; font-size: 12px; margin: 0; line-height: 1.4;">
            If you did not request a password reset, you can safely ignore this email. Your current password will remain unchanged.
          </p>
        </div>
        
        <hr style="border: 0; border-top: 1px solid #E5E3F5; margin: 24px 0;" />
        <p style="font-size: 11px; color: #9CA3AF; text-align: center; margin: 0;">This is an automated security notification from Eazzio Reminder. Please do not reply to this email.</p>
      </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[SMTP] Password reset link sent to ${toEmail}: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`[SMTP] Error sending password reset link to ${toEmail}:`, error);
    throw error;
  }
}

module.exports = {
  sendPasswordResetEmail,
  sendForgotPasswordEmail,
};
