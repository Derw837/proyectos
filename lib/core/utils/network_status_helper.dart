import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusHelper {
  static Future<bool> hasConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();

      if (result is List<ConnectivityResult>) {
        return !result.contains(ConnectivityResult.none);
      }

      if (result is ConnectivityResult) {
        return result != ConnectivityResult.none;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<String> playerMessageForError(Object error) async {
    final offline = !(await hasConnection());
    if (offline) {
      return 'Parece que no tienes internet. Verifica tu conexión y vuelve a intentarlo.';
    }

    final text = error.toString().toLowerCase();

    if (text.contains('mediacodecaudiorenderer') ||
        text.contains('audio renderer') ||
        text.contains('codec')) {
      return 'Ocurrió un problema con el reproductor. Toca "Volver a intentarlo" para reiniciarlo.';
    }

    if (text.contains('behindlivewindowexception')) {
      return 'La transmisión se desfasó. Toca "Volver a intentarlo" para reconectarla.';
    }

    if (text.contains('source error') ||
        text.contains('404') ||
        text.contains('403')) {
      return 'Este contenido no está disponible por este momento.';
    }

    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('timeout')) {
      return 'Parece que hay un problema de conexión. Revisa internet y vuelve a intentarlo.';
    }

    return 'Parece que ocurrió un error al reproducir este contenido. Toca "Volver a intentarlo".';
  }
}