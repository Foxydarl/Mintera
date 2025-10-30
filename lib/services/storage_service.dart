import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _sb = Supabase.instance.client;

  String _sanitize(String name) {
    final replaced = name.replaceAll(RegExp(r"[^A-Za-z0-9\._-]"), '_');
    return replaced.length > 80 ? replaced.substring(replaced.length - 80) : replaced;
  }

  Future<String?> pickAndUpload({required String bucket, required String pathPrefix}) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res == null || res.files.isEmpty) return null;
    final file = res.files.first;
    final bytes = file.bytes as Uint8List?;
    if (bytes == null) return null;
    final uid = _sb.auth.currentUser?.id ?? 'public';
    final safeName = _sanitize(file.name);
    final path = '$pathPrefix/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _sb.storage.from(bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/*'));
    final publicUrl = _sb.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }
}
