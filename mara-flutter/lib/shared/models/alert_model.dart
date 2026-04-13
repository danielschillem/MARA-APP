class AlertModel {
  final String? id;
  final String reference;
  final String typeId;
  final String victimType;
  final String severity;
  final String status;
  final double lat;
  final double lng;
  final String zone;
  final bool isOngoing;
  final String channel;
  final bool isAnonymous;
  final bool hasPhoto;
  final bool hasAudio;
  final String notes;
  final DateTime createdAt;

  const AlertModel({
    this.id,
    required this.reference,
    required this.typeId,
    required this.victimType,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    required this.zone,
    required this.isOngoing,
    required this.channel,
    required this.isAnonymous,
    required this.hasPhoto,
    required this.hasAudio,
    required this.notes,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id']?.toString(),
        reference: json['reference'] ?? '',
        typeId: json['type_id'] ?? '',
        victimType: json['victim_type'] ?? '',
        severity: json['severity'] ?? 'medium',
        status: json['status'] ?? 'new',
        lat: (json['lat'] ?? 0.0).toDouble(),
        lng: (json['lng'] ?? 0.0).toDouble(),
        zone: json['zone'] ?? '',
        isOngoing: json['is_ongoing'] ?? false,
        channel: json['channel'] ?? 'app',
        isAnonymous: json['is_anonymous'] ?? true,
        hasPhoto: json['has_photo'] ?? false,
        hasAudio: json['has_audio'] ?? false,
        notes: json['notes'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'type_id': typeId,
        'victim_type': victimType,
        'lat': lat,
        'lng': lng,
        'zone': zone,
        'is_ongoing': isOngoing,
        'channel': channel,
        'is_anonymous': isAnonymous,
        'has_photo': hasPhoto,
        'has_audio': hasAudio,
        'notes': notes,
      };
}

const Map<String, Map<String, String>> kViolenceTypes = {
  'physical': {'label': 'Violence physique', 'sub': 'Coups, blessures, agression', 'color': 'B5103C'},
  'sexual': {'label': 'Violence sexuelle', 'sub': 'Agression, harcèlement sexuel', 'color': '7A3B8C'},
  'verbal': {'label': 'Violence verbale', 'sub': 'Menaces, insultes, intimidation', 'color': 'B87A1A'},
  'psych': {'label': 'Violence psychologique', 'sub': 'Contrôle, humiliation, isolement', 'color': '1A2E4A'},
  'domestic': {'label': 'Violence domestique', 'sub': 'Au sein du foyer ou de la famille', 'color': 'C85A18'},
  'neglect': {'label': 'Négligence grave', 'sub': 'Abandon, privation de soins', 'color': '2D6A4F'},
};

const Map<String, Map<String, String>> kVictimTypes = {
  'woman': {'label': 'Femme adulte'},
  'child': {'label': 'Enfant'},
  'man': {'label': 'Homme adulte'},
  'elderly': {'label': 'Personne âgée'},
  'unknown': {'label': 'Inconnu(e)'},
};
