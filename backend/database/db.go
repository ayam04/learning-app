package database

import (
	"database/sql"
	"log"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dbPath string) error {
	var err error
	DB, err = sql.Open("sqlite", dbPath)
	if err != nil {
		return err
	}

	if err = DB.Ping(); err != nil {
		return err
	}

	if err = createTables(); err != nil {
		return err
	}

	log.Println("Database initialized successfully")
	return nil
}

func createTables() error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS chapters (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title TEXT NOT NULL,
		description TEXT,
		video_url TEXT NOT NULL,
		order_index INTEGER NOT NULL
	);

	CREATE TABLE IF NOT EXISTS quiz_questions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		chapter_id INTEGER NOT NULL,
		question_text TEXT NOT NULL,
		options TEXT NOT NULL,
		correct_option INTEGER NOT NULL,
		order_index INTEGER NOT NULL,
		FOREIGN KEY (chapter_id) REFERENCES chapters(id)
	);

	CREATE TABLE IF NOT EXISTS user_progress (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id TEXT NOT NULL,
		chapter_id INTEGER NOT NULL,
		content_type TEXT NOT NULL,
		video_timestamp REAL DEFAULT 0,
		quiz_question_index INTEGER DEFAULT 0,
		quiz_answers TEXT DEFAULT '[]',
		completed BOOLEAN DEFAULT FALSE,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (user_id) REFERENCES users(id),
		FOREIGN KEY (chapter_id) REFERENCES chapters(id),
		UNIQUE(user_id, chapter_id, content_type)
	);
	`

	_, err := DB.Exec(schema)
	return err
}

func CloseDB() {
	if DB != nil {
		DB.Close()
	}
}
