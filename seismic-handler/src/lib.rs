use serde::{Deserialize, Serialize};
use serde_json::Value;

// Generate bindings from WIT
wit_bindgen::generate!({
    world: "seismic-handler",
});

use exports::wasmcloud::messaging::handler::{Guest, BrokerMessage};

struct Component;

/// Represents a seismic event from the EMSC feed (GeoJSON format)
#[derive(Debug, Serialize, Deserialize, Clone)]
struct SeismicEvent {
    #[serde(rename = "type")]
    event_type: String,
    properties: EventProperties,
    geometry: Geometry,
    id: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct EventProperties {
    #[serde(rename = "lastupdate")]
    last_update: Option<String>,
    mag: Option<f64>,
    #[serde(rename = "magtype")]
    mag_type: Option<String>,
    time: Option<String>,
    flynn_region: Option<String>,
    auth: Option<String>,
    depth: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Geometry {
    #[serde(rename = "type")]
    geom_type: String,
    coordinates: Vec<f64>,
}

impl Guest for Component {
    /// Handle incoming seismic data messages from WebSocket
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        // Parse the incoming message body
        let body_str = String::from_utf8(msg.body.clone())
            .map_err(|e| format!("Failed to parse message body: {}", e))?;
        
        // Log received message (first 100 chars)
        let preview = if body_str.len() > 100 {
            &body_str[..100]
        } else {
            &body_str
        };
        eprintln!("Received message: {}...", preview);
        
        // Try to parse as JSON
        let json_value: Value = match serde_json::from_str(&body_str) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("Not JSON, skipping: {}", e);
                return Ok(()); // Not an error, just not JSON
            }
        };
        
        // Check if it's a seismic event (GeoJSON Feature format)
        if let Some(event_type) = json_value.get("type").and_then(|t| t.as_str()) {
            if event_type == "Feature" {
                // Parse as seismic event
                match serde_json::from_value::<SeismicEvent>(json_value) {
                    Ok(event) => {
                        // Store in NATS objectStore
                        if let Err(e) = store_in_nats(&event) {
                            eprintln!("Failed to store in NATS: {}", e);
                        }
                        
                        // Store in PostgreSQL
                        if let Err(e) = store_in_postgres(&event) {
                            eprintln!("Failed to store in PostgreSQL: {}", e);
                        }
                        
                        eprintln!("Successfully processed seismic event: {}", event.id);
                    }
                    Err(e) => {
                        eprintln!("Failed to parse seismic event: {}", e);
                    }
                }
            }
        }
        
        Ok(())
    }
}

/// Store seismic event in NATS objectStore (Key-Value store)
fn store_in_nats(event: &SeismicEvent) -> Result<(), String> {
    use wasmcloud::keyvalue::store;
    
    // Use the event ID as the key
    let key = format!("seismic:event:{}", event.id);
    
    // Serialize the event to JSON
    let value = serde_json::to_string(event)
        .map_err(|e| format!("Failed to serialize event: {}", e))?;
    
    // Store in NATS KV (objectStore) - 0 means no expiration
    store::set(&key, value.as_bytes(), 0)
        .map_err(|e| format!("Failed to store in NATS: {}", e))?;
    
    eprintln!("Stored in NATS with key: {}", key);
    Ok(())
}

/// Store seismic event in PostgreSQL database
fn store_in_postgres(event: &SeismicEvent) -> Result<(), String> {
    use wasmcloud::postgres::postgres::{self, PgValue};
    
    // Create INSERT statement with ON CONFLICT for idempotency
    let sql = r#"
        INSERT INTO seismic_events 
        (event_id, event_type, magnitude, magnitude_type, depth, latitude, longitude, 
         time, last_update, flynn_region, auth, raw_data)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT (event_id) DO UPDATE SET
            last_update = EXCLUDED.last_update,
            magnitude = EXCLUDED.magnitude,
            depth = EXCLUDED.depth,
            raw_data = EXCLUDED.raw_data
    "#;
    
    // Extract coordinates (lon, lat)
    let longitude = event.geometry.coordinates.get(0).copied().unwrap_or(0.0);
    let latitude = event.geometry.coordinates.get(1).copied().unwrap_or(0.0);
    
    // Serialize full event as raw data (JSON)
    let raw_data = serde_json::to_string(event)
        .map_err(|e| format!("Failed to serialize raw data: {}", e))?;
    
    // Create parameter array with proper types
    let params = vec![
        PgValue::Text(event.id.clone()),
        PgValue::Text(event.event_type.clone()),
        PgValue::Float8(event.properties.mag.unwrap_or(0.0)),
        PgValue::Text(event.properties.mag_type.clone().unwrap_or_default()),
        PgValue::Float8(event.properties.depth.unwrap_or(0.0)),
        PgValue::Float8(latitude),
        PgValue::Float8(longitude),
        PgValue::Text(event.properties.time.clone().unwrap_or_default()),
        PgValue::Text(event.properties.last_update.clone().unwrap_or_default()),
        PgValue::Text(event.properties.flynn_region.clone().unwrap_or_default()),
        PgValue::Text(event.properties.auth.clone().unwrap_or_default()),
        PgValue::Text(raw_data),
    ];
    
    // Execute the query
    postgres::execute(sql, &params)
        .map_err(|e| format!("Failed to insert into PostgreSQL: {}", e))?;
    
    eprintln!("Stored in PostgreSQL: {}", event.id);
    Ok(())
}

export!(Component);
