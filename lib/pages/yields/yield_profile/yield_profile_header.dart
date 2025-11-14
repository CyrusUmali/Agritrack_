import 'package:flareline/pages/yields/yield_profile/yield_profile_utils.dart';
import 'package:flutter/material.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/services/lanugage_extension.dart'; 


class YieldProfileHeader extends StatelessWidget {
  final Yield yieldData;

  const YieldProfileHeader({super.key, required this.yieldData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // This will space children to opposite ends
        children: [
          // Left side content
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Text(
        

                context.translate('Record Details'), 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),                                                                          
            ],
          ),
          
          // Right side content
          buildStatusIndicator(yieldData.status ?? 'Pending', context),
        ],
      ),
    );
  }
}