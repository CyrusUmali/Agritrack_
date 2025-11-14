import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/pages/yields/yield_profile/yield_profile_form.dart';
import 'package:flareline/pages/yields/yield_profile/yield_profile_header.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/layout.dart';

class YieldProfile extends LayoutWidget {
  const YieldProfile({super.key, required this.yieldData});

  final Yield yieldData;

  @override
  String breakTabTitle(BuildContext context) {
    return "";
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return BlocBuilder<YieldBloc, YieldState>(
      buildWhen: (previous, current) {
        // Only rebuild when the specific yield is updated
        if (current is YieldUpdated) {
          return current.yield.id == yieldData.id;
        }
        return false;
      },
      builder: (context, state) {
        // Use the updated yield data if available, otherwise use the original
        Yield currentYieldData = yieldData;
        if (state is YieldUpdated && state.yield.id == yieldData.id) {
          currentYieldData = state.yield;
        }

        return CommonCard(
          margin: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YieldProfileHeader(yieldData: currentYieldData),
                YieldProfileForm(yieldData: currentYieldData),
              ],
            ),
          ),
        );
      },
    );
  }
}