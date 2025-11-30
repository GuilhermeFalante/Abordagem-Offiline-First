import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'database_service.dart';
import '../models/task.dart';

class SyncService {
  SyncService._init();
  static final SyncService instance = SyncService._init();

  final Set<int> _recentlySynced = {};
  final Map<int, String> _lastResolutions = {};

  bool isRecentlySynced(int id) => _recentlySynced.contains(id);

  void _markRecentlySynced(int id) {
    _recentlySynced.add(id);
    Timer(const Duration(seconds: 4), () {
      _recentlySynced.remove(id);
    });
  }
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
        final String payload = entry['payload'] as String;
        final Map<String, dynamic> localMap = jsonDecode(payload) as Map<String, dynamic>;
        final localTask = Task.fromMap(localMap);

        await Future.delayed(const Duration(milliseconds: 200));

        if (action == 'server_update') {
          final serverMap = jsonDecode(payload) as Map<String, dynamic>;
          final serverTask = Task.fromMap(serverMap);
          print('[SYNC] Processing server_update for id=${serverTask.id} serverLastModified=${serverTask.lastModified.toIso8601String()}');
          await db.applyServerTask(serverTask);
          if (serverTask.id != null) _markRecentlySynced(serverTask.id!);
          if (serverTask.id != null) _lastResolutions[serverTask.id!] = 'server';
          if (queueId != null) await db.removeSyncEntry(queueId);
          continue;
        }

        final Map<String, dynamic>? remote = await _fetchRemoteTask(taskId);

        if (action == 'delete') {
          final pushed = await _pushDeleteToServer(taskId);
          if (pushed && queueId != null) await db.removeSyncEntry(queueId);
        } else {
          if (remote != null && remote['lastModified'] != null) {
            final remoteLast = DateTime.parse(remote['lastModified'] as String);
            if (remoteLast.isAfter(localTask.lastModified)) {
              final serverTask = Task.fromMap(remote);
                print('[SYNC] Remote is newer for id=${serverTask.id}. remoteLast=$remoteLast localLast=${localTask.lastModified} -> applying SERVER');
                await db.applyServerTask(serverTask);
                if (serverTask.id != null) _markRecentlySynced(serverTask.id!);
                if (serverTask.id != null) _lastResolutions[serverTask.id!] = 'server';
            } else {
              final pushed = await _pushToServer(localTask);
              if (pushed) {
                if (localTask.id != null) {
                  await db.update(localTask.copyWith(pending: false));
                  _markRecentlySynced(localTask.id!);
                    print('[SYNC] Local is newer for id=${localTask.id}. localLast=${localTask.lastModified} remoteLast=$remoteLast -> pushing LOCAL');
                    _lastResolutions[localTask.id!] = 'local';
                }
              }
            }
          } else {
            final pushed = await _pushToServer(localTask);
            if (pushed && localTask.id != null) {
              await db.update(localTask.copyWith(pending: false));
              _markRecentlySynced(localTask.id!);
              print('[SYNC] No remote exists for id=${localTask.id} -> pushed LOCAL with lastModified=${localTask.lastModified.toIso8601String()}');
              _lastResolutions[localTask.id!] = 'local';
            }
          }

          if (queueId != null) await db.removeSyncEntry(queueId);
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteTask(int? id) async {
    return null;
  }

  Future<bool> _pushToServer(Task task) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  Future<bool> _pushDeleteToServer(int? id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
  Future<bool> simulateServerEdit(int? taskId) async {
    if (taskId == null) return false;
    final db = DatabaseService.instance;
    final local = await db.read(taskId);
    if (local == null) return false;

    final serverTs = DateTime.now().add(const Duration(seconds: 30));
    final serverTask = local.copyWith(
      lastModified: serverTs,
      pending: false,
      description: '${local.description} (alterado no servidor)'
    );

    print('[SYNC] Simulating server edit for id=${taskId} serverLastModified=${serverTs.toIso8601String()} (enqueued)');
    await db.enqueueServerChange(serverTask);
    return true;
  }
  Map<int, String> takeLastResolutions() {
    final copy = Map<int, String>.from(_lastResolutions);
    _lastResolutions.clear();
    return copy;
  }
}
