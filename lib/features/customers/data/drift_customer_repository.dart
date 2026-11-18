import 'package:drift/drift.dart';
import 'package:kade_ledger/data/app_database.dart';
import 'package:kade_ledger/features/customers/domain/customer.dart';
import 'package:kade_ledger/features/customers/domain/customer_repository.dart';
import 'package:uuid/uuid.dart';

class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  DateTime _nowUtcSeconds() {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    return DateTime.fromMillisecondsSinceEpoch(
      (nowMs ~/ 1000) * 1000,
      isUtc: true,
    );
  }

  Customer _toEntity(CustomerRow row) {
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      note: row.note,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  @override
  Stream<List<Customer>> watchCustomers({String? search}) {
    final query = _db.select(_db.customers)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name.lower())]);

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      final pattern = '%${trimmedSearch.toLowerCase()}%';
      query.where(
        (tbl) =>
            tbl.name.lower().like(pattern) | tbl.phone.lower().like(pattern),
      );
    }

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    final query = _db.select(_db.customers)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? note,
  }) async {
    final now = _nowUtcSeconds();
    final id = _uuid.v4();

    await _db
        .into(_db.customers)
        .insert(
          CustomersCompanion.insert(
            id: id,
            name: name,
            phone: Value(phone),
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return Customer(
      id: id,
      name: name,
      phone: phone,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? note,
  }) async {
    final existing = await getCustomer(id);
    if (existing == null) {
      throw StateError('Customer not found or deleted: $id');
    }

    var now = _nowUtcSeconds();
    if (!now.isAfter(existing.updatedAt)) {
      now = existing.updatedAt.add(const Duration(seconds: 1));
    }

    await (_db.update(
      _db.customers,
    )..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull())).write(
      CustomersCompanion(
        name: Value(name),
        phone: Value(phone),
        note: Value(note),
        updatedAt: Value(now),
      ),
    );

    final updated = await getCustomer(id);
    if (updated == null) {
      throw StateError('Customer not found or deleted: $id');
    }
    return updated;
  }

  @override
  Future<void> softDeleteCustomer(String id) async {
    final existing = await getCustomer(id);
    if (existing == null) {
      return;
    }

    var now = _nowUtcSeconds();
    if (!now.isAfter(existing.updatedAt)) {
      now = existing.updatedAt.add(const Duration(seconds: 1));
    }

    await (_db.update(
      _db.customers,
    )..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull())).write(
      CustomersCompanion(updatedAt: Value(now), deletedAt: Value(now)),
    );
  }
}
