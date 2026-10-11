// Additive migrations for both a fresh schema import and existing installations.
async function migrate(db) {
  const columns = [
    ['otp_verifications', 'verification_hash', 'CHAR(64) NULL'],
    ['bookings', 'reference', 'VARCHAR(40) NULL'],
    ['bookings', 'pricing_version', "VARCHAR(30) NOT NULL DEFAULT '2026-10-v1'"],
  ];
  for (const [table, column, definition] of columns) {
    const [rows] = await db.query('SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?', [table, column]);
    if (!rows.length) await db.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${definition}`);
  }
  await db.query(`CREATE TABLE IF NOT EXISTS auth_sessions (
    token_hash CHAR(64) PRIMARY KEY, user_id INT NOT NULL, expires_at DATETIME(3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB`);
  await db.query(`CREATE TABLE IF NOT EXISTS password_resets (
    email VARCHAR(255) PRIMARY KEY, code_hash CHAR(64) NOT NULL, expires_at DATETIME(3) NOT NULL,
    failed_attempts INT NOT NULL DEFAULT 0, created_at DATETIME(3) NOT NULL
  ) ENGINE=InnoDB`);
  await db.query(`CREATE TABLE IF NOT EXISTS tickets (
    id INT PRIMARY KEY AUTO_INCREMENT, reference VARCHAR(40) NOT NULL UNIQUE, user_id INT NOT NULL,
    booking_id INT NULL, category VARCHAR(30) NOT NULL, subject VARCHAR(150) NOT NULL,
    description TEXT NOT NULL, status ENUM('open','in_progress','resolved','closed') NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX(user_id, updated_at), FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY(booking_id) REFERENCES bookings(id) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await db.query(`CREATE TABLE IF NOT EXISTS ticket_messages (
    id INT PRIMARY KEY AUTO_INCREMENT, ticket_id INT NOT NULL, user_id INT NOT NULL,
    message TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await db.query(`CREATE TABLE IF NOT EXISTS chat_messages (
    id INT PRIMARY KEY AUTO_INCREMENT, user_id INT NOT NULL, role ENUM('user','assistant') NOT NULL,
    message TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX(user_id, id),
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await require('./trip-migrations')(db);
  await db.query('DELETE FROM auth_sessions WHERE expires_at <= UTC_TIMESTAMP(3)');
  await db.query("UPDATE bookings SET reference=CONCAT('FR-',UPPER(UUID())) WHERE reference IS NULL");
}
module.exports = migrate;
