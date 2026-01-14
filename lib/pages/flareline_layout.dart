library flareline_uikit;

import 'package:flareline/breaktab.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/toolbar.dart';
import 'package:flareline/pages/users/privacy_modal.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flareline_uikit/components/sidebar/side_bar.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flareline_uikit/service/sidebar_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 

abstract class FlarelineLayoutWidget extends StatelessWidget {
  const FlarelineLayoutWidget({super.key});

  // Add properties for terms modal control
  bool get showTermsOnStartup => true;
  bool get shouldShowWelcomeModal => false;
  
  // Existing properties
  String get appName => 'AgriTrack';
  bool get showTitle => true;
  bool get isAlignCenter => false;
  bool get showSideBar => true;
  bool get showCurrentRouteInBreadcrumb => true;
  bool showToolBar(BuildContext context) => true;
  bool get showDrawer => false;
  bool get isContentScroll => true;
  double get logoFontSize => 30;
  Color get sideBarDarkColor => FlarelineColors.darkBackground;
  Color get sideBarLightColor => Colors.white;
  double get sideBarWidth => 240;
  double get sideBarCollapsedWidth => 100;
  bool get isSidebarCollapsible => true;
  bool get showBreadcrumbsOnlyOnDesktop => false;

  String sideBarAsset(BuildContext context) =>
      'assets/routes/menu_route_en.json';

  bool isDarkTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  EdgeInsetsGeometry? get customPadding => null;
  EdgeInsetsGeometry? get padding =>
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  String? get logoImageAsset => null;

  Widget? logoWidget(BuildContext context) {
    final sidebarProvider =
        Provider.of<SidebarProvider>(context, listen: false);
    bool isDark = isDarkTheme(context);

    Widget buildLogo() {



// Only show in debug mode
// if (kDebugMode) {
//   return FloatingActionButton(
//     onPressed: () async {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       print('SharedPreferences cleared!');
//     },
//     child: const Icon(Icons.delete),
//     mini: true,
//     backgroundColor: Colors.red,
//   );
// }


      if (logoImageAsset != null) {
        if (logoImageAsset!.endsWith('svg')) {
          return SvgPicture.asset(
            logoImageAsset!,
            height: 32,
          );
        }
        return Image.asset(
          logoImageAsset!,
          width: 32,
          height: 32,
        );
      }
      return SvgPicture.asset(
        'assets/logo/logo_${isDark ? 'white' : 'dark'}.svg',
        height: 32,
      );
    }

    return _HoverableLogo(
      onTap: () => sidebarProvider.togglePin(),
      child: buildLogo(),
    );
  }

  Widget? footerWidget(BuildContext context) {
    return null;
  }

  Widget? toolbarWidget(BuildContext context, bool showDrawer) {
    return null;
  }

  Widget? breakTabRightWidget(BuildContext context) {
    return null;
  }

  String breakTabTitle(BuildContext context) {
    return '';
  }

  List<BreadcrumbItem>? breakTabBreadcrumbs(BuildContext context) {
    return null;
  }

  Widget? breakTabWidget(BuildContext context) {
    return null;
  }

  Widget contentDesktopWidget(BuildContext context);
  Widget contentMobileWidget(BuildContext context) =>
      contentDesktopWidget(context);

  Color? backgroundColor(BuildContext context) {
    return isDarkTheme(context) ? FlarelineColors.darkerBackground : null;
  }

