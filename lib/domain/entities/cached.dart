class Cached<T> {
  const Cached(this.data, {required this.savedAt, this.fromCache = false});

  final T data;
  final DateTime savedAt;
  final bool fromCache;
}
