// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_photogoods.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SearchPhotogoodsData _$SearchPhotogoodsDataFromJson(Map<String, dynamic> json) {
  return _SearchPhotogoodsData.fromJson(json);
}

/// @nodoc
mixin _$SearchPhotogoodsData {
  List<SearchPhotogoods> get data => throw _privateConstructorUsedError;

  /// Serializes this SearchPhotogoodsData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchPhotogoodsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchPhotogoodsDataCopyWith<SearchPhotogoodsData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchPhotogoodsDataCopyWith<$Res> {
  factory $SearchPhotogoodsDataCopyWith(
    SearchPhotogoodsData value,
    $Res Function(SearchPhotogoodsData) then,
  ) = _$SearchPhotogoodsDataCopyWithImpl<$Res, SearchPhotogoodsData>;
  @useResult
  $Res call({List<SearchPhotogoods> data});
}

/// @nodoc
class _$SearchPhotogoodsDataCopyWithImpl<
  $Res,
  $Val extends SearchPhotogoodsData
>
    implements $SearchPhotogoodsDataCopyWith<$Res> {
  _$SearchPhotogoodsDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchPhotogoodsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<SearchPhotogoods>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchPhotogoodsDataImplCopyWith<$Res>
    implements $SearchPhotogoodsDataCopyWith<$Res> {
  factory _$$SearchPhotogoodsDataImplCopyWith(
    _$SearchPhotogoodsDataImpl value,
    $Res Function(_$SearchPhotogoodsDataImpl) then,
  ) = __$$SearchPhotogoodsDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SearchPhotogoods> data});
}

