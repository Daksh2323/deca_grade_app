import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/pdf_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/duolingo_button.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, Color> colors;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.colors,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfService _pdfService = PdfService();
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  String? _localFilePath;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _hasError = false;
  bool _openedExternally = false;
  String _errorMessage = '';
  double _downloadProgress = 0.0;

  int _currentPage = 1;
  int _totalPages = 0;
  Timer? _pageIndicatorTimer;
  bool _showControls = true;
  bool _isSearchMode = false;
  bool _isNightMode = false;
  Offset? _pdfPointerDownPosition;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
    _downloadAndOpen();
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _pdfController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updatePageIndicator(int pageNumber) {
    _pageIndicatorTimer?.cancel();
    _pageIndicatorTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _currentPage == pageNumber) return;
      setState(() => _currentPage = pageNumber);
    });
  }

  void _showUnavailableState([
    String message = 'This study material is not available right now.',
  ]) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _downloadAndOpen() async {
    try {
      if (widget.url.trim().isEmpty) {
        _showUnavailableState();
        return;
      }

      if (widget.url.startsWith('file://')) {
        final localPath = widget.url.replaceFirst('file://', '');
        final file = File(localPath);
        if (!await file.exists() || await file.length() == 0) {
          _showUnavailableState(
            'This PDF file is missing or incomplete. Please try again.',
          );
          return;
        }
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _localFilePath = localPath;
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      final uri = Uri.tryParse(widget.url.trim());
      final isNcertUrl =
          uri != null &&
          (uri.host == 'ncert.nic.in' || uri.host == 'www.ncert.nic.in');
      if (kIsWeb && isNcertUrl) {
        final opened = await launchUrl(uri, webOnlyWindowName: '_self');
        if (!opened && mounted) {
          _showUnavailableState(
            'Could not open the official NCERT PDF. Please try again.',
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
        _hasError = false;
        _downloadProgress = 0.0;
      });

      final fileName = _sanitizeFileName(widget.title);

      final path = await _pdfService.downloadPdf(
        url: widget.url,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          final bytes = await file.readAsBytes();
          setState(() {
            _localFilePath = path;
            _pdfBytes = bytes;
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        _showUnavailableState(
          'This study material is temporarily unavailable. Please check your internet connection and try again.',
        );
      }
    } catch (e, stack) {
      unawaited(CrashReportingService.instance.recordNonFatal(e, stack));
      unawaited(CrashReportingService.instance.breadcrumb('PDF load failed'));
      if (mounted) {
        _showUnavailableState(
          'This study material is temporarily unavailable. Please try again.',
        );
      }
    }
  }

  String _sanitizeFileName(String name) {
    final clean = name
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return '$clean.pdf';
  }

  Future<void> _sharePdf() async {
    if (_localFilePath == null) return;
    HapticFeedback.selectionClick();

    try {
      await Share.shareXFiles([
        XFile(_localFilePath!),
      ], text: 'Check out this study material from DecaGrade! 📚');
    } catch (_) {
      if (mounted) {
        ToastHelper.showError(context, 'Could not share PDF');
      }
    }
  }

  Future<void> _downloadToDevice() async {
    HapticFeedback.mediumImpact();

    ToastHelper.showInfo(context, 'Downloading PDF...');

    final path = await _pdfService.saveToDevice(
      url: widget.url,
      fileName: _sanitizeFileName(widget.title),
    );

    if (path != null) {
      if (mounted) {
        ToastHelper.showSuccess(context, 'PDF saved to Downloads/DecaGrade/');
      }
    } else {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to save PDF');
      }
    }
  }

  Future<void> _openInExternalApp() async {
    if (_localFilePath == null) return;
    HapticFeedback.selectionClick();

    try {
      await OpenFilex.open(_localFilePath!);
    } catch (_) {
      if (mounted) {
        ToastHelper.showError(context, 'No PDF app installed');
      }
    }
  }

  void _jumpToPage() {
    HapticFeedback.selectionClick();
    _pageController.text = _currentPage.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.numbers_rounded, color: widget.colors['primary']),
            const SizedBox(width: 8),
            Text('Jump to Page', style: AppTextStyles.heading2),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total pages: $_totalPages', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: widget.colors['primary'],
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter page number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.colors['primary']!,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(_pageController.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
              } else {
                ToastHelper.showError(context, 'Invalid page number');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors['primary'],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'GO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
      }
    });
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    HapticFeedback.selectionClick();

    final result = _pdfController.searchText(query);
    if (result != null) {
      ToastHelper.showInfo(context, 'Searching…');
    }
  }

  void _toggleControls() {
    HapticFeedback.selectionClick();
    setState(() => _showControls = !_showControls);
  }

  void _handlePdfPointerDown(PointerDownEvent event) {
    _pdfPointerDownPosition = event.position;
  }

  void _handlePdfPointerUp(PointerUpEvent event) {
    final downPosition = _pdfPointerDownPosition;
    _pdfPointerDownPosition = null;
    if (downPosition != null && (event.position - downPosition).distance < 12) {
      _toggleControls();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightMode ? Colors.black : AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPdfContent()),
            if (!_isLoading && !_hasError && _showControls) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: _isNightMode ? Colors.grey.shade900 : AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                      color: widget.colors['light'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: widget.colors['primary'],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: _isNightMode
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_isLoading && !_hasError)
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: TextStyle(
                            color: widget.colors['primary'],
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isLoading && !_hasError) ...[
                  _buildHeaderIcon(
                    _isNightMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    () {
                      HapticFeedback.selectionClick();
                      setState(() => _isNightMode = !_isNightMode);
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildHeaderIcon(Icons.search_rounded, _toggleSearch),
                  const SizedBox(width: 6),
                  _buildHeaderIcon(Icons.more_vert_rounded, _showMoreMenu),
                ],
              ],
            ),
          ),
          if (_isSearchMode)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: _isNightMode ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search in PDF...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.colors['primary'],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      _toggleSearch();
                    },
                  ),
                  filled: true,
                  fillColor: _isNightMode
                      ? Colors.grey.shade800
                      : AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _search,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isNightMode ? Colors.grey.shade800 : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: _isNightMode ? Colors.white : AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    if (_localFilePath == null && _pdfBytes == null) {
      return _buildErrorState();
    }

    try {
      final pdfWidget = _pdfBytes != null
          ? SfPdfViewer.memory(
              _pdfBytes!,
              key: _pdfViewerKey,
              controller: _pdfController,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              pageSpacing: 0,
              enableDoubleTapZooming: true,
              interactionMode: PdfInteractionMode.pan,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
              onDocumentLoaded: (details) {
                if (!mounted) return;
                setState(() {
                  _totalPages = _pdfController.pageCount;
                  _currentPage = _pdfController.pageNumber;
                });
              },
              onPageChanged: (details) {
                _updatePageIndicator(details.newPageNumber);
              },
              onDocumentLoadFailed: (details) {
                if (!mounted) return;
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      'Failed to load PDF. ${details.description ?? ''}';
                });
              },
            )
          : SfPdfViewer.file(
              File(_localFilePath!),
              key: _pdfViewerKey,
              controller: _pdfController,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              canShowPaginationDialog: false,
              pageSpacing: 0,
              enableDoubleTapZooming: true,
              interactionMode: PdfInteractionMode.pan,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              scrollDirection: PdfScrollDirection.vertical,
              onDocumentLoaded: (details) {
                if (!mounted) return;
                setState(() {
                  _totalPages = _pdfController.pageCount;
                  _currentPage = _pdfController.pageNumber;
                });
              },
              onPageChanged: (details) {
                _updatePageIndicator(details.newPageNumber);
              },
              onDocumentLoadFailed: (details) {
                if (!mounted) return;
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      'Failed to load PDF. ${details.description ?? ''}';
                });
              },
            );

      return SizedBox.expand(
        child: ClipRect(
          child: RepaintBoundary(
            child: Listener(
              onPointerDown: _handlePdfPointerDown,
              onPointerUp: _handlePdfPointerUp,
              child: pdfWidget,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load PDF. Please try again.';
          _isLoading = false;
        });
      }
      return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.error,
                    size: 60,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  duration: 1000.ms,
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 30),
            Text(
              'Downloading PDF...',
              style: TextStyle(
                color: _isNightMode ? Colors.white : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: TextStyle(
                color: widget.colors['primary'],
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.colors['primary']!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _openedExternally
                  ? 'PDF opened in browser'
                  : 'Content Unavailable',
              style: AppTextStyles.heading1.copyWith(
                color: _isNightMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'This study material is not available right now.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DuolingoButton(
                  label: 'RETRY',
                  color: widget.colors['primary']!,
                  darkColor: widget.colors['dark']!,
                  icon: Icons.refresh_rounded,
                  onPressed: _downloadAndOpen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isNightMode ? Colors.grey.shade900 : AppColors.cardBg,
        border: Border(
          top: BorderSide(
            color: _isNightMode ? Colors.grey.shade800 : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildControlButton(
            Icons.arrow_back_ios_rounded,
            'Previous',
            _currentPage > 1
                ? () {
                    HapticFeedback.selectionClick();
                    _pdfController.previousPage();
                  }
                : null,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _jumpToPage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: widget.colors['primary']!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.colors['primary']!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_rounded,
                      color: widget.colors['primary'],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_currentPage / $_totalPages',
                      style: TextStyle(
                        color: widget.colors['dark'],
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildControlButton(
            Icons.arrow_forward_ios_rounded,
            'Next',
            _currentPage < _totalPages
                ? () {
                    HapticFeedback.selectionClick();
                    _pdfController.nextPage();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String tooltip,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap != null ? widget.colors['primary'] : AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  void _showMoreMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: _isNightMode ? Colors.grey.shade900 : AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              _buildMenuOption(
                Icons.numbers_rounded,
                'Jump to Page',
                'Go to specific page',
                () {
                  Navigator.pop(context);
                  _jumpToPage();
                },
                widget.colors['primary']!,
              ),
              _buildMenuOption(
                Icons.download_rounded,
                'Download PDF',
                'Save to device storage',
                () {
                  Navigator.pop(context);
                  _downloadToDevice();
                },
                AppColors.aiPrimary,
              ),
              _buildMenuOption(
                Icons.share_rounded,
                'Share PDF',
                'Send to friends',
                () {
                  Navigator.pop(context);
                  _sharePdf();
                },
                AppColors.success,
              ),
              _buildMenuOption(
                Icons.open_in_new_rounded,
                'Open in Another App',
                'Use external PDF reader',
                () {
                  Navigator.pop(context);
                  _openInExternalApp();
                },
                AppColors.warning,
              ),
              _buildMenuOption(
                Icons.zoom_in_rounded,
                'Zoom Level: ${(_pdfController.zoomLevel * 100).toInt()}%',
                'Pinch to zoom in PDF',
                () {
                  Navigator.pop(context);
                  _showZoomControls();
                },
                AppColors.sstPrimary,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _isNightMode
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showZoomControls() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: _isNightMode ? Colors.grey.shade900 : AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            double zoom = _pdfController.zoomLevel;
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        color: widget.colors['primary'],
                      ),
                      const SizedBox(width: 8),
                      Text('Zoom Level', style: AppTextStyles.heading2),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${(zoom * 100).toInt()}%',
                    style: TextStyle(
                      color: widget.colors['primary'],
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: zoom,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    activeColor: widget.colors['primary'],
                    onChanged: (value) {
                      setState(() => zoom = value);
                      _pdfController.zoomLevel = value;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildZoomButton('50%', 0.5, (v) {
                        setState(() => zoom = 1.0);
                        _pdfController.zoomLevel = 1.0;
                      }),
                      _buildZoomButton('100%', 1.0, (v) {
                        setState(() => zoom = 1.0);
                        _pdfController.zoomLevel = 1.0;
                      }),
                      _buildZoomButton('150%', 1.5, (v) {
                        setState(() => zoom = 1.5);
                        _pdfController.zoomLevel = 1.5;
                      }),
                      _buildZoomButton('200%', 2.0, (v) {
                        setState(() => zoom = 2.0);
                        _pdfController.zoomLevel = 2.0;
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildZoomButton(String label, double value, Function(double) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.colors['primary']!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.colors['primary']!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: widget.colors['dark'],
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
