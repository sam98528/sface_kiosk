import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/photo_detail_dialog.dart';
import '../providers/photogoods_provider.dart';
import '../../data/models/photogoods/search_photogoods.dart';

class PhotoListPage extends ConsumerStatefulWidget {
  const PhotoListPage({super.key});

  @override
  ConsumerState<PhotoListPage> createState() => _PhotoListPageState();
}

class _PhotoListPageState extends ConsumerState<PhotoListPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(photogoodsProvider.notifier)
          .searchPhotogoods(' ', refresh: true);
      _maybeLoadMoreToFillViewport();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLoadMoreToFillViewport(),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final hasMore = ref.read(photogoodsHasMoreProvider);
      final isLoading = ref.read(photogoodsLoadingProvider);

      if (hasMore && !isLoading) {
        ref.read(photogoodsProvider.notifier).loadMore();
      }
    }
  }

  void _maybeLoadMoreToFillViewport() {
    if (!_scrollController.hasClients) return;
    final bool hasMore = ref.read(photogoodsHasMoreProvider);
    final bool isLoading = ref.read(photogoodsLoadingProvider);
    if (!hasMore || isLoading) return;
    final ScrollPosition position = _scrollController.position;
    final bool notScrollable =
        position.maxScrollExtent <= 0 || position.extentAfter < 200;
    final bool nearBottom = position.pixels >= position.maxScrollExtent - 200;
    if (notScrollable || nearBottom) {
      ref.read(photogoodsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(photogoodsItemsProvider);
    final isLoading = ref.watch(photogoodsLoadingProvider);
    final error = ref.watch(photogoodsErrorProvider);
    final hasMore = ref.watch(photogoodsHasMoreProvider);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLoadMoreToFillViewport(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Text(
                'Error: $error',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: items.isEmpty && isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? const Center(child: Text('No photos found'))
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemCount: items.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return PhotoGridItem(item: items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PhotoGridItem extends StatelessWidget {
  final SearchPhotogoods item;

  const PhotoGridItem({super.key, required this.item});

  String get imageUrl {
    final awsIp =
        dotenv.env['AWS_IP'] ?? 'https://d37j40e2wj9q14.cloudfront.net/';
    return '$awsIp${item.feedsThumbnailAttach}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // log(imageUrl);
          _showImageDetail(context);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) {
                log('Image load error: $error for URL: $url');
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
              },
              httpHeaders: const {'User-Agent': 'SFace-Kiosk-Flutter/1.0'},
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Views: ${item.feedsViewCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${item.feedsIdx}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: PhotoDetailDialog(item: item, imageUrl: imageUrl),
      ),
    );
  }
}
