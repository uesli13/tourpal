# 🎯 TOURPAL DEVELOPMENT RULES

## **📁 1. FOLDER & STORAGE STRUCTURE RULES**

```
lib/
├── core/                          # Core utilities & configs
│   ├── constants/                 # App colors, strings, etc.
│   ├── config/                    # Firebase, API configs
│   ├── errors/                    # Error handling
│   ├── exceptions/                # Custom exceptions
│   ├── utils/                     # Logger and utilities
│   └── auth/                      # Auth wrapper utilities
├── features/                      # Feature-based organization
│   ├── auth/
│   │   ├── domain/                # Business logic & entities
│   │   ├── data/                  # Data sources & repositories
│   │   ├── services/              # Firebase services
│   │   └── presentation/          # UI & BLoC
│   │       ├── bloc/              # BLoC state management
│   │       ├── screens/           # Full-screen widgets
│   │       ├── widgets/           # Reusable components
│   │       └── dialogs/           # Modal dialogs
│   ├── profile/
│   │   └── presentation/
│   │       └── bloc/              # BLoC state management
│   ├── tours/
│   └── [feature_name]/
├── models/                        # Shared data models
├── services/                      # Global Firebase services
├── repositories/                  # Data access layer
└── main.dart                      # App entry point
```

```
FIREBASE STORAGE STRUCTURE
/
|-- user/
|   |-- {user_id}/
|   |   |-- profile_picture.jpg
|   |   |-- tours/
```

**RULE:** Every new feature follows this exact structure with BLoC folder!

## **📚 2. NAMING CONVENTIONS**

```dart
// FILES
snake_case.dart              ✅ profile_setup_page.dart
PascalCase.dart              ❌ ProfileSetupPage.dart

// CLASSES
PascalCase                   ✅ ProfileBloc, AuthEvent
camelCase                    ❌ profileBloc, authEvent

// VARIABLES & FUNCTIONS
camelCase                    ✅ _nameController, updateProfile
snake_case                   ❌ _name_controller, update_profile

// CONSTANTS
SCREAMING_SNAKE_CASE         ✅ APP_COLORS, API_ENDPOINTS
camelCase                    ❌ appColors, apiEndpoints

// BLOC SPECIFIC
PascalCase + Suffix          ✅ ProfileEvent, ProfileState, ProfileBloc
no_suffix                    ❌ Profile, ProfileManager

// PRIVATE MEMBERS
_leading_underscore          ✅ _buildProfileSection(), _onUpdateProfile
no_underscore                ❌ buildProfileSection() (if private)
```

## **🧩 3. STATE MANAGEMENT RULES (BLoC PATTERN)**

```dart
// RULE: Use BLoC pattern for ALL state management

// ✅ GOOD: BLoC Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String bio;
  
  const UpdateProfileEvent({required this.name, required this.bio});
  
  @override
  List<Object> get props => [name, bio];
}

// ✅ GOOD: BLoC States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded({required this.user});
  @override
  List<Object> get props => [user];
}

// ✅ GOOD: BLoC Implementation
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;
  
  ProfileBloc({required ProfileService profileService})
      : _profileService = profileService,
        super(const ProfileInitial()) {
    on<UpdateProfileEvent>(_onUpdateProfile);
  }
  
  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await _profileService.updateProfile(/* */);
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}

// ❌ BAD: Direct state manipulation in widgets
// ❌ BAD: Using Provider/ChangeNotifier for business logic
// ❌ BAD: Mixing multiple state management solutions
```

## **🔧 4. SERVICE LAYER RULES**

```dart
// RULE: Services handle ALL Firebase operations and return domain models
class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  ProfileService(this._firestore, this._storage);

  // ✅ GOOD: Descriptive method names
  Future<User> updateProfile(ProfileUpdateRequest request) async {
    try {
      // Firebase operations
      final userData = await _firestore.collection('users').doc(id).update(/**/);
      return User.fromMap(userData, id);
    } on FirebaseException catch (e) {
      throw ProfileServiceException('Firebase error: ${e.message}');
    } catch (e) {
      throw ProfileServiceException('Failed to update profile: ${e.toString()}');
    }
  }

  // ✅ GOOD: Proper error handling with custom exceptions
  // ✅ GOOD: Return typed domain objects
  // ✅ GOOD: Single responsibility
  // ❌ BAD: Raw Firebase calls in BLoC
  // ❌ BAD: UI logic in services
}

// RULE: Create custom exceptions for better error handling
abstract class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
  
  @override
  String toString() => 'ProfileException: $message';
}

class ProfileValidationException extends ProfileException {
  const ProfileValidationException(String message) : super(message);
}

class ProfileServiceException extends ProfileException {
  const ProfileServiceException(String message) : super(message);
}
```

