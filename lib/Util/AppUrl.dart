
class AppUrls {
  static const bool isTesting = false;

  static const String _localUrl = "http://localhost/Aquarelms";
  static const String _prodUrl = "https://aquare.co.in/mobileAPI/sachin/lms";

  static const String baseUrl = isTesting ? _localUrl : _prodUrl;
}