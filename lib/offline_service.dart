// ============================================================
//  offline_service.dart
//  PWA Offline Cache Service — Lanka Xplore
//
//  Handles persistent local storage for:
//   • Tourist  : profile, bookings (schedule + history), viewed packages
//   • Guide    : profile, assigned bookings/schedule
//   • Hotel    : profile, hotel booking requests
//   • Rider    : profile, ride assignments/schedule
//
//  Uses: shared_preferences (add to pubspec.yaml)
//
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  // ─── Keys ─────────────────────────────────────────────────
  static const _kTouristProfile = 'offline_tourist_profile';
  static const _kTouristBookings = 'offline_tourist_bookings';
  static const _kTouristPkgs = 'offline_tourist_viewed_packages';
  static const _kTouristSchedule = 'offline_tourist_schedule';

  static const _kGuideProfile = 'offline_guide_profile';
  static const _kGuideBookings = 'offline_guide_bookings';

  static const _kHotelProfile = 'offline_hotel_profile';
  static const _kHotelBookings = 'offline_hotel_bookings';

  static const _kRiderProfile = 'offline_rider_profile';
  static const _kRiderBookings = 'offline_rider_bookings';

  // ─── HELPERS ──────────────────────────────────────────────
  static Future<void> _saveMap(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> _loadMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveList(
      String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════
  //  TOURIST
  // ═══════════════════════════════════════════════════════

  /// Save tourist profile locally (call after Firestore fetch)
  static Future<void> saveTouristProfile(Map<String, dynamic> data) =>
      _saveMap(_kTouristProfile, _sanitize(data));

  /// Load tourist profile when offline
  static Future<Map<String, dynamic>?> loadTouristProfile() =>
      _loadMap(_kTouristProfile);

  /// Save all bookings (used for Booking Details + Travel Schedule offline)
  static Future<void> saveTouristBookings(
          List<Map<String, dynamic>> bookings) =>
      _saveList(_kTouristBookings, bookings.map(_sanitize).toList());

  /// Load cached bookings
  static Future<List<Map<String, dynamic>>> loadTouristBookings() =>
      _loadList(_kTouristBookings);

  /// Save confirmed-only bookings as travel schedule
  static Future<void> saveTouristSchedule(
          List<Map<String, dynamic>> confirmed) =>
      _saveList(_kTouristSchedule, confirmed.map(_sanitize).toList());

  /// Load travel schedule (confirmed bookings)
  static Future<List<Map<String, dynamic>>> loadTouristSchedule() =>
      _loadList(_kTouristSchedule);

  /// Save viewed/explored packages (previous packages)
  static Future<void> saveTouristViewedPackages(
          List<Map<String, dynamic>> packages) =>
      _saveList(_kTouristPkgs, packages.map(_sanitize).toList());

  /// Append a single viewed package (deduplicates by id)
  static Future<void> appendViewedPackage(Map<String, dynamic> pkg) async {
    final current = await loadTouristViewedPackages();
    final id = pkg['id'] ?? pkg['docId'] ?? '';
    // remove old entry if exists, then prepend (most recent first)
    final filtered =
        current.where((p) => (p['id'] ?? p['docId'] ?? '') != id).toList();
    filtered.insert(0, _sanitize(pkg));
    // keep max 50 viewed packages
    final trimmed = filtered.take(50).toList();
    await _saveList(_kTouristPkgs, trimmed);
  }

  /// Load previously viewed packages
  static Future<List<Map<String, dynamic>>> loadTouristViewedPackages() =>
      _loadList(_kTouristPkgs);

  // ═══════════════════════════════════════════════════════
  //  GUIDE
  // ═══════════════════════════════════════════════════════

  static Future<void> saveGuideProfile(Map<String, dynamic> data) =>
      _saveMap(_kGuideProfile, _sanitize(data));

  static Future<Map<String, dynamic>?> loadGuideProfile() =>
      _loadMap(_kGuideProfile);

  static Future<void> saveGuideBookings(List<Map<String, dynamic>> bookings) =>
      _saveList(_kGuideBookings, bookings.map(_sanitize).toList());

  static Future<List<Map<String, dynamic>>> loadGuideBookings() =>
      _loadList(_kGuideBookings);

  // ═══════════════════════════════════════════════════════
  //  HOTEL
  // ═══════════════════════════════════════════════════════

  static Future<void> saveHotelProfile(Map<String, dynamic> data) =>
      _saveMap(_kHotelProfile, _sanitize(data));

  static Future<Map<String, dynamic>?> loadHotelProfile() =>
      _loadMap(_kHotelProfile);

  static Future<void> saveHotelBookings(List<Map<String, dynamic>> bookings) =>
      _saveList(_kHotelBookings, bookings.map(_sanitize).toList());

  static Future<List<Map<String, dynamic>>> loadHotelBookings() =>
      _loadList(_kHotelBookings);

  // ═══════════════════════════════════════════════════════
  //  RIDER
  // ═══════════════════════════════════════════════════════

  static Future<void> saveRiderProfile(Map<String, dynamic> data) =>
      _saveMap(_kRiderProfile, _sanitize(data));

  static Future<Map<String, dynamic>?> loadRiderProfile() =>
      _loadMap(_kRiderProfile);

  static Future<void> saveRiderBookings(List<Map<String, dynamic>> bookings) =>
      _saveList(_kRiderBookings, bookings.map(_sanitize).toList());

  static Future<List<Map<String, dynamic>>> loadRiderBookings() =>
      _loadList(_kRiderBookings);

  // ─── CLEAR (logout) ───────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTouristProfile);
    await prefs.remove(_kTouristBookings);
    await prefs.remove(_kTouristPkgs);
    await prefs.remove(_kTouristSchedule);
    await prefs.remove(_kGuideProfile);
    await prefs.remove(_kGuideBookings);
    await prefs.remove(_kHotelProfile);
    await prefs.remove(_kHotelBookings);
    await prefs.remove(_kRiderProfile);
    await prefs.remove(_kRiderBookings);
  }

  // ─── Sanitize: convert Timestamp / DateTime to ISO string ─
  static Map<String, dynamic> _sanitize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((k, v) {
      if (v == null) {
        result[k] = null;
      } else if (v.runtimeType.toString().contains('Timestamp')) {
        // Firestore Timestamp → ISO string
        try {
          result[k] = (v as dynamic).toDate().toIso8601String();
        } catch (_) {
          result[k] = v.toString();
        }
      } else if (v is DateTime) {
        result[k] = v.toIso8601String();
      } else if (v is Map) {
        result[k] = _sanitize(Map<String, dynamic>.from(v));
      } else if (v is List) {
        result[k] = v.map((e) {
          if (e is Map) return _sanitize(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        result[k] = v;
      }
    });
    return result;
  }
}
