class ChartDataProvider {
  static Map<String, dynamic> getChartData(String reportType) {
    switch (reportType) {
      case 'farmers':
        return {
          'labels': ['Brgy. 1', 'Brgy. 2', 'Brgy. 3', 'Brgy. 4'],
          'values': [45, 32, 28, 39],
        };
      case 'farms':
        return {
          'labels': ['Crop', 'Livestock', 'Fishery', 'Mixed'],
          'values': [40, 25, 20, 15],
        };
      // Add other cases...
      default:
        return {};
    }
  }
}
