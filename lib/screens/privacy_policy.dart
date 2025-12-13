import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.black),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.asset(
                'assets/images/NewLogo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const Text(
              'ClearedToGo Privacy Policy',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            _buildPolicySection(
              title: 'What We Collect',
              icon: Icons.inventory_2_outlined,
              content: [
                'Basic account information (email address for authentication)',
                'Flight checklist PDFs that you generate through the app',
                'Optional pilot information (name, license number, home base) stored locally on your device',
              ],
            ),
            
            _buildPolicySection(
              title: 'How We Use Your Data',
              icon: Icons.settings_outlined,
              content: [
                'Your generated PDF checklists are securely stored and can be accessed by you and your flight school',
                'Personal information (pilot name, license number, home base) is stored locally on your device only',
                'This personal information is only visible to your flight school when included in PDF checklists',
                'We use secure AWS Amplify authentication to protect your account',
              ],
            ),
            
            _buildPolicySection(
              title: 'Data Storage',
              icon: Icons.storage_outlined,
              content: [
                'Generated PDFs: Stored securely in the cloud and accessible to you and your flight school',
                'Personal pilot details: Stored locally on your device using secure storage',
                'Account credentials: Handled securely through AWS Cognito authentication',
              ],
            ),
            
            _buildPolicySection(
              title: 'Data Sharing',
              icon: Icons.share_outlined,
              content: [
                'Your generated checklist PDFs are shared only with your associated flight school',
                'We do not sell or share your personal information with third parties',
                'Personal pilot details remain on your device and appear only in PDFs you choose to generate',
              ],
            ),
            
            _buildPolicySection(
              title: 'Your Rights',
              icon: Icons.security_outlined,
              content: [
                'You can delete your account and associated data at any time',
                'You control what personal information you choose to enter',
                'All data is handled securely and transparently',
              ],
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: const Text(
                'Thanks for trusting us — and fly safe! ✈️',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPolicySection({
    required String title,
    required IconData icon,
    required List<String> content,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      elevation: 3,
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.black, size: 28),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: content.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
