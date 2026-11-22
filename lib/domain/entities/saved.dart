class Saved<T> {
  const Saved(this.data, {required this.savedAt, this.fromStorage = false});

  final T data;
  final DateTime savedAt;
  final bool fromStorage;
}
