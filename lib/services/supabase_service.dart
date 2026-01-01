import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_model.dart';

class SupabaseService {
  SupabaseService._private();
  static final SupabaseService instance = SupabaseService._private();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    await _seedData();
  }

  Future<void> _seedData() async {
    final existing = await client.from('global_counter').select().maybeSingle();
    if (existing == null) {
      final maxNumber = await _getMaxServiceNumber();
      await client.from('global_counter').insert({
        'id': 'main',
        'last_number': maxNumber,
      });
    }
    

    final List<AdminModel> admins = [
      AdminModel(id: '01', password: '1234', service: 'newId'),
      AdminModel(id: '02', password: '2345', service: 'renewID'),
      AdminModel(id: '03', password: '3456', service: 'taxPayment'),
      AdminModel(
        id: '04',
        password: '4567',
        service: 'birthCertificate',
      ),
    ];

    for (var admin in admins) {
      final existing = await client
          .from('admins')
          .select()
          .eq('id', admin.id)
          .maybeSingle();
      if (existing == null) {
        await client.from('admins').insert(admin.toMap());
      }
    }
  }

  Future<int> _getMaxServiceNumber() async {
    try {
      final response = await client
          .from('users')
          .select('service_number')
          .order('service_number', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        return (response['service_number'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      print('Error getting max service number: $e');
    }
    return 0;
  }

  Future<int> _getNextNumber(String serviceName) async {
    final counterResponse = await client
        .from('global_counter')
        .select()
        .eq('id', 'main')
        .maybeSingle();

    int nextNumber;
    if (counterResponse == null) {
      final maxNumber = await _getMaxServiceNumber();
      nextNumber = maxNumber + 1;
      await client.from('global_counter').insert({
        'id': 'main',
        'last_number': nextNumber,
      });
    } else {
      final last = (counterResponse['last_number'] as num?)?.toInt() ?? 0;
      nextNumber = last + 1;
      await client
          .from('global_counter')
          .update({'last_number': nextNumber})
          .eq('id', 'main');
    }
    return nextNumber;
  }

  Future<int> insertUser({
    required String name,
    required String phone,
    String? governmentId,
    required String serviceName,
  }) async {
    final existing = await client
        .from('users')
        .select()
        .eq('name', name)
        .eq('phone', phone)
        .eq('service_name', serviceName)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'There is already a user registered with this name and phone number for this service',
      );
    }

    final serviceNumber = await _getNextNumber(serviceName);
    await client.from('users').insert({
      'name': name,
      'phone': phone,
      'government_id': governmentId,
      'service_name': serviceName,
      'service_number': serviceNumber,
    });
    return serviceNumber;
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final response = await client
        .from('users')
        .select()
        .eq('phone', phone)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUsersByService(
    String serviceName,
  ) async {
    final response = await client
        .from('users')
        .select()
        .eq('service_name', serviceName)
        .order('service_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteUserById(int id) async {
    await client.from('users').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getAdmin(String id, String password) async {
    final response = await client
        .from('admins')
        .select()
        .eq('id', id)
        .eq('password', password)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUsersByNameAndPhone(
    String name,
    String phone,
  ) async {
    final response = await client
        .from('users')
        .select()
        .eq('name', name)
        .eq('phone', phone)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUsersAhead(
    String serviceName,
    int serviceNumber,
  ) async {
    final response = await client
        .from('users')
        .select()
        .eq('service_name', serviceName)
        .lt('service_number', serviceNumber)
        .order('service_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  RealtimeChannel subscribeToUsers(
    String serviceName,
    Function(Map<String, dynamic>) onInsert,
    Function(Map<String, dynamic>) onDelete,
  ) {
    return client
        .channel('users_$serviceName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'service_name',
            value: serviceName,
          ),
          callback: (payload) {
            onInsert(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'service_name',
            value: serviceName,
          ),
          callback: (payload) {
            onDelete(Map<String, dynamic>.from(payload.oldRecord));
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToGlobalCounter(Function(int) onUpdate) {
    return client
        .channel('global_counter')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'global_counter',
          callback: (payload) {
            final lastNumber =
                (payload.newRecord['last_number'] as num?)?.toInt() ?? 0;
            onUpdate(lastNumber);
          },
        )
        .subscribe();
  }
}
