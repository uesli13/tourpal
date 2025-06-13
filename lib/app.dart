import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/injections/repository_providers.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';
import 'features/profile/presentation/screens/become_guide_screen.dart';
import 'features/profile/presentation/screens/guide_profile_screen.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: RepositoryProviders.providers,
      child: MultiBlocProvider(
        providers: RepositoryProviders.blocProviders,
        child: MaterialApp(
          title: 'TourPal',
          debugShowCheckedModeBanner: false,
          theme: AppConfig.theme,
          home: const AuthWrapper(),
          routes: {
            '/become-guide': (context) => const BecomeGuideScreen(),
            '/guide-profile': (context) => const GuideProfileScreen(),
          },
        ),
      ),
    );
  }
}