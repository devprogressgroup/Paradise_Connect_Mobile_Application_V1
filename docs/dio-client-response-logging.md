# Dio Client — Response Logging Menampilkan Path Asli

**Tanggal:** 2026-08-05
**Area:** `core/network` (Dio interceptor)

## Masalah
Semua request (kecuali file download & yang pakai `skipEncryption`) dienkripsi dan dikirim sebagai `POST /px`. Akibatnya log debug response (`[RES Des ...]` / `[RES ERR ...]`) selalu menampilkan path `/px`, bukan endpoint aslinya (misal `/sales/channels-summary`) — menyulitkan saat mau lihat response dari endpoint tertentu di console.

## Perubahan
Path & method asli disimpan ke `options.extra` sebelum di-mutate ke `/px`, lalu dipakai lagi saat logging response/error supaya label log sesuai endpoint sebenarnya.

- [lib/core/network/dio_client.dart:158-159](../lib/core/network/dio_client.dart#L158-L159) — simpan `originalMethod`/`originalPath` ke `options.extra` sebelum path diganti ke `/px`
- [lib/core/network/dio_client.dart:181-184](../lib/core/network/dio_client.dart#L181-L184) — log response (`[RES Des ...]`) pakai `originalPath`
- [lib/core/network/dio_client.dart:204-207](../lib/core/network/dio_client.dart#L204-L207) — log error (`[RES ERR ...]`) pakai `originalPath`

## Hasil
Log debug sekarang tampil seperti:
```
[RES Des 200] /sales/channels-summary => {...}
```
bukan lagi `[RES Des 200] /px => {...}`.
