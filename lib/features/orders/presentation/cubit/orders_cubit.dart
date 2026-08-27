import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

enum OrdersFilter { active, completed, cancelled }

class OrdersState extends Equatable {
  const OrdersState({this.orders = const [], this.filter = OrdersFilter.active, this.status = OrderLoadStatus.initial});
  final List<OrderEntity> orders;
  final OrdersFilter filter;
  final OrderLoadStatus status;
  List<OrderEntity> get filtered {
    switch (filter) {
      case OrdersFilter.active:
        return orders.where((o) => o.status == OrderStatus.ordered || o.status == OrderStatus.shipped || o.status == OrderStatus.outForDelivery).toList();
      case OrdersFilter.completed:
        return orders.where((o) => o.status == OrderStatus.delivered).toList();
      case OrdersFilter.cancelled:
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
    }
  }
  OrdersState copyWith({List<OrderEntity>? orders, OrdersFilter? filter, OrderLoadStatus? status}) => OrdersState(orders: orders ?? this.orders, filter: filter ?? this.filter, status: status ?? this.status);
  @override
  List<Object?> get props => [orders, filter, status];
}

enum OrderLoadStatus { initial, loading, success, failure }

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit() : super(const OrdersState()) { _loadMock(); }

  void setFilter(OrdersFilter f) => emit(state.copyWith(filter: f));

  void _loadMock() {
    emit(state.copyWith(status: OrderLoadStatus.loading));
    final now = DateTime.now();
    final mock = [
      OrderEntity(id: 'ORD78291', date: now.subtract(const Duration(days: 1)), status: OrderStatus.shipped, items: const [OrderItem(name: 'Organic Jaggery Cubes 1kg', price: 229, qty: 2), OrderItem(name: 'Chocolaty Gud 700g', price: 299, qty: 1)], total: 757),
      OrderEntity(id: 'ORD78288', date: now.subtract(const Duration(days: 3)), status: OrderStatus.delivered, items: const [OrderItem(name: 'Organic Jaggery Peanut Chikki 200g', price: 179, qty: 3)], total: 537),
      OrderEntity(id: 'ORD78277', date: now.subtract(const Duration(days: 7)), status: OrderStatus.outForDelivery, items: const [OrderItem(name: 'Organic Liquid Jaggery Kakvi 500ml', price: 349, qty: 1)], total: 349),
      OrderEntity(id: 'ORD78260', date: now.subtract(const Duration(days: 12)), status: OrderStatus.cancelled, items: const [OrderItem(name: 'Gift Hamper 1.5kg', price: 899, qty: 1)], total: 899),
    ];
    emit(state.copyWith(orders: mock, status: OrderLoadStatus.success));
  }
}
