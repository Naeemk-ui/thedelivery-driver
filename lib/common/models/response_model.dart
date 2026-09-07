class ResponseModel {
  final bool _isSuccess;
  final String? _message;
  final bool onboardingRequired;
  ResponseModel(this._isSuccess, this._message,
      {this.onboardingRequired = false});

  String? get message => _message;
  bool get isSuccess => _isSuccess;
}
