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
          "A newsletter sounds like it matters. Your call, but you're at four and behind on the gym. If it goes in, which comes out?",
      weighedAgainst: ['Pricing', 'Gym', 'Dad', 'Sleep'],
    );
  }

  /// GET /conversations/current  → the running Talk transcript
  Future<List<Turn>> conversation() async {
    // MOCK — the always-on companion's last few turns.
    return const [
      Turn(role: 'anchor', text: "You've kept the gym once this week. Sunday's open — lock it in now?"),
      Turn(role: 'user', text: "Yeah, Sunday morning works."),
      Turn(role: 'anchor', text: "Done. If it rains, you said you'd do the 20-minute home set instead. Still good?"),
      Turn(role: 'user', text: "Still good."),
    ];
  }

  /// GET /weeks/current/standing  → the end-of-week review
  Future<WeeklyStanding> standing() async {
    return const WeeklyStanding(
      keptCount: 2,
      totalCount: 3,
      anchorMessage:
          "Two of three. The gym slipped once — that's one week, not who you are. Same three next week, or swap one?",
      items: [
        StandingItem(title: 'Ship the pricing revamp', outcome: 'kept'),
        StandingItem(title: 'Call Dad, Sunday', outcome: 'kept'),
        StandingItem(title: 'Three gym sessions', outcome: 'missed', note: 'forgiven · carried'),
      ],
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

class Turn {
  final String role; // user | anchor
  final String text;
  const Turn({required this.role, required this.text});
}

class WeeklyStanding {
  final int keptCount;
  final int totalCount;
  final String anchorMessage;
  final List<StandingItem> items;
  const WeeklyStanding({
    required this.keptCount,
    required this.totalCount,
    required this.anchorMessage,
    required this.items,
  });
}

class StandingItem {
  final String title;
  final String outcome; // kept | missed | forgiven
  final String? note;
  const StandingItem({required this.title, required this.outcome, this.note});
}
