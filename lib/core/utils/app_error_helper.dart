import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_cristiana/core/utils/network_status_helper.dart';

class AppErrorHelper {
  static Future<String> friendlyMessage(
    Object error, {
    String fallback = 'Ocurrió un problema inesperado. Inténtalo nuevamente.',
  }) async {
    if (error is AuthException) {
      return authMessage(error.message);
    }

    if (error is SocketException || error is HttpException) {
      return 'Parece que no tienes internet en este momento. Verifica tu conexión y vuelve a intentarlo.';
    }

    final offline = !(await NetworkStatusHelper.hasConnection());
    if (offline) {
      return 'Parece que no tienes internet en este momento. Verifica tu conexión y vuelve a intentarlo.';
    }

    final text = error.toString().toLowerCase();

    if (text.contains('clientexception') ||
        text.contains('socketexception') ||
        text.contains('connection reset') ||
        text.contains('connection aborted') ||
        text.contains('connection closed') ||
        text.contains('software caused connection abort') ||
        text.contains('failed host lookup') ||
        text.contains('errno = 101') ||
        text.contains('errno = 104') ||
        text.contains('timeout')) {
      return 'Parece que no tienes internet en este momento. Verifica tu conexión y vuelve a intentarlo.';
    }

    if (text.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (text.contains('email not confirmed')) {
      return 'Tu correo todavía no ha sido confirmado. Revisa tu bandeja de entrada y confirma tu cuenta.';
    }

    if (text.contains('user already registered') ||
        text.contains('already registered')) {
      return 'Ese correo ya está registrado. Intenta iniciar sesión.';
    }

    if (text.contains('invalid email')) {
      return 'El correo electrónico no es válido.';
    }

    if (text.contains('password should be at least') ||
        text.contains('weak password')) {
      return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
    }

    if (text.contains('jwt') || text.contains('token')) {
      return 'Tu sesión ya no es válida. Inicia sesión nuevamente.';
    }

    if (kDebugMode) {
      debugPrint('AppErrorHelper fallback for error: $error');
    }

    return fallback;
  }

  static String authMessage(String message) {
    final text = message.toLowerCase();

    if (text.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (text.contains('email not confirmed')) {
      return 'Tu correo todavía no ha sido confirmado. Revisa tu bandeja de entrada y confirma tu cuenta.';
    }
    if (text.contains('user already registered') ||
        text.contains('already registered')) {
      return 'Ese correo ya está registrado. Intenta iniciar sesión.';
    }
    if (text.contains('invalid email')) {
      return 'El correo electrónico no es válido.';
    }
    if (text.contains('signup is disabled')) {
      return 'El registro de nuevas cuentas está desactivado en este momento.';
    }
    if (text.contains('email rate limit exceeded')) {
      return 'Has intentado demasiadas veces en poco tiempo. Espera un momento y vuelve a intentarlo.';
    }
    if (text.contains('same password')) {
      return 'La nueva contraseña no puede ser igual a la anterior.';
    }

    return message;
  }
}
