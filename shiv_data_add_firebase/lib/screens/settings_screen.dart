import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'upload_screen.dart'; // Admin panel for uploading data if needed

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'LANGUAGE SELECTION',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                title: 'English',
                code: 'en',
                isSelected: appProvider.currentLanguage == 'en',
                onTap: () => appProvider.setLanguage('en'),
              ),
              _buildLanguageOption(
                context,
                title: 'ગુજરાતી',
                code: 'gu',
                isSelected: appProvider.currentLanguage == 'gu',
                onTap: () => appProvider.setLanguage('gu'),
              ),
              _buildLanguageOption(
                context,
                title: 'हिन्दी',
                code: 'hi',
                isSelected: appProvider.currentLanguage == 'hi',
                onTap: () => appProvider.setLanguage('hi'),
              ),
              
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UploadScreen()),
                  );
                },
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, {
    required String title,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF6B00).withValues(alpha: 0.1) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF6B00)) 
            : const Icon(Icons.circle_outlined, color: Colors.grey),
      ),
    );
  }
}
