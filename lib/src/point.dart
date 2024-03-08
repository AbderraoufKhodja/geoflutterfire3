import 'package:cloud_firestore/cloud_firestore.dart';

import 'util.dart';

class GeoFirePoint {
  static Util _util = Util();
  double latitude, longitude;

  GeoFirePoint(this.latitude, this.longitude);

  /// return geographical distance between two Co-ordinates
  static double distanceBetween({required Coordinates to, required Coordinates from}) {
    return Util.distance(to, from);
  }

  /// return neighboring geo-hashes of [hash]
  static Map<String, List<String>> regionOf({
    required String hash,
    required BlockSpacing blockLength,
    required int numBlocks,
  }) {
    return _util.regionOf(
      hashString: hash,
      blockSpacing: blockLength,
      numBlocks: numBlocks,
    );
  }

  /// return hash of [GeoFirePoint]
  String get hash {
    return _util.encode(this.latitude, this.longitude, 9);
  }

  /// return all neighbors of [GeoFirePoint]
  List<String> get neighborsOf {
    return _util.neighborOf(hashString: this.hash);
  }

  /// return [GeoPoint] of [GeoFirePoint]
  GeoPoint get geoPoint {
    return GeoPoint(this.latitude, this.longitude);
  }

  Coordinates get coords {
    return Coordinates(this.latitude, this.longitude);
  }

  /// return distance between [GeoFirePoint] and ([lat], [lng])
  double distance({required double lat, required double lng}) {
    return distanceBetween(from: coords, to: Coordinates(lat, lng));
  }

  /// The regionalData method in the GeoFlutterFire3 library is designed to generate a map of geohashes around a central geopoint. This map includes the central geohash and a set of surrounding geohashes, each truncated to a certain precision. The precision is determined by the number of characters from the geohash.
  ///
  /// The method takes in five optional parameters of type RegionMappingConfig: tinyRMC, smallRMC, mediumRMC, longRMC, and hugeRMC. At least one of these parameters must be provided. If none is provided, an assertion error will be thrown. The mediumRMC parameter has a default value.
  ///
  /// The method also accepts a boolean parameter logMemoryUse, which defaults to false. If set to true, the method will compute and print the approximate memory usage of the returned data.
  ///
  /// The returned map is structured as follows:
  ///
  /// The 'geopoint' key contains the geopoint of the current instance.
  /// The 'data' key contains another map. This inner map has keys in the format 'precisionX', where X is an index from 0 to 8. Each key corresponds to a list of neighboring hashes of the geopoint, truncated to a certain precision. Each list also includes the center hash ('block0') of the geopoint truncated to the same precision.
  /// Returns:
  /// A Map<String, dynamic> containing the geopoint and its related data.
  Map<String, dynamic> regionalData({
    RegionMappingConfig? tinyRMC,
    RegionMappingConfig? smallRMC,
    RegionMappingConfig? mediumRMC =
        const RegionMappingConfig(blockSpacing: BlockSpacing.five, numSpacedBlock: 12),
    RegionMappingConfig? longRMC,
    RegionMappingConfig? hugeRMC,
    bool consolLogMemoryUse = false,
  }) {
    // Assert at least one of the RegionMappingConfig is not null
    assert(
        tinyRMC != null ||
            tinyRMC != null ||
            mediumRMC != null ||
            longRMC != null ||
            hugeRMC != null,
        'At least one of the RegionMappingConfig must be provided');

    final configs = [
      if (tinyRMC != null) (0, tinyRMC),
      if (smallRMC != null) (2, smallRMC),
      if (mediumRMC != null) (4, mediumRMC),
      if (longRMC != null) (6, longRMC),
      if (hugeRMC != null) (8, hugeRMC),
    ];

    final _data = configs.asMap().map(
      (idx, config) {
        final centerHash = this.hash.substring(0, config.$1 + 1);
        final key = 'precision' + config.$1.toString();
        final value = GeoFirePoint.regionOf(
          hash: centerHash,
          blockLength: config.$2.blockSpacing,
          numBlocks: config.$2.numSpacedBlock,
        );
        return MapEntry(
          key,
          value,
        );
      },
    );

    if (consolLogMemoryUse) {
      // Compute the approximate memory usage of the data
      var volume = 0;
      _data.forEach((key, value) {
        volume += key.length;
        value.forEach((key, value) {
          volume += key.length;
          value.forEach((element) {
            volume += key.length;
            volume += element.length;
          });
        });
      });

      print('Memory usage: ${(volume / 1000000 * 100).toStringAsFixed(2)}kb');
    }

    return {'geopoint': this.geoPoint, 'data': _data};
  }

  /// haversine distance between [GeoFirePoint] and ([lat], [lng])
  haversineDistance({required double lat, required double lng}) {
    return GeoFirePoint.distanceBetween(from: coords, to: Coordinates(lat, lng));
  }

