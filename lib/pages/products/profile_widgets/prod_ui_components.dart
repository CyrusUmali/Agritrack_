import 'package:flutter/material.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:path/path.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flareline_uikit/flareline_uikit.dart';
import 'package:flareline/services/lanugage_extension.dart';

import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';

class ProductHeaderUI {
  static Widget buildHeader(
      ThemeData theme, ColorScheme colorScheme, bool isEditing) {
    return Row(
      children: [
        //
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // color: colorScheme.primaryContainer,
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Product Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Edit Mode',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Widget buildContent(
      BuildContext context,
      ThemeData theme,
      ColorScheme colorScheme,
      Product item,
      bool isEditing,
      bool isUploading,
      String? newImageUrl,
      TextEditingController nameController,
      TextEditingController descriptionController,
      String selectedSector,
      Function pickAndUploadImage,
      Function(String) getSectorIcon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(theme, colorScheme, item, isEditing,
                  isUploading, newImageUrl, pickAndUploadImage, getSectorIcon),
              const SizedBox(width: 32),
              Expanded(
                child: _buildProductInfo(
                    theme,
                    colorScheme,
                    item,
                    isEditing,
                    nameController,
                    descriptionController,
                    selectedSector,
                    getSectorIcon,
                    context),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildProductImage(theme, colorScheme, item, isEditing,
                  isUploading, newImageUrl, pickAndUploadImage, getSectorIcon),
              const SizedBox(height: 24),
              _buildProductInfo(
                  theme,
                  colorScheme,
                  item,
                  isEditing,
                  nameController,
                  descriptionController,
                  selectedSector,
                  getSectorIcon,
                  context),
            ],
          );
        }
      },
    );
  }

  static Widget _buildProductImage(
      ThemeData theme,
      ColorScheme colorScheme,
      Product item,
      bool isEditing,
      bool isUploading,
      String? newImageUrl,
      Function pickAndUploadImage,
      Function(String) getSectorIcon) {
    return Hero(
      tag: 'product_image_${item.id}',
      child: GestureDetector(
        onTap: isEditing ? () => pickAndUploadImage() : null,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                if (isUploading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  )
                else
                  FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: NetworkImage(newImageUrl ??
                        item.imageUrl ??
                        'https://static.toiimg.com/photo/67882583.cms'),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.errorContainer,
                            colorScheme.errorContainer.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (isEditing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to change image',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildProductInfo(
      ThemeData theme,
      ColorScheme colorScheme,
      Product item,
      bool isEditing,
      TextEditingController nameController,
      TextEditingController descriptionController,
      String selectedSector,
      Function(String) getSectorIcon,
      BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !isEditing
              ? _buildDisplayName(theme, colorScheme, item)
              : _buildEditName(theme, colorScheme, nameController),
        ),
        const SizedBox(height: 16),

        // Product Description
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !isEditing
              ? _buildDisplayDescription(theme, colorScheme, item, context)
              : _buildEditDescription(
                  theme, colorScheme, descriptionController),
        ),
        const SizedBox(height: 20),

        // Only show sector here when editing (below description)
        if (isEditing)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildEditSector(theme, colorScheme, selectedSector),
          ),
      ],
    );
  }

  static Widget _buildDisplayName(
      ThemeData theme, ColorScheme colorScheme, Product item) {
    return Container(
      key: const ValueKey('display_name'),
      child: Text(
        item.name,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          height: 1.2,
        ),
      ),
    );
  }

  static Widget _buildEditName(ThemeData theme, ColorScheme colorScheme,
      TextEditingController controller) {
    return Container(
      key: const ValueKey('edit_name'),
      child: OutBorderTextFormField(
        controller: controller,
        labelText: 'Product Name',
      ),
    );
  }

  static Widget _buildEditDescription(ThemeData theme, ColorScheme colorScheme,
      TextEditingController controller) {
    return Container(
      key: const ValueKey('edit_description'),
      child: OutBorderTextFormField(
        controller: controller,
        labelText: 'Description',
        maxLines: 4,
        textStyle: theme.textTheme.bodyLarge,
      ),
    );
  }

  static Widget _buildEditSector(
      ThemeData theme, ColorScheme colorScheme, String selectedSector) {
    return Container(
      key: const ValueKey('edit_sector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sector',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSector,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: FlarelineColors.border, width: 1),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: FlarelineColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
            items: [
              _buildDropdownItem('Rice', Icons.rice_bowl_outlined),
              _buildDropdownItem('Corn', Icons.agriculture_outlined),
              _buildDropdownItem('HVC', Icons.local_florist_outlined),
              _buildDropdownItem('Livestock', Icons.pets_outlined),
              _buildDropdownItem('Fishery', Icons.set_meal_outlined),
              _buildDropdownItem('Organic', Icons.eco_outlined),
            ],
            onChanged: (value) {
              // This will be handled by the parent component
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildDisplayDescription(ThemeData theme,
      ColorScheme colorScheme, Product item, BuildContext context) {
    return Container(
      key: const ValueKey('display_description'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: colorScheme.surfaceVariant.withOpacity(0.3),
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.description?.isNotEmpty == true
                  ? item.description!
                  : 'No description available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: item.description?.isNotEmpty == true
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated buildDisplaySector method with better spacing and alignment
  static Widget buildDisplaySector(ThemeData theme, ColorScheme colorScheme,
      Product item, Function(String) getSectorIcon) {
    return Container(
      key: const ValueKey('display_sector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sector',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48, // Fixed height to match button
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondaryContainer,
                  colorScheme.secondaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // Center the content
              children: [
                Icon(
                  getSectorIcon(item.sector),
                  color: colorScheme.onSecondaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  item.sector,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static DropdownMenuItem<String> _buildDropdownItem(
      String value, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(value),
        ],
      ),
    );
  }

  static Widget buildEditControls(
      ColorScheme colorScheme,
      ThemeData theme,
      Product item,
      bool isEditing,
      bool isLoading,
      Function toggleEditing,
      Function submitChanges,
      Function(String) getSectorIcon,
      BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: colorScheme.surfaceVariant.withOpacity(0.3),

        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: isEditing
          ? _buildEditingControls(
              colorScheme, theme, isLoading, toggleEditing, submitChanges)
          : _buildDisplayControls(
              theme, colorScheme, item, toggleEditing, getSectorIcon),
    );
  }

  // Separated edit controls for cleaner code
  static Widget _buildEditingControls(ColorScheme colorScheme, ThemeData theme,
      bool isLoading, Function toggleEditing, Function submitChanges) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: isLoading ? null : () => toggleEditing(),
          icon: const Icon(Icons.close_outlined),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: isLoading ? null : () => submitChanges(),
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_outlined, color: Colors.white),
          label: Text(
            isLoading ? 'Saving...' : 'Save Changes',
            style: const TextStyle(color: Colors.white),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // Display controls with proper sector alignment
  static Widget _buildDisplayControls(ThemeData theme, ColorScheme colorScheme,
      Product item, Function toggleEditing, Function(String) getSectorIcon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
      children: [
        Expanded(
          flex: 1,
          child: buildDisplaySector(theme, colorScheme, item, getSectorIcon),
        ),
        const SizedBox(width: 16),
        // Wrap button in container to control height
        Container(
          height: 48, // Match the sector container height
          child: FilledButton.icon(
            onPressed: () => toggleEditing(),
            icon:
                const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            label: Text(
              'Edit Product',
              style: TextStyle(color: Colors.white),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
