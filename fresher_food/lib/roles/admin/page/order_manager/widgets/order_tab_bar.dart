import 'package:flutter/material.dart';

class OrderTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedTab;
  final Function(int) onTabChanged;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textLightColor;

  const OrderTabBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textLightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => onTabChanged(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedTab == index ? primaryColor : surfaceColor,
                foregroundColor: selectedTab == index ? Colors.white : textLightColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selectedTab == index ? primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                tabs[index],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

