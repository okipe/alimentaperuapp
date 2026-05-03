import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/views/beneficiaria/registro_beneficiaria_p2_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:alimenta_peru/views/shared/widgets/app_header.dart';
import 'package:alimenta_peru/views/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paso 1 de 2 del registro de beneficiaria.
/// Basada en 02-registro-beneficiario.png
class RegistroBeneficiariaP1Screen extends StatefulWidget {
  const RegistroBeneficiariaP1Screen({super.key});

  @override
  State<RegistroBeneficiariaP1Screen> createState() =>
      _RegistroBeneficiariaP1ScreenState();
}

class _RegistroBeneficiariaP1ScreenState
    extends State<RegistroBeneficiariaP1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  String? _comedorSeleccionado;

  static const List<String> _comedores = [
    'Comedor Santa Rosa',
    'Comedor Villa María',
    'Comedor San Martín',
    'Comedor Los Olivos',
  ];

  // IDs hardcodeados para demo
  static const Map<String, String> _comedorIds = {
    'Comedor Santa Rosa': 'comedor_santa_rosa',
    'Comedor Villa María': 'comedor_villa_maria',
    'Comedor San Martín': 'comedor_san_martin',
    'Comedor Los Olivos': 'comedor_los_olivos',
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  void _onContinuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_comedorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona tu comedor cercano'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroBeneficiariaP2Screen(
          nombre: _nombreCtrl.text.trim(),
          dni: _dniCtrl.text.trim(),
          comedor: _comedorSeleccionado!,
          comedorId: _comedorIds[_comedorSeleccionado!] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header con progreso
          AppHeader(
            titulo: 'Registro Beneficiaria',
            mostrarBack: true,
            progreso: 0.5,
            textoProgreso: 'Paso 1 de 2',
          ),

          // Cuerpo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar circular con ícono de cámara
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFEF3C7),
                              border: Border.all(
                                color: AppColors.borderNeutral,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Foto',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Nombre completo
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nombre Completo',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Nombre Completo',
                      hint: 'Ingresa tu nombre',
                      controller: _nombreCtrl,
                      keyboardType: TextInputType.name,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // DNI
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DNI',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'DNI',
                      hint: '12345678',
                      controller: _dniCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'El DNI es requerido';
                        if (v.length != 8) return 'El DNI debe tener 8 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Dropdown comedor
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Comedor Cercano',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _comedorSeleccionado,
                      decoration: InputDecoration(
                        hintText: 'Selecciona tu comedor',
                        hintStyle: GoogleFonts.nunito(
                            color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.store_outlined,
                            color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.borderNeutral),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.borderNeutral),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGreen, width: 2),
                        ),
                        constraints: const BoxConstraints(minHeight: 56),
                      ),
                      items: _comedores
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: GoogleFonts.nunito(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _comedorSeleccionado = v),
                      style: GoogleFonts.nunito(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Botón continuar
                    AppButton(
                      texto: 'Continuar',
                      onPressed: _onContinuar,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
