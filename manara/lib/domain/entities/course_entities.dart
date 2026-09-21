import 'package:equatable/equatable.dart';
import 'quiz_entities.dart';

class SubjectEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  const SubjectEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, imageUrl, createdAt];
}

class LectureEntity extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int position;
  final String videoUrl;
  final List<String> pdfUrls;
  final int points;
  final bool published;
  final bool locked;
  final QuizEntity? quiz;

  const LectureEntity({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.position,
    required this.videoUrl,
    this.pdfUrls = const [],
    this.points = 10,
    this.published = true,
    this.locked = false,
    this.quiz,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        title,
        description,
        position,
        videoUrl,
        pdfUrls,
        points,
        published,
        locked,
        quiz,
      ];
}

class CourseEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String tutorId;
  final String subjectId;
  final bool published;
  final int videoCount;
  final double ratingAverage;
  final int ratingCount;
  final String? tutorName;
  final SubjectEntity? subject;
  final bool isEnrolled;

  const CourseEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.tutorId,
    required this.subjectId,
    this.published = true,
    this.videoCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.tutorName,
    this.subject,
    this.isEnrolled = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        price,
        tutorId,
        subjectId,
        published,
        videoCount,
        ratingAverage,
        ratingCount,
        tutorName,
        subject,
        isEnrolled,
      ];
}
