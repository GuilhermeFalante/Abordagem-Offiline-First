import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'database_service.dart';
import '../models/task.dart';

class SyncService {
  SyncService._init();
  static final SyncService instance = SyncService._init();

  // Keep a short-lived set of recently synced task ids to show a "synced" badge
  final Set<int> _recentlySynced = {};

  bool isRecentlySynced(int id) => _recentlySynced.contains(id);

  void _markRecentlySynced(int id) {
    _recentlySynced.add(id);
    // remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      _recentlySynced.remove(id);
    });
  }

  /// Process the sync_queue: for each entry, simulate sending to server and
  /// on success remove the entry and mark the local task as not pending.
  Future<void> processQueue() async {
    final conn = await Connectivity().checkConnectivity();
    final isOnline = conn != ConnectivityResult.none;
    if (!isOnline) return;

    final db = DatabaseService.instance;
    final entries = await db.readSyncQueue();

    for (final entry in entries) {
      try {
        final int? queueId = entry['id'] as int?;
        final String action = entry['action'] as String;
        final int? taskId = (entry['taskId'] is int) ? entry['taskId'] as int : null;
        // Parse payload (local task snapshot at enqueue time)
        final String payload = entry['payload'] as String;
        final Map<String, dynamic> localMap = jsonDecode(payload) as Map<String, dynamic>;
        final localTask = Task.fromMap(localMap);

        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 200));

        // FETCH remote version (stub). Replace with real API call.
        final Map<String, dynamic>? remote = await _fetchRemoteTask(taskId);

        if (action == 'delete') {
          // Inform server about delete (stub)
          final pushed = await _pushDeleteToServer(taskId);
          if (pushed && queueId != null) await db.removeSyncEntry(queueId);
          // local row likely already removed when enqueued
        } else {
          // CREATE or UPDATE: apply LWW: compare lastModified timestamps
          if (remote != null && remote['lastModified'] != null) {
            final remoteLast = DateTime.parse(remote['lastModified'] as String);
            if (remoteLast.isAfter(localTask.lastModified)) {
              // Server has newer version -> overwrite local
              final serverTask = Task.fromMap(remote);
              // write serverTask to local DB and mark not pending (preserve server lastModified)
              await db.applyServerTask(serverTask);
              if (serverTask.id != null) _markRecentlySynced(serverTask.id!);
            } else {
              // Local is newer -> push to server
              final pushed = await _pushToServer(localTask);
              if (pushed) {
                // mark local as synced
                if (localTask.id != null) {
                  await db.update(localTask.copyWith(pending: false));
                  _markRecentlySynced(localTask.id!);
                }
              }
            }
          } else {
            // No remote version -> push local to server (create)
            final pushed = await _pushToServer(localTask);
            if (pushed && localTask.id != null) {
              await db.update(localTask.copyWith(pending: false));
              _markRecentlySynced(localTask.id!);
            }
          }

          // remove queue entry after processing
          if (queueId != null) await db.removeSyncEntry(queueId);
        }
      } catch (_) {
        // If one entry fails, skip and continue; will retry later
        continue;
      }
    }
  }

  // ----- Stubs for remote interactions (replace with real API calls) -----
  Future<Map<String, dynamic>?> _fetchRemoteTask(int? id) async {
    // TODO: Implement actual HTTP GET to server to retrieve task by id.
    // Return null if remote not found. For now return null to indicate no remote.
    return null;
  }

  Future<bool> _pushToServer(Task task) async {
    // TODO: Implement actual HTTP POST/PUT to push task to server.
    // Should include task.lastModified so server can store its timestamp.
    // For demo we assume success.
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  Future<bool> _pushDeleteToServer(int? id) async {
    // TODO: Implement actual HTTP DELETE to remove remote task.
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}
