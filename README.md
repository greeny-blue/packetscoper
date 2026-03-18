# PacketScopeR: Interactive PCAP Explorer

A lightweight interactive **R Shiny** application for exploring parsed PCAP data through filtering, tabulation, and visualisation.

PacketScopeR is designed for quick inspection of network traffic patterns without requiring heavy tooling. It enables analysts to upload pre-parsed PCAP data (`.csv` format), classify traffic, and explore distributions across key variables such as IPs, ports, and protocols.

This project is a precursor to an interactive data exploration/visualisation app that will be written in **Python Shiny** and will feature **live PCAP acquisition and digestion, and data presentation**.

---

## Features

- CSV-based PCAP ingestion  
  Load pre-parsed `.pcap` data (`.csv` format)

- Traffic classification  
  - Internal ↔ Internal  
  - External ↔ Internal  
  - External only  

- Flexible filtering  
  - Filter by network scope  
  - Define local subnet dynamically  

- Interactive visualisation  
  - Horizontal bar charts
  - Clean hover tooltips  
  - Sort by value or frequency  

- Tabular exploration  
  - Interactive dataset browsing

- Dark mode support  
  - Toggle between light and dark themes  

<img src="images/PacketScopeR screenshot.png">
*PacketScopeR screenshot*

---

## Example Use Cases

- Quick triage of network captures  
- Identifying top talkers (IPs, ports, protocols)  
- Inspecting internal vs external communication patterns  
- Lightweight exploratory analysis before deeper investigation  

---

## Requirements

R packages:

- dplyr  
- stringr  
- shiny  
- plotly  
- bslib  
- DT  

---

## Input Data Format

The app expects a CSV file derived from a PCAP file. At minimum, the following columns should be present:

- src_ip — Source IP address  
- dst_ip — Destination IP address  

Additional columns (e.g. ports, protocols) will automatically become selectable in the UI.

Example (generated via tshark):

> tshark -r capture.pcap -T fields \
>  -e ip.src -e ip.dst -e tcp.port -e udp.port \
>  -E header=y -E separator=, > output.csv

---

## How It Works

### 1. Internal Network Detection

Users define a local network pattern (e.g. 192.168.1.X). This is just a first version and better input sanitation logic will be implemented in future versions
This is converted into a regex and used to classify traffic:

- Internal ↔ Internal  
- External ↔ Internal  
- External  

---

### 2. Reactive Data Pipeline

- File upload triggers parsing  
- Traffic is classified dynamically  
- Filters are applied based on UI input  
- Column selection updates visualisation  

---

### 3. Visualisation

- Selected column is aggregated (count)  
- Data is sorted (by variable or frequency)  
- Rendered as an interactive horizontal bar chart  

---

## Running the App

> shiny::runApp("app.R")

or

> source("app.R")

---

## Key Functions

### sort_ip()

Custom helper to sort IP addresses numerically rather than lexicographically.

---

### pcap_file()

Core reactive function:
- Reads uploaded CSV  
- Classifies traffic  
- Applies network filters  

---

### plot_of_data

Generates:
- Aggregated counts  
- Sorted factor levels  
- Sortable by factor or count via the UI
- Plotly bar chart with custom hover text  

---

## Design Notes

- State preservation  
  Uses isolate() to prevent UI resets when data updates  

- Performance  
  Designed for moderate-sized datasets. Large PCAPs should be pre-filtered before ingestion  

- Extensibility  
  The app structure allows easy addition of:
  - DNS resolution  
  - IP enrichment (GeoIP, ASN, vendor)  
  - Flow-level aggregation  

---

## Limitations

- Requires pre-parsed PCAP (no native .pcap ingestion)  
- No built-in enrichment (yet) 
- Assumes IPv4 format for IP sorting  

---

## Future Improvements

- Better date/time formatting (instead of just POSIX)
- IP lookup (manual + automatic enrichment)  
- GeoIP / ASN integration  
- DNS resolution support  
- Time-series visualisation  
- Basic anomaly detection  

This project is a precursor to a **live** digestion and interactive data exploration/visualisation app that will be written in **Python Shiny**.

---

## Disclaimer

This tool is intended for use on networks you own or have explicit permission to analyse.

---

## Author

Built as part of a hands-on exploration into network traffic analysis, Shiny app design, and lightweight cybersecurity tooling.