import 'dart:math';

import 'point.dart';

class Util {
  static const BASE32_CODES = '0123456789bcdefghjkmnpqrstuvwxyz';
  Map<String, int> base32CodesDic = new Map();

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

  static const Map<Precision, int> BLOCK_INDEX = {
    Precision.huge: 0,
    Precision.long: 2,
    Precision.medium: 4,
    Precision.short: 6,
    Precision.tiny: 8,
  };

  Util() {
    for (var i = 0; i < BASE32_CODES.length; i++) {
      base32CodesDic.putIfAbsent(BASE32_CODES[i], () => i);
    }
  }

  var encodeAuto = 'auto';

  ///
  /// Significant Figure Hash Length
  ///
  /// This is a quick and dirty lookup to figure out how long our hash
  /// should be in order to guarantee a certain amount of trailing
  /// significant figures. This was calculated by determining the error:
  /// 45/2^(n-1) where n is the number of bits for a latitude or
  /// longitude. Key is # of desired sig figs, value is minimum length of
  /// the geohash.
  /// @type Array
  // Desired sig figs:    0  1  2  3   4   5   6   7   8   9  10
  var sigfigHashLength = [0, 5, 7, 8, 11, 12, 13, 15, 16, 17, 18];

  ///
  /// Encode
  /// Create a geohash from latitude and longitude
  /// that is 'number of chars' long
  String encode(var latitude, var longitude, var numberOfChars) {
    if (numberOfChars == encodeAuto) {
      if (latitude.runtimeType == double || longitude.runtimeType == double) {
        throw new Exception('string notation required for auto precision.');
      }
      int decSigFigsLat = latitude.split('.')[1].length;
      int decSigFigsLon = longitude.split('.')[1].length;
      int numberOfSigFigs = max(decSigFigsLat, decSigFigsLon);
      numberOfChars = sigfigHashLength[numberOfSigFigs];
    } else if (numberOfChars == null) {
      numberOfChars = 9;
    }

    var chars = [], bits = 0, bitsTotal = 0, hashValue = 0;
    double maxLat = 90, minLat = -90, maxLon = 180, minLon = -180, mid;

    while (chars.length < numberOfChars) {
      if (bitsTotal % 2 == 0) {
        mid = (maxLon + minLon) / 2;
        if (longitude > mid) {
          hashValue = (hashValue << 1) + 1;
          minLon = mid;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLon = mid;
        }
      } else {
        mid = (maxLat + minLat) / 2;
        if (latitude > mid) {
          hashValue = (hashValue << 1) + 1;
          minLat = mid;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLat = mid;
        }
      }

      bits++;
      bitsTotal++;
      if (bits == 5) {
        var code = BASE32_CODES[hashValue];
        chars.add(code);
        bits = 0;
        hashValue = 0;
      }
    }

    return chars.join('');
  }

