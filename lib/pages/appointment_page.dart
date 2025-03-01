import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/appointment_result_view.dart';
import '../components/seat_status_dialog.dart';
import '../components/time_selection_sheet.dart';
import '../services/appointment_service.dart';
import '../utils/date_time_util.dart';
import '../utils/seat_mapping_util.dart';
import '../utils/toast_util.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _seatController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int? _selectedStartIndex;
  int? _selectedEndIndex;
  late List<String> _timeSlots;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _responseMessage = '';
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  Future<void> _initializeComponent() async {
    // 初始化座位映射数据
    await SeatMappingUtil.initialize();

    // 初始化时间槽
    _timeSlots = DateTimeUtil.generateTimeSlots();

    // 初始化默认日期和时间
    final defaultDateTime = DateTimeUtil.initializeDefaultDateTime();
    setState(() {
      _selectedDate = defaultDateTime['selectedDate'];
      _startTime = defaultDateTime['startTime'];
      _endTime = defaultDateTime['endTime'];
    });

    // 计算时间索引
    _updateTimeIndices();
  }

  // 更新时间索引
  void _updateTimeIndices() {
    final startTimeStr = DateTimeUtil.formatTimeOfDay(_startTime);
    final endTimeStr = DateTimeUtil.formatTimeOfDay(_endTime);

    setState(() {
      _selectedStartIndex = _timeSlots.indexOf(startTimeStr);
      _selectedEndIndex = _timeSlots.indexOf(endTimeStr);
    });
  }

  // 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 显示时间选择
  Future<void> _showTimeSelectionSheet(BuildContext context) async {
    await TimeSelectionSheet.show(
      context,
      timeSlots: _timeSlots,
      initialStartIndex: _selectedStartIndex,
      initialEndIndex: _selectedEndIndex,
      onTimeSelected: (startIndex, endIndex) {
        setState(() {
          _selectedStartIndex = startIndex;
          _selectedEndIndex = endIndex;

          // 更新TimeOfDay
          final startParts = _timeSlots[startIndex].split(':');
          final endParts = _timeSlots[endIndex].split(':');

          _startTime = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]),
          );

          _endTime = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]),
          );
        });
      },
    );
  }

  // 提交预约
  Future<void> _submitAppointment() async {
    if (_seatController.text.isEmpty) {
      ToastUtil.show(context, '请输入座位号');
      return;
    }

    final spaceId = SeatMappingUtil.convertSeatNameToId(_seatController.text);
    if (spaceId == null) {
      ToastUtil.show(context, '无效的座位号');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final date = DateTimeUtil.formatDate(_selectedDate);
      final beginTime = DateTimeUtil.formatTimeOfDay(_startTime);
      final endTime = DateTimeUtil.formatTimeOfDay(_endTime);

      final result = await _appointmentService.createAppointment(
        spaceId: spaceId,
        date: date,
        beginTime: beginTime,
        endTime: endTime,
      );

      setState(() {
        _isLoading = false;
        _isSuccess = result['success'];

        if (_isSuccess) {
          _responseMessage =
              '座位号: ${_seatController.text}\n'
              '日期: $date\n'
              '时间: $beginTime - $endTime';
        } else {
          _responseMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _responseMessage = '发生错误，请重试';
      });
      ToastUtil.show(context, '发生错误，请重试');
    }
  }

  // 显示座位状态查询对话框
  void _showSeatStatusDialog() {
    // 获取当前主题的亮度以设置合适的图标颜色
    final brightness = Theme.of(context).brightness;

    // 在显示BottomSheet前，设置系统导航栏为透明
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false, // 禁用系统强制的对比度
        systemNavigationBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 设置为true使BottomSheet背后的内容可见
      enableDrag: true,
      builder: (BuildContext context) {
        return SeatStatusDialog(
          selectedDate: _selectedDate,
          startTime: _startTime,
          endTime: _endTime,
          onSeatSelected: (seatName) {
            setState(() {
              _seatController.text = seatName;
            });

            // BottomSheet关闭后，恢复系统导航栏的样式
            final colorScheme = Theme.of(context).colorScheme;
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                systemNavigationBarColor: colorScheme.surface,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
              ),
            );
          },
        );
      },
    ).then((_) {
      // BottomSheet关闭后，无论如何都要恢复系统导航栏的样式
      final colorScheme = Theme.of(context).colorScheme;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarIconBrightness:
              brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
        ),
      );
    });
  }

  // 重置预约结果状态
  void _resetAppointmentState() {
    setState(() {
      _responseMessage = '';
      _isSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                // 页面标题
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '预约座位',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '选择日期、时间和座位',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // 主体内容
                _isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('处理中，请稍候...'),
                          ],
                        ),
                      ),
                    )
                    : _responseMessage.isNotEmpty
                    ? AppointmentResultView(
                      isSuccess: _isSuccess,
                      message: _responseMessage,
                      onBackPressed: _resetAppointmentState,
                    )
                    : _buildAppointmentForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 时间选择部分
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withAlpha(76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outline.withAlpha(25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '时间选择',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 日期选择器
                ListTile(
                  onTap: () => _selectDate(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outline.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('预约日期'),
                  subtitle: Text(
                    DateTimeUtil.formatDate(_selectedDate),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // 时间选择器
                ListTile(
                  onTap: () => _showTimeSelectionSheet(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tileColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outline.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  leading: Icon(
                    Icons.access_time_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('预约时间段'),
                  subtitle: Text(
                    '${DateTimeUtil.formatTimeOfDay(_startTime)} - ${DateTimeUtil.formatTimeOfDay(_endTime)}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 座位输入部分
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withAlpha(76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outline.withAlpha(25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chair_alt_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '座位信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _seatController,
                  decoration: InputDecoration(
                    labelText: '座位号',
                    hintText: '请输入座位号（如：001）',
                    prefixIcon: Icon(
                      Icons.chair_outlined,
                      color: colorScheme.primary.withAlpha(200),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withAlpha(127),
                        width: 1.5,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showSeatStatusDialog,
                    icon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.primary,
                    ),
                    label: const Text('查询可用座位'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: colorScheme.primary.withAlpha(127),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 36),

        // 提交按钮
        FilledButton.icon(
          onPressed: _submitAppointment,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('提交预约', style: TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _seatController.dispose();
    super.dispose();
  }
}
