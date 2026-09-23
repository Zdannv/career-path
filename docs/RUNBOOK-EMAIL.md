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

Di penyedia, buka menu SMTP lalu buat kredensial. Yang dibutuhkan:

- Host, misalnya `smtp.resend.com` atau `smtp-relay.brevo.com`
- Port `587` (STARTTLS) — pakai ini, bukan 25
- Username dan password

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
address / Follow the link below…" — persis seperti yang masuk ke inbox
sekarang. Di bawah ini gantinya dalam bahasa Indonesia.

Variabel yang tersedia: `{{ .ConfirmationURL }}`, `{{ .Email }}`,
`{{ .SiteURL }}`, `{{ .Token }}`.

### Confirm signup

Subject: `Verifikasi email Navika kamu`

```html
<div style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0f172a">
  <p style="font-size:18px;font-weight:700;margin:0 0 4px">Navika</p>
  <p style="font-size:13px;color:#64748b;margin:0 0 28px">Career path journey</p>

  <h1 style="font-size:22px;line-height:1.3;margin:0 0 12px">Satu langkah lagi, ya</h1>
  <p style="font-size:15px;line-height:1.6;color:#475569;margin:0 0 24px">
    Tekan tombol di bawah untuk memastikan email ini benar milikmu. Setelah itu
    kamu bisa langsung mulai menyusun rencana kariermu.
  </p>

  <a href="{{ .ConfirmationURL }}"
     style="display:inline-block;background:#7033FF;color:#fff;text-decoration:none;font-size:15px;font-weight:600;padding:13px 28px;border-radius:999px">
    Verifikasi email
  </a>

  <p style="font-size:13px;line-height:1.6;color:#64748b;margin:28px 0 0">
    Tautan ini berlaku 24 jam. Kalau tombolnya tidak bisa ditekan, salin alamat
    ini ke peramban:<br>
    <span style="color:#7033FF;word-break:break-all">{{ .ConfirmationURL }}</span>
  </p>
  <p style="font-size:13px;line-height:1.6;color:#94a3b8;margin:20px 0 0">
    Bukan kamu yang mendaftar? Abaikan saja email ini, tidak ada akun yang dibuat.
  </p>
</div>
```

### Reset password

Subject: `Atur ulang kata sandi Navika`

```html
<div style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0f172a">
  <p style="font-size:18px;font-weight:700;margin:0 0 4px">Navika</p>
  <p style="font-size:13px;color:#64748b;margin:0 0 28px">Career path journey</p>

  <h1 style="font-size:22px;line-height:1.3;margin:0 0 12px">Atur ulang kata sandimu</h1>
  <p style="font-size:15px;line-height:1.6;color:#475569;margin:0 0 24px">
    Kami menerima permintaan mengganti kata sandi untuk {{ .Email }}. Tekan
    tombol di bawah untuk membuat yang baru.
  </p>

  <a href="{{ .ConfirmationURL }}"
     style="display:inline-block;background:#7033FF;color:#fff;text-decoration:none;font-size:15px;font-weight:600;padding:13px 28px;border-radius:999px">
    Buat kata sandi baru
  </a>

  <p style="font-size:13px;line-height:1.6;color:#94a3b8;margin:28px 0 0">
    Bukan kamu yang meminta? Abaikan email ini — kata sandimu tidak berubah
    sampai tautan di atas dibuka.
  </p>
</div>
```

## Yang tetap harus benar

Ganti SMTP tidak memperbaiki tujuan tautannya. Dua hal ini tetap perlu:

- `NEXT_PUBLIC_SITE_URL` di Vercel ditulis lengkap dengan `https://`
- Alamat yang sama terdaftar di **Authentication → URL Configuration →
  Redirect URLs**, misalnya `https://career-path-two-alpha.vercel.app/**`

Kalau tidak, tautan verifikasi mendarat di domain Supabase dan menjawab
`requested path is invalid` (lihat commit `021b7ee`).
