@RestResource(urlMapping='/io/webhook/*')
global with sharing class IO_WebhookIntake {

    global class IntakeResponse {
        public Boolean ok;
        public String corrId;
        public Boolean signatureVerified;
        public String message;
        public Id contentVersionId;
    }

    @HttpPost global static IntakeResponse post() { return handle('POST'); }
    @HttpPut global static IntakeResponse put() { return handle('PUT'); }
    @HttpPatch global static IntakeResponse patch() { return handle('PATCH'); }
    @HttpDelete global static IntakeResponse del() { return handle('DELETE'); }
    @HttpGet global static IntakeResponse get() { return handle('GET'); }

    private static IntakeResponse handle(String method) {
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;

        IntakeResponse out = new IntakeResponse();
        out.ok = true;

        String corrId = header(req, 'X-Correlation-Id');
        if (String.isBlank(corrId)) corrId = IO_Correlation.newId();
        out.corrId = corrId;

        String key = (req.params == null ? null : req.params.get('key'));
        String providedSig = header(req, 'X-IO-Signature');
        Boolean verified = false;

        Blob bodyBlob = req.requestBody;
        String body = (bodyBlob == null) ? '' : bodyBlob.toString();

        try {
            if (!String.isBlank(providedSig) && !String.isBlank(key)) {
                String secret = IO_WebhookSecrets.secretFor(key);
                if (!String.isBlank(secret)) {
                    String expected = hmacSha256Hex(Blob.valueOf(body), Blob.valueOf(secret));
                    verified = secureEquals(expected, providedSig.trim().toLowerCase());
                }
            }
        } catch (Exception ex) {
            verified = false;
        }

        out.signatureVerified = verified;

        try {
            String ts = Datetime.now().formatGMT('yyyyMMdd'T'HHmmss'Z'');
            String title = 'IO_Webhook_' + corrId + '_' + ts;

            Map<String, Object> payload = new Map<String, Object>();
            payload.put('receivedAt', Datetime.now());
            payload.put('method', method);
            payload.put('path', req.requestURI);
            payload.put('queryParams', req.params);
            payload.put('headers', req.headers);
            payload.put('correlationId', corrId);
            payload.put('signatureVerified', verified);
            payload.put('body', body);

            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = title + '.json';
            cv.VersionData = Blob.valueOf(JSON.serializePretty(payload));
            insert cv;

            out.contentVersionId = cv.Id;
            out.message = 'Captured.';
        } catch (Exception ex) {
            out.ok = false;
            out.message = 'Failed to store inbox item: ' + ex.getMessage();
        }

        resp.statusCode = out.ok ? 200 : 500;
        resp.addHeader('Content-Type', 'application/json');
        return out;
    }

    private static String header(RestRequest req, String name) {
        if (req == null || req.headers == null || String.isBlank(name)) return null;
        return req.headers.get(name);
    }

    private static String hmacSha256Hex(Blob data, Blob key) {
        Blob mac = Crypto.generateMac('HmacSHA256', data, key);
        return EncodingUtil.convertToHex(mac).toLowerCase();
    }

    private static Boolean secureEquals(String a, String b) {
        if (a == null || b == null) return false;
        if (a.length() != b.length()) return false;
        Integer diff = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diff |= (a.substring(i, i+1).charAt(0) ^ b.substring(i, i+1).charAt(0));
        }
        return diff == 0;
    }
}
