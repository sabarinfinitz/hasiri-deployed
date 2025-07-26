import requests

API_KEY = "AIzaSyB2fDXhWEstMOIpshUQf-cxsXMHwhEPxVc"
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"
response = requests.get(url)
print(response.status_code)
print(response.text)