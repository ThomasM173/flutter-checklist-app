import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class WebScraper {
  static Future<String> getCessnaData() async {
    try {
      final url = "https://en.wikipedia.org/wiki/Cessna_172"; // ✅ Website URL
      final proxyUrl = "https://api.allorigins.win/get?url=$url"; // ✅ Bypass CORS

      final response = await http.get(Uri.parse(proxyUrl));

      if (response.statusCode == 200) {
        var document = html_parser.parse(response.body);
        var elements = document.querySelectorAll(".infobox tbody tr");

        List<String> info = [];
        for (var element in elements) {
          if (element.text.contains("Cruise speed") || element.text.contains("Range") || element.text.contains("Service ceiling")) {
            info.add(element.text.replaceAll("\n", " ")); // Clean data
          }
        }
        return info.isNotEmpty ? info.join("\n") : "No data available.";
      } else {
        return "Error: Failed to fetch aircraft data.";
      }
    } catch (e) {
      return "Error: Unable to connect to the website.";
    }
  }
}
