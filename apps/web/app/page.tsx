'use client';

import { useEffect, useMemo, useState } from 'react';
import { onAuthStateChanged, signInWithPopup, signOut, User } from 'firebase/auth';
import { auth, googleProvider } from '@/lib/firebase';
import { ApiClientError, createUser, deleteUser, listUsers, updateUser, UserDto, UserFieldErrors } from '@/lib/api';

type FormState = {
  username: string;
  tcNo: string;
  email: string;
  phone: string;
};

const emptyForm: FormState = { username: '', tcNo: '', email: '', phone: '' };

export default function HomePage() {
  const [firebaseUser, setFirebaseUser] = useState<User | null>(null);
  const [token, setToken] = useState('');
  const [users, setUsers] = useState<UserDto[]>([]);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<UserFieldErrors>({});

  useEffect(() => {
    return onAuthStateChanged(auth, async (currentUser) => {
      setFirebaseUser(currentUser);
      if (currentUser) {
        const idToken = await currentUser.getIdToken();
        setToken(idToken);
      } else {
        setToken('');
        setUsers([]);
      }
    });
  }, []);

  useEffect(() => {
    if (!token) return;
    void loadUsers(token);
  }, [token]);

  const isEditing = useMemo(() => editingId !== null, [editingId]);

  async function loadUsers(idToken: string) {
    try {
      setError('');
      const data = await listUsers(idToken);
      setUsers(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Kullanıcılar yüklenemedi.');
    }
  }

  async function handleLogin() {
    await signInWithPopup(auth, googleProvider);
  }

  async function handleLogout() {
    await signOut(auth);
    setForm(emptyForm);
    setEditingId(null);
    setNotice('');
    setError('');
  }

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!token) return;

    try {
      setError('');
      setNotice('');
      setFieldErrors({});
      if (isEditing && editingId !== null) {
        await updateUser(token, editingId, form);
        setNotice('Kullanıcı güncellendi.');
      } else {
        await createUser(token, form);
        setNotice('Kullanıcı eklendi.');
      }

      setForm(emptyForm);
      setEditingId(null);
      await loadUsers(token);
    } catch (e) {
      if (e instanceof ApiClientError) {
        setFieldErrors(e.fieldErrors);
        setError(e.message);
      } else {
        setError('İşlem başarısız.');
      }
    }
  }

  async function handleDelete(id: number) {
    if (!token) return;

    try {
      setError('');
      await deleteUser(token, id);
      setNotice('Kullanıcı silindi.');
      await loadUsers(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Silme başarısız.');
    }
  }

  function startEdit(user: UserDto) {
    setError('');
    setNotice('');
    setFieldErrors({});
    setEditingId(user.id);
    setForm({
      username: user.username,
      tcNo: user.tcNo,
      email: user.email,
      phone: user.phone
    });
  }

  return (
    <main>
      <header>
        <div>
          <h1>Kullanıcı Yönetimi</h1>
          <p>Web paneli Firebase kimliği ile API'ye bağlanır.</p>
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
            <h2>{isEditing ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı Ekle'}</h2>
            <form onSubmit={handleSubmit}>
              <div className="field">
                <input
                  placeholder="Kullanıcı adı"
                  value={form.username}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, username: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, username: undefined }));
                  }}
                  className={fieldErrors.username ? 'input-error' : ''}
                  required
                />
                {fieldErrors.username && <small className="field-error">{fieldErrors.username}</small>}
              </div>
              <div className="field">
                <input
                  placeholder="TC No"
                  value={form.tcNo}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, tcNo: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, tcNo: undefined }));
                  }}
                  className={fieldErrors.tcNo ? 'input-error' : ''}
                  maxLength={11}
                  required
                />
                {fieldErrors.tcNo && <small className="field-error">{fieldErrors.tcNo}</small>}
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
                  className={fieldErrors.email ? 'input-error' : ''}
                  required
                />
                {fieldErrors.email && <small className="field-error">{fieldErrors.email}</small>}
              </div>
              <div className="field">
                <input
                  placeholder="Telefon"
                  value={form.phone}
                  onChange={(e) => {
                    setForm((prev) => ({ ...prev, phone: e.target.value }));
                    setFieldErrors((prev) => ({ ...prev, phone: undefined }));
                  }}
                  className={fieldErrors.phone ? 'input-error' : ''}
                  required
                />
                {fieldErrors.phone && <small className="field-error">{fieldErrors.phone}</small>}
              </div>
              <div className="actions">
                <button type="submit">{isEditing ? 'Güncelle' : 'Kaydet'}</button>
                {isEditing && (
                  <button
                    type="button"
                    className="secondary"
                    onClick={() => {
                      setEditingId(null);
                      setForm(emptyForm);
                      setFieldErrors({});
                      setError('');
                      setNotice('');
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
                {users.map((user) => (
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
                        <button type="button" className="danger" onClick={() => handleDelete(user.id)}>
                          Sil
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
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
