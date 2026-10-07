# "Your daily reward is ready" notifications (B7) - Creator Hub steps

What the code does (built, switched off until step 5):
- After a player claims the daily reward and presses **Yay!**, Roblox asks
  "Get notifications from Escape Crew?" (Roblox only asks players **13 and
  over**, and not again for 30 days after a no).
- 22 hours later (`Config.NOTIFY.hours`) any running Lobby server sends them
  a Roblox notification. Roblox delivers at most **one a day** per player, and
  only to players who said yes.
- It needs any Lobby server to be running at that time (someone playing).

Do these once, in order. Menus move between versions: if a screen looks
different, send me a photo.

## 1. The notification text

1. Go to **create.roblox.com** -> **Creations** -> **Escape Crew**.
2. Left menu: **Engagement** -> **Notifications**.
3. **Create a Notification String**.
4. Name: `Daily reward ready`. Text (99 characters at most):
   `Your Escape Crew daily reward is ready - come and claim it!`
5. **Create**. In the list, under **Actions**, **Copy Asset ID**. Send it to me.

## 2. The API key (lets the game send it)

1. On create.roblox.com, left menu: **Open Cloud** -> **API Keys** ->
   **Create API Key**.
2. Name: `Escape Crew notifications`.
3. **Access Permissions** -> **Select API System**: `user-notification` ->
   **Add API System** -> choose experience **Escape Crew** -> tick **Write**.
4. **Security** -> **Accepted IP Addresses**: add `0.0.0.0/0` (Roblox's own
   servers send it; their addresses change).
5. **Expiration**: none. **Save & Generate Key**.
6. **Copy Key to Clipboard** (it is shown only once). Do NOT send it to me
   or paste it anywhere else - it goes straight into step 3.

## 3. Keep the key as a Secret

1. **Creations** -> **Escape Crew** -> left menu **Secrets** (under
   **Configure** or **Settings**) -> **Create Secret**.
2. Name: `notifications` (exactly; the code asks for this name).
3. Secret: paste the key. Domain: `apis.roblox.com`. **Save**.

## 4. Allow web requests

1. Studio, the **Escape Crew (Lobby)** place: **Home** tab -> **Game
   Settings** -> **Security**.
2. Switch **Allow HTTP Requests** on -> **Save**.

## 5. Tell me the asset id from step 1

I put it in `Config.NOTIFY.messageId`, rebuild, and you sync with Rojo and
publish. Testing only works live (Secrets do not work in Studio Play): claim
the daily reward on a 13+ account, say yes to notifications, and the next
day a notification arrives. The F9 **Server** tab of a Lobby says
"Daily reminder to ... not sent: ..." if Roblox refused it.
