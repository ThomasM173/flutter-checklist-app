import 'package:flutter/material.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  // Track if disclaimer has been shown this session
  static bool _hasBeenShownThisSession = false;

  static bool shouldShow() {
    return !_hasBeenShownThisSession;
  }

  static void markAsAccepted() {
    _hasBeenShownThisSession = true;
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (shouldShow()) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DisclaimerDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E3A5F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Disclaimer of Claims',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ClearedToGo is an aid to pre-flight preparation and checklist management. It is designed to enhance pilot awareness but must not be relied upon as the sole source of operational information.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'These checklists are not authoritative and must only be used in conjunction with the applicable Pilot\'s Operating Handbook (POH), Aircraft Flight Manual (AFM), approved aircraft checklists, and official aeronautical information.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Weather, operational, and other data presented by the software may be delayed, incomplete, or inaccurate. The pilot in command remains solely responsible for verifying all information, determining the suitability of the aircraft and flight, and ensuring the safe conduct of every flight.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This software is provided "as is" without warranty. ClearedToGo accepts no liability for any loss, damage, or claim arising from the use of, or reliance upon, this software.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  markAsAccepted();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
