import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': _en,
    'id_ID': _id,
  };

  // ── English ────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // Navigation / Layout
    'nav_dashboard': 'Dashboard',
    'nav_analytics': 'Analytics',
    'nav_assistant': 'Assistant',
    'nav_system': 'System',

    // System Page
    'system_title': 'System',
    'system_subtitle': 'Broker, AI & App Settings',
    'section_connection': 'Connection',
    'section_intelligence': 'Intelligence',
    'section_app': 'App',

    // Tiles
    'tile_broker': 'MQTT Broker',
    'tile_demo': 'Demo Mode',
    'tile_ai': 'AI Provider',
    'tile_theme': 'Theme & Appearance',
    'tile_language': 'Language',
    'tile_about': 'About & Version',

    // Language tile
    'language_title': 'App Language',
    'language_subtitle': 'Choose the display language for the app',
    'language_en': 'English',
    'language_id': 'Bahasa Indonesia',
    'language_saved': 'Language Updated',
    'language_saved_body': 'App language has been changed.',

    // Demo Mode
    'demo_title': 'Enable Demo Mode',
    'demo_body': 'Generates realistic simulated data for testing when the broker is disconnected.',
    'demo_on_title': 'Demo Mode Active',
    'demo_on_body': 'Simulated sensors have been loaded.',
    'demo_off_title': 'Real Mode Active',
    'demo_off_body': 'Simulated sensors cleared. Waiting for real MQTT data stream.',

    // Dashboard
    'dashboard_title': 'Dashboard',
    'dashboard_subtitle': 'IoT Devices',
    'dashboard_offline': 'Offline',
    'dashboard_scanning': 'Scanning for nodes...',
    'dashboard_no_devices': 'No devices found',
    'dashboard_add_device': 'Add a device',

    // Status
    'status_live': 'Live',
    'status_broker_ok': 'Broker OK',
    'status_offline': 'Offline',
    'status_connecting': 'Connecting…',

    // Broker settings
    'broker_save': 'Save Settings',
    'broker_connect': 'Connect Now',
    'broker_disconnect': 'Disconnect',
    'broker_saved': 'Broker Settings Saved',
    'broker_saved_body': 'Connection configuration updated successfully.',

    // AI settings
    'ai_save': 'Save Configuration',
    'ai_test': 'Test',
    'ai_settings_saved': 'Settings Saved',
    'ai_settings_saved_body': 'API Configuration updated successfully.',

    // Theme tile
    'theme_select': 'Select App Theme Mode',
    'theme_light': 'Light Mode',
    'theme_dark': 'Dark Mode',

    // About tile
    'about_title': 'IUNO IoT  ·  v1.0.1-beta.2',
    'about_view_source': 'View Source Code',

    // Device details
    'device_add_widget': 'Add Widget',
    'device_rename': 'Rename Device',
    'device_name_hint': 'Enter device name',
    'device_save': 'Save',
    'device_cancel': 'Cancel',
    'device_delete': 'Delete',
  };

  // ── Bahasa Indonesia ───────────────────────────────────────────
  static const Map<String, String> _id = {
    // Navigation / Layout
    'nav_dashboard': 'Dashboard',
    'nav_analytics': 'Analitik',
    'nav_assistant': 'Asisten',
    'nav_system': 'Sistem',

    // System Page
    'system_title': 'Sistem',
    'system_subtitle': 'Pengaturan Broker, AI & Aplikasi',
    'section_connection': 'Koneksi',
    'section_intelligence': 'Kecerdasan',
    'section_app': 'Aplikasi',

    // Tiles
    'tile_broker': 'Broker MQTT',
    'tile_demo': 'Mode Demo',
    'tile_ai': 'Penyedia AI',
    'tile_theme': 'Tema & Tampilan',
    'tile_language': 'Bahasa',
    'tile_about': 'Tentang & Versi',

    // Language tile
    'language_title': 'Bahasa Aplikasi',
    'language_subtitle': 'Pilih bahasa tampilan aplikasi',
    'language_en': 'English',
    'language_id': 'Bahasa Indonesia',
    'language_saved': 'Bahasa Diperbarui',
    'language_saved_body': 'Bahasa aplikasi telah berhasil diganti.',

    // Demo Mode
    'demo_title': 'Aktifkan Mode Demo',
    'demo_body': 'Menghasilkan data simulasi realistis untuk pengujian saat broker tidak terhubung.',
    'demo_on_title': 'Mode Demo Aktif',
    'demo_on_body': 'Sensor simulasi telah dimuat.',
    'demo_off_title': 'Mode Real Aktif',
    'demo_off_body': 'Sensor simulasi dihapus. Menunggu aliran data MQTT nyata.',

    // Dashboard
    'dashboard_title': 'Dashboard',
    'dashboard_subtitle': 'Perangkat IoT',
    'dashboard_offline': 'Offline',
    'dashboard_scanning': 'Memindai node...',
    'dashboard_no_devices': 'Tidak ada perangkat ditemukan',
    'dashboard_add_device': 'Tambah perangkat',

    // Status
    'status_live': 'Live',
    'status_broker_ok': 'Broker OK',
    'status_offline': 'Offline',
    'status_connecting': 'Menghubungkan…',

    // Broker settings
    'broker_save': 'Simpan Pengaturan',
    'broker_connect': 'Hubungkan Sekarang',
    'broker_disconnect': 'Putus Koneksi',
    'broker_saved': 'Pengaturan Broker Disimpan',
    'broker_saved_body': 'Konfigurasi koneksi berhasil diperbarui.',

    // AI settings
    'ai_save': 'Simpan Konfigurasi',
    'ai_test': 'Uji',
    'ai_settings_saved': 'Pengaturan Disimpan',
    'ai_settings_saved_body': 'Konfigurasi API berhasil diperbarui.',

    // Theme tile
    'theme_select': 'Pilih Mode Tema Aplikasi',
    'theme_light': 'Mode Terang',
    'theme_dark': 'Mode Gelap',

    // About tile
    'about_title': 'IUNO IoT  ·  v1.0.1-beta.2',
    'about_view_source': 'Lihat Kode Sumber',

    // Device details
    'device_add_widget': 'Tambah Widget',
    'device_rename': 'Ganti Nama Perangkat',
    'device_name_hint': 'Masukkan nama perangkat',
    'device_save': 'Simpan',
    'device_cancel': 'Batal',
    'device_delete': 'Hapus',
  };
}
