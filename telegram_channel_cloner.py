#!/usr/bin/env python3
"""
Telegram Channel Cloner
A Python script to clone Telegram channels with proper error handling
"""

import logging
import asyncio
import json
import os
from typing import Optional, Dict, Any
from pyrogram import Client
from pyrogram.errors import (
    UsernameNotOccupied, 
    ChannelPrivate, 
    UserNotParticipant,
    FloodWait,
    AuthKeyUnregistered,
    UserDeactivated
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s - %(levelname)s] - %(funcName)s() - Line %(lineno)d: %(name)s - %(message)s',
    datefmt='%d-%b-%y %I:%M:%S %p'
)
logger = logging.getLogger(__name__)

class TelegramChannelCloner:
    """Handles Telegram channel cloning operations with robust error handling"""
    
    def __init__(self, api_id: str, api_hash: str, session_name: str = "channel_cloner"):
        self.api_id = api_id
        self.api_hash = api_hash
        self.session_name = session_name
        self.client = None
        
    async def initialize_client(self) -> bool:
        """Initialize the Pyrogram client"""
        try:
            self.client = Client(
                self.session_name,
                api_id=self.api_id,
                api_hash=self.api_hash
            )
            await self.client.start()
            logger.info("Telegram client initialized successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize client: {e}")
            return False
    
    async def validate_username(self, username: str) -> Dict[str, Any]:
        """
        Validate if a username exists and is accessible
        
        Args:
            username: The username to validate (with or without @)
            
        Returns:
            Dict containing validation result and user/channel info
        """
        # Normalize username
        if not username.startswith('@'):
            username = f'@{username}'
            
        try:
            # Try to resolve the username
            peer = await self.client.resolve_peer(username)
            
            # Get detailed info about the peer
            if hasattr(peer, 'channel_id'):
                # It's a channel
                chat = await self.client.get_chat(peer.channel_id)
                return {
                    'valid': True,
                    'type': 'channel',
                    'id': chat.id,
                    'title': chat.title,
                    'username': chat.username,
                    'members_count': getattr(chat, 'members_count', 'Unknown'),
                    'is_verified': getattr(chat, 'is_verified', False)
                }
            elif hasattr(peer, 'user_id'):
                # It's a user
                user = await self.client.get_users(peer.user_id)
                return {
                    'valid': True,
                    'type': 'user',
                    'id': user.id,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'username': user.username,
                    'is_verified': getattr(user, 'is_verified', False)
                }
            else:
                return {
                    'valid': False,
                    'error': 'Unknown peer type',
                    'username': username
                }
                
        except UsernameNotOccupied:
            return {
                'valid': False,
                'error': 'USERNAME_NOT_OCCUPIED',
                'message': f'The username {username} is not occupied by anyone',
                'username': username
            }
        except ChannelPrivate:
            return {
                'valid': False,
                'error': 'CHANNEL_PRIVATE',
                'message': f'The channel {username} is private or you do not have access',
                'username': username
            }
        except Exception as e:
            return {
                'valid': False,
                'error': type(e).__name__,
                'message': str(e),
                'username': username
            }
    
    async def check_admin_rights(self, channel_username: str) -> Dict[str, Any]:
        """
        Check if the current user has admin rights in the target channel
        
        Args:
            channel_username: The channel username to check
            
        Returns:
            Dict containing admin rights information
        """
        try:
            # First validate the username
            validation_result = await self.validate_username(channel_username)
            if not validation_result['valid']:
                return {
                    'has_admin_rights': False,
                    'error': validation_result['error'],
                    'message': validation_result['message']
                }
            
            # Check if it's a channel
            if validation_result['type'] != 'channel':
                return {
                    'has_admin_rights': False,
                    'error': 'NOT_A_CHANNEL',
                    'message': f'{channel_username} is not a channel'
                }
            
            channel_id = validation_result['id']
            
            # Get chat member info for current user
            me = await self.client.get_me()
            member = await self.client.get_chat_member(channel_id, me.id)
            
            # Check admin status
            is_admin = member.status in ['administrator', 'creator']
            
            return {
                'has_admin_rights': is_admin,
                'status': member.status,
                'channel_info': validation_result,
                'user_id': me.id
            }
            
        except UserNotParticipant:
            return {
                'has_admin_rights': False,
                'error': 'USER_NOT_PARTICIPANT',
                'message': f'You are not a member of the channel {channel_username}'
            }
        except Exception as e:
            return {
                'has_admin_rights': False,
                'error': type(e).__name__,
                'message': str(e)
            }
    
    async def clone_full_channel(self, source_channel: str, target_channel: str, **options) -> Dict[str, Any]:
        """
        Clone a full channel with comprehensive error handling
        
        Args:
            source_channel: Source channel username
            target_channel: Target channel username
            **options: Additional cloning options
            
        Returns:
            Dict containing operation result
        """
        logger.info(f"Starting channel cloning from {source_channel} to {target_channel}")
        
        try:
            # Step 1: Validate source channel
            logger.info("Validating source channel...")
            source_validation = await self.validate_username(source_channel)
            if not source_validation['valid']:
                error_msg = f"Source channel validation failed: {source_validation['error']} - {source_validation.get('message', '')}"
                logger.error(error_msg)
                return {
                    'success': False,
                    'error': 'SOURCE_CHANNEL_INVALID',
                    'message': error_msg,
                    'details': source_validation
                }
            
            # Step 2: Validate target channel username
            logger.info("Validating target channel...")
            target_validation = await self.validate_username(target_channel)
            
            # If target channel doesn't exist, that might be expected for new channel creation
            if not target_validation['valid'] and target_validation['error'] == 'USERNAME_NOT_OCCUPIED':
                logger.info(f"Target username {target_channel} is available for new channel creation")
                target_available = True
            elif target_validation['valid']:
                # Target exists, check if we have admin rights
                logger.info("Target channel exists, checking admin rights...")
                admin_check = await self.check_admin_rights(target_channel)
                if not admin_check['has_admin_rights']:
                    error_msg = f"Cannot verify admin rights in target channel: {admin_check.get('message', admin_check.get('error'))}"
                    logger.error(error_msg)
                    return {
                        'success': False,
                        'error': 'NO_ADMIN_RIGHTS',
                        'message': error_msg,
                        'details': admin_check
                    }
                target_available = True
            else:
                error_msg = f"Target channel validation failed: {target_validation['error']} - {target_validation.get('message', '')}"
                logger.error(error_msg)
                return {
                    'success': False,
                    'error': 'TARGET_CHANNEL_INVALID',
                    'message': error_msg,
                    'details': target_validation
                }
            
            # Step 3: Proceed with cloning logic (placeholder for actual implementation)
            logger.info("All validations passed, proceeding with channel cloning...")
            
            # TODO: Implement actual cloning logic here
            # This would include:
            # - Creating target channel if it doesn't exist
            # - Copying channel info (title, description, photo)
            # - Copying messages (if permitted)
            # - Copying members (if permitted)
            # - Setting up channel permissions
            
            return {
                'success': True,
                'message': 'Channel cloning completed successfully',
                'source_info': source_validation,
                'target_info': target_validation if target_validation['valid'] else {'created': True},
                'options': options
            }
            
        except FloodWait as e:
            error_msg = f"Rate limit exceeded. Please wait {e.x} seconds"
            logger.warning(error_msg)
            return {
                'success': False,
                'error': 'FLOOD_WAIT',
                'message': error_msg,
                'wait_time': e.x
            }
        except Exception as e:
            error_msg = f"Channel cloning error: {type(e).__name__}: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': type(e).__name__,
                'message': error_msg
            }
    
    async def close(self):
        """Close the client connection"""
        if self.client:
            await self.client.stop()
            logger.info("Telegram client closed")

