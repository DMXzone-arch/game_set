import 'package:shared_preferences/shared_preferences.dart';

class GuestModeService {
  static const String _guestChoiceKey = 'gameset_continue_as_guest';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<bool> hasChosenGuestMode() async =>
      await _preferences.getBool(_guestChoiceKey) ?? false;

  Future<void> continueAsGuest() => _preferences.setBool(_guestChoiceKey, true);

  Future<void> clearGuestChoice() => _preferences.remove(_guestChoiceKey);
}
