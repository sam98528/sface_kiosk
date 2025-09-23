// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_photogoods.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchPhotogoodsDataImpl _$$SearchPhotogoodsDataImplFromJson(
  Map<String, dynamic> json,
) => _$SearchPhotogoodsDataImpl(
  data: (json['data'] as List<dynamic>)
      .map((e) => SearchPhotogoods.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SearchPhotogoodsDataImplToJson(
  _$SearchPhotogoodsDataImpl instance,
) => <String, dynamic>{'data': instance.data};

_$SearchPhotogoodsImpl _$$SearchPhotogoodsImplFromJson(
  Map<String, dynamic> json,
) => _$SearchPhotogoodsImpl(
  feedsIdx: (json['feeds_idx'] as num).toInt(),
  memIdx: (json['mem_idx'] as num).toInt(),
  feedsType: json['feeds_type'] as String,
  feedsViewCount: (json['feeds_view_count'] as num).toInt(),
  feedsImgAttach: (json['feeds_img_attach'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  feedsThumbnailAttach: json['feeds_thumbnail_attach'] as String,
);

Map<String, dynamic> _$$SearchPhotogoodsImplToJson(
  _$SearchPhotogoodsImpl instance,
) => <String, dynamic>{
  'feeds_idx': instance.feedsIdx,
  'mem_idx': instance.memIdx,
  'feeds_type': instance.feedsType,
  'feeds_view_count': instance.feedsViewCount,
  'feeds_img_attach': instance.feedsImgAttach,
  'feeds_thumbnail_attach': instance.feedsThumbnailAttach,
};
