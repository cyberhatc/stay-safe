import 'package:sqflite/sqflite.dart';
import 'package:stay_safe/core/services/database_helper.dart';
import 'package:stay_safe/core/constants/app_constants.dart';
import 'package:stay_safe/features/friends/models/contact_model.dart';

class ContactRepository {
  Future<List<Contact>> getAllContacts() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(AppConstants.contactsTable, orderBy: 'createdAt DESC');
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<List<Contact>> getEmergencyContacts() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      AppConstants.contactsTable,
      where: 'isEmergency = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<Contact?> getContactById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      AppConstants.contactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<int> insertContact(Contact contact) async {
    final db = await DatabaseHelper.database;
    return await db.insert(AppConstants.contactsTable, contact.toMap());
  }

  Future<int> updateContact(Contact contact) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      AppConstants.contactsTable,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      AppConstants.contactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getContactCount() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.contactsTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> hasEmergencyContacts() async {
    final count = await getContactCount();
    return count > 0;
  }
}
