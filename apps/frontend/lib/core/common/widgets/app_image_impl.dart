import 'package:flutter/widgets.dart';

import 'app_image_impl_stub.dart'
    if (dart.library.io) 'app_image_impl_io.dart'
    if (dart.library.html) 'app_image_impl_web.dart';

Widget buildAppImage({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? error,
}) {
  return buildAppImageImpl(
    path: path,
    fit: fit,
    width: width,
    height: height,
    placeholder: placeholder,
    error: error,
  );
}
