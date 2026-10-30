/// The waiting orders not announced yet: in [pendingIds] but not in
/// [alerted]. Orders that stopped waiting just drop out of both.
Set<String> newOrderIds(Iterable<String> pendingIds, Set<String> alerted) =>
    pendingIds.toSet().difference(alerted);
