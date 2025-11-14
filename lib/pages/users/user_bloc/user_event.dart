part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {}

class AddUser extends UserEvent {
  final String email;
  final String name;
  final String role;
  final String? fname;
  final String? lname;
  final String? sector;
  final String? barangay;
  final String? phone;
  final String? photoUrl;
  final String? password;
  final int? farmerId;
  final String? idToken;

  const AddUser(
      {required this.email,
      required this.name,
      required this.role,
      this.phone,
      this.fname,
      this.lname,
      this.sector,
      this.barangay,
      this.photoUrl,
      this.idToken,
      this.farmerId,
      this.password});

  @override
  List<Object?> get props => [
        email,
        name,
        role,
        fname,
        lname,
        sector,
        barangay,
        photoUrl,
        password,
        idToken,
        phone,
        farmerId
      ];
}

class DeleteUser extends UserEvent {
  final int id;

  const DeleteUser(this.id);

  @override
  List<Object> get props => [id];
}

class FilterUsers extends UserEvent {
  final String? role;
  final String? status;
  final String? query;
  final int? sectorId;

  const FilterUsers({this.role, this.sectorId, this.query, this.status});

  @override
  List<Object?> get props => [role, status, query, sectorId];
}

class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object> get props => [query];
}

class GetUserById extends UserEvent {
  final int id;

  const GetUserById(this.id);

  @override
  List<Object> get props => [id];
}

class SortUsers extends UserEvent {
  final String columnName;

  const SortUsers(this.columnName);

  @override
  List<Object> get props => [columnName];
}

class UpdateUser extends UserEvent {
  final UserModel user;
  final bool passwordChanged;

  const UpdateUser(this.user, {this.passwordChanged = false});

  @override
  List<Object?> get props => [user, passwordChanged];
}
