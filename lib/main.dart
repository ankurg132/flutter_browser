import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magtapp/bloc/ai/ai_bloc.dart';
import 'package:magtapp/bloc/browser_bloc.dart';
import 'package:magtapp/screens/browser/browser_screen.dart';
import 'package:magtapp/services/ai_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => BrowserBloc()),
        BlocProvider(create: (context) => AIBloc(aiService: AIService())),
      ],
      child: MaterialApp(
        title: 'Magtapp Browser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const BrowserScreen(),
      ),
    );
  }
}