  @override
  Widget build(BuildContext context) {
    return _FlarelineLayoutWidgetWrapper(
      showTermsOnStartup: showTermsOnStartup,
      shouldShowWelcomeModal: shouldShowWelcomeModal,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor(context),
      appBar: AppBar(toolbarHeight: 0),
      body: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          final sidebarProvider = Provider.of<SidebarProvider>(context);

          if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
            return Row(
              children: [
                if (showSideBar)
                  sideBarWidget(context, sidebarProvider.isCollapsed),
                Expanded(child: rightContentWidget(context))
              ],
            );
          }
          return rightContentWidget(context);
        },
      ),
      drawer: sideBarWidget(context, false),
    );
  }

  Widget sideBarWidget(BuildContext context, bool isCollapsed) {
    return SideBarWidget(
      isDark: isDarkTheme(context),
      darkBg: sideBarDarkColor,
      lightBg: sideBarLightColor,
      appName: appName,
      sideBarAsset: sideBarAsset(context),
      width: isCollapsed ? sideBarCollapsedWidth : sideBarWidth,
      logoWidget: logoWidget(context),
      footerWidget: footerWidget(context),
      logoFontSize: logoFontSize,
      isCollapsible: isSidebarCollapsible,
    );
  }

  Widget rightContentWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmer = userProvider.farmer;

    Widget contentWidget = Column(
      children: [
        if (showTitle)
          SizedBox(
            height: 50,
            child: breakTabWidget(context) ??
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 600;
                    final shouldShowBreadcrumbs = 
                        !showBreadcrumbsOnlyOnDesktop || isDesktop;
                    
                    return BreakTab(
                      breakTabTitle(context),
                      breadcrumbs: breakTabBreadcrumbs(context),
                      rightWidget: breakTabRightWidget(context),
                      showBreadcrumbs: shouldShowBreadcrumbs && breakTabTitle(context).isNotEmpty,
                      showCurrentRoute: showCurrentRouteInBreadcrumb,
                    );
                  },
                ),
          ),
        if (showTitle) const SizedBox(height: 10),
        isContentScroll
            ? ScreenTypeLayout.builder(
                desktop: contentDesktopWidget,
                mobile: contentMobileWidget,
                tablet: contentMobileWidget,
              )
            : Expanded(
                child: ScreenTypeLayout.builder(
                  desktop: contentDesktopWidget,
                  mobile: contentMobileWidget,
                  tablet: contentMobileWidget,
                ),
              ),
      ],
    );

    return Column(
      children: [
        if (showToolBar(context))
          ToolBarWidget(
            showMore: showDrawer,
            showChangeTheme: true,
            userInfoWidget: _NotificationBadgeAvatar(
              farmerId: farmer?.id,
              imageUrl: farmer?.imageUrl,
            ),
          ),
        if (showToolBar(context)) const SizedBox(height: 0),
        Expanded(
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
            alignment: isAlignCenter ? Alignment.center : null,
            padding: customPadding ?? padding,
            child: isContentScroll
                ? SingleChildScrollView(child: contentWidget)
                : contentWidget,
          ),
        ),
      ],
    );
  }
}






class _FlarelineLayoutWidgetWrapper extends StatefulWidget {
  final Widget child;
  final bool showTermsOnStartup;
  final bool shouldShowWelcomeModal;

  const _FlarelineLayoutWidgetWrapper({
    required this.child,
    required this.showTermsOnStartup,
    required this.shouldShowWelcomeModal,
  });

  @override
  State<_FlarelineLayoutWidgetWrapper> createState() => _FlarelineLayoutWidgetWrapperState();
}

class _FlarelineLayoutWidgetWrapperState extends State<_FlarelineLayoutWidgetWrapper> {
  static final Map<String, bool> _sessionModalStates = {};
  
