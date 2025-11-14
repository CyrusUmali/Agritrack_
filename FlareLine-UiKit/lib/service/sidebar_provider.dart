import 'package:flutter/foundation.dart';

class SidebarProvider with ChangeNotifier {
  bool _isCollapsed = false;
  bool _isPinned = true;

  bool get isCollapsed => _isCollapsed;
  bool get isPinned => _isPinned;

  void toggleCollapse() {
    if (!_isPinned) {
      _isCollapsed = !_isCollapsed;
      if (kDebugMode) {
        // print('Sidebar collapsed: $_isCollapsed');
      }
      notifyListeners();
    }
  }

  void togglePin() {
    _isPinned = !_isPinned;
    // When pinning, expand the sidebar
    // When unpinning, keep the current state or collapse if you prefer
    if (_isPinned) {
      _isCollapsed = false;
    } else {
      _isCollapsed = true;
    }

    if (kDebugMode) {
      // print('Sidebar pinned: $_isPinned');
      // print('Sidebar collapsed: $_isCollapsed');
    }
    notifyListeners();
  }

  void setCollapsed(bool value) {
    if (!_isPinned) {
      _isCollapsed = value;
      if (kDebugMode) {
        // print('Sidebar set collapsed: $_isCollapsed');
      }
      notifyListeners();
    }
  }
}
