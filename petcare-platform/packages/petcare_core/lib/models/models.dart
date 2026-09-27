enum UserRole { petOwner, provider, admin }

enum ServiceType { walking, grooming, training, boarding, vetVisit, petSitting }

enum BookingStatus { requested, accepted, rejected, cancelled, inProgress, completed }

enum PaymentStatus { pending, paid, failed, refunded }

enum ComplaintCategory { serviceQuality, safety, payment, behavior, appBug, other }

enum ComplaintStatus { open, inProgress, resolved, closed }

extension ComplaintCategoryLabel on ComplaintCategory {
  String get label {
    switch (this) {
      case ComplaintCategory.serviceQuality:
        return 'Service quality';
      case ComplaintCategory.safety:
        return 'Safety concern';
      case ComplaintCategory.payment:
        return 'Payment issue';
      case ComplaintCategory.behavior:
        return 'Behavior / conduct';
      case ComplaintCategory.appBug:
        return 'App problem';
      case ComplaintCategory.other:
        return 'Other';
    }
  }
}

extension ComplaintStatusLabel on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.inProgress:
        return 'In progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }
}

class Complaint {
  final String id;
  final ComplaintCategory category;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final String? adminNote;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'],
        category: ComplaintCategory.values.byName(_toCamel(json['category'])),
        subject: json['subject'],
        description: json['description'],
        status: ComplaintStatus.values.byName(_toCamel(json['status'])),
        adminNote: json['adminNote'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

extension ServiceTypeLabel on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.walking:
        return 'Walking';
      case ServiceType.grooming:
        return 'Grooming';
      case ServiceType.training:
        return 'Training';
      case ServiceType.boarding:
        return 'Boarding';
      case ServiceType.vetVisit:
        return 'Vet Visit';
      case ServiceType.petSitting:
        return 'Pet Sitting';
    }
  }
}

class AppUser {
  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final String? email;
  final String? profilePhoto;

  AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    this.email,
    this.profilePhoto,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        role: UserRole.values.byName(_toCamel(json['role'])),
        name: json['name'],
        phone: json['phone'],
        email: json['email'],
        profilePhoto: json['profilePhoto'],
      );
}

class Pet {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final int? age;
  final String? notes;
  final String? photoUrl;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.age,
    this.notes,
    this.photoUrl,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'],
        name: json['name'],
        species: json['species'],
        breed: json['breed'],
        age: json['age'],
        notes: json['notes'],
        photoUrl: json['photoUrl'],
      );
}

class Booking {
  final String id;
  final ServiceType serviceType;
  final BookingStatus status;
  final DateTime scheduledAt;
  final String addressText;
  final double lat;
  final double lng;
  final int priceInr;
  final String? notes;
  final double? safeZoneLat;
  final double? safeZoneLng;
  final int? safeZoneRadiusM;
  final PaymentStatus? paymentStatus;
  final bool hasReview;
  // Denormalized display fields, filled in from whichever nested object
  // GET /bookings/mine includes (pet, and provider or petOwner depending
  // on which app is asking).
  final String? petName;
  final String? otherPartyName;
  final String? otherPartyPhone;

  Booking({
    required this.id,
    required this.serviceType,
    required this.status,
    required this.scheduledAt,
    required this.addressText,
    required this.lat,
    required this.lng,
    required this.priceInr,
    this.notes,
    this.safeZoneLat,
    this.safeZoneLng,
    this.safeZoneRadiusM,
    this.paymentStatus,
    this.hasReview = false,
    this.petName,
    this.otherPartyName,
    this.otherPartyPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final otherParty = json['provider'] ?? json['petOwner'];
    final otherUser = otherParty?['user'];
    final paymentJson = json['payment'];
    return Booking(
      id: json['id'],
      serviceType: ServiceType.values.byName(_toCamel(json['serviceType'])),
      status: BookingStatus.values.byName(_toCamel(json['status'])),
      scheduledAt: DateTime.parse(json['scheduledAt']),
      addressText: json['addressText'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      priceInr: json['priceInr'],
      notes: json['notes'],
      safeZoneLat: (json['safeZoneLat'] as num?)?.toDouble(),
      safeZoneLng: (json['safeZoneLng'] as num?)?.toDouble(),
      safeZoneRadiusM: json['safeZoneRadiusM'],
      paymentStatus: paymentJson != null
          ? PaymentStatus.values.byName(_toCamel(paymentJson['status']))
          : null,
      hasReview: json['review'] != null,
      petName: json['pet']?['name'],
      otherPartyName: otherUser?['name'],
      otherPartyPhone: otherUser?['phone'],
    );
  }
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.inProgress:
        return 'In progress';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

class ProviderServiceOffering {
  final ServiceType serviceType;
  final int priceInr;
  final int durationMin;

  ProviderServiceOffering({required this.serviceType, required this.priceInr, required this.durationMin});

  factory ProviderServiceOffering.fromJson(Map<String, dynamic> json) => ProviderServiceOffering(
        serviceType: ServiceType.values.byName(_toCamel(json['serviceType'])),
        priceInr: json['priceInr'],
        durationMin: json['durationMin'],
      );
}

class ProviderSummary {
  final String id; // ProviderProfile id — this is what bookings reference
  final String name;
  final String? profilePhoto;
  final double ratingAvg;
  final int ratingCount;
  final List<ProviderServiceOffering> servicesOffered;

  ProviderSummary({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.ratingAvg,
    required this.ratingCount,
    required this.servicesOffered,
  });

  factory ProviderSummary.fromJson(Map<String, dynamic> json) => ProviderSummary(
        id: json['id'],
        name: json['user']['name'],
        profilePhoto: json['user']['profilePhoto'],
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        ratingCount: json['ratingCount'],
        servicesOffered: (json['servicesOffered'] as List)
            .map((e) => ProviderServiceOffering.fromJson(e))
            .toList(),
      );

  /// Price for a specific service this provider offers, if any.
  ProviderServiceOffering? offeringFor(ServiceType type) =>
      servicesOffered.where((s) => s.serviceType == type).firstOrNull;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// Converts BACKEND_STYLE / SCREAMING_SNAKE enum strings to Dart camelCase.
String _toCamel(String value) {
  final parts = value.toLowerCase().split('_');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// The inverse of [_toCamel] — converts a Dart enum's camelCase `.name` to
/// the backend's SCREAMING_SNAKE_CASE, e.g. `serviceQuality` -> `SERVICE_QUALITY`.
/// Used whenever an enum value is sent in a request body.
String backendEnumName(String camelName) {
  final buffer = StringBuffer();
  for (int i = 0; i < camelName.length; i++) {
    final char = camelName[i];
    if (char == char.toUpperCase() && char != char.toLowerCase() && i != 0) {
      buffer.write('_');
    }
    buffer.write(char.toUpperCase());
  }
  return buffer.toString();
}
