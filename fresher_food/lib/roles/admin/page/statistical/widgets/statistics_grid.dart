import 'package:flutter/material.dart';
import 'stat_card.dart';

class StatisticsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const StatisticsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, i) {
        final s = stats[i];
        final Color color = s['color'] as Color;
        final List<Color> gradient = List<Color>.from(s['gradient'] as List);
        final IconData icon = s['icon'] as IconData;
        final String value = s['value'].toString();
        final String title = s['title'].toString();
        final Function()? route = s['route'] as Function()?;

        return StatCard(
          title: title,
          value: value,
          icon: icon,
          color: color,
          gradient: gradient,
          onTap: route,
        );
      },
    );
  }
}

