"""
SQLiteCRUDTool – Drop-in replacement for SupabaseCRUDTool.
Same interface: insert / select / update / delete, return {"status", "data"/"message"}.
Used for local testing / experimentation without hitting the real Supabase.
"""

import logging
import sqlite3
import os
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "test_agent.db")


def _dict_factory(cursor: sqlite3.Cursor, row: tuple) -> dict:
    """Make sqlite3 return dicts instead of tuples."""
    return {col[0]: row[i] for i, col in enumerate(cursor.description)}


class SQLiteCRUDTool:
    """
    A utility class that mirrors SupabaseCRUDTool's API but stores
    everything in a local SQLite file.
    """

    def __init__(self, db_path: str = DB_PATH):
        self.db_path = os.path.abspath(db_path)
        self._conn: Optional[sqlite3.Connection] = None

    # ── Connection ──────────────────────────────────────────────────
    @property
    def conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self._conn.row_factory = _dict_factory
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute("PRAGMA foreign_keys=ON")
        return self._conn

    # ── CRUD ────────────────────────────────────────────────────────
    def insert(self, table: str, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            cols = ", ".join(data.keys())
            placeholders = ", ".join("?" for _ in data)
            values = list(data.values())
            self.conn.execute(
                f"INSERT INTO {table} ({cols}) VALUES ({placeholders})", values
            )
            self.conn.commit()
            return {"status": "success", "data": data}
        except Exception as e:
            logger.error(f"SQLite insert into {table}: {e}")
            return {"status": "error", "message": str(e)}

    def select(
        self,
        table: str,
        match_params: Dict[str, Any] = None,
        search_params: Dict[str, Any] = None,
        limit: int = 50,
    ) -> Dict[str, Any]:
        try:
            sql = f"SELECT * FROM {table}"
            conditions = []
            values = []

            if match_params:
                for k, v in match_params.items():
                    conditions.append(f"{k} = ?")
                    values.append(v)

            if search_params:
                for k, v in search_params.items():
                    conditions.append(f"{k} LIKE ?")
                    values.append(f"%{v}%")

            if conditions:
                sql += " WHERE " + " AND ".join(conditions)

            sql += f" LIMIT {limit}"

            rows = self.conn.execute(sql, values).fetchall()
            return {"status": "success", "data": rows}
        except Exception as e:
            logger.error(f"SQLite select from {table}: {e}")
            return {"status": "error", "message": str(e)}

    def update(
        self, table: str, match_params: Dict[str, Any], data: Dict[str, Any]
    ) -> Dict[str, Any]:
        if not match_params:
            return {
                "status": "error",
                "message": "match_params required for update.",
            }
        try:
            set_clause = ", ".join(f"{k} = ?" for k in data)
            where_clause = " AND ".join(f"{k} = ?" for k in match_params)
            values = list(data.values()) + list(match_params.values())

            cur = self.conn.execute(
                f"UPDATE {table} SET {set_clause} WHERE {where_clause}", values
            )
            self.conn.commit()

            if cur.rowcount > 0:
                # Return updated row(s)
                updated = self.select(table, match_params=match_params)
                return {"status": "success", "data": updated.get("data", [])}
            return {
                "status": "success",
                "message": "No records updated.",
                "data": [],
            }
        except Exception as e:
            logger.error(f"SQLite update {table}: {e}")
            return {"status": "error", "message": str(e)}

    def delete(self, table: str, match_params: Dict[str, Any]) -> Dict[str, Any]:
        if not match_params:
            return {
                "status": "error",
                "message": "match_params required for delete.",
            }
        try:
            # Fetch rows first so we can return them
            to_delete = self.select(table, match_params=match_params)

            where_clause = " AND ".join(f"{k} = ?" for k in match_params)
            values = list(match_params.values())

            cur = self.conn.execute(
                f"DELETE FROM {table} WHERE {where_clause}", values
            )
            self.conn.commit()

            if cur.rowcount > 0:
                return {"status": "success", "data": to_delete.get("data", [])}
            return {
                "status": "success",
                "message": "No records deleted.",
                "data": [],
            }
        except Exception as e:
            logger.error(f"SQLite delete from {table}: {e}")
            return {"status": "error", "message": str(e)}

    def close(self):
        if self._conn:
            self._conn.close()
            self._conn = None


# ── Singleton accessor (mirrors get_supabase_tool) ──────────────────
_default_instance: Optional[SQLiteCRUDTool] = None


def get_sqlite_tool(db_path: str = DB_PATH) -> SQLiteCRUDTool:
    global _default_instance
    if _default_instance is None:
        _default_instance = SQLiteCRUDTool(db_path)
    return _default_instance
