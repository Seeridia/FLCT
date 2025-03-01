import 'package:flutter/material.dart';

class AppointmentResultView extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final VoidCallback onBackPressed;

  const AppointmentResultView({
    super.key,
    required this.isSuccess,
    required this.message,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Map<String, String> details = _parseAppointmentDetails(message);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Card(
            elevation: 2,
            shadowColor: colorScheme.shadow.withOpacity(0.3),
            color:
                isSuccess
                    ? colorScheme.primaryContainer.withOpacity(0.9)
                    : colorScheme.errorContainer.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 72,
                    color: isSuccess ? colorScheme.primary : colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? '预约成功' : '预约失败',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isSuccess ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isSuccess && details.isNotEmpty) ...[
                    _buildAppointmentDetailsSection(
                      details,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  FilledButton(
                    onPressed: onBackPressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 56),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.grey[500]?.withOpacity(0.5),
                    ),
                    child: Text(
                      isSuccess ? '返回预约' : '重新尝试',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsSection(
    Map<String, String> details,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            details.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Value
                    Expanded(
                      child: Text(
                        entry.value,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Map<String, String> _parseAppointmentDetails(String message) {
    final Map<String, String> details = {};

    final RegExp detailPattern = RegExp(r'([^：\n]+)[:：]\s*([^,，\n]+)[,，\n]?');
    final matches = detailPattern.allMatches(message);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        String key = match.group(1)?.trim() ?? '';
        String value = match.group(2)?.trim() ?? '';

        // Clean up common keys
        if (key.contains('座位')) key = '座位号';
        if (key.contains('时间')) key = '预约时间';
        if (key.contains('日期')) key = '预约日期';
        if (key.contains('地点') || key.contains('地址')) key = '地点';

        details[key] = value;
      }
    }

    return details;
  }
}
