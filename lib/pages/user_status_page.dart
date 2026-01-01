import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wait_wise/services/supabase_service.dart';
import 'package:wait_wise/config/services.dart' as svc_cfg;

class UserStatusPage extends StatefulWidget {
  final String userName;
  final List<Map<String, dynamic>> userRegistrations;

  const UserStatusPage({
    super.key,
    required this.userName,
    required this.userRegistrations,
  });

  @override
  State<UserStatusPage> createState() => _UserStatusPageState();
}

class _UserStatusPageState extends State<UserStatusPage> {
  List<Map<String, dynamic>> _registrations = [];
  Map<String, List<Map<String, dynamic>>> _queueData = {};
  Map<String, int> _peopleAhead = {};
  Map<String, int> _estimatedMinutes = {};
  Map<String, bool> _isNext = {};
  Map<String, RealtimeChannel> _channels = {};
  // Use centralized service times from config
  Map<String, int> get _serviceTimes => svc_cfg.serviceKeyToTime;

  @override
  void initState() {
    super.initState();
    _registrations = _getUniqueRegistrations(widget.userRegistrations);
    _setupRealtime();
    _loadInitialData();
  }

  List<Map<String, dynamic>> _getUniqueRegistrations(
    List<Map<String, dynamic>> registrations,
  ) {
    final Map<String, Map<String, dynamic>> unique = {};
    for (var reg in registrations) {
      final serviceName = reg['service_name'] as String? ?? '';
      final regId = (reg['id'] as num?)?.toInt() ?? 0;
      final key = serviceName;

      if (!unique.containsKey(key)) {
        unique[key] = reg;
      } else {
        final existingId = (unique[key]?['id'] as num?)?.toInt() ?? 0;
        if (regId > existingId) {
          unique[key] = reg;
        }
      }
    }
    return unique.values.toList();
  }

  @override
  void dispose() {
    for (var channel in _channels.values) {
      channel.unsubscribe();
    }
    super.dispose();
  }

