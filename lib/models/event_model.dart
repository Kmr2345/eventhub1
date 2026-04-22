class EventModel {
  final String id;
  final String title;
  final String titleRu;
  final String titleKz;
  final String description;
  final String descriptionRu;
  final String descriptionKz;
  final String date;
  final String time;
  final String location;
  final String locationRu;
  final String locationKz;
  final String category;
  final String image;
  final int capacity;
  int registered;
  final String organizerId;
  final String organizerName;
  double rating;
  int totalRatings;
  bool isFavorite;

  EventModel({
    required this.id,
    required this.title,
    required this.titleRu,
    required this.titleKz,
    required this.description,
    required this.descriptionRu,
    required this.descriptionKz,
    required this.date,
    required this.time,
    required this.location,
    required this.locationRu,
    required this.locationKz,
    required this.category,
    required this.image,
    required this.capacity,
    required this.registered,
    required this.organizerId,
    required this.organizerName,
    required this.rating,
    required this.totalRatings,
    this.isFavorite = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String _str(dynamic v, String fallback) => (v is String && v.isNotEmpty) ? v : fallback;
    int _int(dynamic v, int fallback) => v is int ? v : (v is num ? v.toInt() : fallback);
    double _double(dynamic v, double fallback) => v is double ? v : (v is num ? v.toDouble() : fallback);
    bool _bool(dynamic v, bool fallback) => v is bool ? v : fallback;

    final title = _str(json['title'], '');
    final desc = _str(json['description'], '');
    final loc = _str(json['location'], '');

    return EventModel(
      id: _str(json['id'] ?? json['_id'], ''),
      title: title,
      titleRu: _str(json['titleRu'] ?? json['title_ru'], title),
      titleKz: _str(json['titleKz'] ?? json['title_kz'], title),
      description: desc,
      descriptionRu: _str(json['descriptionRu'] ?? json['description_ru'], desc),
      descriptionKz: _str(json['descriptionKz'] ?? json['description_kz'], desc),
      date: _str(json['date'], ''),
      time: _str(json['time'], ''),
      location: loc,
      locationRu: _str(json['locationRu'] ?? json['location_ru'], loc),
      locationKz: _str(json['locationKz'] ?? json['location_kz'], loc),
      category: _str(json['category'], ''),
      image: _str(json['image'], ''),
      capacity: _int(json['capacity'], 0),
      registered: _int(json['registered'], 0),
      organizerId: _str(json['organizerId'] ?? json['organizer_id'], ''),
      organizerName: _str(json['organizerName'] ?? json['organizer_name'], ''),
      rating: _double(json['rating'], 0),
      totalRatings: _int(json['totalRatings'] ?? json['total_ratings'], 0),
      isFavorite: _bool(json['isFavorite'] ?? json['is_favorite'], false),
    );
  }

  String getTitle(String lang) => lang == 'ru' ? titleRu : lang == 'kz' ? titleKz : title;
  String getLocation(String lang) => lang == 'ru' ? locationRu : lang == 'kz' ? locationKz : location;
  String getDescription(String lang) => lang == 'ru' ? descriptionRu : lang == 'kz' ? descriptionKz : description;

  int get spotsLeft => capacity - registered;
  double get fillPercent => registered / capacity;

  EventModel copyWith({
    String? title, String? titleRu, String? titleKz,
    String? description, String? descriptionRu, String? descriptionKz,
    String? date, String? time,
    String? location, String? locationRu, String? locationKz,
    String? category, int? capacity, bool? isFavorite,
  }) => EventModel(
    id: id,
    title: title ?? this.title,
    titleRu: titleRu ?? this.titleRu,
    titleKz: titleKz ?? this.titleKz,
    description: description ?? this.description,
    descriptionRu: descriptionRu ?? this.descriptionRu,
    descriptionKz: descriptionKz ?? this.descriptionKz,
    date: date ?? this.date,
    time: time ?? this.time,
    location: location ?? this.location,
    locationRu: locationRu ?? this.locationRu,
    locationKz: locationKz ?? this.locationKz,
    category: category ?? this.category,
    image: image,
    capacity: capacity ?? this.capacity,
    registered: registered,
    organizerId: organizerId,
    organizerName: organizerName,
    rating: rating,
    totalRatings: totalRatings,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

class UserModel {
  final String name;
  final String email;
  final String role; // 'student' | 'organizer'

  const UserModel({required this.name, required this.email, required this.role});

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
