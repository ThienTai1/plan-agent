import 'dart:io';

import 'package:flutter/widgets.dart';

String? _normalizeUrl(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  final lower = v.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return v;
  if (lower.startsWith('www.')) return 'https://$v';

  final uri = Uri.tryParse(v);
  if (uri == null) return null;
  if (uri.hasScheme) return null;
  if (uri.host.isNotEmpty || v.contains('.')) return 'https://$v';
  return null;
}

Widget buildAppImageImpl({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? error,
}) {
  if (path.trim().isEmpty) {
    return error ?? const SizedBox.shrink();
  }

  final url = _normalizeUrl(path);
  if (url != null) {
    return Image.network(url, fit: fit, width: width, height: height);
  }

  return Image.file(File(path), fit: fit, width: width, height: height);
}
