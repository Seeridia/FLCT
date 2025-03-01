import 'package:flutter/material.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Function(String) onSignIn;
  final Function(String) onSignOut;
  final Function(String) onCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onSignIn,
    required this.onSignOut,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = appointment.getStatusText();
    Color statusColor;

    switch (statusText) {
      case '已取消':
        statusColor = Theme.of(context).colorScheme.error;
        break;
      case '已完成':
        statusColor = Theme.of(context).colorScheme.tertiary;
        break;
      case '待签到':
        statusColor = Theme.of(context).colorScheme.primary;
        break;
      case '已签到':
        statusColor = Theme.of(context).colorScheme.primary;
        break;
      case '未开始':
        statusColor = Theme.of(context).colorScheme.secondary;
        break;
      case '未签到':
        statusColor = Theme.of(context).colorScheme.error;
        break;
      default:
        statusColor = Theme.of(context).colorScheme.error;
    }

    final bool needsBlueBorder = statusText == '待签到' || statusText == '未开始';

    return Card(
      shape:
          needsBlueBorder
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              )
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, statusText, statusColor),

            const SizedBox(height: 12),

            _buildDetails(context),

            if (appointment.auditStatus == 2) ...[
              const SizedBox(height: 16),
              _buildActionButtons(statusText),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String statusText,
    Color statusColor,
  ) {
    return Row(
      children: [
        Icon(
          Icons.chair_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${appointment.floor}F ${appointment.spaceName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          appointment.date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.access_time_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${appointment.beginTime} - ${appointment.endTime}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        // Icon(
        //   Icons.numbers_outlined,
        //   size: 16,
        //   color: Theme.of(context).colorScheme.onSurfaceVariant,
        // ),
        // const SizedBox(width: 4),
        // Text(
        //   appointment.id,
        //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //     color: Theme.of(context).colorScheme.onSurfaceVariant,
        //   ),
        // ),
        // 塞不下了...
      ],
    );
  }

  Widget _buildActionButtons(String statusText) {
    if (!appointment.sign && statusText != '未开始' && statusText != '未签到') {
      // 未签到且不是未开始状态时显示签到和取消按钮
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => onSignIn(appointment.id),
              child: const Text('签到'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onCancel(appointment.id),
              child: const Text('取消预约'),
            ),
          ),
        ],
      );
    } else if (appointment.sign) {
      // 已签到时显示签退按钮
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => onSignOut(appointment.id),
              child: const Text('签退'),
            ),
          ),
        ],
      );
    } else if (statusText == '未开始') {
      // 未开始状态只显示取消预约按钮
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onCancel(appointment.id),
              child: const Text('取消预约'),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
