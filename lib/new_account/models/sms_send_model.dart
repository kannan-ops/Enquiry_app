class SmsSendResponse {
  final String? verificationId;
  final String? responseCode;
  final String? message;

  SmsSendResponse({
    this.verificationId,
    this.responseCode,
    this.message,
  });

  factory SmsSendResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] : null;
    final verId = json['verificationId']?.toString() ?? data?['verificationId']?.toString();
    final code = json['responseCode']?.toString() ?? json['code']?.toString() ?? data?['responseCode']?.toString();
    final msg = json['message']?.toString() ?? data?['message']?.toString();

    return SmsSendResponse(
      verificationId: verId,
      responseCode: code,
      message: msg,
    );
  }
}
