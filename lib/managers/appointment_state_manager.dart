import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AppointmentStateManager {
  final List<Appointment> appointments = [];

  // 选项卡缓存
  final Map<int, List<Appointment>> appointmentsCache = {};
  final Map<int, int> currentPageCache = {};
  final Map<int, bool> hasMoreCache = {};

  // 状态变量
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 30;

  // 当前选中的选项卡和状态
  int currentTabIndex = 0;
  String? currentAuditStatus;

  // 审核状态值对应表
  static const List<String?> auditStatusValues = [null, '2', '4', '3'];

  // 初始化
  void init(int tabIndex) {
    currentTabIndex = tabIndex;
    currentAuditStatus = auditStatusValues[tabIndex];

    // 检查是否有缓存
    if (appointmentsCache.containsKey(tabIndex)) {
      appointments.clear();
      appointments.addAll(appointmentsCache[tabIndex]!);
      currentPage = currentPageCache[tabIndex]!;
      hasMore = hasMoreCache[tabIndex]!;
    } else {
      resetState();
    }
  }

  // 切换选项卡
  void changeTab(int tabIndex) {
    if (tabIndex == currentTabIndex) return;

    currentTabIndex = tabIndex;
    currentAuditStatus = auditStatusValues[tabIndex];

    // 检查是否有缓存
    if (appointmentsCache.containsKey(tabIndex)) {
      appointments.clear();
      appointments.addAll(appointmentsCache[tabIndex]!);
      currentPage = currentPageCache[tabIndex]!;
      hasMore = hasMoreCache[tabIndex]!;
    } else {
      resetState();
    }
  }

  // 重置状态
  void resetState() {
    appointments.clear();
    currentPage = 1;
    hasMore = true;

    // 清除当前选项卡的缓存
    appointmentsCache.remove(currentTabIndex);
    currentPageCache.remove(currentTabIndex);
    hasMoreCache.remove(currentTabIndex);
  }

  // 加载预约记录
  Future<void> loadAppointments(VoidCallback onStateChanged) async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    onStateChanged();

    try {
      final data = await ApiService.fetchAppointments(
        currentPage: currentPage,
        pageSize: pageSize,
        auditStatus: currentAuditStatus,
      );

      final List<dynamic> newAppointments = data['dataList'] ?? [];
      final total = data['total'] ?? 0;

      final appointmentList =
          newAppointments.map((json) => Appointment.fromJson(json)).toList();

      appointments.addAll(appointmentList);
      hasMore = appointments.length < total;
      currentPage++;

      // 更新缓存
      appointmentsCache[currentTabIndex] = List.from(appointments);
      currentPageCache[currentTabIndex] = currentPage;
      hasMoreCache[currentTabIndex] = hasMore;
    } finally {
      isLoading = false;
      onStateChanged();
    }
  }

  // 处理签到操作
  Future<String> handleSignIn(String appointmentId) async {
    try {
      final result = await ApiService.signIn(appointmentId);
      return result['msg'] ?? '签到成功';
    } catch (e) {
      return e.toString();
    }
  }

  // 处理签退操作
  Future<String> handleSignOut(String appointmentId) async {
    try {
      final result = await ApiService.signOut(appointmentId);
      return result['msg'] ?? '签退成功';
    } catch (e) {
      return e.toString();
    }
  }

  // 处理取消预约操作
  Future<String> handleCancel(String appointmentId) async {
    try {
      final result = await ApiService.cancelAppointment(appointmentId);
      return result['msg'] ?? '取消预约成功';
    } catch (e) {
      return e.toString();
    }
  }
}
