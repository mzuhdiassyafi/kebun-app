import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// Models (placeholder data for the web preview)
// ---------------------------------------------------------------------------

enum ZoneKind { house, crop, livestock, water, storage }

enum Severity { kritis, peringatan, info }

class Activity {
  Activity(this.title, this.subtitle, this.icon, this.tint, this.soft);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color soft;
}

class Zone {
  Zone({
    required this.id,
    required this.name,
    required this.kind,
    required this.mapRect,
    required this.pin,
    this.number = 1,
    this.crop,
    this.variety,
    this.area = '0,4 ha',
    this.planted = '—',
    this.harvestIn,
    this.sensors = 2,
    this.moisture = 70,
    this.temp = 28,
    this.light = 800,
    this.ph = 6.5,
    this.warning = false,
    this.summaryOverride,
    List<double>? moisture7,
    List<Activity>? activities,
  })  : moisture7 = moisture7 ?? [66, 70, 68, 63, 60, 65, 70],
        activities = activities ?? [];

  final String id;
  final String name;
  final ZoneKind kind;
  final Rect mapRect; // in Figma map coordinates (358 x 430)
  final Offset pin; // label pin position in map coordinates
  final int number;
  final String? crop;
  final String? variety;
  final String area;
  final String planted;
  final String? harvestIn;
  int sensors;
  double moisture;
  double temp;
  int light;
  double ph;
  bool warning;
  final String? summaryOverride;
  final List<double> moisture7;
  final List<Activity> activities;

  String get status => warning ? 'Perhatian' : 'Normal';
  String get summary => summaryOverride ?? '$sensors sensor · Kelembapan ${moisture.round()}%';
  IconData get icon => switch (kind) {
        ZoneKind.livestock => LucideIcons.pawPrint,
        ZoneKind.water => LucideIcons.droplet,
        ZoneKind.house => LucideIcons.house,
        ZoneKind.storage => LucideIcons.warehouse,
        ZoneKind.crop => LucideIcons.sprout,
      };
  Color get iconTint => switch (kind) {
        ZoneKind.livestock => KColors.soil,
        ZoneKind.water => KColors.water,
        ZoneKind.storage => KColors.textSecondary,
        _ => KColors.primary,
      };
  Color get iconSoft => switch (kind) {
        ZoneKind.livestock => KColors.soilSoft,
        ZoneKind.water => KColors.waterSoft,
        ZoneKind.storage => KColors.subtle,
        _ => KColors.primarySoft,
      };
}

class AlertItem {
  AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
    this.day = 'Hari ini',
    this.zoneId,
    this.read = false,
  });
  final String id;
  final String title;
  final String description;
  final String time;
  final Severity severity;
  final String day;
  final String? zoneId;
  bool read;
}

class Harvest {
  Harvest({required this.crop, required this.zone, required this.date, required this.kg, required this.grade, required this.category});
  final String crop;
  final String zone;
  final String date;
  final double kg;
  final String grade;
  final String category; // Tomat / Sayur / Jagung

  Color get soft => switch (category) {
        'Tomat' => KColors.dangerSoft,
        'Sayur' => KColors.primarySoft,
        _ => KColors.sunSoft,
      };
  Color get tint => switch (category) {
        'Tomat' => KColors.danger,
        'Sayur' => KColors.primary,
        _ => KColors.sun,
      };
}

class UpcomingHarvest {
  UpcomingHarvest(this.day, this.month, this.crop, this.zone, this.estimate);
  final int day;
  final String month;
  final String crop;
  final String zone;
  final String estimate;
}

class Animal {
  Animal({required this.name, required this.breed, required this.tag, required this.age, required this.health, required this.category, this.note});
  final String name;
  final String breed;
  final String tag;
  final String age;
  int health;
  final String category;
  final String? note;
}

class AnimalCategory {
  const AnimalCategory(this.label, this.image, this.count);
  final String label;
  final String image;
  final int count;
}

class FeedingSlot {
  FeedingSlot(this.label, this.time, this.food, this.done);
  final String label;
  final String time;
  final String food;
  bool done;
}

