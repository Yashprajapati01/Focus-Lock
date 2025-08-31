import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UninstallDialog extends StatefulWidget {
  const UninstallDialog({super.key});

  @override
  State<UninstallDialog> createState() => _UninstallDialogState();
}

class _UninstallDialogState extends State<UninstallDialog> {
  bool _isUninstalling = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade600, size: 28),
          const SizedBox(width: 12),
          const Text('Uninstall App'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently remove Focus Lock from your device.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What will happen:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• All app data will be deleted\n'
                  '• Focus sessions will be stopped\n'
                  '• App permissions will be revoked\n'
                  '• The app will be completely removed',
                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUninstalling ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUninstalling ? null : _uninstallApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: _isUninstalling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Uninstall'),
        ),
      ],
    );
  }

  Future<void> _uninstallApp() async {
    setState(() {
      _isUninstalling = true;
    });

    try {
      // Using admin rights to uninstall without user confirmation
      const platform = MethodChannel('com.focuslock.admin/uninstall');

      // Call native method to uninstall with admin rights (silent = true)
      // Don't pass packageName, let native side use this.packageName
      final success = await platform.invokeMethod('uninstallApp', {
        'silent': true, // Use admin rights for silent uninstall
      });

      if (success == true) {
        // Close dialog and show success message
        if (mounted) {
          Navigator.of(context).pop(); // Close uninstall dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App uninstall initiated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Silent uninstall returned false');
      }
    } catch (e) {
      // If admin uninstall fails, show error
      if (mounted) {
        setState(() {
          _isUninstalling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silent uninstall failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            action: SnackBarAction(
              label: 'Try Manual',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Close current dialog
                _showSystemUninstallDialog();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSystemUninstallDialog() async {
    try {
      const platform = MethodChannel('com.focuslock.admin/uninstall');
      await platform.invokeMethod('showUninstallDialog');
    } catch (e) {
      // Final fallback - show instructions
      if (mounted) {
        _showManualUninstallInstructions();
      }
    }
  }

  void _showManualUninstallInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Uninstall'),
        content: const Text(
          'To uninstall Focus Lock:\n\n'
          '1. Go to Settings > Apps\n'
          '2. Find "Focus Lock"\n'
          '3. Tap "Uninstall"\n\n'
          'Or use your device\'s app drawer to uninstall.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close instructions
              Navigator.of(context).pop(); // Close uninstall dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
