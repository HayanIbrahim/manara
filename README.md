# Manara — Educational Platform Suite

A modern, production-grade educational platform built with Flutter and Dart, connecting to a live backend at `https://manara-ifnk.onrender.com`.

This monorepo contains both frontend applications:
1. **`manara`**: Student & Tutor Mobile & Desktop Application
2. **`manara_admin`**: Executive Portal for Platform Governance & Curriculum Management

---

## Repository Structure

```
manara/
├── manara/                  # Student & Tutor Flutter Client App
│   ├── lib/
│   │   ├── core/            # Networking (Dio, ApiClient, SessionProvider), Theme, L10n
│   │   ├── data/            # Models, Data Sources (Local & Remote), Repositories
│   │   ├── domain/          # Entities, Contracts
│   │   └── presentation/    # BLoCs, Screens (Auth, Learning, Quizzes, Exams, Tutor, QR Pairing)
│   └── test/                # Unit & BLoC tests
│
├── manara_admin/            # Administrator Desktop & Web Dashboard
│   ├── lib/
│   │   ├── core/            # ApiClient, Constants, Theme, L10n
│   │   ├── data/            # Admin Data Sources & Repositories
│   │   ├── domain/          # Admin Entities & Contracts
│   │   └── presentation/    # Screens (Users, Subjects, Codes, Announcements, Permissions)
│   └── test/                # Unit tests
│
├── api_documentation.md     # Complete Backend API specification
├── FRONTEND_API_GUIDE.md    # Frontend integration guide & recipes
├── openapi.yaml             # OpenAPI 3.1.0 contract
└── README.md                # This file
```

---

## Applications

### 1. `manara` (Student & Tutor App)
- **Role-Based Workflows**: Student dashboard, catalog browsing, sequential lecture learning, mandatory 100% lecture quizzes, and tutor course management.
- **Hardware Binding & Desktop Pairing**: Strict mobile session device binding (`x-device-id`), with QR-based 180s challenge-response pairing for desktop access.
- **Resilient Offline & Rate Limiting**: Built-in 429 backoff handling, Retry-After parsing, and 503 registration retry support.

### 2. `manara_admin` (Executive Portal)
- **User Account Governance**: Real-time account status toggling (`ACTIVE` / `DEACTIVATED`) and remote hardware device reset (`POST /admin/users/:id/device-reset`).
- **Curriculum & Subject Management**: Subject CRUD adhering strictly to OpenAPI schemas.
- **Signup Code Generator**: Single-use role-specific (`STUDENT` / `TUTOR`) registration codes.
- **Academic Permissions**: Tutor subject syllabus authority and student course overrides.
- **Broadcast Announcements**: Role-targeted and course-targeted broadcast notifications.

---

## Live Backend Configuration

- **Target Base URL:** `https://manara-ifnk.onrender.com/api/v1/`
- **Root URL (Health & Socket.IO):** `https://manara-ifnk.onrender.com`
- **Health Check Endpoint:** `GET https://manara-ifnk.onrender.com/health`

---

## Running the Apps

### Prerequisites
- Flutter 3.29+ / Dart 3.8+
- Windows / macOS / Linux desktop enablement or Android/iOS SDK

### Run `manara`
```bash
cd manara
flutter pub get
flutter run -d windows    # Or -d chrome, android, macos
```

### Run `manara_admin`
```bash
cd manara_admin
flutter pub get
flutter run -d windows    # Or -d chrome
```

---

## Running Automated Tests
```bash
# Student & Tutor tests
cd manara && flutter test

# Admin tests
cd manara_admin && flutter test
```
