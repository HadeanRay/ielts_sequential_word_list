import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/word_list_provider.dart';
import 'screens/word_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordListProvider(),
      child: MaterialApp(
        title: 'IELTS 顺序词表',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const WordListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
