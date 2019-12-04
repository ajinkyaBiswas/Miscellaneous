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

import argparse
import time
import json

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup as bs

import winsound
import numpy as np


def _extract_html(bs_data):
    k = bs_data.find_all(class_="_5pcr userContentWrapper")
    postBigDict = list()

    for item in k:

        postDict = dict()

        # post URL
        post_url = None
        try:
            script = item.find(class_="_4vn1")
            for link in script.findAll('a'):
                if '/posts/' in link.get('href'):
                    post_url = link.get('href')
                    print(post_url)
        except:
            np.nan
        postDict['post_url'] = post_url

        # post time
        post_time = None
        try:
            post_time = item.find(class_="_5ptz").get("title")
        except:
            np.nan
        postDict['post_timestamp'] = post_time

        # Post Text

        actualPosts = item.find_all(attrs={"data-testid": "post_message"})
        for posts in actualPosts:
            paragraphs = posts.find_all('p')
            text = ""
            for index in range(0, len(paragraphs)):
                text += paragraphs[index].text

            postDict['Post'] = text

        # Links

        postLinks = item.find_all(class_="_6ks")
        postDict['Link'] = ""
        for postLink in postLinks:
            postDict['Link'] = postLink.find('a').get('href')

        # Images

        postPictures = item.find_all(class_="scaledImageFitWidth img")
        postDict['Image'] = ""
        for postPicture in postPictures:
            postDict['Image'] = postPicture.get('src')

        # Comments

        postComments = item.find_all(attrs={"data-testid": "UFI2Comment/root_depth_0"})
        postDict['Comments'] = dict()

        for comment in postComments:

            if comment.find(class_="_6qw4") is None:
                continue

            commenter = comment.find(class_="_6qw4").text
            postDict['Comments'][commenter] = dict()

            comment_text = comment.find("span", class_="_3l3x")
            if comment_text is not None:
                postDict['Comments'][commenter]["text"] = comment_text.text

            comment_link = comment.find(class_="_ns_")
            if comment_link is not None:
                postDict['Comments'][commenter]["link"] = comment_link.get("href")

            comment_pic = comment.find(class_="_2txe")
            if comment_pic is not None:
                postDict['Comments'][commenter]["image"] = comment_pic.find(class_="img").get("src")

        # Reactions

        toolBar = item.find_all(attrs={"role": "toolbar"})

        if not toolBar:  # pretty fun
            continue

        postDict['Reaction'] = dict()

        for toolBar_child in toolBar[0].children:

            str = toolBar_child['data-testid']
            reaction = str.split("UFI2TopReactions/tooltip_")[1]

            postDict['Reaction'][reaction] = 0

            for toolBar_child_child in toolBar_child.children:

                num = toolBar_child_child['aria-label'].split()[0]

                # fix weird ',' happening in some reaction values
                num = num.replace(',', '.')

                if 'K' in num:
                    realNum = float(num[:-1]) * 1000
                else:
                    realNum = float(num)

                postDict['Reaction'][reaction] = realNum

        postBigDict.append(postDict)

    return postBigDict


def extract(page, numOfPost, infinite_scroll=False, scrape_comment=False):
    with open('facebook_credentials.txt') as file:
        email = file.readline().split('"')[1]
        password = file.readline().split('"')[1]

    option = Options()

    option.add_argument("--disable-infobars")
    option.add_argument("start-maximized")
    option.add_argument("--disable-extensions")

    # Pass the argument 1 to allow and 2 to block
    option.add_experimental_option("prefs", {
        "profile.default_content_setting_values.notifications": 1
    })

    # browser = webdriver.Chrome(executable_path="./chromedriver", chrome_options=option)
    browser = webdriver.Chrome(
        executable_path=r'C:/Users/biswa/JupyterNoteBooks/MARK_AI/chromedriver_win32/chromedriver.exe')
    browser.get("http://facebook.com")
    browser.maximize_window()
    browser.find_element_by_name("email").send_keys(email)
    browser.find_element_by_name("pass").send_keys(password)
    browser.find_element_by_id('loginbutton').click()

    browser.get("http://facebook.com/" + page + "/posts")

    if infinite_scroll:
        lenOfPage = browser.execute_script(
            "window.scrollTo(0, document.body.scrollHeight);var lenOfPage=document.body.scrollHeight;return lenOfPage;")
    else:
        # roughly 8 post per scroll kindaOf
        lenOfPage = int(numOfPost / 8)

    print("Number Of Scrolls Needed " + str(lenOfPage))

    lastCount = -1
    match = False

    retry_count = 0
    while not match:
        if infinite_scroll:
            lastCount = lenOfPage
        else:
            lastCount += 1

        # wait for the browser to load, this time can be changed slightly ~3 seconds with no difference, but 5 seems
        # to be stable enough
        time.sleep(5)

        if infinite_scroll:
            lenOfPage = browser.execute_script(
                "window.scrollTo(0, document.body.scrollHeight);var lenOfPage=document.body.scrollHeight;return "
                "lenOfPage;")
        else:
            browser.execute_script(
                "window.scrollTo(0, document.body.scrollHeight);var lenOfPage=document.body.scrollHeight;return "
                "lenOfPage;")

        ##        if lastCount == lenOfPage:
        ##            match = True

        if lastCount == lenOfPage:
            print(f'Retrying...{retry_count + 1}')
            # waring - beep
            if retry_count > 15:
                duration = 800  # milliseconds
                freq = 550  # Hz
                i = 0
                while i < 3:
                    winsound.Beep(freq, duration)
                    i += 1

            if retry_count == 20:  # although 5 seconds is okay, sometimes we need to keep retrying....now we are doing till 100 seconds...
                match = True
            retry_count += 1
        else:
            match = False
            retry_count = 0


    if scrape_comment:
        moreComments = browser.find_elements_by_xpath('//a[@data-testid="UFI2CommentsPagerRenderer/pager_depth_0"]')
        print("Scrolling through to click on more comments")
        while len(moreComments) != 0:
            for moreComment in moreComments:
                action = webdriver.common.action_chains.ActionChains(browser)
                try:
                    # move to where the comment button is
                    action.move_to_element_with_offset(moreComment, 5, 5)
                    action.perform()
                    moreComment.click()
                except:
                    # do nothing right here
                    pass
            moreComments = browser.find_elements_by_xpath('//a[@data-testid="UFI2CommentsPagerRenderer/pager_depth_0"]')

    # Now that the page is fully scrolled, grab the source code.
    source_data = browser.page_source

    # Throw your source into BeautifulSoup and start parsing!
    bs_data = bs(source_data, 'html.parser')

    postBigDict = _extract_html(bs_data)
    browser.close()

    return postBigDict


start_time = time.time()
page_name = 'xxxxxxx'
extracted_data = extract(page_name, 8, True, False)

print(f'Time taken {(time.time() - start_time)/60} minutes.')
print(f'Scraped {len(extracted_data)} posts from {page_name} page.')

# Save data
# define the name of the directory to be created
path = "./facebook/" + page_name + '_' + str(round(time.time())) # hashtag

try:
    os.mkdir(path)
except OSError:
    print ("Creation of the directory %s failed" % path)
else:
    print ("Successfully created the directory %s " % path)

# convert extracted data to a pandas dataframe
facebook_posts = pd.DataFrame(extracted_data)

facebook_posts.to_csv(path + '/' + page_name + '_posts.csv', index=False)
print('result saved to csv file')