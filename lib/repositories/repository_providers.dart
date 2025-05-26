import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../features/auth/services/auth_service.dart';
import '../features/profile/services/profile_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';

class RepositoryProviders {
  static List<Provider> get providers => [
        // Firebase Services
        Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
        Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),
        Provider<FirebaseStorage>.value(value: FirebaseStorage.instance),
        Provider<GoogleSignIn>.value(value: GoogleSignIn()),

        // App Services
        Provider<AuthService>(
          create: (context) => AuthService(),
        ),

        Provider<ProfileService>(
          create: (context) => ProfileService(
            firestore: context.read<FirebaseFirestore>(),
            storage: context.read<FirebaseStorage>(),
          ),
        ),
      ];

  static List<BlocProvider> get blocProviders => [
        // Auth BLoC
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: context.read<AuthService>(),
            profileService: context.read<ProfileService>(),
          ),
        ),

        // Profile BLoC
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            profileService: context.read<ProfileService>(),
          ),
        ),
      ];

  static Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocProvider(
        providers: blocProviders,
        child: child,
      ),
    );
  }
}