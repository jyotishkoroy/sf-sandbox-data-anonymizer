@IsTest
private class IO_WebhookIntakeTest {
    @IsTest
    static void testIntakeStoresFile() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/io/webhook?key=test';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.addHeader('X-Correlation-Id', 'corrtest123');
        req.requestBody = Blob.valueOf('{"hello":"world"}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        IO_WebhookIntake.IntakeResponse out = IO_WebhookIntake.post();
        Test.stopTest();

        System.assertEquals(true, out.ok);
        System.assertEquals('corrtest123', out.corrId);
        System.assertNotEquals(null, out.contentVersionId);

        ContentVersion stored = [SELECT Id, Title FROM ContentVersion WHERE Id = :out.contentVersionId LIMIT 1];
        System.assert(stored.Title.startsWith('IO_Webhook_corrtest123_'));
    }
}
