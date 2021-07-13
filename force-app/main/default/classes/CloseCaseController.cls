public with sharing class CloseCaseController {

	private Case caseToClose;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public CloseCaseController(ApexPages.StandardController stdController) {
        this.caseToClose = (Case)stdController.getRecord();
		this.caseToClose.status = 'Closed';
    }

	public PageReference save() {
		try {
			upsert(caseToClose);
		} catch(System.DMLException e) {
			ApexPages.addMessages(e);
			return null;
		}
		//  After successful Save, navigate to the default view page
		PageReference redirectSuccess = new ApexPages.StandardController(caseToClose).view();
		return (redirectSuccess);
	}
}