class Farm {
  Farm(this.name, this.area, this.zones, this.sensors);
  String name;
  final String area;
  final int zones;
  final int sensors;
}

class Report {
  Report(this.title, this.meta);
  final String title;
  final String meta;
  double progress = 0; // 0 = not started, 1 = done
}

// ---------------------------------------------------------------------------
// App state
// ---------------------------------------------------------------------------

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  String userName = 'Zuhdi';
  bool loggedIn = true;

  late List<Farm> farms;
  int activeFarm = 0;
  Farm get farm => farms[activeFarm];

  late List<Zone> zones;
  late List<AlertItem> alerts;
  late List<Harvest> harvests;
  late List<UpcomingHarvest> upcoming;
  late List<Animal> animals;
  late List<FeedingSlot> feeding;
  late List<Report> reports;

  bool criticalBannerVisible = true;
  bool tankRefilled = false;
  bool pushNotif = true;
  double moistureThreshold = 45;
  String wateringSchedule = '06.00, 16.00';
  String unitLang = 'kg · Indonesia';
  final Set<String> wateringNow = {};

  Zone zone(String id) => zones.firstWhere((z) => z.id == id);

  int get unreadCount => alerts.where((a) => !a.read).length + (criticalBannerVisible && !tankRefilled ? 1 : 0);

  double get monthTotal => harvests.where((h) => h.date.endsWith('Nov')).fold(0.0, (s, h) => s + h.kg) + _baseMonth;
  // Harvests before the visible history (keeps the Figma total 1.280 kg).
  final double _baseMonth = 885;

  double categoryTotal(String c) {
    final base = {'Tomat': 520.0, 'Sayur': 365.0, 'Jagung': 0.0}[c] ?? 0;
    return base + harvests.where((h) => h.category == c && h.date.endsWith('Nov')).fold(0.0, (s, h) => s + h.kg);
  }

  int get animalTotal => 48;
  int get healthyZones => zones.where((z) => !z.warning).length;

  void setFarm(int i) {
    activeFarm = i;
    notifyListeners();
  }

  void addFarm(String name, String area) {
    farms.add(Farm(name, area, 1, 0));
    notifyListeners();
  }

  void rename(String name) {
    userName = name;
    notifyListeners();
  }

  void markRead(AlertItem a, [bool read = true]) {
    a.read = read;
    notifyListeners();
  }

  void markAllRead() {
    for (final a in alerts) {
      a.read = true;
    }
    notifyListeners();
  }

  AlertItem? removeAlert(AlertItem a) {
    alerts.remove(a);
    notifyListeners();
    return a;
  }

  void restoreAlert(AlertItem a, int index) {
    alerts.insert(index.clamp(0, alerts.length), a);
    notifyListeners();
  }

  void snoozeBanner(bool snooze) {
    criticalBannerVisible = !snooze;
    notifyListeners();
  }

  void refillTank() {
    tankRefilled = true;
    criticalBannerVisible = false;
    alerts.insert(
      0,
      AlertItem(id: 'tank-ok', title: 'Tandon air diisi', description: 'Tandon kembali 100% (2.000 L). Penyiraman sore aman.', time: 'Baru saja', severity: Severity.info, read: true),
    );
    notifyListeners();
  }

  void addHarvest(Harvest h) {
    harvests.insert(0, h);
    notifyListeners();
  }

  void toggleFeeding(FeedingSlot s) {
    s.done = !s.done;
    notifyListeners();
  }

  void addAnimal(Animal a) {
    animals.insert(0, a);
    notifyListeners();
  }

  void setPush(bool v) {
    pushNotif = v;
    notifyListeners();
  }

  void setThreshold(double v) {
    moistureThreshold = v;
    for (final z in zones.where((z) => z.kind == ZoneKind.crop)) {
      z.warning = z.moisture < v;
    }
    notifyListeners();
  }

  void setSchedule(String v) {
    wateringSchedule = v;
    notifyListeners();
  }

  void setUnitLang(String v) {
    unitLang = v;
    notifyListeners();
  }

  void addActivity(Zone z, Activity a) {
    z.activities.insert(0, a);
    notifyListeners();
  }

  Future<void> waterNow(Zone z) async {
    if (wateringNow.contains(z.id)) return;
    wateringNow.add(z.id);
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    wateringNow.remove(z.id);
    z.moisture = (z.moisture + 8).clamp(0, 95);
    z.moisture7[z.moisture7.length - 1] = z.moisture;
    z.warning = z.kind == ZoneKind.crop && z.moisture < moistureThreshold;
    z.activities.insert(0, Activity('Penyiraman manual', 'Baru saja · 10 menit', LucideIcons.droplet, KColors.water, KColors.waterSoft));
    notifyListeners();
  }

  Future<void> download(Report r) async {
    if (r.progress > 0) return;
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      r.progress = i / 10;
      notifyListeners();
    }
  }

  void touch() => notifyListeners();

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  void login() {
    loggedIn = true;
    notifyListeners();
  }

  void _seed() {
    farms = [Farm('Kebun Lembah Hijau', '2,4 ha', 7, 12), Farm('Kebun Belakang Rumah', '0,3 ha', 2, 3)];

    zones = [
      Zone(
        id: 'sayur',
        name: 'Lahan Sayur',
        number: 3,
        kind: ZoneKind.crop,
        crop: 'Selada & Bayam',
        variety: 'Selada Keriting',
        area: '0,5 ha',
        planted: '2 Okt',
        harvestIn: '±7 hari',
        sensors: 2,
        moisture: 38,
        temp: 30,
        light: 910,
        ph: 6.1,
        warning: true,
        mapRect: const Rect.fromLTWH(14, 171, 116, 120),
        pin: const Offset(12, 168),
        moisture7: [52, 49, 44, 41, 39, 42, 38],
        activities: [
          Activity('Penyiraman otomatis', 'Hari ini, 06.00 · 10 menit', LucideIcons.droplet, KColors.water, KColors.waterSoft),
          Activity('Kelembapan di bawah batas', 'Hari ini, 09.40', LucideIcons.triangleAlert, KColors.warning, KColors.warningSoft),
          Activity('Penyiangan gulma', '2 hari lalu · oleh Rudi', LucideIcons.leaf, KColors.primary, KColors.primarySoft),
        ],
      ),
      Zone(
        id: 'tomat',
        name: 'Lahan Tomat',
        number: 2,
        kind: ZoneKind.crop,
        crop: 'Tomat',
        variety: 'Tomat Servo',
        area: '0,6 ha',
        planted: '12 Sep',
        harvestIn: '±18 hari',
        sensors: 3,
        moisture: 72,
        temp: 29,
        light: 840,
        ph: 6.4,
        mapRect: const Rect.fromLTWH(154, 16, 189, 131),
        pin: const Offset(160, 12),
        moisture7: [62, 66, 63, 59, 56, 61, 72],
        activities: [
          Activity('Penyiraman otomatis', 'Hari ini, 06.00 · 15 menit', LucideIcons.droplet, KColors.water, KColors.waterSoft),
          Activity('Pemupukan NPK 16-16-16', 'Kemarin · oleh Rudi', LucideIcons.leaf, KColors.primary, KColors.primarySoft),
          Activity('Cek hama ulat buah', '3 hari lalu · selesai', LucideIcons.triangleAlert, KColors.warning, KColors.warningSoft),
        ],
      ),
      Zone(
        id: 'ternak',
        name: 'Area Ternak',
        number: 5,
        kind: ZoneKind.livestock,
        area: '0,5 ha',
        sensors: 2,
        moisture: 55,
        temp: 27,
        light: 760,
        ph: 7.0,
        summaryOverride: '48 hewan · Kandang 27°C',
        mapRect: const Rect.fromLTWH(16, 315, 182, 100),
        pin: const Offset(12, 312),
      ),
      Zone(
        id: 'jagung',
        name: 'Lahan Jagung',
        number: 4,
        kind: ZoneKind.crop,
        crop: 'Jagung',
        variety: 'Jagung Manis',
        area: '0,5 ha',
        planted: '20 Agu',
        harvestIn: '±40 hari',
        sensors: 3,
        moisture: 64,
        temp: 31,
        light: 980,
        ph: 6.8,
        mapRect: const Rect.fromLTWH(154, 172, 189, 118),
        pin: const Offset(160, 168),
        moisture7: [60, 62, 65, 63, 61, 66, 64],
        activities: [
          Activity('Penyiraman otomatis', 'Hari ini, 06.00 · 12 menit', LucideIcons.droplet, KColors.water, KColors.waterSoft),
          Activity('Baterai sensor pH lemah', 'Kemarin · 15%', LucideIcons.batteryLow, KColors.warning, KColors.warningSoft),
        ],
      ),
      Zone(
        id: 'rumah',
        name: 'Rumah Kebun',
        number: 1,
        kind: ZoneKind.house,
        crop: 'Kebun bibit',
        variety: 'Bibit Cabai & Tomat',
        area: '0,1 ha',
        planted: '1 Nov',
        harvestIn: 'Pindah tanam ±10 hari',
        sensors: 1,
        moisture: 70,
        temp: 28,
        light: 650,
        ph: 6.6,
        mapRect: const Rect.fromLTWH(16, 16, 112, 131),
        pin: const Offset(12, 12),
        moisture7: [68, 71, 69, 70, 67, 72, 70],
        activities: [Activity('Semai bibit cabai', '1 Nov · 120 polybag', LucideIcons.sprout, KColors.primary, KColors.primarySoft)],
      ),
      Zone(
        id: 'kolam',
        name: 'Kolam',
        number: 6,
        kind: ZoneKind.water,
        sensors: 1,
        moisture: 100,
        temp: 26,
        light: 800,
        ph: 7.2,
        summaryOverride: 'Tandon 12% · Kolam 80%',
        mapRect: const Rect.fromLTWH(214, 315, 129, 55),
        pin: const Offset(222, 312),
      ),
      Zone(
        id: 'gudang',
        name: 'Gudang',
        number: 7,
        kind: ZoneKind.storage,
        sensors: 0,
        moisture: 0,
        temp: 29,
        light: 300,
        ph: 7,
        summaryOverride: 'Stok pakan 320 kg · Pupuk 6 sak',
        mapRect: const Rect.fromLTWH(214, 374, 129, 42),
        pin: const Offset(222, 372),
      ),
    ];

    alerts = [
      AlertItem(id: 'a1', title: 'Kelembapan tanah rendah', description: 'Lahan Sayur turun ke 38%, di bawah batas 45%.', time: '10 mnt', severity: Severity.peringatan, zoneId: 'sayur'),
      AlertItem(id: 'a2', title: 'Kesehatan Gendut menurun', description: 'SAPI-007 kurang makan 2 hari. Cek kondisi di kandang.', time: '2 jam', severity: Severity.peringatan, zoneId: 'ternak'),
      AlertItem(id: 'a3', title: 'Pakan sore sudah diberikan', description: 'Area Ternak, 48 ekor. Dicatat oleh Rudi.', time: '3 jam', severity: Severity.info, zoneId: 'ternak'),
      AlertItem(id: 'a4', title: 'Baterai sensor lemah', description: 'Sensor pH di Lahan Jagung tersisa 15%. Ganti baterai minggu ini.', time: '1 hr', severity: Severity.info, day: 'Kemarin', zoneId: 'jagung', read: true),
      AlertItem(id: 'a5', title: 'Panen tomat dicatat', description: '120 kg grade A dari Lahan Tomat.', time: '1 hr', severity: Severity.info, day: 'Kemarin', zoneId: 'tomat', read: true),
    ];

    harvests = [
      Harvest(crop: 'Tomat Servo', zone: 'Lahan Tomat', date: '5 Nov', kg: 120, grade: 'Grade A', category: 'Tomat'),
      Harvest(crop: 'Selada keriting', zone: 'Lahan Sayur', date: '3 Nov', kg: 45, grade: 'Grade A', category: 'Sayur'),
      Harvest(crop: 'Jagung manis', zone: 'Lahan Jagung', date: '1 Nov', kg: 230, grade: 'Grade B', category: 'Jagung'),
      Harvest(crop: 'Tomat Servo', zone: 'Lahan Tomat', date: '28 Okt', kg: 140, grade: 'Grade A', category: 'Tomat'),
      Harvest(crop: 'Bayam', zone: 'Lahan Sayur', date: '25 Okt', kg: 38, grade: 'Grade A', category: 'Sayur'),
    ];

    upcoming = [
      UpcomingHarvest(14, 'Nov', 'Selada', 'Lahan Sayur', '±60 kg'),
      UpcomingHarvest(25, 'Nov', 'Tomat Servo', 'Lahan Tomat', '±180 kg'),
      UpcomingHarvest(16, 'Des', 'Jagung manis', 'Lahan Jagung', '±250 kg'),
    ];

    animals = [
      Animal(name: 'Bella', breed: 'Holstein Friesian', tag: 'SAPI-014', age: '3 tahun', health: 96, category: 'Sapi'),
      Animal(name: 'Melati', breed: 'Jersey', tag: 'SAPI-021', age: '4 tahun', health: 91, category: 'Sapi'),
      Animal(name: 'Gendut', breed: 'Brahman', tag: 'SAPI-007', age: '2,5 tahun', health: 78, category: 'Sapi', note: 'Kurang makan 2 hari'),
      Animal(name: 'Mawar', breed: 'Limousin', tag: 'SAPI-016', age: '5 tahun', health: 93, category: 'Sapi', note: 'Bunting 6 bulan'),
      Animal(name: 'Kenanga', breed: 'Simmental', tag: 'SAPI-018', age: '3 tahun', health: 89, category: 'Sapi'),
      Animal(name: 'Jago', breed: 'Kampung', tag: 'AYAM-003', age: '1 tahun', health: 94, category: 'Ayam'),
      Animal(name: 'Blorok', breed: 'Kampung', tag: 'AYAM-011', age: '8 bulan', health: 90, category: 'Ayam'),
      Animal(name: 'Cemani', breed: 'Ayam Cemani', tag: 'AYAM-015', age: '1,5 tahun', health: 82, category: 'Ayam'),
      Animal(name: 'Kapas', breed: 'Garut', tag: 'DOMBA-002', age: '2 tahun', health: 95, category: 'Domba'),
      Animal(name: 'Wulan', breed: 'Merino', tag: 'DOMBA-005', age: '3 tahun', health: 88, category: 'Domba', note: 'Bunting 3 bulan'),
      Animal(name: 'Bimo', breed: 'Etawa', tag: 'KMB-001', age: '2 tahun', health: 92, category: 'Kambing'),
      Animal(name: 'Lili', breed: 'Saanen', tag: 'KMB-004', age: '1 tahun', health: 76, category: 'Kambing', note: 'Pincang kaki kiri'),
    ];

    feeding = [
      FeedingSlot('Pagi', '06.00', 'Hay & silase', true),
      FeedingSlot('Siang', '12.00', 'Konsentrat', true),
      FeedingSlot('Sore', '16.30', 'Rumput segar', false),
    ];

    reports = [Report('Laporan mingguan', '31 Okt – 6 Nov · PDF, 1,2 MB'), Report('Laporan bulanan Oktober', '1 – 31 Okt · PDF, 3,4 MB')];
  }
}

const animalCategories = [
  AnimalCategory('Sapi', 'assets/images/sapi.png', 18),
  AnimalCategory('Ayam', 'assets/images/ayam.png', 20),
  AnimalCategory('Domba', 'assets/images/domba.png', 6),
  AnimalCategory('Kambing', 'assets/images/kambing.png', 4),
];

/// Gives every widget below it access to [AppState] and rebuilds on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
