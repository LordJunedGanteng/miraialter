# PRD — Mirai Atelier Hub: Landing Page

**Version:** 1.0  
**Date:** 2026-04-19  
**Author:** Mirai Atelier Team  
**Status:** Ready for Implementation

---

## 1. Overview

### 1.1 Purpose
Halaman landing page publik untuk Mirai Atelier Hub — sebuah internal creative project management platform untuk tim game development Mirai Atelier. Landing page ini adalah pintu masuk utama yang memperkenalkan platform kepada anggota tim baru dan pengunjung, serta menyediakan akses langsung ke login dashboard.

### 1.2 Goals
- Menampilkan identitas profesional Mirai Atelier sebagai studio game development
- Memperkenalkan fitur-fitur utama Mirai Atelier Hub secara singkat dan menarik
- Mengarahkan anggota tim ke halaman login (`login.html`) via tombol **Team Login**
- Mempertahankan konsistensi visual dengan Noir Atelier design system yang digunakan di dashboard

### 1.3 Out of Scope
- Registrasi publik (akun dibuat via `login.html`, role ditentukan oleh Admin)
- Konten marketing eksternal / SEO publik
- Halaman portofolio game yang detail

---

## 2. Design System — "Noir Atelier"

Ikuti design system yang sama dengan dashboard. Referensi penuh ada di `DESIGN.md`.

### 2.1 Color Tokens

| Token | Value | Penggunaan |
|---|---|---|
| `--bg` | `#111319` | Canvas utama (Level 0) |
| `--surf` | `#191c21` | Section background (Level 1) |
| `--card` | `#1d2025` | Card / work area (Level 2) |
| `--card2` | `#272a30` | Elevated card / hover (Level 3) |
| `--gold` | `#e8b84b` | Primary accent, CTA |
| `--gold-l` | `#ffd57e` | Gold highlight |
| `--t1` | `#e1e2e9` | Body text |
| `--t2` | `#d2c5b0` | Secondary text |
| `--t3` | `#9b8f7c` | Muted / label text |
| `--purple` | `#c5c0ff` | Feature accent |
| `--teal` | `#5ef3c5` | Success / milestone |
| `--pink` | `#ffb4ab` | Error / warning |

### 2.2 Typography — Inter Variable Font
- **Display (Hero title):** Weight 800–900, letter-spacing `-0.04em`
- **Section heading:** Weight 700, letter-spacing `-0.02em`
- **Body:** Weight 300, relaxed line-height `1.7`
- **Labels / Eyebrow:** Weight 700, ALL CAPS, `+0.1em` letter-spacing

### 2.3 No-Line Rule
Pisahkan section hanya dengan perubahan background color. Tidak ada `border` 1px solid sebagai divider section.

### 2.4 Glassmorphism
Panel mengambang: `background: rgba(29,32,37,0.80)` + `backdrop-filter: blur(20px)`

### 2.5 Primary CTA Gradient
```css
background: linear-gradient(135deg, #ffd57e 0%, #e8b84b 100%);
color: #111319;
```

### 2.6 Ambient Glow
Background accent blobs (non-interactive):
```css
/* Gold — pojok kanan atas */
width: 600px; height: 600px;
background: radial-gradient(circle, rgba(232,184,75,0.07) 0%, transparent 70%);
filter: blur(60px);

/* Purple — pojok kiri bawah */
background: radial-gradient(circle, rgba(197,192,255,0.05) 0%, transparent 70%);
```

---

## 3. Page Structure & Sections

```
┌─────────────────────────────────────────────────┐
│  NAVBAR (sticky, glass)                         │
├─────────────────────────────────────────────────┤
│  01 — HERO                                      │
│  Full viewport · Display title · CTA button     │
├─────────────────────────────────────────────────┤
│  02 — STATS BAR                                 │
│  3–4 angka kunci (members, tasks, divisi, dll)  │
├─────────────────────────────────────────────────┤
│  03 — FEATURES                                  │
│  Bento grid: 6 feature cards                    │
├─────────────────────────────────────────────────┤
│  04 — HOW IT WORKS                              │
│  3-step timeline horizontal                     │
├─────────────────────────────────────────────────┤
│  05 — DIVISIONS                                 │
│  Role/divisi cards yang ada di tim              │
├─────────────────────────────────────────────────┤
│  06 — CTA BANNER                                │
│  Fullwidth dark banner · "Team Login" button    │
├─────────────────────────────────────────────────┤
│  FOOTER                                         │
│  Logo · tagline · copyright                     │
└─────────────────────────────────────────────────┘
```

---

## 4. Section Specifications

### 4.1 Navbar (Sticky Glass)
**Background:** `rgba(17,19,25,0.0)` → `rgba(17,19,25,0.85) blur(20px)` saat scroll  
**Height:** 72px  
**Content:**
- Kiri: Logo mark `MIRAI` (text, gold, font-weight 900, tracking wide) + "Atelier Hub" (t2, weight 300)
- Kanan: Tombol `Team Login` — primary gradient, border-radius `10px`, height `40px`

**Behavior:** Transparan saat di top, glass panel setelah scroll 50px.

