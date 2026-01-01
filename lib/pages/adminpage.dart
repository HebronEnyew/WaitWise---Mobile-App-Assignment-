import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wait_wise/services/supabase_service.dart';

class Adminpage extends StatefulWidget {
  final String serviceName;
  const Adminpage({super.key, required this.serviceName});

  @override
  State<Adminpage> createState() => _AdminPageState();
}

class _AdminPageState extends State<Adminpage> {
  List<Map<String, dynamic>> _users = [];
  RealtimeChannel? _channel;
  final Map<dynamic, bool> _checked = {};

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    _channel = SupabaseService.instance.subscribeToUsers(
      widget.serviceName,
      (newUser) {
        _load();
      },
      (deletedUser) {
        _load();
      },
    );
  }

  Future<void> _load() async {
    final svc = SupabaseService.instance;
    final users = await svc.getUsersByService(widget.serviceName);
    setState(() {
      _users = users;
      // reset checked states for current users
      _checked.clear();
      for (var i = 0; i < _users.length; i++) {
        final id = (_users[i]['id'] as num?)?.toInt() ?? i;
        _checked[id] = false;
      }
    });
  }

  Future<void> _onChecked(Map<String, dynamic> user) async {
    final id = user['id'] as int?;
    if (id != null) {
      try {
        await SupabaseService.instance.deleteUserById(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${widget.serviceName}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF5CC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EEC9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                Icon(Icons.apartment, size: 80, color: Colors.black87),

                const SizedBox(height: 12),

                const Text(
                  'Check off served customers to reduce wait count',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'List of people registered for ${widget.serviceName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),

                const SizedBox(height: 12),

                _tableHeader(),

                ..._users.asMap().entries.map((e) {
                  final idx = e.key + 1;
                  final u = e.value;
                  final id = (u['id'] as num?)?.toInt() ?? idx;
                  return _tableRow(
                    idx.toString(),
                    (u['service_number'] ?? '').toString(),
                    (u['name'] ?? ''),
                    id,
                    () => _onChecked(u),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text('no', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              'service no',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'full name',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _tableRow(
    String no,
    String serviceNo,
    String name,
    dynamic id,
    Future<void> Function() onChecked,
  ) {
    final checked = _checked[id] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(no)),
          Expanded(child: Text(serviceNo)),
          Expanded(flex: 2, child: Text(name)),
          // show right-arrow icon when checked, otherwise show checkbox
          checked
              ? IconButton(
                  onPressed: () async {
                    setState(() {
                      _checked[id] = false;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                  ),
                )
              : Checkbox(
                  value: checked,
                  onChanged: (val) async {
                    setState(() {
                      _checked[id] = true;
                    });
                    await onChecked();
                    // reload to reflect deletion
                    await _load();
                  },
                ),
        ],
      ),
    );
  }
}
