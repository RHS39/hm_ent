import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../pages/home_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});
  @override
  Widget build(BuildContext context) {
    // Reuse existing HomePage but hide its header? For now wrap HomeContent
    return Scaffold(
      appBar: AppBar(title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.w800))),
      body: const SingleChildScrollView(child: HomeContent()),
    );
  }
}
