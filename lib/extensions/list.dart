extension MaybeList<E> on List<E> {
  /// A null safe `get`.
  E? tryGet(final int index) => asMap().containsKey(index) ? this[index] : null;
}
