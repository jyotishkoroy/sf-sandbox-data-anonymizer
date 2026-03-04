public with sharing class IO_ReplayService implements Database.AllowsCallouts {

    public class ReplayRequest {
        @AuraEnabled public String namedCredential;
        @AuraEnabled public String path;
        @AuraEnabled public String method;
        @AuraEnabled public String body;
        @AuraEnabled public Map<String, String> headers;
        @AuraEnabled public String corrId;
    }

    public class ReplayResponse {
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String status;
        @AuraEnabled public String responseBody;
        @AuraEnabled public String corrId;
    }

    @AuraEnabled
    public static ReplayResponse replay(ReplayRequest req) {
        if (req == null) throw new AuraHandledException('Missing replay request.');
        if (String.isBlank(req.namedCredential)) throw new AuraHandledException('Choose a Named Credential.');
        if (String.isBlank(req.path)) req.path = '/';
        if (!req.path.startsWith('/')) req.path = '/' + req.path;

        String method = String.isBlank(req.method) ? 'POST' : req.method.trim().toUpperCase();

        HttpRequest r = new HttpRequest();
        r.setMethod(method);
        r.setEndpoint('callout:' + req.namedCredential.trim() + req.path);

        String corrId = String.isBlank(req.corrId) ? IO_Correlation.newId() : req.corrId.trim();
        r.setHeader('X-Correlation-Id', corrId);

        if (req.headers != null) {
            for (String k : req.headers.keySet()) {
                if (String.isBlank(k)) continue;
                r.setHeader(k, req.headers.get(k));
            }
        }

        if (req.body != null) {
            r.setBody(req.body);
            if (String.isBlank(r.getHeader('Content-Type'))) {
                r.setHeader('Content-Type', 'application/json');
            }
        }

        HttpResponse res = new Http().send(r);

        ReplayResponse out = new ReplayResponse();
        out.statusCode = res.getStatusCode();
        out.status = res.getStatus();
        out.responseBody = res.getBody();
        out.corrId = corrId;
        return out;
    }
}
