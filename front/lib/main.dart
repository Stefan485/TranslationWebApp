import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './screen/chat-screen.dart';

void main(){
    runApp(const ProviderScope(child: TranslateChatApp()));
}

class TranslateChatApp extends StatelessWidget{
    const TranslateChatApp({super.key});

    @override
    Widget build(BuildContext context){
        return MaterialApp(
            title: 'Obradovic',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF76B900),
                    brightness: Brightness.light,
                ).copyWith(
                    primary: const Color(0xFF76B900),
                    onPrimary: const Color(0xFF0D1A00),
                ),
                useMaterial3: true,
                ),
                darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF76B900),
                    brightness: Brightness.dark,
                ).copyWith(
                    primary: const Color(0xFF76B900),
                    onPrimary: const Color(0xFF0D1A00),
                ),
                useMaterial3: true,
            ),
            home: const ChatScreen(),
        );
    }
}