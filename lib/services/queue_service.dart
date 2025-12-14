/// QueueService manages user registrations and queue positions for different services.
/// This is a singleton service that maintains queues across the app.
class QueueService {
  // Singleton pattern implementation
  static final QueueService _instance = QueueService._internal();
  
  /// Factory constructor that returns the singleton instance
  factory QueueService() => _instance;
  
  /// Private constructor for singleton pattern
  QueueService._internal();

  // Map to store queues for each service
  // Key: service name (String), Value: List of user registrations (Map<String, dynamic>)
  final Map<String, List<Map<String, dynamic>>> _queues = {};

  /// Registers a user for a service and returns their queue number.
  /// 
  /// [serviceName] - The name of the service the user is registering for
  /// [userData] - Map containing user information (fullName, phone, kebeleId)
  /// 
  /// Returns the queue number assigned to the user (int)
  int registerUser(String serviceName, Map<String, dynamic> userData) {
    // Validate inputs
    if (serviceName.isEmpty) {
      throw ArgumentError('Service name cannot be empty');
    }
    
    // Initialize queue for service if it doesn't exist
    if (!_queues.containsKey(serviceName)) {
      _queues[serviceName] = [];
    }

    // Calculate queue number (next in line)
    final queueNumber = _queues[serviceName]!.length + 1;
    
    // Create a new map to avoid modifying the original userData
    final newUserData = <String, dynamic>{
      ...userData,
      'queueNumber': queueNumber, // int - user's position in queue
      'serviceName': serviceName, // String - service they registered for
      'registeredAt': DateTime.now(), // DateTime - when they registered
    };
    
    // Add user to the queue
    _queues[serviceName]!.add(newUserData);

    return queueNumber;
  }

  // Get user's position in queue
  int getUserPosition(String serviceName, int queueNumber) {
    if (!_queues.containsKey(serviceName)) {
      return 0;
    }
    final index = _queues[serviceName]!.indexWhere((user) {
      final userQueueNumber = user['queueNumber'];
      // Handle both int and dynamic types
      if (userQueueNumber is int) {
        return userQueueNumber == queueNumber;
      }
      return false;
    });
    return index >= 0 ? index + 1 : 0;
  }

  // Get total number of people in queue for a service
  int getTotalInQueue(String serviceName) {
    return _queues[serviceName]?.length ?? 0;
  }

  // Get number of people ahead of user
  int getPeopleAhead(String serviceName, int queueNumber) {
    final position = getUserPosition(serviceName, queueNumber);
    return position > 0 ? position - 1 : 0;
  }

  // Get user data by service and queue number
  Map<String, dynamic>? getUserData(String serviceName, int queueNumber) {
    if (!_queues.containsKey(serviceName)) {
      return null;
    }
    try {
      return _queues[serviceName]!.firstWhere(
        (user) {
          final userQueueNumber = user['queueNumber'];
          if (userQueueNumber is int) {
            return userQueueNumber == queueNumber;
          }
          return false;
        },
      );
    } catch (e) {
      return null;
    }
  }

  // Get all users in queue for a service (for admin purposes)
  List<Map<String, dynamic>> getQueueForService(String serviceName) {
    return _queues[serviceName] ?? [];
  }

  // Remove user from queue (when served)
  void removeUser(String serviceName, int queueNumber) {
    if (_queues.containsKey(serviceName)) {
      _queues[serviceName]!.removeWhere(
        (user) {
          final userQueueNumber = user['queueNumber'];
          if (userQueueNumber is int) {
            return userQueueNumber == queueNumber;
          }
          return false;
        },
      );
    }
  }
}

