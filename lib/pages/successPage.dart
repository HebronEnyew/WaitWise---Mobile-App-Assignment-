import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wait_wise/services/supabase_service.dart';
import 'package:wait_wise/config/services.dart' as svc_cfg;
import 'package:wait_wise/pages/homepage.dart';

class SuccessPage extends StatefulWidget {
  final String serviceName;
  final int queueNumber;

  const SuccessPage({
    super.key,
    required this.serviceName,
    required this.queueNumber,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  int _totalInQueue = 0;
  int _peopleAhead = 0;
  int _currentPosition = 0;
  int _estimatedMinutes = 0;

  String _mapServiceName(String displayName) {
    final mapping = {
      "New Id card": "newId",
      "Renew Id card": "renewID",
      "Tax payment": "taxPayment",
      "Birth certificate": "birthCertificate",
    };
    return mapping[displayName] ?? displayName.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _loadQueueData();
    _setupRealtime();
  }

  RealtimeChannel? _channel;

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final dbServiceName = _mapServiceName(widget.serviceName);
    _channel = SupabaseService.instance.subscribeToUsers(
      dbServiceName,
      (_) => _loadQueueData(),
      (_) => _loadQueueData(),
    );
  }

  Future<void> _loadQueueData() async {
    final dbServiceName = _mapServiceName(widget.serviceName);
    final users = await SupabaseService.instance.getUsersByService(
      dbServiceName,
    );
    final totalInQueue = users.length;
    final currentPosition =
        users.indexWhere(
          (u) => (u['service_number'] as num?)?.toInt() == widget.queueNumber,
        ) +
        1;
    final peopleAhead = currentPosition > 0 ? currentPosition - 1 : 0;

    // compute per-person estimate using recent completed entries
    final baseTime = svc_cfg.serviceKeyToTime[dbServiceName] ?? 5;
    final perPerson = _estimateTimePerPersonFromList(users, baseTime);
    final estimated = peopleAhead * perPerson;

    if (mounted) {
      setState(() {
        _totalInQueue = totalInQueue;
        _currentPosition = currentPosition > 0
            ? currentPosition
            : totalInQueue + 1;
        _peopleAhead = peopleAhead;
        _estimatedMinutes = estimated;
      });
    }
  }

  int _estimateTimePerPersonFromList(
    List<Map<String, dynamic>> allUsers,
    int baseTime,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final progress = _totalInQueue > 0 ? _currentPosition / _totalInQueue : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "Registered successfully!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "service registered:",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Your service number:",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "${widget.queueNumber}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Text(
                          "$_currentPosition of $_totalInQueue",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          color: Colors.black54,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFFF8C00),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          color: Colors.black54,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "your turn is after $_peopleAhead ${_peopleAhead == 1 ? 'person' : 'people'}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        "Thank you for choosing us!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(
                      Icons.home_outlined,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/userlogin");
                    },
                    icon: const Icon(
                      Icons.person_search,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