  /// Sets the block number based on the given radius, precision, and block spacing.
  ///
  /// The block number is calculated based on the given radius and precision.
  /// The precision determines the block size, and the radius is used to calculate
  /// how many blocks fit within it. For example, if the radius is 10km, the precision
  /// is medium (block size of 4.89km), then the block number would be approximately 2.
  ///
  /// The block spacing is used to threshold the block number. If the block number
  /// isn't a multiple of the block spacing, it's rounded up to the next multiple.
  /// For instance, if the block number is 2 and the block spacing is 5, the thresholded
  /// block number would be 5.
  ///
  /// The function calculates the block number as the radius divided by the block
  /// size corresponding to the given precision, rounded to the nearest integer.
  /// It then applies thresholding based on the block spacing, rounding up to the
  /// nearest multiple of the block spacing.
  ///
  /// If the given precision or block spacing is not in the `BLOCK_SIZE` or
  /// `BLOCK_LENGTH` map, it throws an `ArgumentError`.
  ///
  /// Parameters:
  /// * `radius`: The radius of the block.
  /// * `precision`: The precision of the block size. This should be a value from
  ///   the `Precision` enum.
  /// * `blockSpacing`: The block spacing. This should be a value from the
  ///   `BlockSpacing` enum.
  ///
  /// Returns:
  /// The block number, thresholded based on the block spacing.
  static int setBlockNum(double radius, Precision precision, BlockSpacing blockLength) {
    final length = BLOCK_LENGTH[blockLength];
    final size = BLOCK_SIZE[precision];

    if (size == null) {
      throw ArgumentError('Invalid precision: $precision');
    }
    if (length == null) {
      throw ArgumentError('Invalid blockLength: $blockLength');
    }

    final blockNum = (radius / size).ceil();

    // Apply thresholding based on blockLength
    final thresholdedBlockNum = (blockNum / length).ceil() * length;

    return thresholdedBlockNum;
  }

  static const Map<BlockSpacing, int> BLOCK_LENGTH = {
    BlockSpacing.one: 1,
    BlockSpacing.two: 2,
    BlockSpacing.three: 3,
    BlockSpacing.four: 4,
    BlockSpacing.five: 5,
  };

  static const Map<Precision, double> BLOCK_SIZE = {
    Precision.huge: 5000.0,
    Precision.long: 156.0,
    Precision.medium: 4.89,
    Precision.short: 0.153,
    Precision.tiny: 0.00477,
  };
}

class Coordinates {
  double latitude;
  double longitude;

  Coordinates(this.latitude, this.longitude);
}

/// A configuration class for mapping a region in GeoFlutterFire3.
///
/// This class is used to define the size and number of blocks for a region around a geopoint.
/// The region is represented as a grid in a 2D plane, with each cell corresponding to a geohash.
///
/// Properties:
/// - `blockSpacing`: The index multiplier to which a geohash is saved. It is an instance of `BlockSpacing` enum.
///   The default value is `BlockSpacing.five`, which corresponds an interval of 4 blocks.
/// - `numBlocks`: The number of blocks to include in the data. The default value is 12.
///
/// Example usage:
/// ```dart
/// var config = RegionMappingConfig(blockSpacing: BlockSpacing.five, numBlocks: 12);
/// ```
///
/// The `blockSpacing` property determines the interval at which geohashes are selected from the grid. A smaller `blockSpacing` results in more geohashes being selected, as a geohash is picked at each `blockSpacing` index multiplier, which allows for more precise queries but at the cost of a larger data size and more memory usage. Conversely, a larger `blockSpacing` results in fewer geohashes being selected, as they are more widely spaced apart on the grid. Which reduces the data size and memory usage, but at the cost of less precise queries.
///
/// The `numSpacedBlock` property determines the number of spaced blocks to include in the region. A larger `numSpacedBlock` value results in a larger region, as more blocks are included. Which allows for longer range queries, but also at the expense of a larger data size and more memory usage.
/// Conversely, a smaller `numSpacedBlock` value results in a smaller region, as fewer blocks are included with less memory usage and shorter range queries.
///
/// Here's a visual example of how the RegionMappingConfig works with blockSpacing = BlockSpacing.two and numSpacedBlock = 4.
///
/// <img src="https://github.com/AbderraoufKhodja/geoflutterfire3/blob/main/2spacing4blocks.png" width="200" height="200">
///
/// Here's a visual example of how the RegionMappingConfig might work with blockSpacing = BlockSpacing.three and numSpacedBlock = 3.
///
/// <img src="https://AbderraoufKhodja/geoflutterfire3/blob/main/3spacing3blocks.png" width="200" height="200">
class RegionMappingConfig {
  final BlockSpacing blockSpacing;
  final int numSpacedBlock;

  const RegionMappingConfig({
    this.blockSpacing = BlockSpacing.five,
    this.numSpacedBlock = 12,
  });
}

enum BlockSpacing { one, two, three, four, five }

enum Precision { huge, long, medium, short, tiny }
