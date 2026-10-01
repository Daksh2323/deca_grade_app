class UserModel {
  final String uid;
  final String name;
  final String email;
  final String userClass;
  final String board;
  final int streak;
  final int maxStreak;
  final int streakFreezes;
  final int xp;
  final String photoUrl;
  final List<String> badges;
  final DateTime? lastActive;
  final String? examDate;
  final int dailyGoal;
  final int dailyAiCount;
  final bool isPro;
  final bool isUltimate;
  final String? plan;
  final DateTime? expiryDate;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.userClass,
    required this.board,
    this.streak = 0,
    this.maxStreak = 0,
    this.streakFreezes = 0,
    this.xp = 0,
    this.photoUrl = '',
    this.badges = const [],
    this.lastActive,
    this.examDate,
    this.dailyGoal = 60,
    this.dailyAiCount = 0,
    this.isPro = false,
    this.isUltimate = false,
    this.plan,
    this.expiryDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Student',
      email: map['email']?.toString() ?? '',
      userClass: map['class']?.toString() ?? 'Class 10',
      board: map['board']?.toString() ?? 'CBSE',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      maxStreak: (map['maxStreak'] as num?)?.toInt() ?? 0,
      streakFreezes: (map['streakFreezes'] as num?)?.toInt() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl']?.toString() ?? '',
      badges: List<String>.from(map['badges'] ?? []),
      lastActive: map['lastActive']?.toDate(),
      examDate: map['examDate']?.toString(),
      dailyGoal: (map['dailyGoal'] as num?)?.toInt() ?? 60,
      dailyAiCount: (map['dailyAiCount'] as num?)?.toInt() ?? 0,
      isPro: map['isPro'] == true,
      isUltimate: map['isUltimate'] == true,
      plan: map['plan']?.toString(),
      expiryDate: map['expiryDate']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'class': userClass,
      'board': board,
      'streak': streak,
      'maxStreak': maxStreak,
      'streakFreezes': streakFreezes,
      'xp': xp,
      'photoUrl': photoUrl,
      'badges': badges,
      'lastActive': lastActive,
      'examDate': examDate,
      'dailyGoal': dailyGoal,
      'dailyAiCount': dailyAiCount,
      'isPro': isPro,
      'isUltimate': isUltimate,
      'plan': plan,
      'expiryDate': expiryDate,
    };
  }
}
