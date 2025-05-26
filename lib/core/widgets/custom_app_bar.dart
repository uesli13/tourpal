import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom app bar that provides consistent styling across the app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a [CustomAppBar] with customizable properties
  const CustomAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0.0,
    this.backgroundColor,
    this.height = kToolbarHeight,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.showBackButton = true,
    this.systemUiOverlayStyle,
    this.onBackPressed,
  });

  /// The title widget to display
  final Widget? title;
  
  /// The title text to display (used if [title] is null)
  final String? titleText;
  
  /// A list of widgets to display in a row after the title
  final List<Widget>? actions;
  
  /// A widget to display before the title
  final Widget? leading;
  
  /// Whether the title should be centered
  final bool centerTitle;
  
  /// The elevation of the app bar
  final double elevation;
  
  /// The color of the app bar
  final Color? backgroundColor;
  
  /// The height of the app bar
  final double height;
  
  /// A widget to display at the bottom of the app bar
  final PreferredSizeWidget? bottom;
  
  /// Whether to automatically imply a back button if possible
  final bool automaticallyImplyLeading;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// System UI overlay style to apply
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  
  /// Callback for when the back button is pressed
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: title ?? (titleText != null 
          ? Text(
              titleText!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          : null),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      systemOverlayStyle: systemUiOverlayStyle ?? SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness == Brightness.light
            ? Brightness.light
            : Brightness.dark,
      ),
      actions: actions,
      leading: _buildLeading(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
    );
  }
  
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }
    
    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }
    
    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));
}

/// A custom transparent app bar
class TransparentAppBar extends CustomAppBar {
  /// Creates a transparent app bar
  const TransparentAppBar({
    super.key,
    super.titleText,
    super.title,
    super.actions,
    super.leading,
    super.centerTitle = true,
    super.elevation = 0.0,
    super.height = kToolbarHeight,
    super.bottom,
    super.automaticallyImplyLeading = true,
    super.showBackButton = true,
    super.systemUiOverlayStyle,
    super.onBackPressed,
  }) : super(
    backgroundColor: Colors.transparent,
  );
}

/// A custom app bar with a search field
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a search app bar
  const SearchAppBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.controller,
    this.hintText = 'Search...',
    this.backgroundColor,
    this.height = kToolbarHeight,
    this.automaticallyImplyLeading = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  /// Called when the text changes
  final ValueChanged<String> onChanged;
  
  /// Called when the user submits the search query
  final ValueChanged<String>? onSubmitted;
  
  /// The controller for the search field
  final TextEditingController? controller;
  
  /// Hint text for the search field
  final String hintText;
  
  /// The color of the app bar
  final Color? backgroundColor;
  
  /// The height of the app bar
  final double height;
  
  /// Whether to automatically imply a back button if possible
  final bool automaticallyImplyLeading;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// Callback for when the back button is pressed
  final VoidCallback? onBackPressed;
  
  /// A list of widgets to display in a row after the search field
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: 0,
      title: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller!.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
        style: theme.textTheme.bodyLarge,
        textInputAction: TextInputAction.search,
      ),
      leading: _buildLeading(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
    );
  }
  
  Widget? _buildLeading(BuildContext context) {
    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }
    
    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}