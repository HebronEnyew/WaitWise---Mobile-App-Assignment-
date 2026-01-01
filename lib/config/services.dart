
const List<Map<String, dynamic>> services = [
  {"name": "New Id card", "time": 20, "key": "newId"},
  {"name": "Renew Id card", "time": 15, "key": "renewID"},
  {"name": "Tax payment", "time": 40, "key": "taxPayment"},
  {"name": "Birth certificate", "time": 30, "key": "birthCertificate"},
];

final Map<String, String> serviceNameToKey = {
  for (var s in services) (s['name'] as String): (s['key'] as String),
};

final Map<String, int> serviceKeyToTime = {
  for (var s in services) (s['key'] as String): (s['time'] as int),
};
