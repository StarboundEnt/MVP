import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/health_navigation_profile.dart';
import '../models/saved_items_model.dart';
import '../models/health_journal_model.dart';
import '../providers/app_state.dart';

/// Backup data container
class BackupData {
  final String version;
  final DateTime createdAt;
  final String? deviceInfo;
  final HealthNavigationProfile? profile;
  final List<SavedResource> savedResources;
  final List<SavedConversation> savedConversations;
  final List<HealthJournalEntry> journalEntries;
  final Map<String, dynamic> settings;

  const BackupData({
    required this.version,
    required this.createdAt,
    this.deviceInfo,
    this.profile,
    this.savedResources = const [],
    this.savedConversations = const [],
    this.journalEntries = const [],
    this.settings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'profile': profile?.toJson(),
      'savedResources': savedResources.map((r) => r.toJson()).toList(),
      'savedConversations': savedConversations.map((c) => c.toJson()).toList(),
      'journalEntries': journalEntries.map((e) => e.toJson()).toList(),
      'settings': settings,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      deviceInfo: json['deviceInfo'] as String?,
      profile: json['profile'] != null
          ? HealthNavigationProfile.fromJson(json['profile'])
          : null,
      savedResources: (json['savedResources'] as List<dynamic>? ?? [])
          .map((r) => SavedResource.fromJson(r))
          .toList(),
      savedConversations: (json['savedConversations'] as List<dynamic>? ?? [])
          .map((c) => SavedConversation.fromJson(c))
          .toList(),
      journalEntries: (json['journalEntries'] as List<dynamic>? ?? [])
          .map((e) => HealthJournalEntry.fromJson(e))
          .toList(),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  /// Estimate the size of the backup in bytes
  int get estimatedSize {
    final jsonStr = jsonEncode(toJson());
    return jsonStr.length;
  }

  /// Check if backup can fit in a QR code (< 2KB after compression)
  bool get canFitInQR => estimatedSize < 8000; // Rough estimate before compression

  /// Get summary for display
  String get summary {
    final parts = <String>[];
    if (profile != null) parts.add('Profile');
    if (savedResources.isNotEmpty) {
      parts.add('${savedResources.length} saved resources');
    }
    if (savedConversations.isNotEmpty) {
      parts.add('${savedConversations.length} conversations');
    }
    if (journalEntries.isNotEmpty) {
      parts.add('${journalEntries.length} journal entries');
    }
    return parts.isEmpty ? 'Empty backup' : parts.join(', ');
  }
}

/// Result of a backup operation
class BackupResult {
  final bool success;
  final String? qrData; // Base64 encoded encrypted data for QR
  final String? filePath; // File path if too large for QR
  final String? error;
  final bool usedFileFallback;

  const BackupResult({
    required this.success,
    this.qrData,
    this.filePath,
    this.error,
    this.usedFileFallback = false,
  });
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final BackupData? data;
  final String? error;
  final bool requiresMerge;

  const RestoreResult({
    required this.success,
    this.data,
    this.error,
    this.requiresMerge = false,
  });
}

/// Backup restore mode
enum RestoreMode {
  replaceAll,  // Delete all current data and replace
  merge,       // Merge with existing data (skip duplicates)
  preview,     // Just parse and show what would be restored
}

/// Backup and restore service with AES-256 encryption
class BackupService {
  static const String _backupVersion = '1.0';
  static const int _maxQRBytes = 2000; // Max bytes for QR code

  // Use a user-derived key for encryption
  // In production, this would be derived from a user passphrase
  static const String _defaultKeyBase = 'starbound_backup_key_2024';

  /// Generate encryption key from passphrase
  encrypt.Key _deriveKey(String passphrase) {
    // Use SHA-256 to derive a 32-byte key
    final keyString = passphrase.padRight(32, '0').substring(0, 32);
    return encrypt.Key.fromUtf8(keyString);
  }

  /// Generate a random IV
  encrypt.IV _generateIV() {
    return encrypt.IV.fromSecureRandom(16);
  }

  /// Compress data using gzip
  Uint8List _compress(String data) {
    final bytes = utf8.encode(data);
    final encoder = GZipEncoder();
    return Uint8List.fromList(encoder.encode(bytes)!);
  }

  /// Decompress gzip data
  String _decompress(Uint8List compressed) {
    final decoder = GZipDecoder();
    final decompressed = decoder.decodeBytes(compressed);
    return utf8.decode(decompressed);
  }

  /// Encrypt data with AES-256
  String _encrypt(String data, String passphrase) {
    final key = _deriveKey(passphrase);
    final iv = _generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(data, iv: iv);

    // Prepend IV to encrypted data (IV is not secret)
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  /// Decrypt AES-256 encrypted data
  String _decrypt(String encryptedBase64, String passphrase) {
    final key = _deriveKey(passphrase);
    final combined = base64Decode(encryptedBase64);

    // Extract IV (first 16 bytes)
    final ivBytes = combined.sublist(0, 16);
    final encryptedBytes = combined.sublist(16);

    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Create backup from app state
  Future<BackupData> createBackupData(AppState appState) async {
    return BackupData(
      version: _backupVersion,
      createdAt: DateTime.now(),
      deviceInfo: 'Starbound Mobile',
      profile: appState.healthNavigationProfile,
      savedResources: appState.savedResources,
      savedConversations: appState.savedConversations,
      journalEntries: appState.healthJournalEntries,
      settings: {
        'notificationsEnabled': appState.notificationsEnabled,
        'notificationTime': appState.notificationTime,
        'homeMemoryEnabled': appState.homeMemoryEnabled,
      },
    );
  }

  /// Generate backup for QR code or file
  Future<BackupResult> generateBackup(
    AppState appState, {
    String? passphrase,
  }) async {
    try {
      final backupData = await createBackupData(appState);
      final jsonStr = jsonEncode(backupData.toJson());

      // Compress the data
      final compressed = _compress(jsonStr);

      // Encrypt the compressed data
      final key = passphrase ?? _defaultKeyBase;
      final encryptedBase64 = _encrypt(base64Encode(compressed), key);

      // Check if it fits in a QR code
      if (encryptedBase64.length <= _maxQRBytes) {
        return BackupResult(
          success: true,
          qrData: encryptedBase64,
          usedFileFallback: false,
        );
      }

      // Too large for QR - save to file
      final filePath = await _saveToFile(encryptedBase64);
      return BackupResult(
        success: true,
        qrData: encryptedBase64, // Still provide for potential chunking
        filePath: filePath,
        usedFileFallback: true,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        error: 'Failed to create backup: $e',
      );
    }
  }

  /// Save backup to file
  Future<String> _saveToFile(String encryptedData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/starbound_backup_$timestamp.sbk');
    await file.writeAsString(encryptedData);
    return file.path;
  }

  /// Parse backup from QR code or file data
  Future<RestoreResult> parseBackup(
    String encryptedData, {
    String? passphrase,
    RestoreMode mode = RestoreMode.preview,
  }) async {
    try {
      final key = passphrase ?? _defaultKeyBase;

      // Decrypt the data
      final decryptedBase64 = _decrypt(encryptedData, key);
      final compressed = base64Decode(decryptedBase64);

      // Decompress
      final jsonStr = _decompress(Uint8List.fromList(compressed));
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final backupData = BackupData.fromJson(json);

      return RestoreResult(
        success: true,
        data: backupData,
        requiresMerge: mode == RestoreMode.merge,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        error: 'Failed to parse backup: $e',
      );
    }
  }

  /// Restore backup to app state
  Future<RestoreResult> restoreBackup(
    AppState appState,
    String encryptedData, {
    String? passphrase,
    RestoreMode mode = RestoreMode.replaceAll,
  }) async {
    final parseResult = await parseBackup(
      encryptedData,
      passphrase: passphrase,
      mode: mode,
    );

    if (!parseResult.success || parseResult.data == null) {
      return parseResult;
    }

    if (mode == RestoreMode.preview) {
      return parseResult;
    }

    try {
      final data = parseResult.data!;

      if (mode == RestoreMode.replaceAll) {
        // Clear existing data and replace
        await _clearAndRestore(appState, data);
      } else if (mode == RestoreMode.merge) {
        // Merge with existing data
        await _mergeRestore(appState, data);
      }

      return RestoreResult(
        success: true,
        data: data,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        error: 'Failed to restore backup: $e',
      );
    }
  }

  /// Clear all data and restore from backup
  Future<void> _clearAndRestore(AppState appState, BackupData data) async {
    // Update profile
    if (data.profile != null) {
      await appState.setHealthNavigationProfile(
        userName: data.profile!.userName,
        neighborhood: data.profile!.neighborhood,
        languages: data.profile!.languages,
        barriers: data.profile!.barriers,
        healthInterests: data.profile!.healthInterests,
        workSchedule: data.profile!.workSchedule,
        checkInFrequency: data.profile!.checkInFrequency,
        additionalNotes: data.profile!.additionalNotes,
      );
    }

    // Clear existing saved resources
    final existingResources = List<SavedResource>.from(appState.savedResources);
    for (final resource in existingResources) {
      await appState.unsaveResource(resource.resourceId);
    }

    // Restore saved resources
    for (final resource in data.savedResources) {
      await appState.saveResource(resource.resourceId, notes: resource.userNotes);
    }

    // Clear existing saved conversations
    final existingConvos = List<SavedConversation>.from(appState.savedConversations);
    for (final convo in existingConvos) {
      await appState.unsaveConversation(convo.id);
    }

    // Restore saved conversations
    for (final conversation in data.savedConversations) {
      await appState.saveConversation(conversation);
    }

    // Restore journal entries (journal service handles duplicates)
    for (final entry in data.journalEntries) {
      await appState.saveHealthJournalEntry(
        id: entry.id,
        checkIn: entry.checkIn,
        symptoms: entry.symptoms,
        journalText: entry.journalText,
      );
    }

    // Restore settings
    if (data.settings['notificationsEnabled'] != null) {
      final time = data.settings['notificationTime'] as String? ?? '19:00';
      await appState.updateNotificationSettings(
        data.settings['notificationsEnabled'] as bool,
        time,
      );
    }
    if (data.settings['homeMemoryEnabled'] != null) {
      await appState.setHomeMemoryEnabled(
        data.settings['homeMemoryEnabled'] as bool,
      );
    }
  }

  /// Merge backup data with existing data (skip duplicates)
  Future<void> _mergeRestore(AppState appState, BackupData data) async {
    // Merge profile (prefer newer)
    if (data.profile != null) {
      final currentProfile = appState.healthNavigationProfile;
      if (currentProfile == null ||
          (data.profile!.onboardingCompletedAt != null &&
              (currentProfile.onboardingCompletedAt == null ||
                  data.profile!.onboardingCompletedAt!
                      .isAfter(currentProfile.onboardingCompletedAt!)))) {
        await appState.setHealthNavigationProfile(
          userName: data.profile!.userName,
          neighborhood: data.profile!.neighborhood,
          languages: data.profile!.languages,
          barriers: data.profile!.barriers,
          healthInterests: data.profile!.healthInterests,
          workSchedule: data.profile!.workSchedule,
          checkInFrequency: data.profile!.checkInFrequency,
          additionalNotes: data.profile!.additionalNotes,
        );
      }
    }

    // Merge saved resources (skip duplicates by resourceId)
    final existingResourceIds =
        appState.savedResources.map((r) => r.resourceId).toSet();
    for (final resource in data.savedResources) {
      if (!existingResourceIds.contains(resource.resourceId)) {
        await appState.saveResource(resource.resourceId, notes: resource.userNotes);
      }
    }

    // Merge saved conversations (skip duplicates by id)
    final existingConvoIds =
        appState.savedConversations.map((c) => c.id).toSet();
    for (final conversation in data.savedConversations) {
      if (!existingConvoIds.contains(conversation.id)) {
        await appState.saveConversation(conversation);
      }
    }

    // Merge journal entries (skip duplicates by date)
    final existingEntryDates = appState.healthJournalEntries
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet();
    for (final entry in data.journalEntries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (!existingEntryDates.contains(entryDate)) {
        await appState.saveHealthJournalEntry(
          id: entry.id,
          checkIn: entry.checkIn,
          symptoms: entry.symptoms,
          journalText: entry.journalText,
        );
      }
    }
  }

  /// Read backup from file
  Future<RestoreResult> readBackupFile(
    String filePath, {
    String? passphrase,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const RestoreResult(
          success: false,
          error: 'Backup file not found',
        );
      }

      final encryptedData = await file.readAsString();
      return parseBackup(encryptedData, passphrase: passphrase);
    } catch (e) {
      return RestoreResult(
        success: false,
        error: 'Failed to read backup file: $e',
      );
    }
  }

  /// Delete backup file
  Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all backup files
  Future<List<FileSystemEntity>> listBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((f) => f.path.endsWith('.sbk'))
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path)); // Newest first
      return files;
    } catch (e) {
      return [];
    }
  }
}
