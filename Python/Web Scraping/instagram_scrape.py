from selenium import webdriver
from bs4 import BeautifulSoup as bs
import time
import re
from urllib.request import urlopen
import json
from pandas.io.json import json_normalize
import pandas as pd, numpy as np

import os
import requests

import winsound
import pygame


print('all imported')
# waring - beep
# duration = 800  # milliseconds
# freq = 550  # Hz
# i = 0
# while i < 3:
#     winsound.Beep(freq, duration)
#     i += 1

search_word = 'xxxxxx'

# comment/ uncomment this line depending requirements
search_word_type = 'username'
# search_word_type = 'hashtag'
# hashtag='food'
# browser = webdriver.Chrome(executable_path=r'xxxxxxxxxxxxxxxx/chromedriver.exe')  # '/path/to/chromedriver'
# browser.get('https://www.instagram.com/explore/tags/'+hashtag)

browser = webdriver.Chrome(executable_path=r'xxxxxxxxxxxxxxxxxxxxx/chromedriver.exe')  # '/path/to/chromedriver'



if search_word_type == 'username':
    browser.get('https://www.instagram.com/'+search_word+'/?hl=en')
elif search_word_type == 'hashtag':
    browser.get('https://www.instagram.com/explore/tags/'+search_word)
browser.maximize_window()

start_time = time.time()

links = []
SCROLL_PAUSE_TIME = 5

# Get scroll height
last_height = browser.execute_script("return document.body.scrollHeight")
source = browser.page_source
data = bs(source, 'html.parser')
body = data.find('body')
script = body.find('span')
for link in script.findAll('a'):
    if re.match("/p", link.get('href')):
        l = 'https://www.instagram.com' + link.get('href')
        if l not in links:
            links.append(l)

print('page scrolling started.....')
break_found_count = 0
while True:
    # Scroll down to bottom
    browser.execute_script("window.scrollTo(0, document.body.scrollHeight);")
    source = browser.page_source
    data = bs(source, 'html.parser')
    body = data.find('body')
    script = body.find('span')
    for link in script.findAll('a'):
        if re.match("/p", link.get('href')):
            l = 'https://www.instagram.com' + link.get('href')
            if l not in links:
                links.append(l)
    # Wait to load page
    time.sleep(SCROLL_PAUSE_TIME)

    # Calculate new scroll height and compare with last scroll height
    new_height = browser.execute_script("return document.body.scrollHeight")
    source = browser.page_source
    data = bs(source, 'html.parser')
    body = data.find('body')
    script = body.find('span')
    for link in script.findAll('a'):
        if re.match("/p", link.get('href')):
            l = 'https://www.instagram.com' + link.get('href')
            if l not in links:
                links.append(l)

    if new_height == last_height:
        print(f'WARNING! Page did not scroll. Retrying in 5 seconds...TRY COUNT = {break_found_count + 1}')
        # i = 0
        # while i < 3:
        #     winsound.Beep(freq, duration)
        #     i += 1
        if break_found_count == 19:  # keep trying till 100 seconds..after that break...this is because sometimes internet may get slow or a video is loading or something
            break
        break_found_count += 1
        time.sleep(SCROLL_PAUSE_TIME)
    else:
        break_found_count = 0
        print(f'page scrolling.....new_height = {new_height}')

    last_height = new_height
print('page scrolling completed')

source = browser.page_source
data = bs(source, 'html.parser')
body = data.find('body')
script = body.find('span')  # may be findAll ?
for link in script.findAll('a'):
    if re.match("/p", link.get('href')):
        l = 'https://www.instagram.com' + link.get('href')
        if l not in links:
            links.append(l)

browser.close()
print(f'Number of posts scraped is {len(links)}')
print(f'Time taken for scraping >> {(time.time() - start_time) / 60} minutes...')

# complete alarm...
# i = 0
# while i < 3:
#     winsound.Beep(freq, duration)
#     i += 1

# define the name of the directory to be created
path = "./instagram/" + search_word + '_' + str(round(time.time()))  # hashtag

try:
    os.mkdir(path)
except OSError:
    print("Creation of the directory %s failed" % path)
else:
    print("Successfully created the directory %s " % path)

df_links = pd.DataFrame({'col': links})
df_links.to_csv(path + '/' + search_word + '_links.csv', index=False)

print('cell compiled >> post URLs have been saved in csv')

# complete alarm...
# i = 0
# while i < 3:
#     winsound.Beep(freq, duration)
#     i += 1


# get all data 
start_time = time.time()

result = pd.DataFrame()
prev_pct = 0
for i in range(len(links)):
    try:
        x_url = pd.DataFrame(data={'post_url': [links[i]]})

        page = urlopen(links[i]).read()
        data = bs(page, 'html.parser')

        head = data.find('head')
        head_script = head.find('script', type='application/ld+json')  # script type="application/ld+json"
        head_raw = head_script.text.strip().replace('window._sharedData =', '').replace(';', '')
        head_json_data = json.loads(head_raw)
        x_head = pd.DataFrame.from_dict(json_normalize(head_json_data), orient='columns')
        x_head.columns = x_head.columns.str.replace("shortcode_media.", "")

        body = data.find('body')
        body_script = body.find('script')
        body_raw = body_script.text.strip().replace('window._sharedData =', '').replace(';', '')
        body_json_data = json.loads(body_raw)
        body_posts = body_json_data['entry_data']['PostPage'][0]['graphql']
        body_posts = json.dumps(body_posts)
        body_posts = json.loads(body_posts)
        x_body = pd.DataFrame.from_dict(json_normalize(body_posts), orient='columns')
        x_body.columns = x_body.columns.str.replace("shortcode_media.", "")

        x = pd.concat([x_url, x_head, x_body], axis=1)

        result = result.append(x)

    except:
        np.nan

    curr_pct = (i + 1) * 100 / (len(links))
    if (curr_pct - prev_pct) > 5:
        print(f'\nTime elaped >> {time.time() - start_time} seconds.')
        print(
            f'Scraping >> {i + 1} Out of {len(links)} has been completed. {(i + 1) * 100 / (len(links))} % has completed.')
        prev_pct = curr_pct

result = result.drop_duplicates(subset='shortcode')
result.index = range(len(result.index))
result.to_csv(path + '/' + search_word + '_all_data.csv', index=False)
print('result saved to csv file')

print('cell compiled >> all data scraped in csv file')
print(f'Time taken for scraping >> {(time.time() - start_time) / 60} minutes...')

# complete alarm...
# i = 0
# while i < 3:
#     winsound.Beep(freq, duration)
#     i += 1



# download images
start_time = time.time()

result.index = range(len(result.index))
directory = path

prev_pct = 0
for i in range(len(result)):
    r = requests.get(result['display_url'][i])
    with open(directory+ '/' + result['shortcode'][i]+".jpg", 'wb') as f:
                    f.write(r.content)
    # print progress....
    curr_pct = (i+1)*100/(len(result))
    progress = curr_pct - prev_pct
    if progress > 5:
        print(f'\nTime elaped >> {time.time() - start_time} seconds.')
        print(f'Downloading >> {i+1} Out of {len(result)} has been downloaded. {(i+1)*100/(len(result))} % has completed.')
        print(result['display_url'][i])
        prev_pct = curr_pct

print('cell compiled >> all images downloaded')
print(f'Time taken for scraping >> {(time.time() - start_time)/60} minutes...')

# complete alarm...
# i = 0
# while i < 3:
#     winsound.Beep(freq, duration)
#     i += 1
