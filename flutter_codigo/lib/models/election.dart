class Candidate {
  final String id;
  final String name;
  final String proposal;
  const Candidate({required this.id, required this.name, required this.proposal});
  factory Candidate.fromJson(Map<String,dynamic> x) => Candidate(
    id: x['id'] as String,
    name: x['name'] as String,
    proposal: x['proposal'] as String,
  );
}

class ElectionData {
  final String title;
  final String status;
  final bool alreadyVoted;
  final String? receipt;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<Candidate> candidates;
  ElectionData({required this.title,required this.status,required this.alreadyVoted,required this.receipt,required this.startsAt,required this.endsAt,required this.candidates});
  factory ElectionData.fromJson(Map<String,dynamic> x) => ElectionData(
    title: x['title'] as String,
    status: x['status'] as String,
    alreadyVoted: x['alreadyVoted'] as bool,
    receipt: x['receipt'] as String?,
    startsAt: DateTime.parse(x['startsAt'] as String).toLocal(),
    endsAt: DateTime.parse(x['endsAt'] as String).toLocal(),
    candidates: (x['candidates'] as List).map((e) => Candidate.fromJson(e as Map<String,dynamic>)).toList(),
  );
}

class ResultRow {
  final String name;
  final int votes;
  ResultRow({required this.name,required this.votes});
  factory ResultRow.fromJson(Map<String,dynamic> x) => ResultRow(name:x['name'] as String,votes:(x['votes'] as num).toInt());
}
class ResultsData {
  final String election;
  final List<ResultRow> rows;
  ResultsData({required this.election,required this.rows});
  factory ResultsData.fromJson(Map<String,dynamic> x) => ResultsData(
    election:x['election'] as String,
    rows:(x['results'] as List).map((e)=>ResultRow.fromJson(e as Map<String,dynamic>)).toList(),
  );
}
