# Telegram Channel Cloner

This module provides Telegram channel cloning functionality with robust error handling, specifically addressing the `USERNAME_NOT_OCCUPIED` error.

## Features

- ✅ Username validation before operations
- ✅ Comprehensive error handling for common Telegram API errors
- ✅ Admin rights verification
- ✅ Detailed logging and debugging information
- ✅ CLI interface for easy usage
- ✅ Configuration file support

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Create configuration file:
```bash
cp telegram_config.json.example telegram_config.json
```

3. Edit `telegram_config.json` with your Telegram API credentials:
```json
{
  "api_id": "YOUR_API_ID",
  "api_hash": "YOUR_API_HASH",
  "session_name": "channel_cloner"
}
```

## Getting Telegram API Credentials

1. Go to https://my.telegram.org/apps
2. Log in with your Telegram account
3. Create a new application
4. Copy the `api_id` and `api_hash` to your config file

## Usage

### Command Line Interface

#### Validate usernames only:
```bash
python clone_channel.py @source_channel @target_channel --validate-only
```

#### Check admin rights:
```bash
python clone_channel.py --check-admin @your_channel
```

#### Clone a channel:
```bash
python clone_channel.py @source_channel @target_channel
```

### Python API

```python
from telegram_channel_cloner import TelegramChannelCloner
import asyncio

async def main():
    cloner = TelegramChannelCloner("api_id", "api_hash")
    await cloner.initialize_client()
    
    # Validate username
    result = await cloner.validate_username("@example_channel")
    print(result)
    
    # Clone channel
    result = await cloner.clone_full_channel("@source", "@target")
    print(result)
    
    await cloner.close()

asyncio.run(main())
```

## Error Handling

The module handles various Telegram API errors:

- **USERNAME_NOT_OCCUPIED**: The target username doesn't exist
- **CHANNEL_PRIVATE**: Channel is private or inaccessible
- **USER_NOT_PARTICIPANT**: User is not a member of the channel
- **FLOOD_WAIT**: Rate limiting (includes wait time)

## Example Error Response

```json
{
  "success": false,
  "error": "USERNAME_NOT_OCCUPIED",
  "message": "The username @example is not occupied by anyone",
  "details": {
    "valid": false,
    "error": "USERNAME_NOT_OCCUPIED",
    "username": "@example"
  }
}
```

## Logging

The module uses detailed logging with timestamps:
```
[13-Sep-25 06:20:48 PM - ERROR] - clone_full_channel() - Line 154: __main__ - Channel cloning error: Cannot verify admin rights in target channel: Telegram says: [400 USERNAME_NOT_OCCUPIED] (caused by "contacts.ResolveUsername") Pyrogram 2.3.68 thinks: The username is not occupied by anyone
```

## Files

- `telegram_channel_cloner.py` - Main cloner class
- `clone_channel.py` - CLI interface
- `telegram_config.json.example` - Configuration template
- `requirements.txt` - Python dependencies

## Security Notes

- Never commit `telegram_config.json` to version control
- Session files are automatically ignored by `.gitignore`
- API credentials should be kept secure