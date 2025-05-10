import 'package:flutter/material.dart';
import 'package:approver/utils/version.dart';

/// A widget that displays the current app version information.
/// This can be used in settings screens, about pages, or other places
/// where you want to show the app version.
class VersionDisplay extends StatelessWidget {
  /// Whether to show the full version (including build number)
  final bool showFullVersion;
  
  /// Text style to apply to the version text
  final TextStyle? style;
  
  /// Create a version display widget
  const VersionDisplay({
    super.key,
    this.showFullVersion = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.grey[600],
    );
    
    final displayStyle = style ?? defaultStyle;
    final versionText = showFullVersion 
        ? 'Version ${AppVersion.fullVersion}'
        : 'Version ${AppVersion.version}';
        
    return Text(
      versionText,
      style: displayStyle,
      textAlign: TextAlign.center,
    );
  }
} 