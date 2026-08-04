class ServiceCategoryOption {
  const ServiceCategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ServiceAreaOption {
  const ServiceAreaOption({required this.id, required this.label});

  final String id;
  final String label;
}

const serviceCategoryOptions = <ServiceCategoryOption>[
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000201', label: 'Plumbing / Toilet'),
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000202', label: 'Electrical / Lighting / Fan'),
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000203', label: 'Air Conditioning'),
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000204', label: 'Moving / Delivery'),
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000205', label: 'Cleaning'),
  ServiceCategoryOption(id: '00000000-0000-0000-0000-000000000206', label: 'Handyman'),
];

const serviceAreaOptions = <ServiceAreaOption>[
  ServiceAreaOption(id: '00000000-0000-0000-0000-000000000251', label: 'Mount Austin'),
  ServiceAreaOption(id: '00000000-0000-0000-0000-000000000252', label: 'Taman Molek'),
  ServiceAreaOption(id: '00000000-0000-0000-0000-000000000253', label: 'Permas Jaya'),
  ServiceAreaOption(id: '00000000-0000-0000-0000-000000000254', label: 'Skudai'),
];
