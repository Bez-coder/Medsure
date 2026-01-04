import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugSearchService {
  static const String _fdaApiBase = 'https://api.fda.gov/drug/label.json';

  Future<Map<String, dynamic>> searchDrug(String medicineName) async {
    try {
      // Build the openFDA API URL
      final url = Uri.parse(
        '$_fdaApiBase?search=openfda.generic_name:"$medicineName"&limit=1'
      );

      // Make the API request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if results exist
        if (data['results'] != null && data['results'].isNotEmpty) {
          final drug = data['results'][0];
          final openfda = drug['openfda'] ?? {};

          return {
            'found': true,
            'data': {
              'genericName': _getFirstOrDefault(openfda['generic_name'], medicineName),
              'purpose': _getFirstOrDefault(drug['purpose'], 'Not available'),
              'dosage': _getFirstOrDefault(drug['dosage_and_administration'], 'Not available'),
              'warnings': _getFirstOrDefault(drug['warnings'], 'Not available'),
              'sideEffects': _getFirstOrDefault(drug['adverse_reactions'], 'Not available'),
              'authorizationStatus': 'Approved by FDA',
            },
          };
        } else {
          // No results found
          return {
            'found': false,
            'message': 'No drug information found for "$medicineName"',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'found': false,
          'message': 'Drug not found in FDA database',
        };
      } else {
        throw Exception('FDA API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching for drug: $e');
    }
  }

  /// Helper method to get first element from array or return default
  String _getFirstOrDefault(dynamic value, String defaultValue) {
    if (value is List && value.isNotEmpty) {
      return value[0].toString();
    }
    return defaultValue;
  }
}
