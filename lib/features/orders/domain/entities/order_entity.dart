import 'package:equatable/equatable.dart';

enum OrderStatus { ordered, shipped, outForDelivery, delivered, cancelled }

class OrderItem extends Equatable {
  const OrderItem({required this.name, required this.price, required this.qty, this.image});
  final String name;
  final double price;
  final int qty;
  final String? image;
  @override
  List<Object?> get props => [name, price, qty];
}

class OrderEntity extends Equatable {
  const OrderEntity({required this.id, required this.date, required this.status, required this.items, required this.total});
  final String id;
  final DateTime date;
  final OrderStatus status;
  final List<OrderItem> items;
  final double total;
  @override
  List<Object?> get props => [id, date, status];
}
