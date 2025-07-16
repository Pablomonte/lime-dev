// QEMU LibreMesh Authentication Helpers for Testing
// Provides utilities for authenticating with QEMU backend during integration tests

/**
 * QEMU LibreMesh authentication configuration
 */
const QEMU_CONFIG = {
    baseUrl: "http://10.13.0.1",
    credentials: {
        username: "root",
        password: "admin", // Set by persistent setup script
    },
    timeout: 10000, // 10 seconds
};

/**
 * Session storage for test runs
 */
let testSession = null;

/**
 * Make authenticated ubus call to QEMU LibreMesh
 * @param {string} service - ubus service name
 * @param {string} method - ubus method name
 * @param {Object} params - method parameters
 * @param {string} sessionId - optional session ID (will authenticate if not provided)
 * @returns {Promise<Object>} ubus response
 */
export const ubusCall = async (
    service,
    method,
    params = {},
    sessionId = null
) => {
    if (typeof window === "undefined") {
        throw new Error("ubusCall can only be used in browser environment");
    }

    const session = sessionId || (await getAuthenticatedSession());

    const payload = {
        jsonrpc: "2.0",
        id: Date.now(),
        method: "call",
        params: [session, service, method, params],
    };

    const response = await fetch(`${QEMU_CONFIG.baseUrl}/ubus`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
    });

    if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();

    if (data.error) {
        throw new Error(`ubus error: ${JSON.stringify(data.error)}`);
    }

    // Check for ubus result array format
    if (Array.isArray(data.result)) {
        const [errorCode, result] = data.result;
        if (errorCode !== 0) {
            throw new Error(`ubus call failed with code ${errorCode}`);
        }
        return result;
    }

    return data.result;
};

/**
 * Authenticate with QEMU LibreMesh and get session ID
 * @returns {Promise<string>} session ID
 */
export const getAuthenticatedSession = async () => {
    if (testSession) {
        // Check if session is still valid
        try {
            await ubusCall("session", "access", {}, testSession);
            return testSession;
        } catch {
            // Session expired, re-authenticate
            testSession = null;
        }
    }

    const payload = {
        jsonrpc: "2.0",
        id: Date.now(),
        method: "call",
        params: [
            "00000000000000000000000000000000",
            "session",
            "login",
            QEMU_CONFIG.credentials,
        ],
    };

    const response = await fetch(`${QEMU_CONFIG.baseUrl}/ubus`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
    });

    if (!response.ok) {
        throw new Error(`Authentication failed: HTTP ${response.status}`);
    }

    const data = await response.json();

    if (data.error) {
        throw new Error(`Authentication error: ${JSON.stringify(data.error)}`);
    }

    if (Array.isArray(data.result)) {
        const [errorCode, sessionData] = data.result;
        if (errorCode !== 0) {
            throw new Error(`Authentication failed with code ${errorCode}`);
        }

        if (sessionData && sessionData.ubus_rpc_session) {
            testSession = sessionData.ubus_rpc_session;
            return testSession;
        }
    }

    throw new Error("Invalid authentication response format");
};

/**
 * Check if QEMU LibreMesh is available and accessible
 * @returns {Promise<boolean>}
 */
export const isQemuAccessible = async () => {
    try {
        const response = await fetch(`${QEMU_CONFIG.baseUrl}/ubus`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                jsonrpc: "2.0",
                id: 1,
                method: "list",
                params: [],
            }),
        });
        return response.ok;
    } catch {
        return false;
    }
};

/**
 * Test authentication with QEMU LibreMesh
 * @returns {Promise<boolean>}
 */
export const testAuthentication = async () => {
    try {
        const session = await getAuthenticatedSession();
        return !!session;
    } catch {
        return false;
    }
};

/**
 * Get system information from QEMU LibreMesh
 * @returns {Promise<Object>}
 */
export const getSystemInfo = async () => {
    return await ubusCall("system", "info");
};

/**
 * Get board information from QEMU LibreMesh
 * @returns {Promise<Object>}
 */
export const getBoardInfo = async () => {
    return await ubusCall("system", "board");
};

/**
 * List available ubus services
 * @returns {Promise<Object>}
 */
export const listServices = async () => {
    const payload = {
        jsonrpc: "2.0",
        id: Date.now(),
        method: "list",
        params: [],
    };

    const response = await fetch(`${QEMU_CONFIG.baseUrl}/ubus`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
    });

    const data = await response.json();
    return data.result || {};
};

/**
 * Test remote support (tmate) service
 * @returns {Promise<Object>}
 */
export const testTmateService = async () => {
    try {
        // First check if session exists
        const sessionResult = await ubusCall("tmate", "get_session");
        return {
            available: true,
            hasSession: !!sessionResult,
            sessionData: sessionResult,
        };
    } catch (error) {
        return {
            available: false,
            error: error.message,
        };
    }
};

/**
 * Clean up test session
 */
export const cleanupTestSession = () => {
    testSession = null;
};

/**
 * Jest test helpers
 */
export const QemuTestHelpers = {
    /**
     * Setup QEMU tests with proper timeouts and authentication
     */
    setupTests: () => {
        // Increase Jest timeout for integration tests
        jest.setTimeout(30000);

        beforeEach(() => {
            // Clear session before each test
            cleanupTestSession();
        });

        afterEach(() => {
            // Clean up after each test
            cleanupTestSession();
        });
    },

    /**
     * Skip test if QEMU is not available
     * @param {Function} testFn - Test function
     * @returns {Function} Conditional test function
     */
    skipIfQemuUnavailable: (testFn) => {
        return async (...args) => {
            const available = await isQemuAccessible();
            if (!available) {
                console.warn("Skipping test: QEMU LibreMesh not available");
                return;
            }
            return testFn(...args);
        };
    },

    /**
     * Mock LibreMesh API responses for tests
     */
    mockLibreMeshApi: () => {
        const mockFetch = jest.fn();

        // Mock successful authentication
        mockFetch.mockImplementation((url, options) => {
            if (url.includes("/ubus")) {
                const body = JSON.parse(options.body);

                if (
                    body.params &&
                    body.params[1] === "session" &&
                    body.params[2] === "login"
                ) {
                    return Promise.resolve({
                        ok: true,
                        json: () =>
                            Promise.resolve({
                                jsonrpc: "2.0",
                                id: body.id,
                                result: [
                                    0,
                                    { ubus_rpc_session: "mock-session-id" },
                                ],
                            }),
                    });
                }

                // Mock other ubus calls
                return Promise.resolve({
                    ok: true,
                    json: () =>
                        Promise.resolve({
                            jsonrpc: "2.0",
                            id: body.id,
                            result: [0, { mock: "data" }],
                        }),
                });
            }

            return Promise.reject(new Error("Unknown URL"));
        });

        global.fetch = mockFetch;
        return mockFetch;
    },

    /**
     * Restore original fetch
     */
    restoreFetch: () => {
        // Restore Jest mock methods if available
        if (
            global.fetch &&
            typeof global.fetch === "function" &&
            "mockRestore" in global.fetch
        ) {
            // Use bracket notation to avoid TypeScript error
            global.fetch["mockRestore"]();
        }
    },
};

/**
 * Default export with commonly used functions
 */
export default {
    ubusCall,
    getAuthenticatedSession,
    isQemuAccessible,
    testAuthentication,
    getSystemInfo,
    getBoardInfo,
    listServices,
    testTmateService,
    cleanupTestSession,
    QemuTestHelpers,
    QEMU_CONFIG,
};