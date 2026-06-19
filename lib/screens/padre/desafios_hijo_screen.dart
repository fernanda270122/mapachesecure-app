import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import '../../services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DesafiosHijoScreen extends StatefulWidget {
  final Map<dynamic, dynamic> hijo;
  const DesafiosHijoScreen({super.key, required this.hijo});

  @override
  State<DesafiosHijoScreen> createState() => _DesafiosHijoScreenState();
}

class _DesafiosHijoScreenState extends State<DesafiosHijoScreen> {
  final ApiService _api = ApiService();
  final FlutterTts _tts = FlutterTts();

  List<dynamic> _desafiosCognitiva = [];
  List<dynamic> _desafiosFisica = [];
  List<dynamic> _desafiosHogar = [];
  List<dynamic> _opcionesIA = [];
  bool _cargando = false;

  String get _hijoId => widget.hijo['id'].toString();
  String get _hijoNombre => widget.hijo['nombre'] ?? 'Hijo';

  @override
  void initState() {
    super.initState();
    _cargarDesafios();
    _tts.setLanguage('es-MX').catchError((_) {});
  }

  Future<void> _cargarDesafios() async {
    setState(() => _cargando = true);
    try {
      final todos = await _api.get('/desafios/hijo/$_hijoId');
      final lista = todos is List ? todos : [];
      setState(() {
        _desafiosCognitiva = lista
            .where((d) => d['tipo'] == 'cognitiva')
            .toList();
        _desafiosFisica = lista.where((d) => d['tipo'] == 'fisica').toList();
        _desafiosHogar = lista.where((d) => d['tipo'] == 'hogar').toList();
      });
    } catch (_) {}
    setState(() => _cargando = false);
  }

  Future<void> _actualizarEstadoMision(dynamic id, bool nuevoEstado) async {
    try {
      await _api.post('/desafios/actualizar_estado', {
        'id': id,
        'esta_activo': nuevoEstado,
      });
      _cargarDesafios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar estado: $e')));
    }
  }

