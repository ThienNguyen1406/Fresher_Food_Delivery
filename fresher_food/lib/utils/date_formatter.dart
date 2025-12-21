/// Utility class để format ngày tháng
class DateFormatter {
  /// Format DateTime thành chuỗi dd/MM/yyyy
  /// 
  /// Ví dụ: DateTime(2024, 1, 15) -> "15/01/2024"
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format DateTime thành chuỗi dd/MM/yyyy HH:mm
  /// 
  /// Ví dụ: DateTime(2024, 1, 15, 14, 30) -> "15/01/2024 14:30"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime thành chuỗi với format tùy chỉnh
  /// 
  /// Ví dụ: formatCustom(date, 'dd-MM-yyyy') -> "15-01-2024"
  static String formatCustom(DateTime date, String format) {
    String result = format;
    result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    result = result.replaceAll('yyyy', date.year.toString());
    result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));
    return result;
  }
}
