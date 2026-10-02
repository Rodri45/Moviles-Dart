// lo que devuelve el repositorio: los datos, de cuando son y si salieron de
// la copia local porque la red fallo
class Cached<T> {
  const Cached(this.data, {required this.savedAt, this.fromCache = false});

  final T data;
  final DateTime savedAt;
  final bool fromCache;
}