---

### 4.2 Section 01 — Hero
**Background:** `--bg` dengan 2 ambient glow blobs  
**Layout:** Full viewport height, centered content, max-width 800px  
**Komponen:**

```
[Eyebrow label]   MIRAI ATELIER · INTERNAL PLATFORM
[Display Title]   Platform Kolaborasi
                  Tim Game Development
[Subtitle]        Kelola task, pantau progress, dan koordinasi seluruh
                  divisi kreatif dalam satu workspace yang dirancang
                  khusus untuk studio game.
[CTA Button]      ▶ Team Login          [Ghost: Pelajari Lebih]
[Scroll hint]     ↓ scroll
```

**Typography:**
- Eyebrow: `0.6rem`, weight 700, ALL CAPS, `+0.1em`, color `--gold`
- Title: `4rem` (mobile: `2.5rem`), weight 900, tracking `-0.04em`, color `--t1`
- Keyword highlight: "Game Development" diberi warna `--gold`
- Subtitle: `1rem`, weight 300, color `--t2`, line-height 1.8, max-width 520px

**CTA Primary:** gradient gold, `56px` height, `14px` radius  
**CTA Ghost:** transparent, `rgba(78,70,54,0.3)` border, color `--t1`

---

### 4.3 Section 02 — Stats Bar
**Background:** `--surf`  
**Layout:** Horizontal flex / 4 kolom, padding `40px 0`  
**Pemisah antar stat:** Vertical divider `rgba(78,70,54,0.25)` (bukan border penuh)

| Stat | Label |
|---|---|
| `7+` | Divisi Kreatif |
| `100+` | Task Dikelola |
| `Real-time` | Sinkronisasi |
| `Supabase` | Powered By |

**Typography:** Angka `2.5rem` weight 800 gold, label `0.65rem` weight 700 UPPERCASE t3

---

### 4.4 Section 03 — Features (Bento Grid)
**Background:** `--bg`  
**Heading:**
```
[Eyebrow] FITUR UTAMA
[Title]   Semua yang dibutuhkan
          tim kreatif kamu
```

**Grid:** `3 kolom × 2 baris` desktop, `1 kolom` mobile  
**Card style:** `background: --surf`, `border-radius: 16px`, padding `28px`, hover → `background: --card`  
**Card anatomy:** Icon (Material Symbol, gold, 28px) → Label (eyebrow) → Title (weight 600) → Desc (weight 300, t2)

| # | Icon | Judul | Deskripsi |
|---|---|---|---|
| 1 | `assignment` | Task Management | Buat, assign, dan pantau task seluruh tim dari satu tempat. |
| 2 | `rate_review` | Review Queue | Admin review submission langsung dengan preview file dan feedback real-time. |
| 3 | `forum` | Real-time Chat | DM antar anggota tim dan thread diskusi per task terintegrasi. |
| 4 | `leaderboard` | Leaderboard & Poin | Sistem poin otomatis saat task disetujui — pantau performa tim. |
| 5 | `view_kanban` | Kanban Board | Visualisasi status task drag-and-drop untuk admin dan member. |
| 6 | `notifications` | Notifikasi Live | Push notifikasi instan saat task disetujui, direvisi, atau ada pesan baru. |

