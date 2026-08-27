import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';

class ProfileState extends Equatable {
  const ProfileState({this.addresses = const [], this.payments = const [], this.wishlist = const [], this.isDarkMode = false, this.notifications = true});
  final List<AddressEntity> addresses;
  final List<PaymentMethodEntity> payments;
  final List<String> wishlist;
  final bool isDarkMode;
  final bool notifications;
  ProfileState copyWith({List<AddressEntity>? addresses, List<PaymentMethodEntity>? payments, List<String>? wishlist, bool? isDarkMode, bool? notifications}) => ProfileState(addresses: addresses ?? this.addresses, payments: payments ?? this.payments, wishlist: wishlist ?? this.wishlist, isDarkMode: isDarkMode ?? this.isDarkMode, notifications: notifications ?? this.notifications);
  @override
  List<Object?> get props => [addresses, payments, wishlist, isDarkMode, notifications];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState(addresses: [AddressEntity(id: '1', label: 'Home', address: '123 Assi Ghat, Varanasi', pincode: '221005', isDefault: true), AddressEntity(id: '2', label: 'Office', address: 'Sigra, Varanasi', pincode: '221010')], payments: [PaymentMethodEntity(id: '1', type: 'card', label: 'HDFC •••• 4242', last4: '4242', isDefault: true), PaymentMethodEntity(id: '2', type: 'upi', label: 'rohit@upi')], wishlist: ['1','3','7'])) {
    // mock
  }

  void addAddress(AddressEntity a) => emit(state.copyWith(addresses: [...state.addresses, a]));
  void updateAddress(AddressEntity a) => emit(state.copyWith(addresses: state.addresses.map((e) => e.id == a.id ? a : e).toList()));
  void removeAddress(String id) => emit(state.copyWith(addresses: state.addresses.where((e) => e.id != id).toList()));
  void toggleWishlist(String id) {
    final list = List<String>.from(state.wishlist);
    if (list.contains(id)) list.remove(id); else list.add(id);
    emit(state.copyWith(wishlist: list));
  }
  void moveToCart(String id) => emit(state.copyWith(wishlist: state.wishlist.where((e) => e != id).toList()));
  void toggleDark(bool v) => emit(state.copyWith(isDarkMode: v));
  void toggleNotifications(bool v) => emit(state.copyWith(notifications: v));
}
