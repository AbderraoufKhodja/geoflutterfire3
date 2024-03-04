## 3.0.0
# Breaking Changes

# `GeoFlutterFire3` addresses the following issues of the original `GeoFlutterFire`:

- ~~range queries on multiple fields is not suppoerted by cloud_firestore at the moment, since this library already uses range query on `geohash` field, you cannot perform range queries with `GeoFireCollectionRef`.~~
- `GeoFlutterFire3` supports range now supports range queries because the new library don't use range query internally.
- ~~`limit()` and `orderBy()` are not supported at the moment. `limit()` could be used to limit docs inside each hash individually which would result in running limit on all 9 hashes inside the specified radius. `orderBy()` is first run on `geohashes` in the library, hence appending `orderBy()` with another feild wouldn't produce expected results. Alternatively documents can be sorted on client side.~~
- `GeoFlutterFire3` now supports `limit()` and `orderBy()`.

## 2.3.13
* upgrade dependencies

## 2.3.12
* upgrade dependencies

## 2.3.11
* upgrade dependencies

## 2.3.10
* upgrade dependencies

## 2.3.9
* upgrade dependencies: cloud_firestore

## 2.3.8
* upgrade dependencies: cloud_firestore

## 2.3.7
* upgrade dependencies

## 2.3.6
* upgrade dependencies: cloud_firestore

## 2.3.5
* upgrade dependencies: cloud_firestore

## 2.3.4
* upgrade dependencies: cloud_firestore

## 2.3.3
* upgrade dependencies: cloud_firestore

## 2.3.2
* upgrade dependencies

## 2.3.1
* upgrade dependencies

## 2.3.0
* upgraded dependencies aligned with Flutter2
* added Null safety
* increment major version

## 2.2.4
* update README
* upgraded dependencies aligned with Flutter2

## 2.2.3
* updates for pub analysis feedback
* upgraded dependencies aligned with Flutter2

## 2.2.2
* upgraded dependencies aligned with Flutter2
* added Null safety
* publish new package from forked project

## 2.1.0
* fixed breaking changes
* would not be able to access data using `doc.data['distance']` anymore

## 2.0.3+8
* upgraded dependencies
* fix for iOS build errors
* fixes for breaking changes from 2.0.3 for stream builders
* added a bug-fix for supporting stream builders

## 2.0.2
* added support for filtering documents strictly/easily with respect to radius

## 2.0.1+1
* bumped up the versions of kotlin-plugin and gradle.
* Support for GeoPoints nested inside the firestore document

## 2.0.0
* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.
* reverted to flutter stable channel from master.

## 1.0.2
* Refactored code to adhere to best practices(again)

## 1.0.1
* Refactored code to adhere to best practices

## 1.0.0
* Initial Release

