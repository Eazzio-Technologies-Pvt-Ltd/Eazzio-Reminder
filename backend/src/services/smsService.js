/**
 * SMS service using MSG91 with Fast2SMS fallback
 */
require('dotenv').config();

/**
 * Sends OTP SMS via MSG91 (or fallback)
 * @param {string} phoneNumber 
 * @param {string} otp 
 * @returns {Promise<{success: boolean, error?: any, data?: any}>}
 */
async function sendOtpSms(phoneNumber, otp) {
  const authKey = process.env.MSG91_AUTH_KEY;
  const templateId = process.env.MSG91_TEMPLATE_ID;

  // Standardize phone number for India: must start with 91, strip non-digits
  let formattedPhone = phoneNumber.replace(/\D/g, '');
  if (formattedPhone.length === 10) {
    formattedPhone = '91' + formattedPhone;
  }

  console.log(`[SMS Service] Sending OTP "${otp}" to "${formattedPhone}"...`);

  // If MSG91 keys are missing, simulate success locally for test/development purposes
  if (!authKey || !templateId) {
    console.log(`[SMS Service] [MOCK] MSG91_AUTH_KEY or MSG91_TEMPLATE_ID is not configured. Logged OTP successfully.`);
    return { success: true, mocked: true };
  }

  try {
    const response = await fetch('https://control.msg91.com/api/v5/otp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        template_id: templateId,
        mobile: formattedPhone,
        authkey: authKey,
        otp: otp
      })
    });

    const data = await response.json();

    if (response.ok && (data.type === 'success' || data.success === true)) {
      console.log(`[SMS Service] MSG91 OTP sent successfully to ${formattedPhone}`);
      return { success: true, data };
    }

    console.error(`[SMS Service] MSG91 API returned error:`, data);
    
    // Fallback to Fast2SMS if configured and MSG91 fails
    if (process.env.FAST2SMS_API_KEY) {
      console.log(`[SMS Service] Attempting fallback to Fast2SMS...`);
      return await sendFast2SmsFallback(formattedPhone, otp);
    }

    return { success: false, error: data };
  } catch (err) {
    console.error(`[SMS Service] Error in sendOtpSms:`, err);
    
    // Fallback to Fast2SMS
    if (process.env.FAST2SMS_API_KEY) {
      console.log(`[SMS Service] Attempting fallback to Fast2SMS due to network error...`);
      return await sendFast2SmsFallback(formattedPhone, otp);
    }
    
    return { success: false, error: err.message };
  }
}

/**
 * Fallback SMS trigger using Fast2SMS API
 */
async function sendFast2SmsFallback(formattedPhone, otp) {
  const apiKey = process.env.FAST2SMS_API_KEY;
  // Get 10-digit number for Fast2SMS in India
  const tenDigitPhone = formattedPhone.substring(formattedPhone.length - 10);
  
  try {
    const response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
      method: 'POST',
      headers: {
        'authorization': apiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        variables_values: otp,
        route: 'otp',
        numbers: tenDigitPhone
      })
    });
    
    const data = await response.json();
    if (response.ok && data.return === true) {
      console.log(`[SMS Service] Fast2SMS Fallback OTP sent successfully to ${tenDigitPhone}`);
      return { success: true, data };
    }
    
    console.error(`[SMS Service] Fast2SMS returned error:`, data);
    return { success: false, error: data };
  } catch (err) {
    console.error(`[SMS Service] Fast2SMS error:`, err);
    return { success: false, error: err.message };
  }
}

module.exports = {
  sendOtpSms
};
