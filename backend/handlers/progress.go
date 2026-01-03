package handlers

import (
	"encoding/json"
	"net/http"

	"resume-learning-backend/database"
	"resume-learning-backend/middleware"
	"resume-learning-backend/models"
)

func GetProgress(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == "" {
		http.Error(w, `{"error": "User not authenticated"}`, http.StatusUnauthorized)
		return
	}

	chapters, err := getChaptersWithProgress(userID)
	if err != nil {
		http.Error(w, `{"error": "Failed to fetch progress"}`, http.StatusInternalServerError)
		return
	}

	resumePoint, _ := getResumePoint(userID)

	response := models.ProgressResponse{
		Chapters:    chapters,
		ResumePoint: resumePoint,
	}

	json.NewEncoder(w).Encode(response)
}

func GetResumePoint(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == "" {
		http.Error(w, `{"error": "User not authenticated"}`, http.StatusUnauthorized)
		return
	}

	resumePoint, err := getResumePoint(userID)
	if err != nil {
		json.NewEncoder(w).Encode(map[string]interface{}{"resume_point": nil})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{"resume_point": resumePoint})
}

func SaveVideoProgress(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == "" {
		http.Error(w, `{"error": "User not authenticated"}`, http.StatusUnauthorized)
		return
	}

	var req models.VideoProgressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error": "Invalid request body"}`, http.StatusBadRequest)
		return
	}

	_, err := database.DB.Exec(`
		INSERT INTO user_progress (user_id, chapter_id, content_type, video_timestamp, completed, updated_at)
		VALUES (?, ?, 'video', ?, ?, CURRENT_TIMESTAMP)
		ON CONFLICT(user_id, chapter_id, content_type) 
		DO UPDATE SET video_timestamp = ?, completed = ?, updated_at = CURRENT_TIMESTAMP
	`, userID, req.ChapterID, req.Timestamp, req.Completed, req.Timestamp, req.Completed)

	if err != nil {
		http.Error(w, `{"error": "Failed to save progress"}`, http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Video progress saved",
	})
}

func SaveQuizProgress(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	if userID == "" {
		http.Error(w, `{"error": "User not authenticated"}`, http.StatusUnauthorized)
		return
	}

	var req models.QuizProgressRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error": "Invalid request body"}`, http.StatusBadRequest)
		return
	}

	answersJSON, _ := json.Marshal(req.Answers)

	_, err := database.DB.Exec(`
		INSERT INTO user_progress (user_id, chapter_id, content_type, quiz_question_index, quiz_answers, completed, updated_at)
		VALUES (?, ?, 'quiz', ?, ?, ?, CURRENT_TIMESTAMP)
		ON CONFLICT(user_id, chapter_id, content_type) 
		DO UPDATE SET quiz_question_index = ?, quiz_answers = ?, completed = ?, updated_at = CURRENT_TIMESTAMP
	`, userID, req.ChapterID, req.QuestionIndex, string(answersJSON), req.Completed,
		req.QuestionIndex, string(answersJSON), req.Completed)

	if err != nil {
		http.Error(w, `{"error": "Failed to save progress"}`, http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Quiz progress saved",
	})
}

func getChaptersWithProgress(userID string) ([]models.ChapterWithProgress, error) {
	rows, err := database.DB.Query(`
		SELECT 
			c.id, c.title, c.description, c.video_url, c.order_index,
			COALESCE(vp.video_timestamp, 0) as video_timestamp,
			COALESCE(vp.completed, 0) as video_completed,
			COALESCE(qp.quiz_question_index, 0) as quiz_index,
			COALESCE(qp.completed, 0) as quiz_completed
		FROM chapters c
		LEFT JOIN user_progress vp ON c.id = vp.chapter_id AND vp.user_id = ? AND vp.content_type = 'video'
		LEFT JOIN user_progress qp ON c.id = qp.chapter_id AND qp.user_id = ? AND qp.content_type = 'quiz'
		ORDER BY c.order_index
	`, userID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chapters []models.ChapterWithProgress
	for rows.Next() {
		var ch models.ChapterWithProgress
		var videoTimestamp float64
		var videoCompleted, quizCompleted bool
		var quizIndex int

		err := rows.Scan(
			&ch.ID, &ch.Title, &ch.Description, &ch.VideoURL, &ch.OrderIndex,
			&videoTimestamp, &videoCompleted, &quizIndex, &quizCompleted,
		)
		if err != nil {
			continue
		}

		ch.VideoProgress = videoTimestamp
		ch.VideoCompleted = videoCompleted
		ch.QuizProgress = float64(quizIndex) / 5.0 * 100
		ch.QuizCompleted = quizCompleted

		chapters = append(chapters, ch)
	}

	if chapters == nil {
		chapters = []models.ChapterWithProgress{}
	}

	return chapters, nil
}

func getResumePoint(userID string) (*models.ResumePoint, error) {
	var resumePoint models.ResumePoint
	var videoTimestamp float64
	var quizIndex int

	err := database.DB.QueryRow(`
		SELECT 
			up.chapter_id, c.title, up.content_type, 
			COALESCE(up.video_timestamp, 0), COALESCE(up.quiz_question_index, 0)
		FROM user_progress up
		JOIN chapters c ON up.chapter_id = c.id
		WHERE up.user_id = ? AND up.completed = 0
		ORDER BY up.updated_at DESC
		LIMIT 1
	`, userID).Scan(&resumePoint.ChapterID, &resumePoint.ChapterTitle, &resumePoint.ContentType, &videoTimestamp, &quizIndex)

	if err != nil {
		return getNextChapterToStart(userID)
	}

	resumePoint.VideoTimestamp = videoTimestamp
	resumePoint.QuizQuestionIndex = quizIndex

	if resumePoint.ContentType == "quiz" {
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM quiz_questions WHERE chapter_id = ?",
			resumePoint.ChapterID,
		).Scan(&resumePoint.TotalQuestions)
	}

	return &resumePoint, nil
}

func getNextChapterToStart(userID string) (*models.ResumePoint, error) {
	var resumePoint models.ResumePoint

	err := database.DB.QueryRow(`
		SELECT c.id, c.title
		FROM chapters c
		LEFT JOIN user_progress vp ON c.id = vp.chapter_id AND vp.user_id = ? AND vp.content_type = 'video'
		LEFT JOIN user_progress qp ON c.id = qp.chapter_id AND qp.user_id = ? AND qp.content_type = 'quiz'
		WHERE vp.completed = 1 AND qp.id IS NULL
		ORDER BY c.order_index
		LIMIT 1
	`, userID, userID).Scan(&resumePoint.ChapterID, &resumePoint.ChapterTitle)

	if err == nil {
		resumePoint.ContentType = "quiz"
		resumePoint.QuizQuestionIndex = 0
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM quiz_questions WHERE chapter_id = ?",
			resumePoint.ChapterID,
		).Scan(&resumePoint.TotalQuestions)
		return &resumePoint, nil
	}

	err = database.DB.QueryRow(`
		SELECT c.id, c.title
		FROM chapters c
		LEFT JOIN user_progress up ON c.id = up.chapter_id AND up.user_id = ?
		WHERE up.id IS NULL
		ORDER BY c.order_index
		LIMIT 1
	`, userID).Scan(&resumePoint.ChapterID, &resumePoint.ChapterTitle)

	if err != nil {
		return nil, err
	}

	resumePoint.ContentType = "video"
	resumePoint.VideoTimestamp = 0

	return &resumePoint, nil
}
