// QEMU integration test helpers
// Simple utilities for testing against QEMU LibreMesh backend
import QemuAuth from "./qemu-auth-helpers";

/**
 * Check if QEMU LibreMesh is available for testing
 * @returns {Promise<boolean>}
 */
export const isQemuAvailable = async () => {
    if (typeof window === "undefined") return false; // Not in browser

    try {
        return await QemuAuth.isQemuAccessible();
    } catch {
        return false;
    }
};

/**
 * Skip test if QEMU is not available
 * Usage: it.skipIf(!isQemuEnabled)('test name', () => { ... })
 */
export const isQemuEnabled = process.env.QEMU_TEST === "true";

/**
 * Wait for network calls to settle in tests
 * @param {number} timeout - Timeout in milliseconds
 */
export const waitForNetwork = (timeout = 1000) =>
    new Promise((resolve) => setTimeout(resolve, timeout));

/**
 * Create mock LibreMesh response for consistent testing
 * @param {Object} overrides - Override default values
 */
export const createLibreMeshResponse = (overrides = {}) => ({
    jsonrpc: "2.0",
    id: 1,
    result: [0, { ...overrides }],
});

/**
 * Test utilities for QEMU integration
 */
export const QemuTestUtils = {
    isAvailable: isQemuAvailable,
    isEnabled: isQemuEnabled,
    waitForNetwork,
    createResponse: createLibreMeshResponse,
    auth: QemuAuth,

    /**
     * Setup authenticated test environment
     */
    setupAuthenticatedTests: () => {
        QemuAuth.QemuTestHelpers.setupTests();
    },

    /**
     * Test with authentication
     */
    withAuth: QemuAuth.QemuTestHelpers.skipIfQemuUnavailable,
};