// Note: "DataStack" to avoid collision with the "Stack" class in the Flutter SDK.
class DataStack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E get peek => _list.last;
  E? get peekOrNull => _list.isNotEmpty ? _list.last : null;

  int get length => _list.length;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  void clear() => _list.clear();

  E pop() => _list.removeLast();
  E? popOrNull() => _list.isNotEmpty ? _list.removeLast() : null;

  void popUntil(E value) {
    final index = _list.lastIndexOf(value);
    if (index != -1) {
      _list.removeRange(index + 1, _list.length);
    }
  }

  bool contains(E value) => _list.contains(value);

  List<E> toList() => _list.toList();

  @override
  String toString() => _list.toString();
}
