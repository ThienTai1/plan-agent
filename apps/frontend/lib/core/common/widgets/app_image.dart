import 'package:flutter/widgets.dart';

import 'app_image_impl.dart';

class AppImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? error;

  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return buildAppImage(
      path: path,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      error: error,
    );
  }
}
