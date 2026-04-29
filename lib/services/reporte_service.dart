import 'dart:typed_data';

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:alimenta_peru/models/beneficiaria_model.dart';
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:alimenta_peru/models/reserva_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Servicio de generación de reportes PDF — capa Services de MVVM.
///
/// [generarReportePDF] consulta Firestore para el comedor y el mes
/// indicados, luego construye un PDF con tres secciones:
///
/// 1. **Reservas del mes** — fecha, beneficiaria, raciones, estado.
/// 2. **Donaciones del mes** — fecha, donante, tipo, descripción, monto.
/// 3. **Beneficiarias activas** — nombre, DNI, núm. familia, turno.
///
/// Retorna los bytes `Uint8List` listos para guardar o compartir con
/// `Printing.layoutPdf` o `FileSaver`.
class ReporteService {
  final FirebaseFirestore _db;

  ReporteService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Colores corporativos ──────────────────────────────────────────────────
  static const _verde = PdfColor.fromInt(0xFF16A34A);
  static const _naranja = PdfColor.fromInt(0xFFF97316);
  static const _gris = PdfColor.fromInt(0xFF6B7280);
  static const _negro = PdfColor.fromInt(0xFF1A1A1A);
  static const _fondoFila = PdfColor.fromInt(0xFFF9FAFB);

  // ── API pública ───────────────────────────────────────────────────────────

  /// Genera el reporte PDF para [comedorId] en el mes de [mes].
  ///
  /// Lanza [NetworkException] ante errores de Firestore.
  Future<Uint8List> generarReportePDF(String comedorId, DateTime mes) async {
    try {
      // Rango del mes
      final inicio = Timestamp.fromDate(DateTime(mes.year, mes.month));
      final fin = Timestamp.fromDate(DateTime(mes.year, mes.month + 1));

      // Consultas en paralelo
      final results = await Future.wait([
        // [0] Nombre del comedor
        _db.collection('comedores').doc(comedorId).get(),
        // [1] Reservas del mes
        _db
            .collection('reservas')
            .where('comedorId', isEqualTo: comedorId)
            .where('fechaCreacion', isGreaterThanOrEqualTo: inicio)
            .where('fechaCreacion', isLessThan: fin)
            .orderBy('fechaCreacion')
            .get(),
        // [2] Donaciones del mes
        _db
            .collection('donaciones')
            .where('comedorId', isEqualTo: comedorId)
            .where('fecha', isGreaterThanOrEqualTo: inicio)
            .where('fecha', isLessThan: fin)
            .orderBy('fecha')
            .get(),
        // [3] Beneficiarias activas del comedor
        _db
            .collection('usuarios')
            .where('comedorId', isEqualTo: comedorId)
            .where('rol', isEqualTo: RolUsuario.beneficiaria.name)
            .where('estado', isEqualTo: EstadoUsuario.activo.name)
            .orderBy('nombre')
            .get(),
      ]);

      final comedorSnap = results[0] as DocumentSnapshot;
      final reservasSnap = results[1] as QuerySnapshot;
      final donacionesSnap = results[2] as QuerySnapshot;
      final beneficiariasSnap = results[3] as QuerySnapshot;

      final nombreComedor = comedorSnap.exists
          ? ((comedorSnap.data() as Map<String, dynamic>)['nombre']
                  as String? ??
              'Comedor')
          : 'Comedor';

      final reservas = reservasSnap.docs
          .map((d) => ReservaModel.fromFirestore(d))
          .toList();
      final donaciones = donacionesSnap.docs
          .map((d) => DonacionModel.fromFirestore(d))
          .toList();
      final beneficiarias = beneficiariasSnap.docs
          .map((d) => BeneficiariaModel.fromFirestore(d))
          .toList();

      return _buildPdf(
        nombreComedor: nombreComedor,
        mes: mes,
        reservas: reservas,
        donaciones: donaciones,
        beneficiarias: beneficiarias,
      );
    } catch (e) {
      debugPrint('[ReporteService] Error al generar PDF: $e');
      throw NetworkException(
          'No se pudo generar el reporte. Verifica tu conexión.');
    }
  }

  // ── Construcción del PDF ──────────────────────────────────────────────────

  Future<Uint8List> _buildPdf({
    required String nombreComedor,
    required DateTime mes,
    required List<ReservaModel> reservas,
    required List<DonacionModel> donaciones,
    required List<BeneficiariaModel> beneficiarias,
  }) async {
    final pdf = pw.Document();
    final mesFmt = DateFormat('MMMM yyyy', 'es');
    final fechaFmt = DateFormat('dd/MM/yyyy', 'es');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        header: (ctx) => _buildHeader(nombreComedor, mesFmt.format(mes)),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),

