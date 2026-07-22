const { Pool } = require('pg');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const usePostgres = !!process.env.DATABASE_URL;

let pgPool = null;
let sqliteDb = null;

if (usePostgres) {
  console.log('Connecting to PostgreSQL/NeonDB database...');
  pgPool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL.includes('neon.tech') 
      ? { rejectUnauthorized: false } 
      : (process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false)
  });
  
  pgPool.query('SELECT NOW()')
    .then(() => {
      console.log('Connected to PostgreSQL/NeonDB successfully.');
      initializePostgresTables();
    })
    .catch((err) => {
      console.error('Error connecting to PostgreSQL/NeonDB:', err.message);
    });
} else {
  const dbFile = path.resolve(__dirname, '..', process.env.DB_FILE || 'database.db');
  console.log('Using SQLite fallback database...');
  const dbDir = path.dirname(dbFile);
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  sqliteDb = new sqlite3.Database(dbFile, (err) => {
    if (err) {
      console.error('Error opening SQLite database:', err.message);
    } else {
      console.log('Connected to SQLite database at:', dbFile);
      initializeSqliteTables();
    }
  });
}

async function initializePostgresTables() {
  try {
    // 1. Users table
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        password TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgPool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token TEXT;
    `);

    await pgPool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP WITH TIME ZONE;
    `);

    // 2. Team Requests table
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS team_requests (
        id SERIAL PRIMARY KEY,
        sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 3. Reminders table
    await pgPool.query(`
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

    // 4. Logs table
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS logs (
        id SERIAL PRIMARY KEY,
        reminder_id INTEGER REFERENCES reminders(id) ON DELETE SET NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        event_type TEXT NOT NULL,
        status TEXT NOT NULL,
        details TEXT,
        sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgPool.query(`
      ALTER TABLE logs ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
    `);

    // 5. OTP Verification table
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS otp_verifications (
        id SERIAL PRIMARY KEY,
        phone_number TEXT NOT NULL,
        otp_hash TEXT NOT NULL,
        purpose TEXT DEFAULT 'FORGOT_PASSWORD',
        attempts INTEGER DEFAULT 0,
        verified BOOLEAN DEFAULT FALSE,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pgPool.query(`
      CREATE INDEX IF NOT EXISTS idx_otp_phone_purpose ON otp_verifications (phone_number, purpose);
    `);

    console.log('PostgreSQL database tables initialized successfully.');
  } catch (err) {
    console.error('Error initializing PostgreSQL tables:', err.message);
  }
}

function initializeSqliteTables() {
  sqliteDb.serialize(() => {
    // 1. Users table
    sqliteDb.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        password TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    sqliteDb.run("ALTER TABLE users ADD COLUMN password TEXT", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding password:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE users ADD COLUMN reset_token TEXT", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding reset_token:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE users ADD COLUMN reset_token_expires DATETIME", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding reset_token_expires:', err.message);
      }
    });

    // 2. Team Requests table
    sqliteDb.run(`
      CREATE TABLE IF NOT EXISTS team_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER,
        receiver_id INTEGER,
        status TEXT NOT NULL, -- 'pending', 'accepted', 'rejected'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(sender_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(receiver_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // 3. Reminders table
    sqliteDb.run(`
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        event_type TEXT NOT NULL, -- 'birthday', 'anniversary', 'fee', 'custom', 'task'
        remind_date TEXT NOT NULL, -- 'YYYY-MM-DD'
        remind_time TEXT NOT NULL, -- 'HH:MM'
        message_template TEXT NOT NULL,
        reminder_type TEXT NOT NULL, -- 'call', 'sms', 'notification', 'whatsapp'
        audio_url TEXT,
        send_option TEXT NOT NULL, -- 'auto', 'approval'
        status TEXT NOT NULL, -- 'scheduled', 'pending_approval', 'sent', 'failed', 'rejected', 'paused'
        notification_sound TEXT DEFAULT 'default',
        user_id INTEGER,
        assigned_to INTEGER,
        assigned_by INTEGER,
        repeat_option TEXT DEFAULT 'none',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    sqliteDb.run("ALTER TABLE reminders ADD COLUMN notification_sound TEXT DEFAULT 'default'", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding notification_sound:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE reminders ADD COLUMN user_id INTEGER", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding user_id:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE reminders ADD COLUMN assigned_to INTEGER", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding assigned_to:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE reminders ADD COLUMN assigned_by INTEGER", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding assigned_by:', err.message);
      }
    });

    sqliteDb.run("ALTER TABLE reminders ADD COLUMN repeat_option TEXT DEFAULT 'none'", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding repeat_option:', err.message);
      }
    });

    // 4. Logs table
    sqliteDb.run(`
      CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminder_id INTEGER,
        user_id INTEGER,
        recipient_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        reminder_type TEXT NOT NULL, -- 'call', 'sms'
        event_type TEXT NOT NULL,
        status TEXT NOT NULL, -- 'sent', 'failed', 'rejected'
        details TEXT,
        sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(reminder_id) REFERENCES reminders(id) ON DELETE SET NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
      )
    `);

    sqliteDb.run("ALTER TABLE logs ADD COLUMN user_id INTEGER", (err) => {
      if (err && !err.message.includes('duplicate column name')) {
        console.error('Migration error adding user_id to logs:', err.message);
      }
    });

    // 5. OTP Verification table
    sqliteDb.run(`
      CREATE TABLE IF NOT EXISTS otp_verifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        otp_hash TEXT NOT NULL,
        purpose TEXT DEFAULT 'FORGOT_PASSWORD',
        attempts INTEGER DEFAULT 0,
        verified INTEGER DEFAULT 0, -- 0 for false, 1 for true
        expires_at DATETIME NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    sqliteDb.run(`
      CREATE INDEX IF NOT EXISTS idx_otp_phone_purpose ON otp_verifications (phone_number, purpose)
    `);

    console.log('SQLite database tables initialized successfully with migrations.');
  });
}

function convertSqliteToPg(sql) {
  let index = 1;
  // Replace SQLite "?" placeholders with PostgreSQL positional parameters "$1", "$2", etc.
  let pgSql = sql.replace(/\?/g, () => `$${index++}`);
  // Replace SQLite "LIKE" (case-insensitive by default) with PostgreSQL "ILIKE"
  pgSql = pgSql.replace(/\bLIKE\b/gi, 'ILIKE');
  return pgSql;
}

function preparePgQuery(sql) {
  let pgSql = convertSqliteToPg(sql);
  
  // If it's an INSERT statement, append "RETURNING id" to capture the auto-generated serial ID.
  const trimmed = sql.trim().toUpperCase();
  if (trimmed.startsWith('INSERT INTO') && !trimmed.includes('RETURNING')) {
    pgSql += ' RETURNING id';
  }
  return pgSql;
}

const dbQuery = {
  async all(sql, params = []) {
    if (usePostgres) {
      const pgSql = convertSqliteToPg(sql);
      const res = await pgPool.query(pgSql, params);
      return res.rows;
    } else {
      return new Promise((resolve, reject) => {
        sqliteDb.all(sql, params, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      });
    }
  },

  async get(sql, params = []) {
    if (usePostgres) {
      const pgSql = convertSqliteToPg(sql);
      const res = await pgPool.query(pgSql, params);
      return res.rows[0] || null;
    } else {
      return new Promise((resolve, reject) => {
        sqliteDb.get(sql, params, (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });
    }
  },

  async run(sql, params = []) {
    if (usePostgres) {
      const pgSql = preparePgQuery(sql);
      const res = await pgPool.query(pgSql, params);
      const id = res.rows && res.rows[0] && res.rows[0].id !== undefined 
        ? res.rows[0].id 
        : null;
      return { 
        id, 
        changes: res.rowCount 
      };
    } else {
      return new Promise((resolve, reject) => {
        sqliteDb.run(sql, params, function (err) {
          if (err) reject(err);
          else resolve({ id: this.lastID, changes: this.changes });
        });
      });
    }
  }
};

module.exports = {
  db: usePostgres ? pgPool : sqliteDb,
  dbQuery,
  usePostgres
};
