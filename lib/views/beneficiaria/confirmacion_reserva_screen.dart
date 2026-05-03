import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/models/menu_model.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pantalla de confirmación de reserva con QR.
/// Basada en 04-confirmacion-menu.png
class ConfirmacionReservaScreen extends StatefulWidget {
  final MenuModel menu;
  final String reservaId;
  final String codigoQR;
  final String turno;
  final int numRaciones;

  const ConfirmacionReservaScreen({
    super.key,
    required this.menu,
    required this.reservaId,
    required this.codigoQR,
    required this.turno,
    required this.numRaciones,
  });

  @override
  State<ConfirmacionReservaScreen> createState() =>
      _ConfirmacionReservaScreenState();
}

class _ConfirmacionReservaScreenState
    extends State<ConfirmacionReservaScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = DateFormat("EEEE d 'de' MMMM, yyyy", 'es')
        .format(widget.menu.fecha);
    // Capitalizar primera letra
    final fechaCap =
        '${fechaFormateada[0].toUpperCase()}${fechaFormateada.substring(1)}';
    final idCorto = widget.reservaId.isEmpty
        ? 'DEMO001'
        : widget.reservaId.substring(0, 8).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Check verde ────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                '¡Reserva Confirmada!',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu lugar está asegurado',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Card detalle ───────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetalleRow(label: 'Día', valor: fechaCap),
                    const _HorizontalDivider(),
                    _DetalleRow(label: 'Menú', valor: widget.menu.nombrePlato),
                    const _HorizontalDivider(),
                    _DetalleRow(label: 'Turno', valor: widget.turno),
                    const _HorizontalDivider(),
                    _DetalleRow(
                      label: 'Comedor',
                      valor: 'Comedor Santa Rosa',
                    ),
                    const _HorizontalDivider(),
                    _DetalleRow(
                      label: 'Raciones',
                      valor: '${widget.numRaciones} ${widget.numRaciones == 1 ? 'ración' : 'raciones'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── QR Code ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: widget.codigoQR.isNotEmpty
                          ? widget.codigoQR
                          : 'reserva-demo-$idCorto',
                      version: QrVersions.auto,
                      size: 180,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primaryGreen,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Código de reserva: #$idCorto',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Botones icono (solo visual) ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _IconButton(
                      icono: Icons.calendar_today_outlined,
                      label: 'Calendario',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IconButton(
                      icono: Icons.share_outlined,
                      label: 'Compartir',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Botón volver al inicio ─────────────────────────────────
              AppButton(
                texto: 'Volver al inicio',
                color: AppColors.primaryGreen,
                icono: Icons.home_outlined,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/beneficiaria/dashboard',
                  (route) => false,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Reservar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _DetalleRow extends StatelessWidget {
  final String label;
  final String valor;

  const _DetalleRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalDivider extends StatelessWidget {
  const _HorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: AppColors.borderNeutral,
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icono;
  final String label;

  const _IconButton({required this.icono, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.borderNeutral, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
