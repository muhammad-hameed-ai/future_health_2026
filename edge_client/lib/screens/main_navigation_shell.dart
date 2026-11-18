import 'package:flutter/material.dart';
import 'dashboard_home_screen.dart';
import 'smart_scan_wizard_screen.dart';
import 'clinical_history_screen.dart';
import 'clinical_learn_screen.dart';
import '../services/language_service.dart';

/// Master Application Shell for SkinGuard UAE (Executive 4-Tab Framework).
/// Unifies the Population Health Dashboard, Guided Clinical Intake Wizard,
/// Offline Scan Registry Database, and Official UAE/NICE Guidelines & Protocols.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  bool _isArabic = false;
  Map<String, dynamic>? _selectedSampleData;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _isArabic = LanguageService.isArabic;
    LanguageService.isArabicNotifier.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _isArabic = LanguageService.isArabic;
      });
    }
  }

  @override
  void dispose() {
    LanguageService.isArabicNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _toggleLanguage() {
    LanguageService.toggleLanguage();
  }

  void _navigateToWizard([Map<String, dynamic>? sampleData]) {
    setState(() {
      _selectedSampleData = sampleData;
      _currentIndex = 1;
    });
  }

  void _onScanComplete() {
    setState(() {
      // Direct user to Clinical Registry after scan sign-off
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0284C7);
    const unselectedColor = Color(0xFF64748B);

    final List<Widget> pages = [
      DashboardHomeScreen(
        onStartNewScan: () => _navigateToWizard(null),
        onSelectSample: (sample) => _navigateToWizard(sample),
        isArabic: _isArabic,
        onToggleLanguage: _toggleLanguage,
      ),
      SmartScanWizardScreen(
        initialSampleData: _selectedSampleData,
        isArabic: _isArabic,
        onScanComplete: _onScanComplete,
      ),
      const ClinicalHistoryScreen(),
      const ClinicalLearnScreen(),
    ];

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: _isArabic ? 'الرئيسية' : 'Dashboard',
                    activeColor: brandBlue,
                    inactiveColor: unselectedColor,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.camera_enhance_outlined,
                    activeIcon: Icons.camera_enhance_rounded,
                    label: _isArabic ? 'مسار الفحص' : 'Scan Wizard',
                    activeColor: brandBlue,
                    inactiveColor: unselectedColor,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.folder_shared_outlined,
                    activeIcon: Icons.folder_shared_rounded,
                    label: _isArabic ? 'السجل الطبي' : 'Registry',
                    activeColor: brandBlue,
                    inactiveColor: unselectedColor,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: _isArabic ? 'البروتوكولات' : 'SOP Protocol',
                    activeColor: brandBlue,
                    inactiveColor: unselectedColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
