class PagedResult<T> {
  const PagedResult({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });
  final int count;
  final List<T> results;
  final String? next;
  final String? previous;
  int get totalPages => (count / 5).ceil();
}
