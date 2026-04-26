import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Enums ──────────────────────────────────────────────────────────────
  group('RolUsuario', () {
    test('label retorna texto legible', () {
      expect(RolUsuario.beneficiaria.label, 'Beneficiaria');
      expect(RolUsuario.administradora.label, 'Administradora');
      expect(RolUsuario.donante.label, 'Donante');
    });

    test('dashboardRoute retorna ruta correcta', () {
      expect(RolUsuario.beneficiaria.dashboardRoute,
          '/beneficiaria/dashboard');
      expect(RolUsuario.administradora.dashboardRoute, '/admin/dashboard');
      expect(RolUsuario.donante.dashboardRoute, '/donante/dashboard');
    });

    test('fromString parsea correctamente', () {
      expect(RolUsuarioX.fromString('beneficiaria'), RolUsuario.beneficiaria);
      expect(RolUsuarioX.fromString('administradora'),
          RolUsuario.administradora);
      expect(RolUsuarioX.fromString('donante'), RolUsuario.donante);
    });

    test('fromString retorna beneficiaria por defecto ante valor desconocido',
        () {
      expect(RolUsuarioX.fromString('desconocido'), RolUsuario.beneficiaria);
    });
  });

  group('EstadoReserva', () {
    test('esFinal es verdadero solo para estados terminales', () {
      expect(EstadoReserva.cancelada.esFinal, isTrue);
      expect(EstadoReserva.completada.esFinal, isTrue);
      expect(EstadoReserva.ausente.esFinal, isTrue);
      expect(EstadoReserva.confirmada.esFinal, isFalse);
    });

    test('colorValue retorna valores distintos por estado', () {
      final colores = EstadoReserva.values.map((e) => e.colorValue).toSet();
      expect(colores.length, EstadoReserva.values.length,
          reason: 'Cada estado debe tener un color único');
    });
  });

  group('TipoDonacion', () {
    test('icono no está vacío', () {
      for (final tipo in TipoDonacion.values) {
        expect(tipo.icono, isNotEmpty,
            reason: '${tipo.name} debe tener icono');
      }
    });
  });

  group('EstadoMenu', () {
    test('disponible solo cuando está activo', () {
      expect(EstadoMenu.activo.disponible, isTrue);
      expect(EstadoMenu.cerrado.disponible, isFalse);
      expect(EstadoMenu.agotado.disponible, isFalse);
    });
  });

  group('EstadoUsuario', () {
    test('puedeOperar solo cuando está activo', () {
      expect(EstadoUsuario.activo.puedeOperar, isTrue);
      expect(EstadoUsuario.pendiente.puedeOperar, isFalse);
      expect(EstadoUsuario.inactivo.puedeOperar, isFalse);
    });
  });

  group('UnidadIngrediente', () {
    test('label y labelLargo no están vacíos', () {
      for (final u in UnidadIngrediente.values) {
        expect(u.label, isNotEmpty);
        expect(u.labelLargo, isNotEmpty);
      }
    });
  });

  // ── AppColors ──────────────────────────────────────────────────────────
  group('AppColors', () {
    test('primaryGreen tiene valor correcto', () {
      expect(AppColors.primaryGreen.value, 0xFF16A34A);
    });

    test('primaryOrange tiene valor correcto', () {
      expect(AppColors.primaryOrange.value, 0xFFF97316);
    });

    test('backgroundForStatus retorna card cuando todo es false', () {
      final color = AppColors.backgroundForStatus(
        isSuccess: false,
        isWarning: false,
        isError: false,
      );
      expect(color, AppColors.cardBackground);
    });

    test('backgroundForStatus retorna successGreen cuando isSuccess', () {
      final color = AppColors.backgroundForStatus(
        isSuccess: true,
        isWarning: false,
        isError: false,
      );
      expect(color, AppColors.successGreen);
    });
  });

  // ── AppStrings ──────────────────────────────────────────────────────────
  group('AppStrings', () {
    test('appName no está vacío', () {
      expect(AppStrings.appName, isNotEmpty);
    });

    test('appName es Alimenta Perú', () {
      expect(AppStrings.appName, 'Alimenta Perú');
    });
  });
}
