import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  final String id;
  final String title;
  final String description;
  final int chapterNumber;
  final int estimatedTime;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // Content fields
  final String fullNotes;
  final String shortNotes;
  final List<VideoLecture> videos;
  final List<PdfNote> pdfs;
  final List<String> formulas;
  final List<Flashcard> flashcards;
  final List<NcertSolution> ncertSolutions;
  final List<PyqQuestion> pyqs;

  ChapterModel({
    required this.id,
    required this.title,
    required this.description,
    required this.chapterNumber,
    this.estimatedTime = 45,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.fullNotes = '',
    this.shortNotes = '',
    this.videos = const [],
    this.pdfs = const [],
    this.formulas = const [],
    this.flashcards = const [],
    this.ncertSolutions = const [],
    this.pyqs = const [],
  });

  factory ChapterModel.fromMap(Map<String, dynamic> map, String id) {
    return ChapterModel(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      chapterNumber: (map['chapterNumber'] as num?)?.toInt() ?? 0,
      estimatedTime: (map['estimatedTime'] as num?)?.toInt() ?? 45,
      isPublished: map['isPublished'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      createdBy: map['createdBy'],
      fullNotes:
          map['fullNotes']?.toString() ??
          map['notesDetailed']?.toString() ??
          '',
      shortNotes:
          map['shortNotes']?.toString() ?? map['notesShort']?.toString() ?? '',
      videos:
          (map['videos'] as List?)
              ?.map((v) => VideoLecture.fromMap(v))
              .toList() ??
          [],
      pdfs:
          (map['pdfs'] as List?)?.map((p) => PdfNote.fromMap(p)).toList() ?? [],
      formulas: List<String>.from(map['formulas'] ?? []),
      flashcards:
          (map['flashcards'] as List?)
              ?.map((f) => Flashcard.fromMap(f))
              .toList() ??
          [],
      ncertSolutions:
          (map['ncertSolutions'] as List?)
              ?.map((n) => NcertSolution.fromMap(n))
              .toList() ??
          [],
      pyqs:
          (map['pyqs'] as List?)?.map((p) => PyqQuestion.fromMap(p)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'chapterNumber': chapterNumber,
      'estimatedTime': estimatedTime,
      'isPublished': isPublished,
      'fullNotes': fullNotes,
      'shortNotes': shortNotes,
      'videos': videos.map((v) => v.toMap()).toList(),
      'pdfs': pdfs.map((p) => p.toMap()).toList(),
      'formulas': formulas,
      'flashcards': flashcards.map((f) => f.toMap()).toList(),
      'ncertSolutions': ncertSolutions.map((n) => n.toMap()).toList(),
      'pyqs': pyqs.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// ═══ Video Lecture ═══
class VideoLecture {
  final String id;
  final String title;
  final String youtubeId;
  final String? description;
  final int duration;
  final int order;

  VideoLecture({
    required this.id,
    required this.title,
    required this.youtubeId,
    this.description,
    this.duration = 0,
    this.order = 0,
  });

  factory VideoLecture.fromMap(Map<String, dynamic> map) {
    return VideoLecture(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      description: map['description'],
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'youtubeId': youtubeId,
      'description': description,
      'duration': duration,
      'order': order,
    };
  }

  // Extract YouTube ID from URL
  static String? extractYoutubeId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    return regExp.firstMatch(url)?.group(1);
  }
}

// ═══ PDF Note ═══
class PdfNote {
  final String id;
  final String title;
  final String url;
  final String? description;
  final int sizeKB;
  final int order;

  PdfNote({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.sizeKB = 0,
    this.order = 0,
  });

  factory PdfNote.fromMap(Map<String, dynamic> map) {
    return PdfNote(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      description: map['description'],
      sizeKB: (map['sizeKB'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'sizeKB': sizeKB,
      'order': order,
    };
  }
}

// ═══ Flashcard ═══
class Flashcard {
  final String front;
  final String back;
  final String difficulty;

  Flashcard({
    required this.front,
    required this.back,
    this.difficulty = 'medium',
  });

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {'front': front, 'back': back, 'difficulty': difficulty};
  }
}

// ═══ NCERT Solution ═══
class NcertSolution {
  final String questionNumber;
  final String question;
  final String solution;
  final int marks;

  NcertSolution({
    required this.questionNumber,
    required this.question,
    required this.solution,
    this.marks = 1,
  });

  factory NcertSolution.fromMap(Map<String, dynamic> map) {
    return NcertSolution(
      questionNumber: map['questionNumber'] ?? '',
      question: map['question'] ?? '',
      solution: map['solution'] ?? '',
      marks: (map['marks'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'question': question,
      'solution': solution,
      'marks': marks,
    };
  }
}

// ═══ Previous Year Question ═══
class PyqQuestion {
  final String question;
  final String solution;
  final int year;
  final int marks;
  final String difficulty;
  final String? board;

  PyqQuestion({
    required this.question,
    required this.solution,
    required this.year,
    this.marks = 1,
    this.difficulty = 'medium',
    this.board,
  });

  factory PyqQuestion.fromMap(Map<String, dynamic> map) {
    return PyqQuestion(
      question: map['question'] ?? '',
      solution: map['solution'] ?? '',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      marks: (map['marks'] as num?)?.toInt() ?? 1,
      difficulty: map['difficulty'] ?? 'medium',
      board: map['board'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'solution': solution,
      'year': year,
      'marks': marks,
      'difficulty': difficulty,
      'board': board,
    };
  }
}
