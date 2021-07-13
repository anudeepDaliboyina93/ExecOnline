global class TouchContactBatchSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
      	TouchContactBatch b = new TouchContactBatch();
      	database.executebatch(b);
   	}
}