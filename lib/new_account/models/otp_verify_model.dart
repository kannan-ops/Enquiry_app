class OtpVerifyResponse {
  final bool isSuccess;
  final String? responseCode;
  final String? message;

  OtpVerifyResponse({
    required this.isSuccess,
    this.responseCode,
    this.message,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    final responseCode = json['responseCode']?.toString() ?? json['code']?.toString();
    final message = json['message']?.toString();
    final isSuccess = responseCode == '200' || 
                      json['status'] == 'success' || 
                      (message != null && message.toLowerCase().contains('success'));

    return OtpVerifyResponse(
      isSuccess: isSuccess,
      responseCode: responseCode,
      message: message,
    );
  }
}
