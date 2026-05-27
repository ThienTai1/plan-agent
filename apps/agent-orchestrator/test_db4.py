import psycopg

try:
    conn = psycopg.connect(
        host="aws-0-ap-south-1.pooler.supabase.com",
        port=6543,
        user="postgres",
        password="Thientai2003?",
        dbname="postgres"
    )
    print("Success 6543 pool-0 postgres only")
except Exception as e:
    print("Failed 6543 pool-0 postgres only:", e)
