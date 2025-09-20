import 'package:flutter/material.dart';
import '../auth/signup_screen.dart';

class OnboardingContent {
  final IconData icon;
  final String title;
  final String description;

  OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      icon: Icons.upload_file,
      title: 'Share your recipes',
      description: 'Upload and share your favorite recipes with the community',
    ),
    OnboardingContent(
      icon: Icons.search,
      title: 'Discover new dishes',
      description: 'Explore thousands of recipes from around the world',
    ),
    OnboardingContent(
      icon: Icons.favorite,
      title: 'Save favorites for later',
      description: 'Keep your favorite recipes organized and easily accessible',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSignUp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5A5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_contents[index].icon, size: 48),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _contents[index].title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _contents[index].description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () => _goToSignUp(context),
                    child: const Text('Skip'),
                  ),
                  // Dot indicators
                  Row(
                    children: List.generate(
                      _contents.length,
                      (index) => Container(
                        margin: const EdgeInsets.all(4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _contents.length - 1) {
                        _goToSignUp(context);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                    ),
                    child: Text(
                      _currentPage == _contents.length - 1 ? 'Sign Up' : 'Next',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
