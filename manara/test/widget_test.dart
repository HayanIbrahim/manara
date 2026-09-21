import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/network/api_exceptions.dart';
import 'package:manara/domain/entities/auth_entities.dart';
import 'package:manara/domain/entities/desktop_entities.dart';
import 'package:manara/domain/entities/quiz_entities.dart';
import 'package:manara/domain/repositories/auth_repository.dart';
import 'package:manara/domain/repositories/desktop_pairing_repository.dart';
import 'package:manara/domain/repositories/student_repository.dart';
import 'package:manara/domain/entities/course_entities.dart';
import 'package:manara/domain/entities/exam_entities.dart';
import 'package:manara/domain/entities/gamification_entities.dart';
import 'package:manara/presentation/blocs/auth/auth_bloc.dart';
import 'package:manara/presentation/blocs/auth/auth_event.dart';
import 'package:manara/presentation/blocs/auth/auth_state.dart';
import 'package:manara/presentation/blocs/desktop_pairing/desktop_pairing_bloc.dart';
import 'package:manara/presentation/blocs/desktop_pairing/desktop_pairing_event.dart';
import 'package:manara/presentation/blocs/desktop_pairing/desktop_pairing_state.dart';
import 'package:manara/presentation/blocs/quiz/quiz_bloc.dart';
import 'package:manara/presentation/blocs/quiz/quiz_event.dart';
import 'package:manara/presentation/blocs/quiz/quiz_state.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldFailMismatch = false;

  @override
  Future<String> getDeviceId() async => 'test_device_123456';

  @override
  Future<String?> getSavedToken() async => 'test_token';

  @override
  Future<UserEntity?> getCurrentUser() async => const UserEntity(
        id: 'user_1',
        username: 'teststudent',
        displayName: 'Test Student',
        role: UserRole.student,
      );

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    if (shouldFailMismatch) {
      throw const ApiException(
        message: 'Device mismatch. Contact Admin',
        code: 'DEVICE_MISMATCH',
        statusCode: 403,
      );
    }
    return const UserEntity(
      id: 'user_1',
      username: 'teststudent',
      displayName: 'Test Student',
      role: UserRole.student,
    );
  }

  @override
  Future<UserEntity> register({
    required String signupCode,
    required UserRole role,
    required String username,
    String? email,
    required String displayName,
    required String password,
    required String deviceId,
  }) async {
    return UserEntity(
      id: 'user_2',
      username: username,
      displayName: displayName,
      role: role,
    );
  }

  @override
  Future<void> logout() async {}
}

class MockStudentRepository implements StudentRepository {
  @override
  Future<List<CourseEntity>> getEnrolledCourses() async => [];

  @override
  Future<Map<String, dynamic>> getCourseLearningState(String courseId) async => {};

  @override
  Future<List<ExamSubmissionEntity>> getExamResults() async => [];

  @override
  Future<RatingEntity> rateCourse({required String courseId, required int value, String? comment}) async =>
      RatingEntity(value: value, comment: comment);

  @override
  Future<RatingEntity> rateTutor({required String tutorId, required int value, String? comment}) async =>
      RatingEntity(value: value, comment: comment);

  @override
  Future<ExamSubmissionEntity> submitExam({
    required String examId,
    required List<ExamAnswerEntity> answers,
    List<String> attachmentUrls = const [],
  }) async =>
      ExamSubmissionEntity(
        id: 'sub_1',
        examId: examId,
        studentId: 'stu_1',
        status: ExamSubmissionStatus.submitted,
        answers: answers,
      );

  @override
  Future<QuizAttemptResultEntity> submitQuizAttempt({
    required String lectureId,
    required List<int> answers,
  }) async {
    // Check if answers are all correct (choices == 0)
    final allCorrect = answers.every((a) => a == 0);
    return QuizAttemptResultEntity(
      score: allCorrect ? 100 : 60,
      correct: allCorrect ? 5 : 3,
      total: 5,
      passed: allCorrect,
      nextLectureUnlocked: allCorrect,
    );
  }
}

