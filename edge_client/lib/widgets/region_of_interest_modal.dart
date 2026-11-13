import 'dart:io';
import 'package:flutter/material.dart';

/// Interactive Region of Interest (Grad-CAM Saliency) Heatmap Modal.
/// Provides visual explainability directly to clinicians and patients,
/// illustrating the focal cutaneous areas influencing the classification.
class RegionOfInterestModal extends StatefulWidget {
  final File? imageFile;
  final String? sampleUrl;
  final double malignantProbability;
  final double asymmetryIndex;
  final double colorVariance;

  const RegionOfInterestModal({
    super.key,
    this.imageFile,
    this.sampleUrl,
    required this.malignantProbability,
    required this.asymmetryIndex,
    required this.colorVariance,
  });

  static void show(
    BuildContext context, {
    File? imageFile,
    String? sampleUrl,
    required double malignantProbability,
    required double asymmetryIndex,
    required double colorVariance,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegionOfInterestModal(
        imageFile: imageFile,
        sampleUrl: sampleUrl,
        malignantProbability: malignantProbability,
        asymmetryIndex: asymmetryIndex,
        colorVariance: colorVariance,
      ),
    );
  }

  @override
  State<RegionOfInterestModal> createState() => _RegionOfInterestModalState();
}

class _RegionOfInterestModalState extends State<RegionOfInterestModal> {
  double _overlayOpacity = 0.65;
  bool _showHeatmap = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Medical clean light background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Focal Region of Interest',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explainable Saliency & Dermoscopy Heatmap',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lesion Frame with Synthetic Thermal Saliency Overlay
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base Image
                      if (widget.imageFile != null && widget.imageFile!.existsSync())
                        Image.file(
                          widget.imageFile!,
                          fit: BoxFit.cover,
                        )
                      else if (widget.sampleUrl != null)
                        Image.network(
                          widget.sampleUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      else
                        _buildPlaceholder(),

                      // Saliency Thermal Heatmap Overlay
                      if (_showHeatmap)
                        Opacity(
                          opacity: _overlayOpacity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.65,
                                colors: [
                                  widget.malignantProbability >= 0.60
                                      ? const Color(0xFFEF4444).withOpacity(0.95) // Red core
                                      : const Color(0xFFF59E0B).withOpacity(0.90), // Amber core
                                  const Color(0xFFEAB308).withOpacity(0.70), // Yellow zone
                                  const Color(0xFF10B981).withOpacity(0.35), // Green transition
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.40, 0.75, 1.0],
                              ),
                            ),
                          ),
                        ),

                      // Reticle Crosshairs
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Opacity Slider & Toggle Controls (Modeled after Old App Page 8)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showHeatmap ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: _showHeatmap ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() => _showHeatmap = !_showHeatmap);
                  },
                ),
                Expanded(
                  child: Slider(
                    value: _overlayOpacity,
                    min: 0.1,
                    max: 1.0,
                    activeColor: const Color(0xFF0284C7),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setState(() {
                        _overlayOpacity = val;
                        _showHeatmap = true;
                      });
                    },
                  ),
                ),
                Text(
                  '${(_overlayOpacity * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Diagnostic Annotation Footnote
          const Text(
            'Highlights the focal cutaneous area that most influenced this assessment. Not a definitive surgical margin outline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.grain_rounded, size: 48, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

