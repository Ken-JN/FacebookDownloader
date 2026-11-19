class FbUrlValidator {
  static final RegExp _fbRegex = RegExp(
    r'^(https?:\/\/)?((www|m|web)\.)?(facebook\.com|fb\.watch)\/.*$',
    caseSensitive: false,
  );

  static bool isValid(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return _fbRegex.hasMatch(url.trim());
  }

  static String? extractFirstUrl(String text) {
    final matches = RegExp(r'(https?:\/\/[^\s]+)').allMatches(text);
    for (final match in matches) {
      final potentialUrl = match.group(0);
      if (isValid(potentialUrl)) {
        return potentialUrl;
      }
    }
    return null;
  }
}
