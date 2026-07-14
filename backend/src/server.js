const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { dbQuery, usePostgres } = require('./db');
const { initScheduler, checkAndProcessReminders } = require('./scheduler');
const { sendPasswordResetEmail, sendForgotPasswordEmail } = require('./email');
require('dotenv').config();

function formatReminder(reminder) {
  if (!reminder) return reminder;
  if (reminder.created_at) {
    if (typeof reminder.created_at.toISOString === 'function') {
      return {
        ...reminder,
        created_at: reminder.created_at.toISOString()
      };
    }
    if (typeof reminder.created_at === 'string' && !reminder.created_at.endsWith('Z')) {
      return {
        ...reminder,
        created_at: `${reminder.created_at.replace(' ', 'T')}Z`
      };
    }
  }
  return reminder;
}

function formatLog(log) {
  if (!log) return log;
  if (log.sent_at) {
    if (typeof log.sent_at.toISOString === 'function') {
      return {
        ...log,
        sent_at: log.sent_at.toISOString()
      };
    }
    if (typeof log.sent_at === 'string' && !log.sent_at.endsWith('Z')) {
      return {
        ...log,
        sent_at: `${log.sent_at.replace(' ', 'T')}Z`
      };
    }
  }
  return log;
}

const app = express();
const server = http.createServer(app);

// Configure CORS
app.use(cors());
app.use(express.json());

// Socket.io initialization
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
});

io.on('connection', (socket) => {
  console.log(`[Socket] Client connected: ${socket.id}`);
  
  socket.on('disconnect', () => {
    console.log(`[Socket] Client disconnected: ${socket.id}`);
  });
});

// REST API Routes

