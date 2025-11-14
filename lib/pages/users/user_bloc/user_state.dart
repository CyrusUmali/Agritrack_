part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UsersLoading extends UserState {}

class UsersLoaded extends UserState {
  final List<UserModel> users;
  final String? message;

  const UsersLoaded(this.users, {this.message});

  @override
  List<Object> get props => [users, if (message != null) message!];
}

class UserLoaded extends UserState {
  final UserModel user;

  const UserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class UsersError extends UserState {
  final String message;

  const UsersError(this.message);

  @override
  List<Object> get props => [message];
}

class UserUpdated extends UserState {
  final UserModel user;
  final bool passwordChanged;

  // const UserUpdated(this.user, {this.message = "User updated successfully"} ,{required this.passwordChanged});
  const UserUpdated(this.user, {required this.passwordChanged});

  @override
  List<Object> get props => [user, passwordChanged];
}
