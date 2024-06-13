import 'package:InternHeroes/features/user_auth/presentation/pages/dashboardpage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;

  ProfileScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Screen'),

      ),
      body: Center(
        child: Text('Welcome to your profile, UID: $uid'),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  List<Map<String, String>> onboardingData = [
    {
      'title': 'Welcome to Internheroes',
      'description': 'Discover and Share Knowledge',
      'imagePath': 'assets/images/onboarding1.png',
    },
    {
      'title': 'Knowledge Resource Feature',
      'description': 'Access a wide range of IT-related topics including UI/UX, programming, and more.',
      'imagePath': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Chat Feature',
      'description': 'Connect with other interns and professionals to discuss ideas and seek advice.',
      'imagePath': 'assets/images/onboarding3.png',
    },
    {
      'title': 'Add Post Feature',
      'description': 'Share your own knowledge and experiences by creating posts for others to see.',
      'imagePath': 'assets/images/onboarding4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingItem(onboardingData[index]);
                },
              ),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                    (index) => _buildDot(index),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                if (_currentPage < onboardingData.length - 1) {
                  _pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardPage(),
                    ),
                  );
                }
              },
              child: Text(_currentPage < onboardingData.length - 1 ? 'Next' : 'Get Started'),
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingItem(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title']!,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.0),
          Text(
            data['description']!,
            style: TextStyle(fontSize: 18.0),
          ),
          SizedBox(height: 20.0),
          Expanded(
            child: Image.asset(
              data['imagePath']!,
              height: 200.0,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        width: 10.0,
        height: 10.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == index ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: OnboardingScreen()));
