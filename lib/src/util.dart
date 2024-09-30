/// Returns 1 or 1.0 depending on [N].
N one<N extends num>() {
  if (N == double) {
    return 1.0 as N;
  }

  if (N == int) {
    return 1 as N;
  }

  throw Exception('Unexpected number type: $N');
}

/// Returns 0 or 0.0 depending on [N].
N zero<N extends num>() {
  if (N == double) {
    return 0.0 as N;
  }

  if (N == int) {
    return 0 as N;
  }

  throw Exception('Unexpected number type: $N');
}

/// Returns the sum of [numbers] or `null` if any of them is `null`.
N? sumOrNull<N extends num>(Iterable<N?> numbers) {
  N result = zero<N>();

  for (final number in numbers) {
    if (number == null) {
      return null;
    }
    result = (result + number) as N;
  }

  return result;
}
