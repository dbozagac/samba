export type UserDto = {
  id: number;
  username: string;
  tcNo: string;
  email: string;
  phone: string;
  createdAtUtc: string;
  updatedAtUtc: string;
};

export type UserFieldErrors = Partial<Record<'username' | 'tcNo' | 'email' | 'phone', string>>;

export class ApiClientError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly fieldErrors: UserFieldErrors = {}
  ) {
    super(message);
    this.name = 'ApiClientError';
  }
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8080';

function normalizeFieldName(field: string): keyof UserFieldErrors | null {
  const normalized = field.toLowerCase().replace(/[^a-z]/g, '');
  if (normalized === 'username') return 'username';
  if (normalized === 'tcno') return 'tcNo';
  if (normalized === 'email') return 'email';
  if (normalized === 'phone') return 'phone';
  return null;
}

function getErrorMessage(payload: unknown, status: number): string {
  if (status === 401) return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
  if (status === 403) return 'Bu işlem için yetkiniz yok.';

  if (payload && typeof payload === 'object' && 'message' in payload && typeof payload.message === 'string') {
    return payload.message;
  }

  return 'İşlem sırasında bir hata oluştu. Lütfen bilgileri kontrol edip tekrar deneyin.';
}

function extractFieldErrors(payload: unknown): UserFieldErrors {
  const fieldErrors: UserFieldErrors = {};
  if (!payload || typeof payload !== 'object') return fieldErrors;

  if ('field' in payload && typeof payload.field === 'string' && 'message' in payload && typeof payload.message === 'string') {
    const mapped = normalizeFieldName(payload.field);
    if (mapped) fieldErrors[mapped] = payload.message;
  }

  if ('errors' in payload && payload.errors && typeof payload.errors === 'object') {
    for (const [key, value] of Object.entries(payload.errors as Record<string, unknown>)) {
      const mapped = normalizeFieldName(key);
      if (!mapped) continue;

      if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'string') {
        fieldErrors[mapped] = value[0];
      } else if (typeof value === 'string') {
        fieldErrors[mapped] = value;
      }
    }
  }

  return fieldErrors;
}

async function request<T>(path: string, token: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...(init?.headers ?? {})
    },
    cache: 'no-store'
  });

  if (!response.ok) {
    const text = await response.text();
    let payload: unknown = null;

    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      payload = null;
    }

    const message = text && !payload ? text : getErrorMessage(payload, response.status);
    const fieldErrors = extractFieldErrors(payload);
    throw new ApiClientError(message, response.status, fieldErrors);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}

export function listUsers(token: string) {
  return request<UserDto[]>('/api/users', token);
}

export function createUser(token: string, payload: Omit<UserDto, 'id' | 'createdAtUtc' | 'updatedAtUtc'>) {
  return request<UserDto>('/api/users', token, {
    method: 'POST',
    body: JSON.stringify(payload)
  });
}

export function updateUser(
  token: string,
  id: number,
  payload: Omit<UserDto, 'id' | 'createdAtUtc' | 'updatedAtUtc'>
) {
  return request<UserDto>(`/api/users/${id}`, token, {
    method: 'PUT',
    body: JSON.stringify(payload)
  });
}

export function deleteUser(token: string, id: number) {
  return request<void>(`/api/users/${id}`, token, { method: 'DELETE' });
}
