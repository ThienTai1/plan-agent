import psycopg

# We connect using keyword arguments to avoid URI parsing issues with '?' in password
try:
    conn = psycopg.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        port=6543,
        user="postgres.hmuvlodkgivhqvyrdorq",
        password="Thientai2003?",
        dbname="postgres"
    )
    print("Success 6543 pool-1 kwargs")
except Exception as e:
    print("Failed 6543 pool-1 kwargs:", e)

try:
    conn = psycopg.connect(
        host="aws-0-ap-south-1.pooler.supabase.com",
        port=6543,
        user="postgres.hmuvlodkgivhqvyrdorq",
        password="Thientai2003?",
        dbname="postgres"
    )
    print("Success 6543 pool-0 kwargs")
except Exception as e:
    print("Failed 6543 pool-0 kwargs:", e)
