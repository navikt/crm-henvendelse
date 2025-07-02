global virtual class ApexRestService {
    private static Exception simulatedException;
    private static final Map<Integer, String> DEFAULT_RESPONSE_MAP = new Map<Integer, String>{
        200 => 'OK',
        201 => 'CREATED',
        202 => 'ACCEPTED',
        204 => 'NO_CONTENT',
        400 => 'BAD_REQUEST',
        401 => 'UNAUTHORIZED',
        403 => 'FORBIDDEN',
        404 => 'NOT_FOUND',
        500 => 'INTERNAL_SERVER_ERROR'
    };

    @testVisible
    private static void simulateException(Exception ex) {
        simulatedException = ex;
    }

    /**
     * @description: sets the response code for the RestContext
     * @author Stian Ruud Schikora | 06-22-2021
     * @param responseCode
     **/
    global static void setResponse(Integer responseCode) {
        if (simulatedException != null)
            throw simulatedException;
        // Instantiate the RestResponse
        RestResponse response = RestContext.response;
        response.statusCode = responseCode;
        response.addHeader('Content-Type', 'application/json');
    }

    /**
     * @description: Sets the response code and payload for the RestContext.
     * @author Stian Ruud Schikora | 06-22-2021
     * @param responseCode
     * @param payload
     **/
    global static void setResponse(Integer responseCode, String payload) {
        if (simulatedException != null)
            throw simulatedException;
        // Instantiate the RestResponse
        RestResponse response = RestContext.response;
        response.statusCode = responseCode;
        response.addHeader('Content-Type', 'application/json');
        if (String.isNotBlank(payload))
            response.responseBody = Blob.valueOf(payload);
    }

    /**
     * @description: Adds an error response to the RestContext usin the model defined by Error class
     * @author Stian Ruud Schikora | 07-08-2021
     * @param responseCode
     * @param message
     **/
    global static void errorResponse(Integer responseCode, String message) {
        // Instantiate the RestResponse
        RestResponse response = RestContext.response;
        response.statusCode = responseCode;
        response.addHeader('Content-Type', 'application/json');
        if (String.isNotBlank(message)) {
            response.responseBody = Blob.valueOf(JSON.serialize(new Error(responseCode, message)));
        } else {
            String defaultMessage = DEFAULT_RESPONSE_MAP.containsKey(responseCode)
                ? DEFAULT_RESPONSE_MAP.get(responseCode)
                : null;
            response.responseBody = Blob.valueOf(JSON.serialize(new Error(responseCode, defaultMessage)));
        }
    }

    /**
     * @description: Returns the query parameter from the request with the specified parameter name, null if not existing.
     * @author Stian Ruud Schikora | 06-22-2021
     * @param paramName
     * @return String
     **/
    global static String getRequestParam(String paramName) {
        RestRequest request = RestContext.request;
        return request.params.containsKey(paramName) ? request.params.get(paramName) : null;
    }

    /**
     * @description: Returns the header from the request, null if not existing.
     * @author Stian Ruud Schikora | 06-22-2021
     * @param paramName
     * @return String
     **/
    global static String getRequestHeader(String headerName) {
        RestRequest request = RestContext.request;
        return request.headers.containsKey(headerName) ? request.headers.get(headerName) : null;
    }

    /**
     * @description: Returns the last path parameter in the request URI. If the URI ends with '/' this is removed
     * @author Stian Ruud Schikora | 06-22-2021
     * @return String
     **/
    global static String getLastPathParameter() {
        RestRequest request = RestContext.request;
        return request.requestURI.substringAfterLast('/').substringBefore('?'); //Handle if there are any query parameters
    }

    /**
     * @description: Returns the part of the URI path between two strings. i.e. for a path /account/{accountId}/search/{contactName}
     * a call with firstMatch = account and secondMatch = search should return the accountId path parameter
     * @author Stian Ruud Schikora | 06-22-2021
     * @param firstMatch
     * @param secondMatch
     * @return String
     **/
    global static String getPathStringBetween(String firstMatch, String secondMatch) {
        RestRequest request = RestContext.request;
        return request.requestURI.substringBetween(firstMatch + '/', '/' + secondMatch);
    }

    /**
     * @description: Generic validation for all rest services extending this super class
     * @author Stian Ruud Schikora | 07-05-2021
     * @return Boolean
     **/
    global static Boolean validate() {
        //All endpoints must have a unique correlation ID used for troubleshooting in the callout chain
        RestRequest request = RestContext.request;
        Boolean valid = String.isNotBlank(getXCorrelation());
        if (!valid) {
            errorResponse(400, 'Missing required parameter: X-Correlation-ID');
        }
        return valid;
    }

    /**
     * @description: Gets the X-Correlation header for an incoming request
     * @author Stian Ruud Schikora | 07-19-2021
     * @return String
     **/
    global static String getXCorrelation() {
        return getRequestHeader('X-Correlation-ID');
    }

    public class Error {
        private Integer statusCode;
        private String message;

        public Error(Integer statusCode, String message) {
            this.statusCode = statusCode;
            this.message = message;
        }
    }
}
