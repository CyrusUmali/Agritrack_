import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/pages/announcement/announcements_page.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

class AnnouncementListWidget extends StatefulWidget {
  final ValueNotifier<List<Announcement>> announcementsNotifier;
  final ValueNotifier<String?> selectedAnnouncementNotifier;
  final ValueNotifier<bool> showComposeNotifier;
  final List<Farmer> farmers;
  final Function(String)? onDeleteAnnouncement;

  const AnnouncementListWidget({
    super.key,
    required this.announcementsNotifier,
    required this.selectedAnnouncementNotifier,
    required this.showComposeNotifier,
    required this.farmers,
    this.onDeleteAnnouncement,
  });

  @override
  State<AnnouncementListWidget> createState() => _AnnouncementListWidgetState();
}

class _AnnouncementListWidgetState extends State<AnnouncementListWidget> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<Announcement>> _filteredAnnouncementsNotifier = ValueNotifier([]);
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeFilteredAnnouncements();
    
    // Listen to changes in the original announcements list
    widget.announcementsNotifier.addListener(_initializeFilteredAnnouncements);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.announcementsNotifier.removeListener(_initializeFilteredAnnouncements);
    _searchController.dispose();
    _filteredAnnouncementsNotifier.dispose();
    super.dispose();
  }

  void _initializeFilteredAnnouncements() {
   
    _filteredAnnouncementsNotifier.value = List.from(widget.announcementsNotifier.value);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
  
    
    if (query.isEmpty) {
      _isSearching = false;
      _filteredAnnouncementsNotifier.value = List.from(widget.announcementsNotifier.value);
 
    } else {
      _isSearching = true;
      final filtered = widget.announcementsNotifier.value.where((announcement) {
        final matchesTitle = announcement.title.toLowerCase().contains(query);
        final matchesMessage = announcement.message.toLowerCase().contains(query);
        final matchesRecipient = announcement.recipientName.toLowerCase().contains(query);
        final matchesRecipientType = announcement.recipient.toLowerCase().contains(query);
        
        return matchesTitle || matchesMessage || matchesRecipient || matchesRecipientType;
      }).toList();
      
      _filteredAnnouncementsNotifier.value = filtered;
 
    }
  }

  void _clearSearch() {
 
    _searchController.clear();
    _isSearching = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color:Theme.of(context).cardTheme.surfaceTintColor!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Icon Row
                Row(
                  children: [
                    Icon(Icons.campaign, color: FlarelineColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "Announcements",
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
                    border: Border.all(color: Theme.of(context).cardTheme.surfaceTintColor!) ,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search announcements...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Icons.search, size: 20),
                          ),
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
                
                // New Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                   
                      widget.showComposeNotifier.value = true;
                      widget.selectedAnnouncementNotifier.value = null;
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('New Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlarelineColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stats
                Row(
                  children: [
                    _statCard(
                      'Total Sent',
                      widget.announcementsNotifier.value.length.toString(),
                      Icons.send_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      'To Everyone',
                      widget.announcementsNotifier.value
                          .where((a) => a.recipient == 'everyone')
                          .length
                          .toString(),
                      Icons.group_outlined,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    if (_isSearching)
                      _statCard(
                        'Results',
                        _filteredAnnouncementsNotifier.value.length.toString(),
                        Icons.search,
                        Colors.orange,
                      ),
                  ],
                ),
            
            
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: ValueListenableBuilder<List<Announcement>>(
              valueListenable: _filteredAnnouncementsNotifier,
              builder: (context, filteredAnnouncements, child) {
           
                
                if (filteredAnnouncements.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.campaign_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? "No announcements found" : "No announcements yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching 
                              ? "Try different search terms"
                              : "Create your first announcement",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_isSearching)
                          ElevatedButton(
                            onPressed: () {
                    
                              widget.showComposeNotifier.value = true;
                              widget.selectedAnnouncementNotifier.value = null;
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlarelineColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create Announcement'),
                          ),
                        if (_isSearching)
                          ElevatedButton(
                            onPressed: _clearSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear Search'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredAnnouncements.length,
                  itemBuilder: (context, index) {
             
                    return _announcementListItem(filteredAnnouncements[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
                      color: Colors.grey.shade700,
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

Widget _announcementListItem(Announcement announcement) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return ValueListenableBuilder<String?>(
    valueListenable: widget.selectedAnnouncementNotifier,
    builder: (context, selectedAnnouncement, child) {
      final isSelected = selectedAnnouncement == announcement.id;

      // Adaptive colors for selection and badges
      final selectedColor = isDark 
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.primary.withOpacity(0.1);
          
      final borderColor = isSelected ? theme.colorScheme.primary : Colors.transparent;
      
      final recipientBackgroundColor = announcement.recipient == 'everyone'
          ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1))
          : (isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1));
          
      final recipientIconColor = announcement.recipient == 'everyone'
          ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
          : (isDark ? Colors.blue.shade300 : Colors.blue.shade700);
          
 

      return InkWell(
        onTap: () {
     
          widget.selectedAnnouncementNotifier.value = announcement.id;
          widget.showComposeNotifier.value = false;
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
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Recipient badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: recipientBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          announcement.recipient == 'everyone'
                              ? Icons.group
                              : Icons.person,
                          size: 12,
                          color: recipientIconColor,
                        ),
                      
                      ],
                    ),
                  ),
                  // Delete button
                  if (widget.onDeleteAnnouncement != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                          color: isDark ? theme.hintColor : Colors.grey.shade700,
                      ),
                      onPressed: () {
                   
                        widget.onDeleteAnnouncement!(announcement.id);
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete announcement',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'To: ${announcement.recipientName}',
                style: TextStyle(
                  fontSize: 13, 
                  color: isDark ? theme.hintColor : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                announcement.message,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Footer row with date and analytics
              Row(
                children: [
                  Text(
                    _formatDate(announcement.date),
                    style: TextStyle(
                      fontSize: 12,
                       color: isDark ? theme.hintColor : Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
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