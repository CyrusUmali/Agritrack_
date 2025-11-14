import 'package:flareline/pages/assoc/add_assoc_modal.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class AssociationFilterWidget extends StatelessWidget {
  const AssociationFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final iconTheme = theme.iconTheme;
    final textTheme = theme.textTheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isFarmer = userProvider.isFarmer;

    return Container(
      decoration: BoxDecoration(
        color: cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardTheme.surfaceTintColor ?? Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search associations...',
                hintStyle: TextStyle(color: theme.hintColor),
                prefixIcon: Icon(Icons.search, color: iconTheme.color),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (query) {
                context.read<AssocsBloc>().add(SearchAssocs(query));
              },
            ),
          ),
          VerticalDivider(
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: cardTheme.surfaceTintColor ?? Colors.grey[300],
          ),
          VerticalDivider(
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: cardTheme.surfaceTintColor ?? Colors.grey[300],
          ),
          if (!isFarmer)
            IconButton(
              icon: Icon(Icons.add, color: theme.primaryColor),
              onPressed: () => AddAssociationModal.show(context),
              tooltip: 'Add Association',
            ),
        ],
      ),
    );
  }
}
