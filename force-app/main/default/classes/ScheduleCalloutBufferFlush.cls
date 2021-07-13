global class ScheduleCalloutBufferFlush implements Schedulable {
	global void execute(SchedulableContext sc) {
      CalloutBuffer.flushBuffer(true);
	}
}