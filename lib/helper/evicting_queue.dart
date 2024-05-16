import 'dart:collection';

// Thanks to
// https://www.reddit.com/r/dartlang/comments/lowur2/sizelimited_queue_that_holds_last_n_elements/
class EvictingQueue<E> extends DoubleLinkedQueue<E> {
  int limit;

  EvictingQueue(this.limit);

  @override
  void add(E value) {
    super.add(value);
    while (super.length > limit) {
      super.removeFirst();
    }
  }
}
