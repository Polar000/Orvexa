// Fotos de evidencia: se toman con la cámara, se guardan en el teléfono y se suben al enviar.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'offline.dart';
import 'theme.dart';

const photoBucket = 'evidencias';
const maxPhotos = 4;

/// Abre cámara o galería y copia la foto (reducida) a la carpeta de la app,
/// para que siga disponible aunque no haya señal o se cierre la app.
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Ox.graphite,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: Ox.yellow),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Ox.yellow),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 70);
  if (x == null) return null;
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/fotos_pendientes');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final dest = '${dir.path}/${newId()}.jpg';
  await File(x.path).copy(dest);
  return dest;
}

/// Sube una foto local a su ruta final (se puede repetir sin duplicar).
Future<void> uploadPhoto(String localPath, String remotePath) async {
  final bytes = await File(localPath).readAsBytes();
  await db.storage
      .from(photoBucket)
      .uploadBinary(remotePath, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
}

void deleteLocalPhoto(String path) {
  try {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  } catch (_) {}
}

final _urlCache = <String, (String, DateTime)>{};

Future<String?> signedUrl(String path) async {
  final c = _urlCache[path];
  if (c != null && c.$2.isAfter(DateTime.now())) return c.$1;
  try {
    final url = await db.storage.from(photoBucket).createSignedUrl(path, 3600);
    _urlCache[path] = (url, DateTime.now().add(const Duration(minutes: 50)));
    return url;
  } catch (_) {
    return null;
  }
}

/// Selector de fotos para formularios (muestra miniaturas de las fotos nuevas).
class PhotoPicker extends StatelessWidget {
  final List<String> localPaths;
  final List<String> existing; // fotos ya subidas
  final ValueChanged<List<String>> onChanged;
  const PhotoPicker({super.key, required this.localPaths, this.existing = const [], required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final total = localPaths.length + existing.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fotos (opcional)', style: TextStyle(color: Ox.lightGray)),
          const SizedBox(height: 8),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in existing)
                  Padding(padding: const EdgeInsets.only(right: 8), child: RemotePhoto(p, size: 84)),
                for (final p in localPaths)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        LocalPhoto(p, size: 84),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: InkWell(
                            onTap: () {
                              deleteLocalPhoto(p);
                              onChanged([...localPaths]..remove(p));
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Ox.black,
                              child: Icon(Icons.close, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (total < maxPhotos)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final p = await pickPhoto(context);
                      if (p != null) onChanged([...localPaths, p]);
                    },
                    child: Container(
                      width: 84,
                      decoration: BoxDecoration(
                        color: Ox.graphite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Ox.darkGray),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Ox.yellow),
                          SizedBox(height: 4),
                          Text('Foto', style: TextStyle(fontSize: 11, color: Ox.lightGray)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocalPhoto extends StatelessWidget {
  final String path;
  final double size;
  const LocalPhoto(this.path, {super.key, this.size = 64});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: GestureDetector(
      onTap: () => _viewer(context, Image.file(File(path), fit: BoxFit.contain)),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(size, Icons.broken_image_outlined),
      ),
    ),
  );
}

class RemotePhoto extends StatelessWidget {
  final String path;
  final double size;
  const RemotePhoto(this.path, {super.key, this.size = 64});
  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: signedUrl(path),
    builder: (context, snap) {
      final url = snap.data;
      if (url == null) {
        return _placeholder(
          size,
          snap.connectionState == ConnectionState.done ? Icons.cloud_off : Icons.image_outlined,
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: () => _viewer(context, Image.network(url, fit: BoxFit.contain)),
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(size, Icons.broken_image_outlined),
          ),
        ),
      );
    },
  );
}

/// Fila de fotos (subidas y pendientes) para listas e historiales.
class PhotoStrip extends StatelessWidget {
  final List<String> photos;
  final List<String> local;
  final double size;
  const PhotoStrip({super.key, this.photos = const [], this.local = const [], this.size = 56});
  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && local.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in photos) RemotePhoto(p, size: size),
          for (final p in local) LocalPhoto(p, size: size),
        ],
      ),
    );
  }
}

Widget _placeholder(double size, IconData icon) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(color: Ox.darkGray, borderRadius: BorderRadius.circular(10)),
  child: Icon(icon, color: Ox.lightGray, size: size * 0.35),
);

void _viewer(BuildContext context, Widget image) => showDialog(
  context: context,
  builder: (c) => Dialog(
    backgroundColor: Colors.black,
    insetPadding: const EdgeInsets.all(8),
    child: Stack(
      children: [
        InteractiveViewer(child: Center(child: image)),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
        ),
      ],
    ),
  ),
);
