const sqlite3 = require('sqlite3').verbose();
const { Client } = require('pg');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const dbFile = path.resolve(__dirname, '..', process.env.DB_FILE || 'database.db');
const pgConnectionString = process.env.DATABASE_URL;

if (!pgConnectionString) {
  console.error('Error: DATABASE_URL environment variable is not defined in .env');
  console.error('Please configure DATABASE_URL in backend/.env before running this script.');
  process.exit(1);
}

if (!fs.existsSync(dbFile)) {
  console.error(`Error: SQLite database file not found at ${dbFile}`);
  console.error('Ensure that your SQLite database file exists in the backend directory.');
  process.exit(1);
}

console.log('Starting database migration...');
console.log(`Source SQLite database: ${dbFile}`);
console.log(`Target PostgreSQL URL: ${pgConnectionString.replace(/:[^:@]+@/, ':****@')}`); // Hide password for security

const sqliteDb = new sqlite3.Database(dbFile);
const pgClient = new Client({
  connectionString: pgConnectionString,
  ssl: pgConnectionString.includes('neon.tech') 
    ? { rejectUnauthorized: false } 
    : (process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false)
});

function parseSqliteDate(sqliteDateStr) {
  if (!sqliteDateStr) return new Date();
  let dateStr = sqliteDateStr.trim();
  // If SQLite stored it as standard YYYY-MM-DD HH:MM:SS (which is UTC by default in SQLite CURRENT_TIMESTAMP)
  // we append UTC so JavaScript interprets it correctly as UTC.
  if (/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$/.test(dateStr)) {
    dateStr = dateStr + ' UTC';
  }
  const d = new Date(dateStr);
  return isNaN(d.getTime()) ? new Date() : d;
}

