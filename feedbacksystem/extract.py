import re, json
text = open('bundle.js', encoding='utf-8').read()
routes = []
routes += re.findall(r'\"(/auth/[^\"]*)\"', text)
routes += re.findall(r'\"(/student/[^\"]*)\"', text)
routes += re.findall(r'\"(/forms/[^\"]*)\"', text)
routes += re.findall(r'\"(/hod/[^\"]*)\"', text)
routes += re.findall(r'\"(/responses/[^\"]*)\"', text)
routes += re.findall(r'\"(/dashboard[^\"]*)\"', text)
# check single quotes
routes += re.findall(r'\'(/auth/[^\']*)\'', text)
routes += re.findall(r'\'(/student/[^\']*)\'', text)
routes += re.findall(r'\'(/forms/[^\']*)\'', text)
routes += re.findall(r'\'(/hod/[^\']*)\'', text)
routes += re.findall(r'\'(/responses/[^\']*)\'', text)
routes += re.findall(r'\'(/dashboard[^\']*)\'', text)
print(json.dumps(list(set(routes)), indent=2))
