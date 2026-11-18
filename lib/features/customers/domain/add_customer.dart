import 'package:kade_ledger/features/customers/domain/customer.dart';
import 'package:kade_ledger/features/customers/domain/customer_repository.dart';

enum CustomerValidationError { emptyName, invalidPhone }

sealed class AddCustomerResult {
  const AddCustomerResult();
}

final class AddCustomerSuccess extends AddCustomerResult {
  const AddCustomerSuccess(this.customer);

  final Customer customer;
}

final class AddCustomerFailure extends AddCustomerResult {
  const AddCustomerFailure(this.error);

  final CustomerValidationError error;
}

class AddCustomer {
  const AddCustomer(this._repository);

  final CustomerRepository _repository;

  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

  static CustomerValidationError? validate({
    required String name,
    String? phone,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return CustomerValidationError.emptyName;
    }

    final trimmedPhone = phone?.trim();
    if (trimmedPhone != null &&
        trimmedPhone.isNotEmpty &&
        !_phonePattern.hasMatch(trimmedPhone)) {
      return CustomerValidationError.invalidPhone;
    }

    return null;
  }

  Future<AddCustomerResult> call({
    required String name,
    String? phone,
    String? note,
  }) async {
    final validationError = validate(name: name, phone: phone);
    if (validationError != null) {
      return AddCustomerFailure(validationError);
    }

    final trimmedName = name.trim();
    final trimmedPhone = phone?.trim();
    final trimmedNote = note?.trim();

    final customer = await _repository.addCustomer(
      name: trimmedName,
      phone: (trimmedPhone == null || trimmedPhone.isEmpty)
          ? null
          : trimmedPhone,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );

    return AddCustomerSuccess(customer);
  }
}
