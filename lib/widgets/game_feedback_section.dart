import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/game_feedback_service.dart';
import '../views/home/login_view.dart';

class GameFeedbackSection extends StatefulWidget {
  const GameFeedbackSection({required this.gameId, super.key});

  final String gameId;

  @override
  State<GameFeedbackSection> createState() => _GameFeedbackSectionState();
}

class _GameFeedbackSectionState extends State<GameFeedbackSection> {
  final GameFeedbackService _service = GameFeedbackService();
  bool _saving = false;
  late Stream<GameFeedbackSummary> _votesStream;

  @override
  void initState() {
    super.initState();
    _votesStream = _service.watch(widget.gameId);
  }

  @override
  void didUpdateWidget(covariant GameFeedbackSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _votesStream = _service.watch(widget.gameId);
    }
  }

  Future<void> _vote(GameWorkingVote vote) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      final bool? signedIn = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginView()));
      if (signedIn != true || !mounted) return;
      user = FirebaseAuth.instance.currentUser;
    }
    if (user == null || user.isAnonymous || !mounted) return;

    setState(() => _saving = true);
    try {
      await _service.setVote(widget.gameId, vote);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your vote. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameFeedbackSummary>(
      stream: _votesStream,
      builder: (context, snapshot) {
        final GameFeedbackSummary summary =
            snapshot.data ??
            const GameFeedbackSummary(
              works: 0,
              doesNotWork: 0,
              currentVote: null,
            );
        final int total = summary.total;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF101D31).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.how_to_vote_rounded,
                    color: Color(0xFF64B5F6),
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Does this game work?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$total ${total == 1 ? 'vote' : 'votes'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Works: ${summary.works}',
                    style: const TextStyle(
                      color: Color(0xFF83E5B7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Doesn’t work: ${summary.doesNotWork}',
                    style: const TextStyle(
                      color: Color(0xFFFF9AAA),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _voteButton(
                      label: 'Works',
                      icon: Icons.check_circle_outline_rounded,
                      selected: summary.currentVote == GameWorkingVote.works,
                      color: const Color(0xFF59D6A1),
                      onPressed: () => _vote(GameWorkingVote.works),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _voteButton(
                      label: 'Doesn’t work',
                      icon: Icons.cancel_outlined,
                      selected:
                          summary.currentVote == GameWorkingVote.doesNotWork,
                      color: const Color(0xFFFF6B8A),
                      onPressed: () => _vote(GameWorkingVote.doesNotWork),
                    ),
                  ),
                ],
              ),
              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Could not load votes right now.',
                    style: TextStyle(color: Color(0xFFFF9AAA), fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _voteButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : onPressed,
      icon: _saving
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF071426) : color,
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: color.withValues(alpha: selected ? 1 : .45)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}
