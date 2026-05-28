import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'src/auth/presentation/splash_screen.dart';
import 'src/cart/presentation/cubit/cart_cubit.dart'; // Importación del Cubit

class WacamayaSportsApp extends StatelessWidget {
  const WacamayaSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit(), // Inicialización global del Carrito
      child: MaterialApp(
        title: 'Wacamaya Sports',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
