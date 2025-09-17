import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../core/widgets/bottom_navigation.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Roamio',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: appRouter,
    );
  }
}

// class ScaffoldWithNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Widget child;

//   const ScaffoldWithNavBar({
//     Key? key,
//     required this.currentIndex,
//     required this.child,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: child,
//       bottomNavigationBar: CustomBottomNavigationBar(
//         currentIndex: currentIndex,
//       ),
//     );
//   }
// }