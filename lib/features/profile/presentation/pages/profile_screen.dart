import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth/auth_event.dart';
import '../../../auth/presentation/bloc/auth/auth_state.dart';
import '../widgets/uninstall_dialog.dart';

class ProfileDialog {
  // Colors sampled from your image
  static const _outerDark = Color(0xFF211D1A); // background card
  static const _innerPeach = Color(0xFFFFE4CF); // content panel
  static const _ink = Color(0xFF1C1A18); // text/icons
  static const _divider = Color(0xFFAE998A); // thin lines

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierLabel: 'Profile',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved =
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: const _ProfileCard(),
            ),
          ),
        );
      },
    );
  }

  static void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out? Your data will remain synced when you sign back in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxW = w > 520 ? 480.0 : w - 32; // responsive width

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
        width: maxW,
        decoration: BoxDecoration(
          color: ProfileDialog._outerDark,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                blurRadius: 24, offset: Offset(0, 8), color: Colors.black26)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top bar on the dark card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, color: Colors.white70),
                      ),
                    ),
                  ),
                  const Text(
                    'Focus Lock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Inner peach panel
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              decoration: BoxDecoration(
                color: ProfileDialog._innerPeach,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 18),
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.person,
                        size: 36, color: ProfileDialog._ink),
                  ),
                  const SizedBox(height: 10),
                  const Text('........',
                      style: TextStyle(
                          color: ProfileDialog._ink, fontSize: 16)),
                  const SizedBox(height: 16),

                  // Google sign-in / sign-out button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isSignedIn = state is AuthAuthenticated;

                        if (isSignedIn) {
                          return OutlinedButton.icon(
                            onPressed: () {
                              ProfileDialog._showSignOutDialog(context);
                            },
                            icon: const Icon(Icons.logout,
                                color: ProfileDialog._ink),
                            label: const Text(
                              'Sign out',
                              style: TextStyle(
                                  color: ProfileDialog._ink, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: ProfileDialog._ink, width: 1.2),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              backgroundColor: ProfileDialog._innerPeach,
                            ),
                          );
                        }

                        return OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                              const AuthSignInWithGoogleRequested(),
                            );
                          },
                          icon: const _GoogleGlyph(),
                          label: const Text('Sign in with Google',
                              style: TextStyle(
                                  color: ProfileDialog._ink, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: ProfileDialog._ink, width: 1.2),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            backgroundColor: ProfileDialog._innerPeach,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider between header and menu
                  Container(height: 1, color: ProfileDialog._divider),

                  _tile(icon: Icons.block, text: 'Remove Ads', onTap: () {}),
                  _tile(icon: Icons.share, text: 'Share App', onTap: () {}),
                  _tile(
                      icon: Icons.info_outline,
                      text: 'About Us',
                      onTap: () {}),
                  _tile(
                    icon: Icons.delete_outline,
                    text: 'Uninstall app',
                    onTap: () => _showUninstallDialog(context),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Footer links on the dark card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Privacy Policy',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const Text('  ·  ',
                      style: TextStyle(color: Colors.white54)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Terms of Service',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: ProfileDialog._ink),
      title: Text(text,
          style: const TextStyle(color: ProfileDialog._ink, fontSize: 16)),
      onTap: onTap,
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  static void _showUninstallDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const UninstallDialog());
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    // simple "G" mark without assets
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
        Border.all(color: ProfileDialog._ink, width: 1.2),
      ),
      child: const Text('G',
          style: TextStyle(
              color: ProfileDialog._ink, fontWeight: FontWeight.w700)),
    );
  }
}
