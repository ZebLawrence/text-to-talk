import requests
r = requests.get('http://localhost:8001/voices')
data = r.json()
print(f"Total voices: {data['count']}")
for v in data['voices']:
    print(f"  {v['voice_id']} ({v['type']})")
