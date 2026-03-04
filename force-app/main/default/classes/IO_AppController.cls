public with sharing class IO_AppController {

    public class RepoInfo {
        @AuraEnabled public String version;
        @AuraEnabled public String apiVersion;
        @AuraEnabled public String webhookPath;
    }

    @AuraEnabled(cacheable=true)
    public static RepoInfo getInfo() {
        RepoInfo i = new RepoInfo();
        i.version = '0.1.0';
        i.apiVersion = '55.0';
        i.webhookPath = '/services/apexrest/io/webhook';
        return i;
    }

    @AuraEnabled(cacheable=true)
    public static List<IO_FileService.InboxItem> listInbox(Integer limitSize) {
        return IO_FileService.listInbox(limitSize);
    }

    @AuraEnabled(cacheable=true)
    public static IO_FileService.FileBody getInboxItemBody(Id contentVersionId) {
        return IO_FileService.getBody(contentVersionId);
    }

    @AuraEnabled
    public static IO_ReplayService.ReplayResponse replay(IO_ReplayService.ReplayRequest req) {
        return IO_ReplayService.replay(req);
    }
}
