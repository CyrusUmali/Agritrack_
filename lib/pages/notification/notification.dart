import 'package:flareline/pages/announcement/announcements_page.dart';
import 'package:flareline/pages/notification/NotificationDetailWidget.dart';
import 'package:flareline/pages/notification/NotificationListWidget.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart'; 
import 'package:flareline/pages/layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/services/api_service.dart'; 

class NotificationsPage extends LayoutWidget {
  final int farmerId;

  NotificationsPage({super.key, required this.farmerId});

  final ValueNotifier<String?> selectedNotificationNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<Announcement>> notificationsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isDeletingNotifier = ValueNotifier(false);

  @override
  String breakTabTitle(BuildContext context) {
    return 'Notifications';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
          create: (_) => SectorService(
            RepositoryProvider.of<ApiService>(_),
          ),
        ),
      ],
      child: _buildContent(context),
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
          create: (_) => SectorService(
            RepositoryProvider.of<ApiService>(_),
          ),
        ),
      ],
      child: _buildMobileContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Load notifications when building content
    _loadNotifications(context);
    
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return _buildLoadingWidget();
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: NotificationListWidget(
                  notificationsNotifier: notificationsNotifier,
                  selectedNotificationNotifier: selectedNotificationNotifier,
                  onDeleteNotification: (notificationId) => _deleteNotification(context, notificationId),
                  isLoadingNotifier: isLoadingNotifier,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: NotificationDetailWidget(
                  notificationsNotifier: notificationsNotifier,
                  selectedNotificationNotifier: selectedNotificationNotifier,
                  onDeleteNotification: (notificationId) => _deleteNotification(context, notificationId ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    // Load notifications when building mobile content
    _loadNotifications(context);
    
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return _buildLoadingWidget();
        }
        
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ValueListenableBuilder<String?>(
            valueListenable: selectedNotificationNotifier,
            builder: (context, selectedNotification, child) {
              if (selectedNotification != null) {
                return NotificationDetailWidget(
                  notificationsNotifier: notificationsNotifier,
                  selectedNotificationNotifier: selectedNotificationNotifier,
                  onDeleteNotification: (notificationId) => _deleteNotification(context, notificationId),
                );
              }
              return NotificationListWidget(
                notificationsNotifier: notificationsNotifier,
                selectedNotificationNotifier: selectedNotificationNotifier,
                onDeleteNotification: (notificationId) => _deleteNotification(context, notificationId ),
                isLoadingNotifier: isLoadingNotifier,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FlarelineColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotifications(BuildContext context) async {
    if (notificationsNotifier.value.isNotEmpty) return; // Prevent reloading if already loaded
    
    isLoadingNotifier.value = true;
    
    try {
      final sectorService = RepositoryProvider.of<SectorService>(context);
      final result = await sectorService.fetchFarmerAnnouncements(farmerId);
      
      if (result['success'] == true) {
        final List<dynamic> notificationData = result['data'] ?? [];
        final List<Announcement> notifications = notificationData.map((data) {
          return Announcement(
            id: data['id'].toString(),
            title: data['announcement_title'] ?? '',
            message: data['announcement_content'] ?? '',
            recipient: data['recipient_type'] ?? 'everyone',
            recipientName: 'Admin', // Always from Admin for farmer notifications
            date: DateTime.parse(data['created_at'] ?? DateTime.now().toString()),
            status: data['status'] ?? 'sent',
            farmerId: data['farmer_id']?.toString(),
            readCount: data['read_count'] ?? 0,
            totalRecipients: data['total_recipients'] ?? 0,
          );
        }).toList();

        print(notifications.map((n) => n.message).toList());
        
        notificationsNotifier.value = notifications;
      } else {
        notificationsNotifier.value = [];
        print('Failed to load notifications: ${result['message']}');
      }
    } catch (e) {
      notificationsNotifier.value = [];
      print('Error loading notifications: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> _deleteNotification(BuildContext context, String notificationId) async {
    ModalDialog.show(
      context: context,
      title: 'Delete Notification',
      showTitle: true,
      showTitleDivider: true,
      modalType: ModalType.medium,
      onCancelTap: () => Navigator.of(context).pop(),
      onSaveTap: () async {
        await _performDelete(context, notificationId);
        Navigator.of(context).pop();
      },
      child: const Center(
        child: Text('Are you sure you want to delete this notification?'),
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: 'Cancel',
                  textColor: FlarelineColors.darkBlackText,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                child: ButtonWidget(
                  btnText: 'Delete',
                  onTap: () async {
                    await _performDelete(context, notificationId);
                    Navigator.of(context).pop();
                  },
                  type: ButtonType.primary.type,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, String notificationId) async {
    isDeletingNotifier.value = true;

    try {
      final sectorService = RepositoryProvider.of<SectorService>(context);
      
      // Convert notificationId to int if your API expects int
      final int notificationIdInt = int.parse(notificationId);
      
      final result = await sectorService.deleteFarmerNotification(
        notificationIdInt, // Now passing int
        farmerId,
      );

      if (result['success'] == true) {
        // Remove from local list
        notificationsNotifier.value = notificationsNotifier.value
            .where((notification) => notification.id != notificationId)
            .toList();

        // Clear selection if deleted notification was selected
        if (selectedNotificationNotifier.value == notificationId) {
          selectedNotificationNotifier.value = null;
        }

        ToastHelper.showSuccessToast(
          'Notification deleted successfully',
          context,
        );
      } else {
        ToastHelper.showErrorToast(
          'Notification deletion failed',
          context,
        );
      }
    } catch (e) { 
      ToastHelper.showErrorToast(
        'Notification deletion failed',
        context,
      );
    } finally {
      isDeletingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    selectedNotificationNotifier.dispose();
    isLoadingNotifier.dispose();
    notificationsNotifier.dispose();
    isDeletingNotifier.dispose(); 
  }
}