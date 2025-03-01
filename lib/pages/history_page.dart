import 'package:flutter/material.dart';
import '../components/appointment_card.dart';
import '../managers/appointment_state_manager.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _stateManager = AppointmentStateManager();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  final List<({IconData icon, String text})> _tabs = const [
    (icon: Icons.list_alt_rounded, text: '全部'),
    (icon: Icons.login_rounded, text: '可签到'),
    (icon: Icons.task_alt_rounded, text: '已完成'),
    (icon: Icons.cancel_rounded, text: '已取消'),
  ];

  @override
  void initState() {
    super.initState();
    _stateManager.init(0);
    _loadAppointments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_stateManager.isLoading && _stateManager.hasMore) {
        _loadAppointments();
      }
    }
  }

  Future<void> _loadAppointments() async {
    await _stateManager.loadAppointments(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onRefresh() async {
    _stateManager.resetState();
    await _loadAppointments();
  }

  Future<void> _showSnackBar(String message) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: MediaQuery.of(context).size.width * 0.9,
          content: Text(message),
          showCloseIcon: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleSignIn(String appointmentId) async {
    try {
      final message = await _stateManager.handleSignIn(appointmentId);
      await _showSnackBar(message);
      await _onRefresh();
    } catch (e) {
      await _showSnackBar(e.toString());
    }
  }

  Future<void> _handleSignOut(String appointmentId) async {
    try {
      final message = await _stateManager.handleSignOut(appointmentId);
      await _showSnackBar(message);
      await _onRefresh();
    } catch (e) {
      await _showSnackBar(e.toString());
    }
  }

  Future<void> _handleCancel(String appointmentId) async {
    try {
      final message = await _stateManager.handleCancel(appointmentId);
      await _showSnackBar(message);
      await _onRefresh();
    } catch (e) {
      await _showSnackBar(e.toString());
    }
  }

  void _changeTab(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _stateManager.changeTab(index);

      if (_stateManager.appointments.isEmpty && !_stateManager.isLoading) {
        _loadAppointments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(76),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(
              _tabs.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () => _changeTab(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _selectedIndex == index
                              ? colorScheme.primary
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabs[index].icon,
                          color:
                              _selectedIndex == index
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabs[index].text,
                          style: TextStyle(
                            color:
                                _selectedIndex == index
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: _onRefresh,
            child: _buildAppointmentList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentList() {
    if (_stateManager.appointments.isEmpty && !_stateManager.isLoading) {
      return _buildEmptyView();
    } else {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ListView.builder(
          key: ValueKey<int>(_stateManager.appointments.length),
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: 8,
            bottom: kBottomNavigationBarHeight + 24,
            left: 16,
            right: 16,
          ),
          itemCount:
              _stateManager.appointments.length +
              (_stateManager.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _stateManager.appointments.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final appointment = _stateManager.appointments[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: AppointmentCard(
                  appointment: appointment,
                  onSignIn: _handleSignIn,
                  onSignOut: _handleSignOut,
                  onCancel: _handleCancel,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildEmptyView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: colorScheme.primary.withAlpha(178),
          ),
          const SizedBox(height: 20),
          Text(
            '暂无预约记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withAlpha(204),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('刷新'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}