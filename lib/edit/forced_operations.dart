import 'package:pictus/photo_edit_tool.dart';

class ForcedOperations {
  final List<PhotoEditTool> operationsInOrder;
  final bool showPreviewAfterOperations;

  ForcedOperations({
    required this.operationsInOrder,
    required this.showPreviewAfterOperations,
  });
}
