import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/presentation/screens/main_dashboard_page.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../messages/presentation/screens/messages_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../guide/presentation/screens/guide_dashboard_screen.dart';
import '../../../guide/presentation/screens/my_tours_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isGuide = authState.user.isGuide;

        // Different screens based on user mode
        final screens = isGuide ? _getGuideScreens() : _getTravelerScreens();

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _buildBottomNavigationBar(isGuide),
        );
      },
    );
  }

  List<Widget> _getTravelerScreens() {
    return [
      MainDashboardScreen(onNavigateToTab: _navigateToTab),
      const ExploreScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
  }

  List<Widget> _getGuideScreens() {
    return [
      GuideDashboardScreen(onNavigateToTab: _navigateToTab),
      const MyToursScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
  }

  Widget _buildBottomNavigationBar(bool isGuide) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isGuide ? Colors.orange : AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: isGuide
            ? _getGuideNavigationItems()
            : _getTravelerNavigationItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _getTravelerNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Explore',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getGuideNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.business_center_outlined),
        activeIcon: Icon(Icons.business_center),
        label: 'Guide Hub',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.tour_outlined),
        activeIcon: Icon(Icons.tour),
        label: 'My Tours',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }
}