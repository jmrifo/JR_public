#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jun 23 21:15:13 2023

@author: johannesrenz
"""

"""
This Script runs the BERTopic Topic model. Runtime in Python 3.10.9 is about 2 hours.

"""
#%% IMPORT

import pandas as pd
from nltk.corpus import stopwords
import os
from sklearn.feature_extraction.text import CountVectorizer
import time
from hdbscan import HDBSCAN
from bertopic import BERTopic
from collections import Counter
import re
import plotly.io as pio
import numpy as np

os.chdir("/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/")

#%% LOAD  DATASET

complete_path= "/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/docs_ecb_scrape.csv"
os.chdir("/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/")
complete_df = pd.read_csv(complete_path)

#rename column
complete_df = complete_df.rename(columns={'sectionp': 'doc'}) 
#add id
complete_df["id"]= complete_df.index + 1

#%% get list of only strings

df=complete_df

# Drop rows where doc is not a string
df = df.loc[df["doc"].apply(lambda x: isinstance(x, str))]
# Drop rows where doc column is empty
df.dropna(subset=["doc"], inplace=True)
# Convert the remaining values to strings
df["doc"] = df["doc"].astype(str)
# extract the doc column as a list
preprocessed_texts = df['doc'].tolist()


#%% Run Bertopic Model

start_time=time.time()

#Configure HDBSAN: min_cluster_size is set to 25 to achieve around 500 topics
hdbscan_model = HDBSCAN(min_cluster_size=25,
                        metric='euclidean',
                        cluster_selection_method='eom',
                        prediction_data=True)

#Initialize Stopword removal
english_stop_words = stopwords.words('english')
vect = CountVectorizer(stop_words = english_stop_words)

#Initialize BERTOPIC model
topic_model_test = BERTopic(verbose=True,
                            language="multilingual",
                            calculate_probabilities=True,
                            hdbscan_model=hdbscan_model,
                            vectorizer_model=vect
                            )
#Fit Model
topics=topic_model_test.fit_transform(preprocessed_texts)

#Get the Topics
topics_list=topic_model_test.get_topics()

topics_list_df = pd.DataFrame(topics_list)
topics_list_df = topics_list_df.transpose()
topics_list_df.to_csv("topics_ecb.csv")



#Calculate runtime
end_time=time.time()
runtime = end_time - start_time
run_mins=runtime/60


#%% GENERATE FIGURES: Topics

figure=topic_model_test.visualize_barchart(n_words=20, top_n_topics=200)   
pio.write_html(figure, file="ecb_topics.html")

#%% Export topic info table to tex

topic_info=topic_model_test.get_topic_info()

# Function to remove numbers from the start of a string
def remove_numbers(text):
    text = re.sub(r'^\d+', '', text)  # Remove numbers at the start of the string
    text = re.sub(r'^_+', '', text)  # Remove underscores at the start of the string
    text = re.sub(r'_(?!$)', ', ', text)  # Replace non-initial underscores with ", "
    return text
# Apply the function to the 'Name' column
topic_info['Name'] = topic_info['Name'].apply(remove_numbers)

tex=topic_info.to_latex(index=False)

#%% TABLE: Check similarity to key terms and output to df (entered into latex manually)

similar_topics = topic_model_test.find_topics("inequality", top_n=5)
similar_topics_df= pd.DataFrame(similar_topics)
similar_topics_df=similar_topics_df.transpose()

similar_topics2 = topic_model_test.find_topics("inequal", top_n=5)
similar_topics_df2= pd.DataFrame(similar_topics2)
similar_topics_df2=similar_topics_df2.transpose()


merged_df = pd.merge(similar_topics_df, similar_topics_df2, on=0, how='outer')

avg=merged_df[['1_x','1_y']].mean(axis=1)
avg=pd.DataFrame(avg)
avg=avg.rename(columns={0:"average"})

similar_topics_m =pd.merge(merged_df, avg, left_index=True, right_index=True)


#%% Table additonal material all topics

similar_topics_full = topic_model_test.find_topics("inequal", top_n=596)
similar_topics_full= pd.DataFrame(similar_topics_full)
similar_topics_full=similar_topics_full.transpose()
similar_topics_full=similar_topics_full.rename(columns={0:"Topic", 1:"Similarity"})


topic_info_ext=pd.merge(topic_info, similar_topics_full, on="Topic", how="left")

tex_full=topic_info_ext.to_latex(index=False)