/// @nodoc
class __$$SearchPhotogoodsDataImplCopyWithImpl<$Res>
    extends _$SearchPhotogoodsDataCopyWithImpl<$Res, _$SearchPhotogoodsDataImpl>
    implements _$$SearchPhotogoodsDataImplCopyWith<$Res> {
  __$$SearchPhotogoodsDataImplCopyWithImpl(
    _$SearchPhotogoodsDataImpl _value,
    $Res Function(_$SearchPhotogoodsDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchPhotogoodsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$SearchPhotogoodsDataImpl(
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<SearchPhotogoods>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchPhotogoodsDataImpl implements _SearchPhotogoodsData {
  const _$SearchPhotogoodsDataImpl({required final List<SearchPhotogoods> data})
    : _data = data;

  factory _$SearchPhotogoodsDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchPhotogoodsDataImplFromJson(json);

  final List<SearchPhotogoods> _data;
  @override
  List<SearchPhotogoods> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  String toString() {
    return 'SearchPhotogoodsData(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchPhotogoodsDataImpl &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  /// Create a copy of SearchPhotogoodsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchPhotogoodsDataImplCopyWith<_$SearchPhotogoodsDataImpl>
  get copyWith =>
      __$$SearchPhotogoodsDataImplCopyWithImpl<_$SearchPhotogoodsDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchPhotogoodsDataImplToJson(this);
  }
}

abstract class _SearchPhotogoodsData implements SearchPhotogoodsData {
  const factory _SearchPhotogoodsData({
    required final List<SearchPhotogoods> data,
  }) = _$SearchPhotogoodsDataImpl;

  factory _SearchPhotogoodsData.fromJson(Map<String, dynamic> json) =
      _$SearchPhotogoodsDataImpl.fromJson;

  @override
  List<SearchPhotogoods> get data;

  /// Create a copy of SearchPhotogoodsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchPhotogoodsDataImplCopyWith<_$SearchPhotogoodsDataImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SearchPhotogoods _$SearchPhotogoodsFromJson(Map<String, dynamic> json) {
  return _SearchPhotogoods.fromJson(json);
}

/// @nodoc
mixin _$SearchPhotogoods {
  @JsonKey(name: 'feeds_idx')
  int get feedsIdx => throw _privateConstructorUsedError;
  @JsonKey(name: 'mem_idx')
  int get memIdx => throw _privateConstructorUsedError;
  @JsonKey(name: 'feeds_type')
  String get feedsType => throw _privateConstructorUsedError;
  @JsonKey(name: 'feeds_view_count')
  int get feedsViewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'feeds_img_attach')
  List<int> get feedsImgAttach => throw _privateConstructorUsedError;
  @JsonKey(name: 'feeds_thumbnail_attach')
  String get feedsThumbnailAttach => throw _privateConstructorUsedError;

  /// Serializes this SearchPhotogoods to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchPhotogoods
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchPhotogoodsCopyWith<SearchPhotogoods> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchPhotogoodsCopyWith<$Res> {
  factory $SearchPhotogoodsCopyWith(
    SearchPhotogoods value,
    $Res Function(SearchPhotogoods) then,
  ) = _$SearchPhotogoodsCopyWithImpl<$Res, SearchPhotogoods>;
  @useResult
  $Res call({
    @JsonKey(name: 'feeds_idx') int feedsIdx,
    @JsonKey(name: 'mem_idx') int memIdx,
    @JsonKey(name: 'feeds_type') String feedsType,
    @JsonKey(name: 'feeds_view_count') int feedsViewCount,
    @JsonKey(name: 'feeds_img_attach') List<int> feedsImgAttach,
    @JsonKey(name: 'feeds_thumbnail_attach') String feedsThumbnailAttach,
  });
}

/// @nodoc
class _$SearchPhotogoodsCopyWithImpl<$Res, $Val extends SearchPhotogoods>
    implements $SearchPhotogoodsCopyWith<$Res> {
  _$SearchPhotogoodsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchPhotogoods
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedsIdx = null,
    Object? memIdx = null,
    Object? feedsType = null,
    Object? feedsViewCount = null,
    Object? feedsImgAttach = null,
    Object? feedsThumbnailAttach = null,
  }) {
    return _then(
      _value.copyWith(
            feedsIdx: null == feedsIdx
                ? _value.feedsIdx
                : feedsIdx // ignore: cast_nullable_to_non_nullable
                      as int,
            memIdx: null == memIdx
                ? _value.memIdx
                : memIdx // ignore: cast_nullable_to_non_nullable
                      as int,
            feedsType: null == feedsType
                ? _value.feedsType
                : feedsType // ignore: cast_nullable_to_non_nullable
                      as String,
            feedsViewCount: null == feedsViewCount
                ? _value.feedsViewCount
                : feedsViewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            feedsImgAttach: null == feedsImgAttach
                ? _value.feedsImgAttach
                : feedsImgAttach // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            feedsThumbnailAttach: null == feedsThumbnailAttach
                ? _value.feedsThumbnailAttach
                : feedsThumbnailAttach // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchPhotogoodsImplCopyWith<$Res>
    implements $SearchPhotogoodsCopyWith<$Res> {
  factory _$$SearchPhotogoodsImplCopyWith(
    _$SearchPhotogoodsImpl value,
    $Res Function(_$SearchPhotogoodsImpl) then,
  ) = __$$SearchPhotogoodsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'feeds_idx') int feedsIdx,
    @JsonKey(name: 'mem_idx') int memIdx,
    @JsonKey(name: 'feeds_type') String feedsType,
    @JsonKey(name: 'feeds_view_count') int feedsViewCount,
    @JsonKey(name: 'feeds_img_attach') List<int> feedsImgAttach,
    @JsonKey(name: 'feeds_thumbnail_attach') String feedsThumbnailAttach,
  });
}

/// @nodoc
class __$$SearchPhotogoodsImplCopyWithImpl<$Res>
    extends _$SearchPhotogoodsCopyWithImpl<$Res, _$SearchPhotogoodsImpl>
    implements _$$SearchPhotogoodsImplCopyWith<$Res> {
  __$$SearchPhotogoodsImplCopyWithImpl(
    _$SearchPhotogoodsImpl _value,
    $Res Function(_$SearchPhotogoodsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchPhotogoods
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedsIdx = null,
    Object? memIdx = null,
    Object? feedsType = null,
    Object? feedsViewCount = null,
    Object? feedsImgAttach = null,
    Object? feedsThumbnailAttach = null,
  }) {
    return _then(
      _$SearchPhotogoodsImpl(
        feedsIdx: null == feedsIdx
            ? _value.feedsIdx
            : feedsIdx // ignore: cast_nullable_to_non_nullable
                  as int,
        memIdx: null == memIdx
            ? _value.memIdx
            : memIdx // ignore: cast_nullable_to_non_nullable
                  as int,
        feedsType: null == feedsType
            ? _value.feedsType
            : feedsType // ignore: cast_nullable_to_non_nullable
                  as String,
        feedsViewCount: null == feedsViewCount
            ? _value.feedsViewCount
            : feedsViewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        feedsImgAttach: null == feedsImgAttach
            ? _value._feedsImgAttach
            : feedsImgAttach // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        feedsThumbnailAttach: null == feedsThumbnailAttach
            ? _value.feedsThumbnailAttach
            : feedsThumbnailAttach // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchPhotogoodsImpl implements _SearchPhotogoods {
  const _$SearchPhotogoodsImpl({
    @JsonKey(name: 'feeds_idx') required this.feedsIdx,
    @JsonKey(name: 'mem_idx') required this.memIdx,
    @JsonKey(name: 'feeds_type') required this.feedsType,
    @JsonKey(name: 'feeds_view_count') required this.feedsViewCount,
    @JsonKey(name: 'feeds_img_attach') required final List<int> feedsImgAttach,
    @JsonKey(name: 'feeds_thumbnail_attach') required this.feedsThumbnailAttach,
  }) : _feedsImgAttach = feedsImgAttach;

  factory _$SearchPhotogoodsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchPhotogoodsImplFromJson(json);

  @override
  @JsonKey(name: 'feeds_idx')
  final int feedsIdx;
  @override
  @JsonKey(name: 'mem_idx')
  final int memIdx;
  @override
  @JsonKey(name: 'feeds_type')
  final String feedsType;
  @override
  @JsonKey(name: 'feeds_view_count')
  final int feedsViewCount;
  final List<int> _feedsImgAttach;
  @override
  @JsonKey(name: 'feeds_img_attach')
  List<int> get feedsImgAttach {
    if (_feedsImgAttach is EqualUnmodifiableListView) return _feedsImgAttach;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_feedsImgAttach);
  }

  @override
  @JsonKey(name: 'feeds_thumbnail_attach')
  final String feedsThumbnailAttach;

  @override
  String toString() {
    return 'SearchPhotogoods(feedsIdx: $feedsIdx, memIdx: $memIdx, feedsType: $feedsType, feedsViewCount: $feedsViewCount, feedsImgAttach: $feedsImgAttach, feedsThumbnailAttach: $feedsThumbnailAttach)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchPhotogoodsImpl &&
            (identical(other.feedsIdx, feedsIdx) ||
                other.feedsIdx == feedsIdx) &&
            (identical(other.memIdx, memIdx) || other.memIdx == memIdx) &&
            (identical(other.feedsType, feedsType) ||
                other.feedsType == feedsType) &&
            (identical(other.feedsViewCount, feedsViewCount) ||
                other.feedsViewCount == feedsViewCount) &&
            const DeepCollectionEquality().equals(
              other._feedsImgAttach,
              _feedsImgAttach,
            ) &&
            (identical(other.feedsThumbnailAttach, feedsThumbnailAttach) ||
                other.feedsThumbnailAttach == feedsThumbnailAttach));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    feedsIdx,
    memIdx,
    feedsType,
    feedsViewCount,
    const DeepCollectionEquality().hash(_feedsImgAttach),
    feedsThumbnailAttach,
  );

  /// Create a copy of SearchPhotogoods
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchPhotogoodsImplCopyWith<_$SearchPhotogoodsImpl> get copyWith =>
      __$$SearchPhotogoodsImplCopyWithImpl<_$SearchPhotogoodsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchPhotogoodsImplToJson(this);
  }
}

abstract class _SearchPhotogoods implements SearchPhotogoods {
  const factory _SearchPhotogoods({
    @JsonKey(name: 'feeds_idx') required final int feedsIdx,
    @JsonKey(name: 'mem_idx') required final int memIdx,
    @JsonKey(name: 'feeds_type') required final String feedsType,
    @JsonKey(name: 'feeds_view_count') required final int feedsViewCount,
    @JsonKey(name: 'feeds_img_attach') required final List<int> feedsImgAttach,
    @JsonKey(name: 'feeds_thumbnail_attach')
    required final String feedsThumbnailAttach,
  }) = _$SearchPhotogoodsImpl;

  factory _SearchPhotogoods.fromJson(Map<String, dynamic> json) =
      _$SearchPhotogoodsImpl.fromJson;

  @override
  @JsonKey(name: 'feeds_idx')
  int get feedsIdx;
  @override
  @JsonKey(name: 'mem_idx')
  int get memIdx;
  @override
  @JsonKey(name: 'feeds_type')
  String get feedsType;
  @override
  @JsonKey(name: 'feeds_view_count')
  int get feedsViewCount;
  @override
  @JsonKey(name: 'feeds_img_attach')
  List<int> get feedsImgAttach;
  @override
  @JsonKey(name: 'feeds_thumbnail_attach')
  String get feedsThumbnailAttach;

  /// Create a copy of SearchPhotogoods
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchPhotogoodsImplCopyWith<_$SearchPhotogoodsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
