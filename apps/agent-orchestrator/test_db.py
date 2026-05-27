import psycopg
try:
    conn = psycopg.connect("postgresql://postgres.hmuvlodkgivhqvyrdorq:Thientai2003%3F@aws-0-ap-south-1.pooler.supabase.com:6543/postgres")
    print("Success")
except Exception as e:
    print("Failed pool-0:", e)

try:
    conn = psycopg.connect("postgresql://postgres.hmuvlodkgivhqvyrdorq:Thientai2003%3F@aws-1-ap-south-1.pooler.supabase.com:6543/postgres")
    print("Success")
except Exception as e:
    print("Failed pool-1:", e)
