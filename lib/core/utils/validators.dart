import '../exceptions/profile_exceptions.dart';
import '../exceptions/auth_exceptions.dart';

/// Input validation utilities following TOURPAL DEVELOPMENT RULES
/// 
/// Provides centralized validation with custom exceptions
class AppValidators {
  
  // === PROFILE VALIDATION ===
  
  /// Validates user profile name
  /// 
  /// Throws [ProfileValidationException] if invalid
  static void validateProfileName(String? name) {
    if (name == null || name.trim().isEmpty) {
      throw ProfileValidationException.invalidName;
    }
    
    final trimmedName = name.trim();
    if (trimmedName.length > 50) {
      throw ProfileValidationException.invalidName;
    }
  }

  /// Validates user profile bio
  /// 
  /// Throws [ProfileValidationException] if invalid
  static void validateProfileBio(String? bio) {
    if (bio != null && bio.trim().length > 150) {
      throw ProfileValidationException.invalidBio;
    }
  }

  /// Validates email format
  /// 
  /// Throws [ProfileValidationException] or [AuthValidationException] if invalid
  static void validateEmail(String? email, {bool isAuth = false}) {
    if (email == null || email.trim().isEmpty) {
      throw isAuth ? AuthValidationException.invalidEmail : ProfileValidationException.invalidEmail;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw isAuth ? AuthValidationException.invalidEmail : ProfileValidationException.invalidEmail;
    }
  }

  /// Validates password strength for profile updates
  /// 
  /// Throws [ProfileValidationException] if weak
  static void validatePassword(String? password) {
    if (password == null || password.length < 8) {
      throw ProfileValidationException.weakPassword;
    }
    
    // Check for uppercase, lowercase, and number
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    if (!hasUppercase || !hasLowercase || !hasNumber) {
      throw ProfileValidationException.weakPassword;
    }
  }

  /// Checks if password meets strength requirements
  /// 
  /// Returns true if password is strong enough
  static bool isPasswordStrong(String? password) {
    try {
      validatePassword(password);
      return true;
    } catch (e) {
      return false;
    }
  }

  // === AUTH VALIDATION ===
  
  /// Validates auth password (less strict than profile password)
  /// 
  /// Throws [AuthValidationException] if invalid
  static void validateAuthPassword(String? password) {
    if (password == null || password.length < 6) {
      throw AuthValidationException.invalidPassword;
    }
  }

  /// Validates auth name for signup
  /// 
  /// Throws [AuthValidationException] if invalid
  static void validateAuthName(String? name) {
    if (name == null || name.trim().isEmpty) {
      throw AuthValidationException.invalidName;
    }
    
    final trimmedName = name.trim();
    if (trimmedName.length > 50) {
      throw AuthValidationException.invalidName;
    }
  }

  /// Validates password confirmation matches
  /// 
  /// Throws [AuthValidationException] if mismatch
  static void validatePasswordConfirmation(String? password, String? confirmation) {
    if (password != confirmation) {
      throw AuthValidationException.passwordMismatch;
    }
  }

  // === UTILITY METHODS ===
  
  /// Sanitizes user input by trimming whitespace
  static String? sanitizeInput(String? input) {
    return input?.trim();
  }

  /// Sanitizes and limits string length
  static String? sanitizeAndLimit(String? input, int maxLength) {
    final sanitized = sanitizeInput(input);
    if (sanitized == null) return null;
    
    return sanitized.length > maxLength 
        ? sanitized.substring(0, maxLength) 
        : sanitized;
  }

  /// Validates image file size (in bytes)
  /// 
  /// Throws [ProfileValidationException] if too large
  static void validateImageSize(int? sizeInBytes) {
    if (sizeInBytes != null && sizeInBytes > 5 * 1024 * 1024) { // 5MB
      throw ProfileValidationException.invalidImage;
    }
  }

  /// Validates image file extension
  /// 
  /// Throws [ProfileValidationException] if invalid format
  static void validateImageExtension(String? fileName) {
    if (fileName == null) return;
    
    final extension = fileName.toLowerCase().split('.').last;
    final validExtensions = ['jpg', 'jpeg', 'png'];
    
    if (!validExtensions.contains(extension)) {
      throw ProfileValidationException.invalidImage;
    }
  }

  /// Gets user-friendly error message from validation exception
  static String getValidationErrorMessage(dynamic error) {
    if (error is ProfileValidationException || 
        error is AuthValidationException) {
      return error.message;
    }
    return 'Please check your input and try again';
  }
}