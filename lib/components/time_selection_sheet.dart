import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/toast_util.dart';

class TimeSelectionSheet extends StatefulWidget {
  final List<String> timeSlots;
  final int? initialStartIndex;
  final int? initialEndIndex;
  final Function(int startIndex, int endIndex) onTimeSelected;

  const TimeSelectionSheet({
    super.key,
    required this.timeSlots,
    this.initialStartIndex,
    this.initialEndIndex,
    required this.onTimeSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> timeSlots,
    int? initialStartIndex,
    int? initialEndIndex,
    required Function(int startIndex, int endIndex) onTimeSelected,
  }) async {
    final brightness = Theme.of(context).brightness;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // 设置为true使BottomSheet背后的内容可见
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      // BottomSheet四周都有圆角
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (BuildContext context) {
        return TimeSelectionSheet(
          timeSlots: timeSlots,
          initialStartIndex: initialStartIndex,
          initialEndIndex: initialEndIndex,
          onTimeSelected: onTimeSelected,
        );
      },
    );

    // BottomSheet关闭后，恢复系统导航栏的样式
    final colorScheme = Theme.of(context).colorScheme;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );

    // 如果用户取消选择，不做任何处理
    if (result != true) return;
  }

  @override
  State<TimeSelectionSheet> createState() => _TimeSelectionSheetState();
}

class _TimeSelectionSheetState extends State<TimeSelectionSheet> {
  late int? _tempStartIndex;
  late int? _tempEndIndex;

  @override
  void initState() {
    super.initState();
    _tempStartIndex = widget.initialStartIndex;
    _tempEndIndex = widget.initialEndIndex;
  }

  bool _isTimeRangeValid(int? startIndex, int? endIndex) {
    if (startIndex == null || endIndex == null) return true;
    // 限制最大时长为4.5小时（9个时间槽）
    final timeDifference = (endIndex - startIndex) * 30;
    return timeDifference <= 270;
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的亮度，用于确定文本颜色
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _tempStartIndex == null ? '选择开始时间' : '选择结束时间',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.all(8),
              childAspectRatio: 1.5,
              children: List.generate(widget.timeSlots.length, (index) {
                final bool isStartSelected = index == _tempStartIndex;
                final bool isEndSelected = index == _tempEndIndex;
                final bool isInRange =
                    _tempStartIndex != null &&
                    _tempEndIndex != null &&
                    index > (_tempStartIndex ?? -1) &&
                    index < (_tempEndIndex ?? -1);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_tempStartIndex == null) {
                        // 第一次点击，设置开始时间
                        _tempStartIndex = index;
                        _tempEndIndex = index;
                      } else if (_tempStartIndex != null &&
                          _tempEndIndex != null) {
                        // 如果点击了已选中的范围内，则清除选择
                        if (index >= (_tempStartIndex ?? -1) &&
                            index <= (_tempEndIndex ?? -1)) {
                          _tempStartIndex = null;
                          _tempEndIndex = null;
                        } else {
                          // 否则选择新的范围
                          int newStartIndex = _tempStartIndex ?? -1;
                          int newEndIndex = _tempEndIndex ?? -1;

                          if (index < (_tempStartIndex ?? -1)) {
                            newStartIndex = index;
                          } else {
                            newEndIndex = index;
                          }

                          if (!_isTimeRangeValid(newStartIndex, newEndIndex)) {
                            ToastUtil.show(context, '预约时间不能超过4.5小时');
                            return;
                          }

                          _tempStartIndex = newStartIndex;
                          _tempEndIndex = newEndIndex;
                        }
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isStartSelected || isEndSelected
                              ? Theme.of(context).colorScheme.primary
                              : isInRange
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(77)
                              : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.timeSlots[index],
                      style: TextStyle(
                        // 在深色模式下，无论是否选中，文字颜色都为白色
                        // 在浅色模式下，根据是否选中决定文字颜色
                        color:
                            brightness == Brightness.dark
                                ? Colors.white
                                : (isStartSelected || isEndSelected || isInRange
                                    ? Colors.white
                                    : Colors.black),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed:
                    _tempStartIndex != null && _tempEndIndex != null
                        ? () {
                          widget.onTimeSelected(
                            _tempStartIndex!,
                            _tempEndIndex!,
                          );
                          Navigator.pop(context, true);
                        }
                        : null,
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
