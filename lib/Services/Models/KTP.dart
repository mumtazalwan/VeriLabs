class KTP {
  final String? nik;
  final String? nama;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? alamat;
  final String? rt;
  final String? rw;
  final String? kelurahan;
  final String? kecamatan;
  final String? kotaKabupaten;
  final String? provinsi;
  final String? agama;
  final String? statusPerkawinan;
  final String? pekerjaan;
  final String? kewarganegaraan;
  final String? masaBerlaku;
  final int? finalTrustScore;
  final String? decision;
  final List<String>? reason;

  KTP({
    this.nik,
    this.nama,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamat,
    this.rt,
    this.rw,
    this.kelurahan,
    this.kecamatan,
    this.kotaKabupaten,
    this.provinsi,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
    this.kewarganegaraan,
    this.masaBerlaku,
    this.finalTrustScore,
    this.decision,
    this.reason,
  });

  factory KTP.fromJson(Map<String, dynamic> json) {
    return KTP(
      nik: json['nik'],
      nama: json['nama'],
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      jenisKelamin: json['jenis_kelamin'],
      alamat: json['alamat'],
      rt: json['rt'],
      rw: json['rw'],
      kelurahan: json['kelurahan'],
      kecamatan: json['kecamatan'],
      kotaKabupaten: json['kota_kabupaten'],
      provinsi: json['provinsi'],
      agama: json['agama'],
      statusPerkawinan: json['status_perkawinan'],
      pekerjaan: json['pekerjaan'],
      kewarganegaraan: json['kewarganegaraan'],
      masaBerlaku: json['masa_berlaku'],
      finalTrustScore: json['final_trust_score'],
      decision: json['decision'],
      reason: json['reason'] != null ? List<String>.from(json['reason']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'rt': rt,
      'rw': rw,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'kota_kabupaten': kotaKabupaten,
      'provinsi': provinsi,
      'agama': agama,
      'status_perkawinan': statusPerkawinan,
      'pekerjaan': pekerjaan,
      'kewarganegaraan': kewarganegaraan,
      'masa_berlaku': masaBerlaku,
      'final_trust_score': finalTrustScore,
      'decision': decision,
      'reason': reason,
    };
  }
}
