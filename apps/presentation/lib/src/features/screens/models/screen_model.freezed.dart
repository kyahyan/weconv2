// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'screen_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScreenModel _$ScreenModelFromJson(Map<String, dynamic> json) {
  return _ScreenModel.fromJson(json);
}

/// @nodoc
mixin _$ScreenModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  ScreenType get type => throw _privateConstructorUsedError;
  ScreenMode get mode => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  String? get outputId =>
      throw _privateConstructorUsedError; // ID of the physical display or window
  bool get isEnabled => throw _privateConstructorUsedError;
  ProjectionStyle? get style => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScreenModelCopyWith<ScreenModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScreenModelCopyWith<$Res> {
  factory $ScreenModelCopyWith(
          ScreenModel value, $Res Function(ScreenModel) then) =
      _$ScreenModelCopyWithImpl<$Res, ScreenModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      ScreenType type,
      ScreenMode mode,
      int width,
      int height,
      String? outputId,
      bool isEnabled,
      ProjectionStyle? style});
}

/// @nodoc
class _$ScreenModelCopyWithImpl<$Res, $Val extends ScreenModel>
    implements $ScreenModelCopyWith<$Res> {
  _$ScreenModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? mode = null,
    Object? width = null,
    Object? height = null,
    Object? outputId = freezed,
    Object? isEnabled = null,
    Object? style = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScreenType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ScreenMode,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      outputId: freezed == outputId
          ? _value.outputId
          : outputId // ignore: cast_nullable_to_non_nullable
              as String?,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as ProjectionStyle?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScreenModelImplCopyWith<$Res>
    implements $ScreenModelCopyWith<$Res> {
  factory _$$ScreenModelImplCopyWith(
          _$ScreenModelImpl value, $Res Function(_$ScreenModelImpl) then) =
      __$$ScreenModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      ScreenType type,
      ScreenMode mode,
      int width,
      int height,
      String? outputId,
      bool isEnabled,
      ProjectionStyle? style});
}

/// @nodoc
class __$$ScreenModelImplCopyWithImpl<$Res>
    extends _$ScreenModelCopyWithImpl<$Res, _$ScreenModelImpl>
    implements _$$ScreenModelImplCopyWith<$Res> {
  __$$ScreenModelImplCopyWithImpl(
      _$ScreenModelImpl _value, $Res Function(_$ScreenModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? mode = null,
    Object? width = null,
    Object? height = null,
    Object? outputId = freezed,
    Object? isEnabled = null,
    Object? style = freezed,
  }) {
    return _then(_$ScreenModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScreenType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ScreenMode,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      outputId: freezed == outputId
          ? _value.outputId
          : outputId // ignore: cast_nullable_to_non_nullable
              as String?,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as ProjectionStyle?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScreenModelImpl with DiagnosticableTreeMixin implements _ScreenModel {
  const _$ScreenModelImpl(
      {required this.id,
      required this.name,
      required this.type,
      this.mode = ScreenMode.single,
      this.width = 1920,
      this.height = 1080,
      this.outputId,
      this.isEnabled = false,
      this.style});

  factory _$ScreenModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScreenModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final ScreenType type;
  @override
  @JsonKey()
  final ScreenMode mode;
  @override
  @JsonKey()
  final int width;
  @override
  @JsonKey()
  final int height;
  @override
  final String? outputId;
// ID of the physical display or window
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  final ProjectionStyle? style;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ScreenModel(id: $id, name: $name, type: $type, mode: $mode, width: $width, height: $height, outputId: $outputId, isEnabled: $isEnabled, style: $style)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ScreenModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('mode', mode))
      ..add(DiagnosticsProperty('width', width))
      ..add(DiagnosticsProperty('height', height))
      ..add(DiagnosticsProperty('outputId', outputId))
      ..add(DiagnosticsProperty('isEnabled', isEnabled))
      ..add(DiagnosticsProperty('style', style));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScreenModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.outputId, outputId) ||
                other.outputId == outputId) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.style, style) || other.style == style));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type, mode, width,
      height, outputId, isEnabled, style);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScreenModelImplCopyWith<_$ScreenModelImpl> get copyWith =>
      __$$ScreenModelImplCopyWithImpl<_$ScreenModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScreenModelImplToJson(
      this,
    );
  }
}

abstract class _ScreenModel implements ScreenModel {
  const factory _ScreenModel(
      {required final String id,
      required final String name,
      required final ScreenType type,
      final ScreenMode mode,
      final int width,
      final int height,
      final String? outputId,
      final bool isEnabled,
      final ProjectionStyle? style}) = _$ScreenModelImpl;

  factory _ScreenModel.fromJson(Map<String, dynamic> json) =
      _$ScreenModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  ScreenType get type;
  @override
  ScreenMode get mode;
  @override
  int get width;
  @override
  int get height;
  @override
  String? get outputId;
  @override // ID of the physical display or window
  bool get isEnabled;
  @override
  ProjectionStyle? get style;
  @override
  @JsonKey(ignore: true)
  _$$ScreenModelImplCopyWith<_$ScreenModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