async function runMigration() {
  try {
    await pgClient.connect();
    console.log('Connected to PostgreSQL successfully.');

    // 1. Recreate tables if they don't exist
    console.log('Creating PostgreSQL tables (if not exists)...');
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        password TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS team_requests (
        id SERIAL PRIMARY KEY,
        sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS reminders (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        event_type TEXT NOT NULL,
        remind_date TEXT NOT NULL,
        remind_time TEXT NOT NULL,
        message_template TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        audio_url TEXT,
        send_option TEXT NOT NULL,
        status TEXT NOT NULL,
        notification_sound TEXT DEFAULT 'default',
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
        assigned_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        repeat_option TEXT DEFAULT 'none',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS logs (
        id SERIAL PRIMARY KEY,
        reminder_id INTEGER REFERENCES reminders(id) ON DELETE SET NULL,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        event_type TEXT NOT NULL,
        status TEXT NOT NULL,
        details TEXT,
        sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Helper to fetch all rows from SQLite
    const sqliteAll = (sql, params = []) => {
      return new Promise((resolve, reject) => {
        sqliteDb.all(sql, params, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      });
    };

    // 2. Migrate users
    console.log('Migrating "users" table...');
    const users = await sqliteAll('SELECT * FROM users');
    console.log(`Found ${users.length} users to migrate.`);
    for (const u of users) {
      await pgClient.query(
        `INSERT INTO users (id, name, email, phone, password, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET
           name = EXCLUDED.name,
           email = EXCLUDED.email,
           phone = EXCLUDED.phone,
           password = EXCLUDED.password,
           created_at = EXCLUDED.created_at`,
        [u.id, u.name, u.email, u.phone, u.password, parseSqliteDate(u.created_at)]
      );
    }
    if (users.length > 0) {
      await pgClient.query(`SELECT setval(pg_get_serial_sequence('users', 'id'), coalesce(max(id), 1), max(id) IS NOT NULL) FROM users`);
    }
    console.log('"users" table migration complete.');

    // 3. Migrate team_requests
    console.log('Migrating "team_requests" table...');
    const teamRequests = await sqliteAll('SELECT * FROM team_requests');
    console.log(`Found ${teamRequests.length} team requests to migrate.`);
    for (const r of teamRequests) {
      await pgClient.query(
        `INSERT INTO team_requests (id, sender_id, receiver_id, status, created_at)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO UPDATE SET
           sender_id = EXCLUDED.sender_id,
           receiver_id = EXCLUDED.receiver_id,
           status = EXCLUDED.status,
           created_at = EXCLUDED.created_at`,
        [r.id, r.sender_id, r.receiver_id, r.status, parseSqliteDate(r.created_at)]
      );
    }
    if (teamRequests.length > 0) {
      await pgClient.query(`SELECT setval(pg_get_serial_sequence('team_requests', 'id'), coalesce(max(id), 1), max(id) IS NOT NULL) FROM team_requests`);
    }
    console.log('"team_requests" table migration complete.');

    // 4. Migrate reminders
    console.log('Migrating "reminders" table...');
    const reminders = await sqliteAll('SELECT * FROM reminders');
    console.log(`Found ${reminders.length} reminders to migrate.`);
    for (const rem of reminders) {
      await pgClient.query(
        `INSERT INTO reminders (
          id, title, recipient_name, recipient_phone, event_type, remind_date, remind_time,
          message_template, reminder_type, audio_url, send_option, status, notification_sound,
          user_id, assigned_to, assigned_by, repeat_option, created_at
         )
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           recipient_name = EXCLUDED.recipient_name,
           recipient_phone = EXCLUDED.recipient_phone,
           event_type = EXCLUDED.event_type,
           remind_date = EXCLUDED.remind_date,
           remind_time = EXCLUDED.remind_time,
           message_template = EXCLUDED.message_template,
           reminder_type = EXCLUDED.reminder_type,
           audio_url = EXCLUDED.audio_url,
           send_option = EXCLUDED.send_option,
           status = EXCLUDED.status,
           notification_sound = EXCLUDED.notification_sound,
           user_id = EXCLUDED.user_id,
           assigned_to = EXCLUDED.assigned_to,
           assigned_by = EXCLUDED.assigned_by,
           repeat_option = EXCLUDED.repeat_option,
           created_at = EXCLUDED.created_at`,
        [
          rem.id, rem.title, rem.recipient_name, rem.recipient_phone, rem.event_type, rem.remind_date, rem.remind_time,
          rem.message_template, rem.reminder_type, rem.audio_url, rem.send_option, rem.status, rem.notification_sound,
          rem.user_id, rem.assigned_to, rem.assigned_by, rem.repeat_option, parseSqliteDate(rem.created_at)
        ]
      );
    }
    if (reminders.length > 0) {
      await pgClient.query(`SELECT setval(pg_get_serial_sequence('reminders', 'id'), coalesce(max(id), 1), max(id) IS NOT NULL) FROM reminders`);
    }
    console.log('"reminders" table migration complete.');

    // 5. Migrate logs
    console.log('Migrating "logs" table...');
    const logs = await sqliteAll('SELECT * FROM logs');
    console.log(`Found ${logs.length} logs to migrate.`);
    for (const log of logs) {
      await pgClient.query(
        `INSERT INTO logs (id, reminder_id, recipient_name, recipient_phone, reminder_type, event_type, status, details, sent_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (id) DO UPDATE SET
           reminder_id = EXCLUDED.reminder_id,
           recipient_name = EXCLUDED.recipient_name,
           recipient_phone = EXCLUDED.recipient_phone,
           reminder_type = EXCLUDED.reminder_type,
           event_type = EXCLUDED.event_type,
           status = EXCLUDED.status,
           details = EXCLUDED.details,
           sent_at = EXCLUDED.sent_at`,
        [log.id, log.reminder_id, log.recipient_name, log.recipient_phone, log.reminder_type, log.event_type, log.status, log.details, parseSqliteDate(log.sent_at)]
      );
    }
    if (logs.length > 0) {
      await pgClient.query(`SELECT setval(pg_get_serial_sequence('logs', 'id'), coalesce(max(id), 1), max(id) IS NOT NULL) FROM logs`);
    }
    console.log('"logs" table migration complete.');

    console.log('\x1b[32m%s\x1b[0m', 'Database migration completed successfully!');
  } catch (err) {
    console.error('\x1b[31m%s\x1b[0m', 'Migration failed with error:', err);
  } finally {
    sqliteDb.close();
    await pgClient.end();
    console.log('Database connections closed.');
  }
}

runMigration();
