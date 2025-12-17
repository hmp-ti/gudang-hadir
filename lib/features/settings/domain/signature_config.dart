class SignatureConfig {
  final String signerName;
  final String? signatureFileId;
  final String? stampFileId;

  SignatureConfig({required this.signerName, this.signatureFileId, this.stampFileId});

  factory SignatureConfig.fromJson(Map<String, dynamic> json) {
    return SignatureConfig(
      signerName: json['signerName'] ?? '',
      signatureFileId: json['signatureFileId'],
      stampFileId: json['stampFileId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'signerName': signerName, 'signatureFileId': signatureFileId, 'stampFileId': stampFileId};
  }
}
