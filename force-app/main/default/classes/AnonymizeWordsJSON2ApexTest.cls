@IsTest
private with sharing class AnonymizeWordsJSON2ApexTest {

		public static Integer anonListSize = 200;
		public static String wordListResourceName = 'SandboxAnonymizerWordList';

		static testMethod void getWords() {
			StaticResource randomWordList = [select Body from StaticResource where Name = :wordListResourceName];
			String randomWordListBody = randomWordList.Body.toString();

			JSONParser parser = JSON.createParser(randomWordListBody);

			AnonymizeWordsJSON2Apex.consumeObject(parser);

			AnonymizeWordsJSON2Apex parsedData = AnonymizeWordsJSON2Apex.parse(randomWordListBody);
			System.assert(parsedData.words != null);
		}

}