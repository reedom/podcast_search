// Copyright (c) 2019 Ben Hills and the project contributors. Use of this source
// code is governed by a MIT license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:podcast_search/podcast_search.dart';

/// A class that represents an individual Podcast within the search results. Not all
/// properties may contain values for all search providers.
class Item {
  /// The iTunes ID of the artist.
  final int? artistId;

  /// The iTunes ID of the collection.
  final int? collectionId;

  /// The iTunes ID of the track.
  final int? trackId;

  /// The item unique identifier.
  final String? guid;

  /// The name of the artist.
  final String? artistName;

  /// The name of the iTunes collection the Podcast is part of.
  final String? collectionName;

  /// The track name.
  final String? trackName;

  /// The censored version of the collection name.
  final String? collectionCensoredName;

  /// The censored version of the track name,
  final String? trackCensoredName;

  /// The URL of the iTunes page for the artist.
  final String? artistViewUrl;

  /// The URL of the iTunes page for the podcast.
  final String? collectionViewUrl;

  /// The URL of the RSS feed for the podcast.
  final String? feedUrl;

  /// The URL of the iTunes page for the track.
  final String? trackViewUrl;

  /// Podcast artwork URL 30x30.
  final String? artworkUrl30;

  /// Podcast artwork URL 60x60.
  final String? artworkUrl60;

  /// Podcast artwork URL 100x100.
  final String? artworkUrl100;

  /// Podcast artwork URL 600x600.
  final String? artworkUrl600;

  /// Original artwork at intended resolution.
  final String? artworkUrl;

  /// Podcast release date
  final DateTime? releaseDate;

  /// Explicitness of the collection. For example notExplicit.
  final String? collectionExplicitness;

  /// Explicitness of the track. For example notExplicit.
  final String? trackExplicitness;

  /// Number of tracks in the results.
  final int? trackCount;

  /// Country of origin.
  final String? country;

  /// Primary genre for the podcast.
  final String? primaryGenreName;

  final String? contentAdvisoryRating;

  /// Full list of genres for the podcast.
  final List<Genre>? genre;

  /// Summary of the podcast.
  final String? summary;

  Item({
    this.artistId,
    this.collectionId,
    this.trackId,
    this.guid,
    this.artistName,
    this.collectionName,
    this.trackName,
    this.trackCount,
    this.collectionCensoredName,
    this.trackCensoredName,
    this.artistViewUrl,
    this.collectionViewUrl,
    this.feedUrl,
    this.trackViewUrl,
    this.collectionExplicitness,
    this.trackExplicitness,
    this.artworkUrl30,
    this.artworkUrl60,
    this.artworkUrl100,
    this.artworkUrl600,
    this.artworkUrl,
    this.releaseDate,
    this.country,
    this.primaryGenreName,
    this.contentAdvisoryRating,
    this.genre,
    this.summary,
  });

  /// Takes our json map and builds a Podcast instance from it.
  factory Item.fromJson(
      {required Map<String, dynamic>? json,
      ResultType type = ResultType.itunes}) {
    return type == ResultType.itunes
        ? _fromItunes(json!)
        : _fromPodcastIndex(json!);
  }

  factory Item.fromItunesSearchResult({required Map<String, dynamic> json}) {
    final images = <(int, String)>[];
    if (json.containsKey('im:image')) {
      for (final e in json['im:image'] as List<dynamic>) {
        final url = _getStringEntry(e, ['label']);
        final size = _getIntEntry(e, ['attributes', 'height']);
        if (url != null && size != null) {
          images.add((size, url));
        }
      }
    }
    images.sort((a, b) => b.$1 - a.$1);

    return Item(
      collectionId: _getIntEntry(json, ['id', 'attributes', 'im:id']),
      artistName: _getStringEntry(json, ['im:artist', 'label']),
      collectionName: _getStringEntry(json, ['im:name', 'label']),
      trackName: _getStringEntry(json, ['title', 'label']),
      collectionViewUrl: _getStringEntry(json, ['link', 'attributes', 'href']),
      trackViewUrl: _getStringEntry(json, ['link', 'attributes', 'href']),
      artworkUrl30: images.lastWhereOrNull((e) => 30 <= e.$1)?.$2,
      artworkUrl60: images.lastWhereOrNull((e) => 60 <= e.$1)?.$2,
      artworkUrl100: images.lastWhereOrNull((e) => 100 <= e.$1)?.$2,
      artworkUrl600: images.lastWhereOrNull((e) => 450 <= e.$1)?.$2,
      genre: Item._loadGenres([
        _getStringEntry(json, ['category', 'attributes', 'im:id'])!
      ], [
        _getStringEntry(json, ['category', 'attributes', 'label'])!
      ]),
      releaseDate:
          DateTime.parse(_getStringEntry(json, ['im:releaseDate', 'label'])!),
      // country: json['country'] as String?,
      // primaryGenreName: json['primaryGenreName'] as String?,
      // contentAdvisoryRating: json['contentAdvisoryRating'] as String?,
      summary: _getStringEntry(json, ['summary', 'label']),
    );
  }