  ///
  /// Decode Bounding box
  ///
  /// Decode a hashString into a bound box that matches it.
  /// Data returned in a List [minLat, minLon, maxLat, maxLon]
  List<double> decodeBbox(String hashString) {
    var isLon = true;
    double maxLat = 90, minLat = -90, maxLon = 180, minLon = -180, mid;

    int? hashValue = 0;
    for (var i = 0, l = hashString.length; i < l; i++) {
      var code = hashString[i].toLowerCase();
      hashValue = base32CodesDic[code];

      for (var bits = 4; bits >= 0; bits--) {
        var bit = (hashValue! >> bits) & 1;
        if (isLon) {
          mid = (maxLon + minLon) / 2;
          if (bit == 1) {
            minLon = mid;
          } else {
            maxLon = mid;
          }
        } else {
          mid = (maxLat + minLat) / 2;
          if (bit == 1) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isLon = !isLon;
      }
    }
    return [minLat, minLon, maxLat, maxLon];
  }

  ///
  /// Decode a [hashString] into a pair of latitude and longitude.
  /// A map is returned with keys 'latitude', 'longitude','latitudeError','longitudeError'
  Map<String, double> decode(String hashString) {
    List<double> bbox = decodeBbox(hashString);
    double lat = (bbox[0] + bbox[2]) / 2;
    double lon = (bbox[1] + bbox[3]) / 2;
    double latErr = bbox[2] - lat;
    double lonErr = bbox[3] - lon;
    return {
      'latitude': lat,
      'longitude': lon,
      'latitudeError': latErr,
      'longitudeError': lonErr,
    };
  }

  ///
  /// Neighbor
  ///
  /// Find neighbor of a geohash string in certain direction.
  /// Direction is a two-element array, i.e. [1,0] means north, [-1,-1] means southwest.
  ///
  /// direction [lat, lon], i.e.
  /// [1,0] - north
  /// [1,1] - northeast
  String neighbor(String hashString, var direction) {
    var lonLat = decode(hashString);
    var neighborLat = lonLat['latitude']! + direction[0] * lonLat['latitudeError'] * 2;
    var neighborLon = lonLat['longitude']! + direction[1] * lonLat['longitudeError'] * 2;
    return encode(neighborLat, neighborLon, hashString.length);
  }

  /// Returns the region of a given hash string.
  ///
  /// The [hashString] parameter is the hash string for which the region needs to be determined.
  /// The return value is a map where the keys are strings representing the region names, and the values are lists of strings representing the subregions within each region.
  List<String> neighborOf({
    required String hashString,
  }) {
    final hashStringLength = hashString.length;
    final lonlat = decode(hashString);
    double? lat = lonlat['latitude'];
    double? lon = lonlat['longitude'];
    double latErr = lonlat['latitudeError']! * 2;
    double lonErr = lonlat['longitudeError']! * 2;

    var neighborLat, neighborLon;

    String encodeNeighbor(neighborLatDir, neighborLonDir) {
      neighborLat = lat! + neighborLatDir * latErr;
      neighborLon = lon! + neighborLonDir * lonErr;
      return encode(neighborLat, neighborLon, hashStringLength);
    }

    final block = <String>[];
    final list1 = <int>[-2, -1, 0, 1, 2];
    list1.forEach((i) {
      list1.forEach((j) {
        block.add(encodeNeighbor(i, j));
      });
    });

    return block;
  }

  /// Returns the region of a given hash string.
  ///
  /// The [hashString] parameter is the hash string for which the region needs to be determined.
  /// The return value is a map where the keys are strings representing the region names, and the values are lists of strings representing the subregions within each region.
  Map<String, List<String>> regionOf({
    required String hashString,
    required BlockSpacing blockSpacing,
    required int numBlocks,
  }) {
    final hashStringLength = hashString.length;
    final spacing = blockSpacing.index + 1;
    final lonlat = decode(hashString);
    double? lat = lonlat['latitude'];
    double? lon = lonlat['longitude'];
    double latErr = lonlat['latitudeError']! * 2;
    double lonErr = lonlat['longitudeError']! * 2;

    var neighborLat, neighborLon;

    String encodeNeighbor(neighborLatDir, neighborLonDir) {
      neighborLat = lat! + neighborLatDir * latErr;
      neighborLon = lon! + neighborLonDir * lonErr;
      return encode(neighborLat, neighborLon, hashStringLength);
    }

    final data = <String, List<String>>{};

    final block1 = <String>[];
    final list1 = <int>[-1, 0, 1];
    list1.forEach((i) {
      list1.forEach((j) {
        block1.add(encodeNeighbor(i, j));
      });
    });

    final block2 = <String>[];
    final list2 = <int>[-2, -1, 0, 1, 2];
    list2.forEach((i) {
      list2.forEach((j) {
        block2.add(encodeNeighbor(i, j));
      });
    });

    data['block0'] = [hashString];
    data['block1'] = block1;
    data['block2'] = block2;

    for (var i = 1; i <= numBlocks; i++) {
      final block = <String>[];
      final list = List<int>.generate(
        i * 2 + 1,
        (j) => j * spacing - i * spacing,
      );

      list.forEach((x) {
        list.forEach((y) {
          // final distance = sqrt(x * x + y * y);
          // final radius = i * length;
          // // Crop the block to a circle
          // if (distance <= radius) block.add(encodeNeighbor(x, y));
          block.add(encodeNeighbor(x, y));
        });
      });

      data['block${i * spacing}'] = block;
    }

    return data;
  }

  static int setPrecision(double km) {
    /*
      * 1	≤ 5,000km	×	5,000km
      * 2	≤ 1,250km	×	625km
      * 3	≤ 156km	×	156km
      * 4	≤ 39.1km	×	19.5km
      * 5	≤ 4.89km	×	4.89km
      * 6	≤ 1.22km	×	0.61km
      * 7	≤ 153m	×	153m
      * 8	≤ 38.2m	×	19.1m
      * 9	≤ 4.77m	×	4.77m
      *
     */

    if (km <= 0.00477)
      return 9;
    else if (km <= 0.0382)
      return 8;
    else if (km <= 0.153)
      return 7;
    else if (km <= 1.22)
      return 6;
    else if (km <= 4.89)
      return 5;
    else if (km <= 39.1)
      return 4;
    else if (km <= 156)
      return 3;
    else if (km <= 1250)
      return 2;
    else
      return 1;
  }

  static const double MAX_SUPPORTED_RADIUS = 8587;

  // Length of a degree latitude at the equator
  static const double METERS_PER_DEGREE_LATITUDE = 110574;

  // The equatorial circumference of the earth in meters
  static const double EARTH_MERIDIONAL_CIRCUMFERENCE = 40007860;

  // The equatorial radius of the earth in meters
  static const double EARTH_EQ_RADIUS = 6378137;

  // The meridional radius of the earth in meters
  static const double EARTH_POLAR_RADIUS = 6357852.3;

  /* The following value assumes a polar radius of
     * r_p = 6356752.3
     * and an equatorial radius of
     * r_e = 6378137
     * The value is calculated as e2 == (r_e^2 - r_p^2)/(r_e^2)
     * Use exact value to avoid rounding errors
     */
  static const double EARTH_E2 = 0.00669447819799;

  // Cutoff for floating point calculations
  static const double EPSILON = 1e-12;

  static double distance(Coordinates location1, Coordinates location2) {
    return calcDistance(
        location1.latitude, location1.longitude, location2.latitude, location2.longitude);
  }

  static double calcDistance(double lat1, double long1, double lat2, double long2) {
    // Earth's mean radius in meters
    final double radius = (EARTH_EQ_RADIUS + EARTH_POLAR_RADIUS) / 2;
    double latDelta = _toRadians(lat1 - lat2);
    double lonDelta = _toRadians(long1 - long2);

    double a = (sin(latDelta / 2) * sin(latDelta / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(lonDelta / 2) * sin(lonDelta / 2));
    double distance = radius * 2 * atan2(sqrt(a), sqrt(1 - a)) / 1000;
    return double.parse(distance.toStringAsFixed(3));
  }

  static double _toRadians(double num) {
    return num * (pi / 180.0);
  }

  /// * block size
  ///     * huge ≈ 5,000km	×	5,000km
  ///     * long	≈ 156km	×	156km
  ///     * medium	≈ 4.89km	×	4.89km
  ///     * small	≈ 153m	×	153m
  ///     * tiny ≈ 4.77m	×	4.77m
  ///
  /// Block number represents the block location corresponding to the radius, and each block length corresponds to a specific precision. For Example if the block number is 2, and the precision is medium, then the block length is 4.89km
  static int setBlockNum(double radius, Precision precision, BlockSpacing blockLength) {
    final length = BLOCK_LENGTH[blockLength];
    final size = BLOCK_SIZE[precision];

    if (size == null) {
      throw ArgumentError('Invalid precision: $precision');
    }
    if (length == null) {
      throw ArgumentError('Invalid blockLength: $blockLength');
    }

    final blockNum = (radius / size).round();

    // Apply thresholding based on blockLength
    final thresholdedBlockNum = (blockNum / length).round() * length;

    return thresholdedBlockNum;
  }
}
