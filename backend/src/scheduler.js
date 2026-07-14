const cron = require('node-cron');
const { dbQuery } = require('./db');

let ioInstance = null;

/**
 * Initializes the background scheduler.
 * @param {Object} io - Socket.io server instance.
 */
function initScheduler(io) {
  ioInstance = io;

  // Run scheduler check every minute
  // Pattern: * * * * * (every minute, on the minute)
  cron.schedule('* * * * *', async () => {
    console.log('[Scheduler] Running minute-check for reminders...');
    try {
      await checkAndProcessReminders();
    } catch (err) {
      console.error('[Scheduler] Error running check:', err.message);
    }
  });

  console.log('Background reminder scheduler started (runs every minute).');
}

function calculateNextDate(currentDateStr, repeatOption) {
  const parts = currentDateStr.split('-');
  const date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
  
  switch (repeatOption) {
    case 'daily':
      date.setDate(date.getDate() + 1);
      break;
    case 'weekly':
      date.setDate(date.getDate() + 7);
      break;
    case 'monthly':
      date.setMonth(date.getMonth() + 1);
      break;
    case 'yearly':
      date.setFullYear(date.getFullYear() + 1);
      break;
  }
  
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

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

/**
 * Main routine to query database for reminders that are due.
 */
async function checkAndProcessReminders() {
  const tz = process.env.APP_TIMEZONE || 'Asia/Kolkata';
  let currentDateStr, currentTimeStr;

  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: tz,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    });
    
    const parts = formatter.formatToParts(new Date());
    const partMap = {};
    for (const part of parts) {
      partMap[part.type] = part.value;
    }
    
    currentDateStr = `${partMap.year}-${partMap.month}-${partMap.day}`;
    let hourVal = partMap.hour;
    if (hourVal === '24') {
      hourVal = '00';
    }
    currentTimeStr = `${hourVal}:${partMap.minute}`;
  } catch (err) {
    console.error(`[Scheduler] Invalid/unsupported timezone ${tz}, falling back to local system timezone:`, err.message);
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    currentDateStr = `${year}-${month}-${day}`;
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    currentTimeStr = `${hours}:${minutes}`;
  }

  console.log(`[Scheduler] Checking date: ${currentDateStr}, time <= ${currentTimeStr} (Timezone: ${tz})`);

  // Query reminders that:
  // 1. Are scheduled
  // 2. Have remind_date <= today
  // 3. Have remind_time <= now (if remind_date is today)
  const query = `
    SELECT * FROM reminders 
    WHERE status = 'scheduled'
    AND (
      remind_date < ? 
      OR (remind_date = ? AND remind_time <= ?)
    )
  `;

  const pendingReminders = await dbQuery.all(query, [currentDateStr, currentDateStr, currentTimeStr]);

  if (pendingReminders.length === 0) {
    return;
  }

  console.log(`[Scheduler] Found ${pendingReminders.length} reminders due for processing.`);

  for (const reminder of pendingReminders) {
    if (reminder.repeat_option && reminder.repeat_option !== 'none') {
      // Calculate next remind date
      const nextDate = calculateNextDate(reminder.remind_date, reminder.repeat_option);
      
      // Update original reminder to next occurrence date (keeping it scheduled)
      await dbQuery.run('UPDATE reminders SET remind_date = ? WHERE id = ?', [nextDate, reminder.id]);
      console.log(`[Scheduler] Repeating reminder ID ${reminder.id} rescheduled to ${nextDate}.`);

      // Create a copy representing the current due run
      const copyResult = await dbQuery.run(
        `INSERT INTO reminders (title, recipient_name, recipient_phone, event_type, remind_date, remind_time, message_template, reminder_type, audio_url, send_option, status, notification_sound, user_id, assigned_to, assigned_by, repeat_option)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'none')`,
        [reminder.title, reminder.recipient_name, reminder.recipient_phone, reminder.event_type, reminder.remind_date, reminder.remind_time, reminder.message_template, reminder.reminder_type, reminder.audio_url, reminder.send_option, 'pending_approval', reminder.notification_sound || 'default', reminder.user_id, reminder.assigned_to, reminder.assigned_by]
      );
      
      const currentOccurrenceId = copyResult.id;
      console.log(`[Scheduler] Created occurrence copy ID ${currentOccurrenceId} for due repeating reminder ID ${reminder.id}.`);

      if (ioInstance) {
        const updatedOriginal = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [reminder.id]);
        ioInstance.emit('reminder_updated', formatReminder(updatedOriginal));
        
        const newOccurrence = await dbQuery.get('SELECT * FROM reminders WHERE id = ?', [currentOccurrenceId]);
        ioInstance.emit('reminder_created', formatReminder(newOccurrence));
        ioInstance.emit('approval_needed', {
          id: currentOccurrenceId,
          recipient_name: reminder.recipient_name,
          recipient_phone: reminder.recipient_phone,
          event_type: reminder.event_type,
          reminder_type: reminder.reminder_type,
          message: reminder.message_template,
          send_option: reminder.send_option
        });
      }
    } else {
      // Non-repeating: standard update flow
      await dbQuery.run('UPDATE reminders SET status = ? WHERE id = ?', ['pending_approval', reminder.id]);
      console.log(`[Scheduler] Reminder ID ${reminder.id} marked as pending_approval.`);
      
      // Notify clients to refresh lists and trigger device prompts
      if (ioInstance) {
        ioInstance.emit('reminder_updated', { id: reminder.id, status: 'pending_approval' });
        ioInstance.emit('approval_needed', {
          id: reminder.id,
          recipient_name: reminder.recipient_name,
          recipient_phone: reminder.recipient_phone,
          event_type: reminder.event_type,
          reminder_type: reminder.reminder_type,
          message: reminder.message_template,
          send_option: reminder.send_option
        });
      }
    }
  }
}

module.exports = {
  initScheduler,
  checkAndProcessReminders // Exposed for manual triggering via HTTP/WebSockets
};
