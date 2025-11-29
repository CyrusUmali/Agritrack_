import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final String nextRoute;

  const SplashScreen({super.key, required this.nextRoute});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Wait for 2 seconds then navigate
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(widget.nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/DA_image.jpg',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
           
          ],
        ),
      ),
    );
  }
}