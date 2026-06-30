import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _service = NotificationService.instance;

  bool _isPermissionGranted = false;

  // Controllers for unique scheduled notification
  late bool _isScheduledActive;
  late TextEditingController _scheduledTitleCtrl;
  late TextEditingController _scheduledBodyCtrl;
  DateTime? _scheduledTime;

  // Controllers for recurring notification
  late bool _isRecurringActive;
  late TextEditingController _recurringTitleCtrl;
  late TextEditingController _recurringBodyCtrl;
  late TimeOfDay _recurringTime;

  // Test countdown state
  int _testCountdown = 0;
  Timer? _countdownTimer;

  // Future for pending notifications
  late Future<List<PendingNotificationRequest>> _pendingRequestsFuture;

  @override
  void initState() {
    super.initState();
    _checkPermission();

    // Load initial states from service
    _isScheduledActive = _service.isScheduledActive;
    _scheduledTitleCtrl = TextEditingController(text: _service.scheduledTitle);
    _scheduledBodyCtrl = TextEditingController(text: _service.scheduledBody);
    _scheduledTime = _service.scheduledTime;

    _isRecurringActive = _service.isRecurringActive;
    _recurringTitleCtrl = TextEditingController(text: _service.recurringTitle);
    _recurringBodyCtrl = TextEditingController(text: _service.recurringBody);
    _recurringTime = _service.recurringTime;

    // Initialize the pending requests future
    _pendingRequestsFuture = _service.getPendingRequests();
  }

  void _refreshPendingRequests() {
    if (mounted) {
      setState(() {
        _pendingRequestsFuture = _service.getPendingRequests();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scheduledTitleCtrl.dispose();
    _scheduledBodyCtrl.dispose();
    _recurringTitleCtrl.dispose();
    _recurringBodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final granted = await _service.checkPermission();
    setState(() {
      _isPermissionGranted = granted;
    });
  }

  Future<void> _requestPermission() async {
    final success = await _service.requestPermissions();
    setState(() {
      _isPermissionGranted = success;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Permiso de notificaciones otorgado con éxito'
                : 'Permiso denegado. Actívalo en los ajustes de tu dispositivo.',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? now.add(const Duration(minutes: 5)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _scheduledTime != null
            ? TimeOfDay.fromDateTime(_scheduledTime!)
            : const TimeOfDay(hour: 12, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.cyanAccent,
                onPrimary: Colors.black,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0F172A),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectRecurringTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _recurringTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _recurringTime = pickedTime;
      });
    }
  }

  Future<void> _saveAllSettings() async {
    // Save state back to the service
    _service.isScheduledActive = _isScheduledActive;
    _service.scheduledTitle = _scheduledTitleCtrl.text.trim();
    _service.scheduledBody = _scheduledBodyCtrl.text.trim();
    _service.scheduledTime = _scheduledTime;

    _service.isRecurringActive = _isRecurringActive;
    _service.recurringTitle = _recurringTitleCtrl.text.trim();
    _service.recurringBody = _recurringBodyCtrl.text.trim();
    _service.recurringTime = _recurringTime;

    await _service.updateScheduledNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajustes de notificaciones guardados y actualizados'),
          backgroundColor: Colors.cyan,
        ),
      );
      _refreshPendingRequests(); // Refresh view and pending list smoothly
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "No seleccionada";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} a las ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes de Notificaciones',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Status Card
            _buildCard(
              title: 'Estado de Permisos',
              icon: Icons.security,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPermissionGranted
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPermissionGranted ? 'Permitido' : 'No Permitido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isPermissionGranted
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  if (!_isPermissionGranted)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _requestPermission,
                      child: const Text('Solicitar Permiso'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scheduled Notification Card (Unique)
            _buildCard(
              title: 'Notificación Programada',
              icon: Icons.calendar_today,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activar Recordatorio Único'),
                    subtitle: const Text(
                      'Ideal para avisar del fin de una impresión o entrega.',
                    ),
                    value: _isScheduledActive,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) {
                      setState(() {
                        _isScheduledActive = val;
                      });
                    },
                  ),
                  if (_isScheduledActive) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _scheduledTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título de la Notificación',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scheduledBodyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje de la Notificación',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Fecha y Hora Programada:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      subtitle: Text(
                        _formatDateTime(_scheduledTime),
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.edit_calendar,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: _selectDateTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recurring Notification Card (Periodic)
            _buildCard(
              title: 'Notificación Recurrente',
              icon: Icons.update,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activar Recordatorio Diario'),
                    subtitle: const Text(
                      'Ideal para recordar control de stock o mantenimiento diario.',
                    ),
                    value: _isRecurringActive,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) {
                      setState(() {
                        _isRecurringActive = val;
                      });
                    },
                  ),
                  if (_isRecurringActive) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recurringTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recurringBodyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje del Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Hora de Alerta Diaria:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      subtitle: Text(
                        _recurringTime.format(context),
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.access_time,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: _selectRecurringTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual / Testing Card
            _buildCard(
              title: 'Pruebas de Notificaciones',
              icon: Icons.bug_report,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Prueba Inmediata'),
                          onPressed: () async {
                            await _service.showInstantNotification(
                              id: NotificationService.testNotificationId,
                              title: '🔔 ¡Prueba Instantánea Exitosa!',
                              body:
                                  'Esta notificación demuestra que las notificaciones de ImprimiLab funcionan correctamente en este dispositivo.',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _testCountdown > 0 ? Colors.grey : Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(_testCountdown > 0 ? Icons.hourglass_bottom : Icons.timer),
                          label: Text(_testCountdown > 0 ? 'Espera (${_testCountdown}s)' : 'Prueba en 5 Seg'),
                          onPressed: _testCountdown > 0 ? null : () async {
                            final scheduledTime = DateTime.now().add(
                              const Duration(seconds: 5),
                            );
                            await _service.scheduleUniqueNotification(
                              id: NotificationService
                                  .testScheduledNotificationId,
                              title: '⏰ Recordatorio de Prueba',
                              body:
                                  'Este recordatorio de 5 segundos funciona de forma idéntica a tus recordatorios a largo plazo.',
                              scheduledDate: scheduledTime,
                              isTest: true,
                            );

                            setState(() {
                              _testCountdown = 5;
                            });

                            _countdownTimer?.cancel();
                            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                              if (mounted) {
                                setState(() {
                                  if (_testCountdown > 0) {
                                    _testCountdown--;
                                  } else {
                                    timer.cancel();
                                    _refreshPendingRequests();
                                  }
                                });
                              } else {
                                timer.cancel();
                              }
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notificación de prueba programada para dentro de 5 segundos. Cierra o sal de la app.',
                                ),
                                duration: Duration(seconds: 4),
                              ),
                            );

                            // Refresh list to show pending
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                _refreshPendingRequests();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending Notifications List Card
            _buildCard(
              title: 'Notificaciones Pendientes en Sistema',
              icon: Icons.list_alt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Muestra las alertas registradas en el motor nativo del celular:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<PendingNotificationRequest>>(
                    future: _pendingRequestsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No hay notificaciones programadas activas.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (ctx, index) {
                          final req = snapshot.data![index];
                          String typeLabel = "Desconocido";
                          if (req.id ==
                              NotificationService
                                  .uniqueScheduledNotificationId) {
                            typeLabel = "Recordatorio Único";
                          } else if (req.id ==
                              NotificationService.recurringNotificationId) {
                            typeLabel = "Recordatorio Diario";
                          } else if (req.id ==
                              NotificationService.testScheduledNotificationId) {
                            typeLabel = "Prueba (5 segundos)";
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.alarm,
                                color: Colors.cyanAccent,
                              ),
                              title: Text(
                                req.title ?? 'Sin Título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Tipo: $typeLabel\nMsg: ${req.body ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Limpiar Todas las Notificaciones'),
                    onPressed: () async {
                      await _service.cancelAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Todas las notificaciones programadas han sido canceladas.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      setState(() {
                        _isScheduledActive = false;
                        _isRecurringActive = false;
                      });
                      _refreshPendingRequests();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save settings Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveAllSettings,
              child: const Text(
                'GUARDAR Y APLICAR AJUSTES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24, thickness: 1),
          child,
        ],
      ),
    );
  }
}
