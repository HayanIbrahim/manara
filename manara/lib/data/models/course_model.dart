import '../../domain/entities/course_entities.dart';
import 'quiz_model.dart';

class SubjectModel extends SubjectEntity {
  const SubjectModel({
    required super.id,
    required super.name,
    super.description,
    super.imageUrl,
    super.createdAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class LectureModel extends LectureEntity {
  const LectureModel({
    required super.id,
    required super.courseId,
    required super.title,
    super.description,
    required super.position,
    required super.videoUrl,
    super.pdfUrls = const [],
    super.points = 10,
    super.published = true,
    super.locked = false,
    super.quiz,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    QuizModel? quizModel;
    if (json['quiz'] is Map<String, dynamic>) {
      quizModel = QuizModel.fromJson(json['quiz'] as Map<String, dynamic>);
    }

    return LectureModel(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      position: (json['position'] as num?)?.toInt() ?? 1,
      videoUrl: json['videoUrl']?.toString() ?? '',
      pdfUrls: (json['pdfUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      points: (json['points'] as num?)?.toInt() ?? 10,
      published: json['published'] == true,
      locked: json['locked'] == true,
      quiz: quizModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'position': position,
      'videoUrl': videoUrl,
      'pdfUrls': pdfUrls,
      'points': points,
      'published': published,
      'locked': locked,
      if (quiz is QuizModel) 'quiz': (quiz as QuizModel).toJson(),
    };
  }
}

class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.price,
    required super.tutorId,
    required super.subjectId,
    super.published = true,
    super.videoCount = 0,
    super.ratingAverage = 0.0,
    super.ratingCount = 0,
    super.tutorName,
    super.subject,
    super.isEnrolled = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      if (json['price'] is num) {
        parsedPrice = (json['price'] as num).toDouble();
      } else {
        parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
      }
    }

    String? tutorDisplayName;
    if (json['tutor'] is Map<String, dynamic>) {
      tutorDisplayName = json['tutor']['displayName']?.toString() ?? json['tutor']['username']?.toString();
    }

    SubjectModel? subjectModel;
    if (json['subject'] is Map<String, dynamic>) {
      subjectModel = SubjectModel.fromJson(json['subject'] as Map<String, dynamic>);
    }

    return CourseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      price: parsedPrice,
      tutorId: json['tutorId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      published: json['published'] != false,
      videoCount: (json['videoCount'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      tutorName: tutorDisplayName,
      subject: subjectModel,
      isEnrolled: json['isEnrolled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'tutorId': tutorId,
      'subjectId': subjectId,
      'published': published,
      'videoCount': videoCount,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'isEnrolled': isEnrolled,
    };
  }
}

class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}

class CoursePageModel {
  final List<CourseModel> items;
  final PaginationModel pagination;

  const CoursePageModel({
    required this.items,
    required this.pagination,
  });

  factory CoursePageModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final pagination = json['pagination'] is Map<String, dynamic>
        ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
        : const PaginationModel(page: 1, limit: 20, total: 0, pages: 0);

    return CoursePageModel(items: itemsList, pagination: pagination);
  }
}
