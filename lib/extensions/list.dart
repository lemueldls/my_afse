extension MaybeList<E> on List<E> {
  // bool some(bool test(int index, E element)) {
  //   int index = 0;

  //   return this.any((element) => test(index++, element));
  // }

  E? tryGet(int index) => asMap().containsKey(index) ? this[index] : null;
}
