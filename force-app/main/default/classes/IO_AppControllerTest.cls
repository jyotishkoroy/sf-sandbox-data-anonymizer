@IsTest
private class IO_AppControllerTest {
    @IsTest
    static void testInfo() {
        Test.startTest();
        IO_AppController.RepoInfo i = IO_AppController.getInfo();
        Test.stopTest();
        System.assertEquals('0.1.0', i.version);
        System.assert(i.webhookPath.contains('/apexrest/io/webhook'));
    }

    @IsTest
    static void testInboxListing() {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'IO_Webhook_abc123_20260101T000000Z';
        cv.PathOnClient = 'x.json';
        cv.VersionData = Blob.valueOf('{"ok":true}');
        insert cv;

        Test.startTest();
        List<IO_FileService.InboxItem> items = IO_AppController.listInbox(20);
        IO_FileService.FileBody body = IO_AppController.getInboxItemBody(cv.Id);
        Test.stopTest();

        System.assert(!items.isEmpty());
        System.assertEquals(cv.Id, body.contentVersionId);
        System.assert(body.json.contains('ok'));
    }
}
