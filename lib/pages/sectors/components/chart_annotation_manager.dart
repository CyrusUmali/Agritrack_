import 'package:flareline/pages/sectors/components/annotation_dialog.dart';
import 'package:flareline/pages/sectors/components/sector_data_model.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as chart;
import 'package:flareline/pages/toast/toast_helper.dart';

class ChartAnnotationManager {
  List<chart.CartesianChartAnnotation> customAnnotations = [];
  // Map to store database IDs corresponding to each annotation
  Map<int, int> annotationIndexToId = {}; // Map annotation index to database ID
  final Function(VoidCallback) setState;
  late BuildContext _context;

  ChartAnnotationManager({required this.setState});

  void setContext(BuildContext context) {
    _context = context;
  }

  void handleChartTap(
      TapDownDetails details,
      GlobalKey chartKey,
      int selectedFromYear,
      int selectedToYear,
      List<SectorData> filteredData,
      BuildContext context) {
    _context = context;
    final renderBox = chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = details.localPosition;
    final chartSize = renderBox.size;
    final year = _convertXToValue(
        offset.dx, chartSize.width, selectedFromYear, selectedToYear);
    final value = _convertYToValue(offset.dy, chartSize.height, filteredData);

    _showAnnotationDialog(year, value);
  }

  String _convertXToValue(
      double x, double width, int selectedFromYear, int selectedToYear) {
    final years = selectedToYear - selectedFromYear + 1;
    final yearIndex = (x / width * years).clamp(0, years - 1).floor();
    return (selectedFromYear + yearIndex).toString();
  }

  double _convertYToValue(
      double y, double height, List<SectorData> filteredData) {
    double minValue = double.infinity;
    double maxValue = -double.infinity;

    for (final sector in filteredData) {
      for (final point in sector.data) {
        final value = point['y'].toDouble();
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    final range = maxValue - minValue;
    minValue = (minValue - range * 0.1).clamp(0, double.infinity);
    maxValue = maxValue + range * 0.1;

    final normalizedY = 1 - (y / height);
    return minValue + normalizedY * (maxValue - minValue);
  }

  SectorService get _sectorService {
    return RepositoryProvider.of<SectorService>(_context);
  }

  Future<void> _showAnnotationDialog(String year, double value) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: _context,
      builder: (context) => SimpleAnnotationDialog(
        year: year,
        initialValue: value,
        initialText: '',
      ),
    );

    if (result != null && result['text'] != null) {
      try {
        // Save to backend
        final response = await _sectorService.createAnnotation({
          'year': year,
          'value': result['value'],
          'text': result['text'],
          'coordinateUnit': 'point',
          'horizontalAlignment': 'near',
          'verticalAlignment': 'far',
        });

        print("Raw API Response: ${response.toString()}");

        // Enhanced null checking and response validation
        if (response == null) {
          throw Exception("API returned null");
        }

        // Check if response has the expected structure
        if (response is Map<String, dynamic> &&
            response['success'] == true &&
            response.containsKey('annotation')) {
          final annotationData = response['annotation'] as Map<String, dynamic>;
          final databaseId =
              annotationData['id'] as int?; // Get the database ID

          if (databaseId == null) {
            throw Exception("Database ID not found in response");
          }

          setState(() {
            final newIndex = customAnnotations.length;
            customAnnotations.add(
              chart.CartesianChartAnnotation(
                widget: _buildAnnotationWidget(
                  annotationData['text'] ?? result['text'],
                  newIndex,
                  (annotationData['value'] as num?)?.toDouble() ??
                      result['value'],
                ),
                x: annotationData['year'] ?? year,
                y: (annotationData['value'] as num?)?.toDouble() ??
                    result['value'],
                coordinateUnit: chart.CoordinateUnit.point,
                horizontalAlignment: chart.ChartAlignment.near,
                verticalAlignment: chart.ChartAlignment.far,
              ),
            );

            // Store the mapping between annotation index and database ID
            annotationIndexToId[newIndex] = databaseId;
          });

          ToastHelper.showSuccessToast(
              'Annotation saved successfully', _context);
        } else {
          // More detailed error message
          final errorMsg = response is Map
              ? 'Invalid response structure: ${response.keys.join(', ')}'
              : 'Invalid response type: ${response.runtimeType}';
          ToastHelper.showErrorToast(
              'Failed to save annotation: $errorMsg', _context);
        }
      } catch (e) {
        ToastHelper.showErrorToast('Failed to save annotation', _context);
        debugPrint('Error saving annotation: $e');
      }
    }
  }

