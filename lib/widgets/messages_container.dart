import 'package:flutter/material.dart';

class MessagesContainer extends StatelessWidget {
  const MessagesContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: const SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              foregroundImage: AssetImage('assets/app/app-icon-circle.png'),
            ),
            SizedBox(
              height: 8,
            ),
            Text('...'),
          ],
        ),
      ),
    );
  }
}
