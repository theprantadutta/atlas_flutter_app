class LRUCache<K, V> {
  final int maxSize;
  final Duration ttl;
  final _cache = <K, _CacheEntry<V>>{};  // insertion-ordered by default

  LRUCache({required this.maxSize, required this.ttl});

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.insertedAt) > ttl) {
      _cache.remove(key);
      return null;
    }
    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry;
    return entry.value;
  }

  void put(K key, V value) {
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CacheEntry(value: value, insertedAt: DateTime.now());
  }

  void remove(K key) => _cache.remove(key);
  void clear() => _cache.clear();
  bool containsKey(K key) => get(key) != null;
  int get length => _cache.length;
}

class _CacheEntry<V> {
  final V value;
  final DateTime insertedAt;
  _CacheEntry({required this.value, required this.insertedAt});
}