  Widget _buildAnnotationWidget(String text, int index, double value) {
    return Tooltip(
      message: text,
      preferBelow: false,
      verticalOffset: 20,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: GestureDetector(
        key: ValueKey('annotation_$index'),
        onTap: () => editAnnotation(index),
        onLongPress: () => _deleteAnnotationFromBackend(index),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> editAnnotation(int index) async {
    if (index < 0 || index >= customAnnotations.length) return;

    final annotation = customAnnotations[index];
    final databaseId = annotationIndexToId[index];

    if (databaseId == null) {
      ToastHelper.showErrorToast('Annotation ID not found', _context);
      return;
    }

    // Extract text from the Tooltip widget
    String currentText = '';
    if (annotation.widget is Tooltip) {
      final tooltip = annotation.widget as Tooltip;
      currentText = tooltip.message ?? '';
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: _context,
      builder: (context) => SimpleAnnotationDialog(
        year: annotation.x,
        initialValue: annotation.y,
        initialText: currentText,
        isEditing: true,
      ),
    );

    if (result != null) {
      try {
        if (result['delete'] == true) {
          await _deleteAnnotationFromBackend(index);
        } else if (result['text'] != null) {
          // Use the database ID for updating
          await _sectorService.updateAnnotation(
            databaseId, // Use database ID instead of year
            {
              'year': annotation.x,
              'value': result['value'],
              'text': result['text'],
              'coordinateUnit': 'point',
              'horizontalAlignment': 'near',
              'verticalAlignment': 'far',
            },
          );

          setState(() {
            customAnnotations[index] = chart.CartesianChartAnnotation(
              widget: _buildAnnotationWidget(
                result['text'],
                index,
                result['value'],
              ),
              x: annotation.x,
              y: result['value'],
              coordinateUnit: annotation.coordinateUnit,
              horizontalAlignment: annotation.horizontalAlignment,
              verticalAlignment: annotation.verticalAlignment,
            );
          });

          ToastHelper.showSuccessToast('Annotation updated', _context);
        }
      } catch (e) {
        ToastHelper.showErrorToast('Failed to update annotation', _context);
        debugPrint('Error updating annotation: $e');
      }
    }
  }

  Future<void> _deleteAnnotationFromBackend(int index) async {
    final databaseId = annotationIndexToId[index];

    if (databaseId == null) {
      ToastHelper.showErrorToast('Annotation ID not found', _context);
      return;
    }

    try {
      // Use the database ID for deletion
      await _sectorService.deleteAnnotation(databaseId);

      setState(() {
        customAnnotations.removeAt(index);

        // Clean up the ID mapping and reindex remaining annotations
        annotationIndexToId.remove(index);

        // Reindex all annotations that come after the deleted one
        final updatedMapping = <int, int>{};
        annotationIndexToId.forEach((oldIndex, dbId) {
          if (oldIndex > index) {
            updatedMapping[oldIndex - 1] = dbId;
          } else {
            updatedMapping[oldIndex] = dbId;
          }
        });
        annotationIndexToId = updatedMapping;

        // Rebuild widgets with correct indices
        for (int i = 0; i < customAnnotations.length; i++) {
          final oldAnnotation = customAnnotations[i];
          customAnnotations[i] = chart.CartesianChartAnnotation(
            widget: _buildAnnotationWidget(
              _extractTextFromWidget(oldAnnotation.widget),
              i, // Use the new index
              oldAnnotation.y,
            ),
            x: oldAnnotation.x,
            y: oldAnnotation.y,
            coordinateUnit: oldAnnotation.coordinateUnit,
            horizontalAlignment: oldAnnotation.horizontalAlignment,
            verticalAlignment: oldAnnotation.verticalAlignment,
          );
        }
      });

      ToastHelper.showSuccessToast('Annotation deleted', _context);
    } catch (e) {
      ToastHelper.showErrorToast('Failed to delete annotation', _context);
      debugPrint('Error deleting annotation: $e');
    }
  }

  String _extractTextFromWidget(Widget widget) {
    try {
      // Handle Tooltip wrapper
      if (widget is Tooltip) {
        return widget.message ?? '';
      }
      // Handle GestureDetector wrapping
      else if (widget is GestureDetector) {
        final child = widget.child;

        // Check if it's wrapped in MouseRegion
        if (child is MouseRegion) {
          return _extractFromMouseRegion(child);
        }
        // Handle direct Container child
        else if (child is Container) {
          return _extractFromContainer(child);
        }
      }
      // Handle direct Container
      else if (widget is Container) {
        return _extractFromContainer(widget);
      }
    } catch (e) {
      print('Error extracting text from widget: $e');
    }
    return '';
  }

  String _extractFromMouseRegion(MouseRegion mouseRegion) {
    // For minimal annotations, we can't extract text from the icon
    // Instead, we should store the text separately or use the tooltip message
    return ''; // This will be handled by the Tooltip message
  }

  String _extractFromContainer(Container container) {
    final containerChild = container.child;
    if (containerChild is Row) {
      // Look for Text widget in Row children
      for (final rowChild in containerChild.children) {
        if (rowChild is Text && rowChild.data != null) {
          return rowChild.data!;
        }
      }
    } else if (containerChild is Text) {
      return containerChild.data ?? '';
    }
    return '';
  }

  Future<void> loadAnnotations() async {
    try {
      final annotations = await _sectorService.fetchAnnotations();
      setState(() {
        customAnnotations.clear();
        annotationIndexToId.clear();

        customAnnotations = annotations?.asMap().entries.map((entry) {
              final index = entry.key;
              final ann = entry.value;
              final databaseId = ann?['id'] as int?; // Get the database ID

              if (databaseId != null) {
                annotationIndexToId[index] = databaseId; // Store the mapping
              }

              return chart.CartesianChartAnnotation(
                widget: _buildAnnotationWidget(
                  ann?['text'] ?? '',
                  index, // Use the list index
                  ann?['value'] ?? 0,
                ),
                x: ann?['year'] ?? '',
                y: ann?['value'] ?? 0,
                coordinateUnit: chart.CoordinateUnit.point,
                horizontalAlignment: chart.ChartAlignment.near,
                verticalAlignment: chart.ChartAlignment.far,
              );
            })?.toList() ??
            [];
      });
    } catch (e) {
      ToastHelper.showErrorToast('Failed to load annotations', _context);
      debugPrint('Error loading annotations: $e');
    }
  }
}
