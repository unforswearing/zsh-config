import requests
components = [
  "https://raw.githubusercontent.com/StevenBlack/hosts/",
  "master/alternates/fakenews-gambling/hosts"
]
blackhosts = "".join(components)
response = requests.get(blackhosts)
hfile = open("/etc/hosts", "w")
hfile.write(response.text)
hfile.close()
