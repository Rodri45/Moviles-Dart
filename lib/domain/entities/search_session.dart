enum SearchMode { voice, text }

class SearchSession {
  const SearchSession({
    required this.id,
    required this.mode,
    this.voiceFallback = false,
  });

  final String id;
  final SearchMode mode;
  final bool voiceFallback;

  Map<String, Object> get properties => {'searchId': id, 'mode': mode.name};
}
