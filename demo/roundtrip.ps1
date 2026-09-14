param(
    [string]$RestUrl = "http://127.0.0.1:8000",
    [string]$GraphqlUrl = "http://127.0.0.1:4000/graphql",
    [string]$Nim = "M0000001"
)

$restCount = 0

# 1) profil mahasiswa
Invoke-RestMethod -Uri "$RestUrl/api/mahasiswa/$Nim" | Out-Null
$restCount++

# 2) daftar KRS
$krs = Invoke-RestMethod -Uri "$RestUrl/api/mahasiswa/$Nim/krs"
$restCount++

# 3) nilai + presensi untuk tiap KRS (N request)
foreach ($k in $krs) {
    Invoke-RestMethod -Uri "$RestUrl/api/krs/$($k.krs_id)/hasil" | Out-Null
    $restCount++
}

# GraphQL: satu query untuk data setara
$query = @'
query Demo($nim: String!) {
  mahasiswaByNim(nim: $nim) {
    nim
    namaMahasiswa
    krsByMahasiswaId { nodes { krsId nilaiAkhirByKrsId { nilaiAngka nilaiHuruf } } }
  }
}
'@
$body = @{ query = $query; variables = @{ nim = $Nim } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri $GraphqlUrl -Method Post -ContentType "application/json" -Body $body | Out-Null
$gqlCount = 1

Write-Host "NIM             : $Nim"
Write-Host "REST requests   : $restCount (1 profil + 1 KRS + $($krs.Count) nilai)"
Write-Host "GraphQL request : $gqlCount (1 query)"
