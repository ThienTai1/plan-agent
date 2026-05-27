import psycopg
try:
    conn = psycopg.connect("postgresql://postgres:Thientai2003%3F@aws-0-ap-south-1.pooler.supabase.com:6543/postgres?options=reference%3Dhmuvlodkgivhqvyrdorq")
    print("Success 6543 pool-0 options")
except Exception as e:
    print("Failed 6543 pool-0 options:", e)
