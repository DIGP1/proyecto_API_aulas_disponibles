class ReportCategory {
  final String value;
  final String label;
  final String descripcion;

  ReportCategory({
    required this.value,
    required this.label,
    required this.descripcion,
  });

  factory ReportCategory.fromJson(Map<String, dynamic> json) {
    return ReportCategory(
      value: json['value'],
      label: json['label'],
      descripcion: json['descripcion'],
    );
  }
}