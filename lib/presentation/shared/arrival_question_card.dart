import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/palette.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/format.dart';
import '../screens/no_spots/lot_arrival_view_model.dart';

class ArrivalQuestionCard extends StatefulWidget {
  const ArrivalQuestionCard({super.key});

  @override
  State<ArrivalQuestionCard> createState() => _ArrivalQuestionCardState();
}

class _ArrivalQuestionCardState extends State<ArrivalQuestionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LotArrivalViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arrival = context.watch<LotArrivalViewModel>();
    final question = arrival.question;
    if (question == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: Palette.primary),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Did you park at ${question.lotName}?',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'You asked for directions at '
                '${formatTime(question.redirectedAt)}. Answering is optional.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => arrival.answer(parked: false),
                      child: const Text('No'),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => arrival.answer(parked: true),
                      child: const Text('Yes, I parked'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
