import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/enums/enums.dart'; // ← necesario para .label en extensiones
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:alimenta_peru/models/reserva_model.dart';
import 'package:alimenta_peru/viewmodels/reporte_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servicio de generación y exportación de documentos PDF.
class PdfService {
  PdfService._();

  // ── Colores corporativos ──────────────────────────────────────────────────
  static const _verde = PdfColor.fromInt(0xFF16A34A);
  static const _naranja = PdfColor.fromInt(0xFFF97316);
  static const _gris = PdfColor.fromInt(0xFF6B7280);
  static const _fondo = PdfColor.fromInt(0xFFF9FAFB);
  static const _negro = PdfColor.fromInt(0xFF1A1A1A);

  // ── Reporte general ───────────────────────────────────────────────────────
  static Future<void> exportarReporteConsolidado(DatosReporte datos) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(
          titulo: 'Reporte Consolidado',
          subtitulo:
              '${fmt.format(datos.fechaInicio)} — ${fmt.format(datos.fechaFin)}',
        ),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          pw.Row(children: [
            _kpiBox('Total reservas', '${datos.totalReservas}', _verde),
            pw.SizedBox(width: 8),
            _kpiBox('Completadas', '${datos.reservasCompletadas}', _verde),
            pw.SizedBox(width: 8),
            _kpiBox('Canceladas', '${datos.reservasCanceladas}',
                PdfColors.red600),
            pw.SizedBox(width: 8),
            _kpiBox('Ausentes', '${datos.reservasAusentes}', _gris),
          ]),
          pw.SizedBox(height: 16),
          pw.Row(children: [
            _kpiBox(
              'Donaciones (S/)',
              datos.totalDonaciones.toStringAsFixed(2),
              _naranja,
            ),
            pw.SizedBox(width: 8),
            _kpiBox('Alertas stock', '${datos.insumosConAlerta}', _naranja),
            pw.SizedBox(width: 8),
            _kpiBox(
              'Tasa asistencia',
              '${datos.tasaAsistencia.toStringAsFixed(1)}%',
              _verde,
            ),
          ]),
          pw.SizedBox(height: 24),
          pw.Text('Resumen de actividad',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _negro)),
          pw.SizedBox(height: 8),
          _tablaResumen(datos),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'reporte_alimenta_peru_${fmt.format(DateTime.now())}.pdf',
    );
  }

  // ── Comprobante de reserva ────────────────────────────────────────────────
  static Future<void> exportarComprobanteReserva(ReservaModel reserva) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(
                titulo: 'Comprobante de Reserva',
                subtitulo: AppStrings.appName),
            pw.SizedBox(height: 24),
            // ← fix: beneficiariaId en lugar de nombreUsuario (que ya no existe)
            _filaInfo('ID beneficiaria', reserva.beneficiariaId),
            // ← fix: estado.name porque .label requiere el import de enums (ya incluido)
            _filaInfo('Estado', reserva.estado.label),
            _filaInfo('Fecha', fmt.format(reserva.fechaCreacion)),
            _filaInfo('Turno', reserva.turno),
            _filaInfo('Raciones', '${reserva.numRaciones}'),
            // ← fix: fechaRetiro ya no existe; horaLimite es el equivalente
            _filaInfo('Hora límite', fmt.format(reserva.horaLimite)),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _verde, width: 2),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  reserva.codigoQR,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _gris,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'reserva_${reserva.id}.pdf',
    );
  }

  // ── Comprobante de donación ───────────────────────────────────────────────
  static Future<void> exportarComprobanteDonacion(
      DonacionModel donacion) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(
                titulo: 'Comprobante de Donación',
                subtitulo: AppStrings.appName),
            pw.SizedBox(height: 24),
            // ← fix: donanteId en lugar de nombreDonante (que ya no existe)
            _filaInfo('Donante (ID)', donacion.donanteId),
            // ← fix: tipo.label con import de enums ya incluido
            _filaInfo('Tipo', donacion.tipo.label),
            _filaInfo('Descripción', donacion.descripcion),
            if (donacion.monto != null)
              _filaInfo('Monto', 'S/ ${donacion.monto!.toStringAsFixed(2)}'),
            // ← fix: donacion.fecha en lugar de donacion.fechaCreacion
            _filaInfo('Fecha', fmt.format(donacion.fecha)),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                '¡Gracias por tu generosidad!',
                style: pw.TextStyle(
                    color: _verde,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'donacion_${donacion.id}.pdf',
    );
  }

  // ── Widgets internos de PDF ───────────────────────────────────────────────

  static pw.Widget _header(
      {required String titulo, required String subtitulo}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              pw.Text(titulo,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              // ← fix: PdfColors.white en lugar de PdfColors.white70 (no existe)
              pw.Text(subtitulo,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
            ],
          ),
          pw.Text('🥗', style: const pw.TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(AppStrings.appName,
            style: const pw.TextStyle(color: _gris, fontSize: 9)),
        pw.Text('Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(color: _gris, fontSize: 9)),
      ],
    );
  }

  static pw.Widget _kpiBox(String label, String valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _fondo,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(valor,
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 9, color: _gris)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _filaInfo(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: const pw.TextStyle(color: _gris, fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(valor,
                style: pw.TextStyle(
                    color: _negro,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tablaResumen(DatosReporte datos) {
    final headers = ['Métrica', 'Valor'];
    final filas = [
      ['Total de reservas', '${datos.totalReservas}'],
      ['Reservas completadas', '${datos.reservasCompletadas}'],
      ['Reservas canceladas', '${datos.reservasCanceladas}'],
      ['Ausentes', '${datos.reservasAusentes}'],
      ['Tasa de asistencia', '${datos.tasaAsistencia.toStringAsFixed(1)}%'],
      [
        'Total donaciones en dinero',
        'S/ ${datos.totalDonaciones.toStringAsFixed(2)}'
      ],
      ['Insumos con alerta de stock', '${datos.insumosConAlerta}'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _verde),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ))
              .toList(),
        ),
        ...filas.asMap().entries.map(
              (entry) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: entry.key.isEven ? _fondo : PdfColors.white,
                ),
                children: entry.value
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(cell,
                              style: const pw.TextStyle(fontSize: 10)),
                        ))
                    .toList(),
              ),
            ),
      ],
    );
  }
}
