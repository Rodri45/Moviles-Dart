import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/forecast_card.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../domain/entities/level_forecast.dart';
import '../../shell/main_shell.dart';
import '../home/home_view_model.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  static const routeName = '/forecast';

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeViewModel>();
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Occupancy forecast')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: home.load,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              Text(
                'Arrival · ${formatDate(home.arrivalAt)} at '
                '${formatTime(home.arrivalAt)}',
                style: AppTypography.heading1,
              ),
              if (home.forecastFromCache) ...[
                const SizedBox(height: Spacing.md),
                OfflineBanner(
                  savedAt: home.forecastSavedAt,
                  online: home.online,
                ),
              ],
              if (home.forecastErrorMessage != null) ...[
                const SizedBox(height: Spacing.md),
                NoticeBanner(
                  message: home.forecastErrorMessage!,
                  tone: NoticeTone.danger,
                  icon: Icons.error_outline,
                ),
              ],
              const SizedBox(height: Spacing.md),
              if (home.forecasts.isEmpty && home.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (home.forecasts.isEmpty)
                const Text('No saved forecast is available for this date.')
              else
                for (final level in home.forecasts) ...[
                  _LevelForecast(level: level, home: home),
                  const SizedBox(height: Spacing.md),
                ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppTabBar(
        current: AppTab.home,
        onSelected: (tab) => MainShell.openTab(context, tab),
      ),
    );
  }
}

class _LevelForecast extends StatelessWidget {
  const _LevelForecast({required this.level, required this.home});

  final LevelForecast level;
  final HomeViewModel home;

  @override
  Widget build(BuildContext context) {
    final hours = hourlyOccupancy([level]);
    final start = (home.arrivalAt.hour - 1).clamp(0, 16);
    final visibleHours = hours.sublist(start, start + 8);
    final predicted = home.recommendation?.predictions[level.code];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEVEL ${level.code}${home.recommendation?.recommended == level.code ? ' · RECOMMENDED' : ''}',
          style: AppTypography.overline,
        ),
        const SizedBox(height: Spacing.xs),
        ForecastCard(
          hours: visibleHours,
          currentHour: home.forecastHour,
          live: !home.forecastFromCache,
        ),
        if (predicted != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            'Predicted occupancy at ${home.recommendation!.slot}: '
            '${(predicted * 100).round()}%',
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }
}
