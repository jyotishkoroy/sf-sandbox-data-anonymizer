public with sharing class IO_Correlation {
    public static String newId() {
        String raw = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA1',
                Blob.valueOf(String.valueOf(Datetime.now().getTime()) + ':' + String.valueOf(Crypto.getRandomLong()))
            )
        );
        return raw.substring(0, 16);
    }

    public static void set(String corrId) {
        if (String.isBlank(corrId)) corrId = newId();
        IO_CorrelationState.currentCorrId = corrId;
    }

    public static String get() {
        if (String.isBlank(IO_CorrelationState.currentCorrId)) {
            IO_CorrelationState.currentCorrId = newId();
        }
        return IO_CorrelationState.currentCorrId;
    }

    public static void applyTo(HttpRequest req) {
        if (req == null) return;
        req.setHeader('X-Correlation-Id', get());
    }

    public static void debugMarker(String message) {
        System.debug(LoggingLevel.INFO, 'IO_CORR_ID=' + get() + ' ' + (message == null ? '' : message));
    }

    private class IO_CorrelationState {
        private static String currentCorrId;
    }
}
