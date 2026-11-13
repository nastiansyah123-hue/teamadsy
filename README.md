# Adsy Command Center — Owner

Web terpisah khusus satu Owner untuk membaca Akuisisi, CRM dan Marketplace. Stack React + Vite, Supabase dan Vercel. Warna/logo mengikuti aplikasi Adsy. Semua angka pada versi tanpa env adalah **data simulasi**, bukan laporan bisnis yang tersambung.

## Fitur

- Ringkasan omzet gabungan, perbandingan periode, grafik harian, biaya tercatat, HPP dan kontribusi.
- Halaman Akuisisi (advertiser/CS), CRM (wilayah/anggota) dan Marketplace (platform/toko).
- Performa produk global, unit terjual dan bonus terpisah.
- Master SKU global dan mapping produk sumber dengan faktor konversi satuan.
- Riwayat HPP berdasarkan tanggal berlaku; HPP bonus dihitung walaupun omzet bonus Rp0.
- Target omzet per bulan/divisi/produk, pencapaian, proyeksi linier dan kebutuhan harian tersisa.
- Monitoring kandidat laporan/tanggal kosong dan kelengkapan sumber Shopee.
- Analisis berbasis angka, peringatan biaya naik/omzet turun, catatan Owner.
- Ekspor CSV (dapat dibuka di Excel), filter tanggal/divisi/produk.
- Sidebar dapat diciutkan, menu bawah pada ponsel, pagination tabel dan akses satu akun.

## Pemasangan Supabase yang sama

**Tidak perlu mengubah kode atau menambah kolom di aplikasi Akuisisi, CRM dan Marketplace.** Integrasi memakai tabel baru berawalan `owner_` serta RPC read-only. Tiga schema aplikasi sumber harus sudah ada di project Supabase yang sama. Owner membaca melalui RPC yang memeriksa profil Owner dan daftar tabel tetap; admin/tim aplikasi lama tidak mendapat akses Owner. Policy, trigger dan peran aplikasi lama tidak diubah.

1. Di Supabase SQL Editor, jalankan **`supabase/schema.sql` dari ZIP Owner ini satu kali**. Ini schema tambahan Owner, bukan schema salah satu aplikasi lama. Jangan ulang schema yang sudah terpasang.
2. Tentukan identitas Owner di Authentication → Users. Bisa pakai user Auth yang sudah ada, atau Add user baru dengan email terkonfirmasi dan password. Jangan isi metadata `account_role`, `app: crm_adsy` atau `app: marketplace_adsy` untuk akun Owner baru.
3. Buka `supabase/activate-owner.sql`, ganti `GANTI_EMAIL_OWNER_DI_SINI` dengan email Owner, lalu jalankan di SQL Editor. Tidak perlu mengubah nama/profil/peran aplikasi lain. Maksimal satu baris Owner; tidak ada pendaftaran atau aktivasi mandiri melalui web.
4. Login di web Owner. Bila sumber belum terpasang/versinya belum sesuai, tampil pesan sumber yang gagal; tidak diganti dengan demo atau dianggap nol.

Tabel baru: `owner_profiles`, `owner_products`, `owner_mappings`, `owner_hpp`, `owner_targets`, `owner_notes`. HPP hanya dapat ditambahkan melalui aplikasi, bukan ditimpa/dihapus. Bila salah input pada tanggal yang sudah ada, koreksi secara sengaja melalui SQL Editor setelah memeriksa dampaknya. Transfer akun Owner juga hanya melalui SQL Editor dengan memperbarui `owner_profiles.user_id`.

RPC `owner_read_source` hanya SELECT tabel sumber yang diizinkan, dengan pagination. Tidak memakai service-role key di frontend. Profil Owner terpisah; identitas Supabase Auth tetap menggunakan layanan Auth project yang sama. Penyimpanan sesi browser memakai key khusus Owner dan logout memakai scope lokal agar tidak mengeluarkan sesi aplikasi lain.

