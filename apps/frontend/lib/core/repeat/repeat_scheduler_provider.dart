import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/common/domain/models/repeat_rule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final repeatSchedulerProvider = Provider<void>((ref) {
  final userId = ref.watch(localUserIdProvider);
  final uuid = const Uuid();
  final client = Supabase.instance.client;

  Future<void> tick() async {
    final now = DateTime.now();

    final candidates = await client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .not('custom_properties', 'is', null);

    for (final task in (candidates as List)) {
      final raw = task['custom_properties'];
      if (raw == null) continue;

      Map<String, dynamic> custom;
      if (raw is Map<String, dynamic>) {
        custom = raw;
      } else if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) continue;
          custom = decoded;
        } catch (_) {
          continue;
        }
      } else {
        continue;
      }

      final rr = custom['repeat_rule'];
      if (rr is! Map) continue;
      final rule = RepeatRule.fromJson(Map<String, dynamic>.from(rr));
      if (rule.stopDuplicating) continue;
      final remaining = rule.remainingOccurrences;
      if (remaining != null && remaining <= 0) continue;

      final nextIso = rule.nextOccurrenceIso;
      final next = nextIso != null ? parseDateTimeIso(nextIso) : null;
      final nextOccurrence =
          next ?? computeNextOccurrence(rule: rule, now: now);
      if (nextOccurrence == null) continue;
      if (nextOccurrence.isAfter(now)) continue;

      DateTime cursor = nextOccurrence;
      int generated = 0;
      RepeatRule cursorRule = rule;

      while (!cursor.isAfter(now) && generated < 5) {
        final remainingNow = cursorRule.remainingOccurrences;
        if (remainingNow != null && remainingNow <= 0) {
          cursorRule = cursorRule.copyWith(
            stopDuplicating: true,
            nextOccurrenceIso: null,
          );
          break;
        }
        // Create an instance task without repeat_rule to prevent recursion.
        final instanceCustom = Map<String, dynamic>.from(custom);
        instanceCustom.remove('repeat_rule');

        final nowIso = DateTime.now().toIso8601String();

        await client.from('tasks').insert({
          'id': uuid.v4(),
          'user_id': task['user_id'],
          'goal_id': task['goal_id'],
          'phase_id': task['phase_id'],
          'title': task['title'],
          'description': task['description'],
          'due_date': cursor.toIso8601String(),
          'status': 'PENDING',
          'is_completed': false,
          'priority': task['priority'],
          'custom_properties': instanceCustom.isEmpty ? null : instanceCustom,
          'created_at': nowIso,
          'updated_at': nowIso,
        });

        generated += 1;
        if (remainingNow != null) {
          cursorRule = cursorRule.copyWith(
            remainingOccurrences: remainingNow - 1,
          );
        }

        final nextAfter = computeNextOccurrence(
          rule: cursorRule,
          now: cursor.add(const Duration(seconds: 1)),
        );
        if (nextAfter == null) {
          cursorRule = cursorRule.copyWith(
            stopDuplicating: true,
            nextOccurrenceIso: null,
          );
          break;
        }

        cursor = nextAfter;
        cursorRule = cursorRule.copyWith(
          nextOccurrenceIso: cursor.toIso8601String(),
        );
      }

      final updatedCustom = Map<String, dynamic>.from(custom);
      updatedCustom['repeat_rule'] = cursorRule.toJson();

      await client
          .from('tasks')
          .update({
            'custom_properties': updatedCustom,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', task['id'] as String);
    }
  }

  // Tick frequently; work is small and guarded by next_occurrence.
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    unawaited(tick());
  });

  // Kick once on start.
  unawaited(tick());

  ref.onDispose(timer.cancel);
});
