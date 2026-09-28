import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/features/friends/models/contact_model.dart';
import 'package:stay_safe/features/friends/repositories/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

final contactsProvider = NotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>(
  ContactsNotifier.new,
);

class ContactsNotifier extends Notifier<AsyncValue<List<Contact>>> {
  @override
  AsyncValue<List<Contact>> build() {
    loadContacts();
    return const AsyncValue.loading();
  }

  ContactRepository get _repo => ref.read(contactRepositoryProvider);

  Future<void> loadContacts() async {
    state = const AsyncValue.loading();
    try {
      final contacts = await _repo.getAllContacts();
      state = AsyncValue.data(contacts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addContact(Contact contact) async {
    try {
      await _repo.insertContact(contact);
      await loadContacts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateContact(Contact contact) async {
    try {
      await _repo.updateContact(contact);
      await loadContacts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      await _repo.deleteContact(id);
      await loadContacts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Contact>> getEmergencyContacts() async {
    return await _repo.getEmergencyContacts();
  }
}
