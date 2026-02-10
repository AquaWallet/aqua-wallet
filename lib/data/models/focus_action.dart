abstract class FocusAction {
  const FocusAction._();

  factory FocusAction.next() = FocusActionNext;
  factory FocusAction.nextPage() = FocusActionNextPage;
  factory FocusAction.clear() = FocusActionClear;
}

class FocusActionNext extends FocusAction {
  const FocusActionNext() : super._();
}

class FocusActionNextPage extends FocusAction {
  const FocusActionNextPage() : super._();
}

class FocusActionClear extends FocusAction {
  const FocusActionClear() : super._();
}