**Featured card (card #1 atau #2):** Ukuran 2× lebar (colspan 2), dengan ambient glow ungu di background.

---

### 4.5 Section 04 — How It Works
**Background:** `--surf`  
**Heading:**
```
[Eyebrow] ALUR KERJA
[Title]   Tiga langkah sederhana
```

**Layout:** 3 kolom horizontal, dihubungkan garis dashed gold  

| Step | Icon | Judul | Desc |
|---|---|---|---|
| 01 | `person_add` | Daftar & Tunggu Role | Buat akun dengan nama dan username. Admin akan assign role divisi kamu. |
| 02 | `task_alt` | Kerjakan Task | Terima task dari admin, kerjakan, lalu submit dengan catatan dan file. |
| 03 | `workspace_premium` | Dapatkan Poin | Setelah task disetujui, poin masuk otomatis. Climb the leaderboard. |

**Step number:** `0.6rem`, weight 900, gold, `+0.15em` tracking  
**Connector:** `border-top: 1px dashed rgba(232,184,75,0.2)` antara step

---

### 4.6 Section 05 — Divisions
**Background:** `--bg`  
**Heading:**
```
[Eyebrow] TIM KAMI
[Title]   Divisi yang membentuk
          Mirai Atelier
```

**Layout:** 3 kolom × 2 baris, gap `12px`  
**Card style:** `background: --surf`, border-radius `12px`, padding `20px 22px`, hover scale `1.02`  
**Card anatomy:** Badge pill (role color, subtle fill) → Name → Short desc

| Role | Badge Color | Deskripsi |
|---|---|---|
| Produser | Gold | Koordinasi keseluruhan proyek dan milestone |
| Director | Blue | Pengarah kreatif visual dan narasi game |
| Modeller | Teal | Pembuatan aset 3D karakter dan environment |
| Programmer | Purple | Logika game, sistem, dan integrasi engine |
| Animator | Pink | Gerak karakter, cutscene, dan rigging |
| UI Designer | Cyan | Interface game, HUD, dan user experience |

---

### 4.7 Section 06 — CTA Banner
**Background:** `linear-gradient(135deg, rgba(232,184,75,0.08), rgba(29,32,37,0.5))`  
**Border:** `1px solid rgba(232,184,75,0.15)` (ghost border rule)  
**Margin:** `60px auto`, max-width `900px`, border-radius `20px`  
**Padding:** `64px`

```
[Eyebrow]  SUDAH SIAP?
[Title]    Masuk ke workspace tim kamu
[Subtitle] Semua task, notifikasi, dan progress tim tersedia
           di satu dashboard. Login sekarang.
[Button]   ▶ Team Login
```

**Title:** `2.5rem`, weight 800, tracking `-0.03em`

---

### 4.8 Footer
**Background:** `--surf`  
**Layout:** 2 kolom (brand kiri, info kanan) + copyright bar bawah  

**Kiri:**
- `MIRAI` wordmark (gold, weight 900)
- Tagline: *"Where creativity ships."* (weight 300, t3)

**Kanan:**
- Link: `Team Login` → `login.html`
- Link: `Dashboard` → `dashboard.html` (untuk member yang sudah login)

**Copyright bar:** `border-top: 1px solid rgba(78,70,54,0.15)`, font-size `0.6875rem`, color t3  
```
© 2026 Mirai Atelier. Internal Platform.
```

---

## 5. Behavior & Interactions

### 5.1 Navbar Scroll Effect
```js
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 50);
});
// .scrolled → background: rgba(17,19,25,0.85); backdrop-filter: blur(20px);
```

### 5.2 Scroll Reveal Animation
Setiap section masuk ke viewport: `opacity: 0 → 1`, `translateY: 24px → 0`, duration `0.6s ease`.  
Gunakan `IntersectionObserver` — **tidak perlu library eksternal**.

```js
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('revealed');
      observer.unobserve(e.target);
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
```

```css
.reveal { opacity: 0; transform: translateY(24px); transition: opacity 0.6s ease, transform 0.6s ease; }
.reveal.revealed { opacity: 1; transform: translateY(0); }
```

### 5.3 Stat Counter Animation
Angka di Stats Bar dianimasikan dari `0` → nilai akhir dalam 1.2 detik saat section masuk viewport.  
Hanya untuk nilai numerik — skip untuk teks seperti "Real-time".

### 5.4 Team Login Button
Semua tombol "Team Login" di halaman → `window.location.href = 'login.html'`

---

## 6. Responsive Breakpoints

| Breakpoint | Layout Changes |
|---|---|
| `>= 1024px` | Layout penuh, bento 3 kolom, stats 4 kolom |
| `768–1023px` | Bento 2 kolom, stats 2×2 |
| `< 768px` | Semua single column, hero title 2.5rem, CTA full-width |

---

## 7. File & Assets

### 7.1 Output File
`D:\WebKucing\index.html` — overwrite file landing page yang ada.

### 7.2 External Dependencies
```html
<!-- Fonts -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">
```
Tidak ada framework CSS eksternal — murni custom CSS untuk konsistensi dengan dashboard.

### 7.3 No External Images
Semua visual menggunakan CSS: ambient glow blobs, gradient backgrounds, icon dari Material Symbols. **Tidak ada `<img>` dengan URL eksternal** kecuali logo (opsional).

---

## 8. Acceptance Criteria

- [ ] Halaman bisa dibuka langsung tanpa login (`index.html`)
- [ ] Tombol "Team Login" di navbar dan CTA banner mengarah ke `login.html`
- [ ] Semua 6 section tampil sesuai spesifikasi di atas
- [ ] Warna, font, dan spacing konsisten dengan Noir Atelier design system
- [ ] Tidak ada garis border solid sebagai section divider (No-Line Rule)
- [ ] Scroll reveal animation berjalan smooth di semua section
- [ ] Responsive: tampil dengan baik di mobile (< 768px)
- [ ] Navbar berubah menjadi glass panel setelah scroll 50px
- [ ] Tidak ada referensi ke role selector (role ditetapkan admin)

---

## 9. Registration Flow Update

### Sebelum (lama)
User memilih role saat registrasi → role tersimpan langsung di `profiles`

### Sesudah (baru)
1. User isi: Nama Lengkap, Username, Password
2. Akun dibuat dengan `role = null` (atau default ke `member`)
3. Info banner tampil: *"Role / divisi kamu akan ditentukan oleh Admin setelah akun dibuat."*
4. Admin assign role via **User Control** panel di `admin.html`

### DB Trigger (sudah ada)
Pastikan trigger `on_auth_user_created` di Supabase tidak set default role. Jika ada, hapus atau ubah ke `null`:
```sql
-- Pastikan trigger insert profiles tanpa hardcode role
INSERT INTO profiles (id, full_name, username, role)
VALUES (new.id,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'username',
        NULL);  -- ← role NULL, diisi admin nanti
```

---

*PRD ini siap dikirim ke Google Stitch untuk implementasi `index.html`.*
