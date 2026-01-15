import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeFileProvider = StateProvider<File?>((ref) => null);
