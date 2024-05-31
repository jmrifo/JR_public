#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jun 23 21:33:20 2023

@author: johannesrenz
"""

"""
This Script runs the realtio Narrative model. Runtime in Python 3.7.16 is about 6 hours.

"""

#%% import & load

import os
import pandas as pd 
import relatio

# define the file path

df_path = "/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/ecb_full_scrape_03.csv"
p_out_path= "/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/postproc_ecb_scrape_03.csv"

path= "/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/Comp Text/"
os.chdir(path)

# read the CSV file as a Pandas dataframe
df = pd.read_csv(df_path)


df = df.rename(columns={'sectionp': 'doc', 'link': 'id'}) 


## Drop rows where the "doc" column is not a string
df = df.loc[df["doc"].apply(lambda x: isinstance(x, str))]
# # Drop rows where the "doc" column is empty
df.dropna(subset=["doc"], inplace=True)
# # Convert the remaining values to strings
df["doc"] = df["doc"].astype(str)
# extract the 'Text_cleaned' column as a list
preprocessed_texts = df['doc'].tolist()

#%% preprocess data into sentences, lemmatize, ...
from relatio import Preprocessor

p = Preprocessor(
    spacy_model = "en_core_web_lg",
    remove_chars = ["\"",'-',"^",".","?","!",";","(",")",",",":","\'","+","&","|","/","{","}",
                "~","_","`","[","]",">","<","=","*","%","$","@","#","’"],
    remove_punctuation = True,
    remove_digits = True,
    lowercase = True,
    lemmatize = True,
    n_process = -1,
    batch_size = 10,
)

df = p.split_into_sentences(
    df, output_path = p_out_path, progress_bar = True
)


#%%extract roles (SVO)

sentence_index, roles = p.extract_svos(df['sentence'], progress_bar = True)

for svo in roles[0:20]: print(svo)


postproc_roles = p.process_roles(roles, 
                                 max_length = 50,
                                 progress_bar = True,
                                 output_path = './output/postproc_roles.json')


from relatio.utils import load_roles
postproc_roles = load_roles('./output/postproc_roles.json')

for d in postproc_roles[0:5]: print(d)

#%%entities


known_entities = p.mine_entities(
    df['sentence'], 
    clean_entities = True, 
    progress_bar = True,
    output_path = './output/entities.pkl'
)

#from relatio.utils import load_entities
#known_entities = load_entities('./output/entities.pkl')

for n in known_entities.most_common(10): print(n)


top_known_entities = [e[0] for e in list(known_entities.most_common(100)) if e[0] != '']



#%%embeddings / narrative model


import spacy


from relatio.narrative_models import NarrativeModel


#nlp = spacy.load("en_core_web_lg")
import en_core_web_lg
nlp = en_core_web_lg.load()

embeddings_model = "en_core_web_lg"


m = NarrativeModel(clustering = "hdbscan",
                    PCA = True,
                    UMAP = False,
                    roles_considered = ['ARG0', 'ARG2', 'B-V', 'B-ARGM-NEG', 'ARG1'],
                    roles_with_known_entities = ['ARG0', 'ARG1'],
                    known_entities = top_known_entities,
                    assignment_to_known_entities = 'character_matching',
                    roles_with_unknown_entities = ['ARG0','ARG1'],
                    embeddings_type = "spaCy",
                    embeddings_model = embeddings_model
                    )

#%%fit


m.fit(postproc_roles, weight_by_frequency = True)


#%%narratives

m.plot_selection_metric("DBCV")

narratives = m.predict(postproc_roles, progress_bar = True)

#%%figures

from relatio.utils import prettify

pretty_narratives = []
for n in narratives: 
    pretty_narratives.append(prettify(n))

for i in range(10):           
    print(roles[i])
    print(postproc_roles[i])
    print(pretty_narratives[i])
from relatio import build_graph, draw_graph

G = build_graph(
    narratives, 
    top_n = 100, 
    prune_network = True
)

draw_graph(
    G,
    notebook = True,
    show_buttons = False,
    width="1600px",
    height="1000px",
    output_filename = './output/network_of_narratives.html'
    )

m.clusters_to_txt(path="./output/clusters.txt",topn=50)