// privacy_notice_modal.dart
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flutter/material.dart';

class PrivacyNoticeModal extends StatefulWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showDeclineButton;
  final bool showAcceptCheckbox;

  const PrivacyNoticeModal({
    Key? key,
    this.onAccept,
    this.onDecline,
    this.showDeclineButton = true,
    this.showAcceptCheckbox = true,
  }) : super(key: key);

  @override
  State<PrivacyNoticeModal> createState() => _PrivacyNoticeModalState();

  static void showModal({
    required BuildContext context,
    required VoidCallback onAccept,
    VoidCallback? onDecline,
    bool isMandatory = true,
    String title = 'Privacy Notice',
    double? width,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
          backgroundColor: Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width ?? (isMobile ? screenWidth * 0.95 : 700),
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: PrivacyNoticeModal(
                onAccept: onAccept,
                onDecline: onDecline,
                showDeclineButton: !isMandatory,
                showAcceptCheckbox: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrivacyNoticeModalState extends State<PrivacyNoticeModal> {
  bool isAccepted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 24,
              vertical: isMobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.privacy_tip, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Notice',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 20 : 24,
                            ),
                      ),
                      Text(
                        'Your privacy is important to us. Please review how we handle your information.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: isMobile ? 12 : 14,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                if (widget.showDeclineButton)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onDecline?.call();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildPrivacyContent(context),
                    const SizedBox(height: 20),
                    
                    if (widget.showAcceptCheckbox) _buildAcceptCheckbox(context),
                  ],
                ),
              ),
            ),
          ),

          // Footer with action buttons
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDisclaimer(context),
                const SizedBox(height: 16),
                _buildActionButtons(context, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context: context,
              title: '1. Information We Collect',
              content:
                  'AgriTrack collects information to provide you with better farm management services:\n• Personal Information: Name, email, phone number, address\n• Farm Data: Land size, crops, yields\n• Usage Data: How you interact with our platform\n• Device Information: Browser type, IP address, operating system\n• Location Data: For field mapping and local weather integration',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: '2. How We Use Your Information',
              content:
                  'We use your information to:\n• Provide and improve farm management services\n• Generate personalized insights and recommendations\n• Comply with agricultural reporting requirements\n• Communicate important updates and notifications\n• Ensure platform security and prevent fraud\n• Conduct research and analysis (using anonymized data)\n• Personalize your experience with relevant features',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: '3. Data Sharing & Disclosure',
              content:
                  'We may share your information in these circumstances:\n• Government Authorities: For mandatory agricultural reporting as required by law\n• Service Providers: With trusted partners who help operate our platform (under strict confidentiality)\n• Legal Requirements: When required by law, court order, or government request\n• Business Transfers: In connection with mergers, acquisitions, or asset sales\n• With Your Consent: When you explicitly authorize specific sharing\n\nWe never sell your personal farm data to third parties for marketing purposes.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: '4. Data Security',
              content:
                  'We implement robust security measures to protect your information:\n• Encryption of data in transit and at rest\n• Regular security audits and vulnerability assessments\n• Access controls and authentication mechanisms\n• Secure data centers with physical protections\n• Employee training on data protection practices\n\nDespite our efforts, no electronic transmission or storage is 100% secure.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: '5. Data Retention',
              content:
                  'We retain your information for as long as necessary to:\n• Provide services to you\n• Comply with legal obligations (including agricultural reporting requirements)\n• Resolve disputes and enforce agreements\n• Maintain business records as required by law\n\nYou may request deletion of your data, subject to legal retention requirements.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: '6. Your Rights & Choices',
              content:
                  'Depending on your location, you may have the right to:\n• Access your personal information\n• Correct inaccurate or incomplete data\n• Request deletion of your data (where applicable)\n• Object to certain processing activities\n• Request data portability\n• Withdraw consent (where processing is based on consent)\n\nTo exercise these rights, contact our privacy team at agritrack@gmail.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptCheckbox(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted ? const Color(0xFF10B981) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isAccepted,
            onChanged: (value) {
              setState(() {
                isAccepted = value ?? false;
              });
            },
            activeColor: const Color(0xFF10B981),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isAccepted = !isAccepted;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  children: [
                    const TextSpan(text: 'I have read and understand the '),
                    TextSpan(
                      text: 'Privacy Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const TextSpan(text: ' and consent to data processing as described.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Important: Certain farm data, including crop production and land use information, may be shared with agricultural authorities as required by government regulations.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Row(
      children: [
     
          Expanded(
            child: ButtonWidget(
              btnText: 'Decline',
              onTap: () {
                // Navigator.of(context).pop();
                widget.onDecline?.call();
              },
             
            ),
          ),
  SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: ButtonWidget(
            btnText: 'Accept & Continue',
            onTap: isAccepted
                ? () {
                    Navigator.of(context).pop();
                    widget.onAccept?.call();
                  }
                : null,
            type: ButtonType.primary.type,
          ),
        ),
      ],
    );
  }
}