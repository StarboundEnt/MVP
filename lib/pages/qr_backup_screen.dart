import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../services/backup_service.dart';

/// Screen to generate and display QR backup code
class QRBackupScreen extends StatefulWidget {
  const QRBackupScreen({Key? key}) : super(key: key);

  @override
  State<QRBackupScreen> createState() => _QRBackupScreenState();
}

class _QRBackupScreenState extends State<QRBackupScreen> {
  final BackupService _backupService = BackupService();
  final TextEditingController _passphraseController = TextEditingController();

  BackupResult? _backupResult;
  BackupData? _backupData;
  bool _isGenerating = false;
  bool _showPassphrase = false;
  bool _useCustomPassphrase = false;

  @override
  void initState() {
    super.initState();
    _generateBackupPreview();
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _generateBackupPreview() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final data = await _backupService.createBackupData(appState);
    setState(() => _backupData = data);
  }

  Future<void> _generateBackup() async {
    setState(() => _isGenerating = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final passphrase =
          _useCustomPassphrase ? _passphraseController.text.trim() : null;

      final result = await _backupService.generateBackup(
        appState,
        passphrase: passphrase,
      );

      setState(() {
        _backupResult = result;
        _isGenerating = false;
      });

      if (!result.success) {
        _showError(result.error ?? 'Failed to generate backup');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError('Error generating backup: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
      ),
    );
  }

  Future<void> _shareBackup() async {
    if (_backupResult?.filePath != null) {
      await Share.shareXFiles(
        [XFile(_backupResult!.filePath!)],
        subject: 'Starbound Backup',
        text: 'My Starbound health data backup',
      );
    } else if (_backupResult?.qrData != null) {
      await Share.share(
        _backupResult!.qrData!,
        subject: 'Starbound Backup Data',
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_backupResult?.qrData != null) {
      await Clipboard.setData(ClipboardData(text: _backupResult!.qrData!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup data copied to clipboard'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Backup Your Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Backup summary
            if (_backupData != null) ...[
              _buildSummaryCard(),
              const SizedBox(height: 24),
            ],

            // Passphrase option
            _buildPassphraseSection(),
            const SizedBox(height: 24),

            // Generate button or QR display
            if (_backupResult == null)
              _buildGenerateButton()
            else
              _buildBackupDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 20),
              SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Your data is encrypted before creating the QR code\n'
            '• Scan the QR code on your new device to restore\n'
            '• Large backups are saved as a file you can share\n'
            '• Add a passphrase for extra security (optional)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What will be backed up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.person_outline,
            'Profile & preferences',
            _backupData!.profile != null,
          ),
          _buildSummaryRow(
            Icons.bookmark_outline,
            'Saved resources',
            _backupData!.savedResources.isNotEmpty,
            count: _backupData!.savedResources.length,
          ),
          _buildSummaryRow(
            Icons.chat_bubble_outline,
            'Saved conversations',
            _backupData!.savedConversations.isNotEmpty,
            count: _backupData!.savedConversations.length,
          ),
          _buildSummaryRow(
            Icons.calendar_today_outlined,
            'Journal entries',
            _backupData!.journalEntries.isNotEmpty,
            count: _backupData!.journalEntries.length,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _backupData!.canFitInQR ? Icons.qr_code : Icons.file_present,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _backupData!.canFitInQR
                      ? 'Will generate QR code'
                      : 'Will save as file (too large for QR)',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, bool hasData,
      {int? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasData ? const Color(0xFF4ECDC4) : Colors.white30,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasData ? Colors.white70 : Colors.white30,
                fontSize: 13,
              ),
            ),
          ),
          if (count != null && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Icon(
              hasData ? Icons.check_circle : Icons.remove_circle_outline,
              color: hasData ? const Color(0xFF4ECDC4) : Colors.white30,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildPassphraseSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color:
                    _useCustomPassphrase ? const Color(0xFFFFDA3E) : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Custom passphrase (optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _useCustomPassphrase,
                onChanged: (value) {
                  setState(() => _useCustomPassphrase = value);
                },
                activeColor: const Color(0xFFFFDA3E),
              ),
            ],
          ),
          if (_useCustomPassphrase) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passphraseController,
              obscureText: !_showPassphrase,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter a memorable passphrase',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassphrase ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _showPassphrase = !_showPassphrase);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You'll need this passphrase to restore your backup",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isGenerating ? null : _generateBackup,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        disabledBackgroundColor: const Color(0xFF4ECDC4).withOpacity(0.5),
      ),
      child: _isGenerating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 20),
                SizedBox(width: 8),
                Text(
                  'Generate Backup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBackupDisplay() {
    final result = _backupResult!;

    if (!result.success) {
      return _buildErrorDisplay(result.error ?? 'Unknown error');
    }

    return Column(
      children: [
        // QR Code display
        if (result.qrData != null && !result.usedFileFallback) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: result.qrData!,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan this QR code on your new device',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // File fallback notice
        if (result.usedFileFallback) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDA3E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFDA3E).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.file_present,
                  color: Color(0xFFFFDA3E),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Backup saved as file',
                  style: TextStyle(
                    color: Color(0xFFFFDA3E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your data is too large for a QR code. Share the backup file to transfer to your new device.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  result.filePath ?? '',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareBackup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4ECDC4),
                  side: const BorderSide(color: Color(0xFF4ECDC4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Regenerate button
        TextButton(
          onPressed: () {
            setState(() => _backupResult = null);
          },
          child: const Text(
            'Generate new backup',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE74C3C).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE74C3C),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Backup failed',
            style: TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _backupResult = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
