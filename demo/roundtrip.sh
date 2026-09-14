#!/usr/bin/env bash
set -euo pipefail

REST_URL="${REST_URL:-http://127.0.0.1:8000}"
GRAPHQL_URL="${GRAPHQL_URL:-http://127.0.0.1:4000/graphql}"
NIM="${NIM:-M0000001}"

rest_count=0

# 1) profil mahasiswa
curl -s "$REST_URL/api/mahasiswa/$NIM" >/dev/null
rest_count=$((rest_count + 1))

# 2) daftar KRS
krs_json="$(curl -s "$REST_URL/api/mahasiswa/$NIM/krs")"
rest_count=$((rest_count + 1))

krs_count="$(printf '%s' "$krs_json" | grep -o '"krs_id":[0-9]*' | wc -l | tr -d ' ')"
krs_ids="$(printf '%s' "$krs_json" | grep -o '"krs_id":[0-9]*' | grep -o '[0-9]*' || true)"

# 3) nilai + presensi untuk tiap KRS (N request)
for id in $krs_ids; do
    curl -s "$REST_URL/api/krs/$id/hasil" >/dev/null
    rest_count=$((rest_count + 1))
done

# GraphQL: satu query untuk data setara
query='query Demo($nim: String!) { mahasiswaByNim(nim: $nim) { nim namaMahasiswa krsByMahasiswaId { nodes { krsId nilaiAkhirByKrsId { nilaiAngka nilaiHuruf } } } } }'
curl -s "$GRAPHQL_URL" -H 'content-type: application/json' \
    --data "{\"query\":\"$query\",\"variables\":{\"nim\":\"$NIM\"}}" >/dev/null
gql_count=1

echo "NIM             : $NIM"
echo "REST requests   : $rest_count (1 profil + 1 KRS + $krs_count nilai)"
echo "GraphQL request : $gql_count (1 query)"
