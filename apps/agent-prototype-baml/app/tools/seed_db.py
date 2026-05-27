"""
Schema + Seed data for the local SQLite test database.
Run this script to create (or reset) the test_agent.db file with sample data.

Usage:
    cd apps/agent-service
    python -m app.tools.seed_db
"""

import os
import sqlite3
from uuid import uuid4
from datetime import datetime, timedelta

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "test_agent.db")

SCHEMA = """
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS goals;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS threads;

-- Goals
CREATE TABLE IF NOT EXISTS goals (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    current_state TEXT,
    start_date TEXT NOT NULL,
    end_date TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    custom_properties TEXT,          -- JSON
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tasks
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    goal_id TEXT,                     -- FK → goals.id (optional)
    title TEXT NOT NULL,
    description TEXT,
    due_date TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    priority TEXT DEFAULT 'MEDIUM',
    embedding TEXT,                   -- skip for local tests
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE SET NULL
);

-- Events
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT,
    rrule TEXT,
    embedding TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Messages (chat history)
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    thread_id TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    pending_action TEXT,             -- JSON (Legacy)
    pending_actions TEXT,            -- JSON array (New)
    follow_ups TEXT,                 -- JSON array
    reasoning TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Threads
CREATE TABLE IF NOT EXISTS threads (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
"""


TEST_USER_ID = "test-user-001"


def _now_iso() -> str:
    return datetime.now().isoformat()


def _future(days: int = 0, hours: int = 0) -> str:
    return (datetime.now() + timedelta(days=days, hours=hours)).isoformat()


def _json(data: any) -> str:
    import json
    return json.dumps(data, ensure_ascii=False)


