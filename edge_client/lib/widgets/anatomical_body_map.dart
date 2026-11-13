import 'package:flutter/material.dart';

/// Represents an anatomical body zone for dermatological localization.
class AnatomicalZone {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final bool isAnterior; // Front vs Back view

  const AnatomicalZone({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    this.isAnterior = true,
  });
}

/// Interactive Anatomical Body Map Widget for SkinGuard UAE.
/// Provides visual, interactive touch mapping for lesion anatomical location.
class AnatomicalBodyMap extends StatefulWidget {
  final String selectedLocation;
  final ValueChanged<String> onLocationChanged;
  final bool isArabic;

  const AnatomicalBodyMap({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.isArabic = false,
  });

  @override
  State<AnatomicalBodyMap> createState() => _AnatomicalBodyMapState();
}

class _AnatomicalBodyMapState extends State<AnatomicalBodyMap> {
  bool _showAnterior = true;

  static const List<AnatomicalZone> _anteriorZones = [
    AnatomicalZone(id: 'Head / Neck', nameEn: 'Head & Face', nameAr: 'الرأس والوجه', icon: Icons.face_rounded),
    AnatomicalZone(id: 'Chest / Upper Torso', nameEn: 'Chest & Torso', nameAr: 'الصدر والجذع', icon: Icons.accessibility_new_rounded),
    AnatomicalZone(id: 'Abdomen', nameEn: 'Abdomen', nameAr: 'منطقة البطن', icon: Icons.crop_square_rounded),
    AnatomicalZone(id: 'Left Arm / Hand', nameEn: 'Left Arm / Hand', nameAr: 'الذراع الأيسر / اليد', icon: Icons.front_hand_rounded),
    AnatomicalZone(id: 'Right Arm / Hand', nameEn: 'Right Arm / Hand', nameAr: 'الذراع الأيمن / اليد', icon: Icons.front_hand_rounded),
    AnatomicalZone(id: 'Left Leg / Foot', nameEn: 'Left Leg', nameAr: 'الساق اليسرى', icon: Icons.airline_seat_legroom_extra_rounded),
    AnatomicalZone(id: 'Right Leg / Foot', nameEn: 'Right Leg', nameAr: 'الساق اليمنى', icon: Icons.airline_seat_legroom_extra_rounded),
  ];

  static const List<AnatomicalZone> _posteriorZones = [
    AnatomicalZone(id: 'Upper Back / Trunk', nameEn: 'Upper Back / Trunk', nameAr: 'أعلى الظهر / الجذع', icon: Icons.view_compact_rounded, isAnterior: false),
    AnatomicalZone(id: 'Lower Back / Lumbar', nameEn: 'Lower Back', nameAr: 'أسفل الظهر', icon: Icons.horizontal_split_rounded, isAnterior: false),
    AnatomicalZone(id: 'Posterior Neck / Scalp', nameEn: 'Posterior Neck', nameAr: 'خلف العنق / الفروة', icon: Icons.face_retouching_natural_rounded, isAnterior: false),
    AnatomicalZone(id: 'Left Posterior Arm', nameEn: 'Left Posterior Arm', nameAr: 'خلف الذراع الأيسر', icon: Icons.pan_tool_rounded, isAnterior: false),
    AnatomicalZone(id: 'Right Posterior Arm', nameEn: 'Right Posterior Arm', nameAr: 'خلف الذراع الأيمن', icon: Icons.pan_tool_rounded, isAnterior: false),
    AnatomicalZone(id: 'Left Posterior Leg', nameEn: 'Left Calf / Thigh', nameAr: 'خلف الفخذ / الساق', icon: Icons.airline_seat_legroom_extra_rounded, isAnterior: false),
    AnatomicalZone(id: 'Right Posterior Leg', nameEn: 'Right Calf / Thigh', nameAr: 'خلف الفخذ / الساق', icon: Icons.airline_seat_legroom_extra_rounded, isAnterior: false),
  ];

