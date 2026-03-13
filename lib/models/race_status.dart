/// Logical status of a daily race used for sorting and display.
///
/// This is distinct from the raw `status` string that may be scraped from
/// DG‑Edge or GTSh‑rank.  We only care about three buckets:
///
///  * **current** – the race is actively running or about to start.
///  * **future**  – the race is scheduled for a later time or week.
///  * **past**    – the race has finished (we normally drop these from lists).
///
/// By normalizing early we can easily partition the merged list and show the
/// "upcoming" entries separately in the UI.
enum RaceStatus { past, current, future }

extension RaceStatusX on RaceStatus {
  /// Human-readable name matching the enum cases; handy for JSON serialization
  /// and debugging.
  String get name => toString().split('.').last;
}
