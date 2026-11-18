import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade_ledger/data/app_database.dart';
import 'package:kade_ledger/features/customers/data/drift_customer_repository.dart';
import 'package:kade_ledger/features/customers/domain/add_customer.dart';

void main() {
  late AppDatabase db;
  late DriftCustomerRepository repository;
  late AddCustomer addCustomer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftCustomerRepository(db);
    addCustomer = AddCustomer(repository);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftCustomerRepository & AddCustomer', () {
    test('adds a customer with UUID and UTC timestamps', () async {
      final result = await addCustomer(
        name: '  Kamal Perera  ',
        phone: '077 123 4567',
        note: 'Regular buyer',
      );

      expect(result, isA<AddCustomerSuccess>());
      final customer = (result as AddCustomerSuccess).customer;

      expect(customer.id, isNotEmpty);
      expect(customer.name, 'Kamal Perera');
      expect(customer.phone, '077 123 4567');
      expect(customer.note, 'Regular buyer');
      expect(customer.createdAt.isUtc, isTrue);
      expect(customer.updatedAt.isUtc, isTrue);

      final fetched = await repository.getCustomer(customer.id);
      expect(fetched, equals(customer));
    });

    test('updates a customer and advances updatedAt', () async {
      final created = await repository.addCustomer(
        name: 'Nimali Silva',
        phone: '0711112222',
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final updated = await repository.updateCustomer(
        id: created.id,
        name: 'Nimali Fernando',
        phone: '0719998888',
        note: 'Moved nearby',
      );

      expect(updated.id, created.id);
      expect(updated.name, 'Nimali Fernando');
      expect(updated.phone, '0719998888');
      expect(updated.note, 'Moved nearby');
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    });

    test(
      'soft deletes a customer so it disappears from watchCustomers and getCustomer',
      () async {
        final created = await repository.addCustomer(name: 'Sunil Bandara');

        final beforeDelete = await repository.watchCustomers().first;
        expect(beforeDelete.map((c) => c.id), contains(created.id));

        await repository.softDeleteCustomer(created.id);

        final afterDelete = await repository.watchCustomers().first;
        expect(afterDelete, isEmpty);
        expect(await repository.getCustomer(created.id), isNull);
      },
    );

    test(
      'searches case-insensitively by name or phone, and empty search returns all active',
      () async {
        await repository.addCustomer(name: 'Kamal Perera', phone: '0771234567');
        await repository.addCustomer(name: 'Nimali Silva', phone: '0719876543');
        final deleted = await repository.addCustomer(
          name: 'Kamal Deleted',
          phone: '0770000000',
        );
        await repository.softDeleteCustomer(deleted.id);

        final byName = await repository.watchCustomers(search: 'kamal').first;
        expect(byName.length, 1);
        expect(byName.first.name, 'Kamal Perera');

        final byPhone = await repository.watchCustomers(search: '9876').first;
        expect(byPhone.length, 1);
        expect(byPhone.first.name, 'Nimali Silva');

        final allActive = await repository.watchCustomers(search: '   ').first;
        expect(allActive.length, 2);
      },
    );

    test(
      'AddCustomer rejects empty name, whitespace-only name, and invalid phone',
      () async {
        final emptyResult = await addCustomer(name: '');
        expect(
          emptyResult,
          isA<AddCustomerFailure>().having(
            (f) => f.error,
            'error',
            CustomerValidationError.emptyName,
          ),
        );

        final whitespaceResult = await addCustomer(name: '    ');
        expect(
          whitespaceResult,
          isA<AddCustomerFailure>().having(
            (f) => f.error,
            'error',
            CustomerValidationError.emptyName,
          ),
        );

        final badPhoneResult = await addCustomer(
          name: 'Saman',
          phone: 'not-a-phone',
        );
        expect(
          badPhoneResult,
          isA<AddCustomerFailure>().having(
            (f) => f.error,
            'error',
            CustomerValidationError.invalidPhone,
          ),
        );

        final allCustomers = await repository.watchCustomers().first;
        expect(allCustomers, isEmpty);
      },
    );
  });
}
