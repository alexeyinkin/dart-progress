N one<N extends num>() {
  if (N == double) {
    return 1.0 as N;
  }

  if (N == int) {
    return 1 as N;
  }

  throw Exception('Unexpected number type: $N');
}

N zero<N extends num>() {
  if (N == double) {
    return 0.0 as N;
  }

  if (N == int) {
    return 0 as N;
  }

  throw Exception('Unexpected number type: $N');
}

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
