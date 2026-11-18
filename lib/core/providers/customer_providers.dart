import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kade_ledger/core/providers/database_provider.dart';
import 'package:kade_ledger/features/customers/data/drift_customer_repository.dart';
import 'package:kade_ledger/features/customers/domain/add_customer.dart';
import 'package:kade_ledger/features/customers/domain/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCustomerRepository(db);
});

final addCustomerProvider = Provider<AddCustomer>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return AddCustomer(repository);
});
