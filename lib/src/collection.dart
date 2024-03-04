import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'models/DistanceDocSnapshot.dart';
import 'point.dart';
import 'util.dart';

class GeoFireCollectionRef {
  Query _collectionReference;
  Stream<QuerySnapshot>? _stream;

  GeoFireCollectionRef(this._collectionReference) {
    // : assert(_collectionReference != null)
    _stream = _createStream(_collectionReference)!.shareReplay(maxSize: 1);
  }

  /// return QuerySnapshot stream
  Stream<QuerySnapshot>? snapshot() {
    return _stream;
  }

  /// return the Document mapped to the [id]
  Stream<List<DocumentSnapshot>> data(String id) {
    return _stream!.map((QuerySnapshot querySnapshot) {
      querySnapshot.docs.where((DocumentSnapshot documentSnapshot) {
        return documentSnapshot.id == id;
      });
      return querySnapshot.docs;
    });
  }

  /// add a document to collection with [data]
  Future<DocumentReference> add(Map<String, dynamic> data) {
    try {
      CollectionReference colRef = _collectionReference as CollectionReference;
      return colRef.add(data);
    } catch (e) {
      throw Exception('cannot call add on Query, use collection reference instead');
    }
  }

  /// delete document with [id] from the collection
  Future<void> delete(id) {
    try {
      CollectionReference colRef = _collectionReference as CollectionReference;
      return colRef.doc(id).delete();
    } catch (e) {
      throw Exception('cannot call delete on Query, use collection reference instead');
    }
  }

  /// create or update a document with [id], [merge] defines whether the document should overwrite
  Future<void> setDoc(String id, var data, {bool merge = false}) {
    try {
      CollectionReference colRef = _collectionReference as CollectionReference;
      return colRef.doc(id).set(data, SetOptions(merge: merge));
    } catch (e) {
      throw Exception('cannot call set on Query, use collection reference instead');
    }
  }

  /// set a geo point with [latitude] and [longitude] using [field] as the object key to the document with [id]
  Future<void> setPoint(String id, String field, double latitude, double longitude) {
    try {
      CollectionReference colRef = _collectionReference as CollectionReference;
      var point = GeoFirePoint(latitude, longitude).data;
      return colRef.doc(id).set({'$field': point}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('cannot call set on Query, use collection reference instead');
    }
  }

  /// query firestore documents based on geographic
  ///
  /// `center` is the center of the query
  ///
  /// `radius` from geoFirePoint `center`
  ///
  /// `field` specifies the name of the key in the document
  ///
  /// `radius` in kilometers
  ///
  /// `strictMode` if true, the query will only return documents within the given radius
  Query within({
    required GeoFirePoint center,
    required double radius,
    required String field,
    Precision precision = Precision.medium,
    required BlockSpacing blockLength,
    bool strictMode = false,
  }) {
    final blockNumber = Util.setBlockNum(radius, precision, blockLength);

    final areas = center.neighborsOf;

    return _unboundedGeoQuery(
      field: field,
      precision: precision,
      regionFilter: areas,
      blockNumber: blockNumber,
    );
  }

  Stream<List<DistanceDocSnapshot>> mergeObservable(
      Iterable<Stream<List<DistanceDocSnapshot>>> queries) {
    Stream<List<DistanceDocSnapshot>> mergedObservable =
        Rx.combineLatest(queries, (List<List<DistanceDocSnapshot>> originalList) {
      final reducedList = <DistanceDocSnapshot>[];
      originalList.forEach((t) {
        reducedList.addAll(t);
      });
      return reducedList;
    });
    return mergedObservable;
  }

  /// construct an unbounded query for the [geoHash] and [field]
  Query _unboundedGeoQuery({
    required String field,
    required Precision precision,
    required List<String> regionFilter,
    required int blockNumber,
  }) {
    final temp = _collectionReference;

    late final int idx;
    switch (precision) {
      case Precision.huge:
        idx = 0;
        break;
      case Precision.long:
        idx = 2;
        break;
      case Precision.medium:
        idx = 4;
        break;
      case Precision.short:
        idx = 6;
        break;
      case Precision.tiny:
        idx = 8;
        break;
    }

    return temp.where(
      '$field.data.precision$idx.block$blockNumber',
      arrayContainsAny: regionFilter,
    );
  }

  /// create an observable for [ref], [ref] can be [Query] or [CollectionReference]
  Stream<QuerySnapshot>? _createStream(var ref) {
    return ref.snapshots();
  }
}
