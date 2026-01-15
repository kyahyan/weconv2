import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/service_model.dart';

final activeFileProvider = StateProvider<File?>((ref) => null);
final activeProjectProvider = StateProvider<ServiceProject?>((ref) => null);
final activeEditorItemProvider = StateProvider<ServiceItem?>((ref) => null);
