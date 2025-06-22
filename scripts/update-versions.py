#!/usr/bin/env -S uv run
# /// script
# dependencies = [
#   "requests>=2.28.0",
#   "PyYAML>=6.0",
#   "typer>=0.9.0",
#   "pydantic>=2",
# ]
# ///

"""
Script to update gRPC versions in grpc-versions.yaml
Fetches the latest releases from the gRPC GitHub repository
"""

import requests
import yaml
import typer
from pydantic import BaseModel
from typing import List, Dict, Any


class Release(BaseModel):
    """Represents a gRPC release"""
    name: str
    tag_name: str
    published_at: str

    draft: bool
    prerelease: bool

    @property
    def version(self) -> str:
        return self.tag_name


def fetch_grpc_releases(limit: int = 20) -> List[Release]:
    """Fetch the latest gRPC releases from GitHub API"""
    url = "https://api.github.com/repos/grpc/grpc/releases"
    params = {"per_page": limit}
    
    response = requests.get(url, params=params)
    response.raise_for_status()
    
    releases = response.json()
    
    # Parse JSON directly to Release objects using pydantic
    all_releases = [Release.model_validate(release) for release in releases]
    
    # Filter out pre-releases and drafts
    stable_releases = [release for release in all_releases if not release.prerelease and not release.draft]
    
    return stable_releases

def load_current_config(config_path: str = "grpc-versions.yaml") -> Dict[str, Any]:
    """Load the current version configuration"""
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def update_versions(config: Dict[str, Any], new_releases: List[Release], 
                   keep_active: int = 5, mark_new_active: bool = True) -> Dict[str, Any]:
    """Update the version configuration with new releases"""
    
    # Get existing versions
    existing_versions = {v["version"]: v for v in config.get("versions", [])}
    
    # Add new releases
    updated_versions = []
    
    for i, release in enumerate(new_releases):
        version = release.version
        
        if version in existing_versions:
            # Keep existing configuration
            updated_versions.append(existing_versions[version])
        else:
            # Add new version
            is_active = mark_new_active and i < keep_active
            updated_versions.append({
                "version": version,
                "tag": release.tag_name,
                "active": is_active
            })
    
    # Add any remaining existing versions that weren't in the new releases
    for version, config_item in existing_versions.items():
        if not any(v["version"] == version for v in updated_versions):
            # Mark old versions as inactive
            config_item["active"] = False
            updated_versions.append(config_item)
    
    # Sort by version (newest first, assuming semantic versioning)
    def version_key(version_str):
        # Extract version numbers, handling 'v' prefix
        version_clean = version_str.lstrip('v')
        try:
            parts = [int(x) for x in version_clean.split('.')]
            # Pad to ensure consistent comparison
            while len(parts) < 3:
                parts.append(0)
            return tuple(parts)
        except ValueError:
            return (0, 0, 0)  # Fallback for non-standard versions
    
    updated_versions.sort(key=lambda x: version_key(x["version"]), reverse=True)
    
    # Update config
    config["versions"] = updated_versions[:20]  # Keep top 20 versions
    
    return config

def save_config(config: Dict[str, Any], config_path: str = "grpc-versions.yaml"):
    """Save the updated configuration"""
    with open(config_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

def main(
    config: str = typer.Option("grpc-versions.yaml", help="Path to the configuration file"),
    limit: int = typer.Option(20, help="Number of releases to fetch"),
    keep_active: int = typer.Option(5, help="Number of newest versions to mark as active"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Show what would be updated without making changes")
):
    """Update gRPC versions configuration"""
    
    print("Fetching gRPC releases...")
    try:
        releases = fetch_grpc_releases(limit)
        print(f"Found {len(releases)} stable releases")
        
        if not releases:
            print("No releases found")
            return
        
        print("\nLatest releases:")
        for i, release in enumerate(releases[:10]):
            print(f"  {i+1:2d}. {release.version} ({release.published_at[:10]})")
        
        config_data = load_current_config(config)
        updated_config = update_versions(config_data, releases, keep_active)
        
        if dry_run:
            print("\nDry run - changes that would be made:")
            print(yaml.dump(updated_config, default_flow_style=False, sort_keys=False))
        else:
            save_config(updated_config, config)
            print(f"\nUpdated {config}")
            
            # Show active versions
            active_versions = [v for v in updated_config["versions"] if v.get("active", False)]
            print(f"Active versions ({len(active_versions)}):")
            for version in active_versions:
                print(f"  - {version['version']}")
                
    except requests.RequestException as e:
        print(f"Error fetching releases: {e}")
        raise typer.Exit(1)
    except Exception as e:
        print(f"Error: {e}")
        raise typer.Exit(1)

if __name__ == "__main__":
    typer.run(main) 