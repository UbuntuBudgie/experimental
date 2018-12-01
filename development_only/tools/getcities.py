#!/usr/bin/env python3
import ast
import sys
import requests
import time

"""
This script is to extract citydata, including state info, from:
current.city.list.json.gz, as downloaded from
http://bulk.openweathermap.org/sample/
"""

# source city file
f = sys.argv[1]
# API key from https://locationiq.com/docs#forward-geocoding
# max 2 per second / 10.000 per day
key = sys.argv[2]
cdata = ast.literal_eval(open(f).read())

# output file, to replace "cities"
newfile = f + "_extracted"

line = 0
us_line = 0

def get_state(lat, long, line):
    # MAKE SURE TO REMOVE THE KEY BEFORE PUSHING
    r = requests.get(
        "https://us1.locationiq.com/v1/reverse.php?key=" + key + "&lat="+
        lat+"&lon=" + long + "&format=json"
    )
    check = r.status_code
    if check != 200:
        print("error in line " + line)
        return "error"
    else:
        return ast.literal_eval(r.text)["address"]["state"]
  

for r in cdata:
    line = line + 1
    country = r["country"]
    name = r["name"]
    city_id = str(r["id"])
    state = ""
    if country == "US":
        time.sleep(1)
        # state = get_state()
        lat = str(r["coord"]["lat"])
        long = str(r["coord"]["lon"])
        state = ", " + get_state(lat, long, str(line))
        
    newline = "".join(
        [str(r["id"]), " ", r["name"], state, ", ", r["country"], "\n"]
    )

    if country == "US":
        print(newline)
    with open(newfile, "a") as out:
        out.write(newline)
        

        
        
        
