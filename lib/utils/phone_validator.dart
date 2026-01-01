class PhoneValidator {
  static bool isValidEthiopianPhone(String phone) {
    if (phone.isEmpty) return false;
    
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.startsWith('+251')) {
      final number = cleaned.substring(4);
      if (number.length == 9 && number.startsWith('9')) {
        return true;
      }
    }
    
    if (cleaned.startsWith('251')) {
      final number = cleaned.substring(3);
      if (number.length == 9 && number.startsWith('9')) {
        return true;
      }
    }
    
    if (cleaned.startsWith('09')) {
      if (cleaned.length == 10 && RegExp(r'^09\d{8}$').hasMatch(cleaned)) {
        return true;
      }
    }
    
    if (cleaned.startsWith('9')) {
      if (cleaned.length == 9 && RegExp(r'^9\d{8}$').hasMatch(cleaned)) {
        return true;
      }
    }
    
    return false;
  }
  
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.startsWith('+251')) {
      return cleaned.substring(1);
    }
    
    if (cleaned.startsWith('251')) {
      return '+$cleaned';
    }
    
    if (cleaned.startsWith('09')) {
      return '+251${cleaned.substring(1)}';
    }
    
    if (cleaned.startsWith('9') && cleaned.length == 9) {
      return '+251$cleaned';
    }
    
    return cleaned;
  }
  
  static String getErrorMessage() {
    return 'Please enter a valid Ethiopian phone number\nFormat: 09XXXXXXXX or +2519XXXXXXXX';
  }
}

