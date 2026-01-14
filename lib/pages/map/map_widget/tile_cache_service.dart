// File: services/tile_cache_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TileCacheService {
  static const String _cacheDir = 'map_tiles';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheExpiry = Duration(days: 30);
  
  static Directory? _cacheDirectory;
  static final Map<String, DateTime> _accessTimes = {};
  
  /// Check if caching is supported on current platform
  static bool get isCachingSupported => !kIsWeb;
  
  /// Initialize the cache directory (no-op on web)
  static Future<void> initialize() async {
    if (!isCachingSupported) {
      debugPrint('ℹ️ Tile caching disabled on web platform');
      return;
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDir');
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
      
      // Clean up old tiles on initialization
      await _cleanupOldTiles();
      debugPrint('✅ Tile cache initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize tile cache: $e');
    }
  }
  
  /// Generate a cache key from tile URL
  static String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Get the file path for a cached tile
  static File _getCacheFile(String cacheKey) {
    return File('${_cacheDirectory!.path}/$cacheKey.tile');
  }
  
  /// Check if a tile exists in cache and is not expired
  static Future<bool> hasCachedTile(String url) async {
    if (!isCachingSupported) return false;
    if (_cacheDirectory == null) await initialize();
    
    final cacheKey = _getCacheKey(url);
    final file = _getCacheFile(cacheKey);
    
    if (!await file.exists()) return false;
    
    // Check if tile is expired
    final stat = await file.stat();
    final age = DateTime.now().difference(stat.modified);
    
    if (age > _cacheExpiry) {
      await file.delete();
      return false;
    }
    
    return true;
  }
  
  /// Get a cached tile
  static Future<Uint8List?> getCachedTile(String url) async {
    if (!isCachingSupported) return null;
    
    try {
      if (_cacheDirectory == null) await initialize();
      
      final cacheKey = _getCacheKey(url);
      final file = _getCacheFile(cacheKey);
      
      if (!await file.exists()) return null;
      
      // Check expiry
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      
      if (age > _cacheExpiry) {
        await file.delete();
        return null;
      }
      
      // Update access time for LRU
      _accessTimes[cacheKey] = DateTime.now();
      
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('❌ Error reading cached tile: $e');
      return null;
    }
  }
  
  /// Cache a tile (no-op on web)
  static Future<void> cacheTile(String url, Uint8List data) async {
    if (!isCachingSupported) return;
    
    try {
      if (_cacheDirectory == null) await initialize();
      
      final cacheKey = _getCacheKey(url);
      final file = _getCacheFile(cacheKey);
      
      await file.writeAsBytes(data);
      _accessTimes[cacheKey] = DateTime.now();
      
      // Check cache size and cleanup if needed
      await _enforceCacheSize();
    } catch (e) {
      debugPrint('❌ Error caching tile: $e');
    }
  }
  
  /// Download and cache a tile
  static Future<Uint8List?> downloadAndCacheTile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        
        // Only cache on supported platforms
        if (isCachingSupported) {
          await cacheTile(url, data);
        }
        
        return data;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error downloading tile: $e');
      return null;
    }
  }
  
  /// Clean up expired tiles
  static Future<void> _cleanupOldTiles() async {
    if (!isCachingSupported) return;
    
    try {
      if (_cacheDirectory == null) return;
      
      final files = _cacheDirectory!.listSync();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age > _cacheExpiry) {
            await file.delete();
            debugPrint('🗑️ Deleted expired tile: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old tiles: $e');
    }
  }
  
  /// Enforce cache size limit using LRU
  static Future<void> _enforceCacheSize() async {
    if (!isCachingSupported) return;
    
    try {
      if (_cacheDirectory == null) return;
      
      final files = _cacheDirectory!.listSync();
      int totalSize = 0;
      
      // Calculate total cache size
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      // If under limit, nothing to do
      if (totalSize <= _maxCacheSize) return;
      
      debugPrint('⚠️ Cache size ($totalSize bytes) exceeds limit ($_maxCacheSize bytes)');
      
      // Sort files by access time (LRU)
      final fileStats = <MapEntry<File, DateTime>>[];
      
      for (final file in files) {
        if (file is File) {
          final cacheKey = file.path.split('/').last.replaceAll('.tile', '');
          final accessTime = _accessTimes[cacheKey] ?? DateTime(1970);
          fileStats.add(MapEntry(file, accessTime));
        }
      }
      
      fileStats.sort((a, b) => a.value.compareTo(b.value));
      
      // Delete oldest files until under limit
      for (final entry in fileStats) {
        if (totalSize <= _maxCacheSize) break;
        
        final stat = await entry.key.stat();
        totalSize -= stat.size;
        await entry.key.delete();
        
        debugPrint('🗑️ Deleted LRU tile: ${entry.key.path}');
      }
    } catch (e) {
      debugPrint('❌ Error enforcing cache size: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (!isCachingSupported) {
      return {
        'platform': 'web',
        'cachingSupported': false,
        'message': 'Relying on browser HTTP cache',
      };
    }
    
    if (_cacheDirectory == null) await initialize();
    
    final files = _cacheDirectory!.listSync();
    int totalSize = 0;
    int fileCount = 0;
    
    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        totalSize += stat.size;
        fileCount++;
      }
    }
    
    return {
      'platform': Platform.operatingSystem,
      'cachingSupported': true,
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'maxSizeMB': (_maxCacheSize / (1024 * 1024)).toStringAsFixed(2),
      'utilizationPercent': ((totalSize / _maxCacheSize) * 100).toStringAsFixed(1),
    };
  }
  
  /// Clear all cached tiles
  static Future<void> clearCache() async {
    if (!isCachingSupported) {
      debugPrint('ℹ️ No cache to clear on web platform');
      return;
    }
    
    try {
      if (_cacheDirectory == null) await initialize();
      
      final files = _cacheDirectory!.listSync();
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      
      _accessTimes.clear();
      debugPrint('✅ Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
  
  /// Preload tiles for a specific area (disabled on web)
  static Future<void> preloadArea({
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    Function(int current, int total)? onProgress,
  }) async {
    if (!isCachingSupported) {
      debugPrint('ℹ️ Tile preloading not supported on web');
      onProgress?.call(0, 0);
      return;
    }
    
    int totalTiles = 0;
    int downloadedTiles = 0;
    
    // Calculate total tiles
    for (int z = minZoom; z <= maxZoom; z++) {
      final n = (north * (1 << z) / 360).floor();
      final s = (south * (1 << z) / 360).floor();
      final e = (east * (1 << z) / 360).floor();
      final w = (west * (1 << z) / 360).floor();
      totalTiles += (e - w + 1) * (n - s + 1);
    }
    
    debugPrint('📥 Starting preload of $totalTiles tiles');
    
    for (int z = minZoom; z <= maxZoom; z++) {
      final n = (north * (1 << z) / 360).floor();
      final s = (south * (1 << z) / 360).floor();
      final e = (east * (1 << z) / 360).floor();
      final w = (west * (1 << z) / 360).floor();
      
      for (int x = w; x <= e; x++) {
        for (int y = s; y <= n; y++) {
          final url = urlTemplate
              .replaceAll('{z}', z.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString());
          
          if (!await hasCachedTile(url)) {
            await downloadAndCacheTile(url);
          }
          
          downloadedTiles++;
          onProgress?.call(downloadedTiles, totalTiles);
        }
      }
    }
    
    debugPrint('✅ Preload complete: $downloadedTiles/$totalTiles tiles');
  }
}