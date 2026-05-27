import asyncio
import httpx
import json

async def test_stream():
    url = "http://0.0.0.0:8100/v1/agent/v4/chat/stream-test"
    payload = {
        "query": "Hãy tạo một task mua sữa và xem lịch của mình ngày mai",
        "history": []
    }
    
    print(f"Testing stream at {url}...")
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            async with client.stream("POST", url, json=payload) as response:
                if response.status_code != 200:
                    print(f"Error: {response.status_code}")
                    print(await response.aread())
                    return
                    
                async for line in response.aiter_lines():
                    if not line:
                        continue
                    if line.startswith("data: "):
                        data_str = line[6:]
                        try:
                            data = json.loads(data_str)
                            event_type = data.get("type", "unknown")
                            content = data.get("content", "")
                            
                            if event_type == "thought":
                                print(f"🧠 THOUGHT: {content}")
                            elif event_type == "status":
                                print(f"ℹ️ STATUS: {content}")
                            elif event_type == "text":
                                print(f"💬 ANSWER: {content}")
                            elif event_type == "actions":
                                print(f"📋 CHECKLIST: {data.get('actions')}")
                            elif event_type == "final":
                                print(f"✅ FINAL: {data}")
                            else:
                                print(f"🔹 {event_type}: {data}")
                        except Exception as e:
                            print(f"Parse Error: {e} on line: {line}")
        except Exception as e:
            print(f"Connection Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_stream())
