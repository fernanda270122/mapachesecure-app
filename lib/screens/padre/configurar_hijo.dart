import 'package:flutter/material.dart';                                                                                                                                                     
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
// import 'package:table_calendar/table_calendar.dart';

const _appsPopulares = [
{'nombre': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icono': Icons.music_video},
{'nombre': 'YouTube', 'package': 'com.google.android.youtube', 'icono': Icons.play_circle_fill},
{'nombre': 'Instagram', 'package': 'com.instagram.android', 'icono': Icons.camera_alt},
{'nombre': 'Roblox', 'package': 'com.roblox.client', 'icono': Icons.videogame_asset},
{'nombre': 'WhatsApp', 'package': 'com.whatsapp', 'icono': Icons.chat},
{'nombre': 'Facebook', 'package': 'com.facebook.katana', 'icono': Icons.facebook},
{'nombre': 'Snapchat', 'package': 'com.snapchat.android', 'icono': Icons.camera},
{'nombre': 'Twitter/X', 'package': 'com.twitter.android', 'icono': Icons.alternate_email},
{'nombre': 'Minecraft', 'package': 'com.mojang.minecraftpe', 'icono': Icons.grid_on},
{'nombre': 'Netflix', 'package': 'com.netflix.mediaclient', 'icono': Icons.tv},
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
String? _modoSeleccionado; // 'inmediato', 'horario', 'calendario'

// Horario
int _horaInicio = 20;
int _minutoInicio = 0;
int _horaFin = 22;
int _minutoFin = 0;

// Días de la semana (1=lun, 7=dom)
final Set<int> _diasSeleccionados = {};
final _diasNombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

// Calendario
// DateTime _focusedDay = DateTime.now();
// final Set<DateTime> _fechasSeleccionadas = {};

@override
void initState() {
super.initState();
_cargarDatos();
}

// ── Carga inicial ──────────────────────────────────────────────────────────

Future<void> _cargarDatos() async {
await Future.wait([_cargarApps(), _cargarBloqueos()]);
}

// ── Apps bloqueadas ──────────────────────────────────────────────────────── 
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
const SnackBar(content: Text('Error al actualizar'), backgroundColor: Colors.red),
);
}
}

// ── Bloqueos programados ───────────────────────────────────────────────────

Future<void> _cargarBloqueos() async {
try {
final api = ApiService();
final data = await api.get('/bloqueos/${widget.hijo['id']}');
setState(() => _bloqueos = data is List ? data : []);
} catch (e) {
// Si falla, se deja lista vacía
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
const SnackBar(content: Text('Error al eliminar bloqueo'), backgroundColor: Colors.red),
);
}
}

Future<void> _guardarBloqueo() async {
final api = ApiService();
try {
// if (_modoSeleccionado == 'inmediato') {
// await api.post('/bloqueos/${widget.hijo['id']}', {'tipo': 'inmediato'});
// } else
if (_modoSeleccionado == 'horario') {
if (_diasSeleccionados.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Selecciona al menos un día'), backgroundColor: Colors.orange),
);
return;
}
final inicio = '${_horaInicio.toString().padLeft(2, '0')}:${_minutoInicio.toString().padLeft(2, '0')}';
final fin = '${_horaFin.toString().padLeft(2, '0')}:${_minutoFin.toString().padLeft(2, '0')}';
await api.post('/bloqueos/${widget.hijo['id']}', {
'tipo': 'horario',
'hora_inicio': inicio,
'hora_fin': fin,
'dias_semana': _diasSeleccionados.toList()..sort(),
});

// } else if (_modoSeleccionado == 'calendario') {
// if (_fechasSeleccionadas.isEmpty) {
// ScaffoldMessenger.of(context).showSnackBar(
// const SnackBar(content: Text('Selecciona al menos una fecha'), backgroundColor: Colors.orange),
// );
// return;
// }
// final inicio = '${_horaInicio.toString().padLeft(2, '0')}:${_minutoInicio.toString().padLeft(2, '0')}';
// final fin = '${_horaFin.toString().padLeft(2, '0')}:${_minutoFin.toString().padLeft(2, '0')}';
// final fechas = _fechasSeleccionadas
// .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
// .join(',');
// await api.post('/bloqueos/${widget.hijo['id']}', {
// 'tipo': 'calendario',
// 'hora_inicio': inicio,
// 'hora_fin': fin,
// 'fechas': fechas,
// });
}

setState(() => _modoSeleccionado = null);
await _cargarBloqueos();
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Bloqueo guardado'), backgroundColor: Colors.green),
);
} catch (e) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Error al guardar bloqueo'), backgroundColor: Colors.red),
);
}
}
// ── Widgets auxiliares ───────────────────────────────────────────────────── 
// Scroll tipo tambor para seleccionar hora o minuto   
Widget _scrollPicker(int valor, int maxValor, ValueChanged<int> onChanged) {
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
        color: index == valor ? AppColors.primary : Colors.grey.shade400,
      ),
    ),
  ),
),
),
);
}

