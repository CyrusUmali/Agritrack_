import 'package:flareline/pages/announcement/announcements_page.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationListWidget extends StatefulWidget {
  final ValueNotifier<List<Announcement>> notificationsNotifier;
  final ValueNotifier<String?> selectedNotificationNotifier;
  final ValueNotifier<bool>? isLoadingNotifier;
  final Function(String)? onDeleteNotification;

  const NotificationListWidget({
    super.key, 
    required this.notificationsNotifier,
    required this.selectedNotificationNotifier,
    this.isLoadingNotifier,
    this.onDeleteNotification,
  });

  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends State<NotificationListWidget> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<Announcement>> _filteredNotificationsNotifier = ValueNotifier([]);
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeFilteredNotifications();
    
    // Listen to changes in the original notifications list
    widget.notificationsNotifier.addListener(_initializeFilteredNotifications);
    _searchController.addListener(_onSearchChanged);
  }






void _markAsRead(BuildContext context, String notificationId) {
  // Find the notification in the list
  final notificationIndex = widget.notificationsNotifier.value
      .indexWhere((n) => n.id == notificationId);
  
  if (notificationIndex != -1) {
    final notification = widget.notificationsNotifier.value[notificationIndex];
    
    // Update local state immediately for better UX
    final updatedNotification = Announcement(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      recipient: notification.recipient,
      recipientName: notification.recipientName,
      date: notification.date,
      status: 'read', // Update status to 'read'
      farmerId: notification.farmerId,
      readCount: notification.readCount,
      totalRecipients: notification.totalRecipients,
    );
    
    final updatedList = List<Announcement>.from(widget.notificationsNotifier.value);
    updatedList[notificationIndex] = updatedNotification;
    widget.notificationsNotifier.value = updatedList;
    
    // Call API to mark as read
    _callMarkAsReadApi(context, notificationId);
  }
}

Future<void> _callMarkAsReadApi(BuildContext context, String notificationId) async {
  try {
    final sectorService = RepositoryProvider.of<SectorService>(context);
    final int notificationIdInt = int.parse(notificationId);
    
    await sectorService.markNotificationAsRead(notificationIdInt);
     
  } catch (e) {
    // Revert local state if API call fails
    final notificationIndex = widget.notificationsNotifier.value
        .indexWhere((n) => n.id == notificationId);
    
    if (notificationIndex != -1) {
      final notification = widget.notificationsNotifier.value[notificationIndex];
      final revertedNotification = Announcement(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        recipient: notification.recipient,
        recipientName: notification.recipientName,
        date: notification.date,
        status: 'unread', // Revert to unread
        farmerId: notification.farmerId,
        readCount: notification.readCount,
        totalRecipients: notification.totalRecipients,
      );
      
      final updatedList = List<Announcement>.from(widget.notificationsNotifier.value);
      updatedList[notificationIndex] = revertedNotification;
      widget.notificationsNotifier.value = updatedList;
    }
  }
}


 
 
  @override
  void dispose() {
    widget.notificationsNotifier.removeListener(_initializeFilteredNotifications);
    _searchController.dispose();
    _filteredNotificationsNotifier.dispose();
    super.dispose();
  }

  void _initializeFilteredNotifications() {
    _filteredNotificationsNotifier.value = List.from(widget.notificationsNotifier.value);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      _isSearching = false;
      _filteredNotificationsNotifier.value = List.from(widget.notificationsNotifier.value);
    } else {
      _isSearching = true;
      final filtered = widget.notificationsNotifier.value.where((notification) {
        final matchesTitle = notification.title.toLowerCase().contains(query);
        final matchesMessage = notification.message.toLowerCase().contains(query);
        final matchesRecipient = notification.recipientName.toLowerCase().contains(query);
        final matchesRecipientType = notification.recipient.toLowerCase().contains(query);
        
        return matchesTitle || matchesMessage || matchesRecipient || matchesRecipientType;
      }).toList();
      
      _filteredNotificationsNotifier.value = filtered;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _isSearching = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 
    
    return CommonCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Icon Row
                Row(
                  children: [
                    Icon(Icons.notifications, color: FlarelineColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "My Notifications",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // Search Bar
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).cardTheme.surfaceTintColor!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search notifications...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Icons.search, size: 20),
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onChanged: (value) {
                            setState(() {
                              _isSearching = value.isNotEmpty;
                            });
                          },
                        ),
                      ),
                      if (_isSearching)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearSearch,
                          padding: const EdgeInsets.all(8),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stats
                ValueListenableBuilder<List<Announcement>>(
                  valueListenable: _filteredNotificationsNotifier,
                  builder: (context, filteredNotifications, child) {
                    return Row(
                      children: [
                        _statCard(
                          'Total',
                          widget.notificationsNotifier.value.length.toString(),
                          Icons.notifications_outlined,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                       _statCard(
  'Unread',
  widget.notificationsNotifier.value
      .where((n) => n.status.toLowerCase() == 'unread') // Use status field
      .length
      .toString(),
  Icons.mark_email_unread_outlined,
  Colors.orange,
),
                        const SizedBox(width: 12),
                        if (_isSearching)
                          _statCard(
                            'Results',
                            _filteredNotificationsNotifier.value.length.toString(),
                            Icons.search,
                            Colors.orange,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Notifications List with Loading State
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.isLoadingNotifier ?? ValueNotifier(false),
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return _buildLoadingState(context);
                }
                
                return ValueListenableBuilder<List<Announcement>>(
                  valueListenable: _filteredNotificationsNotifier,
                  builder: (context, filteredNotifications, child) {
                    if (filteredNotifications.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return _buildNotificationsList(filteredNotifications, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FlarelineColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading notifications...",
            style: TextStyle(
              fontSize: 16,
               color:   theme.hintColor  ,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
 
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16), 
          Text(
            _isSearching ?   context.translate('No notifications found')   :  context.translate('No notifications') ,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching 
                ?   context.translate('Try different search terms')
                :    context.translate('You dont have any notifications yet')   ,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child:  Text(context.translate('Clear Search'))   ,
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Announcement> notifications, BuildContext context) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _notificationListItem(notifications[index], context);
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
 
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color, 
                      
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color:  Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }






Widget _notificationListItem(Announcement notification, BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return ValueListenableBuilder<String?>(
    valueListenable: widget.selectedNotificationNotifier,
    builder: (context, selectedNotification, child) {
      final isSelected = selectedNotification == notification.id;
      
      // Adaptive colors for selection and badges
      final selectedColor = isDark 
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.primary.withOpacity(0.1);
          
      final borderColor = isSelected ? theme.colorScheme.primary : Colors.transparent;
      
 
      
      return InkWell(
        onTap: () {
          widget.selectedNotificationNotifier.value = notification.id;
          // Mark as read when tapped if it's unread
          if (!notification.isRead) {
            _markAsRead(context, notification.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : null,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
              left: BorderSide(color: borderColor, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title, recipient badge, and delete button
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Unread indicator
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: FlarelineColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: notification.isRead 
                                  ? (isDark ? theme.hintColor : Colors.grey.shade700)
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                const SizedBox(width: 8),
               
                  // Delete button
                  if (widget.onDeleteNotification != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: isDark ? theme.hintColor : Colors.grey.shade700,
                      ),
                      onPressed: () {
                        widget.onDeleteNotification!(notification.id);
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete notification',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'From: Admin',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? theme.hintColor : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? theme.hintColor : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Footer row with date
              Row(
                children: [
                  Text(
                    _formatDate(notification.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? theme.hintColor : Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  if (notification.isRead)
                    Text(
                      'Read',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}






  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date.day}/${date.month}/${date.year}";
  }
}