          // ── Sección 1: Reservas ──────────────────────────────────────────
          _sectionTitle('1. Reservas del mes', _verde),
          pw.SizedBox(height: 8),
          if (reservas.isEmpty)
            _emptyNote('Sin reservas registradas en este período.')
          else
            _tablaReservas(reservas, fechaFmt),

          pw.SizedBox(height: 24),

          // ── Sección 2: Donaciones ────────────────────────────────────────
          _sectionTitle('2. Donaciones del mes', _naranja),
          pw.SizedBox(height: 8),
          if (donaciones.isEmpty)
            _emptyNote('Sin donaciones registradas en este período.')
          else
            _tablaDonaciones(donaciones, fechaFmt),

          pw.SizedBox(height: 24),

          // ── Sección 3: Beneficiarias activas ─────────────────────────────
          _sectionTitle('3. Beneficiarias activas', _gris),
          pw.SizedBox(height: 8),
          if (beneficiarias.isEmpty)
            _emptyNote('Sin beneficiarias activas en este comedor.')
          else
            _tablaBeneficiarias(beneficiarias),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Widgets de PDF ────────────────────────────────────────────────────────

  pw.Widget _buildHeader(String nombreComedor, String mes) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: _verde,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte Mensual — $nombreComedor',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                mes,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Text('🥗', style: const pw.TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Alimenta Perú',
          style: const pw.TextStyle(color: _gris, fontSize: 8),
        ),
        pw.Text(
          'Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: const pw.TextStyle(color: _gris, fontSize: 8),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _emptyNote(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: _gris, fontSize: 10),
      ),
    );
  }

  pw.Widget _tablaReservas(List<ReservaModel> reservas, DateFormat fmt) {
    const headers = ['Fecha', 'Beneficiaria ID', 'Raciones', 'Estado'];
    const widths = [1.5, 2.5, 1.0, 1.5];

    return _tabla(
      headers: headers,
      widths: widths,
      rows: reservas.map((r) {
        return [
          fmt.format(r.fecha),
          r.beneficiariaId,
          '${r.numRaciones}',
          r.estado.label,
        ];
      }).toList(),
    );
  }

  pw.Widget _tablaDonaciones(List<DonacionModel> donaciones, DateFormat fmt) {
    const headers = ['Fecha', 'Donante ID', 'Tipo', 'Descripción', 'Monto'];
    const widths = [1.2, 2.0, 1.0, 2.5, 1.0];

    return _tabla(
      headers: headers,
      widths: widths,
      rows: donaciones.map((d) {
        return [
          fmt.format(d.fecha),
          d.donanteId,
          d.tipo.label,
          d.descripcion.length > 40
              ? '${d.descripcion.substring(0, 40)}…'
              : d.descripcion,
          d.monto != null ? 'S/ ${d.monto!.toStringAsFixed(2)}' : '—',
        ];
      }).toList(),
    );
  }

  pw.Widget _tablaBeneficiarias(List<BeneficiariaModel> beneficiarias) {
    const headers = ['Nombre', 'DNI', 'Personas familia', 'Turno'];
    const widths = [2.5, 1.5, 1.5, 1.5];

    return _tabla(
      headers: headers,
      widths: widths,
      rows: beneficiarias.map((b) {
        return [
          b.nombre,
          b.dni,
          '${b.numPersonasFamilia}',
          b.turnoPreferido,
        ];
      }).toList(),
    );
  }

  /// Construye una tabla genérica con encabezado verde y filas alternas.
  pw.Widget _tabla({
    required List<String> headers,
    required List<double> widths,
    required List<List<String>> rows,
  }) {
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < widths.length; i++) {
      columnWidths[i] = pw.FlexColumnWidth(widths[i]);
    }

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _negro),
      children: headers
          .map(
            (h) => _cell(
              h,
              textColor: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          )
          .toList(),
    );

    final dataRows = rows.asMap().entries.map((entry) {
      final isEven = entry.key.isEven;
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: isEven ? _fondoFila : PdfColors.white,
        ),
        children: entry.value
            .map((cell) => _cell(cell, textColor: _negro))
            .toList(),
      );
    }).toList();

    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      children: [headerRow, ...dataRows],
    );
  }

  pw.Widget _cell(
    String text, {
    required PdfColor textColor,
    pw.FontWeight? fontWeight,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