## **🎨 5. UI/WIDGET RULES (BLoC INTEGRATION)**

```dart
// RULE: Use BlocBuilder/BlocListener for state management
class ProfileSetupPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // ✅ GOOD: Handle side effects (navigation, snackbars)
        if (state is ProfileUpdateSuccess) {
          Navigator.pushReplacement(context, /**/);
        }
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(/**/);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              _buildHeaderSection(),     // ✅ GOOD: Extracted methods
              _buildFormSection(state),  // ✅ GOOD: Pass state to components
              _buildButtonSection(state),// ✅ GOOD: State-aware widgets
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonSection(ProfileState state) {
    return ElevatedButton(
      onPressed: state is ProfileLoading ? null : () {
        // ✅ GOOD: Dispatch events, don't call methods
        context.read<ProfileBloc>().add(
          UpdateProfileEvent(name: _nameController.text, bio: _bioController.text),
        );
      },
      child: state is ProfileLoading 
          ? CircularProgressIndicator() 
          : Text('Save'),
    );
  }
  
  // ❌ BAD: Calling service methods directly from UI
  // ❌ BAD: Managing state in StatefulWidget
  // ❌ BAD: Massive build() method with everything inline
}
```

## **🚨 6. ERROR HANDLING RULES**

```dart
// RULE: Handle errors at multiple layers

// ✅ SERVICE LAYER: Throw custom exceptions
class ProfileService {
  Future<User> updateProfile(ProfileUpdateRequest request) async {
    try {
      // Firebase operations
    } on FirebaseException catch (e) {
      throw ProfileServiceException('Firebase error: ${e.message}');
    } catch (e) {
      throw ProfileServiceException('Unexpected error: ${e.toString()}');
    }
  }
}

// ✅ BLOC LAYER: Catch and emit error states
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  Future<void> _onUpdateProfile(event, emit) async {
    emit(const ProfileLoading());
    try {
      _validateProfileInput(event); // Extract validation
      final user = await _profileService.updateProfile(event.request);
      emit(ProfileUpdateSuccess(user: user));
    } on ProfileValidationException catch (e) {
      emit(ProfileError(message: e.message));
    } on ProfileException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      emit(ProfileError(message: 'An unexpected error occurred'));
    }
  }
  
  // Extract validation to private methods
  void _validateProfileInput(UpdateProfileEvent event) {
    if (event.name.trim().length > 50) {
      throw const ProfileValidationException('Name cannot exceed 50 characters');
    }
    if (event.name.trim().isEmpty) {
      throw const ProfileValidationException('Name cannot be empty');
    }
  }
}

// ✅ UI LAYER: Display user-friendly messages
BlocListener<ProfileBloc, ProfileState>(
  listener: (context, state) {
    if (state is ProfileError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: /* widget */,
)

// ❌ BAD: Letting exceptions crash the app
// ❌ BAD: Generic error messages for users
```

## **📝 7. LOGGING RULES**

```dart
// RULE: Use AppLogger for structured logging throughout the app

// ✅ GOOD: Import and use AppLogger
import '../../../../core/utils/logger.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileService profileService})
      : _profileService = profileService,
        super(const ProfileInitial()) {
    
    // Log BLoC initialization
    AppLogger.info('ProfileBloc initialized');
  }

  @override
  void onChange(Change<ProfileState> change) {
    super.onChange(change);
    // Log state transitions
    AppLogger.blocTransition(
      'ProfileBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(ProfileEvent event) {
    super.onEvent(event);
    // Log events
    AppLogger.blocEvent('ProfileBloc', event.runtimeType.toString());
  }

  Future<void> _onUpdateProfile(event, emit) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting profile update');
    
    try {
      // Business logic
      stopwatch.stop();
      AppLogger.performance('Profile Update', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', true);
    } catch (e) {
      AppLogger.error('Profile update failed', e);
      AppLogger.serviceOperation('ProfileService', 'updateProfile', false);
    }
  }
}

// ✅ GOOD: Log levels available
AppLogger.debug('Debug information');     // 🐛 Development only
AppLogger.info('General information');    // ℹ️ General logs
AppLogger.warning('Warning message');     // ⚠️ Warnings
AppLogger.error('Error message');         // 🚨 Errors
AppLogger.critical('Critical error');     // 💥 Critical issues

// ✅ GOOD: Specialized logging methods
AppLogger.blocTransition('ProfileBloc', 'Loading', 'Loaded');  // 🔄 State changes
AppLogger.blocEvent('ProfileBloc', 'UpdateProfileEvent');      // 🎯 Events
AppLogger.serviceOperation('ProfileService', 'update', true);  // ✅/❌ Operations
AppLogger.performance('Profile Update', Duration(milliseconds: 150)); // ⏱️ Performance

// ❌ BAD: Using print() statements
// ❌ BAD: No error logging
// ❌ BAD: No performance tracking
```