  @override
  Widget build(BuildContext context) {
    const brandSky = Color(0xFF0284C7);
    const borderSubtle = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    final currentZones = _showAnterior ? _anteriorZones : _posteriorZones;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & View Toggle (Front vs Back)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.accessibility_rounded, color: brandSky, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isArabic ? 'تحديد الموضع التشريحي للآفة' : 'ANATOMICAL LESION SITE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildViewTab(
                      label: widget.isArabic ? 'أمامي' : 'Front',
                      isSelected: _showAnterior,
                      onTap: () => setState(() => _showAnterior = true),
                    ),
                    _buildViewTab(
                      label: widget.isArabic ? 'خلفي' : 'Back',
                      isSelected: !_showAnterior,
                      onTap: () => setState(() => _showAnterior = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Visual Silhouette with Interactive Hotspots
          Center(
            child: Container(
              height: 220,
              width: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stylized Anatomy Silhouette
                  CustomPaint(
                    size: const Size(150, 210),
                    painter: _BodySilhouettePainter(
                      isAnterior: _showAnterior,
                      activeSite: widget.selectedLocation,
                    ),
                  ),

                  // Overlay Interactive Target Pins
                  if (_showAnterior) ...[
                    _buildPin(top: 18, left: 70, zoneId: 'Head / Neck', label: 'Head'),
                    _buildPin(top: 60, left: 70, zoneId: 'Chest / Upper Torso', label: 'Chest'),
                    _buildPin(top: 95, left: 70, zoneId: 'Abdomen', label: 'Abdomen'),
                    _buildPin(top: 75, left: 24, zoneId: 'Right Arm / Hand', label: 'R-Arm'),
                    _buildPin(top: 75, left: 116, zoneId: 'Left Arm / Hand', label: 'L-Arm'),
                    _buildPin(top: 155, left: 52, zoneId: 'Right Leg / Foot', label: 'R-Leg'),
                    _buildPin(top: 155, left: 88, zoneId: 'Left Leg / Foot', label: 'L-Leg'),
                  ] else ...[
                    _buildPin(top: 18, left: 70, zoneId: 'Posterior Neck / Scalp', label: 'Neck'),
                    _buildPin(top: 65, left: 70, zoneId: 'Upper Back / Trunk', label: 'Back'),
                    _buildPin(top: 105, left: 70, zoneId: 'Lower Back / Lumbar', label: 'Lumbar'),
                    _buildPin(top: 75, left: 24, zoneId: 'Right Posterior Arm', label: 'R-Arm'),
                    _buildPin(top: 75, left: 116, zoneId: 'Left Posterior Arm', label: 'L-Arm'),
                    _buildPin(top: 155, left: 52, zoneId: 'Right Posterior Leg', label: 'R-Leg'),
                    _buildPin(top: 155, left: 88, zoneId: 'Left Posterior Leg', label: 'L-Leg'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Selected Site Badge Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: brandSky, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isArabic
                        ? 'الموقع المحدد: ${_lookupArabicName(widget.selectedLocation)}'
                        : 'Selected Anatomical Locus: ${widget.selectedLocation}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    'ICD-10 Mapped',
                    style: TextStyle(color: brandSky, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Selection Chips Row
          Text(
            widget.isArabic ? 'أو اختر الموقع مباشرة:' : 'Or tap anatomical zone:',
            style: const TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: currentZones.map((zone) {
              final isSelected = widget.selectedLocation == zone.id;
              return InkWell(
                onTap: () => widget.onLocationChanged(zone.id),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? brandSky : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? brandSky : borderSubtle,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        zone.icon,
                        size: 13,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isArabic ? zone.nameAr : zone.nameEn,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPin({
    required double top,
    required double left,
    required String zoneId,
    required String label,
  }) {
    final isSelected = widget.selectedLocation == zoneId;
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () => widget.onLocationChanged(zoneId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF0284C7).withOpacity(0.5)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 8 : 3,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.circle,
            size: isSelected ? 11 : 6,
            color: isSelected ? Colors.white : const Color(0xFF0284C7),
          ),
        ),
      ),
    );
  }

  String _lookupArabicName(String id) {
    for (final z in [..._anteriorZones, ..._posteriorZones]) {
      if (z.id == id) return z.nameAr;
    }
    return id;
  }
}

/// Custom painter for medical body silhouette
class _BodySilhouettePainter extends CustomPainter {
  final bool isAnterior;
  final String activeSite;

  const _BodySilhouettePainter({
    required this.isAnterior,
    required this.activeSite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Head
    final headCenter = Offset(size.width / 2, 28);
    canvas.drawCircle(headCenter, 16, fillPaint);
    canvas.drawCircle(headCenter, 16, linePaint);

    // Neck
    final neckRect = Rect.fromCenter(center: Offset(size.width / 2, 48), width: 14, height: 10);
    canvas.drawRect(neckRect, fillPaint);

    // Torso Path
    final torsoPath = Path()
      ..moveTo(size.width / 2 - 32, 54) // Left shoulder
      ..lineTo(size.width / 2 + 32, 54) // Right shoulder
      ..lineTo(size.width / 2 + 24, 120) // Right hip
      ..lineTo(size.width / 2 - 24, 120) // Left hip
      ..close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, linePaint);

    // Arms
    // Left Arm
    canvas.drawLine(Offset(size.width / 2 - 32, 56), Offset(size.width / 2 - 46, 115), linePaint);
    // Right Arm
    canvas.drawLine(Offset(size.width / 2 + 32, 56), Offset(size.width / 2 + 46, 115), linePaint);

    // Legs
    // Left Leg
    canvas.drawLine(Offset(size.width / 2 - 14, 120), Offset(size.width / 2 - 16, 195), linePaint);
    // Right Leg
    canvas.drawLine(Offset(size.width / 2 + 14, 120), Offset(size.width / 2 + 16, 195), linePaint);

    // Back midline marker if posterior
    if (!isAnterior) {
      final spinePaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(size.width / 2, 56), Offset(size.width / 2, 118), spinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) {
    return oldDelegate.isAnterior != isAnterior || oldDelegate.activeSite != activeSite;
  }
}

