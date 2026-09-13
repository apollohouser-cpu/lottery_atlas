/// Published update cadence for official state sources when it is known.
///
/// This describes the lottery's source, not how often Lottery Atlas polls it.
class StateSourceCadenceRegistry {
  StateSourceCadenceRegistry._();

  static String? noticeFor(String stateName) {
    switch (stateName) {
      case 'Iowa':
        return 'Iowa retailer data is published weekly by the state. '
            'Winner and Scratch-Off data may follow different schedules. '
            'Check each official source date before treating the map as current.';
      case 'Missouri':
        return 'Missouri retailer-level winner releases are published monthly. '
            'The latest available month may lag the current date.';
      case 'Nebraska':
        return 'Nebraska Scratch-Off prizes remaining and unclaimed Lotto '
            'prizes are published weekly. Recent local winner notices may '
            'update more often; check each source date separately.';
      default:
        return null;
    }
  }
}
