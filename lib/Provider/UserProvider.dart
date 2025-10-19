import 'package:flutter/foundation.dart';
import 'package:lms_publisher/Service/user_right_service.dart';


class UserProvider with ChangeNotifier {
  LoginResponse? _loginResponse;
  List<MenuPermission> _menuPermissions = [];
  bool _isLoggedIn = false;

  // Getters
  LoginResponse? get loginResponse => _loginResponse;
  List<MenuPermission> get menuPermissions => _menuPermissions;
  bool get isLoggedIn => _isLoggedIn;

  // User data getters
  String? get userCode => _loginResponse?.userData['resultSet_0']?.isNotEmpty == true
      ? _loginResponse!.userData['resultSet_0'][0]['UserCode']
      : null;

  String? get userName => _loginResponse?.userData['resultSet_0']?.isNotEmpty == true
      ? _loginResponse!.userData['resultSet_0'][0]['UserName']
      : null;

  String? get userGroupCode => _loginResponse?.userData['resultSet_0']?.isNotEmpty == true
      ? _loginResponse!.userData['resultSet_0'][0]['UserGroupCode']
      : null;

  String? get userID => _loginResponse?.userData['resultSet_0']?.isNotEmpty == true
      ? _loginResponse!.userData['resultSet_0'][0]['UserID']
      : null;

  String? get userGroupName => _loginResponse?.userData['resultSet_0']?.isNotEmpty == true
      ? _loginResponse!.userData['resultSet_0'][0]['UserGroupName']
      : null;

  // Initialize with login response
  void initializeUser(LoginResponse loginResponse) {
    _loginResponse = loginResponse;
    _isLoggedIn = true;

    // Extract menu permissions from the response
    if (loginResponse.userData['resultSet_0'] != null) {
      _menuPermissions = (loginResponse.userData['resultSet_0'] as List)
          .map((item) => MenuPermission.fromJson(item))
          .toList();
    }

    notifyListeners();
  }

  // Logout user
  void logout() {
    _loginResponse = null;
    _menuPermissions = [];
    _isLoggedIn = false;
    notifyListeners();
  }

  // Check if user has access to a specific menu by menu code
  bool hasMenuAccess(String menuCode) {
    if (!_isLoggedIn) return false;

    final menuPermission = _menuPermissions.firstWhere(
          (permission) => permission.menuCode == menuCode,
      orElse: () => MenuPermission(menuCode: menuCode, showMenu: "0"),
    );

    return menuPermission.showMenu == "1";
  }

  // Check if user has specific permission for a menu
  bool hasPermission(String menuCode, String permissionType) {
    if (!_isLoggedIn) return false;

    final menuPermission = _menuPermissions.firstWhere(
          (permission) => permission.menuCode == menuCode,
      orElse: () => MenuPermission(menuCode: menuCode),
    );

    switch (permissionType.toLowerCase()) {
      case 'add':
        return menuPermission.canAdd == "1";
      case 'edit':
        return menuPermission.canEdit == "1";
      case 'delete':
        return menuPermission.canDelete == "1";
      case 'print':
        return menuPermission.canPrint == "1";
      case 'export':
        return menuPermission.canExport == "1";
      case 'next':
        return menuPermission.canNext == "1";
      case 'alloption':
        return menuPermission.allOption == "1";
      default:
        return false;
    }
  }

  // Get all visible menus for the user
  List<MenuPermission> getVisibleMenus() {
    if (!_isLoggedIn) return [];
    return _menuPermissions.where((permission) => permission.showMenu == "1").toList();
  }
}

// Model class for menu permissions
class MenuPermission {
  final String userCode;
  final String userName;
  final String userGroupCode;
  final String userID;
  final String isBlocked;
  final String addUser;
  final String addDate;
  final String editUser;
  final String editDate;
  final String userGroupName;
  final String menuCode;
  final String menuText;
  final String showMenu;
  final String allOption;
  final String canAdd;
  final String canEdit;
  final String canDelete;
  final String canPrint;
  final String canNext;
  final String canExport;
  final String sNo;

  MenuPermission({
    required this.menuCode,
    this.userCode = '',
    this.userName = '',
    this.userGroupCode = '',
    this.userID = '',
    this.isBlocked = '0',
    this.addUser = '',
    this.addDate = '',
    this.editUser = '',
    this.editDate = '',
    this.userGroupName = '',
    this.menuText = '',
    this.showMenu = '0',
    this.allOption = '0',
    this.canAdd = '0',
    this.canEdit = '0',
    this.canDelete = '0',
    this.canPrint = '0',
    this.canNext = '0',
    this.canExport = '0',
    this.sNo = '',
  });

  factory MenuPermission.fromJson(Map<String, dynamic> json) {
    return MenuPermission(
      userCode: json['UserCode'] ?? '',
      userName: json['UserName'] ?? '',
      userGroupCode: json['UserGroupCode'] ?? '',
      userID: json['UserID'] ?? '',
      isBlocked: json['IsBlocked'] ?? '0',
      addUser: json['AddUser'] ?? '',
      addDate: json['AddDate'] ?? '',
      editUser: json['EditUser'] ?? '',
      editDate: json['EditDate'] ?? '',
      userGroupName: json['UserGroupName'] ?? '',
      menuCode: json['MenuCode'] ?? '',
      menuText: json['MenuText'] ?? '',
      showMenu: json['ShowMenu'] ?? '0',
      allOption: json['AllOption'] ?? '0',
      canAdd: json['CanAdd'] ?? '0',
      canEdit: json['CanEdit'] ?? '0',
      canDelete: json['CanDelete'] ?? '0',
      canPrint: json['CanPrint'] ?? '0',
      canNext: json['CanNext'] ?? '0',
      canExport: json['CanExport'] ?? '0',
      sNo: json['SNo'] ?? '',
    );
  }
}