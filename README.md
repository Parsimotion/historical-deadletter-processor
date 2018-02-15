# historical-deadletter-processor

[![NPM version](https://badge.fury.io/js/historical-deadletter-processor.png)](http://badge.fury.io/js/historical-deadletter-processor)

```javascript
const connectionToTable = "";
const operation = () => console.log("doing");
const tableName = "poison";

new HistoricalDeadletterProcessor(
  (value) => operation(...),
  {
    connection: connectionToTable,
    tableName: tableName,
    partitionKey: "unaPartitionKey",
  },
  { callsToApi: 20, callsToAzure: 50 },
  console.log,
  1 // Retry messages days
).run().asCallback(context.done);

```
