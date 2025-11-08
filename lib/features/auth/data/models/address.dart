class AddressModel {
  final String? street;
  final String? city;
  final String? externalNumber;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? internalNumber;
  final String? suburb;
  final String? county;

  const AddressModel({
    required this.street,
    required this.externalNumber,
    required this.internalNumber,
    required this.city,
    required this.suburb,
    required this.county,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      street: json[r'street'],
      externalNumber: json[r'externalNumber'],
      internalNumber: json[r'internalNumber'],
      city: json[r'city'],
      suburb: json[r'suburb'],
      county: json[r'county'],
      state: json[r'state'],
      country: json[r'country'],
      zipCode: json[r'zipCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'externalNumber': externalNumber,
      'internalNumber': internalNumber,
      'city': city,
      'suburb': suburb,
      'county': county,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  AddressModel copyWith({
    String? street,
    bool clearStreet = false,
    String? city,
    bool clearCity = false,
    String? externalNumber,
    bool clearExternalN = false,
    String? state,
    bool clearState = false,
    String? zipCode,
    bool clearZipCode = false,
    String? country,
    bool clearCountry = false,
    String? internalNumber,
    bool clearInternalN = false,
    String? suburb,
    bool clearSuburb = false,
    String? county,
    bool clearCounty = false,
  }) {
    return AddressModel(
      street: clearStreet ? null : street ?? this.street,
      externalNumber:
          clearExternalN ? null : externalNumber ?? this.externalNumber,
      internalNumber:
          clearInternalN ? null : internalNumber ?? this.internalNumber,
      city: clearCity ? null : city ?? this.city,
      suburb: clearSuburb ? null : suburb ?? this.suburb,
      county: clearCounty ? null : county ?? this.county,
      state: clearState ? null : state ?? this.state,
      country: clearCountry ? null : country ?? this.country,
      zipCode: clearZipCode ? null : zipCode ?? this.zipCode,
    );
  }

  @override
  String toString() {
    return 'Address('
        'street: $street, '
        'externalNumber: $externalNumber, '
        'internalNumber: $internalNumber, '
        'city: $city, '
        'suburb: $suburb, '
        'county: $county, '
        'state: $state, '
        'zipCode: $zipCode, '
        'country: $country'
        ')';
  }
}
