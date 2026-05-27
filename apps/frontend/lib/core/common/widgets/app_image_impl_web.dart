import 'package:flutter/widgets.dart';

String _normalizeUrl(String value) {
  final v = value.trim();
  final lower = v.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return v;
  if (lower.startsWith('www.')) return 'https://$v';
  return 'https://$v';
}

Widget buildAppImageImpl({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? error,
}) {
  final url = _normalizeUrl(path);
  return Image.network(url, fit: fit, width: width, height: height);
}
