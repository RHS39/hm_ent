import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  const AddressEntity({required this.id, required this.label, required this.address, required this.pincode, this.isDefault = false});
  final String id;
  final String label;
  final String address;
  final String pincode;
  final bool isDefault;
  AddressEntity copyWith({String? label, String? address, String? pincode, bool? isDefault}) => AddressEntity(id: id, label: label ?? this.label, address: address ?? this.address, pincode: pincode ?? this.pincode, isDefault: isDefault ?? this.isDefault);
  @override
  List<Object?> get props => [id, label, address, pincode, isDefault];
}

class PaymentMethodEntity extends Equatable {
  const PaymentMethodEntity({required this.id, required this.type, required this.label, this.last4, this.isDefault = false});
  final String id;
  final String type; // card, upi, cod
  final String label;
  final String? last4;
  final bool isDefault;
  @override
  List<Object?> get props => [id, type, label];
}
