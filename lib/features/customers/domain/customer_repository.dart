import 'package:kade_ledger/features/customers/domain/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> watchCustomers({String? search});

  Future<Customer?> getCustomer(String id);

  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? note,
  });

  Future<Customer> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? note,
  });

  Future<void> softDeleteCustomer(String id);
}
