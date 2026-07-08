import urllib.request, urllib.error
base_url = "https://invertis-feedback-system-0chx.onrender.com/api"
endpoints = [
    "/student/dashboard", "/student/dashboard-data", "/student/forms", 
    "/student/active-forms", "/student", "/forms", "/forms/student", 
    "/feedback", "/feedback/student", "/dashboard", "/dashboard/student",
    "/student/feedbacks", "/api/student/dashboard", "/student-dashboard"
]
for ep in endpoints:
    url = base_url + ep
    req = urllib.request.Request(url, headers={'Content-Type': 'application/json'})
    try:
        urllib.request.urlopen(req)
        print(f"200 OK: {ep}")
    except urllib.error.HTTPError as e:
        print(f"{e.code}: {ep}")
    except Exception as e:
        print(f"Error: {ep} -> {e}")
