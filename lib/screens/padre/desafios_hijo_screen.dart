import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

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
    _tts.setLanguage('es-MX');
  }

  Future<void> _cargarDesafios() async {
    setState(() => _cargando = true);
    try {
      final cognitiva = await _api.get('/desafios/tipo/cognitiva');
      final fisica = await _api.get('/desafios/tipo/fisica');
      final hogar = await _api.get('/desafios/tipo/hogar');

      // De cada tipo: mantener los del sistema (hijo_id null) y los de este hijo.
      // Si el hijo ya tiene copia de un desafío del sistema, mostrar su copia (no el global).
      List<dynamic> filtrar(List<dynamic> todos) {
        final hijoEspecificos = todos
            .where((d) => d['hijo_id']?.toString() == _hijoId)
            .toList();
        final titulosHijo = hijoEspecificos.map((d) => d['titulo']).toSet();
        final sistema = todos
            .where((d) => d['hijo_id'] == null && !titulosHijo.contains(d['titulo']))
            .toList();
        return [...hijoEspecificos, ...sistema];
      }

      setState(() {
        _desafiosCognitiva = filtrar(cognitiva is List ? cognitiva : []);
        _desafiosFisica = filtrar(fisica is List ? fisica : []);
        _desafiosHogar = filtrar(hogar is List ? hogar : []);
      });
    } catch (_) {}
    setState(() => _cargando = false);
  }

  Future<void> _actualizarEstadoMision(Map<dynamic, dynamic> desafio, bool nuevoEstado) async {
    try {
      final challengeHijoId = desafio['hijo_id']?.toString();
      if (challengeHijoId == _hijoId) {
        await _api.post('/desafios/actualizar_estado', {
          'id': desafio['id'],
          'esta_activo': nuevoEstado,
        });
      } else {
        await _api.post('/ia/asignar', {
          'titulo': desafio['titulo'],
          'descripcion': desafio['descripcion'],
          'puntos': desafio['puntos'],
          'tipo': desafio['tipo'],
          'dificultad': desafio['dificultad'] ?? 'facil',
          'hijo_id': _hijoId,
          'esta_activo': nuevoEstado,
        });
      }
      _cargarDesafios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    }
  }

  Future<void> _generarDesafios(String categoria, String dificultad) async {
    setState(() => _cargando = true);
    try {
      final resultado = await _api.post('/ia/generar', {
        'categoria': categoria,
        'hijo_id': _hijoId,
        'dificultad': dificultad,
        'cantidad': 3,
      });
      final nuevos = List<dynamic>.from(resultado['desafios'] ?? []);
      setState(() => _opcionesIA = nuevos);
      if (_opcionesIA.isNotEmpty) {
        _mostrarSelectorIA(context, categoria, dificultad);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarSelectorIA(BuildContext context, String categoria, String dificultad) {
    Set<int> seleccionados = {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Selecciona misiones para $_hijoNombre:",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...List.generate(_opcionesIA.length, (index) {
                    final desafio = _opcionesIA[index];
                    final isSelected = seleccionados.contains(index);
                    return CheckboxListTile(
                      title: Text(desafio['titulo'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${desafio['descripcion']}\n${desafio['puntos']} pts"),
                      value: isSelected,
                      activeColor: Colors.green,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) seleccionados.add(index);
                          else seleccionados.remove(index);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: seleccionados.isEmpty
                          ? null
                          : () {
                              List<Map<String, dynamic>> elegidos = seleccionados
                                  .map((i) => Map<String, dynamic>.from(_opcionesIA[i]))
                                  .toList();
                              Navigator.pop(context);
                              _confirmarVariosDesafios(elegidos, categoria, dificultad);
                            },
                      child: Text("Enviar ${seleccionados.length} misiones"),
                    ),
                  ),
                ],
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
          'dificultad': dificultad.toLowerCase(),
          'hijo_id': _hijoId,
          'esta_activo': false,
        });
      }
      _cargarDesafios();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Misiones enviadas! 🦝' ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Desafíos de $_hijoNombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSeccion('Cognitiva', _desafiosCognitiva, Colors.blue, Icons.psychology),
                  _buildSeccion('Física', _desafiosFisica, Colors.orange, Icons.fitness_center),
                  _buildSeccion('Hogar', _desafiosHogar, Colors.green, Icons.home),
                  if (_desafiosCognitiva.isEmpty &&
                      _desafiosFisica.isEmpty &&
                      _desafiosHogar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No hay desafíos asignados.\nGenera algunos con IA.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _mostrarFormularioIA(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generar nuevos con IA',
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSeccion(
      String titulo, List<dynamic> desafios, Color color, IconData icono) {
    if (desafios.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        ...desafios.map((d) => _buildChallengeCard(d, color, icono)),
      ],
    );
  }

  Widget _buildChallengeCard(Map<dynamic, dynamic> d, Color color, IconData icono) {
    final estaActivo = d['esta_activo'] ?? false;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              estaActivo ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(icono, color: estaActivo ? color : Colors.grey),
        ),
        title: Text(d['titulo'] ?? '',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: estaActivo ? Colors.black87 : Colors.grey[600])),
        subtitle: Text('${d['puntos'] ?? 0} pts • ${d['dificultad'] ?? 'facil'}',
            style: TextStyle(fontSize: 12, color: color)),
        trailing: Switch(
          value: estaActivo,
          activeColor: color,
          onChanged: (val) => _actualizarEstadoMision(d, val),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['descripcion'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.indigo),
                      onPressed: () => _tts.speak(d['descripcion'] ?? ''),
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

  void _mostrarFormularioIA(BuildContext context) {
    String categoria = 'cognitiva';
    String dificultad = 'facil';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generar con IA para $_hijoNombre',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Categoría'),
              DropdownButton<String>(
                isExpanded: true,
                value: categoria,
                items: const [
                  DropdownMenuItem(value: 'cognitiva', child: Text('Cognitiva')),
                  DropdownMenuItem(value: 'fisica', child: Text('Física')),
                  DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                ],
                onChanged: (v) => setModalState(() => categoria = v!),
              ),
              const SizedBox(height: 10),
              const Text('Dificultad'),
              DropdownButton<String>(
                isExpanded: true,
                value: dificultad,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (v) => setModalState(() => dificultad = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDark,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _generarDesafios(categoria, dificultad);
                  },
                  child: const Text('Generar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}