import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_cristiana/features_tv/widgets/tv_pressable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _EditingField {
  none,
  email,
  password,
}

class TvLoginScreen extends StatefulWidget {
  const TvLoginScreen({super.key});

  @override
  State<TvLoginScreen> createState() => _TvLoginScreenState();
}

class _TvLoginScreenState extends State<TvLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailTextFocusNode = FocusNode();
  final _passwordTextFocusNode = FocusNode();
  final _loginButtonFocusNode = FocusNode();
  final _emailCardFocusNode = FocusNode();
  final _passwordCardFocusNode = FocusNode();
  final _emailDoneFocusNode = FocusNode();
  final _emailNextFocusNode = FocusNode();
  final _passwordDoneFocusNode = FocusNode();
  final _passwordEnterFocusNode = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  _EditingField _editingField = _EditingField.none;

  @override
  void initState() {
    super.initState();

    _emailTextFocusNode.addListener(_handleTextFocusLoss);
    _passwordTextFocusNode.addListener(_handleTextFocusLoss);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_emailCardFocusNode);
      }
    });
  }

  void _handleTextFocusLoss() {
    if (!mounted) return;

    final emailFocused = _emailTextFocusNode.hasFocus;
    final passwordFocused = _passwordTextFocusNode.hasFocus;

    if (!emailFocused && !passwordFocused) {
      if (_editingField != _EditingField.none) {
        setState(() {
          _editingField = _EditingField.none;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (_passwordController.text.trim().isNotEmpty ||
              _emailController.text.trim().isNotEmpty) {
            FocusScope.of(context).requestFocus(_loginButtonFocusNode);
          } else {
            FocusScope.of(context).requestFocus(_emailCardFocusNode);
          }
        });
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _error = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Debes ingresar tu correo y tu contraseña.';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo iniciar sesión. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startEditing(_EditingField field) {
    setState(() {
      _editingField = field;
      _error = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (field == _EditingField.email) {
        FocusScope.of(context).requestFocus(_emailTextFocusNode);
      } else if (field == _EditingField.password) {
        FocusScope.of(context).requestFocus(_passwordTextFocusNode);
      }
    });
  }

  void _stopEditingAndFocus(FocusNode nextFocus) {
    _emailTextFocusNode.unfocus();
    _passwordTextFocusNode.unfocus();

    setState(() {
      _editingField = _EditingField.none;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(nextFocus);
    });
  }

  void _finishEmail() {
    _stopEditingAndFocus(_passwordCardFocusNode);
  }

  void _finishPassword() {
    _stopEditingAndFocus(_loginButtonFocusNode);
  }

  KeyEventResult _handlePageKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      if (_editingField != _EditingField.none) {
        if (_editingField == _EditingField.email) {
          _stopEditingAndFocus(_emailCardFocusNode);
        } else if (_editingField == _EditingField.password) {
          _stopEditingAndFocus(_passwordCardFocusNode);
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _emailTextFocusNode.removeListener(_handleTextFocusLoss);
    _passwordTextFocusNode.removeListener(_handleTextFocusLoss);

    _emailController.dispose();
    _passwordController.dispose();

    _emailTextFocusNode.dispose();
    _passwordTextFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    _emailCardFocusNode.dispose();
    _passwordCardFocusNode.dispose();
    _emailDoneFocusNode.dispose();
    _emailNextFocusNode.dispose();
    _passwordDoneFocusNode.dispose();
    _passwordEnterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handlePageKey,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF07101C),
                Color(0xFF0A1627),
                Color(0xFF0E1D31),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Container(
                width: 1160,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 560,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0D1726),
                              Color(0xFF12233B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              top: -10,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E88FF)
                                      .withOpacity(0.10),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -10,
                              bottom: -10,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4FC3F7)
                                      .withOpacity(0.08),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 48,
                                      color: Color(0xFF4FC3F7),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Red Cristiana TV',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 26),
                                Text(
                                  'Una experiencia cristiana diseñada para la sala.',
                                  style: TextStyle(
                                    fontSize: 28,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Películas, series, radios y canales en vivo con una interfaz pensada para control remoto.',
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.5,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 28),
                                _TvFeatureRow(
                                  icon: Icons.live_tv_rounded,
                                  text: 'Canales cristianos en vivo',
                                ),
                                SizedBox(height: 12),
                                _TvFeatureRow(
                                  icon: Icons.radio_rounded,
                                  text: 'Radios online activas',
                                ),
                                SizedBox(height: 12),
                                _TvFeatureRow(
                                  icon: Icons.video_collection_rounded,
                                  text: 'Contenido inspirador para pantalla grande',
                                ),
                                SizedBox(height: 12),
                                _TvFeatureRow(
                                  icon: Icons.favorite_rounded,
                                  text: 'Apoyo simple por QR y videos de apoyo',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 560,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1725),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accede con tu cuenta para continuar en TV.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 22),

                            _TvEditableFieldCard(
                              focusNode: _emailCardFocusNode,
                              label: 'Correo electrónico',
                              value: _emailController.text,
                              hint: 'correo@ejemplo.com',
                              icon: Icons.mail_rounded,
                              editing: _editingField == _EditingField.email,
                              textController: _emailController,
                              textFocusNode: _emailTextFocusNode,
                              textInputAction: TextInputAction.done,
                              onActivate: () => _startEditing(_EditingField.email),
                              onDone: _finishEmail,
                              primaryActionLabel: 'Siguiente',
                              primaryActionFocusNode: _emailNextFocusNode,
                              secondaryActionLabel: 'Listo',
                              secondaryActionFocusNode: _emailDoneFocusNode,
                              onPrimaryAction: _finishEmail,
                              onSecondaryAction: _finishEmail,
                            ),

                            const SizedBox(height: 16),

                            _TvEditableFieldCard(
                              focusNode: _passwordCardFocusNode,
                              label: 'Contraseña',
                              value: _passwordController.text,
                              hint: 'Ingresa tu contraseña',
                              icon: Icons.lock_rounded,
                              editing: _editingField == _EditingField.password,
                              textController: _passwordController,
                              textFocusNode: _passwordTextFocusNode,
                              textInputAction: TextInputAction.done,
                              obscureText: _obscurePassword,
                              onActivate: () =>
                                  _startEditing(_EditingField.password),
                              onDone: _finishPassword,
                              primaryActionLabel: 'Entrar',
                              primaryActionFocusNode: _passwordEnterFocusNode,
                              secondaryActionLabel: 'Listo',
                              secondaryActionFocusNode: _passwordDoneFocusNode,
                              onPrimaryAction: _finishPassword,
                              onSecondaryAction: _finishPassword,
                              trailing: TvPressable(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                builder: (context, focused) {
                                  return AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: focused
                                          ? const Color(0xFF1E88FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: focused
                                            ? const Color(0xFF4FC3F7)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 18),

                            if (_error != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A1E1E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x66FF8A80),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 220,
                                child: _TvActionButton(
                                  focusNode: _loginButtonFocusNode,
                                  label: _loading ? 'Ingresando...' : 'Entrar',
                                  icon: Icons.login_rounded,
                                  onTap: _loading ? null : _signIn,
                                  filled: true,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              'Pulsa OK en un campo para editar. Usa “Listo” o “Siguiente” para salir correctamente del teclado.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),

                            const Spacer(),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121F32),
                                borderRadius: BorderRadius.circular(18),
                                border:
                                Border.all(color: const Color(0x22FFFFFF)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF4FC3F7),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Más adelante añadiremos inicio de sesión aún más cómodo con código o QR.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TvFeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _TvEditableFieldCard extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final bool editing;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? trailing;
  final VoidCallback onActivate;
  final VoidCallback onDone;
  final String primaryActionLabel;
  final FocusNode primaryActionFocusNode;
  final String secondaryActionLabel;
  final FocusNode secondaryActionFocusNode;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const _TvEditableFieldCard({
    required this.focusNode,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.editing,
    required this.textController,
    required this.textFocusNode,
    required this.textInputAction,
    this.obscureText = false,
    this.trailing,
    required this.onActivate,
    required this.onDone,
    required this.primaryActionLabel,
    required this.primaryActionFocusNode,
    required this.secondaryActionLabel,
    required this.secondaryActionFocusNode,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  State<_TvEditableFieldCard> createState() => _TvEditableFieldCardState();
}

class _TvEditableFieldCardState extends State<_TvEditableFieldCard> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_refresh);
    widget.textFocusNode.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.textController.removeListener(_refresh);
    widget.textFocusNode.removeListener(_refresh);
    super.dispose();
  }

  String get _displayValue {
    final value = widget.value.trim();
    if (value.isEmpty) return widget.hint;
    if (!widget.obscureText) return value;
    return '•' * value.length.clamp(0, 12);
  }

  @override
  Widget build(BuildContext context) {
    final textFocused = widget.textFocusNode.hasFocus;

    return TvPressable(
      focusNode: widget.focusNode,
      onPressed: widget.onActivate,
      builder: (context, focused) {
        final active = focused || widget.editing || textFocused;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF172235),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x26FFFFFF),
              width: active ? 2 : 1,
            ),
            boxShadow: active
                ? [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withOpacity(0.18),
                blurRadius: 18,
              ),
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!widget.editing)
                          Text(
                            _displayValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              color: widget.value.trim().isEmpty
                                  ? Colors.white38
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          TextField(
                            controller: widget.textController,
                            focusNode: widget.textFocusNode,
                            obscureText: widget.obscureText,
                            textInputAction: widget.textInputAction,
                            onEditingComplete: widget.onDone,
                            onSubmitted: (_) => widget.onDone(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: widget.hint,
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ),
              if (widget.editing) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniActionButton(
                      focusNode: widget.secondaryActionFocusNode,
                      label: widget.secondaryActionLabel,
                      icon: Icons.check_rounded,
                      onTap: widget.onSecondaryAction,
                    ),
                    _MiniActionButton(
                      focusNode: widget.primaryActionFocusNode,
                      label: widget.primaryActionLabel,
                      icon: Icons.arrow_forward_rounded,
                      filled: true,
                      onTap: widget.onPrimaryAction,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TvActionButton extends StatelessWidget {
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _TvActionButton({
    this.focusNode,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return TvPressable(
      focusNode: focusNode,
      onPressed: onTap ?? () {},
      builder: (context, focused) {
        final enabled = onTap != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? (filled
                ? const Color(0xFF1E88FF)
                : Colors.white.withOpacity(0.10))
                : Colors.white12,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused
                  ? const Color(0xFF4FC3F7)
                  : const Color(0x24FFFFFF),
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withOpacity(0.20),
                blurRadius: 18,
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _MiniActionButton({
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TvPressable(
        focusNode: focusNode,
        onPressed: onTap,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: filled
                  ? const Color(0xFF1E88FF)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused
                    ? const Color(0xFF4FC3F7)
                    : const Color(0x24FFFFFF),
                width: focused ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}