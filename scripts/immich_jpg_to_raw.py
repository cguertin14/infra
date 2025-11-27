import argparse
import os
import requests
from datetime import datetime
from pathlib import Path

parser = argparse.ArgumentParser(description="A little script to fetch .NEF files to upload to immich from a given album")
parser.add_argument("--immich-token", type=str, help="Your immich token (perms required: album.read,asset.upload,albumAsset.create)")
parser.add_argument("--album-id", type=str, help="Immich album ID to fetch the .JPG files from")
parser.add_argument("--raw-album-id", type=str, help="Immich RAW album ID to upload the RAW files to")

args = parser.parse_args()
if not args.immich_token or not args.album_id or not args.raw_album_id:
	parser.error("All arguments are required")

# Fetch images from the album on immich
res = requests.get(f"https://photos.cguertin.dev/api/albums/{args.album_id}", headers={"x-api-key": args.immich_token})
raw_files_to_upload = []
for img in res.json()['assets']:
	raw_files_to_upload.append(f"/Volumes/NIKON Z5_2 /DCIM/101NZ5_2/{img['originalFileName'].replace('jpg', 'NEF')}") # Hardcoded path to the RAW files, shouldn't change.

raw_album_id = args.raw_album_id
base_url = "https://photos.cguertin.dev/api"
uploaded_asset_ids = []

# Upload to immich each RAW file
for file_name in raw_files_to_upload:
	file_path = Path(file_name)
	
	if not file_path.exists():
		print(f"File not found: {file_name}")
		continue
	
	# Get file timestamps
	stat = file_path.stat()
	file_created_at = datetime.fromtimestamp(stat.st_birthtime).isoformat() if hasattr(stat, 'st_birthtime') else datetime.fromtimestamp(stat.st_mtime).isoformat()
	file_modified_at = datetime.fromtimestamp(stat.st_mtime).isoformat()
	
	# Prepare multipart form data
	with open(file_path, 'rb') as f:
		files = {
			'assetData': (file_path.name, f, 'application/octet-stream')
		}
		data = {
			'deviceAssetId': f"{file_path.name}-{stat.st_size}",
			'deviceId': 'python-upload-script',
			'fileCreatedAt': file_created_at,
			'fileModifiedAt': file_modified_at,
		}		
		response = requests.post(
			f"{base_url}/assets",
			headers={"x-api-key": args.immich_token},
			files=files,
			data=data
		)
		if response.status_code == 201:
			asset_id = response.json().get('id')
			uploaded_asset_ids.append(asset_id)
			print(f"✓ Uploaded: {file_name} (ID: {asset_id})")
		else:
			print(f"✗ Failed to upload {file_name}: {response.status_code} - {response.text}")

# Add uploaded assets to the RAW album
if uploaded_asset_ids and raw_album_id:
	album_response = requests.put(
		f"{base_url}/albums/{raw_album_id}/assets",
		headers={
			"x-api-key": args.immich_token,
			"Content-Type": "application/json"
		},
		json={"ids": uploaded_asset_ids}
	)
	if album_response.status_code == 200:
		print(f"\n✓ Added {len(uploaded_asset_ids)} assets to album {raw_album_id}")
	else:
		print(f"\n✗ Failed to add assets to album: {album_response.status_code} - {album_response.text}")

