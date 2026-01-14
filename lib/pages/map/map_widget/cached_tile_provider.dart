// File: services/cached_tile_provider.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'tile_cache_service.dart';

class CachedTileProvider extends TileProvider {
  final http.Client httpClient;
  
  CachedTileProvider({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  @override
  ImageProvider getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final url = getTileUrl(coordinates, options);
    return CachedTileImage(url, httpClient);
  }

  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }
}

/// Custom ImageProvider that handles caching
class CachedTileImage extends ImageProvider<CachedTileImage> {
  final String url;
  final http.Client httpClient;

  const CachedTileImage(this.url, this.httpClient);

  @override
  Future<CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<CachedTileImage>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    CachedTileImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      // Try to get from cache first
      final cachedData = await TileCacheService.getCachedTile(url);
      
      if (cachedData != null) {
        debugPrint('✅ Cache HIT: $url');
        final buffer = await ui.ImmutableBuffer.fromUint8List(cachedData);
        return await decode(buffer);
      }
      
      // debugPrint('📥 Cache MISS: Downloading $url');
      
      // Download from network
      final response = await httpClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        
        // Cache the tile asynchronously (don't wait)
        TileCacheService.cacheTile(url, data).catchError((e) {
          debugPrint('⚠️ Failed to cache tile: $e');
        });
        
        final buffer = await ui.ImmutableBuffer.fromUint8List(data);
        return await decode(buffer);
      }
      
      throw Exception('Failed to load tile: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error loading tile: $e');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'CachedTileImage("$url")';
}