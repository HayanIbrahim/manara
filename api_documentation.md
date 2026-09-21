# Educational Platform API — Complete Technical Specification

**Version:** `1.0.0`  
**Protocol:** HTTP/1.1 & HTTPS (JSON over TLS) | WebSocket / Socket.IO v4  
**Default Base URL:** `http://localhost:3000/api/v1`  
**Root Base URL:** `http://localhost:3000` (for `/health`)  
**OpenAPI Specification:** [`openapi.yaml`](./openapi.yaml)  
**Frontend integration guide:** [`FRONTEND_API_GUIDE.md`](./FRONTEND_API_GUIDE.md)

The JSON examples below illustrate the relevant fields for each operation. Database
records can contain additional model fields; use the OpenAPI schemas for the
machine-readable contract.

---

## Table of Contents

1. [Architectural Overview & Security Model](#1-architectural-overview--security-model)
   - [Base URLs & Transports](#base-urls--transports)
   - [Authentication & Token Types](#authentication--token-types)
   - [Hardware Device Binding (`x-device-id`)](#hardware-device-binding-x-device-id)
   - [Temporary Desktop QR Authentication Lifecycle](#temporary-desktop-qr-authentication-lifecycle)
   - [Standard Request & Response Headers](#standard-request--response-headers)
   - [Uniform Error Schema & Status Code Dictionary](#uniform-error-schema--status-code-dictionary)
2. [Complete Endpoint Index](#2-complete-endpoint-index)
3. [System & Health](#3-system--health)
   - `GET /health`
4. [Authentication API](#4-authentication-api)
   - `POST /auth/admin/login`
   - `POST /auth/register`
   - `POST /auth/login`
   - `GET /auth/me`
5. [Temporary Desktop QR Authentication](#5-temporary-desktop-qr-authentication)
   - `POST /desktop/challenges`
   - `GET /desktop/challenges/:challenge/status`
   - `POST /desktop/challenges/:challenge/authorize`
   - `POST /desktop/challenges/:challenge/exchange`
   - `DELETE /desktop/sessions/current`
   - [Socket.IO Real-Time Protocol Specification](#socketio-real-time-protocol-specification)
6. [Public Catalog & Discovery](#6-public-catalog--discovery)
   - `GET /subjects`
   - `GET /courses`
   - `GET /courses/:id`
   - `GET /tutors/:id`
   - `GET /leaderboard`
7. [Admin Management API](#7-admin-management-api)
   - `GET /admin/subjects`
   - `POST /admin/subjects`
   - `PATCH /admin/subjects/:id`
   - `DELETE /admin/subjects/:id`
   - `GET /admin/signup-codes`
   - `POST /admin/signup-codes`
   - `GET /admin/users`
   - `PATCH /admin/users/:id/status`
   - `POST /admin/users/:id/device-reset`
   - `PUT /admin/tutors/:id/subjects/:subjectId`
   - `DELETE /admin/tutors/:id/subjects/:subjectId`
   - `PUT /admin/students/:id/courses/:courseId`
   - `DELETE /admin/students/:id/courses/:courseId`
   - `GET /admin/announcements`
   - `POST /admin/announcements`
8. [Tutor Portal API](#8-tutor-portal-api)
   - `GET /tutor/courses`
   - `POST /tutor/courses`
   - `PATCH /tutor/courses/:id`
   - `POST /tutor/courses/:id/lectures`
   - `PATCH /tutor/lectures/:id`
   - `DELETE /tutor/lectures/:id`
   - `PUT /tutor/lectures/:id/quiz`
   - `POST /tutor/courses/:id/exams`
   - `PATCH /tutor/exams/:id`
   - `GET /tutor/exams/:id/submissions`
   - `PATCH /tutor/submissions/:id/grade`
9. [Student Learning API](#9-student-learning-api)
   - `GET /student/courses`
   - `GET /student/courses/:id/learning`
   - `POST /student/lectures/:id/quiz-attempts`
   - `POST /student/exams/:id/submissions`
   - `GET /student/exam-results`
   - `PUT /student/ratings/course/:id`
   - `PUT /student/ratings/tutor/:id`
   - `GET /student/announcements`
   - `GET /student/achievements`
10. [End-to-End Business Workflows](#10-end-to-end-business-workflows)
    - [Workflow 1: Tutor Onboarding & Subject Assignment](#workflow-1-tutor-onboarding--subject-assignment)
    - [Workflow 2: Course Publishing with Mandatory Lecture Quizzes](#workflow-2-course-publishing-with-mandatory-lecture-quizzes)
    - [Workflow 3: Student Enrollment, Sequential Learning & Points](#workflow-3-student-enrollment-sequential-learning--points)
    - [Workflow 4: Temporary Desktop Session QR Handshake](#workflow-4-temporary-desktop-session-qr-handshake)
    - [Workflow 5: Lost Device Recovery Procedure](#workflow-5-lost-device-recovery-procedure)

---

## 1. Architectural Overview & Security Model

### Base URLs & Transports
- **Server Root:** `http://localhost:3000` (used solely for the `/health` endpoint).
- **API v1 Base URL:** `http://localhost:3000/api/v1` (all application routes).
- **Transport Security:** Deploy behind HTTPS/WSS in production. The deployment controls the TLS version; this Express app does not terminate TLS itself.
- **Data Serialization:** Application responses are JSON (`application/json`), except the current rate-limit response described below. DateTime timestamps are ISO-8601 UTC strings (e.g. `2026-09-14T12:00:00.000Z`). Database identifiers are 24-character hexadecimal MongoDB ObjectIDs.

### Authentication & Token Types
All protected routes require an HTTP `Authorization` header containing a JSON Web Token (JWT) in the `Bearer <token>` format.

The platform issues three mutually exclusive session types:
1. **Admin Token (`sessionType: 'admin'`):**
   - Issued by `POST /auth/admin/login`.
   - Bypasses hardware device ID verification.
   - Valid for 15 minutes by default (configured by `JWT_ACCESS_TTL`).
2. **Mobile Token (`sessionType: 'mobile'`):**
   - Issued by `POST /auth/register` and `POST /auth/login`.
   - Bound to the device ID registered during account creation.
   - Requires the matching `x-device-id` header on every subsequent HTTP call.
3. **Desktop Token (`sessionType: 'desktop'`):**
   - Issued by `POST /desktop/challenges/:challenge/exchange`.
   - Does **not** require the `x-device-id` header.
   - Valid for 8 hours by default (`JWT_DESKTOP_TTL`), subject to the server-side session expiry (`DESKTOP_SESSION_TTL_SECONDS`). Calling `DELETE /desktop/sessions/current` revokes the session immediately. Closing a window without calling that endpoint does not revoke it.

### Hardware Device Binding (`x-device-id`)
To prevent unauthorized account sharing across multiple mobile devices:
- During registration (`POST /auth/register`), the mobile client provides a unique hardware/installation identifier in the body (`device_id`).
- On every protected request by a student or tutor using a mobile token, the client must supply that identical string in the `x-device-id` request header.
- If `x-device-id` is omitted, the API responds with `400 DEVICE_ID_REQUIRED`.
- If `x-device-id` does not match the bound account ID, the API responds with `403 DEVICE_MISMATCH`.
- Only an administrator calling `POST /admin/users/:id/device-reset` can unlink a bound device.

### Temporary Desktop QR Authentication Lifecycle
The platform permits temporary login on desktop/laptop environments without permanently transferring device binding credentials:
1. **Challenge Creation:** The desktop client calls `POST /desktop/challenges` to generate a secure random 32-byte opaque token. Its default TTL is 180 seconds (`QR_CHALLENGE_TTL_SECONDS`).
2. **Display QR:** The desktop app renders the raw token as a QR code and emits `desktop:subscribe` with `{ challenge: '<raw token>' }`. The server joins the corresponding hashed challenge room.
3. **Mobile Scan & Authorize:** The student or tutor scans the QR code with their mobile device (which holds an active mobile token) and calls `POST /desktop/challenges/:challenge/authorize`. This revokes any previous active desktop session for that user and marks the challenge as `APPROVED`.
4. **Token Exchange:** The desktop app receives the `desktop:status` event (or polls `GET /desktop/challenges/:challenge/status`) and invokes `POST /desktop/challenges/:challenge/exchange` to receive a `sessionType: 'desktop'` JWT.
5. **Clean Teardown:** The desktop client should invoke `DELETE /desktop/sessions/current` on logout or window teardown. Closing the window alone does not revoke the session.

### Standard Request & Response Headers

| Header | Applicability | Format / Value | Description |
|---|---|---|---|
| `Content-Type` | All requests with bodies | `application/json` | Required for `POST`, `PUT`, and `PATCH` requests. |
| `Authorization` | All protected endpoints | `Bearer <jwt>` | Signed JSON Web Token. |
| `x-device-id` | Student/Tutor Mobile requests | String (16–256 chars) | Unique client device UUID or keychain identifier. |

### Uniform Error Schema & Status Code Dictionary

Application errors generally use this JSON error envelope. The rate-limit
middleware currently returns a plain string (`text/html`) for `429` responses; inspect the HTTP
status and `Content-Type` before parsing the body.

```json
{
  "error": {
    "code": "ERROR_CODE_STRING",
    "message": "Human-readable explanation",
    "details": {
      "fieldErrors": {
        "email": ["Invalid email address"]
      }
    }
  }
}
```

#### Common HTTP Status Codes & Error Codes

| HTTP Status | Error Code | Meaning / Resolution |
|---|---|---|
| `400 Bad Request` | `DEVICE_ID_REQUIRED` | Missing `x-device-id` header or body parameter. |
| `400 Bad Request` | `INVALID_SIGNUP_CODE` | Provided signup code hash was not found or is expired. |
| `400 Bad Request` | `CANNOT_DEACTIVATE_SELF` | Administrator attempted to deactivate their own account. |
| `401 Unauthorized` | `AUTH_REQUIRED` | No Bearer token provided in `Authorization` header. |
| `401 Unauthorized` | `INVALID_TOKEN` | Token is malformed, expired, or failed signature verification. |
| `401 Unauthorized` | `SESSION_REVOKED` | User status is not active, or `tokenVersion` was incremented. |
| `401 Unauthorized` | `DESKTOP_SESSION_CLOSED` | The desktop session expired, closed, or was consumed elsewhere. |
| `401 Unauthorized` | `INVALID_CREDENTIALS` | Incorrect username, password, or login role mismatch. |
| `403 Forbidden` | `ROLE_FORBIDDEN` | Authenticated user lacks required role (`ADMIN`, `TUTOR`, or `STUDENT`). |
| `403 Forbidden` | `DEVICE_MISMATCH` | Mobile token used on an unauthorized device ID. |
| `403 Forbidden` | `ACCOUNT_DEACTIVATED` | User account has been deactivated by an admin. |
| `403 Forbidden` | `SUBJECT_NOT_ASSIGNED` | Tutor is not officially assigned to this subject by an admin. |
| `403 Forbidden` | `COURSE_ACCESS_REQUIRED` | Student has not been granted access to this course. |
| `403 Forbidden` | `LECTURE_LOCKED` | Must pass the quiz of the preceding lecture with 100% to unlock. |
| `403 Forbidden` | `TUTOR_RATING_FORBIDDEN` | Student must be enrolled in at least one course by this tutor to rate. |
| `404 Not Found` | `COURSE_NOT_FOUND` | Requested course does not exist or is not owned by user. |
| `404 Not Found` | `LECTURE_NOT_FOUND` | Requested lecture does not exist or is not owned by user. |
| `404 Not Found` | `EXAM_NOT_FOUND` | Requested exam does not exist or is not owned by user. |
| `404 Not Found` | `CHALLENGE_NOT_FOUND` | Temporary desktop challenge hash was not found. |
| `409 Conflict` | `SUBJECT_IN_USE` | Cannot delete a subject while courses reference it. |
| `409 Conflict` | `SIGNUP_CODE_ALREADY_USED` | Signup code has already been consumed by another user. |
| `409 Conflict` | `QUIZ_REQUIRED_BEFORE_PUBLISH` | Lecture cannot be published without an attached 5+ question quiz. |
| `409 Conflict` | `CHALLENGE_NOT_PENDING` | QR challenge has expired or is already processed. |
| `409 Conflict` | `CHALLENGE_NOT_APPROVED` | Attempted to exchange an unapproved QR challenge. |
| `409 Conflict` | `CHALLENGE_ALREADY_EXCHANGED` | Desktop challenge has already been exchanged for a token. |
| `422 Unprocessable` | `VALIDATION_ERROR` | Request payload failed Zod schema validation rules. |
| `429 Too Many Requests` | Plain text response | Exceeded an auth or desktop challenge rate limit. Respect `Retry-After` when present. |

---

## 2. Complete Endpoint Index

| Group | Method | Endpoint | Access Level | Description |
|---|---|---|---|---|
| **System** | `GET` | `/health` | Public | System liveness probe |
| **Auth** | `POST` | `/api/v1/auth/admin/login` | Public | Admin login |
| **Auth** | `POST` | `/api/v1/auth/register` | Public | Register student/tutor with single-use code |
| **Auth** | `POST` | `/api/v1/auth/login` | Public | Student/Tutor mobile login with device check |
| **Auth** | `GET` | `/api/v1/auth/me` | Authenticated | Inspect current user and session type |
| **Desktop** | `POST` | `/api/v1/desktop/challenges` | Public | Generate desktop QR challenge |
| **Desktop** | `GET` | `/api/v1/desktop/challenges/:challenge/status` | Public | Poll QR challenge status |
| **Desktop** | `POST` | `/api/v1/desktop/challenges/:challenge/authorize` | Tutor / Student | Mobile app approves QR challenge |
| **Desktop** | `POST` | `/api/v1/desktop/challenges/:challenge/exchange` | Public | Exchange approved QR for desktop JWT |
| **Desktop** | `DELETE`| `/api/v1/desktop/sessions/current` | Desktop Token | Close current desktop session |
| **Catalog** | `GET` | `/api/v1/subjects` | Public | List all active subjects |
| **Catalog** | `GET` | `/api/v1/courses` | Public | Search and filter published courses |
| **Catalog** | `GET` | `/api/v1/courses/:id` | Public | Get published course details & syllabus |
| **Catalog** | `GET` | `/api/v1/tutors/:id` | Public | Get tutor public profile and ratings |
| **Catalog** | `GET` | `/api/v1/leaderboard` | Public | Top 100 students ranked by points |
| **Admin** | `GET` | `/api/v1/admin/subjects` | Admin | List all subjects |
| **Admin** | `POST` | `/api/v1/admin/subjects` | Admin | Create subject |
| **Admin** | `PATCH` | `/api/v1/admin/subjects/:id` | Admin | Update subject |
| **Admin** | `DELETE`| `/api/v1/admin/subjects/:id` | Admin | Delete subject |
| **Admin** | `GET` | `/api/v1/admin/signup-codes` | Admin | List generated signup codes |
| **Admin** | `POST` | `/api/v1/admin/signup-codes` | Admin | Generate role-specific single-use signup code |
| **Admin** | `GET` | `/api/v1/admin/users` | Admin | Search and filter user accounts |
| **Admin** | `PATCH` | `/api/v1/admin/users/:id/status` | Admin | Activate or deactivate account |
| **Admin** | `POST` | `/api/v1/admin/users/:id/device-reset` | Admin | Clear bound mobile device ID |
| **Admin** | `PUT` | `/api/v1/admin/tutors/:id/subjects/:subjectId` | Admin | Assign subject to tutor |
| **Admin** | `DELETE`| `/api/v1/admin/tutors/:id/subjects/:subjectId` | Admin | Remove subject assignment from tutor |
| **Admin** | `PUT` | `/api/v1/admin/students/:id/courses/:courseId` | Admin | Manually grant course access to student |
| **Admin** | `DELETE`| `/api/v1/admin/students/:id/courses/:courseId` | Admin | Revoke student access from course |
| **Admin** | `GET` | `/api/v1/admin/announcements` | Admin | List all platform announcements |
| **Admin** | `POST` | `/api/v1/admin/announcements` | Admin | Publish announcement (ALL, COURSE, STUDENTS)|
| **Tutor** | `GET` | `/api/v1/tutor/courses` | Tutor | List courses owned by the tutor |
| **Tutor** | `POST` | `/api/v1/tutor/courses` | Tutor | Create course under an assigned subject |
| **Tutor** | `PATCH` | `/api/v1/tutor/courses/:id` | Tutor | Update course metadata or price |
| **Tutor** | `POST` | `/api/v1/tutor/courses/:id/lectures` | Tutor | Add lecture to course |
| **Tutor** | `PATCH` | `/api/v1/tutor/lectures/:id` | Tutor | Update lecture details |
| **Tutor** | `DELETE`| `/api/v1/tutor/lectures/:id` | Tutor | Delete lecture & cascade quiz/progress |
| **Tutor** | `PUT` | `/api/v1/tutor/lectures/:id/quiz` | Tutor | Create or replace mandatory 5+ question quiz|
| **Tutor** | `POST` | `/api/v1/tutor/courses/:id/exams` | Tutor | Create exam for course |
| **Tutor** | `PATCH` | `/api/v1/tutor/exams/:id` | Tutor | Update exam questions or instructions |
| **Tutor** | `GET` | `/api/v1/tutor/exams/:id/submissions` | Tutor | List student exam submissions |
| **Tutor** | `PATCH` | `/api/v1/tutor/submissions/:id/grade` | Tutor | Grade submission & award points |
| **Student** | `GET` | `/api/v1/student/courses` | Student | List granted enrolled courses |
| **Student** | `GET` | `/api/v1/student/courses/:id/learning` | Student | Course learning view with locked/unlocked state|
| **Student** | `POST` | `/api/v1/student/lectures/:id/quiz-attempts`| Student | Submit quiz attempt (100% required to pass)|
| **Student** | `POST` | `/api/v1/student/exams/:id/submissions` | Student | Submit answers for course exam |
| **Student** | `GET` | `/api/v1/student/exam-results` | Student | View published exam scores and tutor feedback |
| **Student** | `PUT` | `/api/v1/student/ratings/course/:id` | Student | Rate and review an enrolled course |
| **Student** | `PUT` | `/api/v1/student/ratings/tutor/:id` | Student | Rate and review tutor of an enrolled course |
| **Student** | `GET` | `/api/v1/student/announcements` | Student | View active broadcast announcements |
| **Student** | `GET` | `/api/v1/student/achievements` | Student | View points-based badges and achievements |

---

## 3. System & Health

### `GET /health`
- **Summary:** Service liveness check.
- **Access Level:** Public (No authorization required).
- **Mounted Path:** `GET http://localhost:3000/health` (Root level, not `/api/v1`).
- **Response `200 OK`:**
  ```json
  {
    "status": "ok",
    "service": "educational-platform-api"
  }
  ```

---

## 4. Authentication API

Mounted at `/api/v1/auth`.

### `POST /auth/admin/login`
- **Summary:** Authenticate an administrator account.
- **Access Level:** Public (Rate limit: 20 requests / 15 minutes).
- **Description:** Validates administrator credentials. Returns an Admin Bearer token.
- **Request Body:**
  ```json
  {
    "username": "admin",
    "password": "SecretAdminPassword123"
  }
  ```
- **Validation Rules:**
  - `username`: String, min 3, max 64 chars.
  - `password`: String, min 8, max 256 chars.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "user": {
        "id": "64b000000000000000000001",
        "username": "admin",
        "displayName": "Platform Administrator",
        "role": "ADMIN",
        "status": "ACTIVE",
        "points": 0,
        "deviceBound": false
      }
    }
    ```
  - `401 Unauthorized` (`INVALID_CREDENTIALS`): Invalid username, password, or non-admin account.
  - `403 Forbidden` (`ACCOUNT_DEACTIVATED`): Account status is `DEACTIVATED`.

---

### `POST /auth/register`
- **Summary:** Register a Student or Tutor using a single-use signup code.
- **Access Level:** Public (Rate limit: 20 requests / 15 minutes).
- **Description:** Consumes an admin-generated signup code atomically and binds the account to `device_id`.
- **Request Body:**
  ```json
  {
    "signupCode": "EDU-STUDENT-q9T4FgZ_oN3VXwC2ap8L1m6h",
    "role": "STUDENT",
    "username": "alex_smith",
    "email": "alex.smith@example.com",
    "displayName": "Alex Smith",
    "password": "Password12345!",
    "device_id": "c8a1b392-564a-4d73-b3c9-9403164920de"
  }
  ```
- **Validation Rules:**
  - `signupCode`: String, 8–128 chars.
  - `role`: Enum `STUDENT` or `TUTOR` (must match signup code).
  - `username`: String, 3–64 chars (stored lowercased).
  - `email`: Optional String, valid email format (stored lowercased).
  - `displayName`: String, 1–100 chars.
  - `password`: String, 10–256 chars.
  - `device_id`: String, 16–256 chars (hardware/UUID identifier).
- **Idempotent Retry Policy:** If network disconnects after account creation, submitting the *exact identical payload* returns `200 OK` with a fresh token. If payload fields differ, it returns `409 SIGNUP_CODE_ALREADY_USED`.
- **Responses:**
  - `201 Created` (First creation) or `200 OK` (Safe replay):
    ```json
    {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "user": {
        "id": "64b000000000000000000002",
        "username": "alex_smith",
        "email": "alex.smith@example.com",
        "displayName": "Alex Smith",
        "role": "STUDENT",
        "status": "ACTIVE",
        "points": 0,
        "deviceBound": true
      }
    }
    ```
  - `400 Bad Request` (`INVALID_SIGNUP_CODE`): Code unknown or expired.
  - `403 Forbidden` (`SIGNUP_CODE_ROLE_MISMATCH`): `role` does not match the code's intended role.
  - `409 Conflict` (`SIGNUP_CODE_ALREADY_USED`): Code already consumed.
  - `409 Conflict` (`CONFLICT`): Username or email already registered.
  - `422 Unprocessable` (`VALIDATION_ERROR`): Missing/invalid fields.
  - `503 Service Unavailable` (`REGISTRATION_RETRY_REQUIRED`): Temporary database transaction conflict; retry the identical request.

---

### `POST /auth/login`
- **Summary:** Authenticate a Student or Tutor from their bound device.
- **Access Level:** Public (Rate limit: 20 requests / 15 minutes).
- **Headers:** `x-device-id: <device_id>` (Preferred) OR passed in body `device_id`.
- **Request Body:**
  ```json
  {
    "username": "alex_smith",
    "password": "Password12345!",
    "device_id": "c8a1b392-564a-4d73-b3c9-9403164920de"
  }
  ```
- **Responses:**
  - `200 OK`:
    ```json
    {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "user": {
        "id": "64b000000000000000000002",
        "username": "alex_smith",
        "displayName": "Alex Smith",
        "role": "STUDENT",
        "status": "ACTIVE",
        "points": 0,
        "deviceBound": true
      }
    }
    ```
  - `400 Bad Request` (`DEVICE_ID_REQUIRED`): Neither header nor body contained device ID.
  - `401 Unauthorized` (`INVALID_CREDENTIALS`): Wrong password or user is ADMIN.
  - `403 Forbidden` (`DEVICE_MISMATCH`): The supplied device ID does not match the account's bound device.
  - `403 Forbidden` (`ACCOUNT_DEACTIVATED`): Account is deactivated.

---

### `GET /auth/me`
- **Summary:** Retrieve profile details and session type for the currently authenticated caller.
- **Access Level:** Authenticated (`ADMIN`, `TUTOR`, or `STUDENT`).
- **Headers:** `Authorization: Bearer <token>`, and `x-device-id: <id>` (for mobile sessions).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "user": {
        "id": "64b000000000000000000002",
        "username": "alex_smith",
        "email": "alex.smith@example.com",
        "displayName": "Alex Smith",
        "role": "STUDENT",
        "status": "ACTIVE",
        "points": 120,
        "deviceBound": true
      },
      "sessionType": "mobile"
    }
    ```
  - `401 Unauthorized` (`AUTH_REQUIRED`, `INVALID_TOKEN`, `SESSION_REVOKED`).

---

## 5. Temporary Desktop QR Authentication

Mounted at `/api/v1/desktop`.

### `POST /desktop/challenges`
- **Summary:** Generate a temporary desktop challenge for QR code rendering.
- **Access Level:** Public (Rate limit: 30 requests / minute).
- **Request Body:** None.
- **Responses:**
  - `201 Created`:
    ```json
    {
      "challenge": "Q6hfrwkJut1FJp1YB4W2DY51k_i84kpGSrFyOWQo-dM",
      "expiresAt": "2026-09-14T12:35:00.000Z"
    }
    ```

---

### `GET /desktop/challenges/:challenge/status`
- **Summary:** Poll status of a generated desktop QR challenge.
- **Access Level:** Public (Rate limit: 30 requests / minute).
- **Path Parameters:** `challenge` (The raw challenge string).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "status": "PENDING",
      "expiresAt": "2026-09-14T12:35:00.000Z"
    }
    ```
    *Possible statuses:* `PENDING`, `APPROVED`, `CONSUMED`, `CLOSED`, `EXPIRED`.
  - `404 Not Found` (`CHALLENGE_NOT_FOUND`).

---

### `POST /desktop/challenges/:challenge/authorize`
- **Summary:** Mobile app approves the desktop login challenge.
- **Access Level:** Authenticated Mobile `STUDENT` or `TUTOR`.
- **Headers:** `Authorization: Bearer <mobile_token>`, `x-device-id: <device_id>`.
- **Path Parameters:** `challenge` (The raw challenge string scanned from QR).
- **Description:** Links the user to the challenge, marks it `APPROVED`, broadcasts a Socket.IO event to the desktop room, and terminates any prior desktop sessions for this user.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "status": "APPROVED",
      "expiresAt": "2026-09-14T12:35:00.000Z"
    }
    ```
  - `409 Conflict` (`CHALLENGE_NOT_PENDING`): Challenge expired or already processed.

---

### `POST /desktop/challenges/:challenge/exchange`
- **Summary:** Desktop app exchanges an approved challenge for an access token.
- **Access Level:** Public (Rate limit: 30 requests / minute).
- **Path Parameters:** `challenge` (The raw challenge string).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tokenType": "Bearer",
      "user": {
        "id": "64b000000000000000000002",
        "username": "alex_smith",
        "displayName": "Alex Smith",
        "role": "STUDENT",
        "status": "ACTIVE",
        "points": 120,
        "deviceBound": true
      },
      "expiresAt": "2026-09-14T16:30:00.000Z"
    }
    ```
  - `409 Conflict` (`CHALLENGE_NOT_APPROVED`): Challenge has not been approved by mobile device.
  - `409 Conflict` (`CHALLENGE_ALREADY_EXCHANGED`): A concurrent exchange consumed the challenge after this request read it. A later replay normally returns `CHALLENGE_NOT_APPROVED`.

---

### `DELETE /desktop/sessions/current`
- **Summary:** Explicitly terminate the active desktop session upon logout or window closure.
- **Access Level:** Authenticated Desktop Token (`sessionType: 'desktop'`).
- **Headers:** `Authorization: Bearer <desktop_token>`.
- **Responses:**
  - `204 No Content`: Session closed successfully.
  - `403 Forbidden` (`DESKTOP_TOKEN_REQUIRED`): Token is not a desktop session token.

---

### Socket.IO Real-Time Protocol Specification
Clients connect to the root URL via Socket.IO v4 (`transports: ['websocket', 'polling']`).
- **Subscription:**
  ```javascript
  socket.emit('desktop:subscribe', { challenge: '<raw_challenge>' }, (ack) => {
    // ack: { ok: true } or { ok: false, error: 'INVALID_CHALLENGE' }
  });
  ```
- **Real-Time Push Notification:**
  ```javascript
  socket.on('desktop:status', ({ status }) => {
    // status: 'APPROVED' or 'CONSUMED'
    if (status === 'APPROVED') {
      // Immediately call /desktop/challenges/:challenge/exchange
    }
  });
  ```

---

## 6. Public Catalog & Discovery

Mounted at `/api/v1`.

### `GET /subjects`
- **Summary:** Retrieve all registered academic subjects ordered alphabetically.
- **Access Level:** Public.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000010",
          "name": "Advanced Physics",
          "description": "Mechanics, thermodynamics, and electromagnetism.",
          "imageUrl": "https://cdn.example.com/subjects/physics.png",
          "createdAt": "2026-09-01T10:00:00.000Z"
        }
      ]
    }
    ```

---

### `GET /courses`
- **Summary:** Search, filter, and paginate published courses.
- **Access Level:** Public.
- **Query Parameters:**
  - `q` (string, optional): Case-insensitive search across course name, subject name, or tutor display name.
  - `subjectId` (string, optional): Filter by exact Subject ObjectID.
  - `tutorId` (string, optional): Filter by exact Tutor User ObjectID.
  - `page` (integer, optional, default: 1): Page number (min 1).
  - `limit` (integer, optional, default: 20): Results per page (min 1, max 100).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000020",
          "name": "Calculus I: Foundations",
          "description": "Comprehensive introduction to differential calculus.",
          "imageUrl": "https://cdn.example.com/courses/calc1.png",
          "price": 49.99,
          "published": true,
          "tutorId": "64b000000000000000000005",
          "subjectId": "64b000000000000000000010",
          "videoCount": 12,
          "ratingAverage": 4.85,
          "ratingCount": 42,
          "createdAt": "2026-09-05T08:00:00.000Z",
          "updatedAt": "2026-09-10T14:30:00.000Z",
          "subject": {
            "id": "64b000000000000000000010",
            "name": "Mathematics",
            "description": "Pure and applied mathematics.",
            "imageUrl": "https://cdn.example.com/math.png"
          },
          "tutor": {
            "id": "64b000000000000000000005",
            "displayName": "Dr. Sarah Adams"
          }
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 1,
        "pages": 1
      }
    }
    ```

---

### `GET /courses/:id`
- **Summary:** Retrieve published course syllabus and public lecture outline.
- **Access Level:** Public.
- **Description:** Returns course details with sanitized lecture metadata (`id`, `title`, `position`). Video streaming links, worksheets, and quizzes are omitted from this public endpoint.
- **Path Parameters:** `id` (Course ObjectID).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "id": "64b000000000000000000020",
      "name": "Calculus I: Foundations",
      "description": "Comprehensive introduction to differential calculus.",
      "imageUrl": "https://cdn.example.com/courses/calc1.png",
      "price": 49.99,
      "published": true,
      "videoCount": 2,
      "ratingAverage": 4.85,
      "ratingCount": 42,
      "subject": {
        "id": "64b000000000000000000010",
        "name": "Mathematics"
      },
      "tutor": {
        "id": "64b000000000000000000005",
        "displayName": "Dr. Sarah Adams"
      },
      "lectures": [
        { "id": "64b000000000000000000031", "title": "Limits and Continuity", "position": 1 },
        { "id": "64b000000000000000000032", "title": "The Definition of the Derivative", "position": 2 }
      ]
    }
    ```
  - `404 Not Found` (`COURSE_NOT_FOUND`).

---

### `GET /tutors/:id`
- **Summary:** Retrieve active tutor public profile, published courses, and student reviews.
- **Access Level:** Public.
- **Path Parameters:** `id` (Tutor User ObjectID).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "id": "64b000000000000000000005",
      "displayName": "Dr. Sarah Adams",
      "courses": [
        {
          "id": "64b000000000000000000020",
          "name": "Calculus I: Foundations",
          "imageUrl": "https://cdn.example.com/courses/calc1.png",
          "ratingAverage": 4.85
        }
      ],
      "tutorRatings": [
        { "value": 5, "comment": "Exceptional explanations and notes!" }
      ],
      "ratingAverage": 5.0,
      "ratingCount": 1
    }
    ```
  - `404 Not Found` (`TUTOR_NOT_FOUND`).

---

### `GET /leaderboard`
- **Summary:** Retrieve top 100 students ranked by earned academic points.
- **Access Level:** Public.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "rank": 1,
          "id": "64b000000000000000000002",
          "displayName": "Alex Smith",
          "points": 850
        },
        {
          "rank": 2,
          "id": "64b000000000000000000008",
          "displayName": "Jordan Lee",
          "points": 620
        }
      ]
    }
    ```

---

## 7. Admin Management API

Mounted at `/api/v1/admin`. All routes require `Authorization: Bearer <admin_jwt>`.

### `GET /admin/subjects`
- **Summary:** List all subjects.
- **Responses:** `200 OK` `{ "items": [ Subject ] }`.

---

### `POST /admin/subjects`
- **Summary:** Create an academic subject category.
- **Request Body:**
  ```json
  {
    "name": "Organic Chemistry",
    "description": "Structure, properties, and reactions of organic compounds.",
    "imageUrl": "https://cdn.example.com/subjects/org-chem.png"
  }
  ```
- **Validation:** `name` (1–100 chars, required), `description` (max 1000, optional), `imageUrl` (valid URL, optional).
- **Responses:** `201 Created` with created `Subject` record.

---

### `PATCH /admin/subjects/:id`
- **Summary:** Update subject details.
- **Path Parameters:** `id` (Subject ObjectID).
- **Request Body:** Partial object containing any of `name`, `description`, `imageUrl` (at least 1 property required). Pass `null` to clear optional fields.
- **Responses:** `200 OK` with updated `Subject`.

---

### `DELETE /admin/subjects/:id`
- **Summary:** Delete an unused subject.
- **Path Parameters:** `id` (Subject ObjectID).
- **Responses:**
  - `204 No Content`: Deleted.
  - `409 Conflict` (`SUBJECT_IN_USE`): Cannot delete if one or more courses reference this subject.

---

### `GET /admin/signup-codes`
- **Summary:** List generated signup codes and usage status.
- **Description:** For security, code hashes are never returned. Lists `id`, `role`, `expiresAt`, `usedAt`, `usedById`, and `createdAt`.
- **Responses:** `200 OK` `{ "items": [ ... ] }`.

---

### `POST /admin/signup-codes`
- **Summary:** Generate a single-use onboarding code for a Tutor or Student.
- **Request Body:**
  ```json
  {
    "role": "TUTOR",
    "expiresInHours": 72
  }
  ```
- **Validation:** `role` (`STUDENT` or `TUTOR`), `expiresInHours` (integer 1–720, default: 72).
- **Responses:**
  - `201 Created`:
    ```json
    {
      "id": "64b000000000000000000040",
      "code": "EDU-TUTOR-p7R2xnY_Kc3Mq8FtBv5Sd0Wa",
      "role": "TUTOR",
      "expiresAt": "2026-09-17T12:00:00.000Z"
    }
    ```
    > [!IMPORTANT]
    > The plaintext `code` is returned only once in this response. The server stores only its cryptographic SHA-256 hash. Deliver this code securely to the tutor or student.

---

### `GET /admin/users`
- **Summary:** List platform users with optional filters.
- **Query Parameters:**
  - `role` (optional): Filter by `ADMIN`, `TUTOR`, or `STUDENT`.
  - `status` (optional): Filter by `ACTIVE` or `DEACTIVATED`.
  - `search` (optional): Case-insensitive search on `username` or `displayName`.
- **Responses:** `200 OK` `{ "items": [ safeUser, ... ] }`.

---

### `PATCH /admin/users/:id/status`
- **Summary:** Activate or deactivate a user account.
- **Path Parameters:** `id` (User ObjectID).
- **Request Body:**
  ```json
  {
    "status": "DEACTIVATED"
  }
  ```
- **Side Effects:** Increments `tokenVersion` (invalidating all active JWTs immediately). If deactivating, terminates any active desktop session. Administrators cannot modify their own status (`400 CANNOT_DEACTIVATE_SELF`).
- **Responses:** `200 OK` with safe user object.

---

### `POST /admin/users/:id/device-reset`
- **Summary:** Clear a student's or tutor's hardware device binding (`deviceId = null`).
- **Path Parameters:** `id` (User ObjectID).
- **Request Body:** None.
- **Side Effects:** Clears `deviceId`, increments `tokenVersion` to revoke existing mobile/desktop tokens, closes desktop sessions. The next successful login from a new device atomically binds the new hardware identifier.
- **Responses:** `200 OK` with updated safe user object (`deviceBound: false`).

---

### `PUT /admin/tutors/:id/subjects/:subjectId`
- **Summary:** Authorize a tutor to create and teach courses under a specific subject.
- **Path Parameters:** `id` (Tutor User ObjectID), `subjectId` (Subject ObjectID).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "id": "64b000000000000000000050",
      "tutorId": "64b000000000000000000005",
      "subjectId": "64b000000000000000000010"
    }
    ```
  - `404 Not Found` (`TUTOR_NOT_FOUND`).

---

### `DELETE /admin/tutors/:id/subjects/:subjectId`
- **Summary:** Remove a tutor's teaching privileges for a subject.
- **Path Parameters:** `id` (Tutor User ObjectID), `subjectId` (Subject ObjectID).
- **Responses:** `204 No Content`. (Existing published courses remain intact, but creating new courses under this subject will be blocked).

---

### `PUT /admin/students/:id/courses/:courseId`
- **Summary:** Manually grant a student access to a course (Manual enrollment).
- **Path Parameters:** `id` (Student User ObjectID), `courseId` (Course ObjectID).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "id": "64b000000000000000000060",
      "studentId": "64b000000000000000000002",
      "courseId": "64b000000000000000000020",
      "grantedById": "64b000000000000000000001",
      "active": true,
      "grantedAt": "2026-09-14T12:00:00.000Z"
    }
    ```
  - `404 Not Found` (`STUDENT_NOT_FOUND`).

---

### `DELETE /admin/students/:id/courses/:courseId`
- **Summary:** Revoke a student's access to a course.
- **Path Parameters:** `id` (Student User ObjectID), `courseId` (Course ObjectID).
- **Responses:** `204 No Content` (Sets enrollment `active: false`).

---

### `GET /admin/announcements`
- **Summary:** List all announcements ordered by newest first.
- **Responses:** `200 OK` `{ "items": [ Announcement, ... ] }`.

---

### `POST /admin/announcements`
- **Summary:** Broadcast a targeted or platform-wide announcement.
- **Request Body:**
  ```json
  {
    "title": "Scheduled Platform Maintenance",
    "body": "The system will be offline for 30 minutes on Saturday at 02:00 UTC.",
    "audience": "ALL",
    "courseIds": [],
    "studentIds": [],
    "expiresAt": "2026-09-20T00:00:00.000Z"
  }
  ```
- **Validation Rules:**
  - `title`: String, 1–150 chars.
  - `body`: String, 1–5000 chars.
  - `audience`: Enum `ALL`, `COURSE`, or `STUDENTS`.
  - If `audience === 'COURSE'`, `courseIds` must contain at least 1 valid Course ObjectID.
  - If `audience === 'STUDENTS'`, `studentIds` must contain at least 1 valid Student ObjectID.
  - `expiresAt`: Optional ISO Date string.
- **Responses:** `201 Created` with created `Announcement` record.

---

## 8. Tutor Portal API

Mounted at `/api/v1/tutor`. All routes require `Authorization: Bearer <token>` (Tutor role) and `x-device-id` (if on mobile).

### `GET /tutor/courses`
- **Summary:** Retrieve all courses created by the authenticated tutor.
- **Responses:** `200 OK` `{ "items": [ Course with Subject, ... ] }`.

---

### `POST /tutor/courses`
- **Summary:** Create a new course under an assigned subject.
- **Request Body:**
  ```json
  {
    "name": "Organic Chemistry I",
    "description": "Reaction mechanisms and synthesis pathways.",
    "imageUrl": "https://cdn.example.com/courses/chem1.png",
    "price": 59.99,
    "subjectId": "64b000000000000000000010",
    "published": false
  }
  ```
- **Validation Rules:**
  - `name`: 1–150 chars.
  - `description`: 1–5000 chars.
  - `imageUrl`: Valid URL.
  - `price`: Non-negative number (e.g. `0` or `59.99`).
  - `subjectId`: MongoDB ObjectID. The tutor **must** have an active assignment to this subject.
  - `published`: Boolean (default `false`).
- **Responses:**
  - `201 Created` with created `Course` object.
  - `403 Forbidden` (`SUBJECT_NOT_ASSIGNED`): Tutor is not assigned to `subjectId`.

---

### `PATCH /tutor/courses/:id`
- **Summary:** Update course metadata, price, or publish status.
- **Path Parameters:** `id` (Course ObjectID).
- **Request Body:** Partial object containing any of `name`, `description`, `imageUrl`, `price`, `published`.
- **Responses:** `200 OK` with updated `Course` object.
- **Errors:** `404 Not Found` (`COURSE_NOT_FOUND` if not owned by tutor).

---

### `POST /tutor/courses/:id/lectures`
- **Summary:** Add a sequential lecture to a course.
- **Path Parameters:** `id` (Course ObjectID).
- **Request Body:**
  ```json
  {
    "title": "Alkanes & Conformations",
    "description": "Newman projections and cyclohexane conformations.",
    "position": 1,
    "videoUrl": "https://drive.google.com/file/d/1a2b3c4d/view",
    "pdfUrls": ["https://cdn.example.com/slides/lecture1.pdf"],
    "points": 10,
    "published": false
  }
  ```
- **Validation Rules:**
  - `title`: 1–200 chars.
  - `position`: Positive integer (must be unique within the course).
  - `videoUrl`: Valid URL (e.g. Google Drive stream).
  - `pdfUrls`: Array of URLs (max 20).
  - `points`: Integer 0–1000 (default: 10).
  - `published`: Must be `false` on initial creation (`409 QUIZ_REQUIRED_BEFORE_PUBLISH`).
- **Side Effects:** Increments the course's `videoCount` after creating the lecture.
- **Responses:** `201 Created` with created `Lecture` record.

---

### `PATCH /tutor/lectures/:id`
- **Summary:** Update lecture details or publish it.
- **Path Parameters:** `id` (Lecture ObjectID).
- **Request Body:** Partial subset of `title`, `description`, `position`, `videoUrl`, `pdfUrls`, `points`, `published`.
- **Integrity Rule:** Setting `published: true` requires an attached quiz (`409 QUIZ_REQUIRED_BEFORE_PUBLISH`).
- **Responses:** `200 OK` with updated `Lecture`.

---

### `DELETE /tutor/lectures/:id`
- **Summary:** Delete a lecture, cascading its quizzes and student progress.
- **Path Parameters:** `id` (Lecture ObjectID).
- **Side Effects:** Decrements the course's `videoCount` after deleting the lecture.
- **Responses:** `204 No Content`.

---

### `PUT /tutor/lectures/:id/quiz`
- **Summary:** Create or replace the mandatory 100%-pass quiz for a lecture.
- **Path Parameters:** `id` (Lecture ObjectID).
- **Request Body:**
  ```json
  {
    "questions": [
      {
        "prompt": "What is the bond angle in a tetrahedral carbon?",
        "choices": ["90°", "109.5°", "120°", "180°"],
        "correctChoice": 1
      },
      {
        "prompt": "Which conformation of cyclohexane has the lowest energy?",
        "choices": ["Chair", "Boat", "Twist-boat", "Half-chair"],
        "correctChoice": 0
      },
      {
        "prompt": "An sp3 hybridized orbital has what percentage s-character?",
        "choices": ["50%", "33.3%", "25%", "20%"],
        "correctChoice": 2
      },
      {
        "prompt": "Which element forms four covalent bonds?",
        "choices": ["Oxygen", "Nitrogen", "Carbon", "Fluorine"],
        "correctChoice": 2
      },
      {
        "prompt": "What is the molecular formula of butane?",
        "choices": ["C3H8", "C4H10", "C4H8", "C5H12"],
        "correctChoice": 1
      }
    ]
  }
  ```
- **Validation Rules:**
  - `questions`: Array containing between 5 and 100 questions.
  - Each question must contain `prompt` (1–1000 chars), `choices` (exactly 4 strings), and `correctChoice` (integer `0..3`).
  - `passPercent` is strictly locked to `100%`.
- **Responses:** `200 OK` with saved `Quiz` object.

---

### `POST /tutor/courses/:id/exams`
- **Summary:** Create an exam with multiple choice and written questions.
- **Path Parameters:** `id` (Course ObjectID).
- **Request Body:**
  ```json
  {
    "title": "Midterm Examination",
    "instructions": "Answer all 3 questions. Show complete workings for written problems.",
    "points": 50,
    "published": false,
    "questions": [
      {
        "id": "q1",
        "type": "MULTIPLE_CHOICE",
        "prompt": "Identify the major product of acid-catalyzed dehydration.",
        "choices": ["1-butene", "trans-2-butene", "cis-2-butene", "butanone"],
        "correctChoice": 1,
        "imageUrls": ["https://cdn.example.com/diagrams/reaction1.png"]
      },
      {
        "id": "q2",
        "type": "WRITTEN",
        "prompt": "Outline the full arrow-pushing mechanism for the SN2 reaction of 1-bromobutane with sodium hydroxide.",
        "imageUrls": []
      }
    ]
  }
  ```
- **Validation Rules:**
  - `title`: 1–200 chars.
  - `points`: Integer 0–10000 (default: 50).
  - `questions`: Array of 1 or more questions. Question `id` must be stable strings. `MULTIPLE_CHOICE` requires `choices` (length 4) and `correctChoice` (`0..3`). `WRITTEN` requires `prompt`.
- **Responses:** `201 Created` with created `Exam` record.

---

### `PATCH /tutor/exams/:id`
- **Summary:** Update exam instructions, points, published state, or question array.
- **Path Parameters:** `id` (Exam ObjectID).
- **Request Body:** Partial object containing any of `title`, `instructions`, `points`, `published`, `questions`.
- **Responses:** `200 OK` with updated `Exam`.

---

### `GET /tutor/exams/:id/submissions`
- **Summary:** List student submissions for an exam.
- **Path Parameters:** `id` (Exam ObjectID).
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000070",
          "examId": "64b000000000000000000045",
          "studentId": "64b000000000000000000002",
          "status": "SUBMITTED",
          "score": null,
          "feedback": null,
          "answers": [
            { "questionId": "q1", "choice": 1 },
            { "questionId": "q2", "text": "Hydroxide attacks the primary carbon from the backside..." }
          ],
          "attachmentUrls": ["https://cdn.example.com/uploads/student-work.pdf"],
          "submittedAt": "2026-09-14T11:00:00.000Z",
          "student": {
            "id": "64b000000000000000000002",
            "displayName": "Alex Smith",
            "username": "alex_smith"
          }
        }
      ]
    }
    ```

---

### `PATCH /tutor/submissions/:id/grade`
- **Summary:** Grade a student exam submission and optionally publish results.
- **Path Parameters:** `id` (ExamSubmission ObjectID).
- **Request Body:**
  ```json
  {
    "score": 94.5,
    "feedback": "Excellent mechanism detail. Minor penalty on stereochemical inversion notation.",
    "publish": true
  }
  ```
- **Validation Rules:** `score` (number 0–100), `feedback` (optional string, max 5000 chars), `publish` (boolean, default: `false`).
- **Gamification Rule:** When `publish: true`:
  - Sets `status = 'PUBLISHED'` and `publishedAt = now()`.
  - Creates a unique `PointEvent` (`reason: 'EXAM_COMPLETED'`) and awards the exam's total points to the student's profile.
  - Subsequent regrading or editing will **not** duplicate points (guarded by compound index `[studentId, reason, sourceId]`).
- **Responses:** `200 OK` with updated `ExamSubmission`.

---

## 9. Student Learning API

Mounted at `/api/v1/student`. All routes require `Authorization: Bearer <token>` (Student role) and `x-device-id` (if on mobile).

### `GET /student/courses`
- **Summary:** List all courses currently granted to the authenticated student.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000020",
          "name": "Calculus I: Foundations",
          "description": "Differential and integral calculus.",
          "imageUrl": "https://cdn.example.com/courses/calc1.png",
          "price": 49.99,
          "videoCount": 12,
          "ratingAverage": 4.85,
          "ratingCount": 42,
          "grantedAt": "2026-09-12T10:00:00.000Z",
          "subject": { "id": "64b000000000000000000010", "name": "Mathematics" },
          "tutor": { "id": "64b000000000000000000005", "displayName": "Dr. Sarah Adams" }
        }
      ]
    }
    ```

---

### `GET /student/courses/:id/learning`
- **Summary:** Retrieve course syllabus with dynamic sequential unlock status and progress.
- **Path Parameters:** `id` (Course ObjectID).
- **Behavior & Security Filtering:**
  - Requires active course enrollment (`403 COURSE_ACCESS_REQUIRED`).
  - Lecture 1 (`position: 1`) is unlocked by default.
  - Subsequent lectures remain `{ id, title, position, locked: true }` until the student passes the prior lecture's quiz with 100%.
  - Unlocked lectures include `videoUrl`, `pdfUrls`, and student progress (`bestScore`, `attempts`, `completedAt`).
  - All quiz and exam questions have their `correctChoice` property completely stripped from the response.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "course": {
        "id": "64b000000000000000000020",
        "name": "Calculus I: Foundations",
        "lectures": [
          {
            "id": "64b000000000000000000031",
            "title": "Limits and Continuity",
            "description": "Introduction to limits.",
            "position": 1,
            "videoUrl": "https://drive.google.com/file/d/123/view",
            "pdfUrls": ["https://cdn.example.com/worksheet1.pdf"],
            "points": 10,
            "quiz": {
              "id": "64b000000000000000000035",
              "passPercent": 100,
              "questions": [
                { "prompt": "What is the limit of 1/x as x approaches infinity?", "choices": ["0", "1", "Infinity", "Undefined"] }
              ]
            },
            "progress": {
              "bestScore": 100,
              "attempts": 1,
              "completedAt": "2026-09-13T14:00:00.000Z"
            }
          },
          {
            "id": "64b000000000000000000032",
            "title": "The Definition of the Derivative",
            "position": 2,
            "locked": true
          }
        ],
        "exams": [
          {
            "id": "64b000000000000000000045",
            "title": "Midterm Examination",
            "points": 50,
            "questions": [
              { "id": "q1", "type": "MULTIPLE_CHOICE", "prompt": "Evaluate d/dx (x^2)", "choices": ["x", "2x", "2", "x^2"] }
            ]
          }
        ]
      }
    }
    ```

---

### `POST /student/lectures/:id/quiz-attempts`
- **Summary:** Submit answers for a lecture quiz to unlock the next lecture and earn points.
- **Path Parameters:** `id` (Lecture ObjectID).
- **Request Body:**
  ```json
  {
    "answers": [1, 0, 2, 2, 1]
  }
  ```
- **Validation Rules:**
  - `answers`: Array of integers `0..3` corresponding to zero-based choice selections.
  - Length of `answers` must match the question count (5–100).
- **Grading & Progression Logic:**
  - Evaluates score instantly server-side.
  - If score is `100%`:
    - Sets `progress.completedAt = now()`.
    - Makes the next published lecture available when one exists.
    - Awards the lecture's `points` to the student profile (awarded only on first completion).
    - Automatically checks and syncs student achievements against points thresholds.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "score": 100,
      "correct": 5,
      "total": 5,
      "passed": true,
      "nextLectureUnlocked": true,
      "progress": {
        "id": "64b000000000000000000080",
        "studentId": "64b000000000000000000002",
        "lectureId": "64b000000000000000000031",
        "bestScore": 100,
        "attempts": 1,
        "completedAt": "2026-09-14T12:00:00.000Z"
      }
    }
    ```
  - `403 Forbidden` (`LECTURE_LOCKED`): Prior lecture quiz not yet passed.
  - `422 Unprocessable` (`ANSWER_COUNT_MISMATCH`): Answer count differs from the quiz question count.

`nextLectureUnlocked` mirrors `passed`; it can be `true` on the final lecture,
where there is no following lecture. Refresh the learning view to find the
actual next available lecture.

---

### `POST /student/exams/:id/submissions`
- **Summary:** Submit completed exam answers and optional file attachments.
- **Path Parameters:** `id` (Exam ObjectID).
- **Request Body:**
  ```json
  {
    "answers": [
      { "questionId": "q1", "choice": 1 },
      { "questionId": "q2", "text": "Detailed written explanation with formulas..." }
    ],
    "attachmentUrls": ["https://cdn.example.com/uploads/student-work.pdf"]
  }
  ```
- **Validation Rules:**
  - `answers`: Must contain exactly one answer object for every question defined in the exam.
  - For `MULTIPLE_CHOICE`, `choice` must be an integer `0..3`.
  - For `WRITTEN`, `text` must be a string.
  - `attachmentUrls`: Optional array of URLs (max 20).
- **Responses:**
  - `201 Created` with created `ExamSubmission` (`status: 'SUBMITTED'`).
  - `409 Conflict`: Student has already submitted this exam (limit: 1 submission per exam).
  - `422 Unprocessable` (`INVALID_EXAM_ANSWERS`): Incomplete questions or invalid answer types.

---

### `GET /student/exam-results`
- **Summary:** View graded and published exam scores and tutor feedback.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000070",
          "examId": "64b000000000000000000045",
          "status": "PUBLISHED",
          "score": 94.5,
          "feedback": "Excellent mechanism detail.",
          "publishedAt": "2026-09-14T15:00:00.000Z",
          "exam": {
            "id": "64b000000000000000000045",
            "title": "Midterm Examination",
            "course": {
              "id": "64b000000000000000000020",
              "name": "Calculus I: Foundations"
            }
          }
        }
      ]
    }
    ```

---

### `PUT /student/ratings/course/:id`
- **Summary:** Submit or update a rating for an enrolled course.
- **Path Parameters:** `id` (Course ObjectID).
- **Request Body:**
  ```json
  {
    "value": 5,
    "comment": "Incredible lectures and very clear worksheets."
  }
  ```
- **Validation:** `value` (integer 1–5), `comment` (optional string, max 2000 chars).
- **Side Effects:** Automatically recalculates and updates `ratingAverage` and `ratingCount` on the course record.
- **Responses:** `200 OK` with saved `CourseRating`.
- **Errors:** `403 Forbidden` (`COURSE_ACCESS_REQUIRED`).

---

### `PUT /student/ratings/tutor/:id`
- **Summary:** Submit or update a review for a tutor of an enrolled course.
- **Path Parameters:** `id` (Tutor User ObjectID).
- **Request Body:**
  ```json
  {
    "value": 5,
    "comment": "Always available for feedback and exam grading."
  }
  ```
- **Validation:** `value` (integer 1–5), `comment` (optional string, max 2000 chars).
- **Responses:** `200 OK` with saved `TutorRating`.
- **Errors:** `403 Forbidden` (`TUTOR_RATING_FORBIDDEN` if student is not enrolled in any course taught by this tutor).

---

### `GET /student/announcements`
- **Summary:** Retrieve active broadcast announcements targeted to the student.
- **Description:** Returns non-expired announcements targeted to `ALL`, targeted directly to the student (`STUDENTS`), or targeted to courses the student is enrolled in (`COURSE`).
- **Responses:** `200 OK` `{ "items": [ Announcement, ... ] }`.

---

### `GET /student/achievements`
- **Summary:** Retrieve earned point-threshold achievements and badges.
- **Description:** Automatically evaluates student points against achievement thresholds and awards missing badges prior to responding.
- **Responses:**
  - `200 OK`:
    ```json
    {
      "items": [
        {
          "id": "64b000000000000000000090",
          "awardedAt": "2026-09-14T12:00:00.000Z",
          "achievement": {
            "id": "64b000000000000000000099",
            "key": "POINTS_100",
            "name": "Century Club",
            "description": "Earn 100 learning points across courses.",
            "pointsThreshold": 100,
            "badgeUrl": "https://cdn.example.com/badges/points-100.png"
          }
        }
      ]
    }
    ```

---

## 10. End-to-End Business Workflows

### Workflow 1: Tutor Onboarding & Subject Assignment
```
Admin Client                           Backend API                        Tutor App
    |                                       |                                 |
    |-- 1. POST /admin/signup-codes ------->|                                 |
    |      { role: "TUTOR" }                |                                 |
    |<-- 2. Returns { code: "EDU-TUTOR-.."}-|                                 |
    |                                       |                                 |
    |-- 3. (Deliver code securely to Tutor)---------------------------------->|
    |                                       |                                 |
    |                                       |<-- 4. POST /auth/register ------|
    |                                       |       { code, device_id, ... }  |
    |                                       |--- 5. Returns 201 + JWT -------->
    |                                       |                                 |
    |-- 6. PUT /admin/tutors/:id/subjects/..>|                                 |
    |      (Authorizes tutor to teach)      |                                 |
    |<-- 7. Returns 200 OK -----------------|                                 |
```

---

### Workflow 2: Course Publishing with Mandatory Lecture Quizzes
1. **Tutor creates course:** `POST /tutor/courses` (Must reference an authorized `subjectId`). Initial state: `published: false`.
2. **Tutor adds Lecture 1:** `POST /tutor/courses/:id/lectures` (`published: false`). Video count increments.
3. **Tutor attaches Lecture 1 Quiz:** `PUT /tutor/lectures/:id/quiz` with 5–100 questions (4 choices each, `passPercent: 100`).
4. **Tutor publishes Lecture 1:** `PATCH /tutor/lectures/:id` with `{ "published": true }`.
5. **Tutor publishes Course:** `PATCH /tutor/courses/:id` with `{ "published": true }`. The course is now discoverable on `GET /courses`.

---

### Workflow 3: Student Enrollment, Sequential Learning & Points
1. **Enrollment Grant:** Administrator verifies external student payment and executes `PUT /admin/students/:id/courses/:courseId`.
2. **Student views syllabus:** Student calls `GET /student/courses/:id/learning`. Lecture 1 is unlocked with video and quiz; Lecture 2 has `locked: true`.
3. **Lecture 1 Completion:** Student watches video and calls `POST /student/lectures/:id/quiz-attempts`.
4. **100% Score Validation:** Server validates answers. When score is 100%, server records `LectureProgress`, increments student `points` by 10, and sets `nextLectureUnlocked: true`.
5. **Lecture 2 Unlocked:** Subsequent calls to `GET /student/courses/:id/learning` now display Lecture 2 unlocked.

---

### Workflow 4: Temporary Desktop Session QR Handshake
```
Desktop Application                   Backend (HTTP / Socket)             Mobile Device
    |                                            |                              |
    |-- 1. POST /desktop/challenges ------------>|                              |
    |<-- 2. Returns { challenge, expiresAt } ----|                              |
    |                                            |                              |
    |-- 3. Socket.IO: desktop:subscribe --------->                              |
    |   4. Render QR with raw challenge string   |                              |
    |                                            |                              |
    |                                            |<-- 5. Scan QR & Authorize ---|
    |                                            |    POST /desktop/.../authorize
    |                                            |    (Sends Bearer + device-id)|
    |                                            |--- 6. Returns 200 OK -------->
    |                                            |                              |
    |<-- 7. Socket.IO push: { status: APPROVED }-|                              |
    |                                            |                              |
    |-- 8. POST /desktop/.../exchange ---------->|                              |
    |<-- 9. Returns Desktop JWT (sessionType) ---|                              |
    |                                            |                              |
    |-- 10. Normal API calls with Desktop JWT -->|                              |
    |   (No x-device-id required)                |                              |
    |                                            |                              |
    |-- 11. App close: DELETE /sessions/current ->|                              |
    |<-- 12. Returns 204 No Content (Revoked) ---|                              |
```

---

### Workflow 5: Lost Device Recovery Procedure
1. Student loses their mobile device and contacts the platform administrator.
2. Administrator invokes `POST /admin/users/:id/device-reset`.
3. Backend sets `deviceId = null`, increments `tokenVersion` (invalidating the stolen phone's JWT), and closes any open desktop session.
4. Student downloads app onto their new phone and submits `POST /auth/login` with their username, password, and the new phone's hardware identifier.
5. The backend atomically claims the new device ID. Future requests from the old device are denied with `403 DEVICE_MISMATCH`.
