# Resume Learning App

A full-stack learning application with **Netflix-style "Resume where you left off"** functionality. Built with Flutter (frontend) and Go (backend).

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite)

## Features

- ✅ **Resume Video Playback** - Videos resume from exact timestamp
- ✅ **Resume Quiz Progress** - Quizzes resume from last answered question
- ✅ **Continue Learning Card** - Quick access to resume point from home
- ✅ **Progress Tracking** - Per-chapter video and quiz completion
- ✅ **Simple Auth** - User ID-based login (no password required)
- ✅ **Clean UI** - White and blue color scheme

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter 3.x |
| Backend | Go 1.21+ |
| Database | SQLite |
| State Management | Provider |
| Video Player | video_player package |

## Project Structure

```
├── backend/                 # Go REST API
│   ├── main.go             # Entry point
│   ├── handlers/           # API handlers
│   ├── models/             # Data models
│   ├── database/           # SQLite setup & seeding
│   └── middleware/         # Auth & CORS
│
├── frontend/               # Flutter app
│   └── lib/
│       ├── main.dart       # App entry
│       ├── config/         # Theme
│       ├── models/         # Data models
│       ├── services/       # API service
│       ├── providers/      # State management
│       └── screens/        # UI screens
│
└── README.md
```

## How to Run

### Prerequisites

- [Go 1.21+](https://go.dev/dl/)
- [Flutter 3.x](https://flutter.dev/docs/get-started/install)
- GCC (for SQLite compilation on Windows: [TDM-GCC](https://jmeubank.github.io/tdm-gcc/))

### Backend

```bash
cd backend

# Download dependencies
go mod tidy

# Run the server
go run main.go
```

The server starts at `http://localhost:8080`

### Frontend

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on connected device
flutter run
```

**Note:** If running on mobile/emulator, update the API base URL in `lib/services/api_service.dart` to your machine's IP address.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with userId |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/chapters` | Get all chapters |
| GET | `/api/chapters/:id` | Get chapter with quiz |
| GET | `/api/progress` | Get user's progress |
| GET | `/api/progress/resume` | Get resume point |
| POST | `/api/progress/video` | Save video progress |
| POST | `/api/progress/quiz` | Save quiz progress |

## Resume Accuracy

### Video Resume
- Timestamp saved every 5 seconds during playback
- Timestamp saved on pause and exit
- On resume, video seeks to exact saved timestamp

### Quiz Resume
- Progress saved after each answer
- On resume, quiz starts at last unanswered question
- User's previous answers are preserved

## Approach

1. **Backend-first**: Designed RESTful API with clear endpoints for progress tracking
2. **UPSERT pattern**: Uses SQLite's `ON CONFLICT` for atomic progress updates
3. **Provider pattern**: Clean state management in Flutter
4. **Auto-save**: Video progress saves every 5s; quiz saves on each answer
5. **Resume point calculation**: Backend determines optimal resume point

## Edge Cases Handled

| Scenario | Handling |
|----------|----------|
| New user, no progress | Shows chapter list, no "Continue" card |
| User switches accounts | Clears local state, fetches new user's data |
| Video partially watched | Resumes at exact timestamp |
| Quiz half completed | Resumes at exact question index |
| All content completed | Shows completed badges, allows replay |
| Network failure | Graceful error handling with retry |
| App killed mid-save | Saves progress on every interaction |

## Assumptions & Tradeoffs

### Assumptions
- Single device usage (no cross-device sync)
- Video URLs are publicly accessible
- Simple userId-based auth is sufficient
- SQLite is adequate for demo scale

### Tradeoffs
- **No password auth**: Simpler but less secure (acceptable for demo)
- **Local SQLite**: Easy setup, no cloud sync needed
- **Hardcoded content**: 3 chapters with sample videos/quizzes
- **5-second save interval**: Balance between accuracy and API calls

## Sample Content

The app comes pre-seeded with 3 chapters:
1. Introduction to Flutter
2. State Management
3. Building Beautiful UIs

Each chapter has a sample video and 5 quiz questions.