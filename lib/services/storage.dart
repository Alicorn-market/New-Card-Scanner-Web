import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_data.dart';

/// Simple on-phone storage (no account, no internet).
class Storage {
  /// Screens listen to this and refresh when stored data changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static const _recentKey = 'recent_scans';
  static const _profileKey = 'my_profile';
  static const _slugKey = 'card_slug';
  static const _welcomeKey = 'welcome_seen';

  static Future<bool> seenWelcome() async =>
      (await SharedPreferences.getInstance()).getBool(_welcomeKey) ?? false;

  static Future<void> markWelcomeSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_welcomeKey, true);

  static Future<List<ContactData>> loadRecent() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_recentKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ContactData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeRecent(List<ContactData> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_recentKey, jsonEncode(list.take(200).map((e) => e.toJson()).toList()));
    changes.value++;
  }

  static Future<void> saveRecent(ContactData c) async {
    final list = await loadRecent();
    final i = list.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      list[i] = c;
    } else {
      list.insert(0, c);
    }
    await _writeRecent(list);
  }

  static Future<void> deleteRecent(String id) async {
    final list = await loadRecent();
    list.removeWhere((x) => x.id == id);
    await _writeRecent(list);
  }

  static Future<ContactData?> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_profileKey);
    if (raw == null) return null;
    try {
      return ContactData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(ContactData c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_profileKey, jsonEncode(c.toJson()));
    changes.value++;
  }

  /// Random, hard-to-guess card ID used in the QR link.
  static Future<String> cardSlug() async {
    final p = await SharedPreferences.getInstance();
    var slug = p.getString(_slugKey);
    if (slug == null) {
      const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
      final r = Random.secure();
      slug = List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
      await p.setString(_slugKey, slug);
    }
    return slug;
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_recentKey);
    await p.remove(_profileKey);
    await p.remove(_slugKey);
    changes.value++;
  }
}
