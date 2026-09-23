import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this.storage);
  final FlutterSecureStorage storage;
  static const key = 'bttr.token';
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String token) => storage.write(key: key, value: token);
  @override
  Future<void> delete() => storage.delete(key: key);
}

class SessionStore {
  SessionStore(this.storage);
  final TokenStorage storage;
  final _changes = StreamController<bool>.broadcast(sync: true);
  String? _token;
  String? get token => _token;
  bool get authenticated => _token != null;
  Stream<bool> get changes => _changes.stream;
  // Serialize persistence so a slow login write cannot outlive a logout.
  Future<void> _pending = Future.value();

  Future<void> restore() async {
    try {
      final value = await storage.read();
      _token = value == null || value.trim().isEmpty ? null : value;
    } catch (_) {
      _token = null;
    }
  }

  Future<void> set(String token) {
    _token = token;
    _changes.add(true);
    return _persist(() => storage.write(token));
  }

  Future<void> clear() {
    _token = null;
    _changes.add(false);
    return _persist(storage.delete);
  }

  Future<void> _persist(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } catch (_) {
        /* Session remains usable in memory. */
      }
    });
    return _pending;
  }

  Future<void> dispose() => _changes.close();
}
