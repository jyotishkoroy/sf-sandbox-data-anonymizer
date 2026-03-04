public with sharing class IO_FileService {

    public class InboxItem {
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String title;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String corrId;
    }

    public class FileBody {
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String title;
        @AuraEnabled public String json;
    }

    @AuraEnabled(cacheable=true)
    public static List<InboxItem> listInbox(Integer limitSize) {
        Integer lim = (limitSize == null || limitSize <= 0 || limitSize > 200) ? 50 : limitSize;

        List<ContentVersion> cvs = [
            SELECT Id, Title, CreatedDate, CreatedBy.Name
            FROM ContentVersion
            WHERE Title LIKE 'IO_Webhook_%'
            ORDER BY CreatedDate DESC
            LIMIT :lim
        ];

        List<InboxItem> out = new List<InboxItem>();
        for (ContentVersion cv : cvs) {
            InboxItem i = new InboxItem();
            i.contentVersionId = cv.Id;
            i.title = cv.Title;
            i.createdAt = cv.CreatedDate;
            i.createdByName = cv.CreatedBy == null ? null : cv.CreatedBy.Name;
            i.corrId = extractCorrId(cv.Title);
            out.add(i);
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static FileBody getBody(Id contentVersionId) {
        if (contentVersionId == null) throw new AuraHandledException('Missing file id.');

        ContentVersion cv = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];

        FileBody b = new FileBody();
        b.contentVersionId = cv.Id;
        b.title = cv.Title;
        b.json = cv.VersionData == null ? null : cv.VersionData.toString();
        return b;
    }

    private static String extractCorrId(String title) {
        if (String.isBlank(title)) return null;
        List<String> parts = title.split('_');
        if (parts.size() >= 3) return parts[2];
        return null;
    }
}
