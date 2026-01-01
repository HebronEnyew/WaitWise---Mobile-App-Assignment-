import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wait_wise/pages/registerPage.dart';
import 'package:wait_wise/services/supabase_service.dart';
import 'package:wait_wise/config/services.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  _ServicePageState createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final Map<String, int> _queueCounts = {
    "New Id card": 0,
    "Renew Id card": 0,
    "Tax payment": 0,
    "Birth certificate": 0,
  };

  final Map<String, String> _serviceMapping = serviceNameToKey;

  // Use shared `services` from config
  List<Map<String, dynamic>> servicesList = services;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadQueueCounts();
    _setupRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    _channel = SupabaseService.instance.client
        .channel('service_queue_counts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            final serviceName = payload.newRecord['service_name'] as String?;
            if (serviceName != null) {
              _updateQueueCount(serviceName);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            final serviceName = payload.oldRecord['service_name'] as String?;
            if (serviceName != null) {
              _updateQueueCount(serviceName);
            }
          },
        )
        .subscribe();
  }

  void _updateQueueCount(String serviceName) {
    _loadQueueCountForService(serviceName);
  }

  Future<void> _loadQueueCounts() async {
    for (var service in servicesList) {
      final serviceName = service["name"] as String;
      final dbServiceName =
          _serviceMapping[serviceName] ?? serviceName.toLowerCase();
      await _loadQueueCountForService(dbServiceName);
    }
  }

  Future<void> _loadQueueCountForService(String dbServiceName) async {
    try {
      final users = await SupabaseService.instance.getUsersByService(
        dbServiceName,
      );
      final displayName = _serviceMapping.entries
          .firstWhere(
            (e) => e.value == dbServiceName,
            orElse: () => MapEntry(dbServiceName, dbServiceName),
          )
          .key;
      if (mounted) {
        setState(() {
          _queueCounts[displayName] = users.length;
        });
      }
    } catch (e) {
      print('Error loading queue count: $e');
    }
  }

  int _getQueueCount(String serviceName) {
    return _queueCounts[serviceName] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5CC),

      appBar: AppBar(
        backgroundColor: Color(0xFFFFF5CC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Select service",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: servicesList.length,
                itemBuilder: (context, index) {
                  final service = servicesList[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterPage(
                            serviceName: service["name"] as String,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: _buildServiceCard(
                      service["name"],
                      _getQueueCount(service["name"]),
                      service["time"],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 10),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(name, queue, time) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  "no of people waiting for this\nservice",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              "$queue",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),

          SizedBox(width: 12),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Text(
                  "Estimated time for one person\n",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2),
                Text(
                  "$time min",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.yellow[700],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            },
            icon: Icon(Icons.home_outlined, color: Colors.black, size: 30),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/userlogin");
            },
            icon: Icon(Icons.person_search, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }
}
