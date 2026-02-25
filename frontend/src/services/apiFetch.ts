/**
 * apiFetch — a drop-in replacement for fetch() that handles 401 Unauthorized
 * responses automatically by refreshing the backend JWT and retrying once.
 *
 * Usage:  apiFetch('/api/admin/appointments', { headers: getHeaders() })
 *
 * On 401:
 *   1. Calls the registered onRefreshToken callback (set by AuthContext)
 *   2. If refresh succeeds → retries the request with the new token from localStorage
 *   3. If retry still 401, or if refresh fails → calls onForceLogout → redirects to /login
 */

type RefreshCallback = () => Promise<boolean>;
type LogoutCallback = () => Promise<void>;

let _onRefreshToken: RefreshCallback | null = null;
let _onForceLogout: LogoutCallback | null = null;

/** Called once by AuthContext on mount to register the refresh + logout handlers. */
export function registerAuthHandlers(
    onRefreshToken: RefreshCallback,
    onForceLogout: LogoutCallback
) {
    _onRefreshToken = onRefreshToken;
    _onForceLogout = onForceLogout;
}

function buildAuthHeader(): Record<string, string> {
    const token = localStorage.getItem('token');
    return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * Wraps fetch() with automatic 401-retry logic.
 * Pass the same arguments you would pass to fetch().
 * For requests that need auth, include the Authorization header in your init.headers —
 * apiFetch will automatically replace it with the refreshed token on retry.
 */
export async function apiFetch(
    input: RequestInfo | URL,
    init?: RequestInit
): Promise<Response> {
    // First attempt
    const response = await fetch(input, init);

    if (response.status !== 401) return response;

    // --- 401 received — attempt a token refresh ---
    console.warn('[apiFetch] 401 received. Attempting token refresh...');

    if (!_onRefreshToken) {
        // No handler registered yet (e.g. during initial load), just return the 401
        return response;
    }

    let refreshed = false;
    try {
        refreshed = await _onRefreshToken();
    } catch {
        refreshed = false;
    }

    if (!refreshed) {
        console.error('[apiFetch] Token refresh failed. Forcing logout.');
        await _onForceLogout?.();
        window.location.href = '/login';
        return response;
    }

    // Rebuild the Authorization header with the new token and retry
    const newAuthHeaders = buildAuthHeader();
    const retryInit: RequestInit = {
        ...init,
        headers: {
            ...(init?.headers as Record<string, string> | undefined),
            ...newAuthHeaders,
        },
    };

    console.log('[apiFetch] Retrying request with refreshed token...');
    const retryResponse = await fetch(input, retryInit);

    if (retryResponse.status === 401) {
        // Still unauthorized after refresh — force logout
        console.error('[apiFetch] Retry still 401. Forcing logout.');
        await _onForceLogout?.();
        window.location.href = '/login';
    }

    return retryResponse;
}
