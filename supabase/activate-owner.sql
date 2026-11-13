-- 1. Buat user lewat Supabase Authentication > Users > Add user (email dan password Owner).
--    Atau gunakan identitas Auth yang sudah ada; tidak perlu profil admin aplikasi lain.
-- 2. Ganti email berikut lalu jalankan di SQL Editor. Tidak ada pendaftaran publik Owner.
do $$declare selected_id uuid;begin
 select id into selected_id from auth.users where lower(email)=lower('GANTI_EMAIL_OWNER_DI_SINI');
 if selected_id is null then raise exception 'Email belum ditemukan di Authentication > Users.';end if;
 if exists(select 1 from public.owner_profiles) then raise exception 'Owner sudah terpasang. Untuk transfer akses, ubah user_id pada baris singleton lewat SQL Editor secara sengaja.';end if;
 insert into public.owner_profiles(user_id,name) values(selected_id,'Owner Adsy');
end$$;
