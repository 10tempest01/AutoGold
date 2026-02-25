# AutoGold - Casual Gold Skin Farmer
* **features:**
  * full automation with autoexec support (joins casual lobby and queues automatically)
  * webhooks for skin notifications, errors, wins, etc.
  * smart handling with cross client communication. it re-queues if matched with a foreign player, and rejoins casual lobby if one client disconnects
  * easily configurable settings
* **webhook messages:**
  * :tada: gold skin obtained
  * :performing_arts: character switch
  * :trophy: match win
  * :x: errors/disconnects
  * :bar_chart: session summary
  * :arrows_counterclockwise: teleports
* **requirements:**
  * executor with autoexec and file library (readfile, writefile, etc.) support
  * webhook url (optional but recommended)
* **notes:**
  * ⚠️⚠️⚠️ **this script is not meant to be executed manually, please put it in your autoexec!**
  * this will automatically detect the first character chosen and choose the character correspondingly
# Main Loader
```luau
getgenv().Settings = {
    -- The accounts involved. First entry is treated as the main account, and second entry is treated as the alt account. Anything more than that and i dont know what happens so dont ask me lol
    Accounts = { "Main"; "Alt" };

    -- Methods: FireTouchInterest, Walk
    -- The method used to enter the pads.
    -- Walk is less blatant but may increase the chance of queuing with foreign players.
    PadMethod = "Walk";

    -- Automatically lock the camera when farming.
    LockOn = true;

    -- Disables collision on your character parts to avoid getting bugged.
    Noclip = true;

    -- Continuously presses keys from MoveKeys during a match.
    SpamMoves = true;

    -- Hooks to input remote to avoid downtilts (hookmetamethod required).
    AntiDowntilt = true;

    -- Rejoins with both clients after a disconnect is detected on one of the clients.
    DisconnectDetection = true;

    -- Enables additional print info.
    DebugMode = true;

    -- The offset used when teleporting the alt to the main.
    TPOffset = Vector3.new(3.5, 0, 0);

    -- Which keycodes to spam. Remove any you don't want used.
    -- To awaken when possible, include Enum.KeyCode.G
    MoveKeys = {
        Enum.KeyCode.One;
        Enum.KeyCode.Two;
        Enum.KeyCode.Three;
        Enum.KeyCode.Four;
    };

    -- Discord webhook URL for messages. (set to nil to disable)
    Webhook = "https://discord.com/api/webhooks/xxx";

    -- Your Discord user ID. Used to ping you on important events (gold skin, errors).
    DiscordId = "1";

    -- How often (in minutes) to send a periodic status update to the webhook.
    -- Set to 0 to disable periodic updates entirely.
    PeriodicUpdateInterval = 10;

    -- Characters to cycle through after each gold skin unlock.
    -- If a character has specific keys you DON'T want spammed while playing them, like a purely defensive move, list those keys in the Blacklist table.
    Characters = {
        { Name = "Character1" };
        { Name = "Character2"; Blacklist = { Enum.KeyCode.Three } };
        { Name = "Character3" };
        { Name = "Character4"; Blacklist = { Enum.KeyCode.Four } };
    };
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/10tempest01/AutoGold/refs/heads/main/Main.lua"))()```
