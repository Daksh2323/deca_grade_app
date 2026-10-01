class SubjectModel {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final int totalChapters;
  final int completedChapters;

  SubjectModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.totalChapters = 0,
    this.completedChapters = 0,
  });

  double get progress {
    if (totalChapters == 0) return 0;
    return completedChapters / totalChapters;
  }
}
