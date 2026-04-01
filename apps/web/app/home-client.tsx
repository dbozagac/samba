"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  browserLocalPersistence,
  onIdTokenChanged,
  setPersistence,
  signInWithRedirect,
  signInWithPopup,
  signOut,
  User,
} from "firebase/auth";
import {
  auth,
  firebaseConfigurationError,
  googleProvider,
  isFirebaseConfigured,
} from "@/lib/firebase";
import {
  ApiClientError,
  createUser,
  deleteUser,
  listUsers,
  updateUser,
  PagedResponse,
  UserDto,
  UserFieldErrors,
} from "@/lib/api";

type FormState = {
  username: string;
  tcNo: string;
  email: string;
  phone: string;
};

const emptyForm: FormState = { username: "", tcNo: "", email: "", phone: "" };
const PAGE_SIZE = 20;

export default function HomePage() {
  const [firebaseUser, setFirebaseUser] = useState<User | null>(null);
  const [token, setToken] = useState("");
  const [pagedData, setPagedData] = useState<PagedResponse<UserDto>>({
    items: [],
    page: 1,
    pageSize: PAGE_SIZE,
    totalCount: 0,
    totalPages: 0,
  });
  const [form, setForm] = useState<FormState>(emptyForm);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [fieldErrors, setFieldErrors] = useState<UserFieldErrors>({});

  // Pagination & search state
  const [currentPage, setCurrentPage] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");

  useEffect(() => {
    if (!auth) {
      setError(
        firebaseConfigurationError ??
          "Firebase yapılandırması eksik. NEXT_PUBLIC_FIREBASE_* değişkenlerini ayarlayın.",
      );
      return;
    }

    void setPersistence(auth, browserLocalPersistence).catch(() => {
      // Persistence ayarlanamazsa varsayılan persistence ile devam edilir.
    });

    return onIdTokenChanged(auth, async (currentUser) => {
      setFirebaseUser(currentUser);
      if (currentUser) {
        const idToken = await currentUser.getIdToken();
        setToken(idToken);
      } else {
        setToken("");
        setPagedData({
          items: [],
          page: 1,
          pageSize: PAGE_SIZE,
          totalCount: 0,
          totalPages: 0,
        });
      }
    });
  }, []);

  const loadUsers = useCallback(
    async (idToken: string, page: number, searchTerm: string) => {
      try {
        setError("");
        const data = await listUsers(idToken, {
          page,
          pageSize: PAGE_SIZE,
          search: searchTerm || undefined,
          sortDesc: true,
        });
        setPagedData(data);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Kullanıcılar yüklenemedi.");
      }
    },
    [],
  );

  useEffect(() => {
    if (!token) return;
    void loadUsers(token, currentPage, search);
  }, [token, currentPage, search, loadUsers]);

  const isEditing = useMemo(() => editingId !== null, [editingId]);

  async function handleLogin() {
    if (!auth || !isFirebaseConfigured) {
      setError(
        firebaseConfigurationError ??
          "Firebase yapılandırması eksik. Lütfen ortam değişkenlerini kontrol edin.",
      );
      return;
    }

    try {
      setError("");
      await setPersistence(auth, browserLocalPersistence);
      await signInWithPopup(auth, googleProvider);
    } catch (e) {
      const parsedError = e as { code?: unknown; message?: unknown } | null;
      const code =
        parsedError && parsedError.code
          ? String(parsedError.code)
          : "";

      if (code === "auth/popup-blocked") {
        await signInWithRedirect(auth, googleProvider);
        return;
      }

      if (code === "auth/popup-closed-by-user") {
        return;
      }

      setError(
        parsedError && parsedError.message
          ? String(parsedError.message)
          : "Google ile giriş başarısız oldu.",
      );
    }
  }

  async function handleLogout() {
    if (!auth) return;

    await signOut(auth);
    setForm(emptyForm);
    setEditingId(null);
    setNotice("");
    setError("");
    setSearch("");
    setSearchInput("");
    setCurrentPage(1);
  }

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!token) return;

    try {
      setError("");
      setNotice("");
      setFieldErrors({});
      if (isEditing && editingId !== null) {
        await updateUser(token, editingId, form);
        setNotice("Kullanıcı güncellendi.");
      } else {
        await createUser(token, form);
        setNotice("Kullanıcı eklendi.");
      }

      setForm(emptyForm);
      setEditingId(null);
      await loadUsers(token, currentPage, search);
    } catch (e) {
      if (e instanceof ApiClientError) {
        setFieldErrors(e.fieldErrors);
        setError(e.message);
      } else {
        setError("İşlem başarısız.");
      }
    }
  }

  async function handleDelete(id: number) {
    if (!token) return;

    try {
      setError("");
      await deleteUser(token, id);
      setNotice("Kullanıcı silindi.");
      await loadUsers(token, currentPage, search);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Silme başarısız.");
    }
  }

  function startEdit(user: UserDto) {
    setError("");
    setNotice("");
    setFieldErrors({});
    setEditingId(user.id);
    setForm({
      username: user.username,
      tcNo: user.tcNo,
      email: user.email,
      phone: user.phone,
    });
  }

  function handleSearchSubmit(e: React.FormEvent) {
    e.preventDefault();
    setCurrentPage(1);
    setSearch(searchInput);
  }

  return (
    <main>
      <header>
        <div>
          <h1>Kullanıcı Yönetimi</h1>
          <p>Web paneli Firebase kimliği ile API&apos;ye bağlanır.</p>
        </div>
        {firebaseUser ? (
          <div className="actions">
            <span>{firebaseUser.email}</span>
            <button onClick={handleLogout} className="secondary" type="button">
              Çıkış
            </button>
          </div>
        ) : (
          <button onClick={handleLogin} type="button">
            Google ile Giriş
          </button>
        )}
      </header>

      {notice && <p className="notice">{notice}</p>}
      {error && <p className="error">{error}</p>}

      {firebaseUser ? (
        <>
          <section className="card">
            <h2>{isEditing ? "Kullanıcı Düzenle" : "Yeni Kullanıcı Ekle"}</h2>
            <form onSubmit={handleSubmit}>
              <div className="field">
                <input
                  placeholder="Kullanıcı adı"
                  value={form.username}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, username: e.target.value }));
                    setFieldErrors((prev) => ({
                      ...prev,
                      username: undefined,
                    }));
                  }}
                  className={fieldErrors.username ? "input-error" : ""}
                  required
                />
                {fieldErrors.username && (
                  <small className="field-error">{fieldErrors.username}</small>
                )}
              </div>
              <div className="field">
                <input
                  placeholder="TC No"
                  value={form.tcNo}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, tcNo: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, tcNo: undefined }));
                  }}
                  className={fieldErrors.tcNo ? "input-error" : ""}
                  maxLength={11}
                  required
                />
                {fieldErrors.tcNo && (
                  <small className="field-error">{fieldErrors.tcNo}</small>
                )}
              </div>
              <div className="field">
                <input
                  type="email"
                  placeholder="E-posta"
                  value={form.email}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, email: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, email: undefined }));
                  }}
                  className={fieldErrors.email ? "input-error" : ""}
                  required
                />
                {fieldErrors.email && (
                  <small className="field-error">{fieldErrors.email}</small>
                )}
              </div>
              <div className="field">
                <input
                  placeholder="Telefon"
                  value={form.phone}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, phone: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, phone: undefined }));
                  }}
                  className={fieldErrors.phone ? "input-error" : ""}
                  required
                />
                {fieldErrors.phone && (
                  <small className="field-error">{fieldErrors.phone}</small>
                )}
              </div>
              <div className="actions">
                <button type="submit">
                  {isEditing ? "Güncelle" : "Kaydet"}
                </button>
                {isEditing && (
                  <button
                    type="button"
                    className="secondary"
                    onClick={() => {
                      setEditingId(null);
                      setForm(emptyForm);
                      setFieldErrors({});
                      setError("");
                      setNotice("");
                    }}
                  >
                    İptal
                  </button>
                )}
              </div>
            </form>
          </section>

          <section className="card">
            <h2>Kayıtlı Kullanıcılar</h2>

            {/* Search */}
            <form onSubmit={handleSearchSubmit} className="search-bar">
              <input
                placeholder="Ad, TC, e-posta veya telefon ile ara…"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
              />
              <button type="submit">Ara</button>
              {search && (
                <button
                  type="button"
                  className="secondary"
                  onClick={() => {
                    setSearchInput("");
                    setSearch("");
                    setCurrentPage(1);
                  }}
                >
                  Temizle
                </button>
              )}
            </form>

            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Ad</th>
                  <th>TC No</th>
                  <th>E-posta</th>
                  <th>Telefon</th>
                  <th>İşlem</th>
                </tr>
              </thead>
              <tbody>
                {pagedData.items.map((user) => (
                  <tr key={user.id}>
                    <td>{user.id}</td>
                    <td>{user.username}</td>
                    <td>{user.tcNo}</td>
                    <td>{user.email}</td>
                    <td>{user.phone}</td>
                    <td>
                      <div className="actions">
                        <button type="button" onClick={() => startEdit(user)}>
                          Düzenle
                        </button>
                        <button
                          type="button"
                          className="danger"
                          onClick={() => handleDelete(user.id)}
                        >
                          Sil
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {pagedData.items.length === 0 && (
                  <tr>
                    <td colSpan={6} className="empty-state">
                      {search
                        ? "Aramanızla eşleşen kayıt bulunamadı."
                        : "Henüz kayıt yok."}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>

            {/* Pagination */}
            {pagedData.totalPages > 1 && (
              <div className="pagination">
                <button
                  type="button"
                  disabled={currentPage <= 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                >
                  ← Önceki
                </button>
                <span>
                  Sayfa {pagedData.page} / {pagedData.totalPages} (
                  {pagedData.totalCount} kayıt)
                </span>
                <button
                  type="button"
                  disabled={currentPage >= pagedData.totalPages}
                  onClick={() =>
                    setCurrentPage((p) => Math.min(pagedData.totalPages, p + 1))
                  }
                >
                  Sonraki →
                </button>
              </div>
            )}
          </section>
        </>
      ) : (
        <section className="card">
          <p>Devam etmek için Google hesabınla giriş yap.</p>
        </section>
      )}
    </main>
  );
}
