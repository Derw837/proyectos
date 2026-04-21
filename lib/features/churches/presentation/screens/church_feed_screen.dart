import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_feed_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChurchFeedScreen extends StatefulWidget {
  const ChurchFeedScreen({super.key});

  @override
  State<ChurchFeedScreen> createState() => _ChurchFeedScreenState();
}

class _ChurchFeedScreenState extends State<ChurchFeedScreen> {
  bool isLoading = true;
  String churchId = '';
  String churchName = 'Mi iglesia';

  @override
  void initState() {
    super.initState();
    _loadMyChurch();
  }

  Future<void> _loadMyChurch() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión');
      }

      final church = await Supabase.instance.client
          .from('churches')
          .select('id, church_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        churchId = church?['id']?.toString() ?? '';
        churchName = church?['church_name']?.toString() ?? 'Mi iglesia';
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: isLoading
          ? const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      )
          : HomeFeedScreen(
        initialChurchId: churchId.isEmpty ? null : churchId,
        initialChurchName: churchName,
        initialTab: 'all',
        allowResetToGeneral: true,
      ),
    );
  }
}