public with sharing class CalloutBufferResponseHandlers {
	public CalloutBufferResponseHandlers() {

	}

	public static String responseHandler(String handler, String body, String itemData) {
		String response;
		// Currently nothing to handle
	/*	if (handler=='exampleHandler')
			response = CalloutBufferResponseHandlers.invTitleAccountPOSTPUT(body, itemData); */
		response = '{"SUCCESS":"SUCCESS"}';
		return response;
	}
}