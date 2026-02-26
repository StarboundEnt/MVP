import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/models/habit_model.dart';

void main() {
  group('StarboundHabit', () {
    test('should create habit with correct properties', () {
      const habit = StarboundHabit(
        id: 'test-id',
        title: 'Test Habit',
        category: 'Health',
        habitType: HabitType.choice,
        isCompleted: false,
      );

      expect(habit.id, 'test-id');
      expect(habit.title, 'Test Habit');
      expect(habit.category, 'Health');
      expect(habit.habitType, HabitType.choice);
      expect(habit.isCompleted, false);
    });

    test('should convert to JSON correctly', () {
      const habit = StarboundHabit(
        id: 'test-id',
        title: 'Test Habit',
        category: 'Health',
        habitType: HabitType.choice,
        isCompleted: true,
      );

      final json = habit.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test Habit');
      expect(json['category'], 'Health');
      expect(json['habitType'], 'choice');
      expect(json['isCompleted'], true);
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Habit',
        'category': 'Health',
        'habitType': 'choice',
        'isCompleted': false,
        'completionDates': <String>[],
        'streak': 0,
        'lastCompleted': null,
        'description': null,
        'targetFrequency': null,
        'completionCount': 0,
        'totalGoal': null,
        'priority': 1,
        'tags': <String>[],
        'customData': <String, dynamic>{},
      };

      final habit = StarboundHabit.fromJson(json);

      expect(habit.id, 'test-id');
      expect(habit.title, 'Test Habit');
      expect(habit.category, 'Health');
      expect(habit.habitType, HabitType.choice);
      expect(habit.isCompleted, false);
    });

    test('should calculate streak correctly', () {
      final habit = StarboundHabit(
        id: 'test-id',
        title: 'Test Habit',
        category: 'Health',
        habitType: HabitType.choice,
        isCompleted: false,
        completionDates: [
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );

      expect(habit.getCurrentStreak(), 3);
    });

    test('should identify habit type correctly', () {
      const choiceHabit = StarboundHabit(
        id: 'choice-id',
        title: 'Choice Habit',
        category: 'Health',
        habitType: HabitType.choice,
        isCompleted: false,
      );

      const chanceHabit = StarboundHabit(
        id: 'chance-id',
        title: 'Chance Habit',
        category: 'Support',
        habitType: HabitType.chance,
        isCompleted: false,
      );

      expect(choiceHabit.isChoice(), true);
      expect(choiceHabit.isChance(), false);
      expect(chanceHabit.isChoice(), false);
      expect(chanceHabit.isChance(), true);
    });

    test('should update completion status correctly', () {
      var habit = const StarboundHabit(
        id: 'test-id',
        title: 'Test Habit',
        category: 'Health',
        habitType: HabitType.choice,
        isCompleted: false,
      );

      habit = habit.copyWith(isCompleted: true);
      expect(habit.isCompleted, true);

      habit = habit.copyWith(isCompleted: false);
      expect(habit.isCompleted, false);
    });
  });

  group('StarboundHabits', () {
    setUp(() {
      StarboundHabits.initialize();
    });

    test('should return all habit categories', () {
      final categories = StarboundHabits.getAllCategories();
      expect(categories, isNotEmpty);
      expect(categories, contains('Physical Health'));
      expect(categories, contains('Mental Health'));
      expect(categories, contains('Relationships'));
    });

    test('should return habits for specific category', () {
      final healthHabits = StarboundHabits.getHabitsForCategory('Physical Health');
      expect(healthHabits, isNotEmpty);
      expect(healthHabits.every((habit) => habit.category == 'Physical Health'), true);
    });

    test('should return choice habits only', () {
      final choiceHabits = StarboundHabits.getChoiceHabits();
      expect(choiceHabits.every((habit) => habit.habitType == HabitType.choice), true);
    });

    test('should return chance habits only', () {
      final chanceHabits = StarboundHabits.getChanceHabits();
      expect(chanceHabits.every((habit) => habit.habitType == HabitType.chance), true);
    });

    test('should find habit by id', () {
      final allHabits = StarboundHabits.getAllHabits();
      if (allHabits.isNotEmpty) {
        final firstHabit = allHabits.first;
        final foundHabit = StarboundHabits.getHabitById(firstHabit.id);
        expect(foundHabit, isNotNull);
        expect(foundHabit!.id, firstHabit.id);
      }
    });

    test('should return null for non-existent habit id', () {
      final foundHabit = StarboundHabits.getHabitById('non-existent-id');
      expect(foundHabit, isNull);
    });
  });
}