def seed(db_path: str = DB_PATH):
    """Create tables and insert sample data."""
    db_path = os.path.abspath(db_path)
    print(f"📦 Creating database at: {db_path}")

    conn = sqlite3.connect(db_path)
    conn.executescript(SCHEMA)

    now = _now_iso()

    # ── Goals ───────────────────────────────────────────────────────
    goals = [
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "title": "Học Flutter nâng cao",
            "description": "Thành thạo State Management, Riverpod, và Clean Architecture trong 3 tháng",
            "status": "active",
            "start_date": now,
            "end_date": _future(days=90),
            "created_at": now,
            "updated_at": now,
        },
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "title": "Xây dựng Planning Agent",
            "description": "Phát triển ứng dụng AI Agent hỗ trợ quản lý công việc và lịch trình cá nhân",
            "status": "active",
            "start_date": now,
            "end_date": _future(days=60),
            "created_at": now,
            "updated_at": now,
        },
    ]

    for g in goals:
        cols = ", ".join(g.keys())
        placeholders = ", ".join("?" for _ in g)
        conn.execute(f"INSERT INTO goals ({cols}) VALUES ({placeholders})", list(g.values()))

    goal_flutter_id = goals[0]["id"]
    goal_agent_id = goals[1]["id"]

    # ── Tasks ───────────────────────────────────────────────────────
    tasks = [
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "goal_id": goal_flutter_id,
            "title": "Đọc tài liệu Riverpod 2.0",
            "description": "Đọc hết Official Docs của Riverpod trên riverpod.dev",
            "due_date": _future(days=3),
            "is_completed": 0,
            "priority": "HIGH",
            "created_at": now,
            "updated_at": now,
        },
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "goal_id": goal_flutter_id,
            "title": "Làm bài tập Clean Architecture",
            "description": "Thực hành xây dựng 1 feature theo Clean Architecture",
            "due_date": _future(days=7),
            "is_completed": 0,
            "priority": "MEDIUM",
            "created_at": now,
            "updated_at": now,
        },
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "goal_id": goal_agent_id,
            "title": "Thêm Goal CRUD cho Agent",
            "description": "Triển khai BAML + Python routes cho Goal management",
            "due_date": _future(days=5),
            "is_completed": 0,
            "priority": "CRITICAL",
            "created_at": now,
            "updated_at": now,
        },
    ]

    for t in tasks:
        cols = ", ".join(t.keys())
        placeholders = ", ".join("?" for _ in t)
        conn.execute(f"INSERT INTO tasks ({cols}) VALUES ({placeholders})", list(t.values()))

    # ── Events ──────────────────────────────────────────────────────
    events = [
        {
            "id": str(uuid4()),
            "user_id": TEST_USER_ID,
            "title": "Họp Team hàng tuần",
            "description": "Team standup meeting",
            "start_time": _future(days=1, hours=2),
            "end_time": _future(days=1, hours=3),
            "rrule": "FREQ=WEEKLY;BYDAY=MO",
            "created_at": now,
            "updated_at": now,
        },
    ]

    for e in events:
        cols = ", ".join(e.keys())
        placeholders = ", ".join("?" for _ in e)
        conn.execute(f"INSERT INTO events ({cols}) VALUES ({placeholders})", list(e.values()))

    # ── Conversation Seeding ──────────────────────────────────────────
    thread_id = "thread-ui-showcase"
    conn.execute(
        "INSERT INTO threads (id, user_id, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
        (thread_id, TEST_USER_ID, "Strategic Showcase 🚀", now, now)
    )

    messages = [
        {
            "id": "msg-welcome",
            "thread_id": thread_id,
            "role": "assistant",
            "content": "Chào mừng bạn đến với Strategic Showcase! Đây là nơi trình diễn các khả năng visualization mới của Agent.",
            "created_at": _future(hours=-5),
        },
        {
             "id": "msg-heatmap",
             "thread_id": thread_id,
             "role": "assistant",
             "content": "Đây là **Heatmap chart** dùng để theo dõi mật độ hoạt động của bạn trong 4 tuần qua.",
             "pending_actions": _json([
                 {
                     "type": "CHART",
                     "data": {
                         "title": "Activity Density (4 Weeks)",
                         "config": {
                             "type": "HEATMAP",
                             "options": {"columns": 7, "rows": 4, "color_scale": "green"}
                         },
                         "series": [
                             {
                                 "label": "Workload",
                                 "data": [
                                     {"x": "D1", "y": 3}, {"x": "D2", "y": 0}, {"x": "D3", "y": 8}, {"x": "D4", "y": 5},
                                     {"x": "D5", "y": 2}, {"x": "D6", "y": 10}, {"x": "D7", "y": 4},
                                     {"x": "D8", "y": 1}, {"x": "D9", "y": 6}, {"x": "D10", "y": 9}, {"x": "D11", "y": 3},
                                     {"x": "D12", "y": 0}, {"x": "D13", "y": 5}, {"x": "D14", "y": 7},
                                     {"x": "D15", "y": 4}, {"x": "D16", "y": 2}, {"x": "D17", "y": 8}, {"x": "D18", "y": 10},
                                     {"x": "D19", "y": 1}, {"x": "D20", "y": 0}, {"x": "D21", "y": 6},
                                     {"x": "D22", "y": 3}, {"x": "D23", "y": 9}, {"x": "D24", "y": 5}, {"x": "D25", "y": 4},
                                     {"x": "D26", "y": 2}, {"x": "D27", "y": 7}, {"x": "D28", "y": 1}
                                 ]
                             }
                         ]
                     }
                 }
             ]),
             "created_at": _future(hours=-4),
        },
        {
             "id": "msg-radial",
             "thread_id": thread_id,
             "role": "assistant",
             "content": "Còn đây là **Radial Rings**, hoàn hảo để theo dõi tiến độ đa mục tiêu cùng lúc.",
             "pending_actions": _json([
                 {
                     "type": "CHART",
                     "data": {
                         "title": "Quarterly Progress",
                         "config": {
                             "type": "RADIAL",
                             "options": {"ring_thickness": 8}
                         },
                         "series": [
                             {"label": "Launch MVP", "data": [{"y": 0.85}]},
                             {"label": "User Growth", "data": [{"y": 0.42}]},
                             {"label": "System Stability", "data": [{"y": 0.95}]}
                         ]
                     }
                 }
             ]),
             "created_at": _future(hours=-3),
        },
        {
             "id": "msg-sparkline",
             "thread_id": thread_id,
             "role": "assistant",
             "content": "Tôi cũng có thể gửi biểu đồ **Inline Sparkline** ngay trong nội dung chat như thế này: {sparkline}. Rất tự nhiên đúng không?",
             "pending_actions": _json([
                 {
                     "type": "CHART",
                     "data": {
                         "config": {
                             "type": "SPARKLINE",
                             "options": {"height": 32, "color": "blue"}
                         },
                         "series": [
                             {"data": [{"y": 10}, {"y": 15}, {"y": 8}, {"y": 25}, {"y": 18}, {"y": 30}, {"y": 22}]}
                         ]
                     }
                 }
             ]),
             "created_at": _future(hours=-2),
        },
        {
             "id": "msg-stat",
             "thread_id": thread_id,
             "role": "assistant",
             "content": "Và cuối cùng là các thẻ **Stat Card** và **Progress Bar** để xem báo cáo nhanh.",
             "pending_actions": _json([
                 {
                     "type": "CHART",
                     "data": {
                         "title": "Weekly Stats",
                         "config": {
                             "type": "STAT_CARD",
                             "options": {"layout": "row"}
                         },
                         "series": [
                             {"label": "Completed Tasks", "data": [{"x": "value", "y": 18}, {"x": "trend", "y": 12}]},
                             {"label": "Focus Time", "data": [{"x": "value", "y": 32.5}, {"x": "trend", "y": -5}]},
                             {"label": "Consistency", "data": [{"x": "value", "y": 92}, {"x": "trend", "y": 0}]}
                         ]
                     }
                 },
                 {
                     "type": "CHART",
                     "data": {
                         "title": "Roadmap Status",
                         "config": {"type": "PROGRESS"},
                         "series": [
                             {"label": "Auth System", "data": [{"x": "on_track", "y": 1.0}]},
                             {"label": "Chat Interface", "data": [{"x": "behind", "y": 0.72}]},
                             {"label": "AI Integration", "data": [{"x": "at_risk", "y": 0.15}]}
                         ]
                     }
                 }
             ]),
             "created_at": _future(hours=-1),
        }
    ]

    for m in messages:
        m["updated_at"] = m["created_at"]
        cols = ", ".join(m.keys())
        placeholders = ", ".join("?" for _ in m)
        conn.execute(f"INSERT INTO messages ({cols}) VALUES ({placeholders})", list(m.values()))

    conn.commit()

    # ── Print summary ───────────────────────────────────────────────
    print(f"\n✅ Database seeded successfully!")
    print(f"   Goals:    {len(goals)}")
    print(f"   Tasks:    {len(tasks)}")
    print(f"   Events:   {len(events)}")
    print(f"   Messages: {len(messages)}")
    print(f"\n📂 File: {db_path}")
    print(f"\n🔑 Thread ID: {thread_id}")

    conn.close()


if __name__ == "__main__":
    seed()
