import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> localFileImage(String path) => FileImage(File(path));
