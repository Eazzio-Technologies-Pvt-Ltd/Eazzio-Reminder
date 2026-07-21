import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../theme.dart';
import '../services/native_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  
  late String _appMode;
  late TextEditingController _apiUrlController;
  late String _themeMode;
  late TextEditingController _countryCodeController;

  final _templateTaskController = TextEditingController();
  final _templateAnniversaryController = TextEditingController();
  final _templateFeeController = TextEditingController();
  final _templateCustomController = TextEditingController();
  final _templateBirthdayController = TextEditingController();

  String _soundTask = 'default';
  String _soundAnniversary = 'default';
  String _soundFee = 'default';
  String _soundCustom = 'default';
  String _soundBirthday = 'default';
  
  bool _smsPermission = false;
  bool _accessibilityEnabled = false;
  bool _exactAlarmPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = Provider.of<ReminderProvider>(context, listen: false);
    _appMode = provider.appMode;
    _apiUrlController = TextEditingController(text: provider.apiBaseUrl);
    _themeMode = provider.themeModeStr;
    _countryCodeController = TextEditingController(text: provider.defaultCountryCode);
    _loadCustomSettings();
    _checkNativePermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiUrlController.dispose();
    _countryCodeController.dispose();
    _templateTaskController.dispose();
    _templateAnniversaryController.dispose();
    _templateFeeController.dispose();
    _templateCustomController.dispose();
    _templateBirthdayController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNativePermissions();
    }
  }

  Future<void> _loadCustomSettings() async {
    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final tTask = await provider.getTemplate('task') ?? 'Hi {name}, this is a reminder for your task: {title}. Please check. 🔔';
    final tAnniversary = await provider.getTemplate('anniversary') ?? 'Happy Anniversary, {name}! 💖 Wishing you another year of love, happiness, and beautiful memories together.';
    final tFee = await provider.getTemplate('fee') ?? 'Dear {name}, this is a friendly reminder that your outstanding fee is due. Please clear it at your earliest convenience. Thank you. 💵';
    final tCustom = await provider.getTemplate('custom') ?? 'Hi {name}, this is a quick reminder for your upcoming schedule. Please check. 🔔';
    final tBirthday = await provider.getTemplate('birthday') ?? 'Happy Birthday, {name}! 🎂 Wishing you a wonderful year ahead filled with love, laughter, and success. Have an amazing day!';

    _soundTask = await provider.getNotificationSoundSetting('task');
    _soundAnniversary = await provider.getNotificationSoundSetting('anniversary');
    _soundFee = await provider.getNotificationSoundSetting('fee');
    _soundCustom = await provider.getNotificationSoundSetting('custom');
    _soundBirthday = await provider.getNotificationSoundSetting('birthday');

    if (mounted) {
      setState(() {
        _templateTaskController.text = tTask;
        _templateAnniversaryController.text = tAnniversary;
        _templateFeeController.text = tFee;
        _templateCustomController.text = tCustom;
        _templateBirthdayController.text = tBirthday;
      });
    }
  }

  Future<void> _checkNativePermissions() async {
    final sms = await NativeService.hasSmsPermission();
    final acc = await NativeService.isAccessibilityServiceEnabled();
    final exact = await NativeService.hasExactAlarmPermission();
    if (mounted) {
      setState(() {
        _smsPermission = sms;
        _accessibilityEnabled = acc;
        _exactAlarmPermission = exact;
      });
    }
  }

  Future<void> _requestSmsWithExplanation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'Allow SMS access to notify your reminder contacts automatically from the background when a reminder triggers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final granted = await NativeService.requestSmsPermission();
      setState(() => _smsPermission = granted);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Save custom templates
    provider.saveTemplateSetting('task', _templateTaskController.text.trim());
    provider.saveTemplateSetting('anniversary', _templateAnniversaryController.text.trim());
    provider.saveTemplateSetting('fee', _templateFeeController.text.trim());
    provider.saveTemplateSetting('custom', _templateCustomController.text.trim());
    provider.saveTemplateSetting('birthday', _templateBirthdayController.text.trim());

    // Save default category sounds
    provider.saveSoundSetting('task', _soundTask);
    provider.saveSoundSetting('anniversary', _soundAnniversary);
    provider.saveSoundSetting('fee', _soundFee);
    provider.saveSoundSetting('custom', _soundCustom);
    provider.saveSoundSetting('birthday', _soundBirthday);

    provider.updateSettings(
      appMode: _appMode,
      apiBaseUrl: _apiUrlController.text.trim(),
      themeMode: _themeMode,
      defaultCountryCode: _countryCodeController.text.trim(),
    ).then((_) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Settings saved and applied successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      if (!widget.isTab) {
        navigator.pop();
      }
    }).catchError((err) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $err'),
          backgroundColor: AppTheme.danger,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Application Settings',
          style: TextStyle(color: theme.brightness == Brightness.light ? Colors.black87 : Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: theme.brightness == Brightness.light ? Colors.black87 : Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          image: isDark
              ? const DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.20,
                )
              : null,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Appearance (Dark / Light)
                  Text(
                    'Appearance',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeCard(
                          selected: _themeMode == 'dark',
                          title: 'Dark Theme',
                          subtitle: 'Sleek dark aesthetics',
                          icon: Icons.dark_mode_rounded,
                          onTap: () => setState(() => _themeMode = 'dark'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeCard(
                          selected: _themeMode == 'light',
                          title: 'Light Theme',
                          subtitle: 'Clean white styles',
                          icon: Icons.light_mode_rounded,
                          onTap: () => setState(() => _themeMode = 'light'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Default country code
                  Text(
                    'Phone Number Options',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Default Country Code',
                      prefixIcon: Icon(Icons.public),
                      hintText: '+91',
                      helperText: 'Auto-prepended to phone numbers if they are entered without a country code.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Sounds settings corner
                  Text(
                    'Notification Sound Settings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSoundSelector('task', 'Tasks Default Sound', _soundTask, (val) => setState(() => _soundTask = val)),
                          const Divider(),
                          _buildSoundSelector('birthday', 'Birthday Default Sound', _soundBirthday, (val) => setState(() => _soundBirthday = val)),
                          const Divider(),
                          _buildSoundSelector('anniversary', 'Anniversary Default Sound', _soundAnniversary, (val) => setState(() => _soundAnniversary = val)),
                          const Divider(),
                          _buildSoundSelector('fee', 'Fees Default Sound', _soundFee, (val) => setState(() => _soundFee = val)),
                          const Divider(),
                          _buildSoundSelector('custom', 'Custom Events Default Sound', _soundCustom, (val) => setState(() => _soundCustom = val)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message templates editing
                  Text(
                    'Default Message Templates',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTemplateField('Task Template', _templateTaskController),
                          const SizedBox(height: 16),
                          _buildTemplateField('Birthday Template', _templateBirthdayController),
                          const SizedBox(height: 16),
                          _buildTemplateField('Anniversary Template', _templateAnniversaryController),
                          const SizedBox(height: 16),
                          _buildTemplateField('Fees Template', _templateFeeController),
                          const SizedBox(height: 16),
                          _buildTemplateField('Custom Template', _templateCustomController),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permissions & Automation
                  Text(
                    'Permissions & Automation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            _exactAlarmPermission ? Icons.check_circle : Icons.error_outline,
                            color: _exactAlarmPermission ? AppTheme.success : AppTheme.warning,
                            size: 28,
                          ),
                          title: const Text('Exact Alarms', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            _exactAlarmPermission
                                ? 'Permission Granted: Reminders fire exactly on scheduled time.'
                                : 'Permission Denied: Delayed triggers possible. Alarms will use inexact intervals.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: !_exactAlarmPermission
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
                                  onPressed: () async {
                                    await NativeService.requestExactAlarmPermission();
                                  },
                                  child: const Text('Enable'),
                                )
                              : null,
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            _smsPermission ? Icons.check_circle : Icons.error_outline,
                            color: _smsPermission ? AppTheme.success : AppTheme.warning,
                            size: 28,
                          ),
                          title: const Text('SMS Direct Sending', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            _smsPermission
                                ? 'Permission Granted: SMS sends silently in background.'
                                : 'Permission Denied: Opens native SMS composer.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: !_smsPermission
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
                                  onPressed: _requestSmsWithExplanation,
                                  child: const Text('Grant'),
                                )
                              : null,
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            _accessibilityEnabled ? Icons.check_circle : Icons.error_outline,
                            color: _accessibilityEnabled ? AppTheme.success : AppTheme.warning,
                            size: 28,
                          ),
                          title: const Text('WhatsApp Auto-Clicker', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            _accessibilityEnabled
                                ? 'Accessibility Enabled: WhatsApp sends automatically.'
                                : 'Service Disabled: Enable Eazzio Auto-Send in settings.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: !_accessibilityEnabled
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
                                  onPressed: () async {
                                    await NativeService.openAccessibilitySettings();
                                  },
                                  child: const Text('Enable'),
                                )
                              : null,
                        ),
                        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                          const Divider(),
                          const ListTile(
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warning,
                              size: 28,
                            ),
                            title: Text('iOS Notification Limitations', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'iOS restricts looping alarm sounds in the background. Tap standard local alerts to see reminder details.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Account Actions section
                  Text(
                    'Account Actions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0x08FFFFFF) : const Color(0xFFFEE2E2).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.danger,
                        size: 28,
                      ),
                      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
                      subtitle: const Text('Sign out of your account on this device.', style: TextStyle(fontSize: 12)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to sign out of your account?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    final provider = Provider.of<ReminderProvider>(context, listen: false);
                                    provider.logout().then((_) {
                                      if (mounted) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      }
                                    });
                                  },
                                  child: const Text('Logout', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Logout'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('Save & Apply Settings'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : (isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : (isDark ? AppTheme.textSecondary : Colors.black54),
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected
                    ? (isDark ? Colors.white : AppTheme.primary)
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.textSecondary : Colors.black54,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector(String type, String label, String value, void Function(String) onSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCustomSound = value.startsWith('content://') || value.startsWith('file://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (isCustomSound)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'URI: ...${value.substring(value.length > 25 ? value.length - 25 : 0)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: isCustomSound ? 'custom_uri' : value,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: 'default', child: Text('Default Sound', style: TextStyle(fontSize: 12))),
                  const DropdownMenuItem(value: 'ringtone', child: Text('Phone Ringtone', style: TextStyle(fontSize: 12))),
                  const DropdownMenuItem(value: 'alarm', child: Text('Device Alarm', style: TextStyle(fontSize: 12))),
                  if (isCustomSound)
                    const DropdownMenuItem(value: 'custom_uri', child: Text('Custom Ringtone', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null && val != 'custom_uri') {
                    onSelected(val);
                  }
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.audiotrack, size: 18, color: AppTheme.primary),
                tooltip: 'Select Custom File/Ringtone',
                onPressed: () async {
                  final pickedUri = await NativeService.pickRingtone();
                  if (pickedUri != 'default') {
                    onSelected(pickedUri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Use {name} or {title} as placeholders.',
      ),
    );
  }
}
