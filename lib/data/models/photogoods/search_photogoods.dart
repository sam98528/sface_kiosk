import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_photogoods.freezed.dart';
part 'search_photogoods.g.dart';

@freezed
class SearchPhotogoodsData with _$SearchPhotogoodsData {
  const factory SearchPhotogoodsData({
    required List<SearchPhotogoods> data,
  }) = _SearchPhotogoodsData;

  factory SearchPhotogoodsData.fromJson(Map<String, dynamic> json) =>
      _$SearchPhotogoodsDataFromJson(json);
}
 


@freezed
class SearchPhotogoods with _$SearchPhotogoods {
  const factory SearchPhotogoods({
    @JsonKey(name: 'feeds_idx') required int feedsIdx,
    @JsonKey(name: 'mem_idx') required int memIdx,
    @JsonKey(name: 'feeds_type') required String feedsType,
    @JsonKey(name: 'feeds_view_count') required int feedsViewCount,
    @JsonKey(name: 'feeds_img_attach') required List<int> feedsImgAttach,
    @JsonKey(name: 'feeds_thumbnail_attach') required String feedsThumbnailAttach,
  }) = _SearchPhotogoods;

  factory SearchPhotogoods.fromJson(Map<String, dynamic> json) =>
      _$SearchPhotogoodsFromJson(json);
}