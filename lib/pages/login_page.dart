import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2139), Color(0xFF2A2D47), Color(0xFF1E2139)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Card(
                        elevation: 20,
                        shadowColor: const Color(
                          0xFF4A5568,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: const Color(0xFF2A2D47).withValues(alpha: 0.9),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(
                                0xFF4A5568,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2A2D47).withValues(alpha: 0.95),
                                const Color(0xFF1E2139).withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo with glow effect
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4299E1,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.asset(
                                      "lib/images/logo.png",
                                      height: 100,
                                      width: 100,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 100,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF4299E1,
                                                ).withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: const Icon(
                                                Icons.account_circle,
                                                size: 70,
                                                color: Color(0xFF4299E1),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Welcome text
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Please enter your password to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Password field with modern styling
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: const Color(
                                          0xFF4299E1,
                                        ).withValues(alpha: 0.8),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: const Color(
                                        0xFF1E2139,
                                      ).withValues(alpha: 0.8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4299E1),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 20,
                                          ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Login button with loading state
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4299E1),
                                      foregroundColor: Colors.white,
                                      elevation: 12,
                                      shadowColor: const Color(
                                        0xFF4299E1,
                                      ).withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
