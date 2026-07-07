import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impri_lab/state/app_state.dart';
import 'package:impri_lab/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inicializar FFI para SQLite en modo test
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseService.instance.database;
    await db.execute('DELETE FROM profiles');
  });

  group('Pruebas unitarias de Perfil de Usuario', () {
    test('Registro exitoso e inicio de sesión correcto', () async {
      final state = AppState();
      
      final regSuccess = await state.registerUser(
        'maker1',
        'password123',
        'Juan Maker',
        'juan@maker.com',
      );
      
      expect(regSuccess, isTrue);

      // Intento de registro con el mismo usuario debe fallar
      final regFail = await state.registerUser(
        'maker1',
        'otherpassword',
        'Juan Duplicate',
        'juan2@maker.com',
      );
      expect(regFail, isFalse);

      // Login con datos erróneos
      final loginFail = await state.loginUser('maker1', 'wrong_pass');
      expect(loginFail, isFalse);
      expect(state.currentUser, isNull);

      // Login exitoso
      final loginSuccess = await state.loginUser('maker1', 'password123');
      expect(loginSuccess, isTrue);
      expect(state.currentUser, isNotNull);
      expect(state.currentUser!.name, equals('Juan Maker'));
      expect(state.currentUser!.email, equals('juan@maker.com'));
    });

    test('Actualización de perfil y guardado de cambios', () async {
      final state = AppState();
      
      await state.registerUser(
        'test_update',
        'pass123',
        'Original Name',
        'orig@mail.com',
      );
      
      await state.loginUser('test_update', 'pass123');
      expect(state.currentUser, isNotNull);
      
      final updated = state.currentUser!.copyWith(
        name: 'New Name',
        email: 'new@mail.com',
        phone: '123456789',
        workshopName: 'Super Maker Lab',
        bio: 'Imprimiendo el futuro.',
        website: 'http://supermaker.com',
        makerLevel: 'Profesional',
      );

      await state.updateUserProfile(updated);

      expect(state.currentUser!.name, equals('New Name'));
      expect(state.currentUser!.email, equals('new@mail.com'));
      expect(state.currentUser!.phone, equals('123456789'));
      expect(state.currentUser!.workshopName, equals('Super Maker Lab'));
      expect(state.currentUser!.bio, equals('Imprimiendo el futuro.'));
      expect(state.currentUser!.website, equals('http://supermaker.com'));
      expect(state.currentUser!.makerLevel, equals('Profesional'));
    });

    test('Cierre de sesión limpia estado y SharedPreferences', () async {
      final state = AppState();
      
      await state.registerUser(
        'logout_test',
        'pass',
        'Logout Test',
        'logout@test.com',
      );
      
      await state.loginUser('logout_test', 'pass');
      expect(state.currentUser, isNotNull);

      await state.logoutUser();
      expect(state.currentUser, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('logged_in_user_id'), isFalse);
    });
  });
}
