import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../viewmodels/onboarding/onboarding_viewmodel.dart';

class IntroScheduleScreen extends StatelessWidget {
  IntroScheduleScreen({super.key});

  final List<Widget> pages = [
    OnboardingPage(
      title: 'Schedule your charging',
      subtitle: 'Check, Reserve and charge your EV',
      imagePath: AppMedia.scheduleCharging1,
    ),
    OnboardingPage(
      title: 'Pay for your charging',
      subtitle: 'Pay with any method you prefer',
      imagePath: AppMedia.scheduleCharging2,
    ),
    OnboardingPage(
      title: 'Earn for your charging',
      subtitle: 'Earn points for every sustainable action',
      imagePath: AppMedia.scheduleCharging3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewmodel>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: vm.pageController,
                onPageChanged: vm.setCurrentIndex,
                children: pages,
              ),
            ),
            // Page Indicator and Button
            Padding(
              padding: const EdgeInsets.only(bottom: 24.6),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: vm.currentIndex == index ? 20 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: vm.currentIndex == index
                              ? Colors.black
                              : Colors.black38,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 130),
                  // Button
                  ElevatedButton(
                    onPressed: () => vm.nextPage(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      vm.currentIndex == pages.length - 1
                          ? 'START NOW'
                          : 'NEXT',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
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

// Onboarding Page Widget
class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // unititled Title Positioned to Left
          const Align(
            alignment: Alignment.topLeft,
            child: Text(
              'EZCHARGE',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 50),

          // Align Text Content to the Left
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Image Centered
          Center(
            child: Image.asset(
              imagePath,
              width: 320,
              height: 250,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
