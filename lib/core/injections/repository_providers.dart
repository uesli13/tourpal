import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Core Services
import '../services/storage_service.dart';

// Auth Domain Layer
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/send_password_reset_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';

// Profile Domain Layer
import '../../features/profile/data/datasources/firebase_profile_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/domain/usecases/upload_profile_image_usecase.dart';

// Tour Domain Layer
import '../../features/tours/data/datasources/firebase_tour_data_source.dart';
import '../../features/tours/data/repositories/tour_repository_impl.dart';
import '../../features/tours/domain/repositories/tour_repository.dart';
import '../../features/tours/domain/usecases/get_tours_usecase.dart';
import '../../features/tours/domain/usecases/update_tour_usecase.dart';

// Booking Domain Layer
import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/services/booking_service.dart';

// Tour Session Services
import '../../features/tours/services/tour_session_service.dart';
import '../../features/tours/services/tour_journal_service.dart';
import '../../features/tours/services/location_tracking_service.dart';

// BLoCs
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/role_bloc.dart';
import '../../features/tours/presentation/bloc/tour_creation_bloc.dart';
import '../../features/tours/presentation/bloc/tour_bloc.dart';
import '../../features/bookings/presentation/bloc/booking_bloc.dart';

class RepositoryProviders {
  static List<Provider> get providers => [
    // Firebase Instances
    Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
    Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),
    Provider<FirebaseStorage>.value(value: FirebaseStorage.instance),
    Provider<GoogleSignIn>.value(value: GoogleSignIn()),
    
    // Core Services
    Provider<StorageService>(
      create: (context) => StorageService(
        storage: context.read<FirebaseStorage>(),
      ),
    ),

    // Auth Data Sources
    Provider<FirebaseAuthDataSource>(
      create: (context) => FirebaseAuthDataSource(
        context.read<FirebaseAuth>(),
        context.read<GoogleSignIn>(),
        context.read<FirebaseFirestore>(),
      ),
    ),

    // Auth Repositories
    Provider<AuthRepository>(
      create: (context) => AuthRepositoryImpl(
        context.read<FirebaseAuthDataSource>(),
      ),
    ),

    // Auth Use Cases
    Provider<SignInWithEmailUsecase>(
      create: (context) => SignInWithEmailUsecase(
        context.read<AuthRepository>(),
      ),
    ),
    Provider<SignUpWithEmailUsecase>(
      create: (context) => SignUpWithEmailUsecase(
        context.read<AuthRepository>(),
      ),
    ),
    Provider<SignInWithGoogleUsecase>(
      create: (context) => SignInWithGoogleUsecase(
        context.read<AuthRepository>(),
      ),
    ),
    Provider<SignOutUsecase>(
      create: (context) => SignOutUsecase(
        context.read<AuthRepository>(),
      ),
    ),
    Provider<SendPasswordResetUsecase>(
      create: (context) => SendPasswordResetUsecase(
        context.read<AuthRepository>(),
      ),
    ),
    Provider<GetCurrentUserUsecase>(
      create: (context) => GetCurrentUserUsecase(
        context.read<AuthRepository>(),
      ),
    ),

    // Profile Data Sources
    Provider<FirebaseProfileDataSource>(
      create: (context) => FirebaseProfileDataSource(
        firestore: context.read<FirebaseFirestore>(),
        storage: context.read<FirebaseStorage>(),
      ),
    ),

    // Profile Repositories
    Provider<ProfileRepository>(
      create: (context) => ProfileRepositoryImpl(
        remoteDataSource: context.read<FirebaseProfileDataSource>(),
      ),
    ),

    // Profile Use Cases
    Provider<GetProfileUsecase>(
      create: (context) => GetProfileUsecase(
        context.read<ProfileRepository>(),
      ),
    ),
    Provider<UpdateProfileUsecase>(
      create: (context) => UpdateProfileUsecase(
        context.read<ProfileRepository>(),
      ),
    ),
    Provider<UploadProfileImageUsecase>(
      create: (context) => UploadProfileImageUsecase(
        context.read<ProfileRepository>(),
      ),
    ),

    // Tour Data Sources
    Provider<FirebaseTourDataSource>(
      create: (context) => FirebaseTourDataSource(
        context.read<FirebaseFirestore>(),
      ),
    ),

    // Tour Repositories
    Provider<TourRepository>(
      create: (context) => TourRepositoryImpl(
        context.read<FirebaseTourDataSource>(),
      ),
    ),

    // Tour Use Cases
    Provider<GetToursUsecase>(
      create: (context) => GetToursUsecase(
        context.read<TourRepository>(),
      ),
    ),
    Provider<UpdateTourUsecase>(
      create: (context) => UpdateTourUsecase(
        context.read<TourRepository>(),
      ),
    ),

    // Booking Repositories
    Provider<BookingRepository>(
      create: (context) => BookingRepositoryImpl(
        firestore: context.read<FirebaseFirestore>(),
      ),
    ),
    
    // Services
    Provider<BookingService>(
      create: (context) => BookingService(
        bookingRepository: context.read<BookingRepository>(),
      ),
    ),
    
    // Tour functionality services
    Provider<TourSessionService>(
      create: (context) => TourSessionService(),
    ),
    
    Provider<TourJournalService>(
      create: (context) => TourJournalService(),
    ),
    
    Provider<LocationTrackingService>(
      create: (context) => LocationTrackingService(),
    ),
  ];

  static List<BlocProvider> get blocProviders => [
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        signInWithEmailUsecase: context.read<SignInWithEmailUsecase>(),
        signUpWithEmailUsecase: context.read<SignUpWithEmailUsecase>(),
        signInWithGoogleUsecase: context.read<SignInWithGoogleUsecase>(),
        signOutUsecase: context.read<SignOutUsecase>(),
        sendPasswordResetUsecase: context.read<SendPasswordResetUsecase>(),
        getCurrentUserUsecase: context.read<GetCurrentUserUsecase>(),
      ),
    ),
    BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(
        getProfileUsecase: context.read<GetProfileUsecase>(),
        updateProfileUsecase: context.read<UpdateProfileUsecase>(),
        uploadProfileImageUsecase: context.read<UploadProfileImageUsecase>(),
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<RoleBloc>(
      create: (context) => RoleBloc(),
    ),
    BlocProvider<TourCreationBloc>(
      create: (context) => TourCreationBloc(
        storageService: context.read<StorageService>(),
      ),
    ),
    BlocProvider<TourBloc>(
      create: (context) => TourBloc(
        getToursUsecase: context.read<GetToursUsecase>(),
        updateTourUsecase: context.read<UpdateTourUsecase>(),
      ),
    ),
    BlocProvider<BookingBloc>(
      create: (context) => BookingBloc(
        bookingService: context.read<BookingService>(),
      ),
    ),
  ];
}