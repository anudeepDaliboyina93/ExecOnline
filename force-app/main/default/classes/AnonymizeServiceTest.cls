@isTest
private class AnonymizeServiceTest {

    @isTest
    static void runBatch() {
        AnonymizeService aService = new AnonymizeService();
        List<String> words = aService.getRandomWords();
        List<String> fnames = aService.getRandomFirstNames();
        List<String> lNames = aService.getRandomLastNames();
        List<String> suffixes= aService.getRandomOrgSuffixes();
    }
}