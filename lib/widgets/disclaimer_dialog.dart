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
                      'This software is not intended to replace certified navigation devices.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'YOU USE THIS PROGRAM AT YOUR OWN RISK. LOCATION DATA MAY BE INACCURATE.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'The author does not guarantee the accuracy and completeness of the information provided.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'The built-in navigation database is provided for information purposes only. It may contain incomplete or even erroneous data.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'During preparation and during flight, the pilot must always use official aeronautical documentation and certified navigational equipment.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This software is provided by \'AS IT IS\' without any explicit and implied guarantees.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'The author is not liable for any damages arising from the use of this software.',
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
