import 'package:data/api/auction/auction_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_snackbar.dart';

import 'auction_widgets.dart';

/// Runs one auction action at a time and shows its error as a snackbar.
mixin AuctionActionRunner<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;

  AuctionService get service => ref.read(auctionServiceProvider);

  String get userId => ref.read(currentUserPod)?.id ?? '';

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    setState(() => busy = true);
    try {
      await action();
      return true;
    } on AuctionActionException catch (e) {
      if (mounted) showSnackBar(context, e.error.label(context));
    } catch (e) {
      if (mounted) showErrorSnackBar(context: context, error: e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
    return false;
  }
}
