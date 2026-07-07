import argparse
import os
import requests
from datetime import datetime, timezone
from pathlib import Path

parser = argparse.ArgumentParser(description="A little script to fetch .NEF files to upload to immich from a given album")
parser.add_argument("--immich-token", type=str, help="Your immich token (perms required: album.read,asset.upload,albumAsset.create)")
parser.add_argument("--album-id", type=str, help="Immich album ID to fetch the .JPG files from")
parser.add_argument("--raw-album-id", type=str, help="Immich RAW album ID to upload the RAW files to")

args = parser.parse_args()
if not args.immich_token or not args.album_id or not args.raw_album_id:
	parser.error("All arguments are required")

# Fetch images from the album on immich
base_url = "https://photos.cguertin.dev/api"
headers = {"x-api-key": args.immich_token, "Content-Type": "application/json"}

album_res = requests.get(f"{base_url}/albums/{args.album_id}", headers={"x-api-key": args.immich_token})
if album_res.status_code != 200:
	raise RuntimeError(f"Failed to fetch album {args.album_id}: {album_res.status_code} - {album_res.text}")

raw_files_to_upload = []
next_page = None

while True:
	payload = {"albumIds": [args.album_id]}
	if next_page is not None:
		payload["page"] = int(next_page)

	search_res = requests.post(f"{base_url}/search/metadata", headers=headers, json=payload)
	if search_res.status_code != 200:
		raise RuntimeError(f"Failed to search assets in album {args.album_id}: {search_res.status_code} - {search_res.text}")

	assets = search_res.json().get("assets", {})
	items = assets.get("items", [])

	for img in items:
		jpg_name = img.get("originalFileName")
		if not jpg_name:
			continue

		if jpg_name.lower().endswith(".jpg"):
			raw_name = jpg_name[:-4] + ".NEF"
		elif jpg_name.lower().endswith(".jpeg"):
			raw_name = jpg_name[:-5] + ".NEF"
		else:
			continue

		raw_files_to_upload.append(f"/Volumes/NIKON Z5_2 /DCIM/101NZ5_2/{raw_name}") # Hardcoded path to the RAW files, shouldn't change.

	next_page = assets.get("nextPage")
	if not next_page:
		break

raw_album_id = args.raw_album_id
uploaded_asset_ids = []

# Upload to immich each RAW file
for file_name in raw_files_to_upload:
	file_path = Path(file_name)
	
	if not file_path.exists():
		print(f"File not found: {file_name}")
		continue
	
	# Get file timestamps
	stat = file_path.stat()
	file_created_at = datetime.fromtimestamp(stat.st_birthtime, tz=timezone.utc).isoformat() if hasattr(stat, 'st_birthtime') else datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat()
	file_modified_at = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat()
	
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
