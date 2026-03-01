class KycStorage {
  static String? ktpImgPath;
  static String? selfieImgPath;
  static double? latitude;
  static double? longitude;

  static void clearData() {
    ktpImgPath = null;
    selfieImgPath = null;
    latitude = null;
    longitude = null;
  }
}
