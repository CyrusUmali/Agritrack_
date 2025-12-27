import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart'; 

class SupportMessagesPage extends LayoutWidget {
  SupportMessagesPage({super.key});

  final ValueNotifier<int> selectedTabNotifier = ValueNotifier(0);
  final ValueNotifier<String?> selectedMessageNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<Message>> receivedMessagesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Message>> sentMessagesNotifier = ValueNotifier([]);
  final TextEditingController replyController = TextEditingController();
  final ValueNotifier<bool> isReplyingNotifier = ValueNotifier(false);

  @override
  String breakTabTitle(BuildContext context) {
    return 'Support Messages';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 600,
            child: _messageListWidget(context),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 600,
            child: _messageDetailWidget(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedMessageNotifier,
        builder: (context, selectedMessage, child) {
          if (selectedMessage != null) {
            return _messageDetailWidget(context);
          }
          return _messageListWidget(context);
        },
      ),
    );
  }


 Future<void> _loadMessages(BuildContext context) async {
  isLoadingNotifier.value = true;
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

  
    
    if (userId == null) {
      throw Exception('User ID not found');
    }

    final sectorService = RepositoryProvider.of<SectorService>(context);
    
    // Fetch inbox messages (received)
    final inboxResponse = await sectorService.fetchInbox(userId: userId);

 
    if (inboxResponse['success'] == true) {
      // Use 'data' instead of 'tickets' - the backend now returns 'data'
      final tickets = inboxResponse['tickets'] as List<dynamic>? ?? [];
 
      
      final receivedMessages = tickets.map((ticket) {
        return Message(
          id: ticket['id']?.toString() ?? '',
          subject: ticket['subject'] ?? 'No Subject',
          from: ticket['from'] ?? 'Unknown Sender',
          date: DateTime.parse(ticket['created_at'] ?? DateTime.now().toString()),
          preview: ticket['preview'] ?? 'No preview available',
          content: ticket['text'] ?? 'No content available', // Make sure this uses 'text' not 'content'
          isRead: ticket['isRead'] ?? false,
          status: ticket['status']?.toString(),
          direction: ticket['direction'] ?? 'received',
        );
      }).toList();
      
      // REMOVE THE FILTERING - show all messages from inbox endpoint
      // The backend should already be filtering appropriately
      receivedMessagesNotifier.value = receivedMessages;
 
    } else {
    
    }

    // Fetch sent messages
    final sentResponse = await sectorService.fetchSentMessages(userId: userId);
    
    if (sentResponse['success'] == true) {
      // Use 'data' instead of 'tickets' for sent messages too
      final sentTickets = sentResponse['data'] as List<dynamic>? ?? [];
   
      
      final sentMessages = sentTickets.map((ticket) {
        return Message(
          id: ticket['id']?.toString() ?? '',
          subject: ticket['subject'] ?? 'No Subject',
          from: ticket['from'] ?? 'You', // Use the from field from backend
          date: DateTime.parse(ticket['created_at'] ?? DateTime.now().toString()),
          preview: ticket['preview'] ?? 'No preview available',
          content: ticket['text'] ?? 'No content available', // Make sure this uses 'text'
          isRead: true, // Sent messages are always read
          status: ticket['status']?.toString() ?? 'sent',
          direction: 'sent',
        );
      }).toList();
      
      sentMessagesNotifier.value = sentMessages;
    
    } else {
     
    }

  } catch (e) {
   
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (context.mounted) {
      isLoadingNotifier.value = false;
    }
  }
}


