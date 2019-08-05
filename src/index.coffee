
module.exports = {
  ReaderHistoricalProcessor: require "./retry.historical.processor"
  DeadletterProcessor: require "./deadletter.processor"
  CleanupProcessor: require "./cleanup.processor"
}