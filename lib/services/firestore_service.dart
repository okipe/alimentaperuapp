import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio centralizado de acceso a Firestore.
///
/// Encapsula las colecciones y operaciones genéricas de la base de datos,
/// exponiendo métodos tipados para cada entidad del dominio.
///
/// ## Colecciones disponibles:
/// - `usuarios`
/// - `insumos`
/// - `raciones`
/// - `reservas`
/// - `donaciones`
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Referencias de colecciones ────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usuarios =>
      _db.collection('usuarios');

  CollectionReference<Map<String, dynamic>> get insumos =>
      _db.collection('insumos');

  CollectionReference<Map<String, dynamic>> get raciones =>
      _db.collection('raciones');

  CollectionReference<Map<String, dynamic>> get reservas =>
      _db.collection('reservas');

  CollectionReference<Map<String, dynamic>> get donaciones =>
      _db.collection('donaciones');

  // ── Operaciones genéricas ─────────────────────────────────────────────────

  /// Crea un documento en la colección indicada y retorna el ID generado.
  Future<String> crear(
    CollectionReference<Map<String, dynamic>> coleccion,
    Map<String, dynamic> data,
  ) async {
    final ref = await coleccion.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Actualiza campos de un documento existente.
  Future<void> actualizar(
    CollectionReference<Map<String, dynamic>> coleccion,
    String id,
    Map<String, dynamic> data,
  ) =>
      coleccion.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Elimina un documento por ID.
  Future<void> eliminar(
    CollectionReference<Map<String, dynamic>> coleccion,
    String id,
  ) =>
      coleccion.doc(id).delete();

  /// Obtiene un documento por ID (one-shot).
  Future<DocumentSnapshot<Map<String, dynamic>>> obtener(
    CollectionReference<Map<String, dynamic>> coleccion,
    String id,
  ) =>
      coleccion.doc(id).get();

  /// Escucha cambios en tiempo real de un documento.
  Stream<DocumentSnapshot<Map<String, dynamic>>> escucharDocumento(
    CollectionReference<Map<String, dynamic>> coleccion,
    String id,
  ) =>
      coleccion.doc(id).snapshots();

  // ── Paginación ────────────────────────────────────────────────────────────

  /// Retorna la primera página de una colección ordenada por fecha de creación.
  Future<QuerySnapshot<Map<String, dynamic>>> primeraPagina({
    required CollectionReference<Map<String, dynamic>> coleccion,
    required int limite,
    String ordenarPor = 'createdAt',
    bool descendente = true,
  }) =>
      coleccion
          .orderBy(ordenarPor, descending: descendente)
          .limit(limite)
          .get();

  /// Retorna la siguiente página usando el último documento como cursor.
  Future<QuerySnapshot<Map<String, dynamic>>> siguientePagina({
    required CollectionReference<Map<String, dynamic>> coleccion,
    required int limite,
    required DocumentSnapshot ultimoDocumento,
    String ordenarPor = 'createdAt',
    bool descendente = true,
  }) =>
      coleccion
          .orderBy(ordenarPor, descending: descendente)
          .startAfterDocument(ultimoDocumento)
          .limit(limite)
          .get();

  // ── Batch operations ──────────────────────────────────────────────────────

  /// Ejecuta múltiples escrituras atómicas con WriteBatch.
  Future<void> batch(
      void Function(WriteBatch batch) operaciones) async {
    final b = _db.batch();
    operaciones(b);
    await b.commit();
  }

  // ── Transacciones ─────────────────────────────────────────────────────────

  /// Ejecuta una transacción atómica.
  Future<T> transaccion<T>(
    Future<T> Function(Transaction t) operaciones,
  ) =>
      _db.runTransaction(operaciones);

  // ── Helpers de fecha ──────────────────────────────────────────────────────

  /// Retorna el rango de timestamps para un día específico.
  ({Timestamp inicio, Timestamp fin}) rangoDelDia(DateTime fecha) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    return (
      inicio: Timestamp.fromDate(inicio),
      fin: Timestamp.fromDate(fin),
    );
  }

  /// Retorna el rango de timestamps para un mes específico.
  ({Timestamp inicio, Timestamp fin}) rangoDelMes(DateTime fecha) {
    final inicio = DateTime(fecha.year, fecha.month);
    final fin = DateTime(fecha.year, fecha.month + 1);
    return (
      inicio: Timestamp.fromDate(inicio),
      fin: Timestamp.fromDate(fin),
    );
  }
}
