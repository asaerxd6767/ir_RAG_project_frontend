/// Payload returned by `GET /health`.
class HealthStatus {
  const HealthStatus({required this.isOk, this.detail});

  final bool isOk;
  final String? detail;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    final status = (json['status']?.toString() ?? '').trim().toLowerCase();
    final rawDetail = json['detail']?.toString().trim();
    return HealthStatus(
      isOk: status == 'ok',
      detail: rawDetail == null || rawDetail.isEmpty ? null : rawDetail,
    );
  }
}
