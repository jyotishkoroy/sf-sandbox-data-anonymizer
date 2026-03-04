@IsTest
private class IO_ReplayServiceTest {

    private class Mock200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setStatus('OK');
            r.setBody('{"replayed":true}');
            return r;
        }
    }

    @IsTest
    static void testReplay() {
        Test.setMock(HttpCalloutMock.class, new Mock200());

        IO_ReplayService.ReplayRequest req = new IO_ReplayService.ReplayRequest();
        req.namedCredential = 'DummyNC';
        req.path = '/echo';
        req.method = 'POST';
        req.body = '{"ping":1}';
        req.headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        req.corrId = 'c1';

        Test.startTest();
        IO_ReplayService.ReplayResponse res = IO_ReplayService.replay(req);
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.contains('replayed'));
        System.assertEquals('c1', res.corrId);
    }
}
