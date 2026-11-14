import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../theme/app_theme.dart';

class RoleSelector extends StatelessWidget {
  final AuthRole selectedRole;
  final ValueChanged<AuthRole> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isIndividual = selectedRole == AuthRole.individual;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 8) / 2;

          return Stack(
            children: [
              // Sliding Animated Background Pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isIndividual ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark ? const Color(0xFF262936) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.25 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Text Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildTabItem(
                      label: 'Individual',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      isSelected: isIndividual,
                      onTap: () => onRoleChanged(AuthRole.individual),
                    ),
                  ),
                  Expanded(
                    child: _buildTabItem(
                      label: 'Organisation',
                      icon: Icons.business_outlined,
                      activeIcon: Icons.business_rounded,
                      isSelected: !isIndividual,
                      onTap: () => onRoleChanged(AuthRole.organisation),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: isSelected ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 15,
                    color: isSelected ? AppTheme.heroOrange : AppTheme.textSubtle,
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
