/// A console identified by a DDP reply, not by a vendor/MAC heuristic.
class ConsoleCandidate {
  const ConsoleCandidate({
    required this.address,
    required this.id,
    required this.name,
    required this.platform,
    required this.active,
  });
  final String address;
  final String id;
  final String name;
  final String platform;
  final bool active;
}
