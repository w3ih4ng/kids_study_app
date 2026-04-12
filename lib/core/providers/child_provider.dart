import 'package:flutter/material.dart';
import '../../models/child_model.dart';

class ChildProvider extends ChangeNotifier {
  ChildModel? _activeChild;

  ChildModel? get activeChild => _activeChild;

  void setActiveChild(ChildModel child) {
    _activeChild = child;
    notifyListeners();
  }

  void clearActiveChild() {
    _activeChild = null;
    notifyListeners();
  }
}