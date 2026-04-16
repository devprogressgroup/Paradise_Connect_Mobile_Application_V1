String parseError(dynamic errors) {
  if (errors is Map) {
    return errors.values
        .expand((e) => e)
        .map((e) => e.toString())
        .join('\n');
  }
  return errors?.toString() ?? 'Terjadi kesalahan';
}