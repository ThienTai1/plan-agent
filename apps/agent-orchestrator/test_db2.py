import psycopg
try:
    conn = psycopg.connect("postgresql://postgres.hmuvlodkgivhqvyrdorq:Thientai2003%3F@aws-0-ap-south-1.pooler.supabase.com:5432/postgres")
    print("Success 5432 pool-0")
except Exception as e:
    print("Failed 5432 pool-0:", e)
