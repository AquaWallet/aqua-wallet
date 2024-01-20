abstract class FocusAction {
  const FocusAction._();

  factory FocusAction.next() = FocusActionNext;
  factory FocusAction.clear() = FocusActionClear;
}

class FocusActionNext extends FocusAction {
  const FocusActionNext() : super._();
}

class FocusActionClear extends FocusAction {
  const FocusActionClear() : super._();
}