  static Item _fromItunes(Map<String, dynamic> json) {
    return Item(
      artistId: json['artistId'] as int?,
      collectionId: json['collectionId'] as int?,
      trackId: json['trackId'] as int?,
      guid: json['guid'] as String?,
      artistName: json['artistName'] as String?,
      collectionName: json['collectionName'] as String?,
      collectionExplicitness: json['collectionExplicitness'] as String?,
      trackExplicitness: json['trackExplicitness'] as String?,
      trackName: json['trackName'] as String?,
      trackCount: json['trackCount'] as int?,
      collectionCensoredName: json['collectionCensoredName'] as String?,
      trackCensoredName: json['trackCensoredName'] as String?,
      artistViewUrl: json['artistViewUrl'] as String?,
      collectionViewUrl: json['collectionViewUrl'] as String?,
      feedUrl: json['feedUrl'] as String?,
      trackViewUrl: json['trackViewUrl'] as String?,
      artworkUrl30: json['artworkUrl30'] as String?,
      artworkUrl60: json['artworkUrl60'] as String?,
      artworkUrl100: json['artworkUrl100'] as String?,
      artworkUrl600: json['artworkUrl600'] as String?,
      genre: Item._loadGenres(
          json['genreIds'].cast<String>(), json['genres'].cast<String>()),
      releaseDate: DateTime.parse(json['releaseDate']),
      country: json['country'] as String?,
      primaryGenreName: json['primaryGenreName'] as String?,
      contentAdvisoryRating: json['contentAdvisoryRating'] as String?,
    );
  }

  static Item _fromPodcastIndex(Map<String, dynamic> json) {
    int pubDateSeconds =
        json['lastUpdateTime'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var pubDate = Duration(seconds: pubDateSeconds);
    var categories = json['categories'];
    var genres = <Genre>[];

    if (categories != null) {
      categories
          .forEach((key, value) => genres.add(Genre(int.parse(key), value)));
    }

    return Item(
      collectionId: json['itunesId'] as int?,
      guid: json['podcastGuid'] as String?,
      artistName: json['author'] as String?,
      trackName: json['title'] as String?,
      feedUrl: json['url'] as String?,
      trackViewUrl: json['link'] as String?,
      artworkUrl: json['image'] as String?,
      genre: genres,
      releaseDate: DateTime.fromMillisecondsSinceEpoch(pubDate.inMilliseconds),
    );
  }

  /// Genres appear within the json as two separate lists. This utility function
  /// creates Genre instances for each id and name pair.
  static List<Genre> _loadGenres(List<String>? id, List<String>? name) {
    var genres = <Genre>[];

    if (id != null) {
      for (var x = 0; x < id.length; x++) {
        genres.add(Genre(int.parse(id[x]), name![x]));
      }
    }

    return genres;
  }

  /// Contains a URL for the highest resolution artwork available. If no artwork is available
  /// this will return an empty [String].
  String get bestArtworkUrl {
    return artworkUrl ??
        artworkUrl600 ??
        artworkUrl100 ??
        artworkUrl60 ??
        artworkUrl30 ??
        '';
  }

  /// Contains a URL for the thumbnail resolution artwork. If no thumbnail size artwork
  /// is available this could return a URL for the full size image. If no artwork is available
  /// this will return an empty [String].
  String get thumbnailArtworkUrl {
    return artworkUrl60 ?? artworkUrl100 ?? artworkUrl600 ?? artworkUrl ?? '';
  }
}

String? _getStringEntry(Map<String, dynamic> json, List<String> keys) {
  if (json.containsKey(keys[0])) {
    return keys.length == 1
        ? json[keys[0]] as String?
        : _getStringEntry(json[keys[0]], keys.sublist(1));
  }
  return null;
}

int? _getIntEntry(Map<String, dynamic> json, List<String> keys) {
  if (json.containsKey(keys[0])) {
    return keys.length == 1
        ? int.tryParse(json[keys[0]])
        : _getIntEntry(json[keys[0]], keys.sublist(1));
  }
  return null;
}
