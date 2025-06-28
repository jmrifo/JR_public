def magic_numbers():

    # import needed modules
    src_dir = ""
    dest_dir = ""#/Apps/Overleaf/Experimental Research Report/

    # set Dropbox app credentials
    APP_KEY = ''
    APP_SECRET = ''

    # define paths to local data
    TOKEN_CACHE = 'token.json'
    UPLOAD_CACHE = '.upload_cache.json'

    return src_dir, dest_dir, APP_KEY, APP_SECRET, TOKEN_CACHE, UPLOAD_CACHE

# load upload cache
def load_upload_cache():
    src_dir, dest_dir, APP_KEY, APP_SECRET, TOKEN_CACHE, UPLOAD_CACHE = magic_numbers()
    import os
    import json
    
    if os.path.exists(UPLOAD_CACHE):
        with open(UPLOAD_CACHE, 'r') as f:
            return json.load(f)
    return {}

# save upload cache
def save_upload_cache(cache):
    src_dir, dest_dir, APP_KEY, APP_SECRET, TOKEN_CACHE, UPLOAD_CACHE = magic_numbers()
    import os
    import json
    with open(UPLOAD_CACHE, 'w') as f:
        json.dump(cache, f)

# get Dropbox client
def get_dropbox_client():
    src_dir, dest_dir, APP_KEY, APP_SECRET, TOKEN_CACHE, UPLOAD_CACHE = magic_numbers()
    import os
    import json
    import dropbox
    from dropbox.oauth import DropboxOAuth2FlowNoRedirect

    if os.path.exists(TOKEN_CACHE):
        with open(TOKEN_CACHE, 'r') as f:
            token_data = json.load(f)
        return dropbox.Dropbox(
            oauth2_refresh_token=token_data['refresh_token'],
            app_key=APP_KEY,
            app_secret=APP_SECRET
        )

    auth_flow = DropboxOAuth2FlowNoRedirect(APP_KEY, APP_SECRET, token_access_type='offline')
    authorize_url = auth_flow.start()
    print(authorize_url)
    print(">>> waiting for authorization code...")
    auth_code = input("Enter the authorization code here: ").strip()

    oauth_result = auth_flow.finish(auth_code)

    with open(TOKEN_CACHE, 'w') as f:
        json.dump({'refresh_token': oauth_result.refresh_token}, f)

    return dropbox.Dropbox(
        oauth2_refresh_token=oauth_result.refresh_token,
        app_key=APP_KEY,
        app_secret=APP_SECRET
    )

# main upload logic
def sync_files(verbose=0):
    print("Syncing Dropbox, verbose level:", verbose)
    import os
    import json
    import dropbox
    from dropbox.oauth import DropboxOAuth2FlowNoRedirect

    src_dir, dest_dir, APP_KEY, APP_SECRET, TOKEN_CACHE, UPLOAD_CACHE = magic_numbers()
    if len(APP_SECRET)==0:
            raise ValueError("Missing App Secret")
    if len(APP_SECRET)==0:
            raise ValueError("Missing App Secret")
    if len(src_dir)==0:
            raise ValueError("Please set the source directory")
    if len(dest_dir)==0:
        raise ValueError("Please set the destination directory")
            
    dbx = get_dropbox_client()
    upload_cache = load_upload_cache()

    for root, dirs, files in os.walk(src_dir):
        for filename in files:
            if filename == "main.tex":
                raise ValueError("main.tex is a protected file and should not be uploaded.")
            # build local and Dropbox paths
            local_path = os.path.join(root, filename)
            relative_path = os.path.relpath(local_path, src_dir)
            dropbox_path = os.path.join(dest_dir, relative_path).replace("\\", "/")

            # get current local mod time
            local_mtime = os.path.getmtime(local_path)

            # check if file has changed since last upload
            cached_mtime = upload_cache.get(relative_path)
            if cached_mtime and abs(local_mtime - cached_mtime) < 1:
                if verbose>1: print(f"skipping {relative_path} (unchanged)")
                continue

            # upload file
            with open(local_path, "rb") as f:
                if verbose>0: print(f"uploading {relative_path} to {dropbox_path}")
                dbx.files_upload(f.read(), dropbox_path, mode=dropbox.files.WriteMode("overwrite"))

            # update cache
            upload_cache[relative_path] = local_mtime

    # save updated cache
    save_upload_cache(upload_cache)

# run the sync
sync_files()
