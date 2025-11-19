 
import 'package:flareline/pages/announcement/announcements_page.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart'; 

class AnnouncementDetailWidget extends StatelessWidget {
  final ValueNotifier<List<Announcement>> announcementsNotifier;
  final ValueNotifier<String?> selectedAnnouncementNotifier;
  final Function(String)? onDeleteAnnouncement;

  const AnnouncementDetailWidget({
    super.key,
    required this.announcementsNotifier,
    required this.selectedAnnouncementNotifier,
    this.onDeleteAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedAnnouncementNotifier,
        builder: (context, selectedAnnouncementId, child) {
          if (selectedAnnouncementId == null) {
            return _buildEmptyState();
          }

          final announcement = announcementsNotifier.value.firstWhere(
            (a) => a.id == selectedAnnouncementId,
          );

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color:Theme.of(context).cardTheme.surfaceTintColor!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (MediaQuery.of(context).size.width < 768) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => selectedAnnouncementNotifier.value = null,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  
                  
                     
                    
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: announcement.recipient == 'everyone'
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            announcement.recipient == 'everyone'
                                ? Icons.group
                                : Icons.person,
                            color: announcement.recipient == 'everyone'
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.recipientName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDateFull(announcement.date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 
  String _formatDateFull(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }




 Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Select an announcement",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose an announcement from the list to view details",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}