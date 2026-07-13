const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { dbQuery } = require('./db');
const { initScheduler, checkAndProcessReminders } = require('./scheduler');
const { sendPasswordResetEmail } = require('./email');
require('dotenv').config();

function formatReminder(reminder) {
  if (!reminder) return reminder;
  if (reminder.created_at && !reminder.created_at.endsWith('Z')) {
    return {
      ...reminder,
      created_at: `${reminder.created_at.replace(' ', 'T')}Z`
    };
  }
  return reminder;
}

function formatLog(log) {
  if (!log) return log;
  if (log.sent_at && !log.sent_at.endsWith('Z')) {
    return {
      ...log,
      sent_at: `${log.sent_at.replace(' ', 'T')}Z`
    };
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
  const { identifier, password, name, email, phone } = req.body;
  
  // 1. Password credentials sign-in
  if (identifier && password) {
    try {
      const user = await dbQuery.get(
        'SELECT * FROM users WHERE email = ? OR phone = ?',
        [identifier.trim().toLowerCase(), identifier.trim()]
      );
      if (!user) {
        return res.status(404).json({ error: 'No user found with this email or phone number.' });
      }
      if (user.password && user.password !== password.trim()) {
        return res.status(401).json({ error: 'Incorrect password. Please try again.' });
      }
      return res.json(user);
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  // 2. Google OAuth style login fallback / simple register
  if (!name || (!email && !phone)) {
    return res.status(400).json({ error: 'Name and email or phone are required for login' });
  }

  try {
    let user;
    if (email) {
      user = await dbQuery.get('SELECT * FROM users WHERE email = ?', [email.trim().toLowerCase()]);
    } else {
      user = await dbQuery.get('SELECT * FROM users WHERE phone = ?', [phone.trim()]);
    }

    if (user) {
      return res.json(user);
    }

    // Register user automatically if not exists (for Google login style)
    const result = await dbQuery.run(
      'INSERT INTO users (name, email, phone) VALUES (?, ?, ?)',
      [name.trim(), email ? email.trim().toLowerCase() : null, phone ? phone.trim() : null]
    );
    const newUser = await dbQuery.get('SELECT * FROM users WHERE id = ?', [result.id]);
    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Explicit Sign Up endpoint
app.post('/api/auth/signup', async (req, res) => {
  const { name, phone, password } = req.body;
  if (!name || !phone || !password) {
    return res.status(400).json({ error: 'Name, phone number, and password are required' });
  }

  try {
    // Check if phone number already registered
    const existing = await dbQuery.get('SELECT * FROM users WHERE phone = ?', [phone.trim()]);
    if (existing) {
      return res.status(400).json({ error: 'Phone number is already registered' });
    }

    // Register new user
    const result = await dbQuery.run(
      'INSERT INTO users (name, phone, password) VALUES (?, ?, ?)',
      [name.trim(), phone.trim(), password.trim()]
    );
    const newUser = await dbQuery.get('SELECT * FROM users WHERE id = ?', [result.id]);
    res.status(201).json(newUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Reset Password endpoint
app.post('/api/auth/reset-password', async (req, res) => {
  const { identifier, name, newPassword } = req.body;
  if (!identifier || !name || !newPassword) {
    return res.status(400).json({ error: 'Identifier, name, and new password are required' });
  }

  try {
    // Look up user by email or phone, and matching name (case-insensitive)
    const user = await dbQuery.get(
      'SELECT * FROM users WHERE (email = ? OR phone = ?) AND LOWER(name) = LOWER(?)',
      [identifier.trim(), identifier.trim(), name.trim()]
    );

    if (!user) {
      return res.status(404).json({ error: 'User account details do not match' });
    }

    // Update password
    await dbQuery.run(
      'UPDATE users SET password = ? WHERE id = ?',
      [newPassword.trim(), user.id]
    );

    // Send confirmation email via Brevo SMTP
    let targetEmail = user.email;
    if (!targetEmail && identifier.trim().toLowerCase().includes('@')) {
      targetEmail = identifier.trim().toLowerCase();
    }

    if (targetEmail) {
      try {
        await sendPasswordResetEmail(targetEmail, user.name, newPassword.trim());
      } catch (emailErr) {
        console.error(`[SMTP] Failed to send password reset email to ${targetEmail}:`, emailErr);
      }
    }

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
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
