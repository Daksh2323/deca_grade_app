import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import 'qpg_result_screen.dart';

class PaperHistoryScreen extends StatefulWidget {
  const PaperHistoryScreen({super.key});

  @override
  State<PaperHistoryScreen> createState() => _PaperHistoryScreenState();
}

class _PaperHistoryScreenState extends State<PaperHistoryScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _firestore.getPaperHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await _firestore.deletePaperHistory(id);
    if (mounted) _loadHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Paper History',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : _history.isEmpty
        ? const Center(
            child: Text(
              'No generated papers found yet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _history.length,
            itemBuilder: (_, index) {
              final item = _history[index];
              final subject = item['subject']?.toString() ?? 'Subject';
              final marks = item['totalMarks'] ?? 0;
              final data = item['paperData'] is Map
                  ? Map<String, dynamic>.from(item['paperData'])
                  : <String, dynamic>{};
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '$marks Marks - Class 10 CBSE',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () => _delete(item['id'].toString()),
                  ),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QpgResultScreen(
                          subject: subject,
                          chapters: List<String>.from(
                            item['chapters'] ?? const [],
                          ),
                          totalMarks: marks is num ? marks.toInt() : 0,
                          paperData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
  );
}
