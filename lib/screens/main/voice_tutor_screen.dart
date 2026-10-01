import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../config/theme.dart';
import '../../services/gemini_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/rich_markdown_view.dart';

class VoiceTutorScreen extends StatefulWidget {
  const VoiceTutorScreen({super.key});

  @override
  State<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

class _VoiceTutorScreenState extends State<VoiceTutorScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeminiService _geminiService = GeminiService();

  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;

  String _userText = '';
  String _aiResponse = '';
  String _currentMode = 'chat';
  String _currentLanguage = 'english';

  final List<Map<String, String>> _conversation = [];

  final Map<String, Map<String, dynamic>> _modes = {
    'chat': {
      'name': 'Chat',
      'emoji': '💬',
      'description': 'General conversation',
      'color': Color(0xFF8B5CF6),
    },
    'interview': {
      'name': 'Interview',
      'emoji': '🎤',
      'description': 'Practice interviews',
      'color': Color(0xFFEC4899),
    },
    'debate': {
      'name': 'Debate',
      'emoji': '🗣️',
      'description': 'Critical thinking',
      'color': Color(0xFFF59E0B),
    },
    'explain': {
      'name': 'Explain',
      'emoji': '💡',
      'description': 'Learn concepts',
      'color': Color(0xFF10B981),
    },
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showError('Microphone permission is disabled. Enable it in settings.');
      }
      await openAppSettings();
      return false;
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted) {
      return true;
    }

    if (requested.isPermanentlyDenied) {
      if (mounted) {
        _showError('Microphone permission is disabled. Enable it in settings.');
      }
      await openAppSettings();
      return false;
    }

    if (mounted) {
      _showError('Microphone permission is required to use voice chat.');
    }
    return false;
  }

  Future<void> _initSpeech() async {
    final canUseMic = await _ensureMicPermission();
    if (!canUseMic) {
      _speechEnabled = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _speechEnabled = await _speech.initialize(
      onError: (error) {
        if (error.errorMsg == 'error_permission') {
          _speechEnabled = false;
          if (mounted) {
            _showError('Speech recognition permission is not available.');
          }
        }
      },
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    if (!mounted) return;

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _startListening() async {
    final microphoneReady = await _ensureMicPermission();
    if (!microphoneReady) {
      _speechEnabled = false;
      if (mounted) {
        setState(() {});
      }
      _showError('Microphone not available');
      return;
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          if (error.errorMsg == 'error_permission') {
            _speechEnabled = false;
            if (mounted) {
              _showError('Speech recognition permission is not available.');
            }
          }
        },
      );
    }

    if (!_speechEnabled) {
      _showError('Microphone not available');
      return;
    }

    await _tts.stop();
    setState(() => _isSpeaking = false);

    HapticFeedback.mediumImpact();

    setState(() {
      _userText = '';
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() => _userText = result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: _currentLanguage == 'hindi' ? 'hi-IN' : 'en-US',
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    await _speech.stop();
    setState(() => _isListening = false);

    if (_userText.trim().isNotEmpty) {
      _sendToAI(_userText);
    }
  }

  Future<void> _sendToAI(String message) async {
    setState(() {
      _isThinking = true;
      _conversation.add({'role': 'user', 'text': message});
    });

    try {
      final response = await _geminiService.voiceChat(
        message,
        mode: _currentMode,
        language: _currentLanguage,
      );

      setState(() {
        _aiResponse = response;
        _isThinking = false;
        _conversation.add({'role': 'aria', 'text': response});
      });

      await _speakResponse(response);
    } catch (e) {
      setState(() {
        _isThinking = false;
        _aiResponse = 'Sorry, something went wrong.';
      });
      _showError('Failed to get response');
    }
  }

  Future<void> _speakResponse(String text) async {
    if (_currentLanguage == 'hindi') {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    HapticFeedback.selectionClick();
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  void _changeMode(String mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMode = mode;
      _conversation.clear();
      _userText = '';
      _aiResponse = '';
    });
  }

  void _changeLanguage() {
    HapticFeedback.selectionClick();
    final languages = ['english', 'hindi', 'hinglish'];
    final currentIndex = languages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % languages.length;

    setState(() {
      _currentLanguage = languages[nextIndex];
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getLanguageDisplay() {
    switch (_currentLanguage) {
      case 'hindi':
        return 'हिंदी';
      case 'hinglish':
        return 'Hinglish';
      default:
        return 'English';
    }
  }

  String _getLanguageFlag() {
    switch (_currentLanguage) {
      case 'hindi':
        return '🇮🇳';
      case 'hinglish':
        return '🌐';
      default:
        return '🇬🇧';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModeData = _modes[_currentMode]!;
    final currentColor = currentModeData['color'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildModeSelector(),
            _buildLanguageBadge(),
            const SizedBox(height: 20),
            Expanded(child: _buildVoiceInterface(currentColor)),
            _buildMicButton(currentColor),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _tts.stop();
              _speech.stop();
              Navigator.pop(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Text('🎤', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('Voice Tutor', style: AppTextStyles.heading2),
            ],
          ),
          const Spacer(),
          if (_conversation.isNotEmpty)
            IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _conversation.clear();
                  _userText = '';
                  _aiResponse = '';
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _modes.entries.map((entry) {
          final isSelected = _currentMode == entry.key;
          final data = entry.value;
          final color = data['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => _changeMode(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(data['emoji'], style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      data['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: _changeLanguage,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.aiLightBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.aiBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getLanguageFlag(), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                _getLanguageDisplay(),
                style: TextStyle(
                  color: AppColors.aiDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.swap_horiz_rounded, color: AppColors.aiDark, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInterface(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarGlow(
            animate: _isListening || _isSpeaking || _isThinking,
            glowColor: color,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: const SvgMascot(
                type: MascotType.aria,
                size: 140,
                animate: true,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildStatusText(color),

          const SizedBox(height: 24),

          if (_conversation.isNotEmpty)
            Expanded(
              child: ListView.builder(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final msg = _conversation[_conversation.length - 1 - index];
                  return _buildBubble(msg, color);
                },
              ),
            )
          else
            _buildEmptyState(color),
        ],
      ),
    );
  }

  Widget _buildStatusText(Color color) {
    String status = 'Tap mic to talk';
    IconData? icon = Icons.mic_rounded;

    if (_isListening) {
      status = 'Listening... 👂';
      icon = Icons.hearing_rounded;
    } else if (_isThinking) {
      status = 'Air thinking... 🤔';
      icon = Icons.psychology_rounded;
    } else if (_isSpeaking) {
      status = 'Air speaking... 🔊';
      icon = Icons.volume_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, String> msg, Color color) {
    final isUser = msg['role'] == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const SvgMascot(type: MascotType.aria, size: 32, animate: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? color : AppColors.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 1.5),
              ),
              child: isUser
                  ? Text(
                      msg['text'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    )
                  : RichMarkdownView(
                      content: msg['text'] ?? '',
                      selectable: true,
                      padding: const EdgeInsets.all(0),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEmptyState(Color color) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _modes[_currentMode]!['description'],
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getPromptExample(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPromptExample() {
    switch (_currentMode) {
      case 'interview':
        return '"Prepare me for my science exam"';
      case 'debate':
        return '"Let\'s debate about social media"';
      case 'explain':
        return '"Explain photosynthesis to me"';
      default:
        return '"What is Newton\'s second law?"';
    }
  }

  Widget _buildMicButton(Color color) {
    return Column(
      children: [
        if (_userText.isNotEmpty && _isListening)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.mic_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userText,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (_isSpeaking)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: DuolingoButton(
              label: 'STOP SPEAKING',
              color: AppColors.error,
              darkColor: const Color(0xFFB91C1C),
              icon: Icons.stop_circle_rounded,
              width: double.infinity,
              height: 44,
              onPressed: _stopSpeaking,
            ),
          )
        else
          GestureDetector(
            onTapDown: (_) {
              if (!_isThinking) _startListening();
            },
            onTapUp: (_) {
              if (_isListening) _stopListening();
            },
            onTapCancel: () {
              if (_isListening) _stopListening();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 100 : 80,
              height: _isListening ? 100 : 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.red, const Color(0xFF991B1B)]
                      : [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : color).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: _isListening ? 44 : 36,
              ),
            ),
          ),

        const SizedBox(height: 8),

        Text(
          _isListening
              ? 'Release to send'
              : _isSpeaking
              ? 'Air is speaking...'
              : 'Hold to talk',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
