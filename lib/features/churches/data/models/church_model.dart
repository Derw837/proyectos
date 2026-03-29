class ChurchModel {
  final String id;
  final String churchName;
  final String country;
  final String city;
  final String sector;
  final String address;
  final String phone;
  final String whatsapp;
  final String email;
  final String description;
  final String pastorName;
  final String doctrinalBase;
  final String donationAccountName;
  final String donationBankName;
  final String donationAccountNumber;
  final String donationAccountType;
  final String donationInstructions;
  final String? spiritualHelpLabel;
  final String? spiritualHelpUrl;
  final String? logoUrl;
  final String? coverUrl;
  final String status;

  ChurchModel({
    required this.id,
    required this.churchName,
    required this.country,
    required this.city,
    required this.sector,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.description,
    required this.pastorName,
    required this.doctrinalBase,
    required this.donationAccountName,
    required this.donationBankName,
    required this.donationAccountNumber,
    required this.donationAccountType,
    required this.donationInstructions,
    required this.spiritualHelpLabel,
    required this.spiritualHelpUrl,
    required this.logoUrl,
    required this.coverUrl,
    required this.status,
  });

  factory ChurchModel.fromMap(Map<String, dynamic> map) {
    return ChurchModel(
      id: map['id']?.toString() ?? '',
      churchName: map['church_name']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      sector: map['sector']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      whatsapp: map['whatsapp']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      pastorName: map['pastor_name']?.toString() ?? '',
      doctrinalBase: map['doctrinal_base']?.toString() ?? '',
      donationAccountName: map['donation_account_name']?.toString() ?? '',
      donationBankName: map['donation_bank_name']?.toString() ?? '',
      donationAccountNumber: map['donation_account_number']?.toString() ?? '',
      donationAccountType: map['donation_account_type']?.toString() ?? '',
      donationInstructions: map['donation_instructions']?.toString() ?? '',
      spiritualHelpLabel: map['spiritual_help_label']?.toString(),
      spiritualHelpUrl: map['spiritual_help_url']?.toString(),
      logoUrl: map['logo_url']?.toString(),
      coverUrl: map['cover_url']?.toString(),
      status: map['status']?.toString() ?? '',
    );
  }
}