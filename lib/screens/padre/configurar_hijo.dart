import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
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
  final ApiService _api = ApiService();
  Timer? _relojTimer;
  List<dynamic> _appsBlockeadas = [];
  bool _cargando = true;
  List<dynamic> _bloqueos = [];
  String? _modoSeleccionado;

  int _horaInicio = 20;
  int _minutoInicio = 0;
  int _horaFin = 22;
  int _minutoFin = 0;

  final Set<int> _diasSeleccionados = {};
  final _diasNombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final Set<String> _appsSeleccionadasParaHorario = {};

  // Determinar si hay un bloqueo total activo en el backend
  bool get _hayBloqueoTotalActivo => _bloqueos.any((b) => b['tipo'] == 'total');

  bool _estaBloqueadaPorHorario(Map bloqueo, String packageActual) {
    if (bloqueo['tipo'] != 'horario' || bloqueo['package_names'] == null) {
      return false;
    }

    // 🇨🇱 FORZAR HORARIO CHILENO (UTC -4)
    // DateTime.now().toUtc() nos da la hora cero global.
    // Le restamos 4 horas estrictas para tener siempre la hora exacta de Chile Continental.
    final ahoraChile = DateTime.now().toUtc().subtract(
      const Duration(hours: 4),
    );

    final int horaActualMin = ahoraChile.hour * 60 + ahoraChile.minute;

    int aMinutos(String s) {
      final partes = s.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    }

    try {
      final int inicioMin = aMinutos(bloqueo['hora_inicio']);
      final int finMin = aMinutos(bloqueo['hora_fin']);

      // 1. Decodificamos los días que vienen del backend
      final List<dynamic> diasRaw = jsonDecode(bloqueo['dias_semana']);
      List<int> diasEnEnteros = diasRaw
          .map((d) => int.parse(d.toString()))
          .toList();

      // 2. Usamos el día de la semana calculado bajo el horario de Chile
      // Dart: 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, etc.
      if (!diasEnEnteros.contains(ahoraChile.weekday)) return false;

      bool enHorario = horaActualMin >= inicioMin && horaActualMin <= finMin;

      // Limpieza de espacios fantasmas para asegurar el bloqueo
      List<String> appsEnRegla = (bloqueo['package_names'] as String)
          .split(',')
          .map((package) => package.trim())
          .toList();

      return enHorario && appsEnRegla.contains(packageActual.trim());
    } catch (e) {
      debugPrint("Error en evaluación con Zona Horaria Chile: $e");
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _relojTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relojTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([_cargarApps(), _cargarBloqueos()]);
  }

  Future<void> _cargarApps() async {
    try {
      final apps = await _api.get('/apps/${widget.hijo['id']}');
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
    try {
      if (activar) {
        await _api.post('/apps/', {
          'hijo_id': widget.hijo['id'],
          'nombre_app': app['nombre'],
          'package_name': app['package'],
          'requiere_desafio': true,
        });
      } else {
        final appId = _getAppId(app['package']);
        if (appId != null) await _api.delete('/apps/$appId');
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
      final data = await _api.get('/bloqueos/${widget.hijo['id']}');
      setState(() => _bloqueos = data is List ? data : []);
    } catch (e) {
      debugPrint('Error al cargar bloqueos: $e');
    }
  }

  Future<void> _eliminarBloqueo(String id) async {
    try {
      await _api.delete('/bloqueos/$id');
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

  // 🚀 LÓGICA DE GUARDADO COMPLEMENTADA CON BLOQUEO TOTAL
  Future<void> _toggleBloqueoTotal(bool activar) async {
    try {
      if (activar) {
        await _api.post('/bloqueos/${widget.hijo['id']}', {
          'tipo': 'total',
          'hora_inicio': '00:00',
          'hora_fin': '23:59',
          'dias_semana': [0, 1, 2, 3, 4, 5, 6],
          'package_names': _appsPopulares.map((e) => e['package']).join(','),
        });
      } else {
        final bloqueoTotal = _bloqueos.firstWhere(
          (b) => b['tipo'] == 'total',
          orElse: () => null,
        );
        if (bloqueoTotal != null) {
          await _api.delete('/bloqueos/${bloqueoTotal['id']}');
        }
      }
      await _cargarBloqueos();
      _mostrarAlertaRetraso();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al modificar Bloqueo Total')),
      );
    }
  }

  Future<void> _guardarBloqueo() async {
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

        await _api.post('/bloqueos/${widget.hijo['id']}', {
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
      _mostrarAlertaRetraso();
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

  void _mostrarAlertaRetraso() {
    final temaPadre = context.read<TemaPadreProvider>().coloresPadre;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });

        final colorFondoLilaSuave = Color.lerp(
          temaPadre.primary,
          Colors.white,
          0.88,
        )!;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color: temaPadre.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          backgroundColor: colorFondoLilaSuave,
          content: Row(
            children: [
              Icon(Icons.info_outline, color: temaPadre.primary, size: 28.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'El bloqueo de apps puede tardar entre 2 a 3 minutos en activarse y/o desactivarse.',
                  style: TextStyle(
                    color: Colors.black, // Cambiado a negro neto
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scrollPicker(
    int valor,
    int maxValor,
    Color colorPrimario,
    ValueChanged<int> onChanged,
  ) {
    final controller = FixedExtentScrollController(initialItem: valor);
    return SizedBox(
      height: 110.h,
      width: 45.w,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 38.h,
        perspective: 0.003,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: maxValor,
          builder: (context, index) => Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: index == valor ? colorPrimario : Colors.grey.shade400,
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
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Inicio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scrollPicker(
                        _horaInicio,
                        24,
                        colorPrimario,
                        (v) => setState(() => _horaInicio = v),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24.sp,
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
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Icon(Icons.arrow_forward, color: Colors.grey, size: 20.r),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Fin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scrollPicker(
                        _horaFin,
                        24,
                        colorPrimario,
                        (v) => setState(() => _horaFin = v),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24.sp,
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
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Builder(
          builder: (context) {
            final inicioMin = _horaInicio * 60 + _minutoInicio;
            final finMin = _horaFin * 60 + _minutoFin;
            final diff = finMin - inicioMin;
            if (diff < 120 && diff > 0) {
              return Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'El bloqueo debe ser de mínimo 2 horas',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
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
        // i = 0 es Lunes (1), i = 3 es Jueves (4)
        final dia = i;
        final seleccionado = _diasSeleccionados.contains(dia);
        return FilterChip(
          label: Text(_diasNombres[i]), // Utiliza tu lista ['Lun', 'Mar'...]
          selected: seleccionado,
          onSelected: (val) => setState(() {
            if (val) {
              _diasSeleccionados.add(dia);
            } else {
              _diasSeleccionados.remove(dia);
            }
          }),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: seleccionado ? AppColors.primary : Colors.grey,
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom: true,
        child: Container(
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
                  padding: EdgeInsets.all(20.r),
                  children: [
                    // 🚨 NUEVA TARJETA: INTERRUPTOR DE BLOQUEO TOTAL
                    // 🚨 TARJETA DE BLOQUEO TOTAL ADAPTATIVA CON LA PALETA DEL PADRE
                    Card(
                      color: _hayBloqueoTotalActivo
                          ? Color.lerp(
                              temaPadre.primary,
                              Colors.white,
                              0.88,
                            )! // Fondo lila pastel suave si está activo
                          : Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: _hayBloqueoTotalActivo
                              ? temaPadre.primary.withValues(alpha: 0.5)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      margin: EdgeInsets.only(bottom: 20.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: SwitchListTile(
                          title: Text(
                            'Bloqueo Total Inmediato',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color:
                                  Colors.black, // Texto siempre negro y legible
                            ),
                          ),
                          subtitle: Text(
                            _hayBloqueoTotalActivo
                                ? 'El dispositivo está completamente restringido.'
                                : 'Restringe temporalmente todas las aplicaciones.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: _hayBloqueoTotalActivo
                                ? temaPadre.primary
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.block,
                              color: _hayBloqueoTotalActivo
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          activeThumbColor: temaPadre.primary,
                          value: _hayBloqueoTotalActivo,
                          onChanged: (val) => _toggleBloqueoTotal(val),
                        ),
                      ),
                    ),

                    Text(
                      'Bloqueos activos',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (_bloqueos.isEmpty)
                      Text(
                        'No hay bloqueos configurados',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13.sp,
                        ),
                      )
                    else
                      ..._bloqueos.map(
                        (b) => _tarjetaBloqueo(b, temaPadre.primary),
                      ),

                    SizedBox(height: 24.h),

                    // Si el bloqueo total está activo, deshabilitamos la creación de nuevos horarios temporales
                    if (!_hayBloqueoTotalActivo) ...[
                      Text(
                        'Agregar bloqueo',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
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
                      SizedBox(height: 16.h),
                      if (_modoSeleccionado == 'horario')
                        _formHorario(temaPadre.primary),
                      SizedBox(height: 30.h),
                    ],

                    Text(
                      'Apps a bloquear',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _hayBloqueoTotalActivo
                          ? 'Todas las apps están bloqueadas debido al Bloqueo Total'
                          : 'Activa las apps que quieres bloquear durante el bloqueo',
                      style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                    ),
                    SizedBox(height: 12.h),

                    ..._appsPopulares.map((app) {
                      final String package = app['package'] as String;
                      bool bloqueadaInstante = _estaBloqueada(package);
                      bool bloqueadaPorHorario = _bloqueos.any(
                        (b) => _estaBloqueadaPorHorario(b, package),
                      );

                      final bool estaCheckeada =
                          _hayBloqueoTotalActivo ||
                          (_modoSeleccionado == 'horario'
                              ? _appsSeleccionadasParaHorario.contains(package)
                              : (bloqueadaInstante || bloqueadaPorHorario));

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        margin: EdgeInsets.only(bottom: 8.h),
                        child: SwitchListTile(
                          secondary: CircleAvatar(
                            backgroundColor: estaCheckeada
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            child: Icon(
                              app['icono'] as IconData,
                              color: estaCheckeada ? Colors.red : Colors.grey,
                              size: 20.r,
                            ),
                          ),
                          title: Text(
                            app['nombre'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          subtitle: Text(
                            _hayBloqueoTotalActivo
                                ? 'Bloqueo Total Activo'
                                : (bloqueadaPorHorario
                                      ? 'Bloqueo Programado Activo'
                                      : (estaCheckeada
                                            ? 'Bloqueada'
                                            : 'Permitida')),
                            style: TextStyle(
                              color: estaCheckeada ? Colors.red : Colors.green,
                              fontSize: 12.sp,
                            ),
                          ),
                          value: estaCheckeada,
                          activeThumbColor: _hayBloqueoTotalActivo
                              ? Colors.red
                              : temaPadre.primary,
                          onChanged:
                              (_hayBloqueoTotalActivo || bloqueadaPorHorario)
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
                    SizedBox(height: 20.h),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tarjetaBloqueo(Map b, Color colorPrimario) {
    String diasTexto = "No definidos";
    List<String> listaLimpia = [];
    IconData icono = b['tipo'] == 'total' ? Icons.block : Icons.schedule;

    if (b['dias_semana'] != null) {
      List<String> nombresDias = [
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
          final packageBuscado = p.trim();

          final appPopular = _appsPopulares.firstWhere(
            (element) => element['package'] == packageBuscado,
            orElse: () => {},
          );

          if (appPopular.isNotEmpty) {
            return appPopular['nombre'] as String;
          }

          if (packageBuscado.contains('.')) {
            var segmentos = packageBuscado.split('.');
            String ident = segmentos.length >= 2
                ? segmentos[segmentos.length - 2]
                : segmentos.last;
            return ident[0].toUpperCase() + ident.substring(1);
          }
          return packageBuscado.toUpperCase();
        }).toList();
      } catch (e) {
        debugPrint("Error en formateo de apps: $e");
      }
    }

    final isTotal = b['tipo'] == 'total';

    return Card(
      color: isTotal ? Colors.red.shade50 : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
        side: BorderSide(
          color: isTotal
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isTotal
                      ? Colors.red.withValues(alpha: 0.2)
                      : colorPrimario.withValues(alpha: 0.1),
                  child: Icon(
                    icono,
                    color: isTotal ? Colors.red : colorPrimario,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    isTotal
                        ? "BLOQUEO TOTAL DISPOSITIVO"
                        : "BLOQUEO POR HORARIO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: isTotal
                          ? Colors.red.shade900
                          : Colors.grey.shade700,
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
            Divider(height: 24.h),

            Text(
              isTotal
                  ? "🚫 RESTRICCIÓN ABSOLUTA"
                  : "⏰ ${b['hora_inicio']} - ${b['hora_fin']}",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.red : colorPrimario,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.r,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "Días: $diasTexto",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            if (listaLimpia.isNotEmpty && !isTotal) ...[
              SizedBox(height: 16.h),
              Text(
                "APPS RESTRINGIDAS:",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: listaLimpia.map((nombreApp) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrimario.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: colorPrimario.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      nombreApp,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colorPrimario,
                        fontWeight: FontWeight.bold,
                      ),
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
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: seleccionado ? colorPrimario : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: colorPrimario),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                color: seleccionado ? Colors.white : colorPrimario,
                size: 24.r,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona el horario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            _selectorHoras(colorPrimario),
            SizedBox(height: 16.h),
            Text(
              'Repetir los días:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            _selectorDias(colorPrimario),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _guardarBloqueo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Guardar horario',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