  void _setupRealtime() {
    final uniqueServices = _registrations
        .map((r) => r['service_name'] as String)
        .toSet();

    for (var serviceName in uniqueServices) {
      final channel = SupabaseService.instance.client
          .channel('user_status_$serviceName')
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'service_name',
              value: serviceName,
            ),
            callback: (_) => _updateQueueData(serviceName),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'service_name',
              value: serviceName,
            ),
            callback: (_) => _updateQueueData(serviceName),
          )
          .subscribe();

      _channels[serviceName] = channel;
    }
  }

  Future<void> _loadInitialData() async {
    for (var registration in _registrations) {
      final serviceName = registration['service_name'] as String;
      await _updateQueueData(serviceName);
    }
  }

  Future<void> _updateQueueData(String serviceName) async {
    try {
      final allUsers = await SupabaseService.instance.getUsersByService(
        serviceName,
      );

      final userRegs = _registrations
          .where((r) => r['service_name'] == serviceName)
          .toList();

      if (userRegs.isEmpty) {
        setState(() {
          _queueData[serviceName] = allUsers;
        });
        return;
      }

      for (var userReg in userRegs) {
        final userServiceNumber =
            (userReg['service_number'] as num?)?.toInt() ?? 0;
        final regKey = serviceName;
        final wasNext = _isNext[regKey] ?? false;

        final usersAhead = allUsers.where((u) {
          final serviceNum = (u['service_number'] as num?)?.toInt() ?? 0;
          return serviceNum < userServiceNumber;
        }).toList();

        final peopleAhead = usersAhead.length;
        final baseTime = _getBaseTimeForService(serviceName);
        final estimatedTime = _calculateEstimatedTime(
          serviceName,
          peopleAhead,
          baseTime,
        );
        final isNext = peopleAhead == 0 && allUsers.isNotEmpty;

        setState(() {
          _queueData[serviceName] = allUsers;
          _peopleAhead[regKey] = peopleAhead;
          _estimatedMinutes[regKey] = estimatedTime;
          _isNext[regKey] = isNext;
        });

        if (isNext && !wasNext) {
          _showNotification(serviceName);
        }
      }
    } catch (e) {
      print('Error updating queue data: $e');
    }
  }

  int _calculateEstimatedTime(
    String serviceName,
    int peopleAhead,
    int baseTime,
  ) {
    if (peopleAhead == 0) return 0;

    final perPerson = _estimateTimePerPerson(serviceName, baseTime);
    final estimated = peopleAhead * perPerson;
    return estimated > 0 ? estimated : peopleAhead * baseTime;
  }

  int _estimateTimePerPerson(String serviceName, int baseTime) {
    final allUsers = _queueData[serviceName] ?? [];
    if (allUsers.isEmpty) return baseTime;

    final completedUsers = allUsers.where((u) {
      final created = u['created_at'];
      if (created == null) return false;
      try {
        final createdTime = DateTime.parse(created.toString());
        final now = DateTime.now();
        final diff = now.difference(createdTime).inMinutes;
        return diff > 0 && diff < 120;
      } catch (_) {
        return false;
      }
    }).toList();

    if (completedUsers.length < 2) return baseTime;

    completedUsers.sort((a, b) {
      final aTime = DateTime.parse(a['created_at'].toString());
      final bTime = DateTime.parse(b['created_at'].toString());
      return aTime.compareTo(bTime);
    });

    int totalTime = 0;
    int count = 0;

    for (int i = 1; i < completedUsers.length && i < 20; i++) {
      try {
        final prevTime = DateTime.parse(
          completedUsers[i - 1]['created_at'].toString(),
        );
        final currTime = DateTime.parse(
          completedUsers[i]['created_at'].toString(),
        );
        final diff = currTime.difference(prevTime).inMinutes;
        if (diff > 0 && diff < 60) {
          totalTime += diff;
          count++;
        }
      } catch (_) {}
    }

    return count > 0 ? (totalTime / count).round() : baseTime;
  }

  int _getBaseTimeForService(String serviceName) {
    // serviceName is expected to be the service key (e.g. newId)
    if (_serviceTimes.containsKey(serviceName))
      return _serviceTimes[serviceName]!;

    // Try mapping from display name
    final key = svc_cfg.serviceNameToKey.entries
        .firstWhere(
          (e) => e.key.toLowerCase() == serviceName.toLowerCase(),
          orElse: () => const MapEntry('', ''),
        )
        .value;
    if (key.isNotEmpty && _serviceTimes.containsKey(key))
      return _serviceTimes[key]!;

    // Fallback heuristics
    final lower = serviceName.toLowerCase();
    if (lower.contains('new')) return _serviceTimes['newId'] ?? 5;
    if (lower.contains('renew')) return _serviceTimes['renewID'] ?? 5;
    if (lower.contains('tax')) return _serviceTimes['taxPayment'] ?? 5;
    if (lower.contains('birth')) return _serviceTimes['birthCertificate'] ?? 5;

    return 5;
  }

  void _showNotification(String serviceName) {
    final displayName = _getServiceDisplayName(serviceName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'It\'s your turn for $displayName!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getServiceDisplayName(String serviceName) {
    final mapping = {
      'newId': 'New Id card',
      'renewID': 'Renew Id card',
      'taxPayment': 'Tax payment',
      'birthCertificate': 'Birth certificate',
    };
    return mapping[serviceName] ?? serviceName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5CC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.userName}\'s Status',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _registrations.isEmpty
          ? const Center(
              child: Text(
                'No registrations found',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _registrations.length,
              itemBuilder: (context, index) {
                final registration = _registrations[index];
                final serviceName = registration['service_name'] as String;
                final serviceNumber =
                    (registration['service_number'] as num?)?.toInt() ?? 0;
                final regKey = serviceName;
                final peopleAhead = _peopleAhead[regKey] ?? 0;
                final estimatedTime = _estimatedMinutes[regKey] ?? 0;
                final isNext = _isNext[regKey] ?? false;

                return _buildStatusCard(
                  serviceName,
                  serviceNumber,
                  peopleAhead,
                  estimatedTime,
                  isNext,
                );
              },
            ),
    );
  }

  Widget _buildStatusCard(
    String serviceName,
    int serviceNumber,
    int peopleAhead,
    int estimatedTime,
    bool isNext,
  ) {
    final displayName = _getServiceDisplayName(serviceName);
    final allUsers = _queueData[serviceName] ?? [];
    final totalInQueue = allUsers.length;
    final position =
        allUsers.indexWhere(
          (u) => (u['service_number'] as num?)?.toInt() == serviceNumber,
        ) +
        1;
    final progress = totalInQueue > 0 ? position / totalInQueue : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isNext ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isNext)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Your Turn!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoBox(
                'Service No',
                serviceNumber.toString(),
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildInfoBox(
                'Position',
                '$position/$totalInQueue',
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildInfoBox('Ahead', peopleAhead.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                estimatedTime > 0
                    ? 'Estimated wait: $estimatedTime minutes'
                    : 'You are next!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isNext ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
