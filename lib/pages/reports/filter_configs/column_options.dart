class ColumnOptions {
  static const Map<String, List<String>> reportColumns = {
    'farmers': [
      'Name',
      'Sector',
      'Association',
      'Farms',
      'Products',
      '(Mt | Heads)',
      'Area',
      'Contact',
    ],
    'livestock': [
      'Farm Name',
      'Owner',
      'Barangay',
      'Farm Type',
      'Product',
    ],
    'products': [
      'Product',
      'Sector',
      'Harvest Date',
      'Area Harvested',
      'Volume',
      'Value',
      'Farm Name',
      'Barangay'
    ],
    'barangay': [
      'Barangay',
      'Product',
      'Harvest Date',
      'Volume',
      'Value',
      'Area Harvested',
    ],
    'sectors': [
      'Sector Name',
      'Product',
      'Harvest Date',
      'Volume',
      'Value',
      'Area Harvested',
    ],
    'farmer': [
      'Farmer Id',
      'Farmer Name',
      'Barangay',
      'Product',
      'Association',
      'Volume',
      'Total Value',
      'Area Harvested',
      'Harvest Date',
    ],
  };
}
