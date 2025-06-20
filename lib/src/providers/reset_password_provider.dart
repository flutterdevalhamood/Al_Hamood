import 'package:flutter/material.dart';

class ResetPasswordProvider extends ChangeNotifier {
  SendStatus _status = SendStatus.initialize;
  VerifyStatus _verifyStatus = VerifyStatus.initialize;
  String? token;

  String _message = '';

  SendStatus get status => _status;

  VerifyStatus get verifyStatus => _verifyStatus;

  String get message => _message;
  String _email = '';

  String get email => _email;

  void notifyState(SendStatus status) {
    _status = status;
    notifyListeners();
  }

  void verifyNotifyState(VerifyStatus status) {
    _verifyStatus = status;
    notifyListeners();
  }
}

enum SendStatus { initialize, loading, success, failed }

enum VerifyStatus { initialize, loading, success, failed }