## GitHub dan Vercel

Upload seluruh isi folder `adsy-owner-command-center/` dalam ZIP ke root repository baru. Jangan upload folder node_modules, dist atau .env. Framework preset: **Vite**. Build: `npm run build`. Output: `dist`.

Env Vercel yang dibutuhkan hanya:

```text
VITE_SUPABASE_URL=https://PROJECT-YANG-SAMA.supabase.co
VITE_SUPABASE_ANON_KEY=PUBLIC_ANON_KEY_PROJECT_YANG_SAMA
```

Redeploy setelah mengisi env. Service role dan OpenAI API key tidak diperlukan. Atur Site URL/redirect Auth sesuai domain Owner jika memakai alur email Auth. Login utama menggunakan email/password yang dibuat di Authentication. Untuk pengembangan lokal, salin `.env.example` menjadi `.env.local`, isi kedua public env, lalu `npm ci` dan `npm run dev`.

Tanpa env, aplikasi memakai demo lokal yang jelas ditandai. Pengaturan demo disimpan di localStorage dan dapat di-reset. Saat env aktif, demo tidak dipakai sebagai fallback jika koneksi gagal. Web memuat ulang data saat login, tombol Perbarui, serta setiap 5 menit ketika tab terlihat; data sumber tetap tersimpan pada aplikasi asal. Pembacaan antar-divisi bukan snapshot transaksi atomik lintas aplikasi.

## Mulai mengisi SKU global dan HPP

1. Buat produk internal di **Master SKU Global → Produk global**, misalnya `ADSY-PRIMA`, nama Primagold, satuan box.
2. Di tab Mapping sumber, hubungkan produk Akuisisi, CRM dan Marketplace ke produk global tersebut.
3. Isi faktor konversi. Produk sumber yang sudah dalam unit fisik biasanya faktor **1**. SKU mentah `PRIMA 4` yang belum dikenali Marketplace dihitung sebagai paket; jika satu paket berisi 4 box, isi faktor **4**. Pastikan satuan benar. Produk CRM berbeda wilayah tetap dapat menuju SKU global yang sama.
4. Di **Riwayat HPP**, tentukan biaya per satu unit global dan tanggal mulai berlaku. Tanggal sebelum riwayat pertama ditandai belum lengkap. HPP Rp0 yang sengaja diisi dianggap valid, berbeda dengan belum diisi.
5. Tambahkan HPP tanggal baru jika berubah. Sistem memilih tanggal HPP paling akhir yang tidak melewati tanggal transaksi. HPP November tidak diganti otomatis oleh HPP Desember. Penambahan HPP bertanggal lampau sengaja menghitung ulang laporan Owner sejak tanggal itu.

Mapping dan faktor konversi Owner berlaku pada laporan historis Owner, tanpa mengganti SKU/harga/omzet sumber. Jangan mengubah faktor satuan tanpa memeriksa laporan historis. Produk global yang sudah dipakai mapping/HPP tidak dapat diganti satuannya melalui UI; gunakan produk global baru dan mapping yang sesuai bila satuan berubah.

## Aturan perhitungan

