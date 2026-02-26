import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/design_system.dart';

class StarboundBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const StarboundBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StarboundColors.deepSpace,
        border: Border(
          top: BorderSide(
            color: StarboundColors.cosmicWhite.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              index: 0,
              label: "Home",
              icon: Icons.home_outlined,
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
              activeColor: const Color(0xFFFFDA3E),
            ),
            _NavItem(
              index: 1,
              label: "Support Circle",
              icon: Icons.people_outline,
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
              activeColor: const Color(0xFF3498DB),
            ),
            _NavItem(
              index: 2,
              label: "Journal",
              icon: Icons.calendar_today_outlined,
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
              activeColor: const Color(0xFF00F5D4),
            ),
            _NavItem(
              index: 3,
              label: "Action Vault",
              icon: Icons.star_outline,
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
              activeColor: const Color(0xFFFF6B35),
            ),
            _NavItem(
              index: 4,
              label: "Settings",
              icon: Icons.settings_outlined,
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
              activeColor: const Color(0xFF9B59B6),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable nav item with smooth animations
class _NavItem extends StatefulWidget {
  final int index;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItem({
    Key? key,
    required this.index,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  }) : super(key: key);

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Semantics(
        label: '${widget.label} tab',
        hint: widget.isActive ? 'Currently selected' : 'Tap to navigate to ${widget.label} page',
        selected: widget.isActive,
        button: true,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() {});
          },
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: widget.isActive 
                ? widget.activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active indicator dot
                if (widget.isActive)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                // Icon
                Icon(
                  widget.icon, 
                  size: 24, 
                  color: widget.isActive 
                    ? widget.activeColor 
                    : StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  widget.label,
                  style: StarboundTypography.caption.copyWith(
                    color: widget.isActive 
                      ? widget.activeColor 
                      : StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
