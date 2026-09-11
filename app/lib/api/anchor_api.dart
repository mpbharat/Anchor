import 'dart:async';

/// Typed client for the Anchor API (see ANCHOR-BUILD-SPEC.md §7).
/// TODAY: returns mock data so the front-end can be built against real shapes.
/// EVENT DAY: point [baseUrl] at Merlin's backend and drop the mocks.
class AnchorApi {
  AnchorApi({this.baseUrl = ''});
  final String baseUrl;

  /// GET /weeks/current/commitments
  Future<List<Commitment>> currentCommitments() async {
    // MOCK — replace with a real GET when the backend is live.
    return const [
      Commitment(position: 1, title: 'Ship the pricing revamp', status: 'on_record'),
      Commitment(position: 2, title: 'Three gym sessions', status: 'due', progress: '1 of 3'),
      Commitment(position: 3, title: 'Call Dad, Sunday', status: 'on_record'),
    ];
  }

  /// POST /judge  → the "no" (event-day: real AI call)
  Future<Judgment> judge(String request) async {
    return const Judgment(
      verdict: 'declined',
      spoken:
          "A newsletter sounds like it matters. Your call, but you're at four and behind on the gym — if it goes in, which comes out?",
      weighedAgainst: ['Pricing', 'Gym', 'Dad', 'Sleep'],
    );
  }
}

class Commitment {
  final int position;
  final String title;
  final String status; // on_record | due | done | carried | dropped
  final String? progress;
  const Commitment({
    required this.position,
    required this.title,
    required this.status,
    this.progress,
  });
}

class Judgment {
  final String verdict; // declined | allowed | swapped | nudge | stay_silent
  final String spoken;
  final List<String> weighedAgainst;
  const Judgment({
    required this.verdict,
    required this.spoken,
    required this.weighedAgainst,
  });
}