Future<void> _sendReply(BuildContext context, Message originalMessage) async {
  if (replyController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a reply message'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  isReplyingNotifier.value = true;
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    if (userId == null) {
      throw Exception('User ID not found');
    }

    final sectorService = RepositoryProvider.of<SectorService>(context);
    
    // Send the reply
    final response = await sectorService.sendReply(
      ticketId: originalMessage.id,
      userId: userId,
      message: replyController.text.trim(),
      subject: 'Re: ${originalMessage.subject}',
    );

    if (response['success'] == true) {
      // Clear the reply field
      replyController.clear();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload messages to show the sent reply
      _loadMessages(context);
      
      // Clear selection to refresh the view
      selectedMessageNotifier.value = null;
    } else {
      throw Exception(response['message'] ?? 'Failed to send reply');
    }
  } catch (e) {
 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send reply: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    isReplyingNotifier.value = false;
  }
}



  Widget _messageListWidget(BuildContext context) {
    // Load messages when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (receivedMessagesNotifier.value.isEmpty && !isLoadingNotifier.value) {
        _loadMessages(context);
      }
    });

    return CommonCard(
      child: Column(
        children: [
          // Header with Tabs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mail_outline, color: Colors.blue.shade700, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "Support Messages",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: isLoadingNotifier,
                      builder: (context, isLoading, child) {
                        if (isLoading) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _loadMessages(context),
                          tooltip: 'Refresh messages',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                ValueListenableBuilder<int>(
                  valueListenable: selectedTabNotifier,
                  builder: (context, selectedTab, child) {
                    return Row(
                      children: [
                        _tabButton(
                          "Inbox",
                          Icons.inbox,
                          0,
                          selectedTab,
                          receivedMessagesNotifier.value.where((m) => !m.isRead).length,
                        ),
                        const SizedBox(width: 8),
                        _tabButton(
                          "Sent",
                          Icons.send,
                          1,
                          selectedTab,
                          0,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ValueListenableBuilder<int>(
                  valueListenable: selectedTabNotifier,
                  builder: (context, selectedTab, child) {
                    final messages = selectedTab == 0 
                      ? receivedMessagesNotifier.value 
                      : sentMessagesNotifier.value;
                    
                    if (messages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedTab == 0 ? Icons.inbox_outlined : Icons.send_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedTab == 0 
                                ? "No messages in inbox"
                                : "No sent messages",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedTab == 0
                                ? "Your support messages will appear here"
                                : "Messages you've sent will appear here",
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

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _messageListItem(messages[index], selectedTab == 0);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, int tabIndex, int selectedTab, int unreadCount) {
    final isSelected = selectedTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => selectedTabNotifier.value = tabIndex,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$unreadCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageListItem(Message message, bool isInbox) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedMessageNotifier,
      builder: (context, selectedMessage, child) {
        final isSelected = selectedMessage == message.id;
        return InkWell(
          onTap: () => selectedMessageNotifier.value = message.id,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.shade50
                  : !message.isRead && isInbox
                      ? Colors.grey.shade50
                      : Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
                left: isSelected
                    ? BorderSide(color: Colors.blue.shade700, width: 3)
                    : const BorderSide(color: Colors.transparent, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.subject,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: !message.isRead && isInbox
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isInbox && message.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(message.status!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                message.status!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.from,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.preview,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(message.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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

  Widget _messageDetailWidget(BuildContext context) {
    return CommonCard(
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedMessageNotifier,
        builder: (context, selectedMessageId, child) {
          if (selectedMessageId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Select a message to read",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Find the selected message
          final allMessages = [...receivedMessagesNotifier.value, ...sentMessagesNotifier.value];
          final message = allMessages.firstWhere(
            (m) => m.id == selectedMessageId,
            orElse: () => Message(
              id: '',
              subject: 'Message not found',
              from: 'Unknown',
              date: DateTime.now(),
              preview: '',
              content: 'The selected message could not be found.',
              isRead: true,
            ),
          );

          // Check if this is an inbox message (received message)
          final isInboxMessage = receivedMessagesNotifier.value.any((m) => m.id == message.id);

        
          return Column(
            children: [
              // Message Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Back button for mobile
                        if (MediaQuery.of(context).size.width < 768) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => selectedMessageNotifier.value = null,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            message.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (message.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(message.status!),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              message.status!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            message.from[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.from,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDateFull(message.date),
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

              // Message Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                     
                      // Reply Section - Only show for inbox messages
                      if (isInboxMessage) ...[
                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 20),
                        const Text(
                          'Reply to this message',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: replyController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Type your reply here...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<bool>(
                          valueListenable: isReplyingNotifier,
                          builder: (context, isReplying, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isReplying ? null : () => _sendReply(context, message),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: isReplying
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send, size: 18),
                                          SizedBox(width: 8),
                                          Text('Send Reply'),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your reply will be sent as a response to this support ticket.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green.shade600;
      case 'in progress':
        return Colors.orange.shade600;
      case 'pending':
        return Colors.grey.shade600;
      case 'open':
        return Colors.blue.shade600;
      case 'closed':
        return Colors.grey.shade400;
      default:
        return Colors.blue.shade600;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void dispose() {
    selectedTabNotifier.dispose();
    selectedMessageNotifier.dispose();
    isLoadingNotifier.dispose();
    receivedMessagesNotifier.dispose();
    sentMessagesNotifier.dispose();
    replyController.dispose();
    isReplyingNotifier.dispose(); 
  }
}

 // Message Model
class Message {
  final String id;
  final String subject;
  final String from;
  final DateTime date;
  final String preview;
  final String content;
  final bool isRead;
  final String? status;
  final String direction; // Add this field

  Message({
    required this.id,
    required this.subject,
    required this.from,
    required this.date,
    required this.preview,
    required this.content,
    this.isRead = false,
    this.status,
    this.direction = 'received', // Default to received
  });
}