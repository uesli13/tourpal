import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Services
import '../../features/auth/services/auth_service.dart';
import '../../features/dashboard/services/dashboard_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/tours/services/tour_plan_service.dart';
import '../../features/tours/services/tour_service.dart';
import '../../services/booking_service.dart';
import '../../features/explore/services/explore_service.dart';
import '../../services/user_service.dart';

// BLoCs
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/tours/presentation/bloc/tour_bloc.dart';
import '../../features/tour_creation/presentation/bloc/tour_creation_bloc.dart';
import '../../features/booking/bloc/booking_bloc.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase instances
        Provider<firebase_auth.FirebaseAuth>(
          create: (_) => firebase_auth.FirebaseAuth.instance,
        ),
        Provider<FirebaseFirestore>(
          create: (_) => FirebaseFirestore.instance,
        ),
        Provider<FirebaseStorage>(
          create: (_) => FirebaseStorage.instance,
        ),
        Provider<GoogleSignIn>(
          create: (_) => GoogleSignIn(),
        ),

        // Services - using ProxyProvider for dependency injection
        ProxyProvider3<firebase_auth.FirebaseAuth, FirebaseFirestore, GoogleSignIn, AuthService>(
          update: (_, firebaseAuth, firestore, googleSignIn, __) => AuthService(
            auth: firebaseAuth,
            firestore: firestore,
            googleSignIn: googleSignIn,
          ),
        ),
        ProxyProvider<FirebaseFirestore, DashboardService>(
          update: (_, firestore, __) => DashboardService(
            firestore: firestore,
          ),
        ),
        ProxyProvider2<FirebaseFirestore, firebase_auth.FirebaseAuth, ProfileService>(
          update: (_, firestore, firebaseAuth, __) => ProfileService(
            firestore: firestore,
            firebaseAuth: firebaseAuth,
          ),
        ),
        ProxyProvider<FirebaseFirestore, TourPlanService>(
          update: (_, firestore, __) => TourPlanService(
            firestore: firestore,
          ),
        ),
        ProxyProvider2<FirebaseFirestore, FirebaseStorage, TourService>(
          update: (_, firestore, storage, __) => TourService(
            firestore,
            storage,
          ),
        ),
        Provider<BookingService>(
          create: (_) => BookingService(),
        ),
        ProxyProvider<FirebaseFirestore, ExploreService>(
          update: (_, firestore, __) => ExploreService(firestore),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),

        // BLoCs - using ProxyProvider to access services properly
        ProxyProvider2<AuthService, ProfileService, AuthBloc>(
          update: (_, authService, profileService, previous) {
            if (previous != null) {
              previous.close();
            }
            return AuthBloc(
              authService: authService,
              profileService: profileService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider<DashboardService, DashboardBloc>(
          update: (_, dashboardService, previous) {
            if (previous != null) {
              previous.close();
            }
            return DashboardBloc(
              dashboardService: dashboardService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider<ProfileService, ProfileBloc>(
          update: (_, profileService, previous) {
            if (previous != null) {
              previous.close();
            }
            return ProfileBloc(
              profileService: profileService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider2<TourService, AuthBloc, TourBloc>(
          update: (_, tourService, authBloc, previous) {
            if (previous != null) {
              previous.close();
            }
            return TourBloc(
              tourService: tourService,
              authBloc: authBloc,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider2<TourService, firebase_auth.FirebaseAuth, TourCreationBloc>(
          update: (_, tourService, firebaseAuth, previous) {
            if (previous != null) {
              previous.close();
            }
            return TourCreationBloc(
              tourService: tourService,
              auth: firebaseAuth,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider<ExploreService, ExploreBloc>(
          update: (_, exploreService, previous) {
            if (previous != null) {
              previous.close();
            }
            return ExploreBloc(
              exploreService: exploreService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider<BookingService, BookingBloc>(
          update: (_, bookingService, previous) {
            if (previous != null) {
              previous.close();
            }
            return BookingBloc(
              bookingService: bookingService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        ProxyProvider<UserService, FavoritesBloc>(
          update: (_, userService, previous) {
            if (previous != null) {
              previous.close();
            }
            return FavoritesBloc(
              userService: userService,
            );
          },
          dispose: (_, bloc) => bloc.close(),
        ),
        Provider<NotificationsBloc>(
          create: (_) => NotificationsBloc(),
          dispose: (_, bloc) => bloc.close(),
        ),
      ],
      child: child,
    );
  }
}