class MockDesktopPairingRepository implements DesktopPairingRepository {
  @override
  Future<DesktopChallengeEntity> createChallenge() async => DesktopChallengeEntity(
        challenge: 'chal_test_98765432101234567890',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

  @override
  Future<DesktopStatusEntity> getChallengeStatus(String challenge) async => DesktopStatusEntity(
        status: DesktopChallengeStatus.pending,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

  @override
  Future<DesktopStatusEntity> authorizeChallenge(String challenge) async => DesktopStatusEntity(
        status: DesktopChallengeStatus.approved,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

  @override
  Future<UserEntity> exchangeChallenge(String challenge) async => const UserEntity(
        id: 'desktop_user',
        username: 'desktop_user',
        displayName: 'Desktop User',
        role: UserRole.student,
      );

  @override
  Future<void> closeSession() async {}
}

void main() {
  group('Educational Platform Clean Architecture & Domain Tests', () {
    test('QuizAttemptResultEntity correctly evaluates 100% requirement', () {
      const passedResult = QuizAttemptResultEntity(
        score: 100,
        correct: 5,
        total: 5,
        passed: true,
        nextLectureUnlocked: true,
      );

      expect(passedResult.passed, isTrue);
      expect(passedResult.nextLectureUnlocked, isTrue);
      expect(passedResult.score, equals(100));

      const failedResult = QuizAttemptResultEntity(
        score: 80,
        correct: 4,
        total: 5,
        passed: false,
        nextLectureUnlocked: false,
      );

      expect(failedResult.passed, isFalse);
      expect(failedResult.nextLectureUnlocked, isFalse);
    });

    test('ApiException correctly identifies device mismatch errors', () {
      const exception = ApiException(
        message: 'Device mismatch. Contact Admin',
        code: 'DEVICE_MISMATCH',
        statusCode: 403,
      );

      expect(exception.isDeviceMismatch, isTrue);
      expect(exception.statusCode, equals(403));
    });

    test('UserEntity role getters match OpenAPI role expectations', () {
      const studentUser = UserEntity(
        id: '1',
        username: 'student1',
        displayName: 'John Doe',
        role: UserRole.student,
      );
      expect(studentUser.isStudent, isTrue);
      expect(studentUser.isTutor, isFalse);

      const tutorUser = UserEntity(
        id: '2',
        username: 'tutor1',
        displayName: 'Dr. Smith',
        role: UserRole.tutor,
      );
      expect(tutorUser.isTutor, isTrue);
      expect(tutorUser.isStudent, isFalse);
    });
  });

  group('BLoC Business Logic Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockStudentRepository mockStudentRepo;
    late MockDesktopPairingRepository mockDesktopRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockStudentRepo = MockStudentRepository();
      mockDesktopRepo = MockDesktopPairingRepository();
    });

    test('AuthBloc handles device mismatch and emits error state', () async {
      mockAuthRepo.shouldFailMismatch = true;
      final bloc = AuthBloc(mockAuthRepo);

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>((state) {
            return state is Unauthenticated &&
                state.isDeviceMismatch &&
                state.errorMessage == 'Device mismatch. Contact Admin';
          }),
        ]),
      );

      bloc.add(const AuthLoginSubmitted(username: 'student1', password: 'password123'));
    });

    test('QuizBloc enforces 100% pass threshold', () async {
      final bloc = QuizBloc(mockStudentRepo);

      const sampleQuiz = QuizEntity(
        id: 'q1',
        lectureId: 'lec_1',
        passPercent: 100,
        questions: [
          QuizQuestionEntity(prompt: 'Q1', choices: ['A', 'B', 'C', 'D'], correctChoice: 0),
          QuizQuestionEntity(prompt: 'Q2', choices: ['A', 'B', 'C', 'D'], correctChoice: 0),
          QuizQuestionEntity(prompt: 'Q3', choices: ['A', 'B', 'C', 'D'], correctChoice: 0),
          QuizQuestionEntity(prompt: 'Q4', choices: ['A', 'B', 'C', 'D'], correctChoice: 0),
          QuizQuestionEntity(prompt: 'Q5', choices: ['A', 'B', 'C', 'D'], correctChoice: 0),
        ],
      );

      bloc.add(const QuizInitializeRequested(lectureId: 'lec_1', quiz: sampleQuiz));
      await pumpEventQueue();

      expect(bloc.state, isA<QuizActive>());

      // Select all correct choices (0 for all 5)
      for (int i = 0; i < 5; i++) {
        bloc.add(QuizSelectChoiceRequested(questionIndex: i, choiceIndex: 0));
      }
      await pumpEventQueue();

      expect((bloc.state as QuizActive).isAllAnswered, isTrue);

      bloc.add(QuizSubmitAttemptRequested());
      await pumpEventQueue();

      expect(bloc.state, isA<QuizPassedSuccess>());
      expect((bloc.state as QuizPassedSuccess).result.passed, isTrue);
    });

    test('DesktopPairingBloc creates challenge and prepares polling', () async {
      final bloc = DesktopPairingBloc(mockDesktopRepo);

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DesktopPairingLoading>(),
          predicate<DesktopPairingState>((state) {
            return state is DesktopPairingWaitingForMobile &&
                state.challenge == 'chal_test_98765432101234567890';
          }),
        ]),
      );

      bloc.add(DesktopPairingCreateChallengeRequested());
    });

    test('ApiException handles 429 RateLimitException with retryAfter', () {
      const ex = RateLimitException(
        message: 'Rate limit exceeded',
        retryAfter: '45',
      );

      expect(ex.statusCode, 429);
      expect(ex.retryAfter, '45');
      expect(ex.code, 'RATE_LIMITED');
    });

    test('ValidationException holds fieldErrors correctly', () {
      const ex = ValidationException(
        message: 'Validation failed',
        fieldErrors: {
          'username': ['Username already taken'],
          'password': ['Too short'],
        },
      );

      expect(ex.statusCode, 422);
      expect(ex.fieldErrors?['username'], ['Username already taken']);
      expect(ex.fieldErrors?['password'], ['Too short']);
    });

    test('ServiceUnavailableException represents 503 registration retry required', () {
      const ex = ServiceUnavailableException(
        message: 'Transient database error. Please retry registration.',
        code: 'REGISTRATION_RETRY_REQUIRED',
      );

      expect(ex.statusCode, 503);
      expect(ex.code, 'REGISTRATION_RETRY_REQUIRED');
    });
  });
}
