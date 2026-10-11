// Additive schema. Financial values are integer BDT paisa, never floating point.
module.exports = async function migrateTrips(db) {
  await db.query(`CREATE TABLE IF NOT EXISTS trip_requests (
    id INT PRIMARY KEY AUTO_INCREMENT, reference VARCHAR(40) NOT NULL UNIQUE,
    user_id INT NOT NULL, request_key VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    payload_hash CHAR(64) NOT NULL, service VARCHAR(20) NOT NULL, provider VARCHAR(20) NOT NULL,
    origin VARCHAR(150) NOT NULL, destination VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL, end_date DATE NOT NULL, adults INT NOT NULL, children INT NOT NULL,
    budget_paisa INT UNSIGNED NULL, contact_name VARCHAR(100) NOT NULL, contact_phone VARCHAR(30) NOT NULL,
    requirements TEXT NOT NULL, status VARCHAR(30) NOT NULL DEFAULT 'requested', version INT NOT NULL DEFAULT 1,
    current_quote_id INT NULL, supplier_reference VARCHAR(100) NULL, confirmation_details TEXT NULL,
    created_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3),
    updated_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    UNIQUE(user_id, request_key), INDEX(user_id, id), INDEX(status, id),
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await db.query(`CREATE TABLE IF NOT EXISTS trip_quotes (
    id INT PRIMARY KEY AUTO_INCREMENT, trip_id INT NOT NULL, operator_id INT NULL,
    line_items JSON NOT NULL, total_paisa INT UNSIGNED NOT NULL, itinerary TEXT NOT NULL,
    cancellation_policy TEXT NOT NULL, expires_at DATETIME(3) NOT NULL,
    accepted_at DATETIME(3) NULL, created_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3), INDEX(trip_id, id),
    FOREIGN KEY(trip_id) REFERENCES trip_requests(id) ON DELETE CASCADE,
    FOREIGN KEY(operator_id) REFERENCES users(id) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await db.query(`CREATE TABLE IF NOT EXISTS trip_events (
    id INT PRIMARY KEY AUTO_INCREMENT, trip_id INT NOT NULL, actor_id INT NULL,
    actor_role VARCHAR(20) NOT NULL, event VARCHAR(40) NOT NULL, message TEXT NOT NULL,
    created_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3), INDEX(trip_id, id),
    FOREIGN KEY(trip_id) REFERENCES trip_requests(id) ON DELETE CASCADE,
    FOREIGN KEY(actor_id) REFERENCES users(id) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
};
