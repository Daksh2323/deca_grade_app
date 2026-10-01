import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';

class MascotTestScreen extends StatelessWidget {
  const MascotTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mascots = [
      {
        'type': MascotType.calculo,
        'name': 'Calculo — Math',
        'bg': AppColors.mathLightBg,
        'border': AppColors.mathBorder,
      },
      {
        'type': MascotType.drSpark,
        'name': 'Dr. Spark — Science',
        'bg': AppColors.scienceLightBg,
        'border': AppColors.scienceBorder,
      },
      {
        'type': MascotType.owly,
        'name': 'Owly — English',
        'bg': AppColors.englishLightBg,
        'border': AppColors.englishBorder,
      },
      {
        'type': MascotType.indy,
        'name': 'Indy — Social Science',
        'bg': AppColors.sstLightBg,
        'border': AppColors.sstBorder,
      },
      {
        'type': MascotType.kavi,
        'name': 'Kavi Sahitya — Hindi',
        'bg': AppColors.hindiLightBg,
        'border': AppColors.hindiBorder,
      },
      {
        'type': MascotType.aria,
        'name': 'Air — AI Tutor',
        'bg': AppColors.aiLightBg,
        'border': AppColors.aiBorder,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mascot Preview (SVG)'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            children: mascots.map((mascot) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mascot['bg'] as Color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: mascot['border'] as Color,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    SvgMascot(
                      type: mascot['type'] as MascotType,
                      size: 160,
                      animate: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mascot['name'] as String,
                      style: AppTextStyles.heading3,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
