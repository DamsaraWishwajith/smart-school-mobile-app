import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import '../models/meal_plan_model.dart';
import '../widgets/create_sheet_kit.dart';

const List<String> _kWeekDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _kWeekDays[DateTime.now().weekday - 1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadMealPlans();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<StudentProvider>(context, listen: false).loadMealPlans();
  }

  MealPlanModel? _recordFor(List<MealPlanModel> plans, String day) {
    for (final plan in plans) {
      if (plan.day.toLowerCase() == day.toLowerCase()) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0077BE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meal Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        centerTitle: true,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                final plans = Provider.of<StudentProvider>(context, listen: false).mealPlans;
                _showEditMealPlanSheet(_recordFor(plans, _selectedDay));
              },
              backgroundColor: kSheetAccentColor,
              icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
              label: const Text('Edit Meal Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildDayPills(),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<StudentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.mealPlans.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kSheetAccentColor)),
                    );
                  }

                  if (provider.error != null && provider.mealPlans.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                      ),
                    );
                  }

                  final record = _recordFor(provider.mealPlans, _selectedDay);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: kSheetAccentColor,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        Text(
                          _selectedDay,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record?.updatedAt != null
                              ? 'Updated ${_formatDate(record!.updatedAt!)}'
                              : 'No meal plan set for this day yet',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        _buildMealCard(icon: Icons.restaurant_menu_rounded, label: 'Meal', color: const Color(0xFFFF7043), value: record?.meal),
                        if (record?.notes != null && record!.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildNotesCard(record.notes!),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  Widget _buildDayPills() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kWeekDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _kWeekDays[index];
          final selected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? kSheetAccentColor : const Color(0xFFF5F8FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? kSheetAccentColor : Colors.black12),
              ),
              child: Text(
                day.substring(0, 3),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard({required IconData icon, required String label, required Color color, String? value}) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.4)),
                const SizedBox(height: 6),
                Text(
                  hasValue ? value : 'Not planned yet',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: hasValue ? Colors.black87 : Colors.black38,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notes, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          ),
        ],
      ),
    );
  }

  void _showEditMealPlanSheet(MealPlanModel? existing) {
    final mealController = TextEditingController(text: existing?.meal ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetDragHandle(),
                    sheetHeader(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Edit Meal Plan',
                      subtitle: 'Update the school menu for $_selectedDay',
                    ),
                    const SizedBox(height: 24),
                    sheetSectionLabel('Meal'),
                    TextField(
                      controller: mealController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: sheetFieldDecoration(
                        hint: 'e.g. Breakfast: Milk rice, dhal curry\nLunch: Rice, chicken curry, vegetables\nSnack: Biscuits, juice',
                        icon: Icons.restaurant_menu_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    sheetSectionLabel('Notes'),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: sheetFieldDecoration(hint: 'Allergy notes, special instructions...'),
                    ),
                    const SizedBox(height: 28),
                    sheetSubmitButton(
                      label: 'SAVE MEAL PLAN',
                      icon: Icons.save_rounded,
                      isLoading: isSaving,
                      onPressed: () async {
                        setModalState(() => isSaving = true);
                        final success = await Provider.of<StudentProvider>(context, listen: false).saveMealPlan({
                          'day': _selectedDay,
                          'meal': mealController.text.trim(),
                          'notes': notesController.text.trim(),
                        });
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Meal plan saved successfully!' : 'Failed to save meal plan'),
                              backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
