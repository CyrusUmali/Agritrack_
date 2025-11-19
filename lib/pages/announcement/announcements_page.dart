import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart'; 
import 'package:flareline/pages/layout.dart';
import 'announcement_list_widget.dart'; 
import 'announcement_detail_widget.dart';
import 'compose_announcement_widget.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/services/api_service.dart'; 

class AnnouncementsPage extends LayoutWidget {
  AnnouncementsPage({super.key});

  final ValueNotifier<int> selectedTabNotifier = ValueNotifier(0);
  final ValueNotifier<String?> selectedAnnouncementNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<Announcement>> announcementsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> showComposeNotifier = ValueNotifier(false);
  
  // Compose form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final ValueNotifier<String> recipientTypeNotifier = ValueNotifier('everyone');
  final ValueNotifier<String?> selectedFarmerNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isSendingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isDeletingNotifier = ValueNotifier(false);

  @override
  String breakTabTitle(BuildContext context) {
    return 'Announcements';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
          create: (_) => FarmerRepository(
            apiService: RepositoryProvider.of<ApiService>(_),
          ),
        ),
        RepositoryProvider(
          create: (_) => SectorService(
            RepositoryProvider.of<ApiService>(_),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FarmerBloc(
              farmerRepository: RepositoryProvider.of<FarmerRepository>(context),
            )..add(LoadFarmers()),
          ),
        ],
        child: BlocBuilder<FarmerBloc, FarmerState>(
          builder: (context, farmerState) {
            // Handle loading state
            if (farmerState is FarmersLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            // Handle error state
            if (farmerState is FarmersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    SizedBox(height: 16),
                    Text('Failed to load farmers: ${farmerState.message}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FarmerBloc>().add(LoadFarmers());
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Get real farmers data
            List<Farmer> realFarmers = [];
            if (farmerState is FarmersLoaded) {
              realFarmers = farmerState.farmers;
            }

            return _buildContent(context, realFarmers);
          },
        ),
      ),
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(
          create: (_) => FarmerRepository(
            apiService: RepositoryProvider.of<ApiService>(_),
          ),
        ),
        RepositoryProvider(
          create: (_) => SectorService(
            RepositoryProvider.of<ApiService>(_),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FarmerBloc(
              farmerRepository: RepositoryProvider.of<FarmerRepository>(context),
            )..add(LoadFarmers()),
          ),
        ],
        child: BlocBuilder<FarmerBloc, FarmerState>(
          builder: (context, farmerState) {
            // Handle loading state
            if (farmerState is FarmersLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            // Handle error state
            if (farmerState is FarmersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    SizedBox(height: 16),
                    Text('Failed to load farmers: ${farmerState.message}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FarmerBloc>().add(LoadFarmers());
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Get real farmers data
            List<Farmer> realFarmers = [];
            if (farmerState is FarmersLoaded) {
              realFarmers = farmerState.farmers;
            }

            return _buildMobileContent(context, realFarmers);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Farmer> farmers) {
    // Load announcements when building content
    _loadAnnouncements(context, farmers);
    
    return ValueListenableBuilder<bool>(
      valueListenable: showComposeNotifier,
      builder: (context, showCompose, child) {
        if (showCompose) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  // height: 200,
                  height:   MediaQuery.of(context).size.height - 200,
                  child: AnnouncementListWidget(
                    announcementsNotifier: announcementsNotifier,
                    selectedAnnouncementNotifier: selectedAnnouncementNotifier,
                    showComposeNotifier: showComposeNotifier,
                    farmers: farmers,
                    onDeleteAnnouncement: (announcementId) => _deleteAnnouncement(context, announcementId),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: SizedBox(
                  // height: 600,
                       height:   MediaQuery.of(context).size.height - 200,
                  child: ComposeAnnouncementWidget(
                    titleController: titleController,
                    messageController: messageController,
                    recipientTypeNotifier: recipientTypeNotifier,
                    selectedFarmerNotifier: selectedFarmerNotifier,
                    isSendingNotifier: isSendingNotifier,
                    showComposeNotifier: showComposeNotifier,
                    farmers: farmers,
                    onSendAnnouncement: () => _sendAnnouncement(context, farmers),
                  ),
                ),
              ),
            ],
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                // height: 600,
                     height:   MediaQuery.of(context).size.height - 200,
                child: AnnouncementListWidget(
                  announcementsNotifier: announcementsNotifier,
                  selectedAnnouncementNotifier: selectedAnnouncementNotifier,
                  showComposeNotifier: showComposeNotifier,
                  farmers: farmers,
                  onDeleteAnnouncement: (announcementId) => _deleteAnnouncement(context, announcementId),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: SizedBox(
                // height: 600,
     height:   MediaQuery.of(context).size.height - 200,
                child: AnnouncementDetailWidget(
                  announcementsNotifier: announcementsNotifier,
                  selectedAnnouncementNotifier: selectedAnnouncementNotifier,
                  onDeleteAnnouncement: (announcementId) => _deleteAnnouncement(context, announcementId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileContent(BuildContext context, List<Farmer> farmers) {
    // Load announcements when building mobile content
    _loadAnnouncements(context , farmers);
    
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ValueListenableBuilder<bool>(
        valueListenable: showComposeNotifier,
        builder: (context, showCompose, child) {
          if (showCompose) {
            return ComposeAnnouncementWidget(
              titleController: titleController,
              messageController: messageController,
              recipientTypeNotifier: recipientTypeNotifier,
              selectedFarmerNotifier: selectedFarmerNotifier,
              isSendingNotifier: isSendingNotifier,
              showComposeNotifier: showComposeNotifier,
              farmers: farmers,
              onSendAnnouncement: () => _sendAnnouncement(context, farmers),
            );
          }
          
          return ValueListenableBuilder<String?>(
            valueListenable: selectedAnnouncementNotifier,
            builder: (context, selectedAnnouncement, child) {
              if (selectedAnnouncement != null) {
                return AnnouncementDetailWidget(
                  announcementsNotifier: announcementsNotifier,
                  selectedAnnouncementNotifier: selectedAnnouncementNotifier,
                  onDeleteAnnouncement: (announcementId) => _deleteAnnouncement(context, announcementId),
                );
              }
              return AnnouncementListWidget(
                announcementsNotifier: announcementsNotifier,
                selectedAnnouncementNotifier: selectedAnnouncementNotifier,
                showComposeNotifier: showComposeNotifier,
                farmers: farmers,
                onDeleteAnnouncement: (announcementId) => _deleteAnnouncement(context, announcementId),
              );
            },
          );
        },
      ),
    );
  }


Future<void> _loadAnnouncements(BuildContext context, List<Farmer> farmers) async {
  if (announcementsNotifier.value.isNotEmpty) return;
  
  isLoadingNotifier.value = true;
  
  try {
    final sectorService = RepositoryProvider.of<SectorService>(context);
    final result = await sectorService.fetchAnnouncements();
    
    if (result['success'] == true) {
      // Handle the API response structure
      List<Announcement> announcements = [];
      
      if (result['data'] is List) {
        // If data is a list, process each item
        final List<dynamic> announcementData = result['data'] ?? [];
        announcements = announcementData.map((data) {
          return _createAnnouncementFromData(data, farmers);
        }).toList();
      } else if (result['data'] != null) {
        // If data is a single object, wrap it in a list
        announcements = [_createAnnouncementFromData(result['data'], farmers)];
      }
      
      announcementsNotifier.value = announcements;
    } else {
      announcementsNotifier.value = [];
      print('Failed to load announcements: ${result['message']}');
    }
  } catch (e) {
    announcementsNotifier.value = [];
    print('Error loading announcements: $e');
    ToastHelper.showErrorToast(
      'Error loading announcements',
      context,
    );
  } finally {
    isLoadingNotifier.value = false;
  }
}

Announcement _createAnnouncementFromData(Map<String, dynamic> data, List<Farmer> farmers) {
  return Announcement(
    id: data['id']?.toString() ?? '',
    title: data['title'] ?? '',
    message: data['message'] ?? '',
    recipient: data['recipient_type'] ?? 'everyone',
    recipientName: _getRecipientName(data, farmers),
    date: _parseDateTime(data['created_at']),
    status: data['status'] ?? 'sent',
    farmerId: data['farmer_id']?.toString(),
    readCount: data['read_count'] ?? 0,
    totalRecipients: data['total_recipients'] ?? 0,
  );
}

DateTime _parseDateTime(dynamic dateString) {
  try {
    if (dateString == null) return DateTime.now();
    return DateTime.parse(dateString.toString());
  } catch (e) {
    return DateTime.now();
  }
}

String _getRecipientName(Map<String, dynamic> data, List<Farmer> farmers) {
  final recipientType = data['recipient_type'] ?? 'everyone';
  
  if (recipientType == 'everyone') {
    return 'All Farmers';
  } else if (recipientType == 'specific') {
    final farmerId = data['farmer_id']?.toString();
    if (farmerId != null) {
      try {
        final farmer = farmers.firstWhere(
          (f) => f.id.toString() == farmerId,
        );
        return farmer.name;
      } catch (e) {
        return 'Farmer ID: $farmerId';
      }
    }
  }
  
  return 'Unknown Recipient';
}



Future<void> _sendAnnouncement(BuildContext context, List<Farmer> farmers) async {
  if (titleController.text.trim().isEmpty) {
    ToastHelper.showInfoToast(
      'Please enter a title',
      context,
    );
    return; 
  }

  if (messageController.text.trim().isEmpty) {
    ToastHelper.showInfoToast(
      'Please enter a message',
      context,
    );
    return;
  }

  if (recipientTypeNotifier.value == 'specific' && selectedFarmerNotifier.value == null) {
    ToastHelper.showInfoToast(
      'Please select a Farmer',
      context,
    );
    return;
  }

  isSendingNotifier.value = true;

  try {
    print('Sending announcement...');
    print('Title: ${titleController.text.trim()}');
    print('Message: ${messageController.text.trim()}');
    print('Recipient Type: ${recipientTypeNotifier.value}');
    print('Farmer ID: ${selectedFarmerNotifier.value}');

    final sectorService = RepositoryProvider.of<SectorService>(context);
    
    final result = await sectorService.sendAnnouncement(
      title: titleController.text.trim(),
      message: messageController.text.trim(),
      recipientType: recipientTypeNotifier.value,
      farmerId: recipientTypeNotifier.value == 'specific' ? selectedFarmerNotifier.value : null,
    );

    print('Send announcement result: $result');

    if (result['success'] == true) {
      print('Announcement sent successfully, reloading...');
      // Reload announcements to get the latest from server
      await _loadAnnouncements(context, farmers);

      // Clear form
      titleController.clear();
      messageController.clear();
      recipientTypeNotifier.value = 'everyone';
      selectedFarmerNotifier.value = null;

      showComposeNotifier.value = false;

      ToastHelper.showSuccessToast(
        'Announcement sent successfully',
        context,
      );
    } else {
      print('Send announcement failed: ${result['message']}');
      ToastHelper.showErrorToast(
        'Failed to send announcement: ${result['message']}',
        context,
      );
    }
  } catch (e, stackTrace) {
    print('Exception caught in _sendAnnouncement: $e');
    print('Stack trace: $stackTrace');
    ToastHelper.showErrorToast(
      'Failed to send announcement: $e',
      context,
    );
  } finally {
    isSendingNotifier.value = false;
  }
}




Future<void> _deleteAnnouncement(BuildContext context, String announcementId) async {
  ModalDialog.show(
    context: context,
    title: 'Delete Announcement',
    showTitle: true,
    showTitleDivider: true,
    modalType: ModalType.medium,
    onCancelTap: () => Navigator.of(context).pop(),
    onSaveTap: () async {
      await _performDelete(context, announcementId);
      Navigator.of(context).pop();
    },
    child: Center(
      child: Text('Are you sure you want to delete this announcement?'),
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
                  await _performDelete(context, announcementId);
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




Future<void> _performDelete(BuildContext context, String announcementId) async {
  isDeletingNotifier.value = true;

  try {
    final sectorService = RepositoryProvider.of<SectorService>(context);
    final result = await sectorService.deleteAnnouncement(announcementId);

    if (result['success'] == true) {
      // Create a new list instance to ensure proper notification
      final updatedAnnouncements = announcementsNotifier.value
          .where((announcement) => announcement.id != announcementId)
          .toList();
      
      // This will trigger ValueListenableBuilder to rebuild
      announcementsNotifier.value = updatedAnnouncements;

      // Clear selection if deleted announcement was selected
      if (selectedAnnouncementNotifier.value == announcementId) {
        selectedAnnouncementNotifier.value = null;
      }

      ToastHelper.showSuccessToast(
        'Announcement deleted successfully',
        context,
      );
    } else {
      ToastHelper.showErrorToast(
        'Failed to delete announcement',
        context,
      );
    }
  } catch (e) {
    ToastHelper.showErrorToast(
      'Deletion Failed',
      context,
    );
  } finally {
    isDeletingNotifier.value = false;
  }
}



  @override
  void dispose() {
    selectedAnnouncementNotifier.dispose();
    isLoadingNotifier.dispose();
    announcementsNotifier.dispose();
    showComposeNotifier.dispose();
    titleController.dispose();
    messageController.dispose();
    recipientTypeNotifier.dispose();
    selectedFarmerNotifier.dispose();
    isSendingNotifier.dispose();
    isDeletingNotifier.dispose();
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String recipient;
  final String recipientName;
  final DateTime date;
  final String status;
  final String? farmerId;
  final int readCount;
  final int totalRecipients;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.recipient,
    required this.recipientName,
    required this.date,
    required this.status,
    this.farmerId,
    this.readCount = 0,
    this.totalRecipients = 0,
  });
}