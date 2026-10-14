String? clientDeletionBlockMessage({
  required int orderCount,
  required int paymentCount,
}) {
  if (orderCount > 0) {
    return 'Ce client a des commandes : pour conserver son historique, '
        'il ne peut pas être supprimé.';
  }
  if (paymentCount > 0) {
    return 'Des paiements sont encore associés à ce client. '
        'Vérifiez son historique avant de le supprimer.';
  }
  return null;
}
