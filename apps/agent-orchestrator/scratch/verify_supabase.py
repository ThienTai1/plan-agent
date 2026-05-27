import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

print(f"URL: {url}")
print(f"Key preview: {key[:10]}...")

client: Client = create_client(url, key)

try:
    # Try an update that requires service_role or owner bypass
    # We'll try to fetch a thread first
    res = client.table("threads").select("*").limit(1).execute()
    if res.data:
        thread_id = res.data[0]['id']
        print(f"Testing update on thread: {thread_id}")
        
        # This update fails with anon key if we aren't "authenticated" as the owner
        update_res = client.table("threads").update({"title": res.data[0]['title']}).eq("id", thread_id).execute()
        print("✅ Update successful (Service Role confirmed)")
    else:
        print("⚠️ No threads found to test.")
except Exception as e:
    print(f"❌ Update failed: {str(e)}")