// Selector de hora inicio y fin con scroll
Widget _selectorHoras() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Column(
      children: [
        const Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            _scrollPicker(_horaInicio, 24, (v) => setState(() => _horaInicio = v)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            _scrollPicker(_minutoInicio, 60, (v) => setState(() => _minutoInicio = v)),
          ],
        ),
      ],
    ),
    const Icon(Icons.arrow_forward, color: Colors.grey),
    Column(
      children: [
        const Text('Fin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            _scrollPicker(_horaFin, 24, (v) => setState(() => _horaFin = v)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            _scrollPicker(_minutoFin, 60, (v) => setState(() => _minutoFin = v)),
          ],
        ),
      ],
    ),
  ],
),
const SizedBox(height: 8),
// Mensaje si el bloqueo es menor a 2 horas
Builder(builder: (context) {
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
}),
],
);
}

// Selector de días de la semana
Widget _selectorDias() {
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
  selectedColor: AppColors.primary.withOpacity(0.2),
  checkmarkColor: AppColors.primary,
  labelStyle: TextStyle(
    color: seleccionado ? AppColors.primary : Colors.grey,
    fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
  ),
);
}),
);
}
// ── UI principal ───────────────────────────────────────────────────────────                                                                                                          
@override                                                                                                                                                                                   Widget build(BuildContext context) {
return Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(
    title: Text('Configurar a ${widget.hijo['nombre']}',
        style: const TextStyle(fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  body: AppBackground(
    child: _cargando
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Bloqueos activos ──────────────────────────────────────
              const Text('Bloqueos activos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 10),
              if (_bloqueos.isEmpty)
                const Text('No hay bloqueos configurados',
                    style: TextStyle(color: Colors.grey, fontSize: 13))
              else
                ..._bloqueos.map((b) => _tarjetaBloqueo(b)),

              const SizedBox(height: 24),

              // ── Agregar bloqueo ───────────────────────────────────────
              const Text('Agregar bloqueo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 12),

              // Botones de modo
              Row(
                children: [
                  // _botonModo('inmediato', Icons.block, 'Inmediato'),
                  // const SizedBox(width: 8),
                  _botonModo('horario', Icons.schedule, 'Horario'),
                  // const SizedBox(width: 8),
                  // _botonModo('calendario', Icons.calendar_month, 'Calendario'),
                ],
              ),
              const SizedBox(height: 16),

              // Formulario según modo
              // if (_modoSeleccionado == 'inmediato') _formInmediato(),
              if (_modoSeleccionado == 'horario') _formHorario(),
              // if (_modoSeleccionado == 'calendario') _formCalendario(),

              const SizedBox(height: 30),

              // ── Apps a bloquear ───────────────────────────────────────
              const Text('Apps a bloquear',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 6),
              const Text('Activa las apps que quieres bloquear durante el bloqueo',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              ..._appsPopulares.map((app) {
                final bloqueada = _estaBloqueada(app['package'] as String);
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    secondary: CircleAvatar(
                      backgroundColor: bloqueada ? Colors.red.shade50 : Colors.grey.shade100,
                      child: Icon(app['icono'] as IconData,
                          color: bloqueada ? Colors.red : Colors.grey),
                    ),
                    title: Text(app['nombre'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(bloqueada ? 'Bloqueada' : 'Permitida',
                        style: TextStyle(color: bloqueada ? Colors.red : Colors.green)),
                    value: bloqueada,
                    activeColor: const Color(0xFF1A237E),
                    onChanged: (val) => _toggleApp(app, val),
                  ),
                );
              }),
            ],
          ),
  ),
);
}
// ── Tarjeta de bloqueo activo ──────────────────────────────────────────────                                                                                                          
  Widget _tarjetaBloqueo(Map b) {                                                                                                                                                               String descripcion = '';
    IconData icono = Icons.block;

    // if (b['tipo'] == 'inmediato') {
    //   descripcion = 'Bloqueo inmediato activo';
    //   icono = Icons.block;
    // } else
    if (b['tipo'] == 'horario') {
      descripcion = '${b['hora_inicio']} - ${b['hora_fin']}';
      if (b['dias_semana'] != null) descripcion += '\nDías: ${b['dias_semana']}';
      icono = Icons.schedule;
    }
    // else if (b['tipo'] == 'calendario') {
    //   descripcion = '${b['hora_inicio']} - ${b['hora_fin']}';
    //   if (b['fechas'] != null) descripcion += '\nFechas: ${b['fechas']}';
    //   icono = Icons.calendar_month;
    // }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(icono, color: Colors.red),
        ),
        title: Text(b['tipo'].toString().toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descripcion),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _eliminarBloqueo(b['id']),
        ),
      ),
    );
  }

  // ── Botón de modo ──────────────────────────────────────────────────────────

  Widget _botonModo(String modo, IconData icono, String label) {
    final seleccionado = _modoSeleccionado == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() =>
            _modoSeleccionado = seleccionado ? null : modo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            children: [
              Icon(icono, color: seleccionado ? Colors.white : AppColors.primary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: seleccionado ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formulario inmediato (comentado) ──────────────────────────────────────

  // Widget _formInmediato() {
  //   return Card(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Activar bloqueo ahora mismo',
  //               style: TextStyle(fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 8),
  //           const Text('Todas las apps seleccionadas quedarán bloqueadas inmediatamente.',
  //               style: TextStyle(color: Colors.grey, fontSize: 13)),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               onPressed: _guardarBloqueo,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.red,
  //                 foregroundColor: Colors.white,
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //               ),
  //               child: const Text('Bloquear ahora'),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ── Formulario horario ─────────────────────────────────────────────────────

  Widget _formHorario() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona el horario', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _selectorHoras(),
            const SizedBox(height: 16),
            const Text('Repetir los días:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _selectorDias(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarBloqueo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar horario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulario calendario (comentado) ─────────────────────────────────────

  // Widget _formCalendario() {
  //   return Card(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Selecciona las fechas', style: TextStyle(fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 8),
  //           TableCalendar(
  //             firstDay: DateTime.now(),
  //             lastDay: DateTime.now().add(const Duration(days: 365)),
  //             focusedDay: _focusedDay,
  //             selectedDayPredicate: (day) => _fechasSeleccionadas
  //                 .any((f) => f.year == day.year && f.month == day.month && f.day == day.day),
  //             onDaySelected: (selected, focused) {
  //               setState(() {
  //                 _focusedDay = focused;
  //                 final existe = _fechasSeleccionadas
  //                     .any((f) => f.year == selected.year && f.month == selected.month && f.day == selected.day);
  //                 if (existe) {
  //                   _fechasSeleccionadas.removeWhere(
  //                       (f) => f.year == selected.year && f.month == selected.month && f.day == selected.day);
  //                 } else {
  //                   _fechasSeleccionadas.add(selected);
  //                 }
  //               });
  //             },
  //             calendarStyle: CalendarStyle(
  //               selectedDecoration: BoxDecoration(
  //                 color: AppColors.primary,
  //                 shape: BoxShape.circle,
  //               ),
  //               todayDecoration: BoxDecoration(
  //                 color: AppColors.primary.withOpacity(0.4),
  //                 shape: BoxShape.circle,
  //               ),
  //             ),
  //             headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
  //           ),
  //           const SizedBox(height: 16),
  //           const Text('Selecciona el horario', style: TextStyle(fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 8),
  //           _selectorHoras(),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               onPressed: _guardarBloqueo,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: AppColors.primary,
  //                 foregroundColor: Colors.white,
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //               ),
  //               child: const Text('Guardar bloqueo'),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}