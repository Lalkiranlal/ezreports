import re

path = '/Users/kiranlalk/Desktop/ez_reports/lib/services/webview_service.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix the beginning of onNavigationRequest
content = content.replace("            onNavigationRequest: (NavigationRequest request) {", "          },\n          onNavigationRequest: (NavigationRequest request) {", 1)

# Fix the ending of onNavigationRequest
content = content.replace("          },ion.prevent;\n          },", "          },")

with open(path, 'w') as f:
    f.write(content)
