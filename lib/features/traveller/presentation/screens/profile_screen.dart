import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/text_fields/custom_text_field.dart';
import '../../../auth/api/auth_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../traveller/api/traveller_api.dart';

class TravelerProfilePage extends StatefulWidget {
  const TravelerProfilePage({super.key});

  @override
  State<TravelerProfilePage> createState() => _TravelerProfilePageState();
}

class _TravelerProfilePageState extends State<TravelerProfilePage> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoggingOut = false;
  bool _isInitialized = false;
  String? _initializationError;

  late AuthApi authApi;
  late TravellerApi travelerApi;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _initializeApis();
  }

  Future<void> _initializeApis() async {
    try {
      print('Initializing APIs...');

      // Get the token
      final token = await AuthApi.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated - No token found');
      }

      print('Token found, creating API clients...');

      // Create API clients with token
      final apiClient = ApiClient(token: token);
      authApi = AuthApi(apiClient: apiClient);
      travelerApi = TravellerApi(apiClient: apiClient);

      // Initialize profile future
      _profileFuture = _fetchProfile();

      setState(() {
        _isInitialized = true;
        _initializationError = null;
      });

      print('APIs initialized successfully');
    } catch (error) {
      print('Error initializing APIs: $error');
      setState(() {
        _isInitialized = true;
        _initializationError = error.toString();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    try {
      print('Fetching user profile...');

      final userId = await AuthApi.getUserId();
      if (userId == null) {
        throw Exception('User ID not found in storage');
      }

      print('User ID: $userId');

      final profile = await travelerApi.getProfile(userId.toString());

      // API is expected to return: { success: true, data: {...} }
      if (profile.containsKey('data') && profile['data'] is Map) {
        final profileData = profile['data'];
        _fullNameController.text = profileData['name']?.toString() ?? '';
        _emailController.text = profileData['email']?.toString() ?? '';
        _phoneController.text = profileData['phone_no']?.toString() ?? '';
      } else {
        throw Exception('Invalid profile response: "data" field missing');
      }

      print('Profile fetched successfully');
      return profile;
    } catch (e) {
      print('Error in _fetchProfile: $e');
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D12),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _initializationError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeApis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D12),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D12),
            appBar: AppBar(
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goBack,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load profile',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _profileFuture = _fetchProfile();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _goBack,
                      child: const Text(
                        'Go Back',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildProfileScreen();
      },
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: Text(
          _fullNameController.text.isEmpty
              ? 'Traveler Profile'
              : _fullNameController.text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Profile Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _fullNameController,
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0066FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0066FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0066FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 30),
          
            
            
            // Save Changes Button
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 20),
            
            // Change Password Button
            Center(
              child: TextButton(
                onPressed: _changePassword,
                child: const Text(
                  'Change Password',
                  style: TextStyle(color: Color(0xFF0066FF)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Logout Button
            Center(
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/traveler/home');
    }
  }

  void _saveChanges() async {
    try {
      // Basic validation
      if (_fullNameController.text.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }
      if (_emailController.text.trim().isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (!_emailController.text.contains('@')) {
        throw Exception('Invalid email format');
      }
      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Phone number cannot be empty');
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Updating profile...'),
            ],
          ),
          duration: Duration(seconds: 60), // Long duration as we'll dismiss it manually
          backgroundColor: Colors.blue,
        ),
      );

      print('Starting profile update...');
      final userId = await AuthApi.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final profileData = {
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNo': _phoneController.text.trim(),
        'role': 'traveler',           // Changed to 'traveler' to match JWT token role
        'type': 'traveler',           // Match the role spelling
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),  // Changed to standard field name
      };

      print('Updating profile with data: $profileData');
      await travelerApi.updateProfile(userId.toString(), profileData);

      if (mounted) {
        // Clear the loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clear the loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Password change functionality will be implemented here.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF0066FF))),
          ),
        ],
      ),
    );
  }

  void _logout() {
    if (_isLoggingOut) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                _isLoggingOut = true;
              });
              try {
                await AuthApi.clearAuthData();
                authApi.apiClient.clearToken();
                await authApi.logout();
                if (context.mounted) {
                  context.go('/login', extra: {'isLogout': true});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Error during logout: ${error.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoggingOut = false;
                  });
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
