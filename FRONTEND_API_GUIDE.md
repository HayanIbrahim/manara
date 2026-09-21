# Frontend API integration guide

**API version:** v1  
**Local API base:** `http://localhost:3000/api/v1`  
**Health URL:** `http://localhost:3000/health`  
**Socket.IO URL:** `http://localhost:3000`  
**Coverage:** all 50 implemented HTTP operations, plus the desktop Socket.IO events.

This is the handoff guide for the admin, tutor, student, catalog, and desktop
clients. Paths below are relative to the API base unless `/health` is shown.
For detailed validation rules and example responses, see
[the endpoint specification](./api_documentation.md). For an importable contract,
use [OpenAPI 3.1](./openapi.yaml). The implementation in `src/routes`,
`src/controllers`, and `src/schemas.js` is the final source of truth.

## 1. Connect and authenticate

- Send and receive JSON for requests with bodies. The server accepts a maximum
  JSON body of 1 MiB. A successful `204` response has no body.
- MongoDB IDs are 24-character hexadecimal strings. Dates are serialized as
  ISO 8601 strings. Optional database values can be `null`.
- The server does not use an authentication cookie. Protected requests need
  `Authorization: Bearer <accessToken>`.
- Registration requires `device_id` in the JSON body. Mobile student and tutor
  requests after login need the same value in the `x-device-id` header. Admin
  and desktop sessions do not need that header.
- `POST /auth/login` accepts the device ID in either the `x-device-id` header
  or body `device_id`; the header takes precedence. After an admin device reset,
  the next successful login binds that device ID.
- Auth and registration responses contain `{ accessToken, tokenType, user }`.
  Call `GET /auth/me` to obtain `sessionType` (`admin`, `mobile`, or `desktop`).
  There is no refresh-token endpoint. The default admin/mobile access-token
  lifetime is 15 minutes (`JWT_ACCESS_TTL`); the desktop JWT defaults to 8 hours
  (`JWT_DESKTOP_TTL`) and also depends on the live desktop session.
- The configured CORS origins are in `CORS_ORIGINS`; the example environment
  allows `http://localhost:5173` and `http://localhost:5174`.

The `user` object includes `id`, `username`, nullable `email`, `displayName`,
`role`, `status`, `points`, `createdAt`, `updatedAt`, and `deviceBound`.
Password hashes, the raw device ID, and token version are excluded.

### Minimal TypeScript request helper

```ts
const API_BASE = 'http://localhost:3000/api/v1';

type ApiErrorBody = {
  error: { code: string; message: string; details?: unknown };
};

class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
    public retryAfter?: string | null,
  ) {
    super(message);
  }
}

async function api<T>(
  path: string,
  options: RequestInit = {},
  accessToken?: string,
  mobileDeviceId?: string,
): Promise<T> {
  const headers = new Headers(options.headers);
  if (options.body !== undefined) headers.set('Content-Type', 'application/json');
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  if (mobileDeviceId) headers.set('x-device-id', mobileDeviceId);

  const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (response.status === 204) return undefined as T;

  const contentType = response.headers.get('content-type') ?? '';
  const body = contentType.includes('application/json')
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    const error = typeof body === 'object' && body !== null
      ? (body as ApiErrorBody).error
      : undefined;
    throw new ApiError(
      response.status,
      error?.code ?? `HTTP_${response.status}`,
      error?.message ?? String(body),
      error?.details,
      response.headers.get('retry-after'),
    );
  }
  return body as T;
}

// Body keys are camelCase except the intentionally named device_id.
const login = await api<{ accessToken: string; tokenType: 'Bearer'; user: unknown }>(
  '/auth/login',
  { method: 'POST', body: JSON.stringify({ username, password }) },
  undefined,
  deviceId,
);
```

Handle `401 INVALID_TOKEN` and `401 SESSION_REVOKED` by clearing the current
session and showing login. `400 DEVICE_ID_REQUIRED` means a protected mobile
request omitted the header. `403 DEVICE_MISMATCH` means the account is bound to
a different device; direct the user to the admin device-reset flow.