  Future<void> _generarDesafios(
    String categoria,
    String dificultad,
    Color colorBoton,
  ) async {
    setState(() => _cargando = true);
    try {
      final resultado = await _api.post('/ia/generar', {
        'categoria': categoria,
        'hijo_id': _hijoId,
        'dificultad': difficultyToBackend(dificultad),
        'cantidad': 3,
      });
      final nuevos = List<dynamic>.from(resultado['desafios'] ?? []);
      setState(() => _opcionesIA = nuevos);
      if (_opcionesIA.isNotEmpty) {
        if (!mounted) return;
        _mostrarSelectorIA(context, categoria, dificultad, colorBoton);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  String difficultyToBackend(String diff) {
    if (diff == 'Fácil') return 'facil';
    if (diff == 'Medio') return 'medio';
    if (diff == 'Difícil') return 'dificil';
    return diff.toLowerCase();
  }

  // MODAL 1: SECTOR DE MISIONES IA CORREGIDO Y RESPONSIVO
  void _mostrarSelectorIA(
    BuildContext context,
    String categoria,
    String dificultad,
    Color colorBoton,
  ) {
    Set<int> seleccionados = {};
    final mediaQuery = MediaQuery.of(context);
    final anchoPantalla = mediaQuery.size.width;
    // Capturamos la altura de la pantalla para limitar el modal al 85% de la pantalla como máximo
    final altoMaximoModal = mediaQuery.size.height * 0.85;
    final paddingInferiorSistema = mediaQuery.viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal crezca si es necesario
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(anchoPantalla * 0.06),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                // Ponemos un límite físico para que el modal nunca intente salirse de la pantalla
                constraints: BoxConstraints(maxHeight: altoMaximoModal),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: 24 + paddingInferiorSistema,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. TÍTULO FIJO (No se mueve con el scroll)
                      Text(
                        "Selecciona misiones para $_hijoNombre:",
                        style: TextStyle(
                          fontSize: (anchoPantalla * 0.045).clamp(16.0, 22.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 2. CONTENIDO CON SCROLL (Flexible absorbe el espacio sobrante sin romper la pantalla)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap:
                              true, // Se adapta al tamaño del contenido si es poco
                          itemCount: _opcionesIA.length,
                          itemBuilder: (context, index) {
                            final desafio = _opcionesIA[index];
                            final isSelected = seleccionados.contains(index);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorBoton.withValues(alpha: 0.05)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                title: Text(
                                  desafio['titulo'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: (anchoPantalla * 0.038).clamp(
                                      14.0,
                                      17.0,
                                    ),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "${desafio['descripcion']}\n\n⭐ ${desafio['puntos']} pts",
                                    style: TextStyle(
                                      fontSize: (anchoPantalla * 0.034).clamp(
                                        12.0,
                                        15.0,
                                      ),
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                value: isSelected,
                                activeColor: colorBoton,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      seleccionados.add(index);
                                    } else {
                                      seleccionados.remove(index);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. BOTÓN FIJO ABAJO (Siempre visible y clickeable)
                      SizedBox(
                        width: double.infinity,
                        height: (anchoPantalla * 0.12).clamp(45.0, 55.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorBoton,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: seleccionados.isEmpty
                              ? null
                              : () {
                                  List<Map<String, dynamic>> elegidos =
                                      seleccionados
                                          .map(
                                            (i) => Map<String, dynamic>.from(
                                              _opcionesIA[i],
                                            ),
                                          )
                                          .toList();
                                  Navigator.pop(context);
                                  _confirmarVariosDesafios(
                                    elegidos,
                                    categoria,
                                    dificultad,
                                  );
                                },
                          child: Text(
                            "Enviar ${seleccionados.length} misiones",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: (anchoPantalla * 0.038).clamp(
                                14.0,
                                17.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarVariosDesafios(
    List<Map<String, dynamic>> desafios,
    String categoria,
    String dificultad,
  ) async {
    setState(() => _cargando = true);
    try {
      for (var desafio in desafios) {
        await _api.post('/ia/asignar', {
          'titulo': desafio['titulo'],
          'descripcion': desafio['descripcion'],
          'puntos': desafio['puntos'],
          'tipo': categoria.toLowerCase(),
          'dificultad': difficultyToBackend(dificultad),
          'hijo_id': _hijoId,
          'esta_activo': false,
        });
      }
      _cargarDesafios();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Misiones enviadas! 🦝'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;
    final mediaQuery = MediaQuery.of(context);
    final anchoPantalla = mediaQuery.size.width;
    final paddingInferiorSistema = mediaQuery.viewPadding.bottom;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Desafíos de $_hijoNombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: (anchoPantalla * 0.05).clamp(18.0, 24.0),
          ),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(temaPadre.primary, Colors.white, 0.62)!,
              temaPadre.background,
            ],
          ),
        ),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                // Ajustamos el padding de fondo dinámicamente sumando la barra inferior del celular
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: 40 + paddingInferiorSistema,
                ),
                children: [
                  _buildSeccion(
                    'Cognitiva',
                    _desafiosCognitiva,
                    Colors.blue,
                    Icons.psychology,
                    anchoPantalla,
                  ),
                  _buildSeccion(
                    'Física',
                    _desafiosFisica,
                    Colors.orange,
                    Icons.fitness_center,
                    anchoPantalla,
                  ),
                  _buildSeccion(
                    'Hogar',
                    _desafiosHogar,
                    Colors.green,
                    Icons.home,
                    anchoPantalla,
                  ),
                  if (_desafiosCognitiva.isEmpty &&
                      _desafiosFisica.isEmpty &&
                      _desafiosHogar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No hay desafíos asignados.\nGenera algunos con IA.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: (anchoPantalla * 0.038).clamp(13.0, 16.0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: temaPadre.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _mostrarFormularioIA(context, temaPadre.primary),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      'Generar nuevos con IA',
                      style: TextStyle(
                        fontSize: (anchoPantalla * 0.04).clamp(14.0, 18.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSeccion(
    String titulo,
    List<dynamic> desafios,
    Color color,
    IconData icono,
    double anchoPantalla,
  ) {
    if (desafios.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: (anchoPantalla * 0.042).clamp(14.0, 18.0),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...desafios.map(
          (d) => _buildChallengeCard(
            id: d['id'],
            titulo: d['titulo'] ?? '',
            descripcion: d['descripcion'] ?? '',
            puntos: d['puntos']?.toString() ?? '0',
            dificultad: d['dificultad'] ?? 'facil',
            color: color,
            icono: icono,
            estaActivo: d['esta_activo'] ?? false,
            anchoPantalla: anchoPantalla,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard({
    required dynamic id,
    required String titulo,
    required String descripcion,
    required String puntos,
    required String dificultad,
    required Color color,
    required IconData icono,
    required bool estaActivo,
    required double anchoPantalla,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: estaActivo
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Icon(icono, color: estaActivo ? color : Colors.grey),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: (anchoPantalla * 0.038).clamp(14.0, 17.0),
            color: estaActivo ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          '$puntos pts • $dificultad',
          style: TextStyle(
            fontSize: (anchoPantalla * 0.032).clamp(11.0, 14.0),
            color: color,
          ),
        ),
        trailing: Switch(
          value: estaActivo,
          activeThumbColor: color,
          onChanged: (val) => _actualizarEstadoMision(id, val),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: (anchoPantalla * 0.035).clamp(12.0, 15.0),
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.indigo),
                      onPressed: () => _tts.speak(descripcion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODAL 2: FORMULARIO DE GENERACIÓN CON IA RESPONSIVO
  void _mostrarFormularioIA(BuildContext context, Color colorTema) {
    String categoria = 'cognitiva';
    String dificultad = 'facil';

    final mediaQuery = MediaQuery.of(context);
    final anchoPantalla = mediaQuery.size.width;
    final paddingInferiorSistema = mediaQuery.viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(anchoPantalla * 0.06),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 24 + paddingInferiorSistema,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generar con IA para $_hijoNombre',
                  style: TextStyle(
                    fontSize: (anchoPantalla * 0.045).clamp(16.0, 22.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Categoría',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: (anchoPantalla * 0.035).clamp(13.0, 16.0),
                    color: colorTema,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: Colors.white),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: categoria,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: (anchoPantalla * 0.04).clamp(14.0, 18.0),
                    ),
                    underline: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cognitiva',
                        child: Text('Cognitiva'),
                      ),
                      DropdownMenuItem(value: 'fisica', child: Text('Física')),
                      DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                    ],
                    onChanged: (v) => setModalState(() => categoria = v!),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dificultad',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: (anchoPantalla * 0.035).clamp(13.0, 16.0),
                    color: colorTema,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: Colors.white),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: dificultad,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: (anchoPantalla * 0.04).clamp(14.0, 18.0),
                    ),
                    underline: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                      DropdownMenuItem(value: 'medio', child: Text('Medio')),
                      DropdownMenuItem(
                        value: 'dificil',
                        child: Text('Difícil'),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => dificultad = v!),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: (anchoPantalla * 0.12).clamp(45.0, 55.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTema,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _generarDesafios(categoria, dificultad, colorTema);
                    },
                    child: Text(
                      'Generar misiones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: (anchoPantalla * 0.038).clamp(14.0, 17.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
