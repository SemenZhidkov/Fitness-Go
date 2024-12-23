

import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const BackgroundScaffold({Key? key, this.appBar, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.png'), // Укажите ваш путь к фоновому изображению
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
    );
  }
}

