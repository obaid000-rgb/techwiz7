/// Extracts the 11-character video ID from a youtube.com/watch?v=,
/// youtu.be/, or youtube.com/embed/ URL. Handles extra query params
/// (e.g. &t=30s) and an optional leading www./m. subdomain. Returns null
/// if the URL doesn't look like a valid YouTube link.
String? extractYoutubeVideoId(String url) {
  final trimmed = url.trim();
  final match = RegExp(
    r'^(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})',
  ).firstMatch(trimmed);
  return match?.group(1);
}

/// YouTube serves a predictable thumbnail per video ID with no API call —
/// hqdefault.jpg exists for every uploaded video, unlike maxresdefault.jpg
/// which is only generated for higher-resolution uploads.
String youtubeThumbnailUrl(String videoId) =>
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
