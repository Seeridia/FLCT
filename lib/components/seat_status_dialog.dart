import 'package:flutter/material.dart';
import '../../models/seat_model.dart';
import '../../services/appointment_service.dart';
import '../../utils/date_time_util.dart';
import 'stat_card.dart';
import 'seat_chip.dart';

class SeatStatusDialog extends StatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Function(String) onSeatSelected;

  const SeatStatusDialog({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onSeatSelected,
  });

  @override
  State<SeatStatusDialog> createState() => _SeatStatusDialogState();
}

class _SeatStatusDialogState extends State<SeatStatusDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<SeatModel> _seatStatusData = [];
  Map<String, int> _statusSummary = {'total': 0, 'free': 0, 'freeSingle': 0};
  final AppointmentService _appointmentService = AppointmentService();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _querySeatStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _querySeatStatus() async {
    setState(() {
      _isLoading = true;
      _seatStatusData = [];
      _statusSummary = {'total': 0, 'free': 0, 'freeSingle': 0};
    });

    try {
      final date = DateTimeUtil.formatDate(widget.selectedDate);
      final beginTime = DateTimeUtil.formatTimeOfDay(widget.startTime);
      final endTime = DateTimeUtil.formatTimeOfDay(widget.endTime);

      final result = await _appointmentService.queryAllFloorSeats(
        date: date,
        beginTime: beginTime,
        endTime: endTime,
      );

      if (result['success'] && result['data'] != null) {
        final List<SeatModel> seats = result['data'];

        final total = seats.length;
        final free = seats.where((seat) => seat.isFree).length;
        final freeSingle =
            seats.where((seat) => seat.isFree && seat.isSingleSeat).length;

        setState(() {
          _seatStatusData = seats;
          _statusSummary = {
            'total': total,
            'free': free,
            'freeSingle': freeSingle,
          };
        });
        _animationController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('查询失败: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatisticsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: StatCard(
                  icon: Icons.chair_outlined,
                  title: '总座位',
                  value: _statusSummary['total']!.toString(),
                  color: colorScheme.tertiaryContainer,
                  textColor: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: StatCard(
                  icon: Icons.event_seat,
                  title: '空闲座位',
                  value:
                      '${_statusSummary['free']} (${(_statusSummary['free']! / _statusSummary['total']! * 100).toStringAsFixed(0)}%)',
                  color: colorScheme.primaryContainer,
                  textColor: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StatCard(
          icon: Icons.person_outlined,
          title: '空闲单人座位',
          value:
              '${_statusSummary['freeSingle']} (${(_statusSummary['freeSingle']! / _statusSummary['total']! * 100).toStringAsFixed(0)}%)',
          color: colorScheme.secondaryContainer,
          textColor: colorScheme.onSecondaryContainer,
        ),
      ],
    );
  }

  Widget _buildSeatsGrid(ColorScheme colorScheme, TextTheme textTheme, int columnsCount) {
    if (_seatStatusData.where((seat) => seat.isFree).isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            '暂无空闲座位\n（如果你在该时间段已有一个预约则可能无法显示，但仍然可以通过直接输入座位号的方式预约）',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: columnsCount > 0 ? columnsCount : 3,
      childAspectRatio: (100.0 / 40.0),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _seatStatusData
          .where((seat) => seat.isFree)
          .map(
            (seat) => AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: SeatChip(
                    seat: seat,
                    width: 100.0,
                    onSelected: (seatName) {
                      widget.onSeatSelected(seatName);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final chipWidth = 100.0;
    final horizontalPadding = 24.0 * 2;
    final columnsCount =
        ((screenWidth - horizontalPadding) / (chipWidth + 10)).floor();

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              if (scrollController.position.pixels <= 0 &&
                  notification.dragDetails != null) {
                Navigator.of(context).pop();
                return true;
              }
            }
            return false;
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 4,
                    width: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withAlpha(102),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '座位状态查询',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: '关闭',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shrinkWrap: true,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withAlpha(128),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${DateTimeUtil.formatDate(widget.selectedDate)} ${DateTimeUtil.formatTimeOfDay(widget.startTime)}-${DateTimeUtil.formatTimeOfDay(widget.endTime)}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: _querySeatStatus,
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onSecondaryContainer,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                label: Text(_isLoading ? '正在刷新...' : '刷新数据'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading && _seatStatusData.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_seatStatusData.isNotEmpty)
                        FadeTransition(
                          opacity: _animation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildStatisticsSection(colorScheme),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withAlpha(128),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '空闲座位列表',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSeatsGrid(colorScheme, textTheme, columnsCount),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant
                                      .withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无数据，请点击刷新按钮获取座位状态',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 