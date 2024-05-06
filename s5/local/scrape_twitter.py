# Author: apj2125
# Description: Code to download tweets by IDs
# Note: Please login to twitter on your browser and paste cookies below to authenticate

from twitter.scraper import Scraper
import time
import random
import json
import pandas as pd

def scrape_dataframe(df, batch_size=200, output_file='scraped_data.txt', pause_seconds=2):
    total_rows = len(df)
    total_time = 1

    for i in range(0, total_rows, batch_size):
        if total_time % 600 == 0:
            print("=====LONG PAUSE====")
            time.sleep(180 + random.randint(1, 10))
        batch_ids = df['id'].iloc[i:i+batch_size].tolist()
        tweets = scraper.tweets_by_ids(batch_ids)

        with open(output_file, 'a') as f:
            for data in tweets:
                json_data = json.dumps(data)  # Convert dictionary to JSON string
                f.write(json_data + '\n')

        pause_seconds = random.randint(1, 3)
        time.sleep(pause_seconds)

        total_time = total_time + pause_seconds
        total_min = round(total_time / 60, 2)
        print("Total Time: ", total_time)
        print("Progress", i, " from ", total_rows)
        print("Last Id:", batch_ids[-1:])

if __name__ == "__main__":
    scraper = Scraper(cookies={"ct0": "<insert  your cookie here>", "auth_token": "<insert your auth token here>"})
    df = pd.read_csv('<insert path to tweet IDs here>', header=None, names=['id'])
    scrape_dataframe(df)