## **🔄 8. DEPENDENCY INJECTION RULES**

```dart
// RULE: Use Provider for services, BlocProvider for BLoCs
class RepositoryProviders {
  static List<Provider> get providers => [
    // ✅ GOOD: Services as regular providers
    Provider<FirebaseFirestore>.value(value: firestore),
    
    Provider<ProfileService>(
      create: (context) => ProfileService(
        context.read<FirebaseFirestore>(),
        context.read<FirebaseStorage>(),
      ),
    ),
    
    Provider<AuthService>(
      create: (context) => AuthService(),
    ),
  ];

  static List<BlocProvider> get blocProviders => [
    // ✅ GOOD: BLoCs as BlocProvider
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        authService: context.read<AuthService>(),
        profileService: context.read<ProfileService>(),
      ),
    ),
    
    BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(
        profileService: context.read<ProfileService>(),
      ),
    ),
  ];
}

// ✅ GOOD: Clear separation between services and BLoCs
// ✅ GOOD: Services injected into BLoCs
// ❌ BAD: Direct instantiation in widgets
// ❌ BAD: Circular dependencies
```

## **🎯 9. FEATURE DEVELOPMENT RULES**

```
// RULE: Every feature follows BLoC architecture
features/
├── new_feature/
│   ├── domain/
│   │   ├── entities/          # Domain models (User, Tour, etc.)
│   │   ├── repositories/      # Abstract repository contracts
│   │   └── exceptions/        # Feature-specific exceptions
│   ├── data/
│   │   ├── models/            # Firebase/API models
│   │   ├── datasources/       # Remote/local data sources
│   │   └── repositories/      # Repository implementations
│   ├── services/              # Firebase services
│   └── presentation/
│       ├── bloc/              # Events, States, BLoCs
│       │   ├── feature_event.dart
│       │   ├── feature_state.dart
│       │   └── feature_bloc.dart
│       ├── screens/           # Full-screen widgets
│       ├── widgets/           # Reusable components
│       └── dialogs/           # Modal dialogs

// ✅ GOOD: Clear separation of concerns
// ✅ GOOD: BLoC handles ALL business logic
// ✅ GOOD: Services handle Firebase operations
// ❌ BAD: Business logic in UI widgets
// ❌ BAD: Direct Firebase calls in BLoC
```

## **⚡ 10. PERFORMANCE RULES**

```dart
// RULE: Optimize BLoC rebuilds and performance
class ProfileSetupPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      // ✅ GOOD: Use buildWhen to control rebuilds
      buildWhen: (previous, current) {
        return current is ProfileLoaded || 
               current is ProfileLoading || 
               current is ProfileError;
      },
      builder: (context, state) {
        return Scaffold(/* */);
      },
    );
  }
}

// ✅ GOOD: Use BlocSelector for specific state pieces
BlocSelector<ProfileBloc, ProfileState, bool>(
  selector: (state) => state is ProfileLoading,
  builder: (context, isLoading) {
    return isLoading ? CircularProgressIndicator() : Container();
  },
)

// ✅ GOOD: Dispose BLoCs properly (automatic with BlocProvider)
// ✅ GOOD: Use Equatable for state comparison
// ✅ GOOD: Lazy load images and data
// ❌ BAD: Unnecessary BLoC rebuilds
// ❌ BAD: Heavy operations in build method
```

## **🔒 11. SECURITY RULES**

```dart
// RULE: Validate at multiple layers

// ✅ CLIENT-SIDE: Form validation
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Invalid email format';
  }
  return null;
}

// ✅ SERVICE LAYER: Data sanitization
class ProfileService {
  Future<User> updateProfile(ProfileUpdateRequest request) async {
    // Sanitize inputs
    final sanitizedName = request.name?.trim().substring(0, min(50, request.name!.length));
    final sanitizedBio = request.bio?.trim().substring(0, min(150, request.bio!.length));
    
    // Validate before Firebase call
    if (sanitizedName == null || sanitizedName.isEmpty) {
      throw ProfileServiceException('Name cannot be empty');
    }
    
    // Firebase operations
  }
}

// ✅ BLOC LAYER: Business rule validation
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  Future<void> _onUpdateProfile(event, emit) async {
    // Validate business rules
    if (event.name.length > 50) {
      emit(const ProfileError(message: 'Name is too long'));
      return;
    }
    
    // Proceed with update
  }
}

// ✅ GOOD: Multi-layer validation
// ✅ GOOD: Input sanitization
// ✅ GOOD: Business rule validation
// ❌ BAD: Trusting client input blindly
```

