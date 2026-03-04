public with sharing class IO_WebhookSecrets {
    private static final Map<String, String> SECRETS_BY_KEY = new Map<String, String>{
        // 'stripe' => 'replace-me',
        // 'github' => 'replace-me'
    };

    public static String secretFor(String key) {
        if (String.isBlank(key)) return null;
        return SECRETS_BY_KEY.get(key.trim().toLowerCase());
    }
}