- **CRM adalah transaksi tersendiri**, sesuai konfirmasi Owner, sehingga omzetnya dijumlahkan dengan Akuisisi dan Marketplace. Aplikasi ini tidak melakukan pencocokan pelanggan atau deduplikasi transaksi lintas divisi. Jika kebijakan pencatatan berubah, aturan ini harus ditinjau.
- Akuisisi memakai revenue tersimpan, closing dikurangi invalid, unit dikurangi invalidUnits, dan biaya iklan budget termasuk tarif pajak snapshot.
- CRM memakai revenue/units/closing tersimpan, bukan harga master terbaru. Cross sales tetap memakai nominal yang disimpan sumber.
- Marketplace memakai item dengan status valid saja. Pesanan toko dihitung unik berdasarkan toko + nomor pesanan; satu pesanan berisi beberapa produk tetap satu pesanan dalam total toko/bisnis. Angka pesanan gabungan menggabungkan closing agregat Akuisisi/CRM dan nomor pesanan unik Marketplace, bukan jumlah pelanggan unik.
- SKU Marketplace bertanda `+` mengikuti aturan sumber: produk sebelum + mendapat seluruh omzet, setelah + adalah bonus Rp0. Quantity pesanan mengalikan unit utama/bonus. Bonus yang belum dikenali master Marketplace muncul sebagai sumber `sku:KODE` yang dapat dihubungkan khusus di Owner; isi konversi yang benar.
- HPP = seluruh unit terjual + bonus, setelah faktor konversi, dikali HPP yang berlaku pada tanggal transaksi. Produk/HPP/unit yang belum dapat dipastikan menyebabkan kontribusi ditandai **Belum lengkap**. Omzet sumber tetap disertakan. Kartu unit global hanya menghitung unit yang sudah dipetakan; total gabungan mempunyai beberapa satuan fisik.
- Biaya marketplace meliputi iklan + pajak, affiliate dan fee aktual bila tersedia; bila belum ada fee aktual, memakai estimasi tarif toko sesuai model sumber. Nilai 0 aktual dibedakan dari kosong. Perubahan tarif estimasi toko bisa mengubah estimasi historis yang belum diberi nilai aktual.
- **Kontribusi bukan laba bersih:** omzet − HPP − biaya yang tercatat. Belum mencakup gaji, ongkir, pajak usaha, retur/refund aktual yang belum direkonsiliasi dan biaya lain yang tidak tersedia dalam sumber. Retur parsial tidak dikurangkan otomatis dari omzet mengikuti perilaku Marketplace. Biaya dengan label estimasi tetap diberi penanda.
- Filter produk hanya memasukkan biaya iklan yang dipetakan langsung. Biaya bersama toko, affiliate dan fee tidak dialokasikan ke produk. Kontribusi per produk belum memuat biaya bersama.
- Target Owner terpisah dari target operasional pada aplikasi asal; target bertingkat tidak dijumlahkan karena dapat tumpang tindih. Proyeksi linier memakai omzet tercatat per hari kalender termasuk hari berjalan, bukan jaminan hasil.
- Monitoring adalah kandidat tanggal kosong sampai kemarin WIB berdasarkan akun/penugasan aktif saat ini. Bukan bukti tim terlambat, karena bisa hari libur atau masa sebelum toko/anggota aktif. Tidak ada upload bukan bukti penjualan nol. Filter produk tidak diterapkan pada kelengkapan.

## Analisis dan verifikasi

Analisis saat ini berbasis perhitungan dan aturan yang terlihat angkanya. **AI eksternal belum dihubungkan**; tidak ada pesan yang mengaku dibuat AI. Sumber yang gagal ditampilkan jelas dan metadata ekspor menyebut sumber yang belum lengkap.

```text
npm test
npm run test:db
npm run build
```

Tes model meliputi omzet sumber yang tetap, unit bonus/HPP, tanggal HPP, SKU belum terhubung, transaksi CRM tersendiri, periode pembanding dan CSV formula injection. Tes database meliputi akses satu Owner, penolakan akun biasa/anon, bootstrap terlindungi, allowlist sumber/injeksi SQL, HPP append-only, pencabutan Owner, dan permission sumber tidak berubah. Coexistence keempat schema Akuisisi + CRM + Marketplace + Owner juga telah diuji lokal terhadap schema aplikasi yang tersedia. Render server halaman dan form serta build produksi diperiksa. **Uji klik/tampilan browser belum dilakukan** karena tool browser/cua_repl tidak tersedia. Koneksi ke Supabase/Vercel milik pengguna belum dijalankan; perlu pemasangan SQL dan env di atas.
