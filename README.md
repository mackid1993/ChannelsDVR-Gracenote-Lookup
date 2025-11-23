# Channels DVR Gracenote Lookup Tool

A Windows batch script that searches for Gracenote station IDs using the Channels DVR Server API. This tool helps you find the correct station metadata for channel configuration and guide data mapping.

## Features

- **Interactive Search Mode** - Search for individual channels on-demand
- **Batch Processing Mode** - Process multiple channels from a text file and export to CSV
- **Smart Search Strategy** - Uses both quoted (exact phrase) and unquoted (OR) searches
- **Multiple Search Variations** - Automatically tries different variations of channel names to maximize results
- **Detailed Results** - Shows station type, name, call sign, station ID, and logo availability
- **Deduplication** - Automatically removes duplicate results based on station ID
- **Statistics** - Provides summary of searches performed and results found

## Requirements

- Windows operating system
- PowerShell (included with Windows)
- Access to a running Channels DVR Server on your network
- Network connectivity to the Channels DVR Server

## Usage

### Getting Started

1. Double-click `getGracenote.bat` to run the script
2. Enter your Channels DVR Server IP address when prompted (e.g., `192.168.1.10`)
3. The script will construct the server URL using port 8089 (standard Channels DVR port)

### Interactive Search Mode

Best for searching individual channels or exploring results:

1. Select option **1** from the main menu
2. Enter a channel name to search (e.g., `ESPN`, `HBO`, `CNN`)
3. View the results displayed on screen
4. Type `EXIT` or `MENU` to return to the main menu

**Example searches:**
- `ESPN` - Finds all ESPN-related stations
- `NBC Sports` - Searches for NBC Sports variations
- `Fox` - Finds Fox network stations

### Batch File Processing Mode

Best for processing multiple channels at once:

1. Create a text file with channel names, one per line:
   ```
   ESPN
   Fox News
   HBO
   CNN
   ```

2. Select option **2** from the main menu
3. Enter the full path to your text file
4. Results will be saved to `channel_ids.csv` in the current directory

**CSV Output Format:**
```
SearchTerm,Type,Name,CallSign,StationId,Logo
ESPN,Cable Only,ESPN,ESPN,10179,http://...
```

## How the Search Works

The tool uses an intelligent search strategy to find the best matches:

### Search Variations

1. **Quoted Searches (Exact Phrase)**
   - Original input: `"ESPN"`
   - Lowercase: `"espn"`

2. **Unquoted Searches (OR matching)**
   - Original input: `ESPN`
   - Lowercase: `espn`
   - Alphanumeric only: `ESPN` (removes special characters)
   - Lowercase alphanumeric: `espn`

3. **Short Name Enhancements (4 characters or less)**
   - Adds common suffixes: `tv`, `network`, `hd`, `channel`
   - Example: For `HBO` → also searches `hbotv`, `hbonetwork`, `hbohd`, `hbochannel`

### Result Processing

- Collects results from all search variations
- Removes duplicates based on station ID
- Sorts by type and name
- Shows logo availability indicator

## Understanding the Results

### Station Types

Results are categorized by type:
- **Cable Only** - Cable-exclusive channels
- **Full Power Broadcast** - Over-the-air broadcast stations
- **Streaming** - Streaming-only services
- Other types as defined by Gracenote

### Result Display Format

```
[Type] Name - CallSign - StationID: 12345 [Logo available]
```

**Example:**
```
[Cable Only] ESPN - ESPN - StationID: 10179 [Logo available]
```

### Search Summary

After each search, you'll see:
- Number of search variations that returned results
- Total results collected (including duplicates)
- Number of unique stations found

**Example:**
```
========================================
Search Summary: 3 searches returned results
Total results collected: 8
Unique stations found: 5
========================================
```

## Tips for Best Results

1. **Use simple search terms** - Start with basic channel names (e.g., `ESPN` instead of `ESPN HD`)
2. **Try variations** - If you don't find what you need, try different variations:
   - With/without network affiliation (e.g., `NBC` vs `NBC Sports`)
   - Abbreviated vs full name (e.g., `CNN` vs `Cable News Network`)
3. **Check all results** - Multiple stations may match your search; review all to find the correct one
4. **Use batch mode for bulk operations** - Process multiple channels at once for efficiency

## Troubleshooting

### "Server IP is required" error
- Make sure you enter a valid IP address when prompted
- Example: `192.168.200.40`

### "No results found from any search variation"
- Verify your Channels DVR Server is running and accessible
- Check that port 8089 is not blocked by firewall
- Try a different or more general search term
- Verify the channel exists in the Gracenote database

### "Error: File not found" (Batch mode)
- Ensure the full path to your input file is correct
- Use quotes if the path contains spaces: `"C:\Users\Name\channels.txt"`
- Verify the file exists and is accessible

### Connection issues
- Ping your Channels DVR Server to verify network connectivity
- Ensure the server is on the same network or accessible via your network
- Check firewall settings on both client and server

## Technical Details

### API Endpoint

The tool queries: `http://{SERVER_IP}:8089/tms/stations/{search_term}`

### PowerShell Script

The batch file dynamically generates a PowerShell script in `%TEMP%\process_channel.ps1` for processing API requests. This script is automatically cleaned up when you exit.

### Output Files

- **Interactive mode**: Results displayed on screen only
- **Batch mode**: `channel_ids.csv` created in the current directory

## Examples

### Example 1: Finding ESPN Station ID

**Input:** `ESPN`

**Output:**
```
Trying quoted: "ESPN"
  Found 2 result(s)
Trying: ESPN
  Found 5 result(s)

========================================
Search Summary: 2 searches returned results
Total results collected: 7
Unique stations found: 3
========================================

  [Cable Only] ESPN - ESPN - StationID: 10179 [Logo available]
  [Cable Only] ESPN2 - ESPN2 - StationID: 11867 [Logo available]
  [Cable Only] ESPNEWS - ESPNEWS - StationID: 16485 [Logo available]
```

### Example 2: Batch Processing

**Input file (channels.txt):**
```
ESPN
Fox News
CNN
HBO
```

**Output (channel_ids.csv):**
```csv
SearchTerm,Type,Name,CallSign,StationId,Logo
ESPN,Cable Only,ESPN,ESPN,10179,http://tmsimg.fancybits.co/...
ESPN,Cable Only,ESPN2,ESPN2,11867,http://tmsimg.fancybits.co/...
Fox News,Cable Only,Fox News Channel,FNC,14321,http://tmsimg.fancybits.co/...
CNN,Cable Only,CNN,CNN,10142,http://tmsimg.fancybits.co/...
HBO,Cable Only,HBO,HBO,10243,http://tmsimg.fancybits.co/...
```