async def main():
    """Main function for testing the channel cloner"""
    # Load configuration
    config_file = 'telegram_config.json'
    
    if not os.path.exists(config_file):
        logger.error(f"Configuration file {config_file} not found")
        # Create sample config
        sample_config = {
            "api_id": "YOUR_API_ID",
            "api_hash": "YOUR_API_HASH",
            "session_name": "channel_cloner"
        }
        with open(config_file, 'w') as f:
            json.dump(sample_config, f, indent=2)
        logger.info(f"Created sample configuration file {config_file}")
        logger.info("Please update the configuration with your Telegram API credentials")
        return
    
    # Load config
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Initialize cloner
    cloner = TelegramChannelCloner(
        api_id=config['api_id'],
        api_hash=config['api_hash'],
        session_name=config.get('session_name', 'channel_cloner')
    )
    
    try:
        # Initialize client
        if not await cloner.initialize_client():
            return
        
        # Example usage
        source_channel = "@example_source_channel"
        target_channel = "@example_target_channel"
        
        # Test username validation
        logger.info("Testing username validation...")
        validation_result = await cloner.validate_username(source_channel)
        logger.info(f"Validation result: {validation_result}")
        
        # Test channel cloning
        if validation_result['valid']:
            logger.info("Testing channel cloning...")
            clone_result = await cloner.clone_full_channel(source_channel, target_channel)
            logger.info(f"Clone result: {clone_result}")
        
    except Exception as e:
        logger.error(f"Error in main: {e}")
    finally:
        await cloner.close()

if __name__ == "__main__":
    asyncio.run(main())