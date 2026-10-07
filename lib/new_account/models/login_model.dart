class LoginResponse {
  final bool isSuccess;
  final String? token;
  final int? id;
  final String email;
  final String userName;
  final String userMainId;
  final String virtualId;
  final String userType;
  final String? message;

  LoginResponse({
    required this.isSuccess,
    this.token,
    this.id,
    required this.email,
    required this.userName,
    required this.userMainId,
    required this.virtualId,
    required this.userType,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    try {
      final outerData = json['data'] ?? json;
      if (outerData is Map) {
        final loginData = outerData['data'];
        final String? tokenVal = outerData['token']?.toString();
        
        if (loginData is Map) {
          return LoginResponse(
            isSuccess: true,
            token: tokenVal,
            id: loginData['id'] is int ? loginData['id'] : int.tryParse(loginData['id']?.toString() ?? ''),
            email: loginData['email']?.toString() ?? '',
            userName: loginData['user_name']?.toString() ?? '',
            userMainId: loginData['user_main_id']?.toString() ?? '',
            virtualId: loginData['virtual_id']?.toString() ?? '',
            userType: loginData['user_type']?.toString() ?? '',
            message: json['message']?.toString(),
          );
        }
      }
      return LoginResponse(
        isSuccess: false,
        email: '',
        userName: '',
        userMainId: '',
        virtualId: '',
        userType: '',
        message: 'Invalid login data format',
      );
    } catch (e) {
      return LoginResponse(
        isSuccess: false,
        email: '',
        userName: '',
        userMainId: '',
        virtualId: '',
        userType: '',
        message: 'Parsing error: $e',
      );
    }
  }
}
