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
      blockLength: blockLength,
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

  /// Returns a Map containing the geopoint and data related to the geopoint.
  ///
  /// The 'geopoint' key in the returned Map contains the geopoint of the current instance.
  ///
  /// The 'data' key in the returned Map contains another Map. This inner Map has keys in the format 'precisionX',
  /// where X is an index from 0 to 8. Each key corresponds to a List of neighboring hashes of the geopoint,
  /// truncated to a certain precision. The precision corresponds to the number of characters from the geopoint's hash.
  /// Each List also includes the center hash ('block0') of the geopoint truncated to the same precision.
  ///
  /// This getter is useful for obtaining a detailed breakdown of the geopoint's neighboring hashes at different precisions.
  ///
  /// Returns:
  /// A Map<String, dynamic> containing the geopoint and its related data.
  Map<String, dynamic> data({
    RegionMappingConfig? tinyRMC,
    RegionMappingConfig? smallRMC,
    RegionMappingConfig? mediumRMC =
        const RegionMappingConfig(blockLength: BlockSpacing.five, numBlocks: 12),
    RegionMappingConfig? longRMC,
    RegionMappingConfig? hugeRMC,
    bool logMemoryUse = false,
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
          blockLength: config.$2.blockLength,
          numBlocks: config.$2.numBlocks,
        );
        return MapEntry(
          key,
          value,
        );
      },
    );

    if (logMemoryUse) {
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

class RegionMappingConfig {
  final BlockSpacing blockLength;
  final int numBlocks;

  const RegionMappingConfig({
    this.blockLength = BlockSpacing.five,
    this.numBlocks = 12,
  });
}

enum BlockSpacing { one, two, three, four, five }

enum Precision { huge, long, medium, short, tiny }
