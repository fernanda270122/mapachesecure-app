import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

const _appsPopulares = [
  {
    'nombre': 'TikTok',
    'package': 'com.zhiliaoapp.musically',
    'icono': Icons.music_video,
  },
  {
    'nombre': 'YouTube',
    'package': 'com.google.android.youtube',
    'icono': Icons.play_circle_fill,
  },
  {
    'nombre': 'Instagram',
    'package': 'com.instagram.android',
    'icono': Icons.camera_alt,
  },
  {
    'nombre': 'Roblox',
    'package': 'com.roblox.client',
    'icono': Icons.videogame_asset,
  },
  {'nombre': 'WhatsApp', 'package': 'com.whatsapp', 'icono': Icons.chat},
  {
    'nombre': 'Facebook',
    'package': 'com.facebook.katana',
    'icono': Icons.facebook,
  },
  {
    'nombre': 'Snapchat',
    'package': 'com.snapchat.android',
    'icono': Icons.camera,
  },
  {
    'nombre': 'Twitter/X',
    'package': 'com.twitter.android',
    'icono': Icons.alternate_email,
  },
  {
    'nombre': 'Minecraft',
    'package': 'com.mojang.minecraftpe',
    'icono': Icons.grid_on,
  },
  {
    'nombre': 'Netflix',
    'package': 'com.netflix.mediaclient',
    'icono': Icons.tv,
  },
];

class ConfigurarHijoScreen extends StatefulWidget {
  final Map<String, dynamic> hijo;
  const ConfigurarHijoScreen({super.key, required this.hijo});

  @override
  State<ConfigurarHijoScreen> createState() => _ConfigurarHijoScreenState();
}

class _ConfigurarHijoScreenState extends State<ConfigurarHijoScreen> {
  // Apps bloqueadas
  List<dynamic> _appsBlockeadas = [];
  bool _cargando = true;
  // Bloqueos programados
  List<dynamic> _bloqueos = [];

  // Modo seleccionado para agregar bloqueo
  String? _modoSeleccionado;
  // 'inmediato', 'horario', 'calendario'

  // Horario
  int _horaInicio = 20;
  int _minutoInicio = 0;
  int _horaFin = 22;
  int _minutoFin = 0;

  // Días de la semana (1=lun, 7=dom)
  final Set<int> _diasSeleccionados = {};
  final _diasNombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final Set<String> _appsSeleccionadasParaHorario = {};

