class CheckEmailResponse {
  final bool exists;
  final String? message;

  CheckEmailResponse({
    required this.exists,
    this.message,
  });

  factory CheckEmailResponse.fromJson(Map<String, dynamic> json) {
    final outerData = json['data'] ?? json;
    bool existsVal = false;
    
    if (outerData is Map) {
      existsVal = outerData['exists'] == true || 
                  outerData['isExists'] == true || 
                  outerData['is_exists'] == true ||
                  outerData['exist'] == true ||
                  outerData['status'] == 'exists';
    }
    
    return CheckEmailResponse(
      exists: existsVal,
      message: json['message']?.toString() ?? outerData['message']?.toString(),
    );
  }
}
