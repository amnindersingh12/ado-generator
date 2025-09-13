# Rails Integration Example

This example shows how to integrate the Telegram Channel Cloner with the Rails application.

## Ruby System Call Approach

You can call the Python script from Rails using system commands:

### app/services/telegram_cloner_service.rb

```ruby
class TelegramClonerService
  class << self
    def clone_channel(source_channel, target_channel)
      script_path = Rails.root.join('clone_channel.py')
      
      # Execute the Python script
      result = `python3 #{script_path} #{source_channel} #{target_channel} 2>&1`
      exit_status = $?.exitstatus
      
      if exit_status == 0
        begin
          # Parse JSON response from Python script
          JSON.parse(result)
        rescue JSON::ParserError
          { success: false, error: 'PARSE_ERROR', message: 'Failed to parse response' }
        end
      else
        { success: false, error: 'SCRIPT_ERROR', message: result.strip }
      end
    end
    
    def validate_username(username)
      script_path = Rails.root.join('clone_channel.py')
      
      result = `python3 #{script_path} #{username} #{username} --validate-only 2>&1`
      exit_status = $?.exitstatus
      
      if exit_status == 0
        begin
          JSON.parse(result)
        rescue JSON::ParserError
          { valid: false, error: 'PARSE_ERROR', message: 'Failed to parse response' }
        end
      else
        { valid: false, error: 'SCRIPT_ERROR', message: result.strip }
      end
    end
  end
end
```

### app/controllers/telegram_controller.rb

```ruby
class TelegramController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, only: [:clone_channel]

  def validate_username
    username = params[:username]
    
    if username.blank?
      render json: { valid: false, error: 'MISSING_USERNAME' }
      return
    end
    
    result = TelegramClonerService.validate_username(username)
    render json: result
  end
  
  def clone_channel
    source = params[:source_channel]
    target = params[:target_channel]
    
    if source.blank? || target.blank?
      render json: { 
        success: false, 
        error: 'MISSING_PARAMETERS',
        message: 'Both source and target channels are required'
      }
      return
    end
    
    result = TelegramClonerService.clone_channel(source, target)
    
    # Log the operation
    Rails.logger.info "Telegram clone operation: #{source} -> #{target}, Result: #{result[:success]}"
    
    render json: result
  end

  private

  def ensure_admin
    unless current_user.admin?
      render json: { 
        success: false, 
        error: 'UNAUTHORIZED',
        message: 'Admin access required'
      }, status: :unauthorized
    end
  end
end
```

### config/routes.rb

```ruby
Rails.application.routes.draw do
  # ... existing routes ...
  
  post 'telegram/validate_username', to: 'telegram#validate_username'
  post 'telegram/clone_channel', to: 'telegram#clone_channel'
end
```

### Frontend JavaScript (for AJAX calls)

```javascript
// Validate username
async function validateTelegramUsername(username) {
    try {
        const response = await fetch('/telegram/validate_username', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({ username: username })
        });
        
        return await response.json();
    } catch (error) {
        return { valid: false, error: 'NETWORK_ERROR', message: error.message };
    }
}

// Clone channel
async function cloneTelegramChannel(sourceChannel, targetChannel) {
    try {
        const response = await fetch('/telegram/clone_channel', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({ 
                source_channel: sourceChannel, 
                target_channel: targetChannel 
            })
        });
        
        return await response.json();
    } catch (error) {
        return { success: false, error: 'NETWORK_ERROR', message: error.message };
    }
}
```

## Environment Variables

Add these to your Rails environment files:

### config/application.yml (if using Figaro)

```yaml
TELEGRAM_API_ID: "your_api_id"
TELEGRAM_API_HASH: "your_api_hash"
```

### Modified Python Config Loading

Update the Python script to use environment variables if available:

```python
import os

def load_config():
    config_file = 'telegram_config.json'
    
    # Try environment variables first
    api_id = os.getenv('TELEGRAM_API_ID')
    api_hash = os.getenv('TELEGRAM_API_HASH')
    
    if api_id and api_hash:
        return {
            'api_id': api_id,
            'api_hash': api_hash,
            'session_name': 'channel_cloner'
        }
    
    # Fall back to config file
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            return json.load(f)
    
    raise FileNotFoundError("No configuration found")
```

## Installation for Rails Integration

1. Add Python dependencies to your deployment:
```bash
pip3 install -r requirements.txt
```

2. Ensure Python 3 is available in your deployment environment

3. Set up environment variables or configuration file

4. Test the integration:
```bash
rails console
> TelegramClonerService.validate_username('@test')
```