## **🧪 12. TESTING RULES**

```dart
// RULE: All testing is performed MANUALLY by the developer

// ✅ MANUAL TESTING CHECKLIST:
void manualTestingProcedure() {
  // 1. BLoC State Management Testing
  // - Test profile updates with valid data
  // - Test profile updates with invalid data
  // - Verify loading states appear correctly
  // - Check error states display properly
  // - Confirm success states navigate correctly
  
  // 2. Logger System Testing
  // - Check console for AppLogger output
  // - Verify emoji indicators appear
  // - Test different log levels
  // - Monitor performance metrics
  
  // 3. Error Handling Testing
  // - Test network disconnection
  // - Test invalid inputs
  // - Test Firebase errors
  // - Verify user-friendly error messages
  
  // 4. Authentication Flow Testing
  // - Test sign up process
  // - Test sign in process
  // - Test Google sign-in
  // - Test profile setup navigation
  
  // 5. UI Responsiveness Testing
  // - Test on different screen sizes
  // - Test loading indicators
  // - Test form validation
  // - Test navigation flows
}

// ✅ GOOD: Comprehensive manual testing
// ✅ GOOD: Test all user paths
// ✅ GOOD: Test error scenarios
// ✅ GOOD: Test performance
// ❌ BAD: Skipping edge cases
// ❌ BAD: Not testing error states
```

## **📦 13. PACKAGE MANAGEMENT RULES**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase (core functionality)
  firebase_core: ^2.32.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.17.5
  firebase_storage: ^11.7.0
  
  # BLoC State Management 🚀
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5
  
  # Dependency Injection
  provider: ^6.1.1
  
  # UI/UX
  image_picker: ^1.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing (FOR REFERENCE - Manual testing preferred)
  bloc_test: ^9.1.4
  mocktail: ^1.0.0
  
# ✅ GOOD: BLoC-specific packages
# ✅ GOOD: Testing packages available if needed
# ✅ GOOD: Comment package purposes
# ❌ BAD: Mixing multiple state management solutions
```

## **🔄 14. GIT WORKFLOW RULES**

```bash
# RULE: Feature-specific branches and clear commits
git checkout -b feature/profile-bloc-improvements
git commit -m "feat(core): add custom exception classes"
git commit -m "feat(profile): integrate AppLogger in ProfileBloc"
git commit -m "refactor(profile): extract validation methods"
git commit -m "test(manual): verify ProfileBloc improvements"

# ✅ GOOD: Use conventional commits with feature scope
# ✅ GOOD: One improvement per commit
# ✅ GOOD: Manual testing noted in commits
# ❌ BAD: "WIP" or "fix stuff" commits
```

---

## **🏆 THE GOLDEN RULES SUMMARY:**

### **🚀 TOP 5 BLOC MUST-FOLLOW RULES:**

1. **🏗️ BLOC ARCHITECTURE** - Events → BLoC → States → UI
2. **🎯 SINGLE RESPONSIBILITY** - One BLoC per feature domain
3. **🔒 LAYER VALIDATION** - Validate at UI, BLoC, and Service layers
4. **📱 IMMUTABLE STATES** - Use Equatable for all states and events
5. **🧪 MANUAL TESTING** - Thoroughly test all user paths manually

### **🚀 BLOC BENEFITS:**

- ✅ **Predictable state changes** with event-driven architecture
- ✅ **Testable business logic** separated from UI
- ✅ **Time-travel debugging** with BLoC Inspector
- ✅ **Scalable architecture** for complex applications
- ✅ **Clear data flow** from events to states to UI
- ✅ **Comprehensive logging** with AppLogger integration

---

### **TODOs:**
  - [ ] Add to favorites: low priority
  - [ ] Tour guide availaibility: medium priority
    - [ ] set guide availability schedule
    - [ ] validation of busy schedule without overlapping tours
  - [ ] Tour card design: low-medium priority
    - [ ] Remake the card to have relevant information:
      - [ ] Name
      - [ ] Description
      - [ ] Number of participants
      - [ ] Price
      - [ ] Image
      - [ ] Guide name
      - [ ] Guide profile picture
  - [ ] Send notifications to guide when tour is booked: high priority
  - [ ] User profile:
    - [ ] Edit profile: low priority
  - [ ] Complete profile setup: medium priority
    - [ ] Remake the flow:
      - Confirm that user profile is complete when authenticated