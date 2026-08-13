/// Synchronization Manager for processing offline queue.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../network/network_info.dart';
import '../local_db/local_database_service.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.read(dioProvider),
    ref.read(localDatabaseProvider),
    ref.read(networkInfoProvider),
  );
  return manager;
});

class SyncManager {
  final Dio _dio;
  final LocalDatabaseService _localDb;
  final NetworkInfo _networkInfo;
  bool _isSyncing = false;

  SyncManager(this._dio, this._localDb, this._networkInfo) {
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncPendingJobs();
      }
    });
  }

  Future<void> syncPendingJobs() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) return;

      final jobs = await _localDb.getPendingSyncJobs();

      for (final job in jobs) {
        await _processJob(job);
      }
    } catch (e) {
      // Log or handle global sync error
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processJob(Map<String, dynamic> job) async {
    final id = job['id'] as int;
    final action = job['action'] as String;
    final entityType = job['entity_type'] as String;
    final payloadStr = job['payload'] as String;

    try {
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

      if (entityType == 'customer') {
        if (action == 'CREATE') {
          final response = await _dio.post(
            ApiEndpoints.customers,
            data: payload,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            // Extract server ID, fallback to parsing if it's nested differently based on Api structure
            final serverId = (data is Map && data.containsKey('id'))
                ? data['id'].toString()
                : (data is Map && data['user'] != null
                      ? data['user']['id'].toString()
                      : payload['offline_id']);

            final offlineId = payload['offline_id'];

            final customer = await _localDb.getCustomerById(offlineId);
            if (customer != null) {
              final updatedCustomer = Map<String, dynamic>.from(customer);
              updatedCustomer['id'] = serverId;
              updatedCustomer['is_synced'] = 1;
              await _localDb.updateCustomer(updatedCustomer);
            }
            await _localDb.removeSyncJob(id);
          } else {
            await _localDb.updateSyncJobStatus(id, 'failed');
          }
        }
      }
      // Add UPDATE/DELETE handlers as needed
    } catch (e) {
      await _localDb.updateSyncJobStatus(id, 'failed');
    }
  }
}
