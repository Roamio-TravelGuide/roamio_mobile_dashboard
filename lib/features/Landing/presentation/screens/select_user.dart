import 'package:flutter/material.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SelectUserScreen extends StatefulWidget {
  const SelectUserScreen({super.key});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0D0D12),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Status bar area
                const SizedBox(height: 20),
                
                const SizedBox(height: 60),
                
                // Title
                Text(
                  'Choose Your Role',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Select how you want to use Roamio',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // User type selection cards
                Expanded(
                  child: Column(
                    children: [
                      // Traveler card
                      _buildUserTypeCard(
                        context,
                        userType: 'traveler',
                        icon: Icons.location_on_outlined,
                        title: 'Traveler',
                        description: 'I want to explore new places and discover amazing destinations',
                        isSelected: selectedUserType == 'traveler',
                        onTap: () {
                          setState(() {
                            selectedUserType = 'traveler';
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Tour Guide card
                      _buildUserTypeCard(
                        context,
                        userType: 'guide',
                        icon: Icons.search_outlined,
                        title: 'Tour Guide',
                        description: 'I want to share my knowledge and guide other travelers',
                        isSelected: selectedUserType == 'guide',
                        onTap: () {
                          setState(() {
                            selectedUserType = 'guide';
                          });
                        },
                      ),
                      
                      const Spacer(),
                      
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedUserType != null ? () {
                            // Navigate to main app or next onboarding step
                            Navigator.pushReplacementNamed(context, '/home');
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedUserType != null 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.3),
                            foregroundColor: const Color(0xFF0D0D12),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: selectedUserType != null 
                                  ? const Color(0xFF0D0D12)
                                  : const Color(0xFF0D0D12).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                
                // Bottom indicator
                Container(
                  width: 134,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
    BuildContext context, {
    required String userType,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Color(0xFF0D0D12),
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}