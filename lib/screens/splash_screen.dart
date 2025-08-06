import 'package:flutter/material.dart';
import 'package:rental_house_taxation_flutter/screens/singin.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Spacer top
              const SizedBox(height: 20),

              // Image container
              Image.asset(
                'images/welcome.jpg', // Make sure you add this image to assets
                height: 310,
                fit: BoxFit.contain,
              ),

              // Title text
              const Text(
                'Welcome to Rental\nHouse Taxation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF14183E), // Dark Blue-ish color
                ),
              ),

              // Spacer middle
              const SizedBox(height: 16),

              // Footer with ministry info and button
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Minister of Finance, Somalia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF808080), // Gray color
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121440), // Dark navy
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),

                  ),
                ],
              ),

              // Spacer bottom
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
