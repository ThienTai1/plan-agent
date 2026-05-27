from supabase import create_client
import os
# Load from environment variables (.env)
load_dotenv()

# Supabase URL is loaded from environment to avoid hardcoding private info
URL = os.getenv("SUPABASE_URL", "https://your-supabase-project.supabase.co")
KEY = os.getenv("SUPABASE_KEY", "...")

def check_messages(thread_id, key):
    client = create_client(URL, key)
    res = client.table("messages").select("*").eq("thread_id", thread_id).execute()
    print(f"Messages for {thread_id}: {len(res.data)}")
    for m in res.data:
        print(f" - ID: {m['id']}, Role: {m['role']}, Content: {m['content'][:30]}...")

if __name__ == "__main__":
    # I'll need to find the key from the config files first
    pass
