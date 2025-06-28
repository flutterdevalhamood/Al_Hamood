import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/main.dart';
import 'package:sample/src/models/user_model.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../repo/auth_repo.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  // Tire app theme colors matching login screen
  static const Color primaryColor = Color(0xFFE94560);
  static const Color darkBlue = Color(0xFF1A1A2E);
  static const Color mediumBlue = Color(0xFF16213E);
  static const Color lightBlue = Color(0xFF0F3460);

  final AuthController _authController = AuthController();
  UserData? _currentUser;
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false);
    });
    _authController.addListener(_updateUser);
  }

  @override
  void dispose() {
    _authController.removeListener(_updateUser);
    super.dispose();
  }

  void _updateUser() {
    if (mounted) {
      setState(() {
        _currentUser = _authController.userData;
      });
    }
  }

  void _logout() async {
    // Show a confirmation dialog before logging out
    bool confirmLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Logout',
                style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to logout from TireHub?',
                style: TextStyle(color: darkBlue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool isSuccess = await _authController.logout(
                      AuthRepo.loginId,
                    );
                    if (isSuccess) {
                      showSuccessSnack("Logged out successfully!");
                      Navigator.pop(context, true);
                    } else {
                      showErrorSnack("Error logging out");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmLogout) {
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);
      Future.delayed(Duration(milliseconds: 500), () {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('User Logged out successfully!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
    }
  }

  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Hero(
        tag: 'profile-image',
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      // Default tire-themed avatar when no image is available
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.tire_repair, size: 35, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final imageUrl = authController.userData?.imageUrl;
        return Drawer(
          elevation: 15,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkBlue, mediumBlue, lightBlue],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header Section with TireHub branding
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    children: [
                      // App Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tire_repair,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TireHub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Section
                      InkWell(
                        onTap: () {
                          NavigationService().pushNavigation(
                            Screenroutes.profileUpdateScreen,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildProfileImage(imageUrl),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi ${AuthRepo.user ?? 'User'}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    if (_currentUser?.role_id != null &&
                                        !_isLoading)
                                      Text(
                                        _currentUser!.role_id!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${AuthRepo.role}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.tire_repair,
                  title: 'Tire Services',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.tyreReplacementListScreen,
                    );
                  },
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.tire_repair,
                  title: 'Swap Tyre',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.swapTyreListScreen,
                    );
                  },
                ),

                // Spacer to push logout to bottom
                SizedBox(height: 40),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),

                const SizedBox(height: 16),

                // Logout
                _buildMenuItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isLogout: true,
                  onTap: () {
                    _logout();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color:
            isLogout
                ? Colors.red.withOpacity(0.15)
                : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isLogout
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isLogout
                    ? Colors.red.withOpacity(0.2)
                    : primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isLogout ? Colors.red[200] : Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red[200] : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color:
              isLogout
                  ? Colors.red[200]?.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
