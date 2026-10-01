import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeExtractor {
  YoutubeExplode? _yt;

  YoutubeExplode get _client {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  Future<Map<String, dynamic>> extractStream(String videoId) async {
    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);

      final List<Map<String, dynamic>> qualities = [];
      final Map<String, Map<String, dynamic>> qualityMap = {};

      void addStream(dynamic stream, String type) {
        final qualityLabel = (stream.qualityLabel ?? 'Unknown').trim();
        final resolution =
            '${stream.videoResolution.width}x${stream.videoResolution.height}';
        final key = qualityLabel.isEmpty
            ? 'Unknown'
            : qualityLabel.toLowerCase();

        final candidate = {
          'qualityKey': key,
          'url': stream.url.toString(),
          'quality': qualityLabel,
          'resolution': resolution,
          'size': stream.size.totalMegaBytes.toStringAsFixed(1),
          'type': type,
          'hasAudio': type == 'muxed',
          'bitrate': stream.bitrate.kiloBitsPerSecond.toInt(),
        };

        final existing = qualityMap[key];
        if (existing == null) {
          qualityMap[key] = candidate;
          return;
        }

        final existingHasAudio = existing['hasAudio'] == true;
        final incomingHasAudio = candidate['hasAudio'] == true;
        final existingBitrate = (existing['bitrate'] as num?)?.toInt() ?? 0;
        final incomingBitrate = (candidate['bitrate'] as num?)?.toInt() ?? 0;

        if (!existingHasAudio && incomingHasAudio) {
          qualityMap[key] = candidate;
          return;
        }

        if (existingHasAudio == incomingHasAudio &&
            incomingBitrate > existingBitrate) {
          qualityMap[key] = candidate;
        }
      }

      for (final stream in manifest.muxed) {
        addStream(stream, 'muxed');
      }

      for (final stream in manifest.video) {
        addStream(stream, 'video');
      }

      final uniqueQualities = qualityMap.values.toList();
      uniqueQualities.sort(
        (a, b) => ((b['bitrate'] as num?)?.toInt() ?? 0).compareTo(
          (a['bitrate'] as num?)?.toInt() ?? 0,
        ),
      );

      final hasMuxedQuality = uniqueQualities.any(
        (quality) => quality['hasAudio'] == true,
      );
      final filteredQualities = hasMuxedQuality
          ? uniqueQualities
                .where((quality) => quality['hasAudio'] == true)
                .toList()
          : uniqueQualities;

      final video = await _client.videos.get(videoId);

      // Prefer the highest-bitrate muxed stream (contains audio) for playback.
      String bestUrl = '';
      if (manifest.muxed.isNotEmpty) {
        bestUrl = manifest.muxed.withHighestBitrate().url.toString();
      } else if (filteredQualities.isNotEmpty) {
        bestUrl = filteredQualities.first['url']?.toString() ?? '';
      }

      return {
        'success': true,
        'videoUrl': bestUrl,
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inSeconds ?? 0,
        'thumbnail': video.thumbnails.highResUrl,
        'qualities': filteredQualities,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String?> getStreamForQuality(String videoId, String quality) async {
    try {
      final normalizedTarget = quality.trim().toLowerCase();
      final manifest = await _client.videos.streamsClient.getManifest(videoId);

      // Prefer muxed streams matching the exact quality (audio + video).
      for (final stream in manifest.muxed) {
        final label = (stream.qualityLabel ?? '').trim().toLowerCase();
        if (label == normalizedTarget) {
          return stream.url.toString();
        }
      }

      // Then try video-only streams.
      for (final stream in manifest.video) {
        final label = (stream.qualityLabel ?? '').trim().toLowerCase();
        if (label == normalizedTarget) {
          return stream.url.toString();
        }
      }

      // Last fallback: pick the closest matching resolution by label prefix.
      final allStreams = [...manifest.muxed, ...manifest.video];
      if (allStreams.isNotEmpty) {
        final fallback = allStreams.firstWhere(
          (stream) {
            final label = (stream.qualityLabel ?? '').trim().toLowerCase();
            return label.startsWith(normalizedTarget) ||
                normalizedTarget.startsWith(label);
          },
          orElse: () => allStreams.reduce(
            (a, b) => a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond
                ? a
                : b,
          ),
        );
        return fallback.url.toString();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dispose the client
  void dispose() {
    _yt?.close();
    _yt = null;
  }
}
