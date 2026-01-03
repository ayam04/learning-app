package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"resume-learning-backend/database"
	"resume-learning-backend/models"

	"github.com/gorilla/mux"
)

func GetChapters(w http.ResponseWriter, r *http.Request) {
	rows, err := database.DB.Query(
		"SELECT id, title, description, video_url, order_index FROM chapters ORDER BY order_index",
	)
	if err != nil {
		http.Error(w, `{"error": "Failed to fetch chapters"}`, http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var chapters []models.Chapter
	for rows.Next() {
		var ch models.Chapter
		if err := rows.Scan(&ch.ID, &ch.Title, &ch.Description, &ch.VideoURL, &ch.OrderIndex); err != nil {
			continue
		}
		chapters = append(chapters, ch)
	}

	if chapters == nil {
		chapters = []models.Chapter{}
	}

	json.NewEncoder(w).Encode(chapters)
}

func GetChapterDetail(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chapterID, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, `{"error": "Invalid chapter ID"}`, http.StatusBadRequest)
		return
	}

	var chapter models.Chapter
	err = database.DB.QueryRow(
		"SELECT id, title, description, video_url, order_index FROM chapters WHERE id = ?",
		chapterID,
	).Scan(&chapter.ID, &chapter.Title, &chapter.Description, &chapter.VideoURL, &chapter.OrderIndex)
	if err != nil {
		http.Error(w, `{"error": "Chapter not found"}`, http.StatusNotFound)
		return
	}

	rows, err := database.DB.Query(
		"SELECT id, chapter_id, question_text, options, correct_option, order_index FROM quiz_questions WHERE chapter_id = ? ORDER BY order_index",
		chapterID,
	)
	if err != nil {
		http.Error(w, `{"error": "Failed to fetch questions"}`, http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var questions []models.QuizQuestion
	for rows.Next() {
		var q models.QuizQuestion
		var optionsJSON string
		if err := rows.Scan(&q.ID, &q.ChapterID, &q.QuestionText, &optionsJSON, &q.CorrectOption, &q.OrderIndex); err != nil {
			continue
		}
		json.Unmarshal([]byte(optionsJSON), &q.Options)
		questions = append(questions, q)
	}

	if questions == nil {
		questions = []models.QuizQuestion{}
	}

	response := models.ChapterDetailResponse{
		Chapter:   chapter,
		Questions: questions,
	}

	json.NewEncoder(w).Encode(response)
}
