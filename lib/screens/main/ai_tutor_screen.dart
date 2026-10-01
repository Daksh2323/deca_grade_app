import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/chat_message.dart';
import '../../services/gemini_service.dart';
import '../../services/analytics_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/quick_prompts.dart';
import 'math_solver_screen.dart';
// import 'voice_tutor_screen.dart'; // Hidden for now

class AITutorScreen extends StatefulWidget {
  const AITutorScreen({super.key});

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  final List<ChatMessage> _messages = [];
  String? _selectedSubject;
  bool _isTyping = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: '1',
        text:
            'Hi! I\'m Air ✨ Your 24/7 AI study buddy.\n\n'
            'Ask me anything about your studies — I\'m here to help!\n\n'
            'Try asking me about:\n'
            '• Math problems 🔢\n'
            '• Science concepts 🔬\n'
            '• English literature 📚\n'
            '• Any doubt in your syllabus 💡',
        sender: MessageSender.aria,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _messageController.text.trim();
    final imageBytes = _selectedImageBytes;
    if ((text.isEmpty && imageBytes == null) || _isTyping) return;

    if (imageBytes != null) {
      if (!await _canUseImageSolve()) return;
    } else if (!await _canUseAi()) {
      return;
    }

    HapticFeedback.lightImpact();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
          imageBytes: imageBytes,
        ),
      );
      _selectedImageBytes = null;
      _isTyping = true;
    });
    _scrollToBottom();

    final loadingId = '${DateTime.now().millisecondsSinceEpoch}_loading';
    setState(() {
      _messages.add(
        ChatMessage(
          id: loadingId,
          text: imageBytes == null ? '' : 'Air is analyzing your image...',
          sender: MessageSender.aria,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        ),
      );
    });
    _scrollToBottom();

    try {
      unawaited(_logAiChatAnalytics());
      final response = imageBytes != null
          ? await _geminiService.solveWithImage(
              imageBytes: imageBytes,
              subject: _getSubjectName(_selectedSubject),
              customPrompt: text.isEmpty ? null : text,
            )
          : await _geminiService.sendMessage(
              text,
              subject: _getSubjectName(_selectedSubject),
            );

      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == loadingId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: response,
            status: MessageStatus.sent,
          );
        }
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e, stack) {
      unawaited(CrashReportingService.instance.recordNonFatal(e, stack));
      unawaited(CrashReportingService.instance.breadcrumb('AI request failed'));
      String errorMessage;
      final errStr = e.toString();

      if (errStr.contains('API_KEY_MISSING')) {
        errorMessage =
            '🔑 API Key Missing!\n\n'
            'Please add your Gemini API key in:\n'
            'lib/config/api_config.dart\n\n'
            'Get free key at:\n'
            'aistudio.google.com/apikey';
      } else if (errStr.contains('API_KEY_INVALID')) {
        errorMessage =
            '❌ Invalid API Key!\n\n'
            'Your Gemini API key is incorrect.\n'
            'Please verify it at:\n'
            'aistudio.google.com/apikey';
      } else if (errStr.contains('QUOTA_EXCEEDED')) {
        errorMessage =
            '⏳ Rate Limit Reached!\n\n'
            'You have used your free quota.\n'
            'Please wait a minute and try again.';
      } else if (errStr.contains('MODEL_ERROR')) {
        errorMessage =
            '🤖 Model Not Available!\n\n'
            'Try changing model in api_config.dart to:\n'
            '• gemini-1.5-flash\n'
            '• gemini-pro\n\n'
            'Error: $errStr';
      } else if (errStr.contains('NETWORK') ||
          errStr.contains('SocketException')) {
        errorMessage =
            '📡 No Internet!\n\n'
            'Please check your internet connection\n'
            'and try again.';
      } else {
        errorMessage =
            '😔 Something went wrong!\n\n'
            'Error details:\n$errStr\n\n'
            'Check console for more info.';
      }

      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == loadingId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: errorMessage,
            status: MessageStatus.error,
          );
        }
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<bool> _canUseAi() async {
    return true;
  }

  Future<bool> _canUseImageSolve() async {
    return true;
  }

  Future<void> _logAiChatAnalytics() async {
    var isPremiumUser = false;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final data =
            (await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get())
                .data();
        final expiry = data?['expiryDate'];
        final expiryDate = expiry is Timestamp ? expiry.toDate() : null;
        isPremiumUser =
            (data?['isPro'] == true || data?['isUltimate'] == true) &&
            (expiryDate == null || expiryDate.isAfter(DateTime.now()));
      }
    } catch (_) {}
    await AnalyticsService.instance.logAiChatUsed(isPremiumUser: isPremiumUser);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _selectedImageBytes = bytes);
  }

  String? _getSubjectName(String? id) {
    switch (id) {
      case 'math':
        return 'Mathematics';
      case 'science':
        return 'Science';
      case 'english':
        return 'English';
      case 'social':
        return 'Social Science';
      case 'hindi':
        return 'Hindi';
      default:
        return null;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Start new chat?', style: AppTextStyles.heading2),
        content: Text(
          'This will clear all messages.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              _geminiService.resetChat();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const SvgMascot(type: MascotType.aria, size: 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Air', style: AppTextStyles.heading1),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'ONLINE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Your 24/7 AI Study Buddy',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  /*
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoiceTutorScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.aiPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.aiBorder),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.aiPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  */
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MathSolverScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.aiPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.aiBorder),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.aiPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _resetChat,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_messages.length < 3)
              QuickPrompts(
                onPromptSelected: (prompt) {
                  _sendMessage(prompt);
                },
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedImageBytes != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      width: 72,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(
                                        () => _selectedImageBytes = null,
                                      ),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            maxHeight: 120,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask Air anything...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isTyping ? null : _pickImage,
                    tooltip: 'Attach a study image',
                    icon: const Icon(
                      Icons.image_outlined,
                      color: AppColors.aiPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientHero,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isTyping
                            ? Icons.hourglass_empty_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