  bool _estaBloqueadaPorHorario(Map bloqueo, String packageActual) {
    if (bloqueo['tipo'] != 'horario' || bloqueo['package_names'] == null) {
      return false;
    }
    final ahora = DateTime.now();
    final int horaActualMin = ahora.hour * 60 + ahora.minute;

    int aMinutos(String s) {
      final partes = s.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    }

    final int inicioMin = aMinutos(bloqueo['hora_inicio']);
    final int finMin = aMinutos(bloqueo['hora_fin']);
    final List<dynamic> dias = jsonDecode(bloqueo['dias_semana']);
    if (!dias.contains(ahora.weekday)) return false;

    bool enHorario = horaActualMin >= inicioMin && horaActualMin <= finMin;
    List<String> appsEnRegla = (bloqueo['package_names'] as String).split(',');
    return enHorario && appsEnRegla.contains(packageActual);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _cargarDatos() async {
    await Future.wait([_cargarApps(), _cargarBloqueos()]);
  }

  Future<void> _cargarApps() async {
    try {
      final api = ApiService();
      final apps = await api.get('/apps/${widget.hijo['id']}');
      setState(() {
        _appsBlockeadas = apps is List ? apps : [];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  bool _estaBloqueada(String package) =>
      _appsBlockeadas.any((a) => a['package_name'] == package);

  String? _getAppId(String package) {
    final app = _appsBlockeadas.firstWhere(
      (a) => a['package_name'] == package,
      orElse: () => null,
    );
    return app?['id'];
  }

  Future<void> _toggleApp(Map app, bool activar) async {
    final api = ApiService();
    try {
      if (activar) {
        await api.post('/apps/', {
          'hijo_id': widget.hijo['id'],
          'nombre_app': app['nombre'],
          'package_name': app['package'],
          'requiere_desafio': true,
        });
      } else {
        final appId = _getAppId(app['package']);
        if (appId != null) await api.delete('/apps/$appId');
      }
      await _cargarApps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cargarBloqueos() async {
    try {
      final api = ApiService();
      final data = await api.get('/bloqueos/${widget.hijo['id']}');
      setState(() => _bloqueos = data is List ? data : []);
    } catch (e) {
      // Vacío si falla
    }
  }

  Future<void> _eliminarBloqueo(String id) async {
    try {
      final api = ApiService();
      await api.delete('/bloqueos/$id');
      await _cargarBloqueos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar bloqueo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarBloqueo() async {
    final api = ApiService();
    try {
      if (_modoSeleccionado == 'horario') {
        if (_diasSeleccionados.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona al menos un día'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (_appsSeleccionadasParaHorario.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona al menos una app para este horario'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final inicio =
            '${_horaInicio.toString().padLeft(2, '0')}:${_minutoInicio.toString().padLeft(2, '0')}';
        final fin =
            '${_horaFin.toString().padLeft(2, '0')}:${_minutoFin.toString().padLeft(2, '0')}';
        final String packageNames = _appsSeleccionadasParaHorario.join(',');

        await api.post('/bloqueos/${widget.hijo['id']}', {
          'tipo': 'horario',
          'hora_inicio': inicio,
          'hora_fin': fin,
          'dias_semana': _diasSeleccionados.toList()..sort(),
          'package_names': packageNames,
        });
      }

      setState(() {
        _modoSeleccionado = null;
        _appsSeleccionadasParaHorario.clear();
      });
      await _cargarBloqueos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bloqueo guardado con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      // Popup informativo que desaparece automáticamente a los 5 segundos
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          Future.delayed(const Duration(seconds: 5), () {
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          });
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF1A237E),
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El bloqueo de apps puede tardar entre 2 a 3 minutos en activarse.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al conectar con el servidor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _scrollPicker(
    int valor,
    int maxValor,
    Color colorPrimario,
    ValueChanged<int> onChanged,
  ) {
    final controller = FixedExtentScrollController(initialItem: valor);
    return SizedBox(
      height: 120,
      width: 60,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: maxValor,
          builder: (context, index) => Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: index == valor
                    ? colorPrimario
                    : Colors.grey.shade400, // <-- REFRESCADO DINÁMICAMENTE
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorHoras(Color colorPrimario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Text(
                  'Inicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _scrollPicker(
                      _horaInicio,
                      24,
                      colorPrimario,
                      (v) => setState(() => _horaInicio = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _scrollPicker(
                      _minutoInicio,
                      60,
                      colorPrimario,
                      (v) => setState(() => _minutoInicio = v),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            Column(
              children: [
                const Text(
                  'Fin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _scrollPicker(
                      _horaFin,
                      24,
                      colorPrimario,
                      (v) => setState(() => _horaFin = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _scrollPicker(
                      _minutoFin,
                      60,
                      colorPrimario,
                      (v) => setState(() => _minutoFin = v),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final inicioMin = _horaInicio * 60 + _minutoInicio;
            final finMin = _horaFin * 60 + _minutoFin;
            final diff = finMin - inicioMin;
            if (diff < 120 && diff > 0) {
              return const Text(
                'El bloqueo debe ser de mínimo 2 horas',
                style: TextStyle(color: Colors.red, fontSize: 12),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _selectorDias(Color colorPrimario) {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final dia = i + 1;
        final seleccionado = _diasSeleccionados.contains(dia);
        return FilterChip(
          label: Text(_diasNombres[i]),
          selected: seleccionado,
          onSelected: (val) => setState(() {
            if (val) {
              _diasSeleccionados.add(dia);
            } else {
              _diasSeleccionados.remove(dia);
            }
          }),
          selectedColor: colorPrimario.withOpacity(
            0.2,
          ), // <-- ADAPTADO DINÁMICAMENTE
          checkmarkColor: colorPrimario,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: seleccionado ? colorPrimario : Colors.grey.shade300,
            ),
          ),
          labelStyle: TextStyle(
            color: seleccionado ? colorPrimario : Colors.grey,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Configurar a ${widget.hijo['nombre']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Bloqueos activos ──────────────────────────────────────
                  const Text(
                    'Bloqueos activos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_bloqueos.isEmpty)
                    const Text(
                      'No hay bloqueos configurados',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    )
                  else
                    ..._bloqueos.map(
                      (b) => _tarjetaBloqueo(b, temaPadre.primary),
                    ),

                  const SizedBox(height: 24),

                  // ── Agregar bloqueo ───────────────────────────────────────
                  const Text(
                    'Agregar bloqueo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _botonModo(
                        'horario',
                        Icons.schedule,
                        'Horario',
                        temaPadre.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_modoSeleccionado == 'horario')
                    _formHorario(temaPadre.primary),

                  const SizedBox(height: 30),

                  // ── Apps a bloquear ───────────────────────────────────────
                  const Text(
                    'Apps a bloquear',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Activa las apps que quieres bloquear durante el bloqueo',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  ..._appsPopulares.map((app) {
                    final String package = app['package'] as String;
                    bool bloqueadaInstante = _estaBloqueada(package);
                    bool bloqueadaPorHorario = _bloqueos.any(
                      (b) => _estaBloqueadaPorHorario(b, package),
                    );

                    final bool estaCheckeada = _modoSeleccionado == 'horario'
                        ? _appsSeleccionadasParaHorario.contains(package)
                        : (bloqueadaInstante || bloqueadaPorHorario);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        secondary: CircleAvatar(
                          backgroundColor: estaCheckeada
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          child: Icon(
                            app['icono'] as IconData,
                            color: estaCheckeada ? Colors.red : Colors.grey,
                          ),
                        ),
                        title: Text(
                          app['nombre'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          bloqueadaPorHorario
                              ? 'Bloqueo Programado Activo'
                              : (estaCheckeada ? 'Bloqueada' : 'Permitida'),
                          style: TextStyle(
                            color: estaCheckeada ? Colors.red : Colors.green,
                          ),
                        ),
                        value: estaCheckeada,
                        activeColor: temaPadre
                            .primary, // <-- ADAPTADO AL BOTÓN PRINCIPAL DEL PADRE
                        onChanged: bloqueadaPorHorario
                            ? null
                            : (val) {
                                if (_modoSeleccionado == 'horario') {
                                  setState(() {
                                    if (val) {
                                      _appsSeleccionadasParaHorario.add(
                                        package,
                                      );
                                    } else {
                                      _appsSeleccionadasParaHorario.remove(
                                        package,
                                      );
                                    }
                                  });
                                } else {
                                  _toggleApp(app, val);
                                }
                              },
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _tarjetaBloqueo(Map b, Color colorPrimario) {
    String diasTexto = "No definidos";
    List<String> listaLimpia = [];
    IconData icono = Icons.schedule;

    if (b['dias_semana'] != null) {
      List<String> nombresDias = [
        "",
        "Lunes",
        "Martes",
        "Miércoles",
        "Jueves",
        "Viernes",
        "Sábado",
        "Domingo",
      ];
      try {
        var rawDias = b['dias_semana'];
        if (rawDias is List) {
          diasTexto = rawDias
              .map((id) => nombresDias[int.parse(id.toString())])
              .join(", ");
        } else {
          String limpio = rawDias
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();
          if (limpio.isNotEmpty) {
            diasTexto = limpio
                .split(',')
                .map((id) => nombresDias[int.parse(id.trim())])
                .join(", ");
          }
        }
      } catch (e) {
        diasTexto = b['dias_semana'].toString();
      }
    }

    if (b['package_names'] != null &&
        b['package_names'].toString().trim().isNotEmpty) {
      try {
        String rawApps = b['package_names'].toString();
        listaLimpia = rawApps.split(RegExp(r',\s*')).map((p) {
          if (p.contains('.')) {
            var segmentos = p.split('.');
            String ident = segmentos.length >= 2
                ? segmentos[segmentos.length - 2]
                : segmentos.last;
            return ident[0].toUpperCase() + ident.substring(1);
          }
          return p.trim().toUpperCase();
        }).toList();
      } catch (e) {
        print("Error en formateo de apps: $e");
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorPrimario.withOpacity(
                    0.1,
                  ), // <-- ADAPTADO DINÁMICAMENTE
                  child: Icon(icono, color: colorPrimario, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "BLOQUEO POR HORARIO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarBloqueo(b['id']),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              "⏰ ${b['hora_inicio']} - ${b['hora_fin']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Días: $diasTexto",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            if (listaLimpia.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "APPS RESTRINGIDAS:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      colorPrimario, // <-- REEMPLAZADO DEEPPURPLE POR TU COLOR NEUTRO
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: listaLimpia.map((nombreApp) {
                  return Chip(
                    label: Text(
                      nombreApp,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorPrimario,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: colorPrimario.withOpacity(0.08),
                    side: BorderSide(color: colorPrimario.withOpacity(0.2)),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _botonModo(
    String modo,
    IconData icono,
    String label,
    Color colorPrimario,
  ) {
    final seleccionado = _modoSeleccionado == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _modoSeleccionado = seleccionado ? null : modo;
          if (_modoSeleccionado == 'horario') {
            _appsSeleccionadasParaHorario.clear();
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? colorPrimario : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorPrimario),
          ),
          child: Column(
            children: [
              Icon(icono, color: seleccionado ? Colors.white : colorPrimario),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: seleccionado ? Colors.white : colorPrimario,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formHorario(Color colorPrimario) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el horario',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _selectorHoras(colorPrimario),
            const SizedBox(height: 16),
            const Text(
              'Repetir los días:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _selectorDias(colorPrimario),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _guardarBloqueo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario, // <-- ADAPTADO DINÁMICAMENTE
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar horario',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
