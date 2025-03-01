import 'package:flutter/material.dart';
import '../../models/seat_model.dart';

class SeatChip extends StatelessWidget {
  final SeatModel seat;
  final double width;
  final Function(String) onSelected;

  const SeatChip({
    super.key,
    required this.seat,
    required this.width,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSingleSeat = seat.isSingleSeat;

    return SizedBox(
      width: width,
      child: ActionChip(
        avatar: Icon(
          isSingleSeat ? Icons.person_outline : Icons.people_outline,
          size: 18,
          color: isSingleSeat
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        label: Text(
          seat.spaceName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSingleSeat
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        backgroundColor: isSingleSeat
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        side: BorderSide.none,
        elevation: 0,
        onPressed: () => onSelected(seat.spaceName),
      ),
    );
  }
} 