  // Generate a unique session key based on user ID
  String get _sessionKey {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    return userId != null ? 'user_$userId' : 'anonymous';
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleModals(context);
    });

    return widget.child;
  }

  Future<void> _handleModals(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
 
    final isFarmer = userProvider.isFarmer;
    
    // Check if user has previously declined terms
    final hasDeclinedTerms = _hasDeclinedTerms(userProvider);
    if (await hasDeclinedTerms) {
      return; // Don't show modal if user previously declined
    }

    // Check if terms should be shown - ONLY FOR FARMERS
    final showTerms = widget.showTermsOnStartup && 
          userProvider.isReady && 
          userProvider.user?.termsAccepted == false &&
          isFarmer &&
          !(await hasDeclinedTerms);

    // Get the session state for this user
    final hasShownTermsThisSession = _sessionModalStates[_sessionKey] ?? false;

    // Show terms modal if conditions are met and hasn't been shown this session
    if (showTerms && !hasShownTermsThisSession) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _showTermsModal(context, userProvider);
      });
    }
    
 
  }

  // Check if user has previously declined terms (using shared preferences)
  Future<bool> _hasDeclinedTerms(UserProvider userProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = userProvider.user?.id;
    if (userId != null) {
      final declinedKey = 'terms_declined_$userId';
      return prefs.getBool(declinedKey) ?? false;
    }
    return false;
  }

  // Store decline status persistently
  Future<void> _storeDeclinedStatus(UserProvider userProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = userProvider.user?.id;
    if (userId != null) {
      final declinedKey = 'terms_declined_$userId';
      await prefs.setBool(declinedKey, true);
    }
  }


  

  // Clear decline status (if needed, e.g., for testing)
  Future<void> _clearDeclinedStatus(UserProvider userProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = userProvider.user?.id;
    if (userId != null) {
      final declinedKey = 'terms_declined_$userId';
      await prefs.remove(declinedKey);
    }
  }

  Future<void> _showTermsModal(BuildContext context, UserProvider userProvider) async {
    if (!mounted) return;
    
    // Mark as shown for this session
    _sessionModalStates[_sessionKey] = true;

    // Access the SectorService safely
    final sectorService = context.read<SectorService>();
    
    PrivacyNoticeModal.showModal(
      context: context,
      onAccept: () async {
        try {
          // Validate user exists and has an ID
          if (userProvider.user?.id == null) {
            // Silent failure - remove session flag so modal can show again
            _sessionModalStates.remove(_sessionKey);
            return;
          }
          
          // Clear any previously stored decline status since user now accepts
          await _clearDeclinedStatus(userProvider);
          
          // Direct SectorService API call to accept terms
          final result = await sectorService.acceptTerms(userProvider.user!.id!);
          
          if (result['success'] == true) {
            // Update user with termsAccepted = true
            if (userProvider.user != null) {
              final updatedUser = userProvider.user!.copyWith(
                termsAccepted: true,
              );
              
              // Use setUser method to update and persist
              await userProvider.setUser(updatedUser);
            }

     
          } else {
            // API failure - remove session flag so modal can show again later
            _sessionModalStates.remove(_sessionKey);
          }
          
        } catch (e) {
          // Exception - remove session flag so modal can show again later
          _sessionModalStates.remove(_sessionKey);
        }  
      },
      onDecline: () async {
        // Store the declined status persistently
        await _storeDeclinedStatus(userProvider);
        
   
        if (  mounted) {
           
          _sessionModalStates['${_sessionKey}_welcome'] = true;
          
          // Reset terms modal flag to allow showing again (though it won't due to decline status)
          _sessionModalStates.remove(_sessionKey);
    
          // Close the modal
          Navigator.of(context).pop();
        }
      },
      isMandatory: true,
      title: 'AgriTrack Terms & Conditions',
    );
  }

 
 
 

   

}






class _NotificationBadgeAvatar extends StatefulWidget {
  final int? farmerId;
  final String? imageUrl;

  const _NotificationBadgeAvatar({
    required this.farmerId,
    required this.imageUrl,
  });

  @override
  State<_NotificationBadgeAvatar> createState() =>
      _NotificationBadgeAvatarState();
}

class _NotificationBadgeAvatarState extends State<_NotificationBadgeAvatar> {
  int _unreadCount = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.farmerId != null) {
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    setState(() => isLoading = true);

    try {
      final sectorService =
          RepositoryProvider.of<SectorService>(context, listen: false);
      final result =
          await sectorService.getUnreadNotificationsCount(widget.farmerId!);

      if (result['success'] == true && mounted) {
        final data = result['data'];
        int count = 0;

        if (data is int) {
          count = data;
        } else if (data is Map) {
          count = data['count'] ?? data['unreadCount'] ?? 0;
        }

        setState(() {
          _unreadCount = count;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('Error fetching unread notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundImage: widget.imageUrl != null
              ? NetworkImage(widget.imageUrl!)
              : null,
          radius: 22,
          child: widget.imageUrl == null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SvgPicture.asset(
                    'assets/DA_image.svg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HoverableLogo extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableLogo({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableLogo> createState() => _HoverableLogoState();
}

class _HoverableLogoState extends State<_HoverableLogo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: AnimatedScale(
              scale: _isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}