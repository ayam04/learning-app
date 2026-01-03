package models

import "time"

type User struct {
	ID        string    `json:"id"`
	CreatedAt time.Time `json:"created_at"`
}

type Chapter struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	VideoURL    string `json:"video_url"`
	OrderIndex  int    `json:"order_index"`
}

type ChapterWithProgress struct {
	Chapter
	VideoProgress  float64 `json:"video_progress"`
	QuizProgress   float64 `json:"quiz_progress"`
	VideoCompleted bool    `json:"video_completed"`
	QuizCompleted  bool    `json:"quiz_completed"`
}

type QuizQuestion struct {
	ID            int      `json:"id"`
	ChapterID     int      `json:"chapter_id"`
	QuestionText  string   `json:"question_text"`
	Options       []string `json:"options"`
	CorrectOption int      `json:"correct_option"`
	OrderIndex    int      `json:"order_index"`
}

type UserProgress struct {
	ID                int       `json:"id"`
	UserID            string    `json:"user_id"`
	ChapterID         int       `json:"chapter_id"`
	ContentType       string    `json:"content_type"`
	VideoTimestamp    float64   `json:"video_timestamp"`
	QuizQuestionIndex int       `json:"quiz_question_index"`
	QuizAnswers       []int     `json:"quiz_answers"`
	Completed         bool      `json:"completed"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type ResumePoint struct {
	ChapterID         int     `json:"chapter_id"`
	ChapterTitle      string  `json:"chapter_title"`
	ContentType       string  `json:"content_type"`
	VideoTimestamp    float64 `json:"video_timestamp,omitempty"`
	QuizQuestionIndex int     `json:"quiz_question_index,omitempty"`
	TotalQuestions    int     `json:"total_questions,omitempty"`
}

type LoginRequest struct {
	UserID string `json:"user_id"`
}

type LoginResponse struct {
	Success bool   `json:"success"`
	UserID  string `json:"user_id"`
	Message string `json:"message"`
}

type VideoProgressRequest struct {
	ChapterID int     `json:"chapter_id"`
	Timestamp float64 `json:"timestamp"`
	Duration  float64 `json:"duration"`
	Completed bool    `json:"completed"`
}

type QuizProgressRequest struct {
	ChapterID     int   `json:"chapter_id"`
	QuestionIndex int   `json:"question_index"`
	Answers       []int `json:"answers"`
	Completed     bool  `json:"completed"`
}

type ChapterDetailResponse struct {
	Chapter   Chapter        `json:"chapter"`
	Questions []QuizQuestion `json:"questions"`
}

type ProgressResponse struct {
	Chapters    []ChapterWithProgress `json:"chapters"`
	ResumePoint *ResumePoint          `json:"resume_point,omitempty"`
}
