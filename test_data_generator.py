#!/usr/bin/env python3
"""
Test data generator for Seismic Data Collector

This script generates sample seismic event data in the format
that would be received from the EMSC WebSocket feed.
"""

import json
import random
import time
from datetime import datetime, timedelta

# Sample locations (lon, lat) for earthquake-prone regions
LOCATIONS = [
    (35.0, 36.0, "EASTERN MEDITERRANEAN SEA"),
    (-122.4, 37.8, "NORTHERN CALIFORNIA"),
    (139.7, 35.7, "NEAR COAST OF HONSHU, JAPAN"),
    (143.0, -38.0, "NEAR EAST COAST OF AUSTRALIA"),
    (-71.6, -33.0, "OFFSHORE VALPARAISO, CHILE"),
    (24.0, 38.0, "GREECE"),
    (15.0, 42.0, "ADRIATIC SEA"),
    (67.0, 36.0, "HINDU KUSH REGION, AFGHANISTAN"),
    (-104.0, 18.0, "OFFSHORE JALISCO, MEXICO"),
    (125.0, 7.0, "MINDANAO, PHILIPPINES"),
]

def generate_event_id():
    """Generate a unique event ID"""
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    random_id = random.randint(100000, 999999)
    return f"{timestamp}_{random_id}"

def generate_seismic_event():
    """Generate a sample seismic event in GeoJSON format"""
    lon, lat, region = random.choice(LOCATIONS)
    
    # Add some randomness to location
    lon += random.uniform(-2, 2)
    lat += random.uniform(-2, 2)
    
    # Generate magnitude (more small earthquakes than large ones)
    magnitude = random.choice([
        random.uniform(2.0, 4.0),  # More common
        random.uniform(2.0, 4.0),
        random.uniform(2.0, 4.0),
        random.uniform(4.0, 5.0),  # Moderate
        random.uniform(4.0, 5.0),
        random.uniform(5.0, 6.0),  # Strong (less common)
        random.uniform(6.0, 7.0),  # Major (rare)
    ])
    
    depth = random.uniform(5.0, 100.0)
    
    # Generate timestamp
    time_obj = datetime.utcnow() - timedelta(seconds=random.randint(0, 3600))
    time_str = time_obj.strftime("%Y-%m-%dT%H:%M:%S")
    
    event = {
        "type": "Feature",
        "id": generate_event_id(),
        "properties": {
            "lastupdate": time_str,
            "mag": round(magnitude, 1),
            "magtype": random.choice(["ml", "mb", "mw", "mww"]),
            "time": time_str,
            "flynn_region": region,
            "auth": "EMSC",
            "depth": round(depth, 1)
        },
        "geometry": {
            "type": "Point",
            "coordinates": [round(lon, 4), round(lat, 4)]
        }
    }
    
    return event

def main():
    """Generate and print test events"""
    print("Seismic Event Test Data Generator")
    print("=" * 50)
    print()
    
    num_events = 5
    print(f"Generating {num_events} test events...\n")
    
    for i in range(num_events):
        event = generate_seismic_event()
        print(f"Event {i+1}:")
        print(json.dumps(event, indent=2))
        print()
        time.sleep(0.5)
    
    print("=" * 50)
    print("\nTo send these to NATS (requires NATS CLI):")
    print('nats pub seismic.events \'{"type":"Feature",...}\'')
    print()
    print("To insert directly into PostgreSQL:")
    print("docker exec -it seismic-postgres psql -U postgres -d seismic")
    print()

if __name__ == "__main__":
    main()
