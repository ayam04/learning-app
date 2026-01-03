package database

import (
	"log"
)

func SeedData() error {
	var count int
	err := DB.QueryRow("SELECT COUNT(*) FROM chapters").Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		log.Println("Database already seeded")
		return nil
	}

	log.Println("Seeding database with sample data...")

	chapters := []struct {
		title       string
		description string
		videoURL    string
		orderIndex  int
	}{
		{
			title:       "Introduction to Flutter",
			description: "Learn the basics of Flutter framework and Dart programming language. Set up your development environment and create your first app.",
			videoURL:    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
			orderIndex:  1,
		},
		{
			title:       "State Management",
			description: "Master state management in Flutter using Provider. Understand the difference between stateful and stateless widgets.",
			videoURL:    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
			orderIndex:  2,
		},
		{
			title:       "Building Beautiful UIs",
			description: "Create stunning user interfaces with Flutter widgets. Learn about layouts, styling, and responsive design.",
			videoURL:    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
			orderIndex:  3,
		},
	}

	for _, ch := range chapters {
		_, err := DB.Exec(
			"INSERT INTO chapters (title, description, video_url, order_index) VALUES (?, ?, ?, ?)",
			ch.title, ch.description, ch.videoURL, ch.orderIndex,
		)
		if err != nil {
			return err
		}
	}

	quizData := map[int][]struct {
		question      string
		options       string
		correctOption int
	}{
		1: {
			{"What programming language does Flutter use?", `["JavaScript", "Dart", "Python", "Swift"]`, 1},
			{"What is a Widget in Flutter?", `["A database connection", "A UI component", "A network request", "A testing tool"]`, 1},
			{"Which command creates a new Flutter project?", `["flutter new", "flutter create", "flutter init", "flutter start"]`, 1},
			{"What is hot reload in Flutter?", `["Restarting the app", "Instantly viewing code changes", "Clearing cache", "Building for production"]`, 1},
			{"Flutter apps compile to what?", `["JavaScript only", "Native ARM code", "HTML/CSS", "Java bytecode"]`, 1},
		},
		2: {
			{"What is state in Flutter?", `["App configuration", "Data that can change over time", "Static content", "User credentials"]`, 1},
			{"What method rebuilds a StatefulWidget?", `["rebuild()", "refresh()", "setState()", "update()"]`, 2},
			{"What is Provider in Flutter?", `["A database", "A state management solution", "A UI library", "A testing framework"]`, 1},
			{"When should you use StatelessWidget?", `["When UI changes frequently", "When UI never changes", "For forms", "For animations"]`, 1},
			{"What does ChangeNotifier do?", `["Sends notifications", "Notifies listeners of state changes", "Changes app theme", "Manages routes"]`, 1},
		},
		3: {
			{"Which widget arranges children vertically?", `["Row", "Column", "Stack", "Grid"]`, 1},
			{"What does Expanded widget do?", `["Makes child invisible", "Fills available space", "Adds padding", "Creates animation"]`, 1},
			{"How do you add rounded corners to a Container?", `["Using Padding", "Using BorderRadius", "Using Margin", "Using Alignment"]`, 1},
			{"What is the purpose of Scaffold widget?", `["Database operations", "Provides basic app layout structure", "Network requests", "State management"]`, 1},
			{"Which property sets a Container's background color?", `["backgroundColor", "fillColor", "color or decoration", "paint"]`, 2},
		},
	}

	for chapterID, questions := range quizData {
		for i, q := range questions {
			_, err := DB.Exec(
				"INSERT INTO quiz_questions (chapter_id, question_text, options, correct_option, order_index) VALUES (?, ?, ?, ?, ?)",
				chapterID, q.question, q.options, q.correctOption, i,
			)
			if err != nil {
				return err
			}
		}
	}

	log.Println("Database seeded successfully")
	return nil
}