## 2. Responses, errors, and limits

Most application errors have this shape:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "formErrors": [],
      "fieldErrors": { "username": ["Too small: expected string to have >=3 characters"] }
    }
  }
}
```

Render `details.fieldErrors` next to form fields. Use `error.code` for workflow
decisions and `message` as a fallback display string. Common status meanings:

- `400`: missing device ID or invalid workflow input.
- `401`: missing, expired, invalid, or revoked Bearer token; also invalid login.
- `403`: role, device, enrollment, or ownership restriction.
- `404`: absent resource or inaccessible owned resource.
- `409`: duplicate record or conflicting state.
- `422`: schema validation or an invalid quiz/exam answer set.
- `429`: rate limited. **This response is currently a plain string with
  `text/html` content type**, not the JSON error envelope. Use the HTTP status
  and `Retry-After` header when provided.
- `503 REGISTRATION_RETRY_REQUIRED`: retry the exact same signup payload.

The three authentication POST routes share a limit of 20 requests per 15
minutes. Challenge creation, status polling, and exchange share 30 requests per
minute. These limits are applied by the server middleware, typically per IP.
Do not poll the QR status endpoint every second; use Socket.IO and poll as a
fallback at a modest interval. Empty lists return `{ "items": [] }`. The
public course search additionally returns a `pagination` object.

## 3. Endpoint reference

Each item gives the successful response and the body or query inputs the UI
must supply. Unless a route says otherwise, `POST` and `PATCH` bodies are JSON.
The full field constraints are in [the endpoint specification](./api_documentation.md)
and [OpenAPI schemas](./openapi.yaml).

### System and authentication

- `GET /health` — Public, server root. Returns `200 { status: "ok", service }`.
- `POST /auth/admin/login` — Public. Body: `username`, `password` (at least 8
  characters). Returns `200 { accessToken, tokenType, user }` for an admin.
- `POST /auth/register` — Public. Body: `signupCode`, `role` (`STUDENT` or
  `TUTOR`), `username`, optional `email`, `displayName`, `password` (at least 10
  characters), and `device_id` (16–256 characters). Returns `201` with auth
  data; a retry by the same username, email, password, and device returns `200`
  (the display name may differ). A code used by another account returns
  `409 SIGNUP_CODE_ALREADY_USED`. A used code with no linked account returns
  `409 SIGNUP_CODE_ACCOUNT_MISSING`; ask the admin for a fresh code.
- `POST /auth/login` — Public. Body: `username`, `password`, and either body
  `device_id` or header `x-device-id`. Returns `200` with auth data for a student
  or tutor. Wrong credentials return `401 INVALID_CREDENTIALS`; a different
  device returns `403 DEVICE_MISMATCH`.
- `GET /auth/me` — Any valid admin, tutor, or student session. Returns
  `200 { user, sessionType }`.

### Desktop QR session

- `POST /desktop/challenges` — Public; no body. Returns `201 { challenge,
  expiresAt }`. Default challenge lifetime: 180 seconds. Encode the exact raw
  `challenge` string in the QR code.
- `GET /desktop/challenges/:challenge/status` — Public. Returns `200 { status,
  expiresAt }`; status is `PENDING`, `APPROVED`, `CONSUMED`, `CLOSED`, or
  `EXPIRED`. An unknown challenge returns `404 CHALLENGE_NOT_FOUND`.
- `POST /desktop/challenges/:challenge/authorize` — Student or tutor Bearer
  token; mobile sessions also send `x-device-id`. No body. Returns `200 {
  status: "APPROVED", expiresAt }`. A challenge that is expired or no longer
  pending returns `409 CHALLENGE_NOT_PENDING`.
- `POST /desktop/challenges/:challenge/exchange` — Public; no body. Call after
  approval. Returns `200 { accessToken, tokenType, user, expiresAt }`. An
  unapproved, expired, or already consumed challenge normally returns
  `409 CHALLENGE_NOT_APPROVED`.
- `DELETE /desktop/sessions/current` — Desktop Bearer token. Returns `204`.
  Send on logout or window teardown; closing the app without this call leaves
  the session valid until expiry. A non-desktop token returns
  `403 DESKTOP_TOKEN_REQUIRED`.

The Socket.IO client connects to the server root, emits
`desktop:subscribe` with `{ challenge }`, and receives an acknowledgement of
`{ ok: true }` or `{ ok: false, error: "INVALID_CHALLENGE" }`. The server sends
`desktop:status` with `{ status: "APPROVED" }` or `{ status: "CONSUMED" }`.
Use `desktop:unsubscribe` with `{ challenge }` when leaving the QR screen.
The raw challenge is the subscription value; do not hash it in the client.

### Public catalog

- `GET /subjects` — Public. Returns `200 { items: Subject[] }`, sorted by name.
- `GET /courses` — Public. Optional query: `q`, `subjectId`, `tutorId`, `page`
  (default 1), `limit` (default 20, capped at 100). Returns `200 { items:
  Course[], pagination: { page, limit, total, pages } }`. Only published
  courses are listed, newest first. `q` searches course name, subject name,
  and tutor display name.
- `GET /courses/:id` — Public. Returns `200` with a published course and the
  public `lectures` outline (`id`, `title`, `position`). It does not include
  protected video, PDF, or quiz content. Missing or unpublished courses return
  `404 COURSE_NOT_FOUND`.
- `GET /tutors/:id` — Public. Returns `200` with an active tutor's public
  profile, published `courses`, `tutorRatings`, `ratingAverage`, and
  `ratingCount`. Otherwise `404 TUTOR_NOT_FOUND`.
- `GET /leaderboard` — Public. Returns `200 { items: [{ rank, id,
  displayName, points }] }` for the top 100 active students.

### Admin

All admin endpoints require an admin Bearer token. There is no admin-specific
device header.

- `GET /admin/subjects` — Returns `200 { items: Subject[] }`.
- `POST /admin/subjects` — Body: `name`, optional `description`, `imageUrl`.
  Returns `201 Subject`.
- `PATCH /admin/subjects/:id` — Body: at least one of `name`, `description`,
  `imageUrl`; the latter two accept `null` to clear them. Returns `200 Subject`.
- `DELETE /admin/subjects/:id` — Returns `204`. Referenced subjects return
  `409 SUBJECT_IN_USE`.
- `GET /admin/signup-codes` — Returns `200 { items: SignupCodeMetadata[] }`.
  Metadata includes role, expiry, and use status; plaintext codes are absent.
- `POST /admin/signup-codes` — Body: `role` (`STUDENT` or `TUTOR`) and optional
  `expiresInHours` (1–720, default 72). Returns `201 { id, code, role,
  expiresAt }`. The plaintext `code` is shown only in this response.
- `GET /admin/users` — Optional query: `role`, `status`, `search`. Returns
  `200 { items: User[] }`, newest first, maximum 100; no pagination endpoint.
- `PATCH /admin/users/:id/status` — Body: `{ "status": "ACTIVE" }` or
  `DEACTIVATED`. Returns `200 User`. It revokes existing tokens; an admin
  cannot update their own status here (`400 CANNOT_DEACTIVATE_SELF`).
- `POST /admin/users/:id/device-reset` — No body. Returns `200 User` with
  `deviceBound: false`; it revokes tokens and closes desktop sessions.
- `PUT /admin/tutors/:id/subjects/:subjectId` — No body. Returns `200
  TutorSubject`; repeat calls keep the assignment.
- `DELETE /admin/tutors/:id/subjects/:subjectId` — Returns `204`; removing a
  nonexistent assignment returns a not-found error.
- `PUT /admin/students/:id/courses/:courseId` — No body. Returns `200
  Enrollment` and grants or reactivates access.
- `DELETE /admin/students/:id/courses/:courseId` — Returns `204`; it marks
  the enrollment inactive, and a missing enrollment returns a not-found error.
- `GET /admin/announcements` — Returns `200 { items: Announcement[] }`, newest
  first.
- `POST /admin/announcements` — Body: `title`, `body`, `audience` (`ALL`,
  `COURSE`, `STUDENTS`), optional `courseIds`, `studentIds`, `expiresAt`.
  `COURSE` requires at least one course ID; `STUDENTS` requires at least one
  student ID. Returns `201 Announcement`.

### Tutor

All tutor endpoints require a tutor Bearer token and, for a mobile session,
the matching `x-device-id` header.

- `GET /tutor/courses` — Returns `200 { items: Course[] }` with each course's
  subject, newest first. This includes the tutor's unpublished courses.
- `POST /tutor/courses` — Body: `name`, `description`, `imageUrl`, `price`
  (nonnegative), `subjectId`, optional `published` (default false). Returns
  `201 Course`. The tutor needs an admin subject assignment or receives
  `403 SUBJECT_NOT_ASSIGNED`.
- `PATCH /tutor/courses/:id` — Body: at least one of `name`, `description`,
  `imageUrl`, `price`, `published`. Returns `200 Course`; other tutors' courses
  return `404 COURSE_NOT_FOUND`.
- `POST /tutor/courses/:id/lectures` — Body: `title`, `position` (positive
  integer, unique in course), `videoUrl`, optional `description`, `pdfUrls`
  (maximum 20), `points` (0–1000, default 10), `published` (must be false).
  Returns `201 Lecture`. Attach a quiz before publishing the lecture.
- `PATCH /tutor/lectures/:id` — Body: at least one of `title`, `description`,
  `position`, `videoUrl`, `pdfUrls`, `points`, `published`. Returns `200 Lecture`.
  Publishing without a quiz returns `409 QUIZ_REQUIRED_BEFORE_PUBLISH`.
- `DELETE /tutor/lectures/:id` — Returns `204` and removes the lecture.
- `PUT /tutor/lectures/:id/quiz` — Body: `questions` (5–100); each question
  needs `prompt`, four `choices`, and zero-based `correctChoice` (`0`–`3`).
  Returns `200 Quiz`, creating or replacing it. Passing requires 100%.
- `POST /tutor/courses/:id/exams` — Body: `title`, `questions` (at least one),
  optional `instructions`, `points` (default 50), `published` (default false).
  A question has a stable `id`, `prompt`, `type`, optional `imageUrls`, and,
  for `MULTIPLE_CHOICE`, four `choices` plus `correctChoice`. `WRITTEN`
  questions omit those choice fields. Returns `201 Exam`.
- `PATCH /tutor/exams/:id` — Body: at least one of `title`, `instructions`,
  `points`, `published`, `questions`. Returns `200 Exam`.
- `GET /tutor/exams/:id/submissions` — Returns `200 { items:
  ExamSubmission[] }`, including each student's `id`, `displayName`, and
  `username`, ordered by submission time.
- `PATCH /tutor/submissions/:id/grade` — Body: `score` (`0`–`100`), optional
  `feedback`, `publish` (default false). Returns `200 ExamSubmission`.
  `publish: true` makes it visible in student results and awards the exam's
  points once per student and exam.

### Student

All student endpoints require a student Bearer token and, for a mobile
session, the matching `x-device-id` header.

- `GET /student/courses` — Returns `200 { items: Course[] }` for active
  enrollments, with `grantedAt`, subject, and tutor.
- `GET /student/courses/:id/learning` — Returns `200 { course }` with published
  lectures and exams. Requires an active enrollment (`403
  COURSE_ACCESS_REQUIRED`). Locked lectures expose only `id`, `title`,
  `position`, and `locked: true`. Unlocked lectures include media URLs, a
  redacted quiz, and `progress` (possibly `null`). Exam and quiz questions
  omit `correctChoice`. Published lectures are ordered by `position`.
- `POST /student/lectures/:id/quiz-attempts` — Body: `{ "answers": [0, 2,
  1, 3, 0] }`, one zero-based choice index per quiz question. Returns `200 {
  score, correct, total, passed, nextLectureUnlocked, progress }`.
  `ANSWER_COUNT_MISMATCH` is `422`; a locked lecture returns `403
  LECTURE_LOCKED`. A 100% score completes the lecture and awards its points
  once. `nextLectureUnlocked` mirrors `passed`, including on the final lecture;
  reload the learning view to determine the next visible lecture.
- `POST /student/exams/:id/submissions` — Body: `answers` with exactly one
  `{ questionId, choice }` for each multiple-choice question or `{ questionId,
  text }` for each written question; optional `attachmentUrls` (maximum 20).
  Returns `201 ExamSubmission` with `status: "SUBMITTED"`. Duplicate
  submission is a conflict; malformed answer sets return `422
  INVALID_EXAM_ANSWERS`.
- `GET /student/exam-results` — Returns `200 { items: ExamSubmission[] }`
  including exam and course labels. Only `PUBLISHED` submissions appear.
- `PUT /student/ratings/course/:id` — Body: `value` (integer `1`–`5`),
  optional `comment` (maximum 2000 characters). Returns `200 CourseRating`;
  repeat calls update the same rating. Requires active enrollment.
- `PUT /student/ratings/tutor/:id` — Same rating body. Returns `200
  TutorRating`; requires active enrollment in a course taught by that tutor.
- `GET /student/announcements` — Returns `200 { items: Announcement[] }` for
  nonexpired `ALL`, directly targeted `STUDENTS`, and enrolled `COURSE`
  announcements, newest first.
- `GET /student/achievements` — Returns `200 { items: [{ id, studentId,
  achievementId, awardedAt, achievement }] }`. Eligible point-threshold
  achievements are synced before responding.

## 4. Frontend workflows

### Signup and account recovery

1. An admin creates a role-specific code with `POST /admin/signup-codes` and
   delivers the returned plaintext code to one intended user. Create a separate
   code for each student; codes are never shared or reused.
2. The mobile client generates and stores a stable installation ID, then sends
   it as `device_id` in `POST /auth/register`.
3. Store the returned access token for this session. Send the stored
   installation ID as `x-device-id` on future protected mobile requests.
4. When a token expires, show login; there is no refresh endpoint. If an admin
   resets the device, login with username, password, and the new device ID.
5. If registration returns `SIGNUP_CODE_ALREADY_USED` or
   `SIGNUP_CODE_ACCOUNT_MISSING`, request a fresh code from the admin. An
   identical retry by the original account can return `200` after a lost
   response. Check the `error.code` field, not the English error message.

### Publish a course and start learning

1. Admin assigns a subject to the tutor and grants course access to a student
   using the corresponding `PUT` endpoints.
2. Tutor creates a course, creates an unpublished lecture, attaches its quiz,
   publishes the lecture, then publishes the course.
3. Student loads `GET /student/courses/:id/learning`. Display the locked
   lecture items as navigation only; do not assume media fields exist there.
4. Submit the quiz answers. On a pass, reload the learning view to display
   updated progress and the next unlocked lecture.
5. After exam submission, show the submitted state. Display score and feedback
   only after the tutor publishes a grade and it appears in exam results.

### Desktop QR login

1. Desktop creates a challenge, shows its raw string as a QR code, and
   subscribes with Socket.IO. Use status polling as a fallback.
2. The signed-in student or tutor scans the QR and calls the authorize route.
3. On `APPROVED`, desktop exchanges the challenge exactly once and stores the
   returned desktop token for subsequent protected requests.
4. On logout or teardown, call the session delete route, clear the token, and
   unsubscribe from the Socket.IO room.

The API accepts URL references for videos, PDFs, exam attachments, and images.
It does not provide a file-upload endpoint; upload and hosting are handled by
another service chosen by the product team.
