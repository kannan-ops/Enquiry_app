class CheckPhoneResponse {
  final bool exists;
  final String? message;

  CheckPhoneResponse({
    required this.exists,
    this.message,
  });

  factory CheckPhoneResponse.fromJson(Map<String, dynamic> json) {
    // API responses can be nested in data or root level
    final outerData = json['data'] ?? json;
    
    // Check key 'exists' or 'is_exists' or check if the status/exists is boolean
    bool existsVal = false;
    if (outerData is Map) {
      existsVal = outerData['exists'] == true || 
                  outerData['isExists'] == true || 
                  outerData['is_exists'] == true ||
                  outerData['exist'] == true ||
                  outerData['status'] == 'exists';
    }
    
    return CheckPhoneResponse(
      exists: existsVal,
      message: json['message']?.toString() ?? outerData['message']?.toString(),
    );
  }
}
