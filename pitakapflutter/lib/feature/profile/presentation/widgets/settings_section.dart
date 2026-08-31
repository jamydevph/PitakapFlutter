import 'package:flutter/material.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final String? value;
  final bool isDestructive;
  final VoidCallback? onTap;

  const SettingsTile({
    required this.icon,
    required this.label,
    this.hint,
    this.value,
    this.isDestructive = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = isDestructive ? colorScheme.error : null;

    return ListTile(
      leading: Icon(icon, color: foreground),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
      ),
      subtitle: hint == null ? null : Text(hint!),
      trailing: value == null
          ? null
          : Text(
              value!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: onTap,
    );
  }
}
