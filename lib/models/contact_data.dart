class ContactData {
  ContactData({
    String? id,
    this.name = '',
    this.title = '',
    this.company = '',
    this.mobile = '',
    this.whatsapp = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.linkedin = '',
    this.address = '',
    this.bio = '',
    List<String>? rawLines,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        rawLines = rawLines ?? <String>[];

  final String id;

  /// Text lines found on a scanned card. Only used on the review screen; never saved.
  final List<String> rawLines;
  String name, title, company, mobile, whatsapp, phone, email, website, linkedin, address, bio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'company': company,
        'mobile': mobile,
        'whatsapp': whatsapp,
        'phone': phone,
        'email': email,
        'website': website,
        'linkedin': linkedin,
        'address': address,
        'bio': bio,
      };

  factory ContactData.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString();
    return ContactData(
      id: j['id']?.toString(),
      name: s(j['name']),
      title: s(j['title']),
      company: s(j['company']),
      mobile: s(j['mobile']),
      whatsapp: s(j['whatsapp']),
      phone: s(j['phone']),
      email: s(j['email']),
      website: s(j['website']),
      linkedin: s(j['linkedin']),
      address: s(j['address']),
      bio: s(j['bio']),
    );
  }

  bool get isEmpty =>
      name.isEmpty && company.isEmpty && mobile.isEmpty && phone.isEmpty && email.isEmpty;
}

String initialsOf(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
  return letters.isEmpty ? '?' : letters;
}
