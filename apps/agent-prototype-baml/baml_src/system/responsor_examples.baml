// ══════════════════════════════════════════════════════════════════════
// FEW-SHOT EXAMPLES FOR RESPONSOR AGENT
// ══════════════════════════════════════════════════════════════════════

template_string FewShotExamples() #"
    EXAMPLES OF PERFECT RESPONSES:

    ---
    USER_QUERY: "How am I doing with my goals?"
    CONTEXT: [DASHBOARD_STATS_RESULTS] { "tasks_done": 24, "tasks_overdue": 3, "tasks_on_track": 15, "goal_progress": [{"goal_title": "Deep Learning Master", "progress_pct": 0.65, "status": "on_track"}, {"goal_title": "Healthy Lifestyle", "progress_pct": 0.30, "status": "behind"}], "warnings": ["Healthy Lifestyle progress is slower than planned due to missed morning routines."] }
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "Overall, you're maintaining a great momentum! Your task completion rate is high, though we should look at getting your 'Healthy Lifestyle' goal back on track."
        },
        {
          "component_type": "INSIGHT",
          "insight_data": {
            "tasks_done": 24,
            "tasks_overdue": 3,
            "tasks_on_track": 15,
            "goal_progress": [
              { "goal_title": "Deep Learning Master", "progress_pct": 0.65, "status": "on_track" },
              { "goal_title": "Healthy Lifestyle", "progress_pct": 0.30, "status": "behind" }
            ],
            "warnings": ["Healthy Lifestyle progress is slower than planned due to missed morning routines."]
          }
        }
      ]
    }

    ---
    USER_QUERY: "What are my priorities today?"
    CONTEXT: [TODAY_FOCUS_RESULTS] { "date": "2026-04-10", "tasks": [{"task_id": "t1", "title": "Refactor BAML logic", "priority": "HIGH", "is_completed": false}, {"task_id": "t2", "title": "Review architecture PR", "priority": "MEDIUM", "is_completed": false}] }
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "Every morning is a new chance to focus. Here are the top 3 items I recommend you tackle first today:"
        },
        {
          "component_type": "FOCUS",
          "focus_data": {
            "date": "2026-04-10",
            "tasks": [
                { "task_id": "t1", "title": "Refactor BAML logic", "goal_tag": "Agent Core", "estimated_minutes": 60, "is_completed": false },
                { "task_id": "t2", "title": "Review architecture PR", "goal_tag": "Scalability Initiative", "estimated_minutes": 30, "is_completed": false }
            ]
          }
        }
      ]
    }


    ---
    USER_QUERY: "Break down my goal to 'Run a Marathon'"
    CONTEXT: [PLANNER_NODES] 1. Research training plans, 2. Buy running shoes, 3. Start week 1 schedule.
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "Running a marathon is an incredible goal! I've broken this down into a structured timeline to help you stay on track from day one."
        },
        {
          "component_type": "BREAKDOWN",
          "breakdown_data": {
            "goal_title": "Launch New Marketing Campaign",
            "milestones": [
              {
                "title": "Phase 1: Content & Prep",
                "deadline": "2026-04-15",
                "subtasks": [
                  { "title": "Write 5 blog posts", "deadline": "2026-04-12" },
                  { "title": "Design LinkedIn banners", "deadline": "2026-04-14" }
                ]
              },
              {
                "title": "Phase 2: Distribution",
                "deadline": "2026-04-20",
                "subtasks": [
                  { "title": "Schedule morning posts" },
                  { "title": "Enable ad campaign" }
                ]
              }
            ]
          }
        }
      ]
    }

    ---
    USER_QUERY: "What should I do today?"
    CONTEXT: [TODAY_FOCUS_RESULTS] { "date": "2026-04-07", "tasks": [{"task_id": "t1", "title": "Fix bug #123", "priority": "HIGH", "is_completed": false}] }
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "Focused energy is key today. Here are the top priorities I've identified for you:"
        },
        {
          "component_type": "FOCUS",
          "focus_data": {
            "date": "2026-04-07",
            "tasks": [
                { "task_id": "t1", "title": "Fix bug #123", "goal_tag": "Project Phoenix", "estimated_minutes": 45, "is_completed": false }
            ]
          }
        }
      ]
    }

    ---
    USER_QUERY: "My overdue tasks"
    CONTEXT: [OVERDUE_RESULTS] { "overdue_tasks": [{"task_id": "t2", "title": "Submit report", "original_due": "2026-04-05"}] }
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "It happens to the best of us! I've found one task that slipped past its deadline. Would you like to reschedule it?"
        },
        {
          "component_type": "RESCHEDULE",
          "reschedule_data": {
            "overdue_tasks": [
                { "task_id": "t2", "title": "Submit report", "original_due": "2026-04-05", "suggested_due": "2026-04-10" }
            ]
          }
        }
      ]
    }

    ---
    USER_QUERY: "Show my stats"
    CONTEXT: [DATABASE_STATE] No tasks found for this user.
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "It looks like your dashboard is a clean slate! Since we don't have any tasks tracked yet, would you like to create your first goal or import some tasks to get started?"
        }
      ]
    }

    ---
    USER_QUERY: "How was my week? I want to reflect."
    CONTEXT: [DATABASE_STATE] User completed 12 high-priority tasks. Goal "App Launch" is at 85%.
    AGENT_RESPONSE:
    {
      "blocks": [
        {
          "component_type": "TEXT",
          "text": "Success! You’ve hit 90% of your targets this week. Before we plan the next sprint, let’s take a moment to record what worked."
        },
        {
          "component_type": "REFLECTION",
          "reflection_data": {
            "week_summary": "You dominated the 'Growth' goal this week, completing 12 high-impact tasks. Your focus on deep work in the mornings is clearly yielding results.",
            "questions": [
              {
                "prompt": "What was your single biggest win this week?",
                "placeholder": "The moment I realized..."
              },
              {
                "prompt": "Which task felt heavier than expected?",
                "placeholder": "Identifying why..."
              },
              {
                "prompt": "What will you prioritize for recovery next week?",
                "placeholder": "Saturday rest plan..."
              }
            ],
            "cta_label": "Start Weekly Journal",
            "cta_route": "/journal"
          }
        }
      ]
    }

"#
