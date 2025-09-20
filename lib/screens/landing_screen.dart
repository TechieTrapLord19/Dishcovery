import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/dishcovery.jpg', height: 120),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Dishcovery!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
