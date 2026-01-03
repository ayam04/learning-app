package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/rs/cors"

	"resume-learning-backend/database"
	"resume-learning-backend/handlers"
	"resume-learning-backend/middleware"
)

func main() {
	if err := database.InitDB("./learning.db"); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer database.CloseDB()

	if err := database.SeedData(); err != nil {
		log.Println("Warning: Failed to seed data:", err)
	}

	r := mux.NewRouter()
	api := r.PathPrefix("/api").Subrouter()

	api.HandleFunc("/auth/login", handlers.Login).Methods("POST")
	api.HandleFunc("/auth/logout", handlers.Logout).Methods("POST")

	protected := api.PathPrefix("").Subrouter()
	protected.Use(middleware.AuthMiddleware)
	protected.Use(middleware.JSONMiddleware)

	protected.HandleFunc("/chapters", handlers.GetChapters).Methods("GET")
	protected.HandleFunc("/chapters/{id}", handlers.GetChapterDetail).Methods("GET")

	protected.HandleFunc("/progress", handlers.GetProgress).Methods("GET")
	protected.HandleFunc("/progress/resume", handlers.GetResumePoint).Methods("GET")
	protected.HandleFunc("/progress/video", handlers.SaveVideoProgress).Methods("POST")
	protected.HandleFunc("/progress/quiz", handlers.SaveQuizProgress).Methods("POST")

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	handler := c.Handler(r)

	port := ":8080"
	log.Printf("Server starting on http://localhost%s", port)

	if err := http.ListenAndServe(port, handler); err != nil {
		log.Fatal("Server failed:", err)
	}
}
