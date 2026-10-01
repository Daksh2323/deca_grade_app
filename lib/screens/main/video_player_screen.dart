import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/theme.dart';
import '../../services/youtube_extractor.dart';
import '../../utils/toast_helper.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String youtubeId;
  final String title;
  final String description;
  final Map<String, Color> colors;

  const VideoPlayerScreen({
    super.key,
    required this.youtubeId,
    required this.title,
    required this.description,
    required this.colors,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final YouTubeExtractor _extractor = YouTubeExtractor();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final WebViewController _fallbackController = WebViewController();

  bool _isLoading = true;
  bool _hasError = false;
  bool _isFallbackMode = false;
  String _errorMessage = '';
  String _currentQuality = '';
  List<Map<String, dynamic>> _availableQualities = [];
  Map<String, dynamic>? _videoInfo;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    _fallbackController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() {});
          },
        ),
      );

    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result = await _extractor.extractStream(widget.youtubeId);

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to extract');
      }

      final videoUrl = result['videoUrl'] as String;
      _videoInfo = result;
      _availableQualities = List<Map<String, dynamic>>.from(
        result['qualities'] ?? [],
      );

      if (_availableQualities.isNotEmpty) {
        _currentQuality = _availableQualities.first['quality'] ?? '';
      }

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _videoController!.initialize();

      if (!mounted) {
        _videoController?.dispose();
        _videoController = null;
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.colors['primary'] ?? AppColors.primary,
          handleColor: widget.colors['primary'] ?? AppColors.primary,
          bufferedColor: (widget.colors['primary'] ?? AppColors.primary)
              .withOpacity(0.3),
          backgroundColor: Colors.white.withOpacity(0.2),
        ),
        errorBuilder: (context, errorMessage) =>
            _buildPlayerError(errorMessage),
        placeholder: _buildPlaceholder(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isFallbackMode = true;
          _errorMessage = _getReadableError(e.toString());
        });
        _fallbackController.loadRequest(
          Uri.parse(
            'https://www.youtube.com/embed/${widget.youtubeId}?autoplay=1',
          ),
        );
      }
    }
  }

  String _getReadableError(String error) {
    if (error.contains('SocketException') || error.contains('NetworkError')) {
      return 'No internet connection. Please check your network.';
    }
    if (error.contains('VideoUnavailable') || error.contains('not available')) {
      return 'This video is not available. It may be private or deleted.';
    }
    if (error.contains('age') || error.contains('sign in')) {
      return 'This video requires age verification.';
    }
    if (error.contains('region')) {
      return 'This video is not available in your region.';
    }
    return 'Unable to load video. Please try again.';
  }

  Future<void> _changeQuality(Map<String, dynamic> quality) async {
    final selectedQuality = quality['quality'] ?? '';
    if (selectedQuality.isEmpty) return;
    if (_currentQuality == selectedQuality && _videoController != null) return;

    HapticFeedback.mediumImpact();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final currentPosition = _videoController?.value.position;

    setState(() {
      _isLoading = true;
      _currentQuality = selectedQuality;
    });

    try {
      final selectedUrl =
          (quality['url'] as String?) ??
          await _extractor.getStreamForQuality(
            widget.youtubeId,
            selectedQuality,
          );

      if (selectedUrl == null || selectedUrl.isEmpty) {
        throw Exception('Unable to find stream for $selectedQuality');
      }

      final previousController = _videoController;
      final previousChewie = _chewieController;

      _chewieController = null;
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(selectedUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _videoController!.initialize();

      if (currentPosition != null && currentPosition.inSeconds > 0) {
        await _videoController!.seekTo(currentPosition);
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: widget.colors['primary'] ?? AppColors.primary,
          handleColor: widget.colors['primary'] ?? AppColors.primary,
          bufferedColor: (widget.colors['primary'] ?? AppColors.primary)
              .withOpacity(0.3),
          backgroundColor: Colors.white.withOpacity(0.2),
        ),
        errorBuilder: (context, msg) => _buildPlayerError(msg),
        placeholder: _buildPlaceholder(),
      );

      previousController?.dispose();
      previousChewie?.dispose();

      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastHelper.showSuccess(context, 'Quality: $selectedQuality');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ToastHelper.showError(context, 'This quality could not be loaded');
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _extractor.dispose();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFallbackMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('DecaGrade Video'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: WebViewWidget(controller: _fallbackController),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: Colors.black,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                bottom: 8,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.colors['primary'] ?? AppColors.primary,
                          widget.colors['dark'] ?? AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.colors['primary'] ?? AppColors.primary)
                              .withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DecaGrade',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black,
              child: AspectRatio(aspectRatio: 16 / 9, child: _buildVideoArea()),
            ),
            if (!_isLoading && !_hasError && _availableQualities.isNotEmpty)
              _buildQualityBar(),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: _buildInfoSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    if (_chewieController != null)
      return Chewie(controller: _chewieController!);
    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: widget.colors['primary'] ?? AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preparing video...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Extracting best quality',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadVideo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.colors['primary'] ?? AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerError(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVideo, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: widget.colors['primary'] ?? AppColors.primary,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildQualityBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (widget.colors['primary'] ?? AppColors.primary)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.colors['primary'] ?? AppColors.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hd_rounded,
                  color: widget.colors['primary'] ?? AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentQuality.isNotEmpty ? _currentQuality : 'Auto',
                  style: TextStyle(
                    color: widget.colors['primary'] ?? AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showQualityMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Quality',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_videoInfo != null)
            Text(
              _formatDuration(_videoInfo!['duration'] ?? 0),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge(Icons.school_rounded, 'Class 10', AppColors.primary),
              _buildBadge(Icons.menu_book_rounded, 'CBSE', AppColors.aiPrimary),
              _buildBadge(
                Icons.hd_rounded,
                _currentQuality.isNotEmpty ? _currentQuality : 'HD',
                AppColors.warning,
              ),
              _buildBadge(Icons.stars_rounded, 'Free', AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.description.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.colors['light'] ?? AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.colors['border'] ?? AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: widget.colors['dark'] ?? AppColors.primaryDark,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'About this lesson',
                        style: TextStyle(
                          color: widget.colors['dark'] ?? AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.aiPrimary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Player Features',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFeature(Icons.hd_rounded, 'Multiple quality options'),
                _buildFeature(Icons.speed_rounded, 'Playback speed control'),
                _buildFeature(Icons.fullscreen_rounded, 'Fullscreen support'),
                _buildFeature(
                  Icons.play_arrow_rounded,
                  'Custom branded player',
                ),
                _buildFeature(Icons.block_rounded, 'No ads or distractions'),
                _buildFeature(
                  Icons.security_rounded,
                  'Safe & distraction-free',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m ${s}s';
  }

  void _showQualityMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final maxSheetHeight = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderMedium,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.hd_rounded,
                          color: widget.colors['primary'] ?? AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Video Quality', style: AppTextStyles.heading2),
                        const Spacer(),
                        Text(
                          '${_availableQualities.length} options',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._availableQualities.map((quality) {
                      final isSelected = _currentQuality == quality['quality'];
                      final bool hasAudio = quality['hasAudio'] == true;
                      return InkWell(
                        onTap: () {
                          if (!hasAudio) {
                            ToastHelper.showWarning(
                              context,
                              'Selected stream has no audio; choose a muxed option',
                            );
                            return;
                          }
                          _changeQuality(quality);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (widget.colors['light'] ??
                                      AppColors.backgroundSecondary)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (widget.colors['primary'] ??
                                        AppColors.primary)
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? (widget.colors['primary'] ??
                                          AppColors.primary)
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quality['quality'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? (widget.colors['dark'] ??
                                                AppColors.primaryDark)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${quality['resolution']} • ${quality['size']} MB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (quality == _availableQualities.first)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Best',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
