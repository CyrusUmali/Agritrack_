import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropRequirementsWidget extends StatefulWidget {
  const CropRequirementsWidget({super.key});

  @override
  State<CropRequirementsWidget> createState() => _CropRequirementsWidgetState();
}

class _CropRequirementsWidgetState extends State<CropRequirementsWidget> {
  Map<String, dynamic>? cropRequirements;
  Map<String, dynamic>? filteredCropRequirements;
  bool isLoading = false;
  String? errorMessage;
  String selectedModel = 'Random Forest'; // Default model
  final List<String> availableModels = [
    'Random Forest',
    'Decision Tree',
    'Logistic Regression'
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCropRequirements();
    _searchController.addListener(_filterCrops);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCrops() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      setState(() {
        filteredCropRequirements = cropRequirements;
      });
    } else {
      setState(() {
        filteredCropRequirements = {};
        cropRequirements?.forEach((cropName, cropData) {
          if (cropName.toLowerCase().contains(searchTerm)) {
            filteredCropRequirements![cropName] = cropData;
          }
        });
      });
    }
  }

  Future<void> _fetchCropRequirements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      cropRequirements = null;
      filteredCropRequirements = null;
    });

    try {
      final uri = Uri.parse(ApiConstants.cropRequirements).replace(
        queryParameters: {
          'model': selectedModel == 'All Models' ? '' : selectedModel,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print(data); // Debug print
        if (data['status'] == 'success') {
          print('success');
          setState(() {
            cropRequirements = data['data'];
            filteredCropRequirements = data['data'];
          });
        } else {
          print('fail');
          throw Exception(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search crops',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Display loading/error states
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red),
            )
          else if (filteredCropRequirements == null)
            const Text('No data available')
          else if (filteredCropRequirements!.isEmpty)
            const Text('No crops match your search')
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _buildRequirementsList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirementsList() {
    return ListView.builder(
      itemCount: filteredCropRequirements!.length,
      itemBuilder: (context, index) {
        final cropName = filteredCropRequirements!.keys.elementAt(index);
        final cropData = filteredCropRequirements![cropName];
        final requirements = cropData['requirements'];
        final imageUrl = cropData['image_url'];
        final prediction = cropData['prediction'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop header with image and prediction
                Row(
                  children: [
                    if (imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cropName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Prediction Score: $prediction',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Requirements table
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    // Table header
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Parameter',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Min',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Max',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Mean',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Table rows with new parameter names
                    _buildRequirementRow('Soil pH', requirements['soil_ph']),
                    _buildRequirementRow('Fertility EC (μS/cm)', requirements['fertility_ec']),
                    _buildRequirementRow('Humidity (%)', requirements['humidity']),
                    _buildRequirementRow('Sunlight (lux)', requirements['sunlight']),
                    _buildRequirementRow('Soil Temperature (°C)', requirements['soil_temp']),
                    _buildRequirementRow('Soil Moisture (%)', requirements['soil_moisture']),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildRequirementRow(String parameter, Map<String, dynamic> values) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(parameter),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_formatValue(values['min'])),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_formatValue(values['max'])),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_formatValue(values['mean'])),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}