import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

// NOTA: Si ya ejecutaste el comando "flutterfire configure" en tu terminal,
// puedes quitar las dos barras "//" de la línea de abajo para importar las opciones:

void main() async {
  // Asegura que los bindings de Flutter estén completamente listos antes de lanzar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicialización real de Firebase. Esto elimina la pantalla roja [core/no-app]
    await Firebase.initializeApp(
      // Si descomentaste el import de arriba, descomenta también esta línea:
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('=== Firebase inicializado con éxito ===');
  } catch (e) {
    debugPrint('=== Error crítico al inicializar Firebase: $e ===');
  }

  // Intercepción global de errores (Restricción de No Analíticas externos)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== Error Detectado Localmente ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  runApp(const WacamayaSportsApp());
}
