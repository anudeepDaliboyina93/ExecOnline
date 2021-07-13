global class MarketoSyncBatchSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
        MarketoSyncBatch b = new MarketoSyncBatch();
      	database.executebatch(b);
   	}
}