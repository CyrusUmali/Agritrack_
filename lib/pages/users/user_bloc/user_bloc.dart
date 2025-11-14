import 'dart:async';
import 'package:flareline/repositories/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/user_model.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({required this.userRepository}) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<DeleteUser>(_onDeleteUser);
    on<FilterUsers>(_onFilterUsers);
    on<SearchUsers>(_onSearchUsers);
    on<SortUsers>(_onSortUsers);
    on<GetUserById>(_onGetUserById);
    on<UpdateUser>(_onUpdateUser);
  }

  List<UserModel> _users = [];
  String _searchQuery = '';
  String? _roleFilter;
  String? _statusFilter;
  String? _sortColumn;
  bool _sortAscending = true;

  List<UserModel> get allUsers => _users;
  String? get roleFilter => _roleFilter;
  String? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());

    try {
      final updatedUser = await userRepository.updateUser(event.user);
      final index = _users.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      emit(UserUpdated(updatedUser, passwordChanged: event.passwordChanged));
      emit(UserLoaded(updatedUser));
    } catch (e) {
      // print('Error updating user: ${e.toString()}');
      emit(UsersError(e.toString()));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      emit(UsersLoading());

      // Call the repository's changePassword method
      await userRepository.changePassword(currentPassword, newPassword);

      // Password changed successfully - no need to emit UserUpdated
      // since we'll navigate to login immediately
    } catch (e) {
      emit(UsersError(e.toString()));
      rethrow; // Re-throw to handle in the UI
    }
  }

  Future<void> _onGetUserById(
    GetUserById event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());

    try {
      final user = await userRepository.getUserById(event.id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());

    try {
      _users = await userRepository.fetchUsers();
      emit(UsersLoaded(_applyFilters()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onAddUser(
    AddUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final newUser = UserModel(
        id: 0, // Let server assign ID
        email: event.email,
        name: event.name,
        role: event.role,
        password: event.password,
        sector: event.sector,
        fname: event.fname,
        lname: event.lname,
        barangay: event.barangay,
        photoUrl: event.photoUrl,
        idToken: event.idToken,
        farmerId: event.farmerId,
      );

      await userRepository.addUser(newUser);
      _users = await userRepository.fetchUsers();
      emit(UsersLoaded([..._applyFilters()],
          message: 'User added successfully!'));
    } catch (e) {
      emit(UsersError('Failed to add user: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());
    try {
      await userRepository.deleteUser(event.id);
      _users = _users.where((user) => user.id != event.id).toList();
      emit(UsersLoaded(_applyFilters(), message: 'User deleted successfully!'));
    } catch (e) {
      emit(UsersError('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<void> _onFilterUsers(
    FilterUsers event,
    Emitter<UserState> emit,
  ) async {
    // Update filters based on the event
    _roleFilter = event.role;
    _statusFilter = event.status;
    _searchQuery = event.query?.trim().toLowerCase() ?? '';

    emit(UsersLoaded(_applyFilters()));
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserState> emit,
  ) async {
    _searchQuery = event.query.trim().toLowerCase();
    emit(UsersLoaded(_applyFilters()));
  }

  Future<void> _onSortUsers(
    SortUsers event,
    Emitter<UserState> emit,
  ) async {
    if (_sortColumn == event.columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = event.columnName;
      _sortAscending = true;
    }

    final filteredUsers = _applyFilters();
    for (var i = 0;
        i < (filteredUsers.length > 3 ? 3 : filteredUsers.length);
        i++) {}

    emit(UsersLoaded(filteredUsers));
  }

  List<UserModel> _applyFilters() {
    List<UserModel> filteredUsers = _users.where((user) {
      // Role filter - skip if filter is null, 'All', or empty
      if (_roleFilter != null &&
          _roleFilter!.isNotEmpty &&
          _roleFilter != 'All' &&
          user.role?.toLowerCase() != _roleFilter!.toLowerCase()) {
        return false;
      }

      // Status filter - skip if filter is null, 'All', or empty
      if (_statusFilter != null &&
          _statusFilter!.isNotEmpty &&
          _statusFilter != 'All' &&
          user.status?.toLowerCase() != _statusFilter!.toLowerCase()) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = user.name.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery) ||
            (user.role?.toLowerCase().contains(_searchQuery) ?? false) ||
            (user.fname?.toLowerCase().contains(_searchQuery) ?? false) ||
            (user.lname?.toLowerCase().contains(_searchQuery) ?? false) ||
            (user.status?.toLowerCase().contains(_searchQuery) ?? false);

        if (!matchesSearch) return false;
      }

      return true;
    }).toList();

    // Sorting
    if (_sortColumn != null) {
      filteredUsers.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Name':
            compareResult = a.name.compareTo(b.name);
            break;
          case 'Email':
            compareResult = a.email.compareTo(b.email);
            break;
          case 'Role':
            compareResult = (a.role ?? '').compareTo(b.role ?? '');
            break;
          case 'Status':
            compareResult = (a.status ?? '').compareTo(b.status ?? '');
            break;
          default:
            compareResult = 0;
        }
        return _sortAscending ? compareResult : -compareResult;
      });
    }

    return filteredUsers;
  }
}
