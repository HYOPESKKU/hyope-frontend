import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../utils/adherence_utils.dart';
import '../utils/date_utils.dart';
import 'common_widgets.dart';

class AdherenceCalendarCard extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final DailyAssessment? selectedAssessment;
  final List<DailyAssessment> assessments;
  final bool showStats;
  final VoidCallback onToggleStats;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const AdherenceCalendarCard({
    super.key,
    required this.selectedMonth,
    required this.selectedDate,
    required this.selectedAssessment,
    required this.assessments,
    required this.showStats,
    required this.onToggleStats,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final stats = calculateMonthlyAdherenceStats(assessments, selectedMonth);

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle(title: '복약·식사 캘린더')),
              TextButton.icon(
                onPressed: onToggleStats,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F80FF),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  showStats ? Icons.calendar_month_outlined : Icons.bar_chart_rounded,
                  size: 18,
                ),
                label: Text(
                  showStats ? '캘린더' : '통계 보기',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${selectedMonth.year}.${selectedMonth.month.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              IconButton(
                onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showStats
                ? AdherenceStatsPanel(
                    key: const ValueKey('adherence-stats-open'),
                    stats: stats,
                  )
                : Column(
                    key: const ValueKey('adherence-calendar-open'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: ['일', '월', '화', '수', '목', '금', '토']
                            .map(
                              (day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      color: Color(0xFF8A92A6),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: List.generate(rowCount, (row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: List.generate(7, (col) {
                                final index = row * 7 + col;
                                final dayNumber = index - leadingEmptyCells + 1;
                                if (dayNumber < 1 || dayNumber > daysInMonth) {
                                  return const Expanded(child: SizedBox(height: 50));
                                }

                                final date = DateTime(selectedMonth.year, selectedMonth.month, dayNumber);
                                final assessment = findAssessmentByDate(assessments, date);
                                final isSelected = selectedDate != null && isSameDay(date, selectedDate!);
                                final mealStatus = aggregateAdherence(assessment, AdherenceType.meal);
                                final medStatus = aggregateAdherence(assessment, AdherenceType.medication);

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => onDateSelected(date),
                                    child: DayAdherenceCell(
                                      date: date,
                                      isSelected: isSelected,
                                      mealStatus: mealStatus,
                                      medicationStatus: medStatus,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: const [
                          StatusLegend(label: '완료', color: Color(0xFF2FB86E)),
                          StatusLegend(label: '일부 완료', color: Color(0xFFE5A900)),
                          StatusLegend(label: '미완료', color: Color(0xFFE74747)),
                          StatusLegend(label: '미확인', color: Color(0xFF9AA2B4)),
                        ],
                      ),
                    ],
                  ),
          ),
          if (!showStats && selectedDate == null) ...[
            const SizedBox(height: 10),
            const Text(
              '날짜를 선택하면 아침·점심·저녁 복약/식사 이행 상세가 표시됩니다.',
              style: TextStyle(
                color: Color(0xFF8A92A6),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (!showStats) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE8ECF5), height: 1),
            const SizedBox(height: 14),
            SelectedDateAdherenceSection(
              date: selectedDate!,
              assessment: selectedAssessment,
            ),
          ],
        ],
      ),
    );
  }
}

class AdherenceStatsPanel extends StatelessWidget {
  final AdherenceStats stats;

  const AdherenceStatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F80FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4F80FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '월간 이행률 통계',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '기록 ${stats.recordedDays}일 기준 · 미기록 ${stats.noRecordDays}일',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A92A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final useVertical = constraints.maxWidth < 330;
              final mealCard = AdherenceRateCard(
                title: '식사 이행률',
                rate: stats.mealRate,
                doneCount: stats.mealDoneCount,
                totalCount: stats.mealNeededCount,
                missedCount: stats.mealMissedCount,
                icon: Icons.restaurant_outlined,
                color: const Color(0xFF2FB86E),
              );
              final medicationCard = AdherenceRateCard(
                title: '복약 이행률',
                rate: stats.medicationRate,
                doneCount: stats.medicationDoneCount,
                totalCount: stats.medicationNeededCount,
                missedCount: stats.medicationMissedCount,
                icon: Icons.medication_outlined,
                color: const Color(0xFF4F80FF),
              );

              if (useVertical) {
                return Column(
                  children: [
                    mealCard,
                    const SizedBox(height: 10),
                    medicationCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: mealCard),
                  const SizedBox(width: 10),
                  Expanded(child: medicationCard),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SimpleStatsText(
                    label: '전체 이행률',
                    value: '${stats.overallRate.round()}%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SimpleStatsText(
                    label: '총 미완료',
                    value: '${stats.totalMissedCount}회',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stats.comment,
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.35,
              color: Color(0xFF687085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AdherenceRateCard extends StatelessWidget {
  final String title;
  final double rate;
  final int doneCount;
  final int totalCount;
  final int missedCount;
  final IconData icon;
  final Color color;

  const AdherenceRateCard({
    super.key,
    required this.title,
    required this.rate,
    required this.doneCount,
    required this.totalCount,
    required this.missedCount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (rate / 100).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF333B4F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${rate.round()}%',
                style: TextStyle(
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '$doneCount/$totalCount회 완료',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.8,
                      color: Color(0xFF8A92A6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            missedCount == 0 ? '누락 없음' : '미완료 $missedCount회',
            style: const TextStyle(
              fontSize: 10.8,
              color: Color(0xFF9AA2B4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DayAdherenceCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final AdherenceAggregate mealStatus;
  final AdherenceAggregate medicationStatus;

  const DayAdherenceCell({
    super.key,
    required this.date,
    required this.isSelected,
    required this.mealStatus,
    required this.medicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F80FF).withOpacity(0.10) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF4F80FF) : const Color(0xFFE8ECF5),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSelected ? const Color(0xFF4F80FF) : const Color(0xFF3A4256),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _TinyStatusChip(label: '식', status: mealStatus),
              const SizedBox(width: 3),
              _TinyStatusChip(label: '약', status: medicationStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class SelectedDateAdherenceSection extends StatelessWidget {
  final DateTime date;
  final DailyAssessment? assessment;

  const SelectedDateAdherenceSection({
    super.key,
    required this.date,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: '${formatDate(date)} 이행 상세'),
        const SizedBox(height: 14),
        if (assessment == null)
          const Text(
            '해당 날짜의 통화 분석 기록이 없습니다.',
            style: TextStyle(color: Color(0xFF8A92A6)),
          )
        else
          Column(
            children: Slot.values.map((slot) {
              final meal = findAdherence(assessment!, AdherenceType.meal, slot);
              final medication = findAdherence(assessment!, AdherenceType.medication, slot);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8ECF5)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          slot.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF333B4F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdherenceStatusTile(label: '식사', record: meal),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdherenceStatusTile(label: '복약', record: medication),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class AdherenceStatusTile extends StatelessWidget {
  final String label;
  final AdherenceRecord? record;

  const AdherenceStatusTile({super.key, required this.label, required this.record});

  @override
  Widget build(BuildContext context) {
    final status = statusFromRecord(record);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 18, color: status.color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label ${status.label}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: status.color,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusLegend extends StatelessWidget {
  final String label;
  final Color color;

  const StatusLegend({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A8294), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SimpleStatsText extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatsText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A92A6),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF182033),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TinyStatusChip extends StatelessWidget {
  final String label;
  final AdherenceAggregate status;

  const _TinyStatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 17,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: status.aggregateColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w900,
            color: status.aggregateColor,
          ),
        ),
      ),
    );
  }
}
