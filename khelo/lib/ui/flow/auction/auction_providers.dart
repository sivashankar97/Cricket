import 'dart:typed_data';

import 'package:data/api/auction/auction_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final publishedAuctionsProvider = StreamProvider.autoDispose<List<Auction>>(
  (ref) => ref.watch(auctionServiceProvider).streamPublishedAuctions(),
);

final adminAuctionsProvider =
    StreamProvider.autoDispose.family<List<Auction>, String>(
  (ref, userId) =>
      ref.watch(auctionServiceProvider).streamAdminAuctions(userId),
);

final auctionProvider = StreamProvider.autoDispose.family<Auction?, String>(
  (ref, id) => ref.watch(auctionServiceProvider).streamAuction(id),
);

final auctionLogProvider =
    StreamProvider.autoDispose.family<List<AuctionLogEntry>, String>(
  (ref, id) => ref.watch(auctionServiceProvider).streamLog(id),
);

final auctionPhotoProvider =
    StreamProvider.autoDispose.family<Uint8List?, String>((ref, photoId) {
  ref.keepAlive();
  return ref.watch(auctionServiceProvider).streamPhoto(photoId);
});
