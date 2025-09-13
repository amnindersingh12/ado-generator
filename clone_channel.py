#!/usr/bin/env python3
"""
CLI wrapper for Telegram Channel Cloner
"""

import argparse
import asyncio
import json
import sys
from telegram_channel_cloner import TelegramChannelCloner

async def main():
    parser = argparse.ArgumentParser(description='Clone Telegram channels')
    parser.add_argument('source', help='Source channel username (with or without @)')
    parser.add_argument('target', help='Target channel username (with or without @)')
    parser.add_argument('--config', default='telegram_config.json', help='Config file path')
    parser.add_argument('--validate-only', action='store_true', help='Only validate usernames, do not clone')
    parser.add_argument('--check-admin', help='Check admin rights for specified channel')
    
    args = parser.parse_args()
    
    # Load configuration
    try:
        with open(args.config, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Configuration file {args.config} not found!")
        print("Please create it from telegram_config.json.example")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in configuration file: {e}")
        sys.exit(1)
    
    # Initialize cloner
    cloner = TelegramChannelCloner(
        api_id=config['api_id'],
        api_hash=config['api_hash'],
        session_name=config.get('session_name', 'channel_cloner')
    )
    
    try:
        # Initialize client
        if not await cloner.initialize_client():
            print("Failed to initialize Telegram client")
            sys.exit(1)
        
        if args.check_admin:
            # Check admin rights
            print(f"Checking admin rights for {args.check_admin}...")
            result = await cloner.check_admin_rights(args.check_admin)
            print(json.dumps(result, indent=2))
            
        elif args.validate_only:
            # Validate usernames only
            print(f"Validating source channel: {args.source}")
            source_result = await cloner.validate_username(args.source)
            print(json.dumps(source_result, indent=2))
            
            print(f"\nValidating target channel: {args.target}")
            target_result = await cloner.validate_username(args.target)
            print(json.dumps(target_result, indent=2))
            
        else:
            # Perform full cloning
            print(f"Cloning channel from {args.source} to {args.target}...")
            result = await cloner.clone_full_channel(args.source, args.target)
            print(json.dumps(result, indent=2))
            
            if result['success']:
                print("\n✅ Channel cloning completed successfully!")
            else:
                print(f"\n❌ Channel cloning failed: {result['message']}")
                sys.exit(1)
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    finally:
        await cloner.close()

if __name__ == "__main__":
    asyncio.run(main())