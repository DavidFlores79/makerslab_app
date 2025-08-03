import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';

class ChatPage extends StatelessWidget {
  static const String routeName = '/chat';
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: const Center(child: Text('Página de Chat')),
    );
  }
}
