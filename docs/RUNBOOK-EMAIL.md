# Email autentikasi: keluar dari batas kirim Supabase

## Kenapa perlu

Layanan email bawaan Supabase memang bukan untuk produksi. Batasnya **2 email
per jam untuk seluruh proyek** — bukan per pengguna — dan Supabase menyebutnya
"best effort", tanpa jaminan sampai. Begitu dua orang mendaftar dalam satu jam,
orang ketiga menerima `email rate limit exceeded`.

Dengan SMTP sendiri, batas itu ditentukan penyedia email dan kuota di Supabase
bisa dinaikkan (bawaannya 30 email/jam setelah SMTP terpasang, dan angkanya
bisa diubah).

Semua langkah di bawah dikerjakan di dashboard, bukan di kode. Kode aplikasi
tidak perlu diubah sama sekali: Supabase tetap yang mengirim, hanya jalurnya
yang berganti.

## Pilihan penyedia

| Penyedia | Kuota gratis | Catatan |
|---|---|---|
| **Resend** | 3.000 email/bulan, 100/hari | Paling cepat disiapkan, dokumentasinya menyebut Supabase langsung |
| **Brevo** (dulu Sendinblue) | 300 email/hari | Kuota harian terbesar di antara yang gratis |
| **Mailgun** | 100 email/hari | Perlu kartu kredit saat mendaftar |
| **Amazon SES** | ~$0,10 per 1.000 email | Termurah kalau volumenya besar, penyiapannya paling panjang |
| Gmail / Google Workspace | 500 email/hari | Tidak disarankan: akun bisa dikunci kalau dianggap mengirim massal |

Untuk MVP Navika, Resend atau Brevo sudah lebih dari cukup — satu email per
pendaftar, ditambah reset sandi sesekali.

## Langkah

### 1. Siapkan domain pengirim

Pengirim sebaiknya memakai domain sendiri, misalnya `noreply@navika.id`.
Mengirim atas nama `@gmail.com` akan banyak masuk spam, karena SPF dan DKIM
milik Gmail tidak mengizinkan penyedia lain mengirim atas namanya.

Di dashboard penyedia, tambahkan domain lalu salin data DNS yang diminta
(umumnya tiga baris: SPF, DKIM, dan kadang DMARC) ke pengelola domain. Tunggu
sampai statusnya "verified".

Belum punya domain? Sementara bisa pakai domain uji coba milik penyedia
(Resend: `onboarding@resend.dev`) — hanya untuk pengujian, tidak untuk rilis.

### 2. Ambil kredensial SMTP

Host, username, dan password semuanya datang dari penyedia — tidak ada yang
boleh dikarang sendiri. Port selalu `587` (STARTTLS), bukan 25.

| Penyedia | Host | Username | Password |
|---|---|---|---|
| Resend | `smtp.resend.com` | `resend` (harfiah, memang kata itu) | API key, diawali `re_` |
| Brevo | `smtp-relay.brevo.com` | login SMTP berbentuk `xxxxxx@smtp-brevo.com` | SMTP key dari menu SMTP & API |
| Mailgun | `smtp.mailgun.org` | `postmaster@mg.domainmu.com` | password SMTP di halaman domain |
| Amazon SES | `email-smtp.<region>.amazonaws.com` | hasil "Create SMTP credentials" | dari langkah yang sama |

Di Resend, kuncinya dibuat di **API Keys → Create API Key** dan hanya tampil
sekali. Supabase juga menyembunyikannya setelah disimpan, jadi simpan salinannya
di pengelola kata sandi, bukan di catatan atau chat.

### 3. Pasang di Supabase

**Dashboard → Project Settings → Authentication → SMTP Settings**

1. Nyalakan **Enable Custom SMTP**
2. Sender email: `noreply@navika.id`
3. Sender name: `Navika`
4. Host, Port, Username, Password dari langkah 2
5. Save

### 4. Naikkan batas kirim

**Dashboard → Authentication → Rate Limits → "Rate limit for sending emails"**

Setelah SMTP sendiri terpasang, angkanya bisa dinaikkan. Untuk MVP, 100–200
email per jam cukup lapang. Jangan dibuat tak terbatas: batas itu juga yang
menahan penyalahgunaan kalau ada yang mendaftar massal.

### 5. Uji

Daftar dengan satu email baru, pastikan emailnya masuk, lalu periksa di
penyedia bahwa pengirimannya tercatat di sana — itu bukti jalur SMTP-nya
benar-benar dipakai.

Kalau emailnya masuk spam, periksa lagi status SPF/DKIM di langkah 1.

## Isi email

**Dashboard → Authentication → Email Templates**

Template bawaannya berbahasa Inggris dan tanpa merek: "Confirm your email
address / Follow the link below…". Gantinya ada di repo, tinggal salin seluruh
isi berkasnya ke kolom Message body:

| Template di Supabase | Berkas | Subject |
|---|---|---|
| Confirm signup | `docs/email/confirm-signup.html` | Verifikasi email Navika kamu |
| Reset password | `docs/email/reset-password.html` | Atur ulang kata sandi Navika |

Keduanya memakai tabel dan gaya inline, bukan flexbox atau `<style>`: Gmail,
Outlook, dan aplikasi email bawaan HP membuang stylesheet dan tidak mengenal
layout modern. Tidak ada gambar sama sekali, jadi tampilannya utuh walau
penerima memblokir gambar — yang biasa dilakukan Gmail untuk pengirim baru.

Variabel yang boleh dipakai: `{{ .ConfirmationURL }}`, `{{ .Email }}`,
`{{ .SiteURL }}`, `{{ .Token }}`.

Untuk melihat hasilnya sebelum dipasang, salin berkasnya, ganti
`{{ .ConfirmationURL }}` dengan alamat apa saja, lalu buka di peramban.

## Yang tetap harus benar

Ganti SMTP tidak memperbaiki tujuan tautannya. Dua hal ini tetap perlu:

- `NEXT_PUBLIC_SITE_URL` di Vercel ditulis lengkap dengan `https://`
- Alamat yang sama terdaftar di **Authentication → URL Configuration →
  Redirect URLs**, misalnya `https://career-path-two-alpha.vercel.app/**`

Kalau tidak, tautan verifikasi mendarat di domain Supabase dan menjawab
`requested path is invalid` (lihat commit `021b7ee`).
