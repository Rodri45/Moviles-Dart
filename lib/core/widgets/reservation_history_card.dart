import 'package:flutter/material.dart';

import '../../domain/entities/reservation.dart';
import '../design/palette.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../format.dart';

// la lista del historial de reservas, con chulo si llego y x si se vencio
class ReservationHistoryCard extends StatelessWidget {
  const ReservationHistoryCard({super.key, required this.reservations});

  final List<Reservation> reservations;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Text('No reservations yet', style: AppTypography.caption),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < reservations.length; i++) ...[
            _HistoryRow(reservation: reservations[i]),
            if (i < reservations.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 14),
      child: Row(
        children: [
          _StatusBadge(status: reservation.status),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              'Spot ${reservation.spotCode} · ${reservation.levelCode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            formatDate(reservation.createdAt),
            style: AppTypography.monoData,
          ),
        ],
      ),
    );
  }
}

// el cuadrito verde con chulo, rojo con x, gris si se cancelo, azul si sigue
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (status) {
      ReservationStatus.fulfilled || ReservationStatus.released => (
        Icons.check,
        Palette.success,
        Palette.successSoft,
      ),
      ReservationStatus.expired => (
        Icons.close,
        Palette.danger,
        Palette.dangerSoft,
      ),
      ReservationStatus.cancelled => (
        Icons.remove,
        Palette.textSecondary,
        Palette.background,
      ),
      ReservationStatus.active => (
        Icons.schedule,
        Palette.primary,
        Palette.primarySoft,
      ),
    };

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.badge),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
