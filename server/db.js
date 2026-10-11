const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'torisom_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 100,
  connectTimeout: 10000,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: true,
    ...(process.env.DB_SSL_CA_FILE ? { ca: require('fs').readFileSync(process.env.DB_SSL_CA_FILE, 'utf8') } : {}),
  } : undefined,
  timezone: 'Z',
  dateStrings: ['DATE']
});

module.exports = pool;
