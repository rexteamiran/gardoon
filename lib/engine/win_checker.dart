/// ارزیابی شرط‌های برد — طبق architecture.md بخش ۳.۴
///
/// بعد از هر مرگ (شب یا روز) همه شرط‌ها ارزیابی می‌شوند؛
/// چند تیم می‌توانند هم‌زمان شرط بردشان را داشته باشند.
library;

import 'models/scenario.dart';
import 'models/session.dart';

class WinChecker {
  const WinChecker();

  /// همه شرط‌های برد را ارزیابی می‌کند؛ id تیم‌های برنده را برمی‌گرداند.
  List<String> evaluate(GameSessionState state) {
    final winners = <String>[];
    for (final wc in state.scenario.winConditions) {
      if (_conditionMet(state, wc)) {
        if (!winners.contains(wc.team)) winners.add(wc.team);
      }
    }
    return winners;
  }

  bool _conditionMet(GameSessionState state, GrdnWinCondition wc) {
    if (wc.terms.isEmpty) return false;
    final results = wc.terms.map((t) => _termMet(state, t)).toList();
    return wc.join.toUpperCase() == 'OR'
        ? results.any((r) => r)
        : results.every((r) => r);
  }

  bool _termMet(GameSessionState state, GrdnTerm term) {
    final left = _operand(state, term.left);
    final right = _operand(state, term.right);
    if (left == null || right == null) return false;

    switch (term.op) {
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '>':
        return left > right;
      case '<':
        return left < right;
      case '>=':
        return left >= right;
      case '<=':
        return left <= right;
      default:
        return false;
    }
  }

  /// عملوندهای مجاز: aliveCount:تیم • aliveCount:role:نقش • aliveTotal • round • عدد
  int? _operand(GameSessionState state, String raw) {
    final v = raw.trim();
    if (v == 'round') return state.roundNumber;
    if (v == 'aliveTotal') return state.aliveTotal;
    if (v.startsWith('aliveCount:role:')) {
      return state.aliveCountOfRole(v.substring('aliveCount:role:'.length));
    }
    if (v.startsWith('aliveCount:')) {
      return state.aliveCountOfTeam(v.substring('aliveCount:'.length));
    }
    return int.tryParse(v);
  }
}
