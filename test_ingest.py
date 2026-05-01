import requests
import json

# 1. Provide a direct URL to a PDF file on the internet
pdf_url = "https://arxiv.org/pdf/1706.03762.pdf"
filename = "attention_is_all_you_need.pdf"

print(f"Reading {filename} from URL...")

# 2. Build the payload matching your API's schema
payload = {
    "document": {
        "url": pdf_url,
        "filename": filename
    },
    "doc_id": "test-12345", # A unique ID for this document
    "metadata": {
        "project": "Test Project",
        "description": "Testing URL ingestion"
    }
}

# 3. Send it to your FastAPI server
print("Sending to http://localhost:8000/ingest...")
response = requests.post("http://localhost:8000/ingest", json=payload)

# 4. Print out the structured chunks!
if response.status_code == 200:
    data = response.json()
    print(f"\nStatus: {data['status']}")
    print(f"Chunks produced: {data['counts']['chunks_produced']}")
    
    if data.get('errors'):
        print(f"Errors: {data['errors']}")
    
    # Print the first chunk to see how beautifully it structures the data
    if data['chunks']:
        print("\n--- First Chunk Example ---")
        print(json.dumps(data['chunks'][0], indent=2))
else:
    print(f"Error: {response.status_code}")
    print(response.text)
