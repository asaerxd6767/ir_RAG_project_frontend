import 'package:material_ui/material_ui.dart';

class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key});

  static double of(BuildContext context, {double minimum = 16}) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    return viewPadding > minimum ? viewPadding : minimum;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: of(context));
  }
}
