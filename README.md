# historical-deadletter-processor

[![NPM version](https://badge.fury.io/js/historical-deadletter-processor.png)](http://badge.fury.io/js/historical-deadletter-processor)

```javascript
const connectionToTable = "";
const operation = () => console.log("doing");

new RetryHistoricalProcessor(
  {
    connection: connectionToTable,
    processor: (value) => operation(...),
    app: "an app",
    job: "a job",
    daysRetrying: 1,
    concurrency: { callsToApi: 20 },
    logger: console.log
  },
).run().asCallback(context.done);

```
