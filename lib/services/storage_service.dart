import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Servicio de almacenamiento de archivos en Firebase Storage.
///
/// Maneja la subida y descarga de documentos (comprobantes de donación,
/// fotos de perfil, etc.).
///
/// ## Estructura de rutas en Storage:
/// ```
/// alimenta_peru/
/// ├── comprobantes/
/// │   └── {donanteId}/
/// │       └── {timestamp}_{filename}
/// └── perfiles/
///     └── {userId}/
///         └── avatar.jpg
/// ```
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  static const String _baseFolder = 'alimenta_peru';

  // ── Comprobantes de donación ──────────────────────────────────────────────

  /// Sube un archivo de comprobante y retorna su URL de descarga.
  Future<String?> subirComprobante({
    required String donanteId,
    required File archivo,
    void Function(double progreso)? onProgress,
  }) async {
    try {
      final nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}_${archivo.path.split('/').last}';
      final ref = _storage
          .ref()
          .child('$_baseFolder/comprobantes/$donanteId/$nombreArchivo');

      final task = ref.putFile(
        archivo,
        SettableMetadata(
          contentType: _inferirContentType(archivo.path),
          customMetadata: {
            'donanteId': donanteId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Progreso de subida
      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          final progreso = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progreso);
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] Error al subir comprobante: $e');
      return null;
    }
  }

  // ── Fotos de perfil ───────────────────────────────────────────────────────

  /// Sube o reemplaza la foto de perfil de un usuario.
  Future<String?> subirFotoPerfil({
    required String userId,
    required File imagen,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('$_baseFolder/perfiles/$userId/avatar.jpg');

      await ref.putFile(
        imagen,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] Error al subir foto de perfil: $e');
      return null;
    }
  }

  // ── Descarga ─────────────────────────────────────────────────────────────

  /// Obtiene la URL de descarga de un archivo dado su path en Storage.
  Future<String?> obtenerUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] Error al obtener URL: $e');
      return null;
    }
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina un archivo de Storage dado su URL de descarga.
  Future<bool> eliminarPorUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('[Storage] Error al eliminar archivo: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _inferirContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
