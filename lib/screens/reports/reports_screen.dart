import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_pie_chart_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_summary_card.dart';
import '../../widgets/spending_bar_chart_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    if (expenseProvider.expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: EmptyState(
          icon: Icons.trending_up_outlined,
          title: 'No expense data yet',
          message: 'Start adding expenses to see charts and analytics',
        ),
      );
    }

    final totalToday = expenseProvider.totalToday;
    final totalThisMonth = expenseProvider.totalThisMonth;
    final expenseCount = expenseProvider.expenseCountThisMonth;
    final topCategoryId = expenseProvider.topCategoryId;
    final topCategory = topCategoryId != null
        ? categoryProvider.getById(topCategoryId)
        : null;
    final topCategoryName = topCategory?.name ?? 'N/A';

    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 600 ? (width - 48) / 3 : (width - 40) / 2 - 6;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF040A16), Color(0xFF0B1430), Color(0xFF0F1D3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: const AssetImage('assets/icon.png'),
              fit: BoxFit.none,
              alignment: const Alignment(1.25, -1.25),
              opacity: 0.03,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.2),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AnimatedReveal(
                  delayMs: 40,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: 120,
                        child: ReportSummaryCard(
                          label: 'Today',
                          value: CurrencyUtils.format(totalToday),
                          backgroundColor: const Color(0xFF1E2F52),
                          textColor: const Color(0xFF9BC6FF),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        height: 120,
                        child: ReportSummaryCard(
                          label: 'This Month',
                          value: CurrencyUtils.format(totalThisMonth),
                          backgroundColor: const Color(0xFF1D3A45),
                          textColor: const Color(0xFF83F2D1),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        height: 120,
                        child: ReportSummaryCard(
                          label: 'Expenses',
                          value: expenseCount.toString(),
                          backgroundColor: const Color(0xFF2A254D),
                          textColor: const Color(0xFFC0B6FF),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        height: 120,
                        child: ReportSummaryCard(
                          label: 'Top Category',
                          value: topCategoryName,
                          backgroundColor: const Color(0xFF41342A),
                          textColor: const Color(0xFFFFD29A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedReveal(
                  delayMs: 140,
                  child: SpendingBarChartCard(expenseProvider: expenseProvider),
                ),
                const SizedBox(height: 16),
                _AnimatedReveal(
                  delayMs: 260,
                  child: CategoryPieChartCard(
                    expenseProvider: expenseProvider,
                    categoryProvider: categoryProvider,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedReveal extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedReveal({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700 + delayMs),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value.clamp(0, 1), child: animatedChild),
        );
      },
      child: child,
    );
  }
}
