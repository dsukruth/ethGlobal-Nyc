declare class ApiEndpoint {
    private static __baseUrl__;
    private static __defined__;
    static getBaseUrl: () => string | undefined;
    static setBaseUrl: (baseUrlInput?: string) => void;
}
export default ApiEndpoint;
