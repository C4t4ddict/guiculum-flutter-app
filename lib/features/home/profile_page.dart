import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nicknameCtrl = TextEditingController();
  final _jobGoalCtrl = TextEditingController();
  final _studyPromiseCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  bool _saving = false;
  int _refreshTick = 0;
  String? _optimisticNickname;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _jobGoalCtrl.dispose();
    _studyPromiseCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(ProfileDto profile) async {
    final previous = _optimisticNickname ?? profile.nickname;
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해줘.')));
      return;
    }

    setState(() {
      _saving = true;
      _optimisticNickname = nickname;
    });

    try {
      await ProfileService.updateMyNickname(nickname);
      await ProfileService.updateProfileExtras(
        jobGoal: _jobGoalCtrl.text,
        studyStyle: _studyPromiseCtrl.text,
        interests: _interestsCtrl.text.split(','),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('변경 사항 저장 완료'),
          action: SnackBarAction(
            label: '실행 취소',
            onPressed: () async {
              setState(() {
                _optimisticNickname = previous;
                _nicknameCtrl.text = previous;
              });
              try {
                await ProfileService.updateMyNickname(previous);
              } catch (_) {}
            },
          ),
        ),
      );
      setState(() => _refreshTick++);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimisticNickname = previous;
        _nicknameCtrl.text = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.value(_refreshTick).then((_) => ProfileService.fetchMyProfile()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('프로필 조회 실패: ${snapshot.error}'));
          }
          final p = snapshot.data;
          if (p == null) {
            return const Center(child: Text('로그인 필요 또는 프로필 없음'));
          }

          final currentNickname = _optimisticNickname ?? p.nickname;
          if (_nicknameCtrl.text.isEmpty) _nicknameCtrl.text = currentNickname;
          if (_jobGoalCtrl.text.isEmpty) _jobGoalCtrl.text = p.jobGoal;
          if (_studyPromiseCtrl.text.isEmpty) _studyPromiseCtrl.text = p.studyStyle;
          if (_interestsCtrl.text.isEmpty) _interestsCtrl.text = p.interests.join(', ');

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshTick++),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x330050CB), width: 2),
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_rounded, color: AppColors.primaryStrong),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('프로필 설정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_rounded, color: AppColors.primaryStrong)),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0050CB), Color(0xFF6FCEFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: const Icon(Icons.flight_rounded, size: 54, color: AppColors.primaryStrong),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(color: AppColors.primaryStrong, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(currentNickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.lightText)),
                      const SizedBox(height: 4),
                      Text(p.jobGoal.isEmpty ? '비행 자격: 학습자' : '비행 자격: ${p.jobGoal}', style: const TextStyle(fontSize: 14, color: AppColors.lightMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  icon: Icons.person_rounded,
                  title: '개인 정보',
                  child: Column(
                    children: [
                      _ProfileInput(label: '닉네임', controller: _nicknameCtrl),
                      const SizedBox(height: 12),
                      _ReadOnlyProfileInput(label: '이메일', value: p.email),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ProfileSection(
                  icon: Icons.flight_takeoff_rounded,
                  title: '학습 아이덴티티',
                  child: Column(
                    children: [
                      _ProfileInput(label: '목표 역할', controller: _jobGoalCtrl),
                      const SizedBox(height: 12),
                      _ProfileTextArea(label: '학습 다짐', controller: _studyPromiseCtrl, hintText: '오늘도 목표 고도까지 흔들림 없이 학습하겠습니다.'),
                      const SizedBox(height: 12),
                      _ProfileInput(label: '관심 분야', controller: _interestsCtrl, hintText: '예: Flutter, UI, 아키텍처'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _saveProfile(p),
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_saving ? '저장 중...' : '변경 사항 저장'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _ProfileSection(
                  icon: Icons.dashboard_customize_rounded,
                  title: '계정 바로가기',
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: const [
                      _ShortcutCard(icon: Icons.analytics_rounded, label: '비행 기록', accent: Color(0xFF006689)),
                      _ShortcutCard(icon: Icons.settings_suggest_rounded, label: '알림 설정', accent: Color(0xFF006689)),
                      _ShortcutCard(icon: Icons.shield_rounded, label: '계정 보안', accent: Color(0xFF006689)),
                      _ShortcutCard(icon: Icons.logout_rounded, label: '로그아웃', accent: Colors.redAccent),
                    ],
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

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _ProfileSection({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryStrong, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.lightMuted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.glassCard(),
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ],
    );
  }
}

class _ProfileInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  const _ProfileInput({required this.label, required this.controller, this.hintText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _ReadOnlyProfileInput extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyProfileInput({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
        ),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          controller: TextEditingController(text: value),
          decoration: const InputDecoration(suffixIcon: Icon(Icons.lock_rounded)),
        ),
      ],
    );
  }
}

class _ProfileTextArea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  const _ProfileTextArea({required this.label, required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryStrong)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _ShortcutCard({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.lightText)),
        ],
      ),
    );
  }
}
