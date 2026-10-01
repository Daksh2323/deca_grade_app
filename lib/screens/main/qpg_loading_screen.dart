import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';
import 'qpg_result_screen.dart';

class QpgLoadingScreen extends StatefulWidget {
  final String subject;
  final String subjectId;
  final List<String> chapters;
  final String schoolName;
  final String examName;
  final int mcqCount;
  final int arCount;
  final int twoMarkCount;
  final int threeMarkCount;
  final int fiveMarkCount;
  final int caseCount;

  const QpgLoadingScreen({
    super.key,
    required this.subject,
    required this.subjectId,
    required this.chapters,
    required this.schoolName,
    required this.examName,
    required this.mcqCount,
    required this.arCount,
    required this.twoMarkCount,
    required this.threeMarkCount,
    required this.fiveMarkCount,
    required this.caseCount,
  });

  @override
  State<QpgLoadingScreen> createState() => _QpgLoadingScreenState();
}

class _QpgLoadingScreenState extends State<QpgLoadingScreen> {
  Timer? _progressTimer;
  int _progress = 5;
  String _currentMessage = 'Connecting to Air AI Core...';
  bool _hasError = false;

  final List<Map<String, dynamic>> _statusSteps = [
    {
      'threshold': 15,
      'msg': 'Air is researching 2024-25 CBSE Sample Papers...',
    },
    {
      'threshold': 35,
      'msg': 'Analyzing PYQs and marking distribution trends...',
    },
    {
      'threshold': 55,
      'msg': 'Draft-building Section A (MCQs and Assertion-Reason)...',
    },
    {
      'threshold': 75,
      'msg': 'Constructing Sections B, C and D (Short and Long Answers)...',
    },
    {
      'threshold': 90,
      'msg': 'Formulating Section E Case Studies and Answer Key...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startContinuousProgressTimer();
    _triggerBackendGeneration();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startContinuousProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || _progress >= 95 || _hasError) return;
      setState(() {
        _progress += 1;
        for (final step in _statusSteps) {
          if (_progress == step['threshold']) {
            _currentMessage = step['msg'] as String;
          }
        }
      });
    });
  }

  String _getBackendUrl() {
    return '${ApiConfig.backendBaseUrl}/api/generate/question-paper';
  }

  Future<void> _triggerBackendGeneration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in again to generate a paper.');
      }
      final token = await user.getIdToken().timeout(
        const Duration(seconds: 15),
      );
      if (token == null || token.isEmpty) {
        throw Exception('Please sign in again to generate a paper.');
      }
      final backendUrl = _getBackendUrl();
      debugPrint('QPG request: POST $backendUrl');
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'subject': widget.subject,
              'chapters': widget.chapters,
              'school_name': widget.schoolName,
              'exam_name': widget.examName,
              'mcq_count': widget.mcqCount,
              'ar_count': widget.arCount,
              'two_mark_count': widget.twoMarkCount,
              'three_mark_count': widget.threeMarkCount,
              'five_mark_count': widget.fiveMarkCount,
              'case_count': widget.caseCount,
            }),
          )
          .timeout(const Duration(minutes: 5));
      if (response.statusCode != 200) {
        String detail = response.body.trim();
        if (detail.length > 240) {
          detail = '${detail.substring(0, 240)}...';
        }
        throw Exception(
          'Backend returned ${response.statusCode}${detail.isEmpty ? '' : ': $detail'}',
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _progress = 100;
          _currentMessage = 'Question Paper and Answer Key Ready!';
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final paperData = decoded['data'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QpgResultScreen(
            subject: widget.subject,
            chapters: widget.chapters,
            totalMarks: (decoded['total_marks'] as num?)?.toInt() ?? 80,
            paperData: paperData is Map
                ? Map<String, dynamic>.from(paperData)
                : <String, dynamic>{},
          ),
        ),
      );
    } catch (exception) {
      debugPrint('Generation error: $exception');
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _currentMessage = exception.toString().replaceFirst(
            'Exception: ',
            '',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 140,
                height: 140,
                child: SvgMascot(
                  type: MascotType.aria,
                  size: 140,
                  animate: true,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _hasError ? 'Generation Error' : 'Air is Drafting Your Paper',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _currentMessage,
                  key: ValueKey(_currentMessage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _hasError ? AppColors.error : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_hasError) ...[
                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_progress%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ] else
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
