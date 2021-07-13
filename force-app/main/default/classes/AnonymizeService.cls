public with sharing class AnonymizeService {

    //public static Integer anonListSize = 200;

    public static String wordListResourceName = 'SandboxAnonymizerWordList';
    public static String anonExceptionResourceName = 'SandboxAnonymizerExceptions';

    public List<String> getRandomWords() {
        return randomWords;
    }

    public List<String> getRandomFirstNames() {
        return randomFirstNames;
    }

    public List<String> getRandomLastNames() {
        return randomLastNames;
    }

    public List<String> getRandomOrgSuffixes() {
    	return randomOrgSuffixes;
    }

    public static List<String> randomWords {
        get {
            StaticResource randomWordList = [select Body from StaticResource where Name = :wordListResourceName];
            String randomWordListBody = randomWordList.Body.toString();
            AnonymizeWordsJSON2Apex parsedData = AnonymizeWordsJSON2Apex.parse(randomWordListBody);
            return new List<String>(parsedData.words);
        }
    }

    public static List<String> randomFirstNames {
        get {
            StaticResource randomWordList = [select Body from StaticResource where Name = :wordListResourceName];
            String randomWordListBody = randomWordList.Body.toString();
            AnonymizeWordsJSON2Apex parsedData = AnonymizeWordsJSON2Apex.parse(randomWordListBody);
            return new List<String>(parsedData.firstNames);
        }
    }

    public static List<String> randomLastNames {
        get {
            StaticResource randomWordList = [select Body from StaticResource where Name = :wordListResourceName];
            String randomWordListBody = randomWordList.Body.toString();
            AnonymizeWordsJSON2Apex parsedData = AnonymizeWordsJSON2Apex.parse(randomWordListBody);
            return new List<String>(parsedData.lastNames);
        }
    }

    public static List<String> randomOrgSuffixes {
        get {
            StaticResource randomWordList = [select Body from StaticResource where Name = :wordListResourceName];
            String randomWordListBody = randomWordList.Body.toString();
            AnonymizeWordsJSON2Apex parsedData = AnonymizeWordsJSON2Apex.parse(randomWordListBody);
            return new List<String>(parsedData.orgSuffixes);
        }
    }

    public static Integer randomNumber(Integer numberLimit) {    
    	Integer rand = Math.round(Math.ceil(Math.random()*(numberLimit-1)));
        return rand;
    }

    public static String randomValue(List<String> randomList) {
    	return randomList[randomNumber(randomList.size())];
    }
    

    public static String emailSuffix {
        get {
            return 'example.com';
        }
    }


}