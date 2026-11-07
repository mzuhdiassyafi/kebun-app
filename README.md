# Kebun.io

Aplikasi Flutter untuk memantau kebun: zona tanaman, sensor, ternak, analitik, dan panen. Data masih placeholder.

**Web:** https://mzuhdiassyafi.github.io/kebun-app/

## Jalankan lokal

```bash
flutter pub get
flutter run -d chrome
```

## Struktur

- `lib/theme.dart`: warna, tipografi, radius
- `lib/data.dart`: model dan `AppState` (data placeholder)
- `lib/widgets.dart`: komponen bersama
- `lib/main.dart`: shell dan navigasi responsif (bottom nav di HP, rail di tablet, sidebar di desktop)
- `lib/screens/`: Beranda, Kebun, Detail Zona, Ternak, Notifikasi, Analitik, Panen, Profil

Setiap push ke `main` otomatis di-build dan di-deploy ke GitHub Pages lewat `.github/workflows/deploy.yml`.
