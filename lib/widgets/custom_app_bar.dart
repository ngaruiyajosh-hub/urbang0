import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar widget for the transport application.
/// Implements status-aware interface with minimal elevation for clean design.
///
/// Supports multiple variants for different screen contexts.
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button for navigation
  withBack,

  /// App bar with search functionality
  withSearch,

  /// Transparent app bar for overlaying content (e.g., maps)
  transparent,

  /// App bar with role indicator (passenger/driver)
  withRole,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display
  final String? title;

  /// App bar variant
  final CustomAppBarVariant variant;

  /// Leading widget (overrides default back button)
  final Widget? leading;

  /// Action widgets to display on the right
  final List<Widget>? actions;

  /// Whether to show elevation shadow
  final bool showElevation;

  /// Custom background color (overrides theme)
  final Color? backgroundColor;

  /// Custom foreground color for icons and text
  final Color? foregroundColor;

  /// Role text for withRole variant
  final String? roleText;

  /// Search callback for withSearch variant
  final VoidCallback? onSearchTap;

  /// Center the title
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.leading,
    this.actions,
    this.showElevation = false,
    this.backgroundColor,
    this.foregroundColor,
    this.roleText,
    this.onSearchTap,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on variant
    final effectiveBackgroundColor = variant == CustomAppBarVariant.transparent
        ? Colors.transparent
        : backgroundColor ?? colorScheme.surface;

    final effectiveForegroundColor =
        foregroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? Colors.white
            : theme.textTheme.bodyLarge?.color);

    // Determine system UI overlay style
    final systemOverlayStyle = variant == CustomAppBarVariant.transparent
        ? SystemUiOverlayStyle.light
        : (theme.brightness == Brightness.light
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light);

    return AppBar(
      systemOverlayStyle: systemOverlayStyle,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: showElevation ? 2.0 : 0,
      shadowColor: showElevation ? colorScheme.shadow : null,
      centerTitle: centerTitle,
      leading: _buildLeading(context, effectiveForegroundColor),
      title: _buildTitle(context, effectiveForegroundColor),
      actions: _buildActions(context, effectiveForegroundColor),
    );
  }

  Widget? _buildLeading(BuildContext context, Color? foregroundColor) {
    if (leading != null) return leading;

    switch (variant) {
      case CustomAppBarVariant.withBack:
        return IconButton(
          icon: Icon(Icons.arrow_back, color: foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        );
      case CustomAppBarVariant.transparent:
        return IconButton(
          icon: Icon(Icons.arrow_back, color: foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        );
      default:
        return null;
    }
  }

  Widget? _buildTitle(BuildContext context, Color? foregroundColor) {
    if (title == null && variant != CustomAppBarVariant.withRole) return null;

    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.withRole:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (roleText != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleText!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      case CustomAppBarVariant.withSearch:
        return InkWell(
          onTap: onSearchTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: foregroundColor?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? 'Search location...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Text(
          title!,
          style: theme.textTheme.titleLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  List<Widget>? _buildActions(BuildContext context, Color? foregroundColor) {
    if (actions != null) return actions;

    switch (variant) {
      case CustomAppBarVariant.standard:
      case CustomAppBarVariant.withBack:
        return [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: foregroundColor),
            onPressed: () {
              // Handle notifications
            },
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ];
      case CustomAppBarVariant.transparent:
        return [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert, color: foregroundColor),
              onPressed: () {
                // Handle menu
              },
              tooltip: 'Menu',
            ),
          ),
        ];
      default:
        return null;
    }
  }
}