// 1. Get all reminders
app.get('/api/reminders', async (req, res) => {
  const { userId } = req.query;
  try {
    let query = 'SELECT * FROM reminders';
    let params = [];
    if (userId) {
      query += ' WHERE user_id = ? OR assigned_to = ?';
      params = [userId, userId];
    }
    query += ' ORDER BY remind_date ASC, remind_time ASC';
    const reminders = await dbQuery.all(query, params);
    res.json(reminders.map(formatReminder));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Create a reminder
app.post('/api/reminders', async (req, res) => {
  const {
    title,
    recipient_name,
    recipient_phone,
    event_type,
    remind_date,
    remind_time,
    message_template,
    reminder_type,
    audio_url,
    send_option,
    notification_sound,
    user_id,
    assigned_to,
    assigned_by,
    repeat_option
  } = req.body;

  // Validation
  if (!title || !recipient_name || !recipient_phone || !event_type || !remind_date || !remind_time || !message_template || !reminder_type || !send_option) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const status = 'scheduled'; // Always start as scheduled
    const result = await dbQuery.run(
      `INSERT INTO reminders (title, recipient_name, recipient_phone, event_type, remind_date, remind_time, message_template, reminder_type, audio_url, send_option, status, notification_sound, user_id, assigned_to, assigned_by, repeat_option)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        title, 
        recipient_name, 
        recipient_phone, 
        event_type, 
        remind_date, 
        remind_time, 
        message_template, 
        reminder_type, 
        audio_url || null, 
        send_option, 
        status, 
        notification_sound || 'default',
        user_id || null,
        assigned_to || null,
        assigned_by || null,
        repeat_option || 'none'
      ]
    );

    const newReminder = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [result.id]);
    const formatted = formatReminder(newReminder);
    
    // Notify clients of new reminder
    io.emit('reminder_created', formatted);

    res.status(201).json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Update a reminder
app.put('/api/reminders/:id', async (req, res) => {
  const { id } = req.params;
  const {
    title,
    recipient_name,
    recipient_phone,
    event_type,
    remind_date,
    remind_time,
    message_template,
    reminder_type,
    audio_url,
    send_option,
    status,
    notification_sound,
    user_id,
    assigned_to,
    assigned_by,
    repeat_option
  } = req.body;

  try {
    const existing = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    await dbQuery.run(
      `UPDATE reminders 
       SET title = ?, recipient_name = ?, recipient_phone = ?, event_type = ?, remind_date = ?, remind_time = ?, message_template = ?, reminder_type = ?, audio_url = ?, send_option = ?, status = ?, notification_sound = ?, user_id = ?, assigned_to = ?, assigned_by = ?, repeat_option = ?
       WHERE id = ?`,
      [
        title || existing.title,
        recipient_name || existing.recipient_name,
        recipient_phone || existing.recipient_phone,
        event_type || existing.event_type,
        remind_date || existing.remind_date,
        remind_time || existing.remind_time,
        message_template || existing.message_template,
        reminder_type || existing.reminder_type,
        audio_url !== undefined ? audio_url : existing.audio_url,
        send_option || existing.send_option,
        status || existing.status,
        notification_sound || existing.notification_sound || 'default',
        user_id !== undefined ? user_id : existing.user_id,
        assigned_to !== undefined ? assigned_to : existing.assigned_to,
        assigned_by !== undefined ? assigned_by : existing.assigned_by,
        repeat_option !== undefined ? repeat_option : existing.repeat_option,
        id
      ]
    );

    const updated = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    const formatted = formatReminder(updated);
    io.emit('reminder_updated', formatted);

    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Delete a reminder
app.delete('/api/reminders/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const existing = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    await dbQuery.run('DELETE FROM reminders WHERE id = ?', [id]);
    io.emit('reminder_deleted', { id: parseInt(id) });

    res.json({ message: 'Reminder deleted successfully', id: parseInt(id) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- AUTH ENDPOINTS ---

// Log in or register user
app.post('/api/auth/login', async (req, res) => {
  const { email, password, name } = req.body;
  
  // 1. Password credentials sign-in
  if (email && password) {
    try {
      const user = await dbQuery.get(
        'SELECT * FROM users WHERE LOWER(email) = LOWER(?)',
        [email.trim()]
      );
      if (!user) {
        return res.status(404).json({ error: 'No user found with this email address.' });
      }
      const bcrypt = require('bcryptjs');
      let passwordMatch = false;
      if (user.password) {
        if (user.password.startsWith('$2a$') || user.password.startsWith('$2b$')) {
          passwordMatch = await bcrypt.compare(password.trim(), user.password);
        } else {
          passwordMatch = user.password === password.trim();
        }
      }
      if (!passwordMatch) {
        return res.status(401).json({ error: 'Incorrect password. Please try again.' });
      }
      return res.json(user);
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  // 2. Google OAuth style login fallback / simple register
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required for login' });
  }

  try {
    let user = await dbQuery.get('SELECT * FROM users WHERE LOWER(email) = LOWER(?)', [email.trim()]);

    if (user) {
      return res.json(user);
    }

    // Register user automatically if not exists (for Google login style)
    const result = await dbQuery.run(
      'INSERT INTO users (name, email) VALUES (?, ?)',
      [name.trim(), email.trim().toLowerCase()]
    );
    const newUser = await dbQuery.get('SELECT * FROM users WHERE id = ?', [result.id]);
    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Explicit Sign Up endpoint
app.post('/api/auth/signup', async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  try {
    // Check if email already registered
    const existing = await dbQuery.get('SELECT * FROM users WHERE LOWER(email) = LOWER(?)', [email.trim()]);
    if (existing) {
      return res.status(400).json({ error: 'Email address is already registered' });
    }

    // Register new user
    const result = await dbQuery.run(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name.trim(), email.trim().toLowerCase(), password.trim()]
    );
    const newUser = await dbQuery.get('SELECT * FROM users WHERE id = ?', [result.id]);
    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rate limiting maps for OTP requests
const otpRequestLimits = new Map(); // phone -> Array of timestamps
const ipRequestLimits = new Map();    // IP -> Array of timestamps

function checkOtpRateLimit(phone) {
  const now = Date.now();
  const windowMs = 10 * 60 * 1000; // 10 minutes
  if (!otpRequestLimits.has(phone)) {
    otpRequestLimits.set(phone, [now]);
    return false;
  }
  const timestamps = otpRequestLimits.get(phone).filter(ts => now - ts < windowMs);
  if (timestamps.length >= 3) {
    return true;
  }
  timestamps.push(now);
  otpRequestLimits.set(phone, timestamps);
  return false;
}

function checkIpRateLimit(ip) {
  const now = Date.now();
  const windowMs = 10 * 60 * 1000; // 10 minutes
  if (!ipRequestLimits.has(ip)) {
    ipRequestLimits.set(ip, [now]);
    return false;
  }
  const timestamps = ipRequestLimits.get(ip).filter(ts => now - ts < windowMs);
  if (timestamps.length >= 5) { // Limit to 5 per 10 mins per IP
    return true;
  }
  timestamps.push(now);
  ipRequestLimits.set(ip, timestamps);
  return false;
}

// 1. Send OTP for forgot password
// 1. Send OTP for forgot password
app.post('/api/auth/forgot-password/send-otp', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email address is required' });
  }

  const cleanEmail = email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
    return res.status(400).json({ error: 'Invalid email address format' });
  }

  // Rate Limiting Checks
  const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  if (checkIpRateLimit(clientIp)) {
    return res.status(429).json({ error: 'Too many requests from this IP. Please try again in 10 minutes.' });
  }
  if (checkOtpRateLimit(cleanEmail)) {
    return res.status(429).json({ error: 'Too many OTP requests for this email address. Please try again in 10 minutes.' });
  }

  try {
    // Check if user exists
    const user = await dbQuery.get('SELECT * FROM users WHERE LOWER(email) = LOWER(?)', [cleanEmail]);

    if (!user) {
      // Diagnostic alert: explain that the input email is not linked to any account
      return res.status(404).json({ error: `No registered account found for: ${cleanEmail}` });
    }

    // Generate random 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash OTP using bcrypt before storing
    const salt = await bcrypt.genSalt(10);
    const otpHash = await bcrypt.hash(otp, salt);

    // Create OtpVerification record: expiresAt = now + 5 minutes
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();
    await dbQuery.run(
      'INSERT INTO otp_verifications (phone_number, otp_hash, purpose, expires_at) VALUES (?, ?, ?, ?)',
      [cleanEmail, otpHash, 'FORGOT_PASSWORD', expiresAt]
    );

    // Send OTP via Email SMTP
    const { sendOtpEmail } = require('./email');
    try {
      await sendOtpEmail(user.email, user.name, otp);
    } catch (emailErr) {
      console.error('[Forgot Password Email Error]:', emailErr);
      return res.status(500).json({ error: `SMTP Email failed: ${emailErr.message || emailErr}` });
    }

    res.json({ success: true, message: 'OTP sent successfully' });
  } catch (err) {
    console.error('[Forgot Password Send OTP] Error:', err);
    res.status(500).json({ error: `Internal server error: ${err.message}` });
  }
});

// 2. Verify OTP
app.post('/api/auth/forgot-password/verify-otp', async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'Email and OTP are required' });
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    // Fetch latest unverified OtpVerification
    const otpRecord = await dbQuery.get(
      'SELECT * FROM otp_verifications WHERE phone_number = ? AND purpose = ? AND (verified = FALSE OR verified = 0) ORDER BY created_at DESC LIMIT 1',
      [cleanEmail, 'FORGOT_PASSWORD']
    );

    if (!otpRecord) {
      return res.status(400).json({ error: 'No active OTP request found. Please request a new one.' });
    }

    // Check expiry
    if (new Date(otpRecord.expires_at) < new Date()) {
      return res.status(400).json({ error: 'OTP expired, request a new one' });
    }

    // Check attempts limit (max 5)
    if (otpRecord.attempts >= 5) {
      return res.status(400).json({ error: 'Maximum verification attempts exceeded. Please request a new OTP.' });
    }

    // Compare bcrypt hash
    const isMatch = await bcrypt.compare(otp.trim(), otpRecord.otp_hash);
    if (!isMatch) {
      // Increment attempts
      await dbQuery.run(
        'UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = ?',
        [otpRecord.id]
      );
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Mark verified = true
    await dbQuery.run(
      'UPDATE otp_verifications SET verified = ? WHERE id = ?',
      [usePostgres ? true : 1, otpRecord.id]
    );

    // Generate short-lived JWT resetToken (payload: email, purpose), expiresIn: 10m
    const resetToken = jwt.sign(
      { email: cleanEmail, purpose: 'RESET_PASSWORD' },
      process.env.JWT_SECRET || 'fallback_secret_key_eazzio',
      { expiresIn: '10m' }
    );

    res.json({ success: true, resetToken });
  } catch (err) {
    console.error('[Forgot Password Verify OTP] Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 3. Reset Password using token
app.post('/api/auth/forgot-password/reset', async (req, res) => {
  const { resetToken, newPassword } = req.body;
  if (!resetToken || !newPassword) {
    return res.status(400).json({ error: 'Reset token and new password are required' });
  }

  // Password strength check (min 8 chars)
  if (newPassword.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters long' });
  }

  try {
    // Verify JWT resetToken
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET || 'fallback_secret_key_eazzio');
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired reset token' });
    }

    if (decoded.purpose !== 'RESET_PASSWORD' || !decoded.email) {
      return res.status(400).json({ error: 'Invalid token purpose' });
    }

    const email = decoded.email;

    // Find user by email
    const user = await dbQuery.get('SELECT * FROM users WHERE LOWER(email) = LOWER(?)', [email]);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Hash newPassword with bcrypt
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword.trim(), salt);

    // Update user record
    await dbQuery.run(
      'UPDATE users SET password = ? WHERE id = ?',
      [hashedPassword, user.id]
    );

    // Delete/invalidate used OtpVerifications
    await dbQuery.run(
      'DELETE FROM otp_verifications WHERE phone_number = ?',
      [email]
    );

    res.json({ success: true, message: 'Password reset successful' });
  } catch (err) {
    console.error('[Forgot Password Reset] Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});



// Search users
app.get('/api/users/search', async (req, res) => {
  const { query } = req.query;
  if (!query) {
    return res.status(400).json({ error: 'Query parameter is required' });
  }

  try {
    const users = await dbQuery.all(
      'SELECT id, name, email, phone FROM users WHERE email LIKE ? OR phone LIKE ? OR name LIKE ? LIMIT 10',
      [`%${query}%`, `%${query}%`, `%${query}%`]
    );
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- TEAMS ENDPOINTS ---

// Send a team request
app.post('/api/teams/request', async (req, res) => {
  const { senderId, email } = req.body;
  if (!senderId || !email) {
    return res.status(400).json({ error: 'senderId and email are required' });
  }

  try {
    const receiver = await dbQuery.get('SELECT * FROM users WHERE email = ?', [email.trim().toLowerCase()]);
    if (!receiver) {
      return res.status(404).json({ error: 'No eazzio user found with this email/gmail' });
    }

    if (receiver.id === parseInt(senderId)) {
      return res.status(400).json({ error: 'You cannot send a request to yourself' });
    }

    // Check if already friends or request pending
    const existing = await dbQuery.get(
      `SELECT * FROM team_requests 
       WHERE (sender_id = ? AND receiver_id = ?) 
       OR (sender_id = ? AND receiver_id = ?)`,
      [senderId, receiver.id, receiver.id, senderId]
    );

    if (existing) {
      return res.status(400).json({ error: `Request already exists. Status: ${existing.status}` });
    }

    await dbQuery.run(
      'INSERT INTO team_requests (sender_id, receiver_id, status) VALUES (?, ?, ?)',
      [senderId, receiver.id, 'pending']
    );

    // Notify update via WebSockets
    io.emit('team_update');

    res.status(201).json({ message: 'Request sent successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get pending team requests
app.get('/api/teams/requests', async (req, res) => {
  const { userId } = req.query;
  if (!userId) {
    return res.status(400).json({ error: 'userId parameter is required' });
  }

  try {
    // Get incoming requests
    const incoming = await dbQuery.all(
      `SELECT tr.id, tr.status, u.id as sender_id, u.name, u.email, u.phone 
       FROM team_requests tr 
       JOIN users u ON tr.sender_id = u.id 
       WHERE tr.receiver_id = ? AND tr.status = 'pending'`,
      [userId]
    );

    // Get outgoing requests
    const outgoing = await dbQuery.all(
      `SELECT tr.id, tr.status, u.id as receiver_id, u.name, u.email, u.phone 
       FROM team_requests tr 
       JOIN users u ON tr.receiver_id = u.id 
       WHERE tr.sender_id = ? AND tr.status = 'pending'`,
      [userId]
    );

    res.json({ incoming, outgoing });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Respond to team request
app.post('/api/teams/requests/:id/respond', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body; // 'accepted' or 'rejected'
  if (!status || (status !== 'accepted' && status !== 'rejected')) {
    return res.status(400).json({ error: 'Invalid status. Must be accepted or rejected' });
  }

  try {
    const request = await dbQuery.get('SELECT * FROM team_requests WHERE id = ?', [id]);
    if (!request) {
      return res.status(404).json({ error: 'Request not found' });
    }

    await dbQuery.run('UPDATE team_requests SET status = ? WHERE id = ?', [status, id]);

    // Notify updates
    io.emit('team_update');

    res.json({ message: `Request successfully ${status}` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get team members
app.get('/api/teams/members', async (req, res) => {
  const { userId } = req.query;
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  try {
    const members = await dbQuery.all(
      `SELECT tr.id as request_id, 
              CASE WHEN tr.sender_id = ? THEN u2.id ELSE u1.id END as id,
              CASE WHEN tr.sender_id = ? THEN u2.name ELSE u1.name END as name,
              CASE WHEN tr.sender_id = ? THEN u2.email ELSE u1.email END as email,
              CASE WHEN tr.sender_id = ? THEN u2.phone ELSE u1.phone END as phone
       FROM team_requests tr
       JOIN users u1 ON tr.sender_id = u1.id
       JOIN users u2 ON tr.receiver_id = u2.id
       WHERE (tr.sender_id = ? OR tr.receiver_id = ?) AND tr.status = 'accepted'`,
      [userId, userId, userId, userId, userId, userId, userId, userId]
    );

    res.json(members);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 5. Get all reminders pending approval
app.get('/api/approvals', async (req, res) => {
  try {
    const approvals = await dbQuery.all("SELECT * FROM reminders WHERE status = 'pending_approval' ORDER BY remind_date ASC");
    res.json(approvals.map(formatReminder));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 6. Approve and log a reminder sent via device
app.post('/api/approvals/:id/approve', async (req, res) => {
  const { id } = req.params;
  const { status, details } = req.body;
  try {
    const reminder = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    if (!reminder) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    const finalStatus = status || 'sent';
    const logDetails = details || `Sent via device ${reminder.reminder_type.toUpperCase()}`;

    // Update reminder status
    await dbQuery.run("UPDATE reminders SET status = ? WHERE id = ?", [finalStatus, id]);
    
    // Log details
    await dbQuery.run(
      'INSERT INTO logs (reminder_id, recipient_name, recipient_phone, reminder_type, event_type, status, details) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, reminder.recipient_name, reminder.recipient_phone, reminder.reminder_type, reminder.event_type, finalStatus, logDetails]
    );

    io.emit('reminder_updated', { id: parseInt(id), status: finalStatus });
    io.emit('logs_updated');

    res.json({ message: `Reminder marked as ${finalStatus}`, success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 7. Reject/dismiss a reminder
app.post('/api/approvals/:id/reject', async (req, res) => {
  const { id } = req.params;
  try {
    const reminder = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    if (!reminder) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    // Update status to rejected
    await dbQuery.run("UPDATE reminders SET status = 'rejected' WHERE id = ?", [id]);
    
    // Log rejection
    await dbQuery.run(
      'INSERT INTO logs (reminder_id, recipient_name, recipient_phone, reminder_type, event_type, status, details) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, reminder.recipient_name, reminder.recipient_phone, reminder.reminder_type, reminder.event_type, 'rejected', 'Rejected by user approval workflow']
    );

    io.emit('reminder_updated', { id: parseInt(id), status: 'rejected' });
    io.emit('logs_updated');

    res.json({ message: 'Reminder rejected' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 8. Get communication logs (history)
app.get('/api/history', async (req, res) => {
  try {
    const logs = await dbQuery.all('SELECT * FROM logs ORDER BY sent_at DESC');
    res.json(logs.map(formatLog));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 9. Special Test Route: Run scheduler check immediately
app.post('/api/test-trigger-scheduler', async (req, res) => {
  try {
    console.log('[API] Triggering manual scheduler run...');
    await checkAndProcessReminders();
    res.json({ message: 'Scheduler check completed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10. Special Test Route: Test-Send a reminder immediately via device prompt
app.post('/api/reminders/:id/test-send', async (req, res) => {
  const { id } = req.params;
  try {
    const reminder = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [id]);
    if (!reminder) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    console.log(`[API] Triggering test-send (forcing pending_approval state) for ID ${id}...`);
    await dbQuery.run("UPDATE reminders SET status = 'pending_approval' WHERE id = ?", [id]);

    io.emit('reminder_updated', { id: parseInt(id), status: 'pending_approval' });
    io.emit('approval_needed', {
      id: reminder.id,
      recipient_name: reminder.recipient_name,
      recipient_phone: reminder.recipient_phone,
      event_type: reminder.event_type,
      reminder_type: reminder.reminder_type,
      message: reminder.message_template,
      send_option: 'auto' // Force direct pop-up on client
    });

    res.json({ message: 'Test send triggered: reminder moved to pending approval for device dispatch.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Initialize Port
const PORT = process.env.PORT || 3000;

// Start Server
server.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`Event Reminder Backend running on port ${PORT}`);
  console.log(`Endpoint: http://localhost:${PORT}`);
  console.log(`===================================================`);

  // Start the background cron scheduler
  initScheduler(io);
});
