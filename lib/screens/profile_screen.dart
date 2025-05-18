import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../services/user_repository.dart';
import '../screens/sign_in_screen.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepo = UserRepository();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Not signed in, navigate away
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      });
    } else {
      _uid = currentUser.uid;
    }
  }

  Future<User?> _fetchUser() {
    return _userRepo.fetchUser(_uid);
  }

    void _confirmAndSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (shouldSignOut == true) {
    await AuthService().signOut();

    // Use microtask to safely navigate after widget rebuild
    Future.microtask(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('User not found'));
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text("Profile"),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/tourpal_logo.png',
                fit: BoxFit.contain,
            ),
          ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed:() => _confirmAndSignOut(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.profilePhoto!),
                    )
                  else
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user.email ?? '', style: const TextStyle(fontSize: 16)),
                  const Divider(height: 32),
                  if (user.description != null && user.description!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('About', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Text(user.description!),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Birthdate'),
                          Text(user.birthdate ?? ''),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Member Since'),
                          Text(user.regdate ?? ''),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}