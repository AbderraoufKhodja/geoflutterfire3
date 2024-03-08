// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire3/geoflutterfire3.dart';

void main() {
  test('description', () {
    final cities = [
      (48.8566, 2.3522, "paris"),
      (43.2965, 5.3698, "marseille"),
      (45.75, 4.85, "lyon"),
      (43.6043, 1.4437, "toulouse"),
      (43.7102, 7.2620, "nice"),
      (47.2186, -1.5536, "nantes"),
      (48.5734, 7.7521, "strasbourg"),
      (43.6108, 3.8767, "montpellier"),
      (44.8378, -0.5792, "bordeaux"),
      (50.6292, 3.0573, "lille"),
      (48.1173, -1.6778, "rennes"),
      (49.2583, 4.0317, "reims"),
      (49.4944, 0.1078, "leHavre"),
      (49.0360, 2.0807, "cergyPontoise"),
      (45.4397, 4.3872, "saintEtienne"),
      (43.1242, 5.9280, "toulon"),
      (47.4784, -0.5632, "angers"),
      (45.1885, 5.7245, "grenoble"),
      (47.3220, 5.0415, "dijon"),
      (43.5297, 5.4474, "aixEnProvence"),
    ];

    final cityGeoFirePoint = GeoFirePoint(cities[1].$1, cities[1].$2);
    final marseilleData = cityGeoFirePoint.regionalData(
      consolLogMemoryUse: true,
    );

    cities.forEach((city) {
      final cityGeoPoint = GeoFirePoint(city.$1, city.$2);
      final data = cityGeoPoint.regionalData(
          mediumRMC: RegionMappingConfig(
        blockSpacing: BlockSpacing.five,
        numSpacedBlock: 60,
      ));

      // Distance between city and marseille
      final dist =
          cityGeoPoint.distance(lat: cityGeoFirePoint.latitude, lng: cityGeoFirePoint.longitude);

      final blockNumber = GeoFirePoint.setBlockNum(
        dist,
        Precision.medium,
        BlockSpacing.five,
      );

      // GeoHashes inclusion
      final List marseilleHashesFilter = marseilleData['data']['precision4']["block2"];
      final List cityHashes = data['data']['precision4']["block${blockNumber}"];

      final isCityInMarseille = cityHashes.any((hash) => marseilleHashesFilter.contains(hash));

      print(
          'city: ${city.$3}, distance: $dist, isCityInMarseille: $isCityInMarseille, blockNumber: $blockNumber');
    });
  });
}
