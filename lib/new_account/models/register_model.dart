class RegisterRequest {
  final String email;
  final String password;
  final String userName;
  final String? address;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.userName,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'email_otp': false,
      'mobile_otp': false,
      'status': 1,
      'is_verified': 1,
      'created_by': 'user',
      'user_type': 'guest',
      'user_name': userName,
      if (address != null) 'address': address,
    };
  }
}

class RegisterResponse {
  final bool isSuccess;
  final String? message;

  RegisterResponse({
    required this.isSuccess,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final outerData = json['data'] ?? json;
    bool success = false;
    String? msg = json['message']?.toString();

    if (outerData is Map) {
      final innerData = outerData['data'] ?? outerData;
      if (innerData is Map) {
        success = innerData['result'] == 'Success' || 
                  innerData['code'] == 200 || 
                  innerData['status'] == 200 ||
                  innerData['success'] == true;
        msg = msg ?? innerData['message']?.toString();
      }
    }

    return RegisterResponse(
      isSuccess: success,
      message: msg,
    );
  }
}
