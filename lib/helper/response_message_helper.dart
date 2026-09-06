import 'dart:convert';

class ResponseMessageHelper {
  static String? extractFromResponse(dynamic response, {String? fallback}) {
    if (response == null) {
      return _clean(fallback);
    }

    String? responseFallback = fallback;
    dynamic body;

    try {
      responseFallback ??= response.statusText as String?;
    } catch (_) {}

    try {
      body = response.body;
    } catch (_) {}

    return extractFromBody(body, fallback: responseFallback);
  }

  static String? extractFromBody(dynamic body, {String? fallback}) {
    return _read(body) ?? _clean(fallback);
  }

  static String? _read(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final String? cleaned = _clean(value);
      if (cleaned == null) {
        return null;
      }

      if (cleaned.startsWith('{') || cleaned.startsWith('[')) {
        try {
          return _read(jsonDecode(cleaned));
        } catch (_) {}
      }

      return cleaned;
    }

    if (value is Map) {
      for (final String key in const [
        'message',
        'error_message',
        'error',
        'msg',
        'detail',
      ]) {
        final String? message = _read(value[key]);
        if (message != null) {
          return message;
        }
      }

      final String? validationMessage = _readErrors(value['errors']);
      if (validationMessage != null) {
        return validationMessage;
      }

      return _read(value['data']);
    }

    if (value is Iterable) {
      for (final dynamic item in value) {
        final String? message = _read(item);
        if (message != null) {
          return message;
        }
      }
    }

    return null;
  }

  static String? _readErrors(dynamic errors) {
    if (errors == null) {
      return null;
    }

    if (errors is Map) {
      for (final dynamic entry in errors.entries) {
        final String? message = _read(entry.value);
        if (message != null) {
          return message;
        }
      }
      return null;
    }

    return _read(errors);
  }

  static String? _clean(String? value) {
    if (value == null) {
      return null;
    }

    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }

    return trimmed.replaceAll('_', ' ');